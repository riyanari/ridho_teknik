import 'dart:async';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ridho_teknik/pages/teknisi/teknisi_task_detail_page.dart';

import '../../models/servis_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/teknisi_provider.dart';
import '../../theme/theme.dart';

class TeknisiDashboardPage extends StatefulWidget {
  const TeknisiDashboardPage({super.key});

  @override
  State<TeknisiDashboardPage> createState() => _TeknisiDashboardPageState();
}

class _TeknisiDashboardPageState extends State<TeknisiDashboardPage> {
  String _selectedStatus = 'Semua'; // Semua | ditugaskan | dikerjakan | selesai
  String _selectedJenis = 'Semua'; // Semua | cuci | perbaikan | instalasi
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  final List<Map<String, dynamic>> _statusChips = [
    {'value': 'Semua', 'display': 'Semua', 'color': kPrimaryColor},
    {'value': 'ditugaskan', 'display': 'Ditugaskan', 'color': Colors.blue},
    {'value': 'dikerjakan', 'display': 'Dikerjakan', 'color': Colors.purple},
    {'value': 'selesai', 'display': 'Selesai', 'color': Colors.green},
  ];

  final List<Map<String, String>> _jenisList = const [
    {'value': 'Semua', 'display': 'Semua Jenis'},
    {'value': 'cuci', 'display': 'Cuci'},
    {'value': 'perbaikan', 'display': 'Perbaikan'},
    {'value': 'instalasi', 'display': 'Instalasi'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeknisiProvider>().fetchTasks();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // =========================
  // FILTERING
  // =========================

  // String _statusKey(ServisModel s) => s.statusKeyFromItems;
  String _statusKey(ServisModel s) {
    final items = s.itemsData;

    // fallback kalau itemsData kosong
    if (items.isEmpty) return s.status.name.toLowerCase();

    final statuses = items
        .map((it) => (it['status'] ?? '').toString().toLowerCase().trim())
        .where((x) => x.isNotEmpty)
        .toList();

    if (statuses.isEmpty) return s.status.name.toLowerCase();

    final allSelesai = statuses.every((x) => x == 'selesai');
    if (allSelesai) return 'selesai';

    final anyDitugaskan = statuses.any((x) => x == 'ditugaskan');
    if (anyDitugaskan) return 'ditugaskan';

    // di titik ini: tidak ada ditugaskan,
    // berarti semua item minimal sudah mulai (dikerjakan/selesai)
    return 'dikerjakan';
  }


  String _jenisKey(ServisModel s) {
    // s.jenis adalah enum JenisPenanganan
    switch (s.jenis) {
      case JenisPenanganan.cuciAc:
        return 'cuci';
      case JenisPenanganan.perbaikanAc:
        return 'perbaikan';
      case JenisPenanganan.instalasi:
        return 'instalasi';
    }
  }

  bool _matchStatus(ServisModel s) {
    if (_selectedStatus == 'Semua') return true;
    return _statusKey(s) == _selectedStatus;
  }

  bool _matchJenis(ServisModel s) {
    if (_selectedJenis == 'Semua') return true;
    return _jenisKey(s) == _selectedJenis;
  }

  bool _matchSearch(ServisModel s) {
    if (_searchQuery.trim().isEmpty) return true;
    final q = _searchQuery.toLowerCase();

    final id = s.id.toLowerCase();
    final lokasiNama = s.lokasiNama.toLowerCase();
    final lokasiAlamat = s.lokasiAlamat.toLowerCase();
    final acText = s.acDisplay.toLowerCase();
    final tindakanText = s.tindakan.isEmpty
        ? ''
        : s.tindakan.map((e) => e.name.toLowerCase()).join(' ');

    return id.contains(q) ||
        lokasiNama.contains(q) ||
        lokasiAlamat.contains(q) ||
        acText.contains(q) ||
        tindakanText.contains(q);
  }

  List<ServisModel> _filtered(List<ServisModel> all) {
    final rows = all
        .where(_matchStatus)
        .where(_matchJenis)
        .where(_matchSearch)
        .toList();

    rows.sort((a, b) {
      DateTime aKey = a.tanggalSelesai ?? a.tanggalDitugaskan;
      DateTime bKey = b.tanggalSelesai ?? b.tanggalDitugaskan;
      return bKey.compareTo(aKey);
    });

    return rows;
  }

  Future<void> _refresh() async {
    await context.read<TeknisiProvider>().fetchTasks();
  }

  // =========================
  // UI HELPERS
  // =========================

  Color _statusColor(String status) {
    switch (status) {
      case 'ditugaskan':
        return Colors.blue;
      case 'dikerjakan':
        return Colors.purple;
      case 'selesai':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'ditugaskan':
        return 'Ditugaskan';
      case 'dikerjakan':
        return 'Dikerjakan';
      case 'selesai':
        return 'Selesai';
      default:
        return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'ditugaskan':
        return Iconsax.task_square;
      case 'dikerjakan':
        return Iconsax.timer;
      case 'selesai':
        return Iconsax.tick_circle;
      default:
        return Iconsax.activity;
    }
  }

  String _fmtDateTime(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('dd MMM y • HH:mm', 'id_ID').format(dt);
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

  // =========================
  // WIDGETS
  // =========================

  Widget _buildJenisDropdown() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Iconsax.category, color: kPrimaryColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButton<String>(
                value: _selectedJenis,
                isExpanded: true,
                underline: const SizedBox(),
                icon: Icon(Iconsax.arrow_down_1, color: kPrimaryColor),
                items: _jenisList.map((e) {
                  return DropdownMenuItem<String>(
                    value: e['value']!,
                    child: Text(
                      e['display']!,
                      style: primaryTextStyle.copyWith(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _selectedJenis = v);
                },
              ),
            ),
            if (_selectedJenis != 'Semua')
              IconButton(
                onPressed: () => setState(() => _selectedJenis = 'Semua'),
                icon: const Icon(Iconsax.close_circle, color: Colors.red, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required BuildContext context,
    required String nama,
    required String subtitle,
    required int ditugaskan,
    required int dikerjakan,
    required int selesai,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryColor, const Color(0xFF5D6BC0)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: whiteTextStyle.copyWith(fontSize: 20, fontWeight: bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: whiteTextStyle.copyWith(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _confirmLogout(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.logout_1, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _buildHeaderStat(icon: Iconsax.task_square, value: '$ditugaskan', label: 'Ditugaskan')),
              const SizedBox(width: 10),
              Expanded(child: _buildHeaderStat(icon: Iconsax.timer_start, value: '$dikerjakan', label: 'Dikerjakan')),
              const SizedBox(width: 10),
              Expanded(child: _buildHeaderStat(icon: Iconsax.tick_circle, value: '$selesai', label: 'Selesai')),
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(value, style: whiteTextStyle.copyWith(fontSize: 18, fontWeight: bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: whiteTextStyle.copyWith(fontSize: 11, color: Colors.white.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Iconsax.search_normal_1, color: kPrimaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (v) {
                  _searchDebounce?.cancel();
                  _searchDebounce = Timer(const Duration(milliseconds: 350), () {
                    if (!mounted) return;
                    setState(() => _searchQuery = v);
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Cari ID / lokasi / AC / tindakan...',
                  hintStyle: greyTextStyle.copyWith(fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                onPressed: () {
                  _searchDebounce?.cancel();
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: const Icon(Iconsax.close_circle, color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChips() {
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: _statusChips.map((chip) {
          final isSelected = _selectedStatus == chip['value'];
          final color = chip['color'] as Color;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                chip['display'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: medium,
                  color: isSelected ? Colors.white : color,
                ),
              ),
              selected: isSelected,
              selectedColor: color,
              backgroundColor: color.withValues(alpha: 0.1),
              avatar: isSelected ? const Icon(Iconsax.tick_circle, size: 16, color: Colors.white) : null,
              onSelected: (_) => setState(() => _selectedStatus = chip['value'] as String),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? Colors.transparent : color.withValues(alpha: 0.25)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // =========================
  // CARD
  // =========================

  Widget _buildTaskCard(ServisModel s) {
    final status = _statusKey(s);
    final statusColor = _statusColor(status);
    final statusText = _statusLabel(status);
    final statusIcon = _statusIcon(status);

    final jumlahText = s.itemsData.isNotEmpty
        ? '${s.itemsData.length}'
        : (s.acUnitsNames.isNotEmpty ? '${s.acUnitsNames.length}' : (s.jumlahAc?.toString() ?? '-'));

    final lokasiText = s.lokasiAlamat;
    final assignedAt = _fmtDateTime(s.tanggalDitugaskan);

    final keluhanText = s.catatan.trim();
    final tindakanText = s.tindakan.isEmpty ? '' : s.tindakan.map((e) => e.name).join(', ');

    final infoUtama = (status == 'ditugaskan')
        ? (keluhanText.isNotEmpty ? keluhanText : 'Belum ada keluhan')
        : (tindakanText.isNotEmpty ? tindakanText : (keluhanText.isNotEmpty ? keluhanText : 'Belum ada tindakan'));

    final clientName = s.lokasiNama.trim();
    final titleText = clientName.isNotEmpty ? clientName : 'Client #${s.id}';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha:0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              border: Border.all(color: statusColor.withValues(alpha:0.15), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha:0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleText,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.2),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Iconsax.calendar_1, size: 13, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(
                            assignedAt,
                            style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [statusColor.withValues(alpha:0.2), statusColor.withValues(alpha:0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha:0.3), width: 1.5),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[100]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _infoItemForTechnician(
                          icon: Iconsax.cpu,
                          title: 'Jumlah AC',
                          value: '$jumlahText Unit',
                          color: Colors.blue,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey[200],
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      Expanded(
                        child: _infoItemForTechnician(
                          icon: Iconsax.info_circle,
                          title: 'Jenis',
                          value: s.jenisDisplay,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (status != 'selesai') ...[
                  _modernDetailTile(
                    icon: Iconsax.location,
                    title: 'Alamat',
                    value: lokasiText,
                    iconColor: kPrimaryColor,
                    gradientColors: [kPrimaryColor.withValues(alpha:0.1), kPrimaryColor.withValues(alpha:0.05)],
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                ],

                _modernDetailTile(
                  icon: status == 'ditugaskan' ? Iconsax.message_text : Iconsax.note_text,
                  title: status == 'ditugaskan' ? 'Keluhan Client' : 'Tindakan',
                  value: infoUtama,
                  iconColor: status == 'ditugaskan' ? Colors.orange : Colors.purple,
                  gradientColors: status == 'ditugaskan'
                      ? [Colors.orange.withValues(alpha:0.1), Colors.orange.withValues(alpha:0.05)]
                      : [Colors.purple.withValues(alpha:0.1), Colors.purple.withValues(alpha:0.05)],
                  maxLines: 3,
                ),

                if (s.technicianNames.length > 1) ...[
                  const SizedBox(height: 12),
                  _modernDetailTile(
                    icon: Iconsax.profile_2user,
                    title: 'Tim Teknisi',
                    value: s.techniciansNamesDisplay,
                    iconColor: Colors.indigo,
                    gradientColors: [Colors.indigo.withValues(alpha:0.1), Colors.indigo.withValues(alpha:0.05)],
                    maxLines: 2,
                  ),
                ],

                const SizedBox(height: 20),
                _buildActionButtonForTechnician(statusColor, s),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItemForTechnician({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    String subtitle = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color.withValues(alpha:0.8)),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.grey[900],
            height: 1.2,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );
  }

  Widget _modernDetailTile({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
    required List<Color> gradientColors,
    int maxLines = 2,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: iconColor.withValues(alpha:0.15), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: iconColor.withValues(alpha:0.1), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: iconColor.withValues(alpha:0.9),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[800], height: 1.4),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonForTechnician(Color statusColor, ServisModel s) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDetail(s),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [statusColor.withValues(alpha:0.95), statusColor.withValues(alpha:0.75)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: statusColor.withValues(alpha:0.25), blurRadius: 15, offset: const Offset(0, 4))],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.document_text, size: 20, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Detail',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(ServisModel s) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TeknisiTaskDetailPage(servis: s)),
    );
  }

  // =========================
  // BUILD
  // =========================

  @override
  Widget build(BuildContext context) {
    return Consumer2<TeknisiProvider, AuthProvider>(
      builder: (context, prov, auth, _) {
        final all = prov.tasks;
        final list = _filtered(all);

        final ditugaskan = all.where((s) => _statusKey(s) == 'ditugaskan').length;
        final dikerjakan = all.where((s) => _statusKey(s) == 'dikerjakan').length;
        final selesai = all.where((s) => _statusKey(s) == 'selesai').length;

        final user = auth.user;
        final nama = (user?.name?.toString().trim().isNotEmpty ?? false) ? user!.name! : 'Teknisi';
        final subtitle = (user?.role?.toString().trim().isNotEmpty ?? false)
            ? user!.role!.toString().toUpperCase()
            : 'TEKNISI';

        return Scaffold(
          backgroundColor: kBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(
                  context: context,
                  nama: nama,
                  subtitle: subtitle,
                  ditugaskan: ditugaskan,
                  dikerjakan: dikerjakan,
                  selesai: selesai,
                ),
                _buildSearchBar(),
                _buildStatusChips(),
                _buildJenisDropdown(),

                if (prov.error != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.18)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.warning_2, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            prov.error!,
                            style: primaryTextStyle.copyWith(fontSize: 12, color: Colors.red),
                          ),
                        ),
                        TextButton(onPressed: _refresh, child: const Text('Coba lagi')),
                      ],
                    ),
                  ),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: prov.loading && all.isEmpty
                        ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(child: CircularProgressIndicator()),
                      ],
                    )
                        : list.isEmpty
                        ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 90),
                        Column(
                          children: [
                            Icon(Iconsax.note_remove, color: Colors.grey[400], size: 78),
                            const SizedBox(height: 14),
                            Text('Tidak ada data',
                                style: greyTextStyle.copyWith(fontSize: 16, fontWeight: medium)),
                            const SizedBox(height: 6),
                            Text('Coba ubah filter atau kata kunci.',
                                style: greyTextStyle.copyWith(fontSize: 13)),
                            const SizedBox(height: 18),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedStatus = 'Semua';
                                  _selectedJenis = 'Semua';
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Reset'),
                            ),
                          ],
                        ),
                      ],
                    )
                        : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 8, bottom: 90),
                      itemCount: list.length,
                      itemBuilder: (context, i) => _buildTaskCard(list[i]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
