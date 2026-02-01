// lib/pages/teknisi/teknisi_ac_list_page.dart
import 'package:flutter/material.dart';
import '../../models/ac_model.dart';
import '../../models/keluhan_model.dart';
import '../../models/lokasi_model.dart';
import '../../models/servis_model.dart';
import '../../models/teknisi_model.dart';
import '../../theme/theme.dart';
import 'teknisi_servis_detail_page.dart';
import 'package:ridho_teknik/extensions/servis_extensions.dart';

class TeknisiAcListPage extends StatefulWidget {
  final TeknisiModel teknisi;
  final LokasiModel lokasi;
  const TeknisiAcListPage({super.key, required this.teknisi, required this.lokasi});

  @override
  State<TeknisiAcListPage> createState() => _TeknisiAcListPageState();
}

class _TeknisiAcListPageState extends State<TeknisiAcListPage> {
  final List<AcModel> _acList = [
    AcModel(
      id: 'A1',
      lokasiId: 'L1',
      nama: 'AC Split 1 PK - Ruang Tamu',
      merk: 'Daikin',
      type: 'FTKN50',
      kapasitas: '1 PK',
      terakhirService: DateTime.now().subtract(const Duration(days: 30)),
    ),
    AcModel(
      id: 'A2',
      lokasiId: 'L1',
      nama: 'AC Kamar 0.5 PK',
      merk: 'Panasonic',
      type: 'CS-EN5',
      kapasitas: '0.5 PK',
      terakhirService: DateTime.now().subtract(const Duration(days: 90)),
    ),
  ];

  final List<KeluhanModel> _keluhanList = [
    KeluhanModel(
      id: 'K1',
      lokasiId: 'L1',
      acId: 'A1',
      judul: 'AC Tidak Dingin',
      deskripsi: 'AC tidak dingin meski suhu minimum',
      status: KeluhanStatus.diproses,
      prioritas: Prioritas.tinggi,
      tanggalDiajukan: DateTime.now().subtract(const Duration(days: 1)),
      assignedTo: 'T1',
    ),
    KeluhanModel(
      id: 'K2',
      lokasiId: 'L1',
      acId: 'A2',
      judul: 'AC Berisik',
      deskripsi: 'Suara berisik dari unit outdoor',
      status: KeluhanStatus.diproses,
      prioritas: Prioritas.sedang,
      tanggalDiajukan: DateTime.now().subtract(const Duration(days: 2)),
      assignedTo: 'T1',
    ),
  ];

