// lib/pages/klien/servis_history_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridho_teknik/pages/klien/servis_detail_page.dart';
import 'package:ridho_teknik/pages/klien/widgets/app_card.dart';
import 'package:ridho_teknik/providers/client_servis_provider.dart';
import '../../models/servis_model.dart';
import '../../models/lokasi_model.dart';
import '../../theme/theme.dart';

class ServisHistoryPage extends StatefulWidget {
  final LokasiModel lokasi;
  const ServisHistoryPage({super.key, required this.lokasi});

  @override
  State<ServisHistoryPage> createState() => _ServisHistoryPageState();
}

class _ServisHistoryPageState extends State<ServisHistoryPage> {
  JenisPenanganan? _selectedJenis;
  ServisStatus? _selectedStatus;
  int _selectedTab = 0; // 0: semua, 1: diproses, 2: selesai, 3: ditolak

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('=== INIT STATE CALLED ===');
      print('Lokasi ID: ${widget.lokasi.id}');
      print('Lokasi Nama: ${widget.lokasi.nama}');
      print('========================');

      context.read<ClientServisProvider>().fetchServis(
      );
    });
  }

  // Method untuk mendapatkan filtered servis berdasarkan filter aktif
  List<ServisModel> _getFilteredServis(List<ServisModel> allServis) {
    print('=== GET FILTERED SERVIS ===');
    print('Total servis from provider: ${allServis.length}');

    // Filter pertama berdasarkan lokasi
    var filtered = allServis
        .where((servis) {
      print('Servis ID: ${servis.id}, Lokasi ID: ${servis.lokasiId}, Widget Lokasi ID: ${widget.lokasi.id}');
      print('Match: ${servis.lokasiId == widget.lokasi.id}');
      return servis.lokasiId == widget.lokasi.id;
    })
        .toList();

    print('After lokasi filter: ${filtered.length}');

    // Filter berdasarkan jenis jika dipilih
    if (_selectedJenis != null) {
      filtered = filtered.where((s) {
        print('Jenis filter: Servis jenis ${s.jenis} vs selected ${_selectedJenis}');
        return s.jenis == _selectedJenis;
      }).toList();
      print('After jenis filter: ${filtered.length}');
    }

    // Filter berdasarkan tab yang dipilih
    switch (_selectedTab) {
      case 1: // Diproses
        filtered = filtered.where((s) {
          print('Status filter Diproses: ${s.isInProgress}');
          return s.isInProgress;
        }).toList();
        break;
      case 2: // Selesai
        filtered = filtered.where((s) {
          print('Status filter Selesai: ${s.isCompleted}');
          return s.isCompleted;
        }).toList();
        break;
      case 3: // Ditolak
        filtered = filtered.where((s) {
          print('Status filter Ditolak: ${s.isRejected}');
          return s.isRejected;
        }).toList();
        break;
    }

    print('Final filtered count: ${filtered.length}');
    print('=============================');

    return filtered;
  }

  // Method untuk reset semua filter
  void _resetFilters() {
    setState(() {
      _selectedJenis = null;
      _selectedStatus = null;
      _selectedTab = 0;
    });
  }

  // Hitung jumlah filter aktif
  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedJenis != null) count++;
    if (_selectedStatus != null) count++;
    if (_selectedTab != 0) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    print('=== BUILD CALLED ===');

    return Consumer<ClientServisProvider>(
      builder: (context, prov, _) {
        print('Provider loading: ${prov.loading}');
        print('Provider error: ${prov.error}');
        print('Provider servisList length: ${prov.servisList.length}');

        // Debug print untuk semua servis
        for (var i = 0; i < prov.servisList.length; i++) {
          final servis = prov.servisList[i];
          print('Servis[$i]: ID=${servis.id}, LokasiID=${servis.lokasiId}, Status=${servis.status}');
        }

        if (prov.loading) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Riwayat Servis', style: titleWhiteTextStyle.copyWith(fontSize: 18)),
              backgroundColor: kPrimaryColor,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (prov.error != null) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Riwayat Servis', style: titleWhiteTextStyle.copyWith(fontSize: 18)),
              backgroundColor: kPrimaryColor,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: kBoxMenuRedColor),
                    const SizedBox(height: 16),
                    Text(
                      'Terjadi Kesalahan',
                      style: primaryTextStyle.copyWith(fontSize: 18, fontWeight: bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      prov.error!,
                      style: greyTextStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => prov.fetchServis(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text('Coba Lagi', style: whiteTextStyle),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final filteredServis = _getFilteredServis(prov.servisList);

        // Stats untuk semua data (tanpa filter)
        final allServisForStats = prov.servisList
            .where((servis) => servis.lokasiId == widget.lokasi.id)
            .toList();

        final cuciCount = allServisForStats.where((s) => s.jenis == JenisPenanganan.cuciAc).length;
        final perbaikanCount = allServisForStats.where((s) => s.jenis == JenisPenanganan.perbaikanAc).length;
        final instalasiCount = allServisForStats.where((s) => s.jenis == JenisPenanganan.instalasi).length;

        print('Stats: Total=${allServisForStats.length}, Cuci=$cuciCount, Perbaikan=$perbaikanCount, Instalasi=$instalasiCount');

        return Scaffold(
          appBar: AppBar(
            title: Text('Riwayat Servis', style: titleWhiteTextStyle.copyWith(fontSize: 18)),
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Reset filter button
              if (_getActiveFilterCount() > 0)
                IconButton(
                  icon: Icon(Icons.filter_alt_off, color: Colors.white),
                  onPressed: _resetFilters,
                  tooltip: 'Reset Filter',
                ),
            ],
          ),
          body: Column(
            children: [
              // Container untuk konten yang bisa discroll
              Expanded(
                child: Container(
                  color: kBackgroundColor,
                  child: CustomScrollView(
                    slivers: [
                      // Stats Cards dengan Jenis
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha:0.1), // Perbaikan: ganti .withValues(alpha:0.1)
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Ringkasan Servis',
                                    style: primaryTextStyle.copyWith(
                                      fontSize: 16,
                                      fontWeight: bold,
                                    ),
                                  ),
                                  // Info filter aktif
                                  if (_getActiveFilterCount() > 0)
                                    GestureDetector(
                                      onTap: _resetFilters,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: kPrimaryColor.withValues(alpha:0.1), // Perbaikan
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (_selectedTab != 0)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                margin: const EdgeInsets.only(right: 4),
                                                decoration: BoxDecoration(
                                                  color: _getTabColor(_selectedTab),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  _getTabText(_selectedTab),
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            if (_selectedJenis != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                margin: const EdgeInsets.only(right: 4),
                                                decoration: BoxDecoration(
                                                  color: _getJenisColor(_selectedJenis!),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(_getJenisIcon(_selectedJenis!), size: 10, color: Colors.white),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      _getJenisText(_selectedJenis!),
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            const SizedBox(width: 4),
                                            Icon(Icons.close, size: 14, color: kPrimaryColor),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildJenisStatCard(
                                    jenis: JenisPenanganan.cuciAc,
                                    count: cuciCount,
                                    total: allServisForStats.length,
                                    isSelected: _selectedJenis == JenisPenanganan.cuciAc,
                                  ),
                                  _buildJenisStatCard(
                                    jenis: JenisPenanganan.perbaikanAc,
                                    count: perbaikanCount,
                                    total: allServisForStats.length,
                                    isSelected: _selectedJenis == JenisPenanganan.perbaikanAc,
                                  ),
                                  _buildJenisStatCard(
                                    jenis: JenisPenanganan.instalasi,
                                    count: instalasiCount,
                                    total: allServisForStats.length,
                                    isSelected: _selectedJenis == JenisPenanganan.instalasi,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Filter Section
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header List dengan hasil filter
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _getListTitle(),
                                          style: primaryTextStyle.copyWith(
                                            fontSize: 16,
                                            fontWeight: bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Lokasi: ${widget.lokasi.nama}',
                                          style: greyTextStyle.copyWith(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: kPrimaryColor.withValues(alpha:0.1), // Perbaikan
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${filteredServis.length} servis',
                                      style: primaryTextStyle.copyWith(
                                        fontSize: 12,
                                        color: kPrimaryColor,
                                        fontWeight: bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Filter Container
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha:0.05), // Perbaikan
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Status Utama Dropdown
                                    Row(
                                      children: [
                                        Icon(Icons.filter_list, size: 16, color: kPrimaryColor),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Status:',
                                          style: primaryTextStyle.copyWith(
                                            fontSize: 13,
                                            fontWeight: medium,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Container(
                                            height: 36,
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[50],
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey[300]!),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<int>(
                                                value: _selectedTab,
                                                isExpanded: true,
                                                icon: Icon(Icons.arrow_drop_down, color: kGreyColor),
                                                style: primaryTextStyle.copyWith(fontSize: 13),
                                                items: [
                                                  DropdownMenuItem(
                                                    value: 0,
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.list, size: 16, color: kGreyColor),
                                                        const SizedBox(width: 8),
                                                        Text('Semua Status', style: primaryTextStyle.copyWith(fontSize: 13)),
                                                      ],
                                                    ),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 1,
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.hourglass_top, size: 16, color: Colors.orange),
                                                        const SizedBox(width: 8),
                                                        Text('Diproses', style: primaryTextStyle.copyWith(fontSize: 13)),
                                                      ],
                                                    ),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 2,
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.check_circle, size: 16, color: kBoxMenuGreenColor),
                                                        const SizedBox(width: 8),
                                                        Text('Selesai', style: primaryTextStyle.copyWith(fontSize: 13)),
                                                      ],
                                                    ),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 3,
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.cancel, size: 16, color: Colors.red),
                                                        const SizedBox(width: 8),
                                                        Text('Ditolak', style: primaryTextStyle.copyWith(fontSize: 13)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                                onChanged: (value) {
                                                  setState(() {
                                                    _selectedTab = value ?? 0;
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Jenis Servis - Grid satu baris kecil
                                    Text(
                                      'Jenis Servis:',
                                      style: primaryTextStyle.copyWith(
                                        fontSize: 13,
                                        fontWeight: medium,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 40,
                                      child: ListView(
                                        scrollDirection: Axis.horizontal,
                                        children: [
                                          // Semua Jenis
                                          Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedJenis = null;
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: _selectedJenis == null
                                                      ? kPrimaryColor.withValues(alpha:0.2) // Perbaikan
                                                      : Colors.grey[100],
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: _selectedJenis == null
                                                        ? kPrimaryColor
                                                        : Colors.grey[300]!,
                                                    width: _selectedJenis == null ? 1.5 : 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.all_inclusive,
                                                      size: 14,
                                                      color: _selectedJenis == null
                                                          ? kPrimaryColor
                                                          : Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Semua',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: _selectedJenis == null
                                                            ? kPrimaryColor
                                                            : Colors.grey[600],
                                                        fontWeight: _selectedJenis == null
                                                            ? FontWeight.w500
                                                            : FontWeight.normal,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),

                                          // Cuci
                                          Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedJenis = JenisPenanganan.cuciAc;
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: _selectedJenis == JenisPenanganan.cuciAc
                                                      ? Colors.blue.withValues(alpha:0.2) // Perbaikan
                                                      : Colors.grey[100],
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: _selectedJenis == JenisPenanganan.cuciAc
                                                        ? Colors.blue
                                                        : Colors.grey[300]!,
                                                    width: _selectedJenis == JenisPenanganan.cuciAc ? 1.5 : 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.clean_hands,
                                                      size: 14,
                                                      color: _selectedJenis == JenisPenanganan.cuciAc
                                                          ? Colors.blue
                                                          : Colors.blue.withValues(alpha:0.6), // Perbaikan
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Cuci',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: _selectedJenis == JenisPenanganan.cuciAc
                                                            ? Colors.blue
                                                            : Colors.blue.withValues(alpha:0.8), // Perbaikan
                                                        fontWeight: _selectedJenis == JenisPenanganan.cuciAc
                                                            ? FontWeight.w500
                                                            : FontWeight.normal,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),

                                          // Perbaikan
                                          Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedJenis = JenisPenanganan.perbaikanAc;
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: _selectedJenis == JenisPenanganan.perbaikanAc
                                                      ? Colors.orange.withValues(alpha:0.2) // Perbaikan
                                                      : Colors.grey[100],
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: _selectedJenis == JenisPenanganan.perbaikanAc
                                                        ? Colors.orange
                                                        : Colors.grey[300]!,
                                                    width: _selectedJenis == JenisPenanganan.perbaikanAc ? 1.5 : 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.build,
                                                      size: 14,
                                                      color: _selectedJenis == JenisPenanganan.perbaikanAc
                                                          ? Colors.orange
                                                          : Colors.orange.withValues(alpha:0.6), // Perbaikan
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Perbaikan',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: _selectedJenis == JenisPenanganan.perbaikanAc
                                                            ? Colors.orange
                                                            : Colors.orange.withValues(alpha:0.8), // Perbaikan
                                                        fontWeight: _selectedJenis == JenisPenanganan.perbaikanAc
                                                            ? FontWeight.w500
                                                            : FontWeight.normal,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),

                                          // Instalasi
                                          Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedJenis = JenisPenanganan.instalasi;
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: _selectedJenis == JenisPenanganan.instalasi
                                                      ? Colors.green.withValues(alpha:0.2) // Perbaikan
                                                      : Colors.grey[100],
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: _selectedJenis == JenisPenanganan.instalasi
                                                        ? Colors.green
                                                        : Colors.grey[300]!,
                                                    width: _selectedJenis == JenisPenanganan.instalasi ? 1.5 : 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.install_desktop,
                                                      size: 14,
                                                      color: _selectedJenis == JenisPenanganan.instalasi
                                                          ? Colors.green
                                                          : Colors.green.withValues(alpha:0.6), // Perbaikan
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Instalasi',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: _selectedJenis == JenisPenanganan.instalasi
                                                            ? Colors.green
                                                            : Colors.green.withValues(alpha:0.8), // Perbaikan
                                                        fontWeight: _selectedJenis == JenisPenanganan.instalasi
                                                            ? FontWeight.w500
                                                            : FontWeight.normal,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),

                      // List Servis
                      if (filteredServis.isEmpty)
                        SliverToBoxAdapter(
                          child: _buildEmptyState(),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              final servis = filteredServis[index];
                              print('Building servis card at index $index: ID=${servis.id}');
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ServisDetailPage(servis: servis),
                                      ),
                                    );
                                  },
                                  child: _ServisCard(servis: servis),
                                ),
                              );
                            },
                            childCount: filteredServis.length,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget untuk statistik jenis servis
  Widget _buildJenisStatCard({
    required JenisPenanganan jenis,
    required int count,
    required int total,
    required bool isSelected,
  }) {
    final percentage = total > 0 ? (count / total * 100).toInt() : 0;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedJenis = isSelected ? null : jenis;
        });
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected
                  ? _getJenisColor(jenis)
                  : _getJenisColor(jenis).withValues(alpha:0.1), // Perbaikan
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? _getJenisColor(jenis) : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(
              _getJenisIcon(jenis),
              color: isSelected ? Colors.white : _getJenisColor(jenis),
              size: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            count.toString(),
            style: primaryTextStyle.copyWith(
              fontSize: 16,
              fontWeight: bold,
              color: isSelected ? _getJenisColor(jenis) : null,
            ),
          ),
          Text(
            _getJenisText(jenis),
            style: greyTextStyle.copyWith(
              fontSize: 11,
              color: isSelected ? _getJenisColor(jenis) : _getJenisColor(jenis),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (percentage > 0)
            Text(
              '$percentage%',
              style: greyTextStyle.copyWith(
                fontSize: 9,
                color: isSelected ? _getJenisColor(jenis) : null,
              ),
            ),
        ],
      ),
    );
  }

  // Widget untuk empty state
  Widget _buildEmptyState() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 60,
            color: kGreyColor.withValues(alpha:0.5), // Perbaikan
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ditemukan servis',
            style: primaryTextStyle.copyWith(
              fontSize: 16,
              fontWeight: bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tidak ada servis yang sesuai dengan filter yang dipilih',
            style: greyTextStyle.copyWith(fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _resetFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.filter_alt_off, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text('Reset Filter', style: whiteTextStyle.copyWith(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getListTitle() {
    if (_selectedTab != 0) {
      switch (_selectedTab) {
        case 1: return 'Servis Diproses';
        case 2: return 'Servis Selesai';
        case 3: return 'Servis Ditolak';
      }
    }
    return 'Semua Servis';
  }

  String _getTabText(int tabIndex) {
    switch (tabIndex) {
      case 0: return 'Semua';
      case 1: return 'Diproses';
      case 2: return 'Selesai';
      case 3: return 'Ditolak';
      default: return '';
    }
  }

  Color _getTabColor(int tabIndex) {
    switch (tabIndex) {
      case 1: return Colors.orange;
      case 2: return kBoxMenuGreenColor;
      case 3: return Colors.red;
      default: return kPrimaryColor;
    }
  }

  // Helper methods
  String _getJenisText(JenisPenanganan? jenis) {
    if (jenis == null) return '';
    switch (jenis) {
      case JenisPenanganan.cuciAc:
        return 'Cuci';
      case JenisPenanganan.perbaikanAc:
        return 'Perbaikan';
      case JenisPenanganan.instalasi:
        return 'Instalasi';
    }
  }

  Color _getJenisColor(JenisPenanganan jenis) {
    switch (jenis) {
      case JenisPenanganan.cuciAc:
        return Colors.blue;
      case JenisPenanganan.perbaikanAc:
        return Colors.orange;
      case JenisPenanganan.instalasi:
        return Colors.green;
    }
  }

  IconData _getJenisIcon(JenisPenanganan jenis) {
    switch (jenis) {
      case JenisPenanganan.cuciAc:
        return Icons.clean_hands;
      case JenisPenanganan.perbaikanAc:
        return Icons.build;
      case JenisPenanganan.instalasi:
        return Icons.install_desktop;
    }
  }
}

// ==================== SERVIS CARD ====================
class _ServisCard extends StatelessWidget {
  final ServisModel servis;

  const _ServisCard({required this.servis});

  @override
  Widget build(BuildContext context) {
    print('=== BUILDING SERVIS CARD ===');
    print('Servis ID: ${servis.id}');
    print('Lokasi Nama: ${servis.lokasiNama}');
    print('AC Nama: ${servis.acNama}');
    print('Status: ${servis.status}');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05), // Perbaikan
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan Jenis, Status, dan Invoice
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Jenis Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: servis.jenisColor.withValues(alpha:0.1), // Perbaikan
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: servis.jenisColor.withValues(alpha:0.3)), // Perbaikan
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(servis.jenisIcon, size: 11, color: servis.jenisColor),
                      const SizedBox(width: 3),
                      Text(
                        servis.jenisDisplay,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: servis.jenisColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Invoice Badge (jika ada)
                if (servis.noInvoice != null && servis.noInvoice!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha:0.1), // Perbaikan
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.purple.withValues(alpha:0.3)), // Perbaikan
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt, size: 9, color: Colors.purple),
                        const SizedBox(width: 3),
                        Text(
                          servis.noInvoice!,
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Info Servis Utama
            Row(
              children: [
                // ID Servis
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.tag, size: 13, color: Colors.grey),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Servis #${servis.id}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: servis.statusColor.withValues(alpha:0.1), // Perbaikan
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(servis.status),
                        size: 11,
                        color: servis.statusColor,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        servis.statusDisplay,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: servis.statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // INFO LOKASI & AC
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha:0.03), // Perbaikan
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha:0.1)), // Perbaikan
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lokasi
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 13, color: kPrimaryColor),
                            const SizedBox(width: 6),
                            Text(
                              'Lokasi',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          servis.lokasiNama,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          servis.lokasiAlamat,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // AC Unit
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.ac_unit, size: 13, color: kSecondaryColor),
                            const SizedBox(width: 6),
                            Text(
                              'AC Unit',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          servis.acNama,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${servis.acMerk} • ${servis.acKapasitas}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // FOOTER: TANGGAL & BIAYA
            Row(
              children: [
                // Tanggal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 11, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Ditugaskan:',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(servis.tanggalDitugaskan),
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      if (servis.tanggalSelesai != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, size: 11, color: kBoxMenuGreenColor),
                              const SizedBox(width: 4),
                              Text(
                                'Selesai: ${_formatDate(servis.tanggalSelesai!)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: kBoxMenuGreenColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Biaya
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: kBoxMenuGreenColor.withValues(alpha:0.1), // Perbaikan
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.attach_money, size: 13, color: kBoxMenuGreenColor),
                          const SizedBox(width: 3),
                          Text(
                            servis.formattedTotalBiaya,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: kBoxMenuGreenColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // View Details Button
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Tap untuk detail →',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(ServisStatus status) {
    switch (status) {
      case ServisStatus.ditugaskan:
        return Icons.assignment;
      case ServisStatus.dalam_perjalanan:
        return Icons.directions_car;
      case ServisStatus.tiba_di_lokasi:
        return Icons.location_on;
      case ServisStatus.sedang_diperiksa:
        return Icons.search;
      case ServisStatus.dalam_perbaikan:
        return Icons.build;
      case ServisStatus.menunggu_suku_cadang:
        return Icons.inventory;
      case ServisStatus.selesai:
        return Icons.check_circle;
      case ServisStatus.ditolak:
        return Icons.cancel;
      case ServisStatus.menunggu_konfirmasi:
        return Icons.hourglass_empty;
      case ServisStatus.dikerjakan:
        // TODO: Handle this case.
        throw UnimplementedError();
      case ServisStatus.batal:
        // TODO: Handle this case.
        throw UnimplementedError();
      case ServisStatus.menunggu_konfirmasi_owner:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  String _formatDate(DateTime date) {
    try {
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      print('Error formatting date: $e');
      return 'N/A';
    }
  }
}