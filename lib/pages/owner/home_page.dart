import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/ac_model.dart';
import '../../models/maintenance_reminder_model.dart';
import '../../models/servis_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/owner_master_provider.dart';
import '../../theme/theme.dart';

import 'client/client_list_page.dart';
import 'maintenance_reminder_page.dart';
import 'service/service_list_page.dart';
import 'technician_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isRefreshing = false;
  bool _isDateFormatInitialized = false;
  bool _isInitialLoadComplete = false;

  static const int _defaultMaintenanceIntervalMonths = 3;

  static const int _maxUpcomingHome = 5;
  static const int _maxLocationPerIntervalHome = 5;

  static const Color _safeColor = Color(0xFF16A34A);

  static const Color _warningColor = Color(0xFFF59E0B);

  static const Color _urgentColor = Color(0xFFEF4444);

  // ============================================================
  // INIT
  // ============================================================

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isInitialLoadComplete) {
        return;
      }

      _isInitialLoadComplete = true;

      _loadInitialData();
    });
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadInitialData() async {
    if (_isRefreshing) return;

    final provider = context.read<OwnerMasterProvider>();

    setState(() {
      _isRefreshing = true;
    });

    try {
      await Future.wait([
        provider.fetchServices(),
        provider.fetchDashboardStats(),
        provider.fetchUpcomingVisits(),
        provider.fetchReminderAc3Bulan(),
        provider.fetchReminderAc6Bulan(),
      ]);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Iconsax.close_circle, color: Colors.white, size: 19),
                const SizedBox(width: 9),
                Expanded(child: Text('Gagal memuat data: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
    } finally {
      if (!mounted) return;

      setState(() {
        _isRefreshing = false;
      });
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _confirmLogout(BuildContext context) async {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Keluar dari aplikasi?',
      desc: 'Anda harus login kembali untuk mengakses dashboard owner.',
      btnCancelText: 'Batal',
      btnOkText: 'Keluar',
      btnCancelColor: Colors.grey,
      btnOkColor: Colors.red,
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        await context.read<AuthProvider>().logout();

        if (!context.mounted) {
          return;
        }

        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      },
    ).show();
  }

  // ============================================================
  // FORMAT
  // ============================================================

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, d MMMM y', 'id_ID').format(date);
  }

  String _formatVisitDate(DateTime? date) {
    if (date == null) {
      return 'Belum dijadwalkan';
    }

    return DateFormat('EEE, dd MMM • HH:mm', 'id_ID').format(date);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (!_isDateFormatInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: kPrimaryColor),
              const SizedBox(height: 14),
              Text(
                'Menyiapkan dashboard...',
                style: greyTextStyle.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Consumer<OwnerMasterProvider>(
          builder: (context, provider, child) {
            return Stack(
              children: [
                RefreshIndicator(
                  color: kPrimaryColor,
                  onRefresh: _loadInitialData,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildBusinessHeader(context, provider),

                            const SizedBox(height: 14),

                            _buildQuickStats(provider),

                            const SizedBox(height: 22),

                            _buildSectionTitle(
                              title: 'Menu Utama',
                              subtitle: 'Kelola operasional Ridho Teknik',
                              trailing: '${_getMainMenus().length} Menu',
                            ),

                            const SizedBox(height: 12),

                            _buildMainMenuGrid(),

                            const SizedBox(height: 25),

                            _buildSectionTitle(
                              title: 'Jadwal 7 Hari Ke Depan',
                              subtitle: 'Kunjungan servis yang akan datang',
                              trailing:
                                  '${provider.upcomingVisits.length} Total',
                            ),

                            const SizedBox(height: 12),

                            _buildUpcomingVisits(provider),

                            const SizedBox(height: 25),

                            _buildSectionTitle(
                              title: 'Reminder Perawatan',
                              subtitle: 'Monitoring jadwal perawatan rutin AC',
                              trailing:
                                  '${_buildMaintenanceLocations(provider).length} Lokasi',
                            ),

                            const SizedBox(height: 12),

                            _buildMaintenanceReminderSections(provider),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_isRefreshing)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.06),
                        alignment: Alignment.center,
                        child: Container(
                          width: 54,
                          height: 54,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(17),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: kPrimaryColor,
                          ),
                        ),
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

  // ============================================================
  // BUSINESS HEADER
  // ============================================================

  Widget _buildBusinessHeader(
    BuildContext context,
    OwnerMasterProvider provider,
  ) {
    final now = DateTime.now();

    final formattedDate = _formatDate(now);

    final upcomingCount = provider.upcomingVisits.length;

    final pendingServices = provider
        .getServicesByStatus('menunggu_konfirmasi')
        .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5059C8), Color(0xFF263B89)],
        ),
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4353B3).withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -65,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.045),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            right: 80,
            bottom: -60,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.025),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Iconsax.building_3,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: 11),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ridho Teknik',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          'AC Service Specialist',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.76),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  InkWell(
                    onTap: () {
                      _confirmLogout(context);
                    },
                    borderRadius: BorderRadius.circular(13),
                    child: Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Iconsax.logout_1,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              const Text(
                'Selamat Datang, Owner! 👋',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                formattedDate,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 19),

              Row(
                children: [
                  Expanded(
                    child: _buildHeaderStat(
                      icon: Iconsax.calendar_1,
                      value: '$upcomingCount',
                      label: '7 Hari Ke Depan',
                    ),
                  ),

                  const SizedBox(width: 9),

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 15),

              const SizedBox(width: 7),

              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK STATS
  // ============================================================

  Widget _buildQuickStats(OwnerMasterProvider provider) {
    final totalServices = provider.services.length;

    final totalUpcoming = provider.upcomingVisits.length;

    final maintenance = _buildMaintenanceLocations(provider);

    final urgentCount = maintenance.where((group) {
      return _convertToReminderLocation(group).status ==
          MaintenanceStatus.urgent;
    }).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              title: 'Service',
              value: totalServices,
              icon: Iconsax.activity,
              color: const Color(0xFF4A55B5),
              subtitle: 'Total',
            ),
          ),

          _statDivider(),

          Expanded(
            child: _buildStatItem(
              title: 'Kunjungan',
              value: totalUpcoming,
              icon: Iconsax.calendar_1,
              color: const Color(0xFF18A999),
              subtitle: '7 Hari',
            ),
          ),

          _statDivider(),

          Expanded(
            child: _buildStatItem(
              title: 'Mendesak',
              value: urgentCount,
              icon: Iconsax.danger,
              color: _urgentColor,
              subtitle: 'Lokasi',
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(width: 1, height: 64, color: Colors.grey[100]);
  }

  Widget _buildStatItem({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),

        const SizedBox(height: 7),

        Text(
          value.toString(),
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 1),

        Text(subtitle, style: TextStyle(fontSize: 8, color: Colors.grey[500])),
      ],
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
    String? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B1E2D),
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style: TextStyle(fontSize: 9, color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              trailing,
              style: const TextStyle(
                color: kPrimaryColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // MAIN MENU
  // ============================================================

  List<MainMenu> _getMainMenus() {
    return const [
      MainMenu(
        icon: Iconsax.calendar_edit,
        title: 'Service',
        description: 'Jadwal & pekerjaan',
        color: Color(0xFFB86800),
        gradient: [Color(0xFFC87900), Color(0xFF9D4E00)],
      ),
      MainMenu(
        icon: Iconsax.people,
        title: 'Client',
        description: 'Data pelanggan',
        color: Color(0xFF159D8A),
        gradient: [Color(0xFF20B6A1), Color(0xFF128E80)],
      ),
      MainMenu(
        icon: Iconsax.profile_2user,
        title: 'Teknisi',
        description: 'Tim & rating',
        color: Color(0xFF386FD8),
        gradient: [Color(0xFF4588F0), Color(0xFF314AA2)],
      ),
    ];
  }

  Widget _buildMainMenuGrid() {
    final menus = _getMainMenus();

    return SizedBox(
      height: 135,
      child: Row(
        children: List.generate(menus.length, (index) {
          final menu = menus[index];

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index == menus.length - 1 ? 0 : 9,
              ),
              child: _buildMainMenuCard(context, menu),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMainMenuCard(BuildContext context, MainMenu menu) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _navigateToMenu(context, menu.title);
        },
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: menu.gradient,
            ),
            borderRadius: BorderRadius.circular(19),
            boxShadow: [
              BoxShadow(
                color: menu.color.withValues(alpha: 0.26),
                blurRadius: 13,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -25,
                top: -30,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.17),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(menu.icon, color: Colors.white, size: 18),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        menu.title,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        menu.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          height: 1.3,
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToMenu(BuildContext context, String menuTitle) {
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
    }
  }

  // ============================================================
  // UPCOMING
  // ============================================================

  Widget _buildUpcomingVisits(OwnerMasterProvider provider) {
    final visits = provider.upcomingVisits;

    if (visits.isEmpty) {
      return _buildEmptyState(
        icon: Iconsax.calendar_remove,
        title: 'Belum ada jadwal',
        message: 'Tidak ada kunjungan servis dalam 7 hari ke depan.',
        color: kPrimaryColor,
      );
    }

    return Column(
      children: visits
          .take(_maxUpcomingHome)
          .map(
            (service) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _buildServiceItem(service),
            ),
          )
          .toList(),
    );
  }

  Widget _buildServiceItem(ServisModel service) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ServiceListPage()),
          );
        },
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: Colors.black.withValues(alpha: 0.025)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: service.statusColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Iconsax.calendar_1,
                  color: service.statusColor,
                  size: 19,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            service.lokasiNama,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: service.statusColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            service.statusDisplay,
                            style: TextStyle(
                              color: service.statusColor,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Service ${service.jenisDisplay}',
                      style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        Icon(Iconsax.clock, size: 12, color: kPrimaryColor),

                        const SizedBox(width: 5),

                        Expanded(
                          child: Text(
                            _formatVisitDate(service.tanggalBerkunjung),
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              Icon(Iconsax.arrow_right_3, size: 17, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MAINTENANCE ROOT
  // ============================================================

  Widget _buildMaintenanceReminderSections(OwnerMasterProvider provider) {
    final locations = _buildMaintenanceLocations(provider);

    if (locations.isEmpty) {
      return _buildEmptyState(
        icon: Iconsax.tick_circle,
        title: 'Belum ada reminder',
        message: 'Belum ada data perawatan yang perlu ditampilkan.',
        color: _safeColor,
      );
    }

    final groupedByInterval = <int, List<_MaintenanceLocationGroup>>{};

    for (final location in locations) {
      groupedByInterval.putIfAbsent(
        location.intervalMonths,
        () => <_MaintenanceLocationGroup>[],
      );

      groupedByInterval[location.intervalMonths]!.add(location);
    }

    final intervalEntries = groupedByInterval.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      children: List.generate(intervalEntries.length, (index) {
        final entry = intervalEntries[index];

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == intervalEntries.length - 1 ? 0 : 13,
          ),
          child: _buildMaintenanceIntervalCard(
            intervalMonths: entry.key,
            locations: entry.value,
          ),
        );
      }),
    );
  }

  // ============================================================
  // BUILD MAINTENANCE DATA
  // ============================================================

  List<_MaintenanceLocationGroup> _buildMaintenanceLocations(
    OwnerMasterProvider provider,
  ) {
    final allAc = <AcModel>[
      ...provider.reminder3Bulan,
      ...provider.reminder6Bulan,
    ];

    final uniqueAc = <String, AcModel>{};

    for (final ac in allAc) {
      uniqueAc[_buildAcUniqueKey(ac)] = ac;
    }

    final grouped = <String, _MaintenanceLocationGroup>{};

    for (final ac in uniqueAc.values) {
      final locationName = _extractLocationName(ac);

      final locationId = _extractLocationId(ac);

      final interval = _extractIntervalMonths(ac);

      final groupKey = '${locationId ?? locationName.toLowerCase()}|$interval';

      final users = _extractLocationUsers(ac);

      grouped.putIfAbsent(
        groupKey,
        () => _MaintenanceLocationGroup(
          locationId: locationId,
          locationName: locationName,
          intervalMonths: interval,
          users: <UserModel>[],
          units: <AcModel>[],
        ),
      );

      final group = grouped[groupKey]!;

      group.units.add(ac);

      for (final user in users) {
        final alreadyExists = group.users.any((existing) {
          if (existing.id != null && user.id != null) {
            return existing.id == user.id;
          }

          final existingEmail = (existing.email ?? '').trim().toLowerCase();

          final userEmail = (user.email ?? '').trim().toLowerCase();

          if (existingEmail.isNotEmpty && userEmail.isNotEmpty) {
            return existingEmail == userEmail;
          }

          return (existing.phone ?? '').trim() == (user.phone ?? '').trim();
        });

        if (!alreadyExists) {
          group.users.add(user);
        }
      }
    }

    final result = grouped.values.toList();

    result.sort((a, b) {
      final aLocation = _convertToReminderLocation(a);

      final bLocation = _convertToReminderLocation(b);

      final aRemaining = aLocation.remainingDays ?? 999999;

      final bRemaining = bLocation.remainingDays ?? 999999;

      return aRemaining.compareTo(bRemaining);
    });

    return result;
  }

  // ============================================================
  // CONVERT GROUP -> REMINDER
  // ============================================================

  MaintenanceReminderLocation _convertToReminderLocation(
    _MaintenanceLocationGroup group,
  ) {
    return MaintenanceReminderLocation(
      locationId: group.locationId,
      locationName: group.locationName,
      intervalMonths: group.intervalMonths,
      acCount: group.units.length,
      roomCount: _countUniqueRooms(group.units),
      oldestDays: _getOldestServiceDays(group.units),
      lastServiceDate: _getOldestServiceDate(group.units),
      users: List<UserModel>.from(group.users),
    );
  }

  // ============================================================
  // MAINTENANCE INTERVAL CARD
  // ============================================================

  Widget _buildMaintenanceIntervalCard({
    required int intervalMonths,
    required List<_MaintenanceLocationGroup> locations,
  }) {
    final pairs = locations.map((group) {
      return _ReminderPair(
        group: group,
        location: _convertToReminderLocation(group),
      );
    }).toList();

    pairs.sort((a, b) {
      final aRemaining = a.location.remainingDays ?? 999999;

      final bRemaining = b.location.remainingDays ?? 999999;

      return aRemaining.compareTo(bRemaining);
    });

    final urgentCount = pairs.where((item) {
      return item.location.status == MaintenanceStatus.urgent;
    }).length;

    final warningCount = pairs.where((item) {
      return item.location.status == MaintenanceStatus.warning;
    }).length;

    final safeCount = pairs.where((item) {
      return item.location.status == MaintenanceStatus.safe;
    }).length;

    final visible = pairs.take(_maxLocationPerIntervalHome).toList();

    final pageLocations = pairs.map((e) => e.location).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Iconsax.timer_1,
                  color: kPrimaryColor,
                  size: 19,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Perawatan $intervalMonths Bulan',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      'Monitoring jadwal servis setiap $intervalMonths bulan',
                      style: TextStyle(
                        fontSize: 9,
                        height: 1.3,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${locations.length} lokasi',
                  style: const TextStyle(
                    fontSize: 8,
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ====================================================
          // STATUS SUMMARY
          // ====================================================
          Row(
            children: [
              Expanded(
                child: _buildHomeStatusSummary(
                  color: _urgentColor,
                  icon: Iconsax.danger,
                  label: 'Mendesak',
                  count: urgentCount,
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: _buildHomeStatusSummary(
                  color: _warningColor,
                  icon: Iconsax.warning_2,
                  label: 'Segera',
                  count: warningCount,
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: _buildHomeStatusSummary(
                  color: _safeColor,
                  icon: Iconsax.tick_circle,
                  label: 'Aman',
                  count: safeCount,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ...List.generate(visible.length, (index) {
            final pair = visible[index];

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == visible.length - 1 ? 0 : 8,
              ),
              child: _buildReminderLocationItem(
                location: pair.location,
                sourceGroup: pair.group,
              ),
            );
          }),

          if (pairs.length > _maxLocationPerIntervalHome) ...[
            const SizedBox(height: 9),

            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MaintenanceReminderPage(
                        intervalMonths: intervalMonths,
                        locations: pageLocations,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha: 0.055),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Iconsax.element_3,
                        size: 14,
                        color: kPrimaryColor,
                      ),

                      const SizedBox(width: 7),

                      Text(
                        '+ ${pairs.length - _maxLocationPerIntervalHome} lokasi lainnya',
                        style: const TextStyle(
                          fontSize: 9,
                          color: kPrimaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(width: 6),

                      const Icon(
                        Iconsax.arrow_right_3,
                        size: 13,
                        color: kPrimaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // HOME STATUS SUMMARY
  // ============================================================

  Widget _buildHomeStatusSummary({
    required Color color,
    required IconData icon,
    required String label,
    required int count,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 12, color: color),

          const SizedBox(width: 5),

          Text(
            '$count',
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(width: 4),

          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 7,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOCATION REMINDER ITEM
  // ============================================================

  Widget _buildReminderLocationItem({
    required MaintenanceReminderLocation location,
    required _MaintenanceLocationGroup sourceGroup,
  }) {
    final color = location.statusColor;

    final whatsappUsers = _getWhatsappUsers(location.users);

    final hasPhone = whatsappUsers.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // ====================================================
            // STATUS STRIPE
            // ====================================================
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 4, color: color),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(15, 13, 13, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =================================================
                  // MAIN ROW
                  // =================================================
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // =============================================
                      // STATUS ICON
                      // =============================================
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          location.statusIcon,
                          size: 19,
                          color: color,
                        ),
                      ),

                      const SizedBox(width: 11),

                      // =============================================
                      // LOCATION INFO
                      // =============================================
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    location.locationName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF20222E),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      height: 1.25,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 7),

                                _buildMaintenanceStatusBadge(location),
                              ],
                            ),

                            const SizedBox(height: 7),

                            Wrap(
                              spacing: 11,
                              runSpacing: 5,
                              children: [
                                _buildReminderMeta(
                                  icon: Iconsax.cpu,
                                  text: '${location.acCount} AC',
                                ),

                                if (location.roomCount > 0)
                                  _buildReminderMeta(
                                    icon: Iconsax.building,
                                    text: '${location.roomCount} ruang',
                                  ),

                                if (location.users.isNotEmpty)
                                  _buildReminderMeta(
                                    icon: Iconsax.people,
                                    text: '${location.users.length} PIC',
                                  ),
                              ],
                            ),

                            const SizedBox(height: 7),

                            // =======================================
                            // REMAINING STATUS
                            // =======================================
                            Row(
                              children: [
                                Icon(Iconsax.clock, size: 12, color: color),

                                const SizedBox(width: 5),

                                Expanded(
                                  child: Text(
                                    location.remainingLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // =============================================
                      // WHATSAPP
                      // =============================================
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (hasPhone) {
                              _showWhatsAppPicSheet(sourceGroup);
                            } else {
                              _showNoWhatsAppMessage();
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: hasPhone
                                  ? const Color(
                                      0xFF25D366,
                                    ).withValues(alpha: 0.09)
                                  : Colors.grey.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Iconsax.message,
                              size: 18,
                              color: hasPhone
                                  ? const Color(0xFF25D366)
                                  : Colors.grey[400],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 11),

                  // =================================================
                  // DATE INFORMATION
                  // =================================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildCompactDateInfo(
                            icon: Iconsax.calendar_1,
                            title: 'Terakhir',
                            value: location.lastServiceLabel,
                          ),
                        ),

                        Container(
                          width: 1,
                          height: 31,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          color: Colors.grey[200],
                        ),

                        Expanded(
                          child: _buildCompactDateInfo(
                            icon: Iconsax.calendar_tick,
                            title: 'Berikutnya',
                            value: location.nextServiceLabel,
                            valueColor: color,
                          ),
                        ),

                        const SizedBox(width: 7),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withValues(alpha: 0.065),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${location.intervalMonths} Bln',
                            style: const TextStyle(
                              color: kPrimaryColor,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildMaintenanceStatusBadge(MaintenanceReminderLocation location) {
    final color = location.statusColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            location.statusTitle,
            style: TextStyle(
              color: color,
              fontSize: 7.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // META INFO
  // ============================================================

  Widget _buildReminderMeta({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: const Color(0xFF9A9CA7)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF82848F),
            fontSize: 8,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // COMPACT DATE
  // ============================================================

  Widget _buildCompactDateInfo({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          width: 29,
          height: 29,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 13, color: Colors.grey[500]),
        ),

        const SizedBox(width: 7),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 7,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: valueColor ?? const Color(0xFF474955),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // WHATSAPP USERS
  // ============================================================

  List<UserModel> _getWhatsappUsers(List<UserModel> users) {
    return users.where((user) {
      final phone = (user.phone ?? '').trim();

      return phone.isNotEmpty;
    }).toList();
  }

  // ============================================================
  // WHATSAPP PIC SHEET
  // ============================================================

  Future<void> _showWhatsAppPicSheet(_MaintenanceLocationGroup group) async {
    final users = _getWhatsappUsers(group.users);

    if (users.isEmpty) {
      _showNoWhatsAppMessage();

      return;
    }

    if (users.length == 1) {
      await _openWhatsAppToUser(group: group, user: users.first);

      return;
    }

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(12),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.70,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),

                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 43,
                        height: 43,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF25D366,
                          ).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Iconsax.message,
                          color: Color(0xFF25D366),
                          size: 20,
                        ),
                      ),

                      const SizedBox(width: 11),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hubungi PIC',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 2),

                            Text(
                              group.locationName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF25D366,
                          ).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${users.length} PIC',
                          style: const TextStyle(
                            color: Color(0xFF25D366),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Pilih kontak yang ingin dihubungi',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                    itemCount: users.length,
                    separatorBuilder: (_, __) {
                      return const SizedBox(height: 8);
                    },
                    itemBuilder: (_, index) {
                      final user = users[index];

                      final name = (user.name ?? '').trim();

                      final email = (user.email ?? '').trim();

                      final phone = (user.phone ?? '').trim();

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            Navigator.pop(sheetContext);

                            await _openWhatsAppToUser(group: group, user: user);
                          },
                          borderRadius: BorderRadius.circular(15),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FC),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.grey[100]!),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: kPrimaryColor.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Iconsax.user,
                                    size: 19,
                                    color: kPrimaryColor,
                                  ),
                                ),

                                const SizedBox(width: 11),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name.isNotEmpty ? name : 'PIC',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),

                                      const SizedBox(height: 3),

                                      Text(
                                        phone,
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),

                                      if (email.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          email,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 8,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                Container(
                                  width: 37,
                                  height: 37,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF25D366,
                                    ).withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Iconsax.message,
                                    color: Color(0xFF25D366),
                                    size: 17,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // OPEN WHATSAPP
  // ============================================================

  Future<void> _openWhatsAppToUser({
    required _MaintenanceLocationGroup group,
    required UserModel user,
  }) async {
    final rawPhone = (user.phone ?? '').trim();

    if (rawPhone.isEmpty) {
      _showNoWhatsAppMessage();

      return;
    }

    final phone = _normalizeWhatsAppPhone(rawPhone);

    if (phone.isEmpty) {
      _showNoWhatsAppMessage();

      return;
    }

    final rawName = (user.name ?? '').trim();

    final greetingName = rawName.isNotEmpty ? rawName : 'Bapak/Ibu';

    final reminder = _convertToReminderLocation(group);

    final message =
        '''
Halo $greetingName,

Kami dari Ridho Teknik ingin menginformasikan jadwal perawatan rutin AC di lokasi *${group.locationName}*.

Interval perawatan: *${group.intervalMonths} bulan*
Servis terakhir: *${reminder.lastServiceLabel}*
Jadwal berikutnya: *${reminder.nextServiceLabel}*
Status saat ini: *${reminder.statusTitle}*
${reminder.remainingLabel}

Saat ini terdapat *${group.units.length} unit AC* yang tercatat dalam reminder perawatan.

Apakah kami dapat membantu menjadwalkan kunjungan servis rutin?

Terima kasih.
Ridho Teknik
AC Service Specialist
''';

    final uri = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showWhatsAppError();
      }
    } catch (_) {
      _showWhatsAppError();
    }
  }

  // ============================================================
  // NORMALIZE WA
  // ============================================================

  String _normalizeWhatsAppPhone(String input) {
    var phone = input.replaceAll(RegExp(r'[^0-9]'), '');

    if (phone.isEmpty) {
      return '';
    }

    if (phone.startsWith('0')) {
      phone = '62${phone.substring(1)}';
    } else if (phone.startsWith('8')) {
      phone = '62$phone';
    }

    return phone;
  }

  void _showWhatsAppError() {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Iconsax.close_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('WhatsApp tidak dapat dibuka.')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  void _showNoWhatsAppMessage() {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Iconsax.info_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Nomor WhatsApp PIC belum tersedia.')),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ============================================================
  // INTERVAL
  // ============================================================

  int _extractIntervalMonths(AcModel ac) {
    try {
      final map = _acToMap(ac);

      if (map.isEmpty) {
        return _defaultMaintenanceIntervalMonths;
      }

      final directCandidates = [
        map['service_interval_months'],
        map['maintenance_interval_months'],
        map['interval_months'],
        map['serviceIntervalMonths'],
        map['maintenanceIntervalMonths'],
        map['intervalServisBulan'],
        map['interval_servis_bulan'],
        map['service_interval'],
        map['maintenance_interval'],
      ];

      for (final candidate in directCandidates) {
        final parsed = _parsePositiveInt(candidate);

        if (parsed != null) {
          return parsed;
        }
      }

      final roomRaw = map['room'];

      if (roomRaw is Map) {
        final locationRaw = roomRaw['location'] ?? roomRaw['lokasi'];

        if (locationRaw is Map) {
          final candidates = [
            locationRaw['service_interval_months'],
            locationRaw['maintenance_interval_months'],
            locationRaw['interval_months'],
            locationRaw['interval_servis_bulan'],
          ];

          for (final candidate in candidates) {
            final parsed = _parsePositiveInt(candidate);

            if (parsed != null) {
              return parsed;
            }
          }
        }
      }
    } catch (_) {}

    return _defaultMaintenanceIntervalMonths;
  }

  int? _parsePositiveInt(dynamic value) {
    if (value == null) {
      return null;
    }

    final parsed = int.tryParse(value.toString());

    if (parsed == null || parsed <= 0) {
      return null;
    }

    return parsed;
  }

  // ============================================================
  // AC UNIQUE
  // ============================================================

  String _buildAcUniqueKey(AcModel ac) {
    final map = _acToMap(ac);

    final id = map['id'] ?? map['ac_unit_id'];

    if (id != null) {
      return 'id:$id';
    }

    final location = _extractLocationName(ac);

    final room = _extractRoomName(ac);

    return '$location|$room|${ac.nama}|${ac.merk}|${ac.type}';
  }

  // ============================================================
  // AC MAP
  // ============================================================

  Map<String, dynamic> _acToMap(AcModel ac) {
    try {
      final raw = ac.toJson();

      return Map<String, dynamic>.from(raw);
    } catch (_) {
      return {};
    }
  }

  // ============================================================
  // LOCATION ID
  // ============================================================

  int? _extractLocationId(AcModel ac) {
    if (ac.locationId > 0) {
      return ac.locationId;
    }

    final room = ac.room;

    if (room != null) {
      if (room.locationId > 0) {
        return room.locationId;
      }

      final location = room.location;

      if (location != null) {
        final parsed = int.tryParse(location.id.toString());

        if (parsed != null && parsed > 0) {
          return parsed;
        }
      }
    }

    return null;
  }

  // ============================================================
  // LOCATION NAME
  // ============================================================

  String _extractLocationName(AcModel ac) {
    final room = ac.room;

    if (room?.location != null) {
      final location = room!.location!;

      final map = location.toJson();

      final name = (map['name'] ?? map['nama'] ?? '').toString().trim();

      if (name.isNotEmpty) {
        return name;
      }
    }

    final map = _acToMap(ac);

    final roomRaw = map['room'];

    if (roomRaw is Map) {
      final locationRaw = roomRaw['location'];

      if (locationRaw is Map) {
        final value = (locationRaw['name'] ?? locationRaw['nama'] ?? '')
            .toString()
            .trim();

        if (value.isNotEmpty) {
          return value;
        }
      }
    }

    return 'Lokasi belum diketahui';
  }

  // ============================================================
  // ROOM NAME
  // ============================================================

  String _extractRoomName(AcModel ac) {
    final room = ac.room;

    if (room != null && room.name.trim().isNotEmpty) {
      return room.name.trim();
    }

    return '';
  }

  // ============================================================
  // LOCATION USERS
  // ============================================================

  List<UserModel> _extractLocationUsers(AcModel ac) {
    final room = ac.room;

    if (room?.location != null) {
      return room!.location!.users.where((user) {
        final role = (user.role ?? '').trim().toLowerCase();

        return role.isEmpty || role == 'client';
      }).toList();
    }

    return <UserModel>[];
  }

  // ============================================================
  // ROOM COUNT
  // ============================================================

  int _countUniqueRooms(List<AcModel> list) {
    final rooms = <String>{};

    for (final ac in list) {
      if (ac.roomId > 0) {
        rooms.add('id:${ac.roomId}');

        continue;
      }

      final room = _extractRoomName(ac);

      if (room.isNotEmpty) {
        rooms.add('name:$room');
      }
    }

    return rooms.length;
  }

  // ============================================================
  // OLDEST SERVICE DAYS
  // ============================================================

  int? _getOldestServiceDays(List<AcModel> units) {
    final date = _getOldestServiceDate(units);

    if (date == null) {
      return null;
    }

    final today = DateUtils.dateOnly(DateTime.now());

    final serviceDate = DateUtils.dateOnly(date.toLocal());

    return today.difference(serviceDate).inDays;
  }

  // ============================================================
  // OLDEST SERVICE DATE
  // ============================================================

  DateTime? _getOldestServiceDate(List<AcModel> units) {
    DateTime? oldest;

    for (final ac in units) {
      final date = ac.terakhirService;

      if (date == null) {
        continue;
      }

      if (oldest == null || date.isBefore(oldest)) {
        oldest = date;
      }
    }

    return oldest;
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.025)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.022),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color.withValues(alpha: 0.55), size: 24),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  message,
                  style: TextStyle(
                    fontSize: 9,
                    height: 1.4,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MAIN MENU MODEL
// ============================================================

class MainMenu {
  final IconData icon;
  final String title;
  final Color color;
  final String description;
  final List<Color> gradient;

  const MainMenu({
    required this.icon,
    required this.title,
    required this.color,
    required this.description,
    required this.gradient,
  });
}

// ============================================================
// MAINTENANCE LOCATION GROUP
// ============================================================

class _MaintenanceLocationGroup {
  final int? locationId;
  final String locationName;
  final int intervalMonths;

  final List<UserModel> users;
  final List<AcModel> units;

  _MaintenanceLocationGroup({
    required this.locationId,
    required this.locationName,
    required this.intervalMonths,
    required this.users,
    required this.units,
  });
}

// ============================================================
// PAIR UNTUK MENJAGA RELASI
//
// _MaintenanceLocationGroup:
// dipakai WhatsApp
//
// MaintenanceReminderLocation:
// dipakai status, warna, tanggal
// ============================================================

class _ReminderPair {
  final _MaintenanceLocationGroup group;

  final MaintenanceReminderLocation location;

  const _ReminderPair({required this.group, required this.location});
}
