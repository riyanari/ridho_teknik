import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ridho_teknik/pages/owner/client_list_page.dart';
import 'package:ridho_teknik/pages/owner/service_list_page.dart';
import 'package:ridho_teknik/pages/owner/technician_list_page.dart';
import 'package:ridho_teknik/theme/theme.dart';
import 'package:provider/provider.dart';
import 'package:ridho_teknik/providers/auth_provider.dart';
import 'package:ridho_teknik/providers/owner_master_provider.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../models/servis_model.dart';
import '../../models/user_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isRefreshing = false;
  bool _isDateFormatInitialized = false;
  bool _isInitialLoadComplete = false;

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting();
  }


  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('id_ID', null);
    if (!mounted) return;

    setState(() {
      _isDateFormatInitialized = true;
    });

    // Panggil load data setelah frame pertama (context aman)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInitialLoadComplete) {
        _isInitialLoadComplete = true;
        _loadInitialData();
      }
    });
  }


  Future<void> _loadInitialData() async {
    print('🚀 HomePage._loadInitialData() - Memulai');

    final provider = context.read<OwnerMasterProvider>();

    setState(() {
      _isRefreshing = true;
    });

    try {
      print('⏳ Memulai loading data awal...');

      await Future.wait([
        provider.fetchClients(),
        provider.fetchTechnicians(),
        provider.fetchServices(),
        provider.fetchDashboardStats(),
      ]);

      print('✅ Data berhasil diload:');
      print('   - Clients: ${provider.clients.length} data');
      print('   - Technicians: ${provider.technicians.length} data');
      print('   - Services: ${provider.services.length} data');

      // Print detail data untuk debugging
      _printDataDetails(provider);

    } catch (e, stackTrace) {
      print('❌ Error loading data: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _printDataDetails(OwnerMasterProvider provider) {
    print('\n📊 DETAIL DATA:');

    // Print clients
    if (provider.clients.isNotEmpty) {
      print('📋 CLIENTS (${provider.clients.length}):');
      for (var i = 0; i < provider.clients.length; i++) {
        final client = provider.clients[i];
        print('   ${i + 1}. ${client.name} (${client.email}) - ID: ${client.id}');
      }
    } else {
      print('📋 CLIENTS: Kosong');
    }

    // Print technicians
    if (provider.technicians.isNotEmpty) {
      print('\n🔧 TECHNICIANS (${provider.technicians.length}):');
      for (var i = 0; i < provider.technicians.length; i++) {
        final tech = provider.technicians[i];
        print('   ${i + 1}. ${tech.name} (${tech.email}) - Role: ${tech.role}');
      }
    } else {
      print('\n🔧 TECHNICIANS: Kosong');
    }

    // Print services
    if (provider.services.isNotEmpty) {
      print('\n📅 SERVICES (${provider.services.length}):');
      for (var i = 0; i < provider.services.length; i++) {
        final service = provider.services[i];
        print('   ${i + 1}. ${service.jenisDisplay} - ${service.statusDisplay} - Lokasi: ${service.lokasiNama}');
        if (service.tanggalBerkunjung != null) {
          print('       Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(service.tanggalBerkunjung!)}');
        }
      }
    } else {
      print('\n📅 SERVICES: Kosong');
    }

    // Print dashboard stats jika ada
    if (provider.dashboardStats != null) {
      print('\n📈 DASHBOARD STATS:');
      provider.dashboardStats!.forEach((key, value) {
        print('   $key: $value');
      });
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Logout',
      desc: 'Yakin ingin keluar?',
      btnCancelText: 'Batal',
      btnOkText: 'Keluar',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        await context.read<AuthProvider>().logout();

        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      },
    ).show();
  }

  String _formatDate(DateTime date) {
    if (!_isDateFormatInitialized) {
      return DateFormat('EEEE, d MMMM y').format(date);
    }
    return DateFormat('EEEE, d MMMM y', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ HomePage.build() dipanggil');

    if (!_isDateFormatInitialized) {
      print('   Menunggu inisialisasi date formatting...');
      return Scaffold(
        backgroundColor: kBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: kPrimaryColor),
              const SizedBox(height: 16),
              Text(
                'Menyiapkan aplikasi...',
                style: primaryTextStyle.copyWith(fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Consumer<OwnerMasterProvider>(
          builder: (context, provider, child) {
            // Debug print saat build
            print('🔄 Building HomePage dengan data:');
            print('   Clients: ${provider.clients.length}');
            print('   Technicians: ${provider.technicians.length}');
            print('   Services: ${provider.services.length}');
            print('   Loading: ${provider.loading}');
            print('   Error: ${provider.error}');

            // Jika data masih kosong dan tidak sedang loading, tampilkan tombol refresh
            final showRefreshButton = provider.clients.isEmpty &&
                provider.technicians.isEmpty &&
                provider.services.isEmpty &&
                !_isRefreshing &&
                !provider.loading;

            return Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _loadInitialData,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header dengan info bisnis
                              _buildBusinessHeader(context, provider),
                              const SizedBox(height: 20),

                              // Statistik Cepat
                              _buildQuickStats(provider),
                              const SizedBox(height: 20),

                              // Menu Utama
                              _buildMainMenuTitle(),
                            ],
                          ),
                        ),
                      ),

                      // Grid Menu
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.9,
                          ),
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              final menus = _getMainMenus();
                              return _buildMainMenuCard(context, menus[index]);
                            },
                            childCount: _getMainMenus().length,
                          ),
                        ),
                      ),

                      // Jadwal Service Hari Ini
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                          child: _buildTodaySchedule(provider),
                        ),
                      ),

                      // Client Terbaru
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: _buildRecentClients(provider),
                        ),
                      ),

                      // Teknisi Aktif
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
                          child: _buildActiveTechnicians(provider),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tombol manual refresh jika data kosong
                if (showRefreshButton)
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: FloatingActionButton(
                      onPressed: _loadInitialData,
                      backgroundColor: kPrimaryColor,
                      child: const Icon(Iconsax.refresh, color: Colors.white),
                    ),
                  ),

                // Loading overlay
                if (_isRefreshing)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha:0.3),
                      child: Center(
                        child: CircularProgressIndicator(color: kPrimaryColor),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBusinessHeader(BuildContext context, OwnerMasterProvider provider) {
    final now = DateTime.now();
    final formattedDate = _formatDate(now);

    // Hitung statistik
    final todayServices = provider.services.where((service) {
      final visitDate = service.tanggalBerkunjung;
      if (visitDate == null) return false;
      return visitDate.year == now.year &&
          visitDate.month == now.month &&
          visitDate.day == now.day;
    }).length;

    final pendingServices = provider.getServicesByStatus('menunggu_konfirmasi').length;

    print('📊 Statistik Header:');
    print('   - Today services: $todayServices');
    print('   - Pending services: $pendingServices');
    print('   - Total services: ${provider.services.length}');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryColor, kBoxMenuDarkBlueColor],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha:0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Iconsax.building_3, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ridho Teknik',
                        style: whiteTextStyle.copyWith(
                          fontSize: 16,
                          fontWeight: bold,
                        ),
                      ),
                      Text(
                        'AC Service Specialist',
                        style: whiteTextStyle.copyWith(
                          fontSize: 12,
                          fontWeight: regular,
                          color: Colors.white.withValues(alpha:0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _confirmLogout(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.logout_1, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Selamat Datang, Owner! 👋',
            style: whiteTextStyle.copyWith(
              fontSize: 20,
              fontWeight: bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formattedDate,
            style: whiteTextStyle.copyWith(
              fontSize: 14,
              color: Colors.white.withValues(alpha:0.8),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildHeaderStat(
                  icon: Iconsax.calendar_1,
                  value: '$todayServices',
                  label: 'Service Hari Ini',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildHeaderStat(
                  icon: Iconsax.notification_bing,
                  value: '$pendingServices',
                  label: 'Menunggu Konfirmasi',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                value,
                style: whiteTextStyle.copyWith(
                  fontSize: 18,
                  fontWeight: bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: whiteTextStyle.copyWith(
              fontSize: 11,
              color: Colors.white.withValues(alpha:0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(OwnerMasterProvider provider) {
    final totalClients = provider.clients.length;
    final totalTechnicians = provider.technicians.length;
    final totalServices = provider.services.length;
    final completedServices = provider.getServicesByStatus('selesai').length;

    print('📈 Quick Stats:');
    print('   - Total Clients: $totalClients');
    print('   - Total Technicians: $totalTechnicians');
    print('   - Total Services: $totalServices');
    print('   - Completed Services: $completedServices');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            title: 'Client',
            value: totalClients,
            icon: Iconsax.people,
            color: kBoxMenuGreenColor,
            subtitle: 'Total',
          ),
          const SizedBox(width: 12),
          _buildStatItem(
            title: 'Teknisi',
            value: totalTechnicians,
            icon: Iconsax.profile_2user,
            color: kSecondaryColor,
            subtitle: 'Aktif',
          ),
          const SizedBox(width: 12),
          _buildStatItem(
            title: 'Service',
            value: totalServices,
            icon: Iconsax.activity,
            color: kPrimaryColor,
            subtitle: '$completedServices selesai',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: primaryTextStyle.copyWith(
              fontSize: 22,
              fontWeight: bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: greyTextStyle.copyWith(
              fontSize: 12,
              fontWeight: medium,
            ),
          ),
          Text(
            subtitle,
            style: greyTextStyle.copyWith(
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMenuTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Menu Utama',
          style: primaryTextStyle.copyWith(
            fontSize: 18,
            fontWeight: bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: kPrimaryColor.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_getMainMenus().length} Menu',
            style: primaryTextStyle.copyWith(
              fontSize: 12,
              fontWeight: medium,
              color: kPrimaryColor,
            ),
          ),
        ),
      ],
    );
  }

  List<MainMenu> _getMainMenus() {
    return [
      MainMenu(
        icon: Iconsax.calendar_edit,
        title: 'Service',
        color: kBoxMenuDarkBlueColor,
        description: 'List jadwal service',
        gradient: [kBoxMenuCoklatColor, const Color(0xFF8B4513)],
      ),
      MainMenu(
        icon: Iconsax.people,
        title: 'Client',
        color: kBoxMenuGreenColor,
        description: 'Data-data client',
        gradient: [kBoxMenuGreenColor, const Color(0xFF1B998B)],
      ),
      MainMenu(
        icon: Iconsax.profile_2user,
        title: 'Teknisi',
        color: kBoxMenuLightBlueColor,
        description: 'Data teknisi & rating',
        gradient: [kBoxMenuLightBlueColor, const Color(0xFF2E3A7A)],
      ),
      // MainMenu(
      //   icon: Iconsax.location,
      //   title: 'Lokasi',
      //   color: kPrimaryColor,
      //   description: 'Data lokasi client',
      //   gradient: [kPrimaryColor, kBoxMenuDarkBlueColor],
      // ),
      // MainMenu(
      //   icon: Iconsax.cpu,
      //   title: 'AC Units',
      //   color: kBoxMenuGreenColor,
      //   description: 'Data unit AC',
      //   gradient: [kBoxMenuGreenColor, const Color(0xFF1B998B)],
      // ),
      // MainMenu(
      //   icon: Iconsax.chart_square,
      //   title: 'Dashboard',
      //   color: kSecondaryColor,
      //   description: 'Statistik lengkap',
      //   gradient: [kSecondaryColor, const Color(0xFFFF6B35)],
      // ),
    ];
  }

  Widget _buildMainMenuCard(BuildContext context, MainMenu menu) {
    return GestureDetector(
      onTap: () => _navigateToMenu(context, menu.title),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: menu.gradient,
          ),
          boxShadow: [
            BoxShadow(
              color: menu.color.withValues(alpha:0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                menu.icon,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(height: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  menu.title,
                  style: whiteTextStyle.copyWith(
                    fontSize: 13,
                    fontWeight: bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  menu.description,
                  style: whiteTextStyle.copyWith(
                    fontSize: 9,
                    fontWeight: regular,
                    color: Colors.white.withValues(alpha:0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToMenu(BuildContext context, String menuTitle) {
    print('👉 Navigasi ke menu: $menuTitle');
    switch (menuTitle) {
      case 'Service':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ServiceListPage()),
        );
        break;
      case 'Client':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ClientListPage()),
        );
        break;
      case 'Teknisi':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TechnicianListPage()),
        );
        break;
      default:
        _showComingSoon(context, 'Halaman $menuTitle');
    }
  }

  void _showComingSoon(BuildContext context, String feature) {
    print('🚧 Coming Soon: $feature');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature akan segera tersedia'),
        backgroundColor: kPrimaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildTodaySchedule(OwnerMasterProvider provider) {
    final todayServices = provider.services.where((service) {
      final visitDate = service.tanggalBerkunjung;
      if (visitDate == null) return false;
      final now = DateTime.now();
      return visitDate.year == now.year &&
          visitDate.month == now.month &&
          visitDate.day == now.day;
    }).toList();

    print('📅 Today Schedule: ${todayServices.length} service hari ini');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Iconsax.calendar_1,
          title: 'Jadwal Service Hari Ini',
          count: todayServices.length,
          color: kPrimaryColor,
        ),
        const SizedBox(height: 12),
        todayServices.isEmpty
            ? _buildEmptyState(
          icon: Iconsax.calendar_remove,
          message: 'Tidak ada jadwal service hari ini',
        )
            : Column(
          children: todayServices
              .take(3)
              .map((service) => _buildServiceItem(service))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildServiceItem(ServisModel service) {
    final time = service.tanggalBerkunjung != null
        ? DateFormat('HH:mm').format(service.tanggalBerkunjung!)
        : 'Belum dijadwalkan';

    print('   Service Item: ${service.jenisDisplay} - ${service.statusDisplay} - $time');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Iconsax.calendar_1, color: kPrimaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Service ${service.jenisDisplay}',
                  style: primaryTextStyle.copyWith(
                    fontSize: 14,
                    fontWeight: semiBold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Iconsax.clock, size: 14, color: kPrimaryColor),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: greyTextStyle.copyWith(fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: service.statusColor.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        service.statusDisplay,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: bold,
                          color: service.statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  service.lokasiNama,
                  style: greyTextStyle.copyWith(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Iconsax.arrow_right_3, color: kPrimaryColor, size: 20),
        ],
      ),
    );
  }

  Widget _buildRecentClients(OwnerMasterProvider provider) {
    final recentClients = provider.clients.take(3).toList();

    print('👥 Recent Clients: ${recentClients.length} dari total ${provider.clients.length}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Iconsax.people,
          title: 'Client Terbaru',
          count: provider.clients.length,
          color: kBoxMenuGreenColor,
        ),
        const SizedBox(height: 12),
        recentClients.isEmpty
            ? _buildEmptyState(
          icon: Iconsax.people,
          message: 'Belum ada data client',
        )
            : Column(
          children: recentClients
              .map((client) {
            print('   Client: ${client.name} (${client.email})');
            return _buildClientItem(client);
          })
              .toList(),
        ),
      ],
    );
  }

  Widget _buildClientItem(UserModel client) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kBoxMenuGreenColor.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Iconsax.profile_circle, color: kBoxMenuGreenColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name ?? 'Nama tidak tersedia',
                  style: primaryTextStyle.copyWith(
                    fontSize: 14,
                    fontWeight: semiBold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Iconsax.sms, size: 14, color: kBoxMenuGreenColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        client.email ?? 'Email tidak tersedia',
                        style: greyTextStyle.copyWith(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTechnicians(OwnerMasterProvider provider) {
    final activeTechnicians = provider.technicians.take(3).toList();

    print('🔧 Active Technicians: ${activeTechnicians.length} dari total ${provider.technicians.length}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Iconsax.profile_2user,
          title: 'Teknisi Aktif',
          count: provider.technicians.length,
          color: kSecondaryColor,
        ),
        const SizedBox(height: 12),
        activeTechnicians.isEmpty
            ? _buildEmptyState(
          icon: Iconsax.profile_2user,
          message: 'Belum ada data teknisi',
        )
            : Column(
          children: activeTechnicians
              .map((technician) {
            print('   Technician: ${technician.name} (${technician.email}) - ${technician.role}');
            return _buildTechnicianItem(technician);
          })
              .toList(),
        ),
      ],
    );
  }

  Widget _buildTechnicianItem(UserModel technician) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kSecondaryColor.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Iconsax.profile_circle, color: kSecondaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  technician.name ?? 'Nama tidak tersedia',
                  style: primaryTextStyle.copyWith(
                    fontSize: 14,
                    fontWeight: semiBold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Iconsax.sms, size: 14, color: kSecondaryColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        technician.email ?? 'Email tidak tersedia',
                        style: greyTextStyle.copyWith(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Iconsax.crown1, size: 14, color: kSecondaryColor),
                    const SizedBox(width: 4),
                    Text(
                      technician.role?.toUpperCase() ?? 'TEKNISI',
                      style: greyTextStyle.copyWith(
                        fontSize: 12,
                        fontWeight: medium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: primaryTextStyle.copyWith(
                fontSize: 14,
                fontWeight: bold,
              ),
            ),
          ],
        ),
        Text(
          '$count Total',
          style: greyTextStyle.copyWith(
            fontSize: 12,
            fontWeight: medium,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
  }) {
    print('   Empty State: $message');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.grey[400],
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: greyTextStyle.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class MainMenu {
  final IconData icon;
  final String title;
  final Color color;
  final String description;
  final List<Color> gradient;

  MainMenu({
    required this.icon,
    required this.title,
    required this.color,
    required this.description,
    required this.gradient,
  });
}