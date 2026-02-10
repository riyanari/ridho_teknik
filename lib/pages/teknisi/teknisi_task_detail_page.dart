import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/servis_model.dart';
import '../../providers/teknisi_provider.dart';
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

class _TeknisiTaskDetailPageState extends State<TeknisiTaskDetailPage> {
  // ✅ Paling stabil: simpan servis di state, dan refresh dari provider setelah aksi
  late ServisModel _servis;

  // ✅ untuk auto-scroll ke item yang baru di-start
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {};

  bool _pickingPhoto = false;
  final Set<int> _uploadingItems = {};
  bool _showAllDetails = false;

  // draft foto per item
  final Map<int, List<String>> _draftSebelum = {};
  final Map<int, List<String>> _draftPengerjaan = {};
  final Map<int, List<String>> _draftSesudah = {};

  // input per item
  final Map<int, TextEditingController> _diagnosaCtrls = {};
  final Map<int, TextEditingController> _tindakanCtrls = {};

  bool _isUploading(int itemId) => _uploadingItems.contains(itemId);

  List<String> _draftOf(Map<int, List<String>> map, int itemId) => map[itemId] ?? [];

  void _setDraft(Map<int, List<String>> map, int itemId, List<String> paths) {
    setState(() => map[itemId] = paths);
  }

  void _removeDraftAt(Map<int, List<String>> map, int itemId, int index) {
    final list = [..._draftOf(map, itemId)];
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    _setDraft(map, itemId, list);
  }

  void _clearDraft(Map<int, List<String>> map, int itemId) {
    setState(() => map.remove(itemId));
  }

  TextEditingController _diagCtrl(int itemId, {String initial = ''}) {
    return _diagnosaCtrls.putIfAbsent(itemId, () => TextEditingController(text: initial));
  }

  TextEditingController _tindCtrl(int itemId, {String initial = ''}) {
    return _tindakanCtrls.putIfAbsent(itemId, () => TextEditingController(text: initial));
  }

  GlobalKey _keyForItem(int itemId) {
    return _itemKeys.putIfAbsent(itemId, () => GlobalKey());
  }

  @override
  void initState() {
    super.initState();
    _servis = widget.servis;
  }

  @override
  void dispose() {
    for (final c in _diagnosaCtrls.values) {
      c.dispose();
    }
    for (final c in _tindakanCtrls.values) {
      c.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  // =========================
  // REFRESH "BENAR": ambil data terbaru dari provider setelah aksi
  // =========================
  Future<void> _refreshFromProvider({int? ensureItemId}) async {
    final prov = context.read<TeknisiProvider>();

    // paling aman: hit endpoint tasks lagi
    await prov.fetchTasks();

    if (!mounted) return;

    final idx = prov.tasks.indexWhere((e) => e.id == _servis.id);
    if (idx != -1) {
      setState(() => _servis = prov.tasks[idx]);
    }

    // auto scroll ke item yang baru berubah
    if (ensureItemId != null) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      final key = _itemKeys[ensureItemId];
      final ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: 0.15,
        );
      }
    }
  }

  // ===== picker =====
  Future<List<String>> _pickImagesSheet(BuildContext context) async {
    if (_pickingPhoto) return [];
    _pickingPhoto = true;

    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
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
                    'Pilih Sumber Foto',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSourceOption(
                      context,
                      icon: Iconsax.camera,
                      label: 'Kamera',
                      color: kPrimaryColor,
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                    ),
                    _buildSourceOption(
                      context,
                      icon: Iconsax.gallery,
                      label: 'Galeri',
                      color: Colors.indigo,
                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      );

      if (!mounted || source == null) return [];
      final picker = ImagePicker();

      if (source == ImageSource.camera) {
        final x = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
        if (x == null) return [];
        return [x.path];
      } else {
        final xs = await picker.pickMultiImage(imageQuality: 85);
        return xs.map((e) => e.path).toList();
      }
    } finally {
      _pickingPhoto = false;
    }
  }

  static Widget _buildSourceOption(
      BuildContext context, {
        required IconData icon,
        required String label,
        required Color color,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha:0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha:0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // ===== snack =====
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

  // ===== status service dari item (RULE STABIL) =====
  // - kalau semua selesai => selesai
  // - kalau ada yang masih ditugaskan => ditugaskan
  // - sisanya => dikerjakan
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

  // ===== Backend actions =====
  Future<void> _startItem(BuildContext context, int itemId) async {
    if (_isUploading(itemId)) return;
    setState(() => _uploadingItems.add(itemId));

    try {
      final prov = context.read<TeknisiProvider>();
      final ok = await prov.startItem(itemId);

      if (!mounted) return;

      if (ok) {
        await _refreshFromProvider(ensureItemId: itemId);
        _showSnackBar(context, 'Item mulai dikerjakan', Colors.green, icon: Iconsax.tick_circle);
      } else {
        _showSnackBar(context, prov.submitError ?? 'Gagal mulai item', Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(context, 'Gagal: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _uploadingItems.remove(itemId));
    }
  }

  Future<void> _uploadProgress(
      BuildContext context,
      int itemId, {
        List<String> fotoSebelum = const [],
        List<String> fotoPengerjaan = const [],
        List<String> fotoSesudah = const [],
        bool includeText = false,
      }) async {
    if (_isUploading(itemId)) return;

    if (fotoSebelum.isEmpty && fotoPengerjaan.isEmpty && fotoSesudah.isEmpty && !includeText) {
      _showSnackBar(context, 'Tidak ada data untuk diupload', Colors.orange);
      return;
    }

    setState(() => _uploadingItems.add(itemId));

    try {
      final prov = context.read<TeknisiProvider>();
      final diag = includeText ? _diagCtrl(itemId).text.trim() : null;
      final tind = includeText ? _tindCtrl(itemId).text.trim() : null;

      final ok = await prov.updateItemProgress(
        itemId,
        diagnosa: diag,
        tindakan: tind,
        fotoSebelum: fotoSebelum,
        fotoPengerjaan: fotoPengerjaan,
        fotoSesudah: fotoSesudah,
      );

      if (!mounted) return;

      if (ok) {
        if (fotoSebelum.isNotEmpty) _clearDraft(_draftSebelum, itemId);
        if (fotoPengerjaan.isNotEmpty) _clearDraft(_draftPengerjaan, itemId);
        if (fotoSesudah.isNotEmpty) _clearDraft(_draftSesudah, itemId);

        await _refreshFromProvider(ensureItemId: itemId);

        _showSnackBar(context, 'Progress tersimpan', Colors.green, icon: Iconsax.tick_circle);
      } else {
        _showSnackBar(context, prov.submitError ?? 'Gagal simpan progress', Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(context, 'Gagal: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _uploadingItems.remove(itemId));
    }
  }

  Future<void> _finishItem(BuildContext context, int itemId) async {
    if (_isUploading(itemId)) return;

    final diag = _diagCtrl(itemId).text.trim();
    final tind = _tindCtrl(itemId).text.trim();
    final draftSesudah = _draftOf(_draftSesudah, itemId);

    setState(() => _uploadingItems.add(itemId));
    try {
      final prov = context.read<TeknisiProvider>();
      final ok = await prov.finishItem(
        itemId,
        diagnosa: diag.isEmpty ? null : diag,
        tindakan: tind.isEmpty ? null : tind,
        fotoSesudah: draftSesudah,
      );

      if (!mounted) return;

      if (ok) {
        _clearDraft(_draftSesudah, itemId);

        await _refreshFromProvider(ensureItemId: itemId);

        _showSnackBar(context, 'Item selesai', Colors.green, icon: Iconsax.tick_circle);
      } else {
        _showSnackBar(context, prov.submitError ?? 'Gagal menyelesaikan item', Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(context, 'Gagal: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _uploadingItems.remove(itemId));
    }
  }

  // ===== parse list foto dari itemsData =====
  List<String> _listFrom(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
    return [];
  }

  // ===== SERVER PHOTO BLOCK (untuk item selesai) =====
  Widget _serverPhotoBlock({
    required String title,
    required List<String> urls,
  }) {
    if (urls.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title  •  Server: 0',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.grey[800]),
            ),
            const SizedBox(height: 6),
            Text('Tidak ada foto di server', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title  •  Server: ${urls.length}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.grey[800]),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: urls.length,
            itemBuilder: (context, index) {
              final url = urls[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  url,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.broken_image)),
                  ),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===== UI =====
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
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
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
                      statusColor.withValues(alpha:0.9),
                      statusColor.withValues(alpha:0.7),
                      statusColor.withValues(alpha:0.5),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Iconsax.location, size: 14, color: Colors.white.withValues(alpha:0.8)),
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStatsCard(context),
                const SizedBox(height: 20),
                _buildTimelineCard(status),
                const SizedBox(height: 20),
                _buildAcSectionCard(context),
                const SizedBox(height: 20),
                _buildDetailsSection(),
                const SizedBox(height: 20),
                if (_servis.technicianNames.isNotEmpty) ...[
                  _buildTechniciansCard(),
                  const SizedBox(height: 20),
                ],
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ===== Cards =====
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
            value: _servis.technicianNames.isNotEmpty ? '${_servis.technicianNames.length}' : '1',
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
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

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
          BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 25, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.timer_1, color: kPrimaryColor, size: 20),
              const SizedBox(width: 10),
              const Text(
                'Timeline Pengerjaan',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black87),
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
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: step.isCompleted ? kPrimaryColor : Colors.white,
                          border: Border.all(
                            color: step.isCompleted
                                ? kPrimaryColor
                                : step.isActive
                                ? kPrimaryColor.withValues(alpha:0.3)
                                : Colors.grey[300]!,
                            width: 3,
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
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : step.isActive
                            ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
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
                          color: step.isCompleted ? kPrimaryColor : Colors.grey[300],
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
                                  : (step.isActive ? Colors.black87 : Colors.grey[600]),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step.time != null ? _fmtDateTime(step.time!) : 'Menunggu...',
                            style: TextStyle(
                              fontSize: 13,
                              color: step.time != null ? Colors.grey[600] : Colors.grey[400],
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

  Widget _buildAcSectionCard(BuildContext context) {
    final items = _servis.itemsData;
    final hasItems = items.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 25, offset: const Offset(0, 10)),
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
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kPrimaryColor.withValues(alpha:0.2), kPrimaryColor.withValues(alpha:0.1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Iconsax.cpu, color: kPrimaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Unit AC',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_jumlahAcDisplay(_servis)} Unit',
                    style: TextStyle(fontSize: 12, color: kPrimaryColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: hasItems
                ? Column(
              children: items.map((item) {
                final itemId = int.tryParse((item['id'] ?? '').toString()) ?? 0;
                return Container(
                  key: _keyForItem(itemId),
                  child: _buildAcItemCard(context, item),
                );
              }).toList(),
            )
                : _buildFallbackAcList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAcItemCard(BuildContext context, Map<String, dynamic> item) {
    final ac = (item['ac_unit'] is Map) ? Map<String, dynamic>.from(item['ac_unit'] as Map) : <String, dynamic>{};
    final itemId = int.tryParse((item['id'] ?? '').toString()) ?? 0;
    final itemStatus = (item['status'] ?? '').toString().toLowerCase().trim();

    final name = (ac['name'] ?? '-').toString();
    final brand = (ac['brand'] ?? '-').toString();
    final type = (ac['type'] ?? '-').toString();
    final capacity = (ac['capacity'] ?? '-').toString();

    final statusColor = _statusColor(itemStatus);
    final isSelesaiItem = itemStatus == 'selesai';
    final isDikerjakanItem = itemStatus == 'dikerjakan';

    final serverSebelum = _listFrom(item['foto_sebelum']);
    final serverPengerjaan = _listFrom(item['foto_pengerjaan']);
    final serverSesudah = _listFrom(item['foto_sesudah']);

    final initialDiag = (item['diagnosa'] ?? '').toString();
    final initialTind = (item['tindakan'] ?? '').toString();

    final draftSebelum = _draftOf(_draftSebelum, itemId);
    final draftPengerjaan = _draftOf(_draftPengerjaan, itemId);
    final draftSesudah = _draftOf(_draftSesudah, itemId);

    final diagCtrl = _diagCtrl(itemId, initial: initialDiag);
    final tindCtrl = _tindCtrl(itemId, initial: initialTind);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[50]!, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryColor.withValues(alpha:0.15), kPrimaryColor.withValues(alpha:0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Iconsax.airdrop, color: kPrimaryColor, size: 28),
              ),
              const SizedBox(width: 16),
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
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor.withValues(alpha:0.2)),
                          ),
                          child: Text(
                            _statusLabel(itemStatus),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$brand • $type • $capacity',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // action row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAcDetailDialog(context, ac),
                  icon: const Icon(Iconsax.document_text, size: 16),
                  label: const Text('Detail'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (isSelesaiItem || _isUploading(itemId)) ? null : () => _startItem(context, itemId),
                  icon: _isUploading(itemId)
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Icon(Iconsax.play_circle, size: 16),
                  label: Text(isSelesaiItem ? 'Selesai' : (isDikerjakanItem ? 'Sedang' : 'Mulai')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),

          // progress section
          if (isDikerjakanItem || isSelesaiItem) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            Text('Diagnosa', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey[800])),
            const SizedBox(height: 8),
            TextField(
              controller: diagCtrl,
              readOnly: isSelesaiItem,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tulis diagnosa...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                isDense: true,
                filled: isSelesaiItem,
                fillColor: isSelesaiItem ? Colors.grey[100] : null,
              ),
            ),
            const SizedBox(height: 12),
            Text('Tindakan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey[800])),
            const SizedBox(height: 8),
            TextField(
              controller: tindCtrl,
              readOnly: isSelesaiItem,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tulis tindakan...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                isDense: true,
                filled: isSelesaiItem,
                fillColor: isSelesaiItem ? Colors.grey[100] : null,
              ),
            ),
            const SizedBox(height: 12),

            // tombol simpan text (disabled kalau selesai)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: (isSelesaiItem || _isUploading(itemId)) ? null : () => _uploadProgress(context, itemId, includeText: true),
                icon: const Icon(Iconsax.save_2, size: 16),
                label: const Text('Simpan Diagnosa & Tindakan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimaryColor,
                  side: BorderSide(color: kPrimaryColor.withValues(alpha:0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // FOTO SEBELUM
            if (isSelesaiItem)
              _serverPhotoBlock(title: 'Foto Sebelum', urls: serverSebelum)
            else
              _photoBlock(
                title: 'Foto Sebelum',
                serverCount: serverSebelum.length,
                draft: draftSebelum,
                onPick: () async {
                  final picked = await _pickImagesSheet(context);
                  if (!mounted || picked.isEmpty) return;
                  _setDraft(_draftSebelum, itemId, [...draftSebelum, ...picked]);
                },
                onRemoveDraft: (idx) => _removeDraftAt(_draftSebelum, itemId, idx),
                onUpload: () => _uploadProgress(context, itemId, fotoSebelum: draftSebelum),
                uploading: _isUploading(itemId),
              ),

            const SizedBox(height: 16),

            // FOTO PENGERJAAN
            if (isSelesaiItem)
              _serverPhotoBlock(title: 'Foto Pengerjaan', urls: serverPengerjaan)
            else
              _photoBlock(
                title: 'Foto Pengerjaan',
                serverCount: serverPengerjaan.length,
                draft: draftPengerjaan,
                onPick: () async {
                  final picked = await _pickImagesSheet(context);
                  if (!mounted || picked.isEmpty) return;
                  _setDraft(_draftPengerjaan, itemId, [...draftPengerjaan, ...picked]);
                },
                onRemoveDraft: (idx) => _removeDraftAt(_draftPengerjaan, itemId, idx),
                onUpload: () => _uploadProgress(context, itemId, fotoPengerjaan: draftPengerjaan),
                uploading: _isUploading(itemId),
              ),

            const SizedBox(height: 16),

            // FOTO SESUDAH
            if (isSelesaiItem)
              _serverPhotoBlock(title: 'Foto Sesudah', urls: serverSesudah)
            else
              _photoBlock(
                title: 'Foto Sesudah',
                serverCount: serverSesudah.length,
                draft: draftSesudah,
                onPick: () async {
                  final picked = await _pickImagesSheet(context);
                  if (!mounted || picked.isEmpty) return;
                  _setDraft(_draftSesudah, itemId, [...draftSesudah, ...picked]);
                },
                onRemoveDraft: (idx) => _removeDraftAt(_draftSesudah, itemId, idx),
                onUpload: () => _uploadProgress(context, itemId, fotoSesudah: draftSesudah),
                uploading: _isUploading(itemId),
              ),

            const SizedBox(height: 16),

            // FINISH ITEM
            if (!isSelesaiItem)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUploading(itemId) ? null : () => _finishItem(context, itemId),
                  icon: _isUploading(itemId)
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Iconsax.tick_circle, size: 18),
                  label: const Text('Selesaikan Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _photoBlock({
    required String title,
    required int serverCount,
    required List<String> draft,
    required VoidCallback? onPick,
    required void Function(int index) onRemoveDraft,
    required VoidCallback? onUpload,
    required bool uploading,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$title  •  Server: $serverCount',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.grey[800]),
                ),
              ),
              if (onPick != null)
                IconButton(
                  onPressed: onPick,
                  icon: const Icon(Iconsax.add, size: 18),
                ),
            ],
          ),
          if (draft.isNotEmpty) ...[
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: draft.length,
              itemBuilder: (context, index) {
                final path = draft[index];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(path),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => onRemoveDraft(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha:0.6), shape: BoxShape.circle),
                          child: const Icon(Iconsax.trash, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (onUpload == null || uploading) ? null : onUpload,
                icon: uploading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Iconsax.export, size: 16),
                label: Text(uploading ? 'Mengupload...' : 'Upload $title'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text('Belum ada draft', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ],
      ),
    );
  }

  Widget _buildFallbackAcList() {
    return Center(
      child: Column(
        children: [
          Icon(Iconsax.cpu, color: Colors.grey[300], size: 64),
          const SizedBox(height: 16),
          Text('Tidak ada data unit AC', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 25, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryColor.withValues(alpha:0.2), kPrimaryColor.withValues(alpha:0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Iconsax.document_text, color: kPrimaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Detail Servis',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailItem(
            icon: Iconsax.message_text,
            title: 'Keluhan',
            content: _servis.catatan,
            color: const Color(0xFF2196F3),
          ),
          const SizedBox(height: 16),
          _buildDetailItem(
            icon: Iconsax.note_text,
            title: 'Tindakan',
            content: _servis.tindakan.isEmpty ? 'Belum ada tindakan' : _servis.tindakan.map((e) => e.name).join(', '),
            color: const Color(0xFF4CAF50),
          ),
          if (_servis.diagnosa.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDetailItem(
              icon: Iconsax.clipboard_text,
              title: 'Diagnosa',
              content: _servis.diagnosa,
              color: const Color(0xFF9C27B0),
            ),
          ],
          if (_servis.catatan.length > 100 || (_servis.diagnosa.trim().isNotEmpty && _servis.diagnosa.length > 100)) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.center,
              child: TextButton.icon(
                onPressed: () => setState(() => _showAllDetails = !_showAllDetails),
                icon: Icon(_showAllDetails ? Iconsax.arrow_up_2 : Iconsax.arrow_down_2, size: 14),
                label: Text(
                  _showAllDetails ? 'Tampilkan lebih sedikit' : 'Tampilkan lebih banyak',
                  style: TextStyle(fontSize: 13, color: kPrimaryColor, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem({
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha:0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  _showAllDetails ? content : _truncateText(content, 100),
                  style: TextStyle(fontSize: 14, color: Colors.grey[800], fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  Widget _buildTechniciansCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 25, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryColor.withValues(alpha:0.2), kPrimaryColor.withValues(alpha:0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Iconsax.profile_2user, color: kPrimaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tim Teknisi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _servis.technicianNames.map((name) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryColor.withValues(alpha:0.08), kPrimaryColor.withValues(alpha:0.03)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kPrimaryColor.withValues(alpha:0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kPrimaryColor.withValues(alpha:0.2), kPrimaryColor.withValues(alpha:0.1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'T',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kPrimaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showAcDetailDialog(BuildContext context, Map<String, dynamic> ac) {
    final name = (ac['name'] ?? '-').toString();
    final brand = (ac['brand'] ?? '-').toString();
    final type = (ac['type'] ?? '-').toString();
    final capacity = (ac['capacity'] ?? '-').toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.2), blurRadius: 30, offset: const Offset(0, -10))],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kPrimaryColor.withValues(alpha:0.2), kPrimaryColor.withValues(alpha:0.1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Iconsax.airdrop, color: kPrimaryColor, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 4),
                            Text('$brand • $type', style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildAcDetailRow('Nama Unit', name),
                  const SizedBox(height: 12),
                  _buildAcDetailRow('Merk', brand),
                  const SizedBox(height: 12),
                  _buildAcDetailRow('Type', type),
                  const SizedBox(height: 12),
                  _buildAcDetailRow('Kapasitas', capacity),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: const Text('Tutup'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAcDetailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500))),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    final options = [
      _OptionItem(icon: Iconsax.share, label: 'Bagikan Detail', color: const Color(0xFF2196F3)),
      _OptionItem(icon: Iconsax.printer, label: 'Cetak Laporan', color: const Color(0xFF4CAF50)),
      _OptionItem(icon: Iconsax.message, label: 'Hubungi Client', color: const Color(0xFF9C27B0)),
      _OptionItem(icon: Iconsax.map, label: 'Buka di Maps', color: const Color(0xFFFF9800)),
      _OptionItem(icon: Iconsax.info_circle, label: 'Informasi Lainnya', color: const Color(0xFF607D8B)),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.2), blurRadius: 30, offset: const Offset(0, -10))],
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
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Opsi Tugas',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text('Pilih aksi yang ingin dilakukan', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 0),
                    ),
                    child: const Text('Tutup'),
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
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: option.color.withValues(alpha:0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(option.icon, color: option.color, size: 22),
      ),
      title: Text(option.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
      trailing: Icon(Iconsax.arrow_right_3, color: Colors.grey[400], size: 18),
      onTap: () => Navigator.pop(context),
    );
  }

  String _jumlahAcDisplay(ServisModel s) {
    if (s.itemsData.isNotEmpty) return '${s.itemsData.length}';
    if (s.jumlahAc != null && s.jumlahAc! > 0) return '${s.jumlahAc}';
    if (s.acUnitsNames.isNotEmpty) return '${s.acUnitsNames.length}';
    return '-';
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

  _OptionItem({required this.icon, required this.label, required this.color});
}
