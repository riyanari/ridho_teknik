// lib/pages/klien/klien_page.dart
import 'package:flutter/material.dart';
import 'package:ridho_teknik/pages/klien/widgets/empty_state.dart';
import 'package:ridho_teknik/pages/klien/widgets/modern_lokasi_card.dart';
import '../../models/lokasi_model.dart';
import '../../theme/theme.dart';
import 'ac_list_page.dart';
import 'lokasi_form_dialog.dart';

class KlienPage extends StatefulWidget {
  const KlienPage({super.key});

  @override
  State<KlienPage> createState() => _KlienPageState();
}

class _KlienPageState extends State<KlienPage> {
  final List<LokasiModel> lokasiList = [
    LokasiModel(
      id: 'L1',
      nama: 'Rumah Pak Budi',
      alamat: 'Jl. Sudirman No. 123, Jakarta Pusat',
      jumlahAC: 3,
      lastService: DateTime.now().subtract(const Duration(days: 15)),
    ),
    LokasiModel(
      id: 'L2',
      nama: 'Toko Bu Ani',
      alamat: 'Jl. Ahmad Yani No. 45, Bekasi Barat',
      jumlahAC: 2,
      lastService: DateTime.now().subtract(const Duration(days: 45)),
    ),
    LokasiModel(
      id: 'L3',
      nama: 'Kantor PT Maju Jaya',
      alamat: 'Gedung Graha, Lantai 8, Jakarta Selatan',
      jumlahAC: 5,
      lastService: DateTime.now().subtract(const Duration(days: 60)),
    ),
  ];

  // Untuk search
  final TextEditingController _searchController = TextEditingController();
  List<LokasiModel> _filteredLokasi = [];

  @override
  void initState() {
    super.initState();
    _filteredLokasi = lokasiList;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLokasi = lokasiList.where((lokasi) {
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
      final index = lokasiList.indexWhere((e) => e.id == result.id);
      if (index >= 0) {
        lokasiList[index] = result;
        _showSnackBar('Lokasi berhasil diperbarui', kBoxMenuGreenColor);
      } else {
        lokasiList.add(result);
        _showSnackBar('Lokasi berhasil ditambahkan', kBoxMenuGreenColor);
      }
      _onSearchChanged();
    });
  }

  void _deleteLokasi(LokasiModel lokasi) {
    showDialog(
      context: context,
      builder: (_) => _deleteDialog(lokasi),
    );
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

  Widget _deleteDialog(LokasiModel lokasi) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: kWhiteColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kBoxMenuRedColor, Colors.red[700]!],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Hapus Lokasi?',
              style: primaryTextStyle.copyWith(fontSize: 20, fontWeight: bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Lokasi "${lokasi.nama}" akan dihapus permanen. Tindakan ini tidak dapat dibatalkan.',
              style: greyTextStyle.copyWith(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: kGreyColor.withValues(alpha:0.5)),
                    ),
                    child: Text('Batal', style: blackTextStyle.copyWith(fontWeight: medium)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => lokasiList.removeWhere((e) => e.id == lokasi.id));
                      Navigator.pop(context);
                      _onSearchChanged();
                      _showSnackBar('Lokasi berhasil dihapus', kBoxMenuRedColor);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBoxMenuRedColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text('Hapus', style: whiteTextStyle.copyWith(fontWeight: bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStats() {
    final totalAC = lokasiList.fold(0, (sum, lokasi) => sum + lokasi.jumlahAC);
    final activeLocations = lokasiList.where((l) =>
        l.lastService.isAfter(DateTime.now().subtract(const Duration(days: 30)))
    ).length;

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
            color: kPrimaryColor.withValues(alpha:0.3),
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
                    'Halo, Klien!',
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
                      color: Colors.white.withValues(alpha:0.8),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 24,
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
                  color: Colors.black.withValues(alpha:0.1),
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
                  bgColor: Colors.white.withValues(alpha:0.2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  title: 'Total AC',
                  value: totalAC.toString(),
                  icon: Icons.ac_unit_rounded,
                  color: Colors.white,
                  bgColor: Colors.white.withValues(alpha:0.2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  title: 'Aktif',
                  value: activeLocations.toString(),
                  icon: Icons.check_circle_rounded,
                  color: Colors.white,
                  bgColor: Colors.white.withValues(alpha:0.2),
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
              child: _filteredLokasi.isEmpty
                  ? EmptyState(
                icon: Icons.location_on_outlined,
                title: _searchController.text.isEmpty
                    ? 'Belum Ada Lokasi'
                    : 'Lokasi Tidak Ditemukan',
                subtitle: _searchController.text.isEmpty
                    ? 'Tambahkan lokasi pertama Anda untuk mengelola AC'
                    : 'Coba dengan kata kunci lain',
                actionText: 'Tambah Lokasi',
                onAction: () => _openForm(),
                iconColor: kPrimaryColor,
              )
                  : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Semua Lokasi',
                          style: primaryTextStyle.copyWith(
                            fontSize: 14,
                            fontWeight: bold,
                          ),
                        ),
                        Text(
                          '${_filteredLokasi.length} ditemukan',
                          style: greyTextStyle.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: _filteredLokasi.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final lokasi = _filteredLokasi[index];
                          return ModernLokasiCard(
                            lokasi: lokasi,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AcListPage(lokasi: lokasi),
                                ),
                              );
                            },
                            onEdit: () => _openForm(lokasi: lokasi),
                            onDelete: () => _deleteLokasi(lokasi),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: kSecondaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}