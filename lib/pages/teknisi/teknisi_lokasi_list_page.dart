// lib/pages/teknisi/teknisi_lokasi_list_page.dart
import 'package:flutter/material.dart';
import '../../models/keluhan_model.dart';
import '../../models/lokasi_model.dart';
import '../../models/servis_model.dart';
import '../../models/teknisi_model.dart';
import '../../theme/theme.dart';
import 'teknisi_ac_list_page.dart';

class TeknisiLokasiListPage extends StatefulWidget {
  final TeknisiModel teknisi;
  const TeknisiLokasiListPage({super.key, required this.teknisi});

  @override
  State<TeknisiLokasiListPage> createState() => _TeknisiLokasiListPageState();
}

class _TeknisiLokasiListPageState extends State<TeknisiLokasiListPage> {
  final List<LokasiModel> _lokasiList = [
    LokasiModel(
      id: 'L1',
      nama: 'Rumah Pak Budi',
      alamat: 'Jl. Sudirman No. 123, Jakarta Pusat',
      jumlahAC: 3,
      lastService: DateTime.now().subtract(const Duration(days: 15)), clientId: '',
    ),
    LokasiModel(
      id: 'L2',
      nama: 'Toko Bu Ani',
      alamat: 'Jl. Ahmad Yani No. 45, Bekasi Barat',
      jumlahAC: 2,
      lastService: DateTime.now().subtract(const Duration(days: 45)), clientId: '',
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
      lokasiId: 'L2',
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
      tanggalDitugaskan: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ServisModel(
      id: 'SRV2',
      keluhanId: 'K2',
      lokasiId: 'L2',
      acId: 'A2',
      teknisiId: 'T1',
      status: ServisStatus.ditugaskan,
      tanggalDitugaskan: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  List<LokasiModel> get _lokasiDitugaskan {
    final lokasiIds = _servisList
        .where((s) => s.teknisiId == widget.teknisi.id)
        .map((s) => s.lokasiId)
        .toSet();

    return _lokasiList
        .where((lokasi) => lokasiIds.contains(lokasi.id))
        .toList();
  }

  int getJumlahTugas(String lokasiId) {
    return _servisList
        .where((s) => s.lokasiId == lokasiId && s.teknisiId == widget.teknisi.id)
        .length;
  }

  Widget _buildHeader() {
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
                      'Lokasi Ditugaskan',
                      style: whiteTextStyle.copyWith(
                        fontSize: 18,
                        fontWeight: bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_lokasiDitugaskan.length} lokasi perlu ditangani',
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
                child: Icon(
                  Icons.filter_list_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Lokasi',
                  value: _lokasiDitugaskan.length.toString(),
                  icon: Icons.location_city_rounded,
                  color: Colors.white,
                  bgColor: Colors.white.withValues(alpha:0.2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  title: 'Total Tugas',
                  value: _servisList
                      .where((s) => s.teknisiId == widget.teknisi.id)
                      .length
                      .toString(),
                  icon: Icons.assignment_rounded,
                  color: Colors.white,
                  bgColor: Colors.white.withValues(alpha:0.2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  title: 'Prioritas',
                  value: _keluhanList
                      .where((k) => k.prioritas == Prioritas.tinggi || k.prioritas == Prioritas.darurat)
                      .length
                      .toString(),
                  icon: Icons.priority_high_rounded,
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

  Widget _buildLokasiCard(LokasiModel lokasi) {
    final jumlahTugas = getJumlahTugas(lokasi.id);
    final keluhanLokasi = _keluhanList
        .where((k) => k.lokasiId == lokasi.id && k.assignedTo == widget.teknisi.id)
        .toList();

    final hasPriority = keluhanLokasi
        .any((k) => k.prioritas == Prioritas.tinggi || k.prioritas == Prioritas.darurat);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeknisiAcListPage(
              teknisi: widget.teknisi,
              lokasi: lokasi,
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
                        colors: hasPriority
                            ? [Colors.red, Colors.orange]
                            : [kPrimaryColor.withValues(alpha:0.1), kPrimaryColor.withValues(alpha:0.2)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      color: hasPriority ? Colors.white : kPrimaryColor,
                      size: 22,
                    ),
                  ),
                  if (hasPriority)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red, Colors.orange],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.priority_high_rounded, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'Prioritas',
                            style: whiteTextStyle.copyWith(fontSize: 11, fontWeight: medium),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                lokasi.nama,
                style: primaryTextStyle.copyWith(
                  fontSize: 18,
                  fontWeight: bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                lokasi.alamat,
                style: greyTextStyle.copyWith(
                  fontSize: 13,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoBadge(
                    icon: Icons.ac_unit_rounded,
                    text: '${lokasi.jumlahAC} AC',
                    color: kBoxMenuLightBlueColor,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoBadge(
                    icon: Icons.assignment_rounded,
                    text: '$jumlahTugas tugas',
                    color: kSecondaryColor,
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TeknisiAcListPage(
                            teknisi: widget.teknisi,
                            lokasi: lokasi,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(Icons.arrow_forward_rounded, size: 16),
                    label: Text(
                      'Detail',
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
              child: _lokasiDitugaskan.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_off_rounded,
                      size: 64,
                      color: kGreyColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum Ada Lokasi',
                      style: primaryTextStyle.copyWith(
                        fontSize: 18,
                        fontWeight: bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Anda belum ditugaskan ke lokasi manapun',
                      style: greyTextStyle,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
                  : SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    ..._lokasiDitugaskan.map((lokasi) {
                      return _buildLokasiCard(lokasi);
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