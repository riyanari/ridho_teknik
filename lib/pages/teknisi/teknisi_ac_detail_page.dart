import 'dart:io';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/servis_model.dart';
import '../../providers/teknisi_provider.dart';
import '../../theme/theme.dart';
import '../../utils/photo_url_helper.dart';

class TeknisiAcDetailPage extends StatefulWidget {
  final ServisModel servis;
  final Map<String, dynamic> item;
  final int itemId;
  final String? token;
  final Future<void> Function() onUpdate;

  const TeknisiAcDetailPage({
    super.key,
    required this.servis,
    required this.item,
    required this.itemId,
    required this.token,
    required this.onUpdate,
  });

  @override
  State<TeknisiAcDetailPage> createState() => _TeknisiAcDetailPageState();
}

class _TeknisiAcDetailPageState extends State<TeknisiAcDetailPage>
    with SingleTickerProviderStateMixin {
  late Map<String, dynamic> _item;
  late String? _token;
  late int _itemId;

  bool _pickingPhoto = false;
  final Set<int> _uploadingItems = {};

  // draft foto per item
  final Map<int, List<String>> _draftSebelum = {};
  final Map<int, List<String>> _draftPengerjaan = {};
  final Map<int, List<String>> _draftSesudah = {};

  // input
  late TextEditingController _diagnosaCtrl;
  late TextEditingController _tindakanCtrl;

  // animasi
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _token = widget.token;
    _itemId = widget.itemId;

    final initialDiag = (_item['diagnosa'] ?? '').toString();
    final initialTind = (_item['tindakan'] ?? '').toString();

    _diagnosaCtrl = TextEditingController(text: initialDiag);
    _tindakanCtrl = TextEditingController(text: initialTind);

    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _diagnosaCtrl.dispose();
    _tindakanCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Map<String, String> get _authHeaders {
    final t = (_token ?? '').trim();
    if (t.isEmpty) return const {};
    return {'Authorization': 'Bearer $t', 'Accept': 'image/*'};
  }

  bool _isUploading() => _uploadingItems.contains(_itemId);

  List<String> _draftOf(Map<int, List<String>> map) => map[_itemId] ?? [];

  void _setDraft(Map<int, List<String>> map, List<String> paths) =>
      setState(() => map[_itemId] = paths);

  void _removeDraftAt(Map<int, List<String>> map, int index) {
    final list = [..._draftOf(map)];
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    _setDraft(map, list);
  }

  void _clearDraft(Map<int, List<String>> map) =>
      setState(() => map.remove(_itemId));

  String get _itemStatus =>
      (_item['status'] ?? '').toString().toLowerCase().trim();

  bool get _isSelesai => _itemStatus == 'selesai';
  bool get _isDikerjakan => _itemStatus == 'dikerjakan';
  bool get _isDitugaskan => _itemStatus == 'ditugaskan';

  Color get _statusColor {
    switch (_itemStatus) {
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

  String get _statusLabel {
    switch (_itemStatus) {
      case 'ditugaskan':
        return 'Ditugaskan';
      case 'dikerjakan':
        return 'Dikerjakan';
      case 'selesai':
        return 'Selesai';
      default:
        return _itemStatus;
    }
  }

  List<String> get _serverSebelum => asServiceItemPhotoUrls(
    itemId: _itemId,
    type: 'sebelum',
    valueFromApi: _item['foto_sebelum'],
  );

  List<String> get _serverPengerjaan => asServiceItemPhotoUrls(
    itemId: _itemId,
    type: 'pengerjaan',
    valueFromApi: _item['foto_pengerjaan'],
  );

  List<String> get _serverSesudah => asServiceItemPhotoUrls(
    itemId: _itemId,
    type: 'sesudah',
    valueFromApi: _item['foto_sesudah'],
  );

  // ===== ACTIONS =====
  Future<void> _startItem() async {
    if (_isUploading()) return;

    // Tampilkan Awesome Dialog konfirmasi dengan desain kustom
    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.bottomSlide,
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha:0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.play_circle,
                size: 60,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Mulai Pengerjaan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withValues(alpha:0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Iconsax.info_circle,
                            color: Colors.blue, size: 16),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Setelah mulai, Anda dapat:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildBulletPoint('Mengisi diagnosa kondisi AC'),
                  const SizedBox(height: 8),
                  _buildBulletPoint('Mencatat tindakan yang dilakukan'),
                  const SizedBox(height: 8),
                  _buildBulletPoint('Mengupload foto dokumentasi'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Apakah Anda yakin ingin memulai?',
              style: TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
      btnCancelText: 'BATAL',
      btnOkText: 'YA, MULAI',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        setState(() => _uploadingItems.add(_itemId));

        try {
          final prov = context.read<TeknisiProvider>();
          final ok = await prov.startItem(_itemId);

          if (!mounted) return;

          if (ok) {
            // Update local state IMMEDIATELY
            setState(() {
              _item['status'] = 'dikerjakan';
            });

            // Then sync with server
            await widget.onUpdate();

            if (mounted) {
              // HAPUS baris ini karena menyebabkan dialog tertutup:
              // Navigator.of(context, rootNavigator: true).pop();

              // Show success dialog - pastikan context masih valid
              AwesomeDialog(
                context: context,
                dialogType: DialogType.success,
                animType: AnimType.scale,
                title: 'Berhasil Dimulai!',
                desc: 'Silakan lakukan pengerjaan dan lengkapi data yang diperlukan',
                btnOkText: 'OK',
                btnOkOnPress: () {
                  // Dialog akan otomatis tertutup setelah OK ditekan
                  // Tidak perlu navigasi kembali
                },
              ).show();
            }
          } else {
            if (mounted) {
              AwesomeDialog(
                context: context,
                dialogType: DialogType.error,
                animType: AnimType.scale,
                title: 'Gagal',
                desc: prov.submitError ?? 'Gagal mulai item',
                btnOkText: 'MENGERTI',
              ).show();
            }
          }
        } catch (e) {
          if (mounted) {
            AwesomeDialog(
              context: context,
              dialogType: DialogType.error,
              animType: AnimType.scale,
              title: 'Error',
              desc: 'Terjadi kesalahan: $e',
              btnOkText: 'MENGERTI',
            ).show();
          }
        } finally {
          if (mounted) setState(() => _uploadingItems.remove(_itemId));
        }
      },
      btnCancelColor: Colors.grey,
      btnOkColor: Colors.blue,
    ).show();
  }

// Helper widget untuk bullet points
  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(fontSize: 14, color: Colors.blue)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Future<void> _uploadProgress({
    List<String> fotoSebelum = const [],
    List<String> fotoPengerjaan = const [],
    List<String> fotoSesudah = const [],
    bool includeText = false,
  }) async {
    if (_isUploading()) return;

    if (fotoSebelum.isEmpty &&
        fotoPengerjaan.isEmpty &&
        fotoSesudah.isEmpty &&
        !includeText) {
      _showSnackBar('Tidak ada data untuk diupload', Colors.orange);
      return;
    }

    setState(() => _uploadingItems.add(_itemId));

    try {
      final prov = context.read<TeknisiProvider>();
      final diag = includeText ? _diagnosaCtrl.text.trim() : null;
      final tind = includeText ? _tindakanCtrl.text.trim() : null;

      final ok = await prov.updateItemProgress(
        _itemId,
        diagnosa: diag,
        tindakan: tind,
        fotoSebelum: fotoSebelum,
        fotoPengerjaan: fotoPengerjaan,
        fotoSesudah: fotoSesudah,
      );

      if (!mounted) return;

      if (ok) {
        if (fotoSebelum.isNotEmpty) _clearDraft(_draftSebelum);
        if (fotoPengerjaan.isNotEmpty) _clearDraft(_draftPengerjaan);
        if (fotoSesudah.isNotEmpty) _clearDraft(_draftSesudah);

        await widget.onUpdate();

        if (mounted) {
          _showSnackBar('Progress tersimpan', Colors.green);

          // Update local item
          final prov = context.read<TeknisiProvider>();
          final servisIdx =
          prov.tasks.indexWhere((e) => e.id == widget.servis.id);
          if (servisIdx != -1) {
            final updatedServis = prov.tasks[servisIdx];
            final updatedItem = updatedServis.itemsData.firstWhere(
                  (e) => (e['id'].toString() == _itemId.toString()),
              orElse: () => _item,
            );
            setState(() => _item = updatedItem);
          }
        }
      } else {
        _showSnackBar(prov.submitError ?? 'Gagal simpan progress', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Gagal: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _uploadingItems.remove(_itemId));
    }
  }

  Future<void> _finishItem() async {
    if (_isUploading()) return;

    final diag = _diagnosaCtrl.text.trim();
    final tind = _tindakanCtrl.text.trim();
    final draftSesudah = _draftOf(_draftSesudah);

    if (diag.isEmpty) {
      _showDialogError(
        'Diagnosa Diperlukan',
        'Isi diagnosa untuk menjelaskan kondisi AC sebelum menyelesaikan item.',
        Iconsax.clipboard_text,
      );
      return;
    }

    if (tind.isEmpty) {
      _showDialogError(
        'Tindakan Diperlukan',
        'Isi tindakan yang telah dilakukan pada AC ini.',
        Iconsax.key,
      );
      return;
    }

    if (draftSesudah.isEmpty && _serverSesudah.isEmpty) {
      _showDialogError(
        'Foto Sesudah Diperlukan',
        'Ambil foto kondisi AC setelah selesai diservis.',
        Iconsax.camera,
      );
      return;
    }

    _showFinishConfirmationDialog(diag, tind, draftSesudah);
  }

  void _showDialogError(String title, String message, IconData icon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kBoxMenuRedColor.withValues(alpha:0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: kBoxMenuRedColor, size: 32),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message,
            style: greyTextStyle, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Mengerti', style: TextStyle(color: kPrimaryColor)),
          ),
        ],
      ),
    );
  }

  void _showFinishConfirmationDialog(
      String diag,
      String tind,
      List<String> draftSesudah,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha:0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.tick_circle,
                  color: Colors.green, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Selesaikan Item?',
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pastikan semua data sudah lengkap:', style: greyTextStyle),
            const SizedBox(height: 12),
            _buildCheckItem('Diagnosa', diag),
            const SizedBox(height: 8),
            _buildCheckItem('Tindakan', tind),
            const SizedBox(height: 8),
            _buildCheckItem(
                'Foto Sesudah',
                draftSesudah.isNotEmpty
                    ? '${draftSesudah.length} foto draft'
                    : '${_serverSesudah.length} foto server'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _executeFinishItem(diag, tind, draftSesudah);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Selesaikan'),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  )),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _executeFinishItem(
      String diag,
      String tind,
      List<String> draftSesudah,
      ) async {
    setState(() => _uploadingItems.add(_itemId));

    try {
      final prov = context.read<TeknisiProvider>();
      final ok = await prov.finishItem(
        _itemId,
        diagnosa: diag.isEmpty ? null : diag,
        tindakan: tind.isEmpty ? null : tind,
        fotoSesudah: draftSesudah,
      );

      if (!mounted) return;

      if (ok) {
        _clearDraft(_draftSesudah);
        await widget.onUpdate();

        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        _showSnackBar(prov.submitError ?? 'Gagal menyelesaikan item',
            Colors.red);
      }
    } catch (e) {
      _showSnackBar('Gagal: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _uploadingItems.remove(_itemId));
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha:0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.tick_circle,
                  color: Colors.green, size: 64),
            ),
            const SizedBox(height: 24),
            const Text('Item Selesai!',
                style:
                TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'Item servis telah diselesaikan dan laporan telah dikirim.',
              style: greyTextStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // back to list
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
                color == Colors.green
                    ? Iconsax.tick_circle
                    : color == Colors.orange
                    ? Iconsax.info_circle
                    : Iconsax.close_circle,
                color: Colors.white,
                size: 20),
            const SizedBox(width: 8),
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

  // ===== PICKER =====
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
                color: Colors.black.withValues(alpha: 0.2),
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
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
        final x = await picker.pickImage(
            source: ImageSource.camera, imageQuality: 85);
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

  Widget _buildSourceOption(
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
                colors: [color, color.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndAppendDraft(
      Map<int, List<String>> draftMap,
      ) async {
    final picked = await _pickImagesSheet(context);
    if (!mounted || picked.isEmpty) return;

    final current = _draftOf(draftMap);
    _setDraft(draftMap, [...current, ...picked]);
  }

  // ===== UI BUILD =====
  @override
  Widget build(BuildContext context) {
    final ac = (_item['ac_unit'] is Map)
        ? Map<String, dynamic>.from(_item['ac_unit'] as Map)
        : <String, dynamic>{};

    final name = (ac['name'] ?? '-').toString();
    final brand = (ac['brand'] ?? '-').toString();
    final type = (ac['type'] ?? '-').toString();
    final capacity = (ac['capacity'] ?? '-').toString();
    final location = (ac['location'] ?? '-').toString();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Detail AC',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left,
              color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildAcHeader(
                  context,
                  name: name,
                  brand: brand,
                  type: type,
                  capacity: capacity,
                  location: location,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),

                  // Status Card
                  _buildStatusCard(),

                  const SizedBox(height: 20),

                  // Diagnosa & Tindakan Section
                  _buildDiagnosaTindakanSection(),

                  const SizedBox(height: 20),

                  // Dokumentasi Foto
                  _buildPhotoDocumentationSection(),

                  const SizedBox(height: 20),

                  // Action Buttons
                  _buildActionButtons(),

                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== DIAGNOSA & TINDAKAN SECTION =====
  Widget _buildDiagnosaTindakanSection() {
    if (_isDitugaskan) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
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
                    color: Colors.blue.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.info_circle,
                      color: Colors.blue, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Mulai pengerjaan untuk mengisi diagnosa dan tindakan',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_isSelesai) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
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
                    color: Colors.orange.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.clipboard_text,
                      color: Colors.orange, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Diagnosa',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha:0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha:0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _diagnosaCtrl.text.trim().isEmpty
                        ? 'Tidak ada diagnosa'
                        : _diagnosaCtrl.text.trim(),
                    style: TextStyle(
                      fontSize: 14,
                      color: _diagnosaCtrl.text.trim().isEmpty
                          ? Colors.grey[500]
                          : Colors.black87,
                      fontStyle: _diagnosaCtrl.text.trim().isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.key, color: Colors.blue, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Tindakan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha:0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha:0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tindakanCtrl.text.trim().isEmpty
                        ? 'Tidak ada tindakan'
                        : _tindakanCtrl.text.trim(),
                    style: TextStyle(
                      fontSize: 14,
                      color: _tindakanCtrl.text.trim().isEmpty
                          ? Colors.grey[500]
                          : Colors.black87,
                      fontStyle: _tindakanCtrl.text.trim().isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // _isDikerjakan
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
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
                  color: Colors.orange.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Iconsax.clipboard_text,
                    color: Colors.orange, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Diagnosa & Tindakan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Diagnosa Field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha:0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withValues(alpha:0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Iconsax.clipboard_text,
                          color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Diagnosa',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const Spacer(),
                    if (_diagnosaCtrl.text.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Terisi',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _diagnosaCtrl,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Kompressor mati, freon habis, PCB rusak...',
                    hintStyle:
                    TextStyle(fontSize: 13, color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tindakan Field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha:0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withValues(alpha:0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child:
                      const Icon(Iconsax.key, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Tindakan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Spacer(),
                    if (_tindakanCtrl.text.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Terisi',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tindakanCtrl,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText:
                    'Contoh: Ganti kapasitor, isi freon, bersihkan evaporator...',
                    hintStyle:
                    TextStyle(fontSize: 13, color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUploading() ? null : () => _uploadProgress(includeText: true),
              icon: _isUploading()
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Iconsax.save_2, size: 18),
              label: Text(
                _isUploading() ? 'Menyimpan...' : 'Simpan Diagnosa & Tindakan',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcHeader(
      BuildContext context, {
        required String name,
        required String brand,
        required String type,
        required String capacity,
        required String location,
      }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.03),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _statusColor.withValues(alpha:0.2),
                      _statusColor.withValues(alpha:0.05)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Iconsax.airdrop,
                  color: _statusColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$brand • $type',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Iconsax.speedometer,
                            color: kPrimaryColor, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Kapasitas',
                              style:
                              TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(capacity,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Iconsax.location,
                              color: Colors.blue, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Lokasi',
                                style:
                                TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(location,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _statusColor.withValues(alpha:0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _itemStatus == 'selesai'
                  ? Iconsax.tick_circle
                  : _itemStatus == 'dikerjakan'
                  ? Iconsax.timer
                  : Iconsax.task_square,
              color: _statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Pengerjaan',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _statusColor,
                  ),
                ),
              ],
            ),
          ),
          if (_isSelesai)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Selesai',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoDocumentationSection() {
    final draftSebelum = _draftOf(_draftSebelum);
    final draftPengerjaan = _draftOf(_draftPengerjaan);
    final draftSesudah = _draftOf(_draftSesudah);

    final serverSebelum = _serverSebelum;
    final serverPengerjaan = _serverPengerjaan;
    final serverSesudah = _serverSesudah;

    if (_isDitugaskan) {
      return SizedBox.shrink();  // This will hide the photo documentation section
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
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
                  color: kPrimaryColor.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Iconsax.gallery, color: kPrimaryColor, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Dokumentasi Foto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Jika SELESAI: Tampilkan foto dari server
          if (_isSelesai) ...[
            if (serverSebelum.isEmpty &&
                serverPengerjaan.isEmpty &&
                serverSesudah.isEmpty)
              _buildEmptyPhotoState()
            else ...[
              if (serverSebelum.isNotEmpty)
                _buildServerPhotoCategory(
                    'Sebelum', serverSebelum, Colors.orange),
              const SizedBox(height: 16),
              if (serverPengerjaan.isNotEmpty)
                _buildServerPhotoCategory(
                    'Pengerjaan', serverPengerjaan, Colors.blue),
              const SizedBox(height: 16),
              if (serverSesudah.isNotEmpty)
                _buildServerPhotoCategory(
                    'Sesudah', serverSesudah, Colors.green),
            ],
          ] else ...[
            // Jika DIKERJAKAN: Tampilkan draft + upload
            _buildPhotoBlock(
              title: 'Foto Sebelum',
              subtitle: 'Wajib diisi',
              icon: Iconsax.camera,
              color: Colors.orange,
              draft: draftSebelum,
              serverCount: serverSebelum.length,
              onPick: _isUploading()
                  ? null
                  : () => _pickAndAppendDraft(_draftSebelum),
              onRemoveDraft: (idx) => _removeDraftAt(_draftSebelum, idx),
              onUpload: _isUploading()
                  ? null
                  : () => _uploadProgress(fotoSebelum: draftSebelum),
              uploading: _isUploading(),
              isRequired: true,
            ),
            const SizedBox(height: 16),

            _buildPhotoBlock(
              title: 'Foto Pengerjaan',
              subtitle: 'Opsional',
              icon: Iconsax.camera,
              color: Colors.blue,
              draft: draftPengerjaan,
              serverCount: serverPengerjaan.length,
              onPick: _isUploading()
                  ? null
                  : () => _pickAndAppendDraft(_draftPengerjaan),
              onRemoveDraft: (idx) => _removeDraftAt(_draftPengerjaan, idx),
              onUpload: _isUploading()
                  ? null
                  : () => _uploadProgress(fotoPengerjaan: draftPengerjaan),
              uploading: _isUploading(),
              isRequired: false,
            ),
            const SizedBox(height: 16),

            _buildPhotoBlock(
              title: 'Foto Sesudah',
              subtitle: 'Wajib diisi',
              icon: Iconsax.camera,
              color: Colors.green,
              draft: draftSesudah,
              serverCount: serverSesudah.length,
              onPick: _isUploading()
                  ? null
                  : () => _pickAndAppendDraft(_draftSesudah),
              onRemoveDraft: (idx) => _removeDraftAt(_draftSesudah, idx),
              onUpload: _isUploading()
                  ? null
                  : () => _uploadProgress(fotoSesudah: draftSesudah),
              uploading: _isUploading(),
              isRequired: true,
            ),

            // Tampilkan foto server yang sudah ada (jika ada)
            if (serverSebelum.isNotEmpty ||
                serverPengerjaan.isNotEmpty ||
                serverSesudah.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Foto Tersimpan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              if (serverSebelum.isNotEmpty)
                _buildServerPhotoCategory(
                    'Sebelum', serverSebelum, Colors.orange),
              const SizedBox(height: 12),
              if (serverPengerjaan.isNotEmpty)
                _buildServerPhotoCategory(
                    'Pengerjaan', serverPengerjaan, Colors.blue),
              const SizedBox(height: 12),
              if (serverSesudah.isNotEmpty)
                _buildServerPhotoCategory(
                    'Sesudah', serverSesudah, Colors.green),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoBlock({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<String> draft,
    required int serverCount,
    required VoidCallback? onPick,
    required void Function(int index) onRemoveDraft,
    required VoidCallback? onUpload,
    required bool uploading,
    required bool isRequired,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (serverCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$serverCount tersimpan',
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Draft photos grid
        if (draft.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: draft.length,
            itemBuilder: (context, index) {
              final path = draft[index];
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: FileImage(File(path)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => onRemoveDraft(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha:0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Iconsax.trash,
                            color: Colors.white, size: 12),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
        ],

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Iconsax.add, size: 16),
                label: Text(
                  draft.isEmpty ? 'Ambil Foto' : 'Tambah',
                  style: TextStyle(fontSize: 12, color: color),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color.withValues(alpha:0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (onUpload == null || uploading || draft.isEmpty)
                    ? null
                    : onUpload,
                icon: uploading
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Iconsax.cloud_plus, size: 16),
                label: Text(
                  uploading ? 'Upload...' : 'Upload',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: draft.isEmpty ? Colors.grey[300] : color,
                  foregroundColor:
                  draft.isEmpty ? Colors.grey[600] : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),

        if (isRequired && draft.isEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Iconsax.info_circle,
                    size: 14, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Foto $title wajib diupload sebelum menyelesaikan item',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildServerPhotoCategory(
      String title, List<String> photos, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Foto $title',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${photos.length}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: photos.length > 4 ? 4 : photos.length,
          itemBuilder: (context, index) {
            final url = photos[index];
            return GestureDetector(
              onTap: () => _showFullScreenImage(context, url),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  headers: _authHeaders,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(Icons.broken_image,
                          color: Colors.grey[400], size: 20),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (photos.length > 4) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _showFullGallery(context, title, photos, color),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Lihat ${photos.length} foto',
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyPhotoState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.photo_camera_back,
                size: 32, color: Colors.grey[400]),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum Ada Dokumentasi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Foto dokumentasi belum tersedia',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.6,
                color: Colors.black,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  headers: _authHeaders,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image,
                        color: Colors.white70, size: 40),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha:0.5),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullGallery(
      BuildContext context, String title, List<String> photos, Color color) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha:0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Foto $title',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${photos.length} foto',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  final url = photos[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showFullScreenImage(context, url);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        headers: _authHeaders,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                              child: Icon(Icons.broken_image,
                                  color: Colors.grey)),
                        ),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isDitugaskan) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isUploading() ? null : _startItem,
          icon: _isUploading()
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white),
          )
              : const Icon(Iconsax.play_circle, size: 22),
          label: Text(
            _isUploading() ? 'MEMULAI...' : 'MULAI KERJAKAN',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 2,
          ),
        ),
      );
    }

    if (_isDikerjakan) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green, Colors.green.withValues(alpha:0.8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha:0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _isUploading() ? null : _finishItem,
          icon: _isUploading()
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white),
          )
              : const Icon(Iconsax.tick_circle, size: 18),
          label: Text(
            _isUploading() ? 'Menyelesaikan...' : 'Selesaikan Item Servis',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            minimumSize: const Size(double.infinity, 56),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      );
    }

    if (_isSelesai) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.withValues(alpha:0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.tick_circle,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Item Selesai',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Servis telah diselesaikan',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}