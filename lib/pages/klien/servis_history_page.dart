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
  ServisStatus? _selectedTabStatus; // ✅ ini tab status
// kalau gak dipakai boleh hapus

  // ✅ helper: normalisasi id ke int agar perbandingan selalu match
  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return int.tryParse(v.toString());
  }

  int get _lokasiId => _asInt(widget.lokasi.id) ?? -1;

  Widget _statusChip({
    required String label,
    required ServisStatus? value, // null = semua
    required IconData icon,
    required Color color,
  }) {
    final selected = _selectedTabStatus == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabStatus = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.18) : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color : Colors.grey[300]!,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: selected ? color : color.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? color : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✅ lebih aman: ambil servis khusus lokasi ini (kalau backend mendukung)
      context.read<ClientServisProvider>().fetchServis(
        // lokasiId: widget.lokasi.id.toString(),
      );
    });
  }

  List<ServisModel> _getFilteredServis(List<ServisModel> allServis) {
    var filtered = List<ServisModel>.from(allServis);

    // ✅ filter status (tab)
    if (_selectedTabStatus != null) {
      filtered = filtered.where((s) => s.status == _selectedTabStatus).toList();
    }

    // ✅ filter jenis (dropdown)
    if (_selectedJenis != null) {
      filtered = filtered.where((s) => s.jenis == _selectedJenis).toList();
    }

    filtered.sort((a, b) {
      final da = a.tanggalDitugaskan;
      final db = b.tanggalDitugaskan;
      return db.compareTo(da);
    });

    return filtered;
  }


  void _resetFilters() {
    setState(() {
      _selectedJenis = null;
      _selectedTabStatus = null;
// kalau gak kepakai, hapus field ini sekalian
    });
  }


  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedJenis != null) count++;
    if (_selectedTabStatus != null) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ClientServisProvider>(
      builder: (context, prov, _) {
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
                    Text(prov.error!, style: greyTextStyle, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => prov.fetchServis(lokasiId: widget.lokasi.id.toString()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

        // ✅ stats pakai cara yang sama (int compare)
        final allServisForStats = prov.servisList.where((s) => _asInt(s.lokasiId) == _lokasiId).toList();

        final cuciCount = allServisForStats.where((s) => s.jenis == JenisPenanganan.cuciAc).length;
        final perbaikanCount = allServisForStats.where((s) => s.jenis == JenisPenanganan.perbaikanAc).length;
        final instalasiCount = allServisForStats.where((s) => s.jenis == JenisPenanganan.instalasi).length;

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
              if (_getActiveFilterCount() > 0)
                IconButton(
                  icon: const Icon(Icons.filter_alt_off, color: Colors.white),
                  onPressed: _resetFilters,
                  tooltip: 'Reset Filter',
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: Container(
                  color: kBackgroundColor,
                  child: CustomScrollView(
                    slivers: [
                      // Stats
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
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
                                    style: primaryTextStyle.copyWith(fontSize: 16, fontWeight: bold),
                                  ),
                                  if (_getActiveFilterCount() > 0)
                                    GestureDetector(
                                      onTap: _resetFilters,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: kPrimaryColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
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
                                                      style: const TextStyle(fontSize: 10, color: Colors.white),
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

                      // Filters
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _getListTitle(),
                                          style: primaryTextStyle.copyWith(fontSize: 16, fontWeight: bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text('Lokasi: ${widget.lokasi.nama}', style: greyTextStyle.copyWith(fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: kPrimaryColor.withValues(alpha: 0.1),
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

                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Tab status
                                    // ✅ Jenis Servis (Dropdown) - TARUH DI ATAS
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.category, size: 16, color: kPrimaryColor),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Jenis Servis:',
                                              style: primaryTextStyle.copyWith(fontSize: 13, fontWeight: medium),
                                            ),
                                          ],
                                        ),
                                        SizedBox(width: 10,),
                                        Expanded(
                                          child: Container(
                                            height: 42,
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[50],
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey[300]!),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<JenisPenanganan?>(
                                                value: _selectedJenis,
                                                isExpanded: true,
                                                icon: Icon(Icons.arrow_drop_down, color: kGreyColor),
                                                style: primaryTextStyle.copyWith(fontSize: 13),
                                                items: const [
                                                  DropdownMenuItem(value: null, child: Text('Semua Jenis')),
                                                  DropdownMenuItem(value: JenisPenanganan.cuciAc, child: Text('Cuci')),
                                                  DropdownMenuItem(value: JenisPenanganan.perbaikanAc, child: Text('Perbaikan')),
                                                  DropdownMenuItem(value: JenisPenanganan.instalasi, child: Text('Instalasi')),
                                                ],
                                                onChanged: (v) => setState(() => _selectedJenis = v),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),



                                    const SizedBox(height: 14),

                                    Row(
                                      children: [
                                        Icon(Icons.filter_list, size: 16, color: kPrimaryColor),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Status:',
                                          style: primaryTextStyle.copyWith(fontSize: 13, fontWeight: medium),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    SizedBox(
                                      height: 40,
                                      child: ListView(
                                        scrollDirection: Axis.horizontal,
                                        children: [
                                          _statusChip(label: 'Semua', value: null, icon: Icons.all_inclusive, color: kPrimaryColor),
                                          _statusChip(label: 'Menunggu', value: ServisStatus.menunggu_konfirmasi, icon: Icons.hourglass_empty, color: Colors.orange),
                                          _statusChip(label: 'Ditugaskan', value: ServisStatus.ditugaskan, icon: Icons.assignment, color: Colors.blue),
                                          _statusChip(label: 'Dikerjakan', value: ServisStatus.dikerjakan, icon: Icons.play_circle_fill, color: Colors.purple),
                                          _statusChip(label: 'Selesai', value: ServisStatus.selesai, icon: Icons.check_circle, color: kBoxMenuGreenColor),
                                          _statusChip(label: 'Batal', value: ServisStatus.batal, icon: Icons.cancel, color: Colors.red),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 12),


                                    // SizedBox(
                                    //   height: 40,
                                    //   child: ListView(
                                    //     scrollDirection: Axis.horizontal,
                                    //     children: [
                                    //       _jenisChip(
                                    //         label: 'Semua',
                                    //         icon: Icons.all_inclusive,
                                    //         color: kPrimaryColor,
                                    //         selected: _selectedJenis == null,
                                    //         onTap: () => setState(() => _selectedJenis = null),
                                    //       ),
                                    //       _jenisChip(
                                    //         label: 'Cuci',
                                    //         icon: Icons.clean_hands,
                                    //         color: Colors.blue,
                                    //         selected: _selectedJenis == JenisPenanganan.cuciAc,
                                    //         onTap: () => setState(() => _selectedJenis = JenisPenanganan.cuciAc),
                                    //       ),
                                    //       _jenisChip(
                                    //         label: 'Perbaikan',
                                    //         icon: Icons.build,
                                    //         color: Colors.orange,
                                    //         selected: _selectedJenis == JenisPenanganan.perbaikanAc,
                                    //         onTap: () => setState(() => _selectedJenis = JenisPenanganan.perbaikanAc),
                                    //       ),
                                    //       _jenisChip(
                                    //         label: 'Instalasi',
                                    //         icon: Icons.install_desktop,
                                    //         color: Colors.green,
                                    //         selected: _selectedJenis == JenisPenanganan.instalasi,
                                    //         onTap: () => setState(() => _selectedJenis = JenisPenanganan.instalasi),
                                    //       ),
                                    //     ],
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // List
                      if (filteredServis.isEmpty)
                        SliverToBoxAdapter(child: _buildEmptyState())
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              final servis = filteredServis[index];
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => ServisDetailPage(servis: servis)),
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


  Widget _buildJenisStatCard({
    required JenisPenanganan jenis,
    required int count,
    required int total,
    required bool isSelected,
  }) {
    final percentage = total > 0 ? (count / total * 100).toInt() : 0;

    return GestureDetector(
      onTap: () => setState(() => _selectedJenis = isSelected ? null : jenis),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? _getJenisColor(jenis) : _getJenisColor(jenis).withValues(alpha: 0.1),
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

  Widget _buildEmptyState() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: kGreyColor.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Tidak ditemukan servis',
            style: primaryTextStyle.copyWith(fontSize: 16, fontWeight: bold),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.filter_alt_off, size: 16, color: Colors.white),
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
    switch (_selectedTabStatus) {
      case ServisStatus.menunggu_konfirmasi:
        return 'Menunggu Konfirmasi';
      case ServisStatus.ditugaskan:
        return 'Ditugaskan';
      case ServisStatus.dikerjakan:
        return 'Sedang Dikerjakan';
      case ServisStatus.selesai:
        return 'Selesai';
      case ServisStatus.batal:
        return 'Batal';
      default:
        return 'Semua Servis';
    }
  }



  String _getJenisText(JenisPenanganan jenis) {
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            // Header (jenis + status)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: servis.jenisColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: servis.jenisColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(servis.jenisIcon, size: 11, color: servis.jenisColor),
                      const SizedBox(width: 3),
                      Text(
                        servis.jenisDisplay,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: servis.jenisColor),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: servis.statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getStatusIcon(servis.status), size: 11, color: servis.statusColor),
                      const SizedBox(width: 3),
                      Text(
                        servis.statusDisplay,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: servis.statusColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ID + Teknisi ringkas
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.tag, size: 13, color: Colors.grey),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Servis #${servis.id}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 12, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        servis.techniciansShortDisplay,
                        style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Lokasi & AC
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
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
                          children: const [
                            Icon(Icons.location_on, size: 13, color: kPrimaryColor),
                            SizedBox(width: 6),
                            Text('Lokasi', style: TextStyle(fontSize: 9, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          servis.lokasiNama,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          servis.lokasiAlamat,
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // AC
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.ac_unit, size: 13, color: kSecondaryColor),
                            SizedBox(width: 6),
                            Text('AC Unit', style: TextStyle(fontSize: 9, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          servis.acDisplay,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          (servis.jumlahAc != null && servis.jumlahAc! > 0)
                              ? '${servis.jumlahAc} unit'
                              : (servis.acUnitsNames.isNotEmpty ? '${servis.acUnitsNames.length} unit' : '-'),
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Footer: tanggal & biaya
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 11, color: Colors.grey),
                      const SizedBox(width: 4),
                      const Text('Dibuat:', style: TextStyle(fontSize: 9, color: Colors.grey)),
                      const SizedBox(width: 4),
                      Text(_formatDate(servis.tanggalDitugaskan), style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: kBoxMenuGreenColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_money, size: 13, color: kBoxMenuGreenColor),
                      const SizedBox(width: 3),
                      Text(
                        servis.formattedTotalBiaya,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kBoxMenuGreenColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Tap untuk detail →',
                style: TextStyle(fontSize: 9, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(ServisStatus status) {
    switch (status) {
      case ServisStatus.menunggu_konfirmasi:
        return Icons.hourglass_empty;
      case ServisStatus.ditugaskan:
        return Icons.assignment;
      case ServisStatus.dikerjakan:
        return Icons.play_circle_fill;
      case ServisStatus.selesai:
        return Icons.check_circle;
      case ServisStatus.batal:
        return Icons.cancel;

    // legacy
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
      case ServisStatus.ditolak:
        return Icons.block;
      case ServisStatus.menunggu_konfirmasi_owner:
        return Icons.hourglass_bottom;
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
