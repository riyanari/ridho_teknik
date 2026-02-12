
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

  final ScrollController _scrollController = ScrollController();

  bool _showAllDetails = false;

  // Animasi
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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
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

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // =========================
  // REFRESH DATA
  // =========================
  Future<void> _refreshFromProvider() async {
    final prov = context.read<TeknisiProvider>();
    await prov.fetchTasks();
    if (!mounted) return;
    final idx = prov.tasks.indexWhere((e) => e.id == _servis.id);
    if (idx != -1) {
      setState(() => _servis = prov.tasks[idx]);
    }
  }

  // ===== status service dari item =====
  String _statusKey() {
    final items = _servis.itemsData;
    if (items.isEmpty) return _servis.status.name.toLowerCase();

    final statuses = items
        .map((it) => (it['status'] ?? '').toString().toLowerCase().trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (statuses.isEmpty) return _servis.status.name.toLowerCase();
    if (statuses.every((x) => x == 'selesai')) return 'selesai';
    final anyDitugaskan = statuses.any((x) => x == 'ditugaskan');
    if (anyDitugaskan) return 'ditugaskan';
    return 'dikerjakan';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ditugaskan':
        return const Color(0xFF2196F3);
      case 'dikerjakan':
        return const Color(0xFF9C27B0);
      case 'selesai':
        return const Color(0xFF4CAF50);
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
    if (s.jumlahAc != null && s.jumlahAc! > 0) return '${s.jumlahAc}';
    if (s.acUnitsNames.isNotEmpty) return '${s.acUnitsNames.length}';
    return '-';
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

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 18, top: 4),
          child: CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha:0.9),
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
              backgroundColor: Colors.white.withValues(alpha:0.9),
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
                    child: _buildTimelineCard(status),
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
                  if (_servis.technicianNames.isNotEmpty) ...[
                    SlideTransition(
                      position: _slideAnimation,
                      child: _buildTechniciansCard(),
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

  // ==================== HEADER ====================
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
                statusColor.withValues(alpha:0.8),
                statusColor.withValues(alpha:0.6),
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
                    color: Colors.white.withValues(alpha:0.1),
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
                    color: Colors.white.withValues(alpha:0.1),
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
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha:0.3)),
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
                        Icon(Iconsax.location,
                            size: 14, color: Colors.white.withValues(alpha:0.8)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _servis.lokasiAlamat,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha:0.9),
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
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.2),
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

  // ==================== STATS CARD ====================
  Widget _buildStatsCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
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
            value: _servis.technicianNames.isNotEmpty
                ? '${_servis.technicianNames.length}'
                : '1',
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
                colors: [color.withValues(alpha:0.15), color.withValues(alpha:0.05)],
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

  // ==================== TIMELINE CARD ====================
  Widget _buildTimelineCard(String status) {
    final steps = [
      _TimelineStep(
        icon: Iconsax.task_square,
        title: 'Ditugaskan',
        time: _servis.tanggalDitugaskan,
        isActive: true,
        isCompleted: true,
      ),
      _TimelineStep(
        icon: Iconsax.play_circle,
        title: 'Dikerjakan',
        time: _servis.tanggalMulai,
        isActive: status == 'dikerjakan' || status == 'selesai',
        isCompleted: _servis.tanggalMulai != null,
      ),
      _TimelineStep(
        icon: Iconsax.tick_circle,
        title: 'Selesai',
        time: _servis.tanggalSelesai,
        isActive: status == 'selesai',
        isCompleted: _servis.tanggalSelesai != null,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 25,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kPrimaryColor.withValues(alpha:0.2),
                      kPrimaryColor.withValues(alpha:0.1)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Iconsax.timer_1, color: kPrimaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Timeline Pengerjaan',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87),
              ),
              const Spacer(),
              if (_servis.durationDisplay != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Iconsax.clock,
                          size: 14, color: kPrimaryColor),
                      const SizedBox(width: 4),
                      Text(
                        _servis.durationDisplay!,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: kPrimaryColor),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isLast = index == steps.length - 1;

            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: step.isCompleted ? kPrimaryColor : Colors.white,
                          border: Border.all(
                            color: step.isCompleted
                                ? kPrimaryColor
                                : step.isActive
                                ? kPrimaryColor.withValues(alpha:0.3)
                                : Colors.grey[300]!,
                            width: 2,
                          ),
                          boxShadow: step.isCompleted
                              ? [
                            BoxShadow(
                              color: kPrimaryColor.withValues(alpha:0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                              : null,
                        ),
                        child: step.isCompleted
                            ? const Icon(Icons.check,
                            size: 16, color: Colors.white)
                            : step.isActive
                            ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kPrimaryColor.withValues(alpha:0.6),
                            ),
                          ),
                        )
                            : null,
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                step.isCompleted
                                    ? kPrimaryColor
                                    : Colors.grey[300]!,
                                steps[index + 1].isCompleted
                                    ? kPrimaryColor
                                    : Colors.grey[300]!,
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: step.isCompleted
                                  ? Colors.black87
                                  : (step.isActive
                                  ? Colors.black87
                                  : Colors.grey[600]),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step.time != null
                                ? _fmtDateTime(step.time!)
                                : 'Menunggu...',
                            style: TextStyle(
                              fontSize: 13,
                              color: step.time != null
                                  ? Colors.grey[600]
                                  : Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==================== LIST AC SECTION ====================
  Widget _buildAcListSection(BuildContext context) {
    final items = _servis.itemsData;
    final hasItems = items.isNotEmpty;
    final progress = _calculateProgress(items);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 25,
              offset: const Offset(0, 10)),
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
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kPrimaryColor.withValues(alpha:0.2),
                            kPrimaryColor.withValues(alpha:0.1)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Iconsax.cpu,
                          color: kPrimaryColor, size: 20),
                    ),
                    const SizedBox(width: 4),
                    Column(
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 1),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_jumlahAcDisplay(_servis)} Unit',
                            style: TextStyle(
                                fontSize: 12,
                                color: kPrimaryColor,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$progress% Selesai',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (hasItems)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: _buildProgressBar(progress),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: hasItems
                ? Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final itemId =
                    int.tryParse((item['id'] ?? '').toString()) ?? 0;
                final isLast = index == items.length - 1;

                return Column(
                  children: [
                    _buildAcListItem(context, item, itemId),
                    if (!isLast) const SizedBox(height: 12),
                  ],
                );
              }).toList(),
            )
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
            Text('Progress Pengerjaan',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500)),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$progress%',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor),
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
                      colors: [kPrimaryColor, kPrimaryColor.withValues(alpha:0.7)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 4),
        if (progress == 100)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle, color: Colors.green, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'Semua item selesai',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.green,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ==================== LIST ITEM AC (CARD) ====================
  Widget _buildAcListItem(
      BuildContext context, Map<String, dynamic> item, int itemId) {
    final ac = (item['ac_unit'] is Map)
        ? Map<String, dynamic>.from(item['ac_unit'] as Map)
        : <String, dynamic>{};

    final itemStatus = (item['status'] ?? '').toString().toLowerCase().trim();
    final statusColor = _statusColor(itemStatus);

    final name = (ac['name'] ?? '-').toString();
    final brand = (ac['brand'] ?? '-').toString();
    final type = (ac['type'] ?? '-').toString();
    final capacity = (ac['capacity'] ?? '-').toString();

    final hasFoto = _hasFoto(item);

    return GestureDetector(
      onTap: () {
        // Navigasi ke halaman detail AC
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: itemStatus == 'selesai'
                ? Colors.green.withValues(alpha:0.3)
                : itemStatus == 'dikerjakan'
                ? Colors.blue.withValues(alpha:0.3)
                : Colors.grey.withValues(alpha:0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon & Status
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withValues(alpha:0.2),
                        statusColor.withValues(alpha:0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Iconsax.airdrop,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                if (itemStatus == 'selesai')
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 12),
                    ),
                  ),
                if (itemStatus == 'dikerjakan')
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Iconsax.timer,
                          color: Colors.white, size: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // Info AC
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: statusColor.withValues(alpha:0.2)),
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
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      '$brand • $type • $capacity',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Status completion badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // _buildCompletionBadge(
                      //   label: 'Diagnosa',
                      //   isCompleted: hasDiagnosa,
                      //   color: Colors.orange,
                      // ),
                      // const SizedBox(width: 8),
                      // _buildCompletionBadge(
                      //   label: 'Tindakan',
                      //   isCompleted: hasTindakan,
                      //   color: Colors.blue,
                      // ),
                      // const SizedBox(width: 8),
                      _buildCompletionBadge(
                        label: 'Foto',
                        isCompleted: hasFoto,
                        color: Colors.green,
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Iconsax.arrow_right_3,
                          color: Colors.grey[600],
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow

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
        color: isCompleted ? color.withValues(alpha:0.1) : Colors.grey[100],
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

    if (sebelum is List) if (sebelum.isNotEmpty) return true;
    if (sebelum is String) if (sebelum.trim().isNotEmpty) return true;
    if (pengerjaan is List) if (pengerjaan.isNotEmpty) return true;
    if (pengerjaan is String) if (pengerjaan.trim().isNotEmpty) return true;
    if (sesudah is List) if (sesudah.isNotEmpty) return true;
    if (sesudah is String) if (sesudah.trim().isNotEmpty) return true;

    return false;
  }

  Widget _buildFallbackAcList() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha:0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Iconsax.cpu,
                color: kPrimaryColor.withValues(alpha:0.3), size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada data unit AC',
            style: TextStyle(
                color: Colors.grey[600],
                fontSize: 15,
                fontWeight: FontWeight.w500),
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

  // ==================== DETAIL SECTION ====================
  Widget _buildDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 25,
              offset: const Offset(0, 10))
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
                      kPrimaryColor.withValues(alpha:0.2),
                      kPrimaryColor.withValues(alpha:0.1)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                Icon(Iconsax.document_text, color: kPrimaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Detail Servis',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87),
              ),
              const Spacer(),
              IconButton(
                onPressed: () =>
                    setState(() => _showAllDetails = !_showAllDetails),
                icon: Icon(_showAllDetails
                    ? Iconsax.arrow_up_2
                    : Iconsax.arrow_down_1),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailCard(
            icon: Iconsax.message_text,
            title: 'Keluhan',
            content: _servis.catatan.isNotEmpty
                ? _servis.catatan
                : 'Tidak ada keluhan',
            color: const Color(0xFF2196F3),
          ),
          const SizedBox(height: 12),
          _buildDetailCard(
            icon: Iconsax.key,
            title: 'Tindakan',
            content: _servis.tindakan.isEmpty
                ? 'Belum ada tindakan'
                : _servis.tindakan.map((e) => e.name).join(', '),
            color: const Color(0xFF4CAF50),
          ),
          if (_servis.diagnosa.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDetailCard(
              icon: Iconsax.clipboard_text,
              title: 'Diagnosa',
              content: _servis.diagnosa,
              color: const Color(0xFF9C27B0),
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
        color: color.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha:0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: color.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(content,
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TECHNICIANS CARD ====================
  Widget _buildTechniciansCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 25,
              offset: const Offset(0, 10))
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
                      kPrimaryColor.withValues(alpha:0.2),
                      kPrimaryColor.withValues(alpha:0.1)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Iconsax.profile_2user,
                    color: kPrimaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tim Teknisi',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87),
              ),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(
                  '${_servis.technicianNames.length} teknisi',
                  style: TextStyle(
                      fontSize: 12,
                      color: kPrimaryColor,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _servis.technicianNames.asMap().entries.map((entry) {
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
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha:0.08), color.withValues(alpha:0.02)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha:0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withValues(alpha:0.7)],
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
                              color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      name,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87),
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
          _showSnackBar(context, 'Fitur bagikan akan segera hadir',
              Colors.blue);
        },
      ),
      _OptionItem(
        icon: Iconsax.printer,
        label: 'Cetak Laporan',
        color: const Color(0xFF4CAF50),
        onTap: () {
          Navigator.pop(context);
          _showSnackBar(
              context, 'Fitur cetak akan segera hadir', Colors.green);
        },
      ),
      _OptionItem(
        icon: Iconsax.message,
        label: 'Hubungi Client',
        color: const Color(0xFF9C27B0),
        onTap: () {
          Navigator.pop(context);
          _showSnackBar(context, 'Fitur hubungi client akan segera hadir',
              Colors.purple);
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
                topLeft: Radius.circular(32), topRight: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha:0.2),
                  blurRadius: 30,
                  offset: const Offset(0, -10)),
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
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text('Opsi Tugas',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text('Pilih aksi yang ingin dilakukan',
                      style:
                      TextStyle(fontSize: 14, color: Colors.grey[600])),
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
                          borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 0),
                    ),
                    child: const Text('Tutup',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
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
            color: option.color.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(14)),
        child: Icon(option.icon, color: option.color, size: 24),
      ),
      title: Text(option.label,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87)),
      trailing: Container(
        width: 32,
        height: 32,
        decoration:
        BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
        child: Icon(Iconsax.arrow_right_3, color: Colors.grey[500], size: 18),
      ),
      onTap: option.onTap,
    );
  }
}

class _TimelineStep {
  final IconData icon;
  final String title;
  final DateTime? time;
  final bool isActive;
  final bool isCompleted;

  _TimelineStep({
    required this.icon,
    required this.title,
    required this.time,
    required this.isActive,
    required this.isCompleted,
  });
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