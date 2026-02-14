// lib/pages/klien/klien_page.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ridho_teknik/pages/klien/widgets/empty_state.dart';
import 'package:ridho_teknik/pages/klien/widgets/modern_lokasi_card.dart';
import '../../models/lokasi_model.dart';
import '../../providers/client_master_provider.dart';
import '../../theme/theme.dart';
import 'ac_list_page.dart';
import 'lokasi_form_dialog.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class KlienPage extends StatefulWidget {
  const KlienPage({super.key});

  @override
  State<KlienPage> createState() => _KlienPageState();
}

class _KlienPageState extends State<KlienPage> {
  // Untuk search
  final TextEditingController _searchController = TextEditingController();
  List<LokasiModel> _filteredLokasi = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // fetch data API setelah build pertama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientMasterProvider>().fetchLokasi();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    final provider = context.read<ClientMasterProvider>();

    final list = provider.lokasi;
    setState(() {
      _filteredLokasi = list.where((lokasi) {
        return lokasi.nama.toLowerCase().contains(query) ||
            lokasi.alamat.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _openForm({LokasiModel? lokasi}) async {
    final result = await showModalBottomSheet<LokasiModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LokasiFormDialog(initial: lokasi),
    );

    if (result == null) return;

    setState(() {
      final index = _filteredLokasi.indexWhere((e) => e.id == result.id);
      if (index >= 0) {
        _filteredLokasi[index] = result;
        _showSnackBar('Lokasi berhasil diperbarui', kBoxMenuGreenColor);
      } else {
        _filteredLokasi.add(result);
        _showSnackBar('Lokasi berhasil ditambahkan', kBoxMenuGreenColor);
      }
      _onSearchChanged();
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: whiteTextStyle.copyWith(fontWeight: medium)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _getNamaUser(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final name = auth.user?.name?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Klien';
  }

  Widget _buildHeaderStats() {
    // Access the list of locations from the provider
    final lokasiList = context.watch<ClientMasterProvider>().lokasi;

    // Return an empty state or something else if lokasiList is empty
    if (lokasiList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kPrimaryColor, Color(0xFF5D6BC0)],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, ${_getNamaUser(context)}!',
                      style: whiteTextStyle.copyWith(
                        fontSize: 16,
                        fontWeight: bold,
                      ),
                    ),
                    Text(
                      'Kelola lokasi dan AC Anda',
                      style: whiteTextStyle.copyWith(
                        fontSize: 12,
                        fontWeight: regular,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _confirmLogout(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.logout_1,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari lokasi...',
                  hintStyle: greyTextStyle,
                  prefixIcon: Icon(Icons.search, color: kPrimaryColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Display a message or empty state if there are no locations
            Text(
              'Belum ada lokasi',
              style: whiteTextStyle.copyWith(fontSize: 16, fontWeight: bold),
            ),
          ],
        ),
      );
    }

    // Return the actual stats when lokasiList is not empty
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryColor, Color(0xFF5D6BC0)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, ${_getNamaUser(context)}!',
                    style: whiteTextStyle.copyWith(
                      fontSize: 16,
                      fontWeight: bold,
                    ),
                  ),
                  Text(
                    'Kelola lokasi dan AC Anda',
                    style: whiteTextStyle.copyWith(
                      fontSize: 12,
                      fontWeight: regular,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _confirmLogout(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari lokasi...',
                hintStyle: greyTextStyle,
                prefixIcon: Icon(Icons.search, color: kPrimaryColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Stats Cards
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Lokasi',
                  value: lokasiList.length.toString(),
                  icon: Icons.location_city_rounded,
                  color: Colors.white,
                  bgColor: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  title: 'Total AC',
                  value: lokasiList.fold(0, (sum, lokasi) => sum + lokasi.jumlahAC).toString(),
                  icon: Icons.ac_unit_rounded,
                  color: Colors.white,
                  bgColor: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  title: 'Aktif',
                  value: lokasiList.where((l) =>
                      l.lastService.isAfter(DateTime.now().subtract(const Duration(days: 30)))
                  ).length.toString(),
                  icon: Icons.check_circle_rounded,
                  color: Colors.white,
                  bgColor: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: whiteTextStyle.copyWith(
                fontSize: 18,
                fontWeight: bold,
              ),
            ),
            Text(
              title,
              style: whiteTextStyle.copyWith(
                fontSize: 10,
                color: Colors.white.withValues(alpha:0.8),
              ),
            ),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header dengan gradient
            _buildHeaderStats(),

            // Content
            Expanded(
              child: Consumer<ClientMasterProvider>(
                builder: (context, prov, _) {
                  if (prov.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (prov.error != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          prov.error!,
                          style: greyTextStyle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  // pastikan filtered mengikuti data provider kalau search kosong
                  final listToShow = _searchController.text.isEmpty ? prov.lokasi : _filteredLokasi;

                  if (listToShow.isEmpty) {
                    return EmptyState(
                      icon: Icons.location_on_outlined,
                      title: _searchController.text.isEmpty ? 'Belum Ada Lokasi' : 'Lokasi Tidak Ditemukan',
                      subtitle: _searchController.text.isEmpty
                          ? 'Belum ada lokasi dari server'
                          : 'Coba dengan kata kunci lain',
                      actionText: 'Refresh',
                      onAction: () async {
                        await context.read<ClientMasterProvider>().fetchLokasi();
                        _onSearchChanged();
                      },
                      iconColor: kPrimaryColor,
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Semua Lokasi',
                              style: primaryTextStyle.copyWith(fontSize: 14, fontWeight: bold),
                            ),
                            Text(
                              '${listToShow.length} ditemukan',
                              style: greyTextStyle.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.only(bottom: 20),
                            itemCount: listToShow.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final lokasi = listToShow[index];
                              return ModernLokasiCard(
                                lokasi: lokasi,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => AcListPage(lokasi: lokasi)),
                                  );
                                },
                                // NOTE: client belum punya CRUD lokasi di API
                                onEdit: () => _openForm(lokasi: lokasi),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
