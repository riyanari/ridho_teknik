// lib/pages/teknisi/teknisi_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:ridho_teknik/extensions/servis_extensions.dart';
import '../../models/keluhan_model.dart';
import '../../models/servis_model.dart';
import '../../models/teknisi_model.dart';
import '../../theme/theme.dart';
import 'teknisi_lokasi_list_page.dart';
import 'package:provider/provider.dart';
import '../../providers/teknisi_provider.dart';

class TeknisiDashboardPage extends StatefulWidget {
  const TeknisiDashboardPage({super.key});

  @override
  State<TeknisiDashboardPage> createState() => _TeknisiDashboardPageState();
}

class _TeknisiDashboardPageState extends State<TeknisiDashboardPage> {


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeknisiProvider>().fetch();
    });
  }


  // Data dummy teknisi
  final TeknisiModel _teknisi = TeknisiModel(
    id: 'T1',
    nama: 'Budi Santoso',
    spesialisasi: 'AC Split & Central',
    noHp: '0812-3456-7890',
    rating: 4.7,
    totalService: 127,
    foto: 'assets/default_teknisi.jpg',
  );

  // Data dummy servis
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
      lokasiId: 'L2',
      acId: 'A2',
      teknisiId: 'T1',
      status: ServisStatus.menungguKonfirmasi,
      tindakan: [TindakanServis.gantiKapasitor],
      tanggalDitugaskan: DateTime.now().subtract(const Duration(days: 1)),
      tanggalSelesai: DateTime.now().subtract(const Duration(hours: 3)),
      biayaServis: 300000,
      biayaSukuCadang: 200000,
    ),
    ServisModel(
      id: 'SRV3',
      keluhanId: 'K3',
      lokasiId: 'L3',
      acId: 'A3',
      teknisiId: 'T1',
      status: ServisStatus.ditugaskan,
      tanggalDitugaskan: DateTime.now().subtract(const Duration(hours: 1)),
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

  int get _totalTugas => _servisList.length;
  int get _tugasBerjalan => _servisList
      .where((s) => s.status.index < ServisStatus.selesai.index)
      .length;
  int get _menungguKonfirmasi => _servisList
      .where((s) => s.status == ServisStatus.menungguKonfirmasi)
      .length;
  int get _tugasSelesai => _servisList
      .where((s) => s.status == ServisStatus.selesai)
      .length;

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
          // Profile Info
          Row(
            children: [
              // Container(
              //   width: 60,
              //   height: 60,
              //   decoration: BoxDecoration(
              //     shape: BoxShape.circle,
              //     color: Colors.white,
              //     border: Border.all(color: Colors.white, width: 2),
              //     image: const DecorationImage(
              //       image: AssetImage('assets/default_teknisi.jpg'),
              //       fit: BoxFit.cover,
              //     ),
              //   ),
              // ),
              // const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _teknisi.nama,
                      style: whiteTextStyle.copyWith(
                        fontSize: 20,
                        fontWeight: bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _teknisi.spesialisasi,
                      style: whiteTextStyle.copyWith(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha:0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, color: Colors.yellow, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${_teknisi.rating} • ${_teknisi.totalService} servis',
                          style: whiteTextStyle.copyWith(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha:0.8),
                          ),
                        ),
                      ],
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
                child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Quick Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Tugas',
                  value: _totalTugas.toString(),
                  icon: Icons.list_alt_rounded,
                  color: Colors.white,
                  bgColor: Colors.white.withValues(alpha:0.2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  title: 'Berjalan',
                  value: _tugasBerjalan.toString(),
                  icon: Icons.running_with_errors_rounded,
                  color: Colors.white,
                  bgColor: Colors.white.withValues(alpha:0.2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  title: 'Menunggu',
                  value: _menungguKonfirmasi.toString(),
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

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aksi Cepat',
            style: primaryTextStyle.copyWith(
              fontSize: 18,
              fontWeight: bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.location_on_rounded,
                  label: 'Lihat Lokasi',
                  color: kPrimaryColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeknisiLokasiListPage(teknisi: _teknisi),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.assignment_rounded,
                  label: 'Tugas Saya',
                  color: kSecondaryColor,
                  onTap: () {
                    // Navigasi ke halaman tugas
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.calendar_today_rounded,
                  label: 'Jadwal',
                  color: kBoxMenuGreenColor,
                  onTap: () {
                    // Navigasi ke halaman jadwal
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.bar_chart_rounded,
                  label: 'Statistik',
                  color: kBoxMenuDarkBlueColor,
                  onTap: () {
                    // Navigasi ke halaman statistik
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha:0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: primaryTextStyle.copyWith(
                fontSize: 14,
                fontWeight: medium,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTasks() {
    final recentTasks = _servisList
        .where((s) => s.status.index < ServisStatus.selesai.index)
        .toList();

    if (recentTasks.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
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
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 48,
              color: kGreyColor,
            ),
            const SizedBox(height: 12),
            Text(
              'Tidak ada tugas aktif',
              style: primaryTextStyle.copyWith(
                fontSize: 16,
                fontWeight: bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Semua tugas telah selesai',
              style: greyTextStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tugas Berjalan',
                  style: primaryTextStyle.copyWith(
                    fontSize: 14,
                    fontWeight: bold,
                  ),
                ),
                Text(
                  '$_tugasBerjalan tugas',
                  style: greyTextStyle.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          ...recentTasks.map((servis) {
            return _buildTaskItem(servis);
          }),
        ],
      ),
    );
  }

  Widget _buildTaskItem(ServisModel servis) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: servis.statusColorUI.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: servis.statusColorUI.withValues(alpha:0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: servis.statusColorUI.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  servis.statusTextUI,
                  style: primaryTextStyle.copyWith(
                    fontSize: 12,
                    fontWeight: medium,
                    color: servis.statusColorUI,
                  ),
                ),
              ),
              Text(
                'Rp ${servis.totalBiaya.toInt()}',
                style: primaryTextStyle.copyWith(
                  fontSize: 14,
                  fontWeight: bold,
                  color: kPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Servis AC #${servis.id.substring(3)}',
            style: primaryTextStyle.copyWith(
              fontSize: 16,
              fontWeight: bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 14, color: kGreyColor),
              const SizedBox(width: 6),
              Text(
                'Lokasi L${servis.lokasiId.substring(1)}',
                style: greyTextStyle.copyWith(fontSize: 12),
              ),
              const SizedBox(width: 12),
              Icon(Icons.access_time_rounded, size: 14, color: kGreyColor),
              const SizedBox(width: 6),
              Text(
                _formatTimeAgo(servis.tanggalDitugaskan),
                style: greyTextStyle.copyWith(fontSize: 12),
              ),
            ],
          ),
          if (servis.tindakan.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Tindakan: ${servis.tindakanTextUI}',
              style: greyTextStyle.copyWith(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else {
      return '${difference.inDays} hari lalu';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header dengan profile
            _buildHeader(),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 80),
                child: Column(
                  children: [
                    // Quick Actions
                    _buildQuickActions(),
                    const SizedBox(height: 4),

                    // Recent Tasks
                    _buildRecentTasks(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeknisiLokasiListPage(teknisi: _teknisi),
            ),
          );
        },
        backgroundColor: kSecondaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.location_searching_rounded, size: 24),
      ),
    );
  }
}