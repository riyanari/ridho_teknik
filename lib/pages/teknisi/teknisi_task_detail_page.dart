import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ridho_teknik/pages/teknisi/teknisi_ac_detail_page.dart';

import '../../models/servis_model.dart';
import '../../providers/teknisi_provider.dart';
import '../../services/token_store.dart';
import '../../theme/theme.dart';

class TeknisiTaskDetailPage extends StatefulWidget {
  const TeknisiTaskDetailPage({
    super.key,
    required this.servis,
  });

  final ServisModel servis;

  @override
  State<TeknisiTaskDetailPage> createState() => _TeknisiTaskDetailPageState();
}

class _TeknisiTaskDetailPageState extends State<TeknisiTaskDetailPage>
    with SingleTickerProviderStateMixin {
  late ServisModel _servis;
  String? _token;
  int? _selectedFloor;

  final ScrollController _scrollController = ScrollController();
  bool _showAllDetails = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _servis = widget.servis;
    _setupAnimations();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final store = context.read<TokenStore>();
    String? token;
    try {
      token = await store.getToken();
    } catch (_) {
      token = null;
    }
    if (!mounted) return;
    setState(() {
      _token = token;
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  int _getFloorNumberFromItem(Map<String, dynamic> item) {
    final acRaw = item['ac_unit'];
    final ac = acRaw is Map<String, dynamic>
        ? acRaw
        : (acRaw is Map ? Map<String, dynamic>.from(acRaw) : <String, dynamic>{});

    final room = ac['room'];
    if (room is Map) {
      final floor = room['floor'];
      if (floor is Map) {
        return int.tryParse((floor['number'] ?? 0).toString()) ?? 0;
      }
    }

    return int.tryParse((ac['lantai'] ?? 0).toString()) ?? 0;
  }

  String _getFloorLabelFromItem(Map<String, dynamic> item) {
    final acRaw = item['ac_unit'];
    final ac = acRaw is Map<String, dynamic>
        ? acRaw
        : (acRaw is Map ? Map<String, dynamic>.from(acRaw) : <String, dynamic>{});

    final room = ac['room'];
    if (room is Map) {
      final floor = room['floor'];
      if (floor is Map) {
        final name = (floor['name'] ?? '').toString().trim();
        final number = int.tryParse((floor['number'] ?? 0).toString()) ?? 0;

        if (name.isNotEmpty) return name;
        if (number > 0) return 'Lantai $number';
      }
    }

    final lantai = int.tryParse((ac['lantai'] ?? 0).toString()) ?? 0;
    return lantai > 0 ? 'Lantai $lantai' : '-';
  }

  List<int> _extractFloorOptions(List<Map<String, dynamic>> items) {
    final floors = items
        .map(_getFloorNumberFromItem)
        .where((e) => e > 0)
        .toSet()
        .toList()
      ..sort();

    return floors;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshFromProvider() async {
    final prov = context.read<TeknisiProvider>();
    await prov.fetchTasks();
    if (!mounted) return;
    final idx = prov.tasks.indexWhere((e) => e.id == _servis.id);
    if (idx != -1) {
      setState(() => _servis = prov.tasks[idx]);
    }
  }

  String _statusKey() {
    final items = _servis.itemsData;
    if (items.isEmpty) return _servis.status.name.toLowerCase();

    final statuses = items
        .map((it) => (it['status'] ?? '').toString().toLowerCase().trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (statuses.isEmpty) return _servis.status.name.toLowerCase();
    if (statuses.every((x) => x == 'selesai')) return 'selesai';
    if (statuses.any((x) => x == 'dikerjakan')) return 'dikerjakan';
    if (statuses.any((x) => x == 'ditugaskan')) return 'ditugaskan';
    return _servis.status.name.toLowerCase();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'menunggukonfirmasi':
      case 'menunggu_konfirmasi':
        return Colors.orange;
      case 'ditugaskan':
        return const Color(0xFF2196F3);
      case 'dikerjakan':
        return const Color(0xFF9C27B0);
      case 'selesai':
        return const Color(0xFF4CAF50);
      case 'batal':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'menunggukonfirmasi':
      case 'menunggu_konfirmasi':
        return 'Menunggu Konfirmasi';
      case 'ditugaskan':
        return 'Ditugaskan';
      case 'dikerjakan':
        return 'Dikerjakan';
      case 'selesai':
        return 'Selesai';
      case 'batal':
        return 'Batal';
      default:
        return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'menunggukonfirmasi':
      case 'menunggu_konfirmasi':
        return Iconsax.timer;
      case 'ditugaskan':
        return Iconsax.task_square;
      case 'dikerjakan':
        return Iconsax.timer_1;
      case 'selesai':
        return Iconsax.tick_circle;
      case 'batal':
        return Iconsax.close_circle;
      default:
        return Iconsax.activity;
    }
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('dd MMM y', 'id_ID').format(dt);
  }

  void _showSnackBar(
      BuildContext context,
      String message,
      Color color, {
        IconData? icon,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) Icon(icon, color: Colors.white, size: 20),
            if (icon != null) const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _jumlahAcDisplay(ServisModel s) {
    if (s.itemsData.isNotEmpty) return '${s.itemsData.length}';
    if (s.jumlahAc > 0) return '${s.jumlahAc}';
    if (s.acUnits.isNotEmpty) return '${s.acUnits.length}';
    if (s.acUnitId != null) return '1';
    return '-';
  }

  List<String> _technicianNames(ServisModel s) {
    final names = <String>[];

    for (final tech in s.techniciansData) {
      final name = (tech['name'] ?? '').toString().trim();
      if (name.isNotEmpty && !names.contains(name)) {
        names.add(name);
      }
    }

    final fallback = (s.teknisiData?['name'] ?? '').toString().trim();
    if (fallback.isNotEmpty && !names.contains(fallback)) {
      names.add(fallback);
    }

    if (names.isEmpty && s.technicianId != null) {
      names.add('Teknisi #${s.technicianId}');
    }

    return names;
  }

  String _lokasiAlamat(ServisModel s) {
    return (s.lokasiData?['address'] ?? '-').toString();
  }

  String? _durationDisplay(ServisModel s) {
    final start = s.tanggalMulai;
    final end = s.tanggalSelesai;

    if (start == null) return null;

    final effectiveEnd = end ?? DateTime.now();
    final diff = effectiveEnd.difference(start);

    if (diff.inMinutes < 1) return 'Baru dimulai';
    if (diff.inHours < 1) return '${diff.inMinutes} menit';
    if (diff.inDays < 1) {
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      if (minutes == 0) return '$hours jam';
      return '$hours jam $minutes menit';
    }
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    if (hours == 0) return '$days hari';
    return '$days hari $hours jam';
  }

  int _calculateProgress(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return 0;
    final completed = items.where((item) {
      final status = (item['status'] ?? '').toString().toLowerCase();
      return status == 'selesai';
    }).length;
    return (completed * 100 / items.length).round();
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusKey();
    final statusColor = _statusColor(status);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final technicianNames = _technicianNames(_servis);

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 18, top: 4),
          child: CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.9),
            child: IconButton(
              icon: Icon(Iconsax.arrow_left_2, color: Colors.grey[800]),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18, top: 4),
            child: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.9),
              child: IconButton(
                icon: Icon(Iconsax.more, color: Colors.grey[800]),
                onPressed: () => _showOptionsMenu(context),
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildHeaderSliver(status, statusColor),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildStatsCard(context),
                  ),
                  const SizedBox(height: 20),
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildAcListSection(context),
                  ),
                  const SizedBox(height: 20),
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildDetailsSection(),
                  ),
                  const SizedBox(height: 20),
                  if (technicianNames.isNotEmpty) ...[
                    SlideTransition(
                      position: _slideAnimation,
                      child: _buildTechniciansCard(technicianNames),
                    ),
                    const SizedBox(height: 20),
                  ],
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSliver(String status, Color statusColor) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 280,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                statusColor,
                statusColor.withValues(alpha: 0.8),
                statusColor.withValues(alpha: 0.6),
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -80,
                top: -80,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                left: -50,
                bottom: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 80),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon(status), size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            _statusLabel(status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _servis.lokasiNama,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Iconsax.location,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _lokasiAlamat(_servis),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _servis.jenisDisplay,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    final technicianNames = _technicianNames(_servis);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            icon: Iconsax.calendar_1,
            value: _fmtDate(_servis.tanggalDitugaskan),
            label: 'Tanggal',
            color: const Color(0xFF2196F3),
          ),
          const SizedBox(width: 20),
          _buildStatItem(
            icon: Iconsax.cpu,
            value: _jumlahAcDisplay(_servis),
            label: 'Unit AC',
            color: const Color(0xFF4CAF50),
          ),
          const SizedBox(width: 20),
          _buildStatItem(
            icon: Iconsax.profile_2user,
            value: technicianNames.isNotEmpty ? '${technicianNames.length}' : '0',
            label: 'Teknisi',
            color: const Color(0xFF9C27B0),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcListSection(BuildContext context) {
    final items = _servis.itemsData;
    final hasItems = items.isNotEmpty;
    final progress = _calculateProgress(items);

    final floorOptions = _extractFloorOptions(items);
    final filteredItems = _selectedFloor == null
        ? items
        : items.where((item) => _getFloorNumberFromItem(item) == _selectedFloor).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              kPrimaryColor.withValues(alpha: 0.2),
                              kPrimaryColor.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Iconsax.cpu, color: kPrimaryColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Daftar Unit AC',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: kPrimaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${filteredItems.length} Unit',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: kPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$progress% Selesai',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (hasItems)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: _buildProgressBar(progress),
            ),

          if (floorOptions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Lantai',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: _selectedFloor,
                        isExpanded: true,
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey[600],
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        hint: const Text('Semua lantai'),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Semua lantai'),
                          ),
                          ...floorOptions.map(
                                (floor) => DropdownMenuItem<int?>(
                              value: floor,
                              child: Text('Lantai $floor'),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedFloor = value;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: hasItems
                ? (filteredItems.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Tidak ada AC pada lantai ini',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
                : Column(
              children: filteredItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final itemId =
                    int.tryParse((item['id'] ?? '').toString()) ?? 0;
                final isLast = index == filteredItems.length - 1;

                return Column(
                  children: [
                    _buildAcListItem(context, item, itemId),
                    if (!isLast) const SizedBox(height: 14),
                  ],
                );
              }).toList(),
            ))
                : _buildFallbackAcList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress Pengerjaan',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$progress%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            return Stack(
              children: [
                Container(
                  height: 8,
                  width: maxWidth,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  height: 8,
                  width: maxWidth * (progress / 100),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimaryColor, kPrimaryColor.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildAcListItem(
      BuildContext context,
      Map<String, dynamic> item,
      int itemId,
      ) {
    final acRaw = item['ac_unit'];
    final ac = acRaw is Map<String, dynamic>
        ? acRaw
        : (acRaw is Map ? Map<String, dynamic>.from(acRaw) : <String, dynamic>{});

    final floorLabel = _getFloorLabelFromItem(item);

    final itemStatus = (item['status'] ?? '').toString().toLowerCase().trim();
    final statusColor = _statusColor(itemStatus);

    final name = (ac['name'] ?? '-').toString();
    final brand = (ac['brand'] ?? '-').toString();
    final type = (ac['type'] ?? '-').toString();
    final capacity = (ac['capacity'] ?? '-').toString();

    final hasFoto = _hasFoto(item);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeknisiAcDetailPage(
              servis: _servis,
              item: item,
              itemId: itemId,
              token: _token,
              onUpdate: _refreshFromProvider,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: itemStatus == 'selesai'
                ? Colors.green.withValues(alpha: 0.25)
                : itemStatus == 'dikerjakan'
                ? Colors.blue.withValues(alpha: 0.25)
                : Colors.grey.withValues(alpha: 0.18),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              height: 86,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 14),
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withValues(alpha: 0.18),
                        statusColor.withValues(alpha: 0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Iconsax.airdrop, color: statusColor, size: 22),
                ),
                if (itemStatus == 'selesai')
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 11),
                    ),
                  ),
                if (itemStatus == 'dikerjakan')
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Iconsax.timer, color: Colors.white, size: 9),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          _statusLabel(itemStatus),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$brand • $type',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 14,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          capacity,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: kPrimaryColor,
                          ),
                        ),
                      ),
                      if (floorLabel != '-')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Iconsax.building_3,
                                size: 11,
                                color: Colors.purple,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                floorLabel,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.purple,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      _buildCompletionBadge(
                        label: 'Foto',
                        isCompleted: hasFoto,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // const SizedBox(width: 10),
            // Container(
            //   width: 34,
            //   height: 34,
            //   decoration: BoxDecoration(
            //     color: Colors.grey[100],
            //     shape: BoxShape.circle,
            //   ),
            //   child: Icon(
            //     Iconsax.arrow_right_3,
            //     color: Colors.grey[600],
            //     size: 16,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionBadge({
    required String label,
    required bool isCompleted,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted ? color.withValues(alpha: 0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.circle_outlined,
            size: 10,
            color: isCompleted ? color : Colors.grey[400],
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: isCompleted ? color : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasFoto(Map<String, dynamic> item) {
    final sebelum = item['foto_sebelum'];
    final pengerjaan = item['foto_pengerjaan'];
    final sesudah = item['foto_sesudah'];

    if (sebelum is List && sebelum.isNotEmpty) return true;
    if (sebelum is String && sebelum.trim().isNotEmpty) return true;
    if (pengerjaan is List && pengerjaan.isNotEmpty) return true;
    if (pengerjaan is String && pengerjaan.trim().isNotEmpty) return true;
    if (sesudah is List && sesudah.isNotEmpty) return true;
    if (sesudah is String && sesudah.trim().isNotEmpty) return true;

    return false;
  }

  Widget _buildFallbackAcList() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.cpu,
              color: kPrimaryColor.withValues(alpha: 0.3),
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada data unit AC',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Unit AC akan muncul setelah teknisi ditugaskan',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    final catatan = (_servis.catatan ?? '').trim();
    final tindakan = (_servis.tindakanSummary ?? '').trim();
    final diagnosa = (_servis.diagnosa ?? '').trim();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kPrimaryColor.withValues(alpha: 0.2),
                      kPrimaryColor.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Iconsax.document_text, color: kPrimaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Detail Servis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _showAllDetails = !_showAllDetails),
                icon: Icon(
                  _showAllDetails ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailCard(
            icon: Iconsax.message_text,
            title: 'Keluhan / Catatan',
            content: catatan.isNotEmpty ? catatan : 'Tidak ada keluhan',
            color: const Color(0xFF2196F3),
          ),
          const SizedBox(height: 12),
          _buildDetailCard(
            icon: Iconsax.key,
            title: 'Tindakan',
            content: tindakan.isNotEmpty ? tindakan : 'Belum ada tindakan',
            color: const Color(0xFF4CAF50),
          ),
          if (diagnosa.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDetailCard(
              icon: Iconsax.clipboard_text,
              title: 'Diagnosa',
              content: diagnosa,
              color: const Color(0xFF9C27B0),
            ),
          ],
          if (_showAllDetails) ...[
            const SizedBox(height: 12),
            _buildDetailCard(
              icon: Iconsax.receipt_text,
              title: 'Durasi',
              content: _durationDisplay(_servis) ?? 'Belum tersedia',
              color: const Color(0xFFFF9800),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechniciansCard(List<String> technicianNames) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kPrimaryColor.withValues(alpha: 0.2),
                      kPrimaryColor.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Iconsax.profile_2user, color: kPrimaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tim Teknisi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${technicianNames.length} teknisi',
                  style: TextStyle(
                    fontSize: 12,
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: technicianNames.asMap().entries.map((entry) {
              final index = entry.key;
              final name = entry.value;
              final colors = [
                const Color(0xFF2196F3),
                const Color(0xFF4CAF50),
                const Color(0xFF9C27B0),
                const Color(0xFFFF9800),
                const Color(0xFFE91E63),
              ];
              final color = colors[index % colors.length];

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.08), color.withValues(alpha: 0.02)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withValues(alpha: 0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'T',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    final options = [
      _OptionItem(
        icon: Iconsax.share,
        label: 'Bagikan Detail',
        color: const Color(0xFF2196F3),
        onTap: () {
          Navigator.pop(context);
          _showSnackBar(context, 'Fitur bagikan akan segera hadir', Colors.blue);
        },
      ),
      _OptionItem(
        icon: Iconsax.printer,
        label: 'Cetak Laporan',
        color: const Color(0xFF4CAF50),
        onTap: () {
          Navigator.pop(context);
          _showSnackBar(context, 'Fitur cetak akan segera hadir', Colors.green);
        },
      ),
      _OptionItem(
        icon: Iconsax.message,
        label: 'Hubungi Client',
        color: const Color(0xFF9C27B0),
        onTap: () {
          Navigator.pop(context);
          _showSnackBar(
            context,
            'Fitur hubungi client akan segera hadir',
            Colors.purple,
          );
        },
      ),
      _OptionItem(
        icon: Iconsax.map,
        label: 'Buka di Maps',
        color: const Color(0xFFFF9800),
        onTap: () {
          Navigator.pop(context);
          _showSnackBar(context, 'Fitur maps akan segera hadir', Colors.orange);
        },
      ),
      _OptionItem(
        icon: Iconsax.info_circle,
        label: 'Informasi Lainnya',
        color: const Color(0xFF607D8B),
        onTap: () => Navigator.pop(context),
      ),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Opsi Tugas',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Pilih aksi yang ingin dilakukan',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 24),
                ...options.map((option) => _buildOptionTile(context, option)),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 0),
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionTile(BuildContext context, _OptionItem option) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: option.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(option.icon, color: option.color, size: 24),
      ),
      title: Text(
        option.label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      trailing: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(Iconsax.arrow_right_3, color: Colors.grey[500], size: 18),
      ),
      onTap: option.onTap,
    );
  }
}

class _OptionItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _OptionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}