  final List<ServisModel> _servisList = [
    ServisModel(
      id: 'SRV1',
      keluhanId: 'K1',
      lokasiId: 'L1',
      acId: 'A1',
      teknisiId: 'T1',
      status: ServisStatus.dalamPerjalanan,
      tindakan: [TindakanServis.pembersihan, TindakanServis.isiFreon],
      tanggalDitugaskan: DateTime.now().subtract(const Duration(hours: 2)),
      biayaServis: 250000,
      biayaSukuCadang: 150000,
    ),
    ServisModel(
      id: 'SRV2',
      keluhanId: 'K2',
      lokasiId: 'L1',
      acId: 'A2',
      teknisiId: 'T1',
      status: ServisStatus.ditugaskan,
      tanggalDitugaskan: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  List<AcModel> get _acDitugaskan {
    final acIds = _servisList
        .where((s) => s.lokasiId == widget.lokasi.id && s.teknisiId == widget.teknisi.id)
        .map((s) => s.acId)
        .toSet();

    return _acList
        .where((ac) => acIds.contains(ac.id))
        .toList();
  }

  ServisModel? getServisByAcId(String acId) {
    final idx = _servisList.indexWhere(
          (s) => s.acId == acId &&
          s.lokasiId == widget.lokasi.id &&
          s.teknisiId == widget.teknisi.id,
    );
    if (idx == -1) return null;
    return _servisList[idx];
  }

  KeluhanModel? getKeluhanByAcId(String acId) {
    final idx = _keluhanList.indexWhere(
          (k) => k.acId == acId &&
          k.lokasiId == widget.lokasi.id &&
          k.assignedTo == widget.teknisi.id,
    );
    if (idx == -1) return null;
    return _keluhanList[idx];
  }

  Widget _buildHeader() {
    final totalAC = _acDitugaskan.length;
    final acDalamPerbaikan = _acDitugaskan.where((ac) {
      final servis = getServisByAcId(ac.id);
      if (servis == null) return false;
      return servis.status.index >= ServisStatus.tibaDiLokasi.index &&
          servis.status.index < ServisStatus.selesai.index;
    }).length;

    final acMenunggu = _acDitugaskan.where((ac) {
      final servis = getServisByAcId(ac.id);
      return servis?.status == ServisStatus.menungguKonfirmasi;
    }).length;


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
          // Back button and title
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.lokasi.nama,
                      style: whiteTextStyle.copyWith(
                        fontSize: 16,
                        fontWeight: bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AC yang perlu ditangani',
                      style: whiteTextStyle.copyWith(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha:0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats Cards
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
                  title: 'Dalam Perbaikan',
                  value: acDalamPerbaikan.toString(),
                  icon: Icons.build_rounded,
                  color: Colors.white,
                  bgColor: Colors.white.withValues(alpha:0.2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  title: 'Menunggu',
                  value: acMenunggu.toString(),
                  icon: Icons.hourglass_top_rounded,
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
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: whiteTextStyle.copyWith(
              fontSize: 18,
              fontWeight: bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: whiteTextStyle.copyWith(
              fontSize: 10,
              color: Colors.white.withValues(alpha:0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAcCard(AcModel ac) {
    final servis = getServisByAcId(ac.id);

    // kalau data servis belum ada, jangan render card (atau tampilkan card "belum ada tugas")
    if (servis == null) return const SizedBox.shrink();

    final keluhan = getKeluhanByAcId(ac.id); // boleh null
    final daysSinceService = DateTime.now().difference(ac.terakhirService).inDays;

    final statusColor = servis.status.color;   // dari extension
    final statusText  = servis.status.text;

    Color _getStatusColor() {
      switch (servis.status) {
        case ServisStatus.ditugaskan:
          return Colors.blue;
        case ServisStatus.dalamPerjalanan:
          return Colors.orange;
        case ServisStatus.tibaDiLokasi:
          return Colors.purple;
        case ServisStatus.sedangDiperiksa:
          return Colors.indigo;
        case ServisStatus.dalamPerbaikan:
          return Colors.red;
        case ServisStatus.menungguSukuCadang:
          return Colors.amber;
        case ServisStatus.selesai:
          return Colors.green;
        case ServisStatus.ditolak:
          return Colors.red[900]!;
        case ServisStatus.menungguKonfirmasi:
          return Colors.yellow[700]!;
      }
    }

    String _getStatusIcon() {
      switch (servis.status) {
        case ServisStatus.ditugaskan:
          return '📋';
        case ServisStatus.dalamPerjalanan:
          return '🚗';
        case ServisStatus.tibaDiLokasi:
          return '📍';
        case ServisStatus.sedangDiperiksa:
          return '🔍';
        case ServisStatus.dalamPerbaikan:
          return '🔧';
        case ServisStatus.menungguSukuCadang:
          return '⏳';
        case ServisStatus.selesai:
          return '✅';
        case ServisStatus.ditolak:
          return '❌';
        case ServisStatus.menungguKonfirmasi:
          return '⏰';
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeknisiServisDetailPage(
              teknisi: widget.teknisi,
              lokasi: widget.lokasi,
              ac: ac,
              keluhan: keluhan,
              servis: servis,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getStatusColor().withValues(alpha:0.1),
                          _getStatusColor().withValues(alpha:0.2),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _getStatusIcon(),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getStatusColor().withValues(alpha:0.3)),
                    ),
                    child: Text(
                      statusText,
                      style: primaryTextStyle.copyWith(
                        fontSize: 12,
                        fontWeight: medium,
                        color: _getStatusColor(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                ac.nama,
                style: primaryTextStyle.copyWith(
                  fontSize: 18,
                  fontWeight: bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '${ac.merk} • ${ac.type} • ${ac.kapasitas}',
                style: greyTextStyle.copyWith(fontSize: 13),
              ),
              if (keluhan != null && keluhan.judul.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: keluhan.prioritasColor.withValues(alpha:0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: keluhan.prioritasColor.withValues(alpha:0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_rounded, size: 14, color: keluhan.prioritasColor),
                          const SizedBox(width: 6),
                          Text(
                            'Keluhan: ${keluhan.judul}',
                            style: primaryTextStyle.copyWith(
                              fontSize: 14,
                              fontWeight: medium,
                              color: keluhan.prioritasColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        keluhan.deskripsi,
                        style: greyTextStyle.copyWith(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoBadge(
                    icon: Icons.calendar_today_rounded,
                    text: '$daysSinceService hari',
                    color: kBoxMenuCoklatColor,
                  ),
                  const SizedBox(width: 12),
                  // _buildInfoBadge(
                  //   icon: Icons.monetization_on_rounded,
                  //   text: 'Rp ${servis.totalBiaya.toInt()}',
                  //   color: kBoxMenuGreenColor,
                  // ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TeknisiServisDetailPage(
                            teknisi: widget.teknisi,
                            lokasi: widget.lokasi,
                            ac: ac,
                            keluhan: keluhan,
                            servis: servis,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(Icons.arrow_forward_rounded, size: 16),
                    label: Text(
                      'Tangani',
                      style: whiteTextStyle.copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: primaryTextStyle.copyWith(
              fontSize: 12,
              fontWeight: medium,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header dengan gradient
            _buildHeader(),

            // Content
            Expanded(
              child: _acDitugaskan.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.ac_unit,
                      size: 64,
                      color: kGreyColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tidak Ada AC',
                      style: primaryTextStyle.copyWith(
                        fontSize: 18,
                        fontWeight: bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tidak ada AC yang perlu ditangani di lokasi ini',
                      style: greyTextStyle,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
                  : SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    ..._acDitugaskan.map((ac) {
                      return _buildAcCard(ac);
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}