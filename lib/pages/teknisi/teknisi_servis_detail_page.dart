import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/ac_model.dart';
import '../../models/lokasi_model.dart';
import '../../models/servis_model.dart';
import '../../theme/theme.dart';

class TeknisiServisDetailPage extends StatefulWidget {
  final LokasiModel lokasi;
  final AcModel ac;
  final ServisModel servis;

  const TeknisiServisDetailPage({
    super.key,
    required this.lokasi,
    required this.ac,
    required this.servis,
  });

  @override
  State<TeknisiServisDetailPage> createState() =>
      _TeknisiServisDetailPageState();
}

class _TeknisiServisDetailPageState extends State<TeknisiServisDetailPage>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _diagnosaController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  final TextEditingController _biayaServisController = TextEditingController();
  final TextEditingController _biayaSukuCadangController =
  TextEditingController();

  final List<File> _fotoSebelum = [];
  final List<File> _fotoSesudah = [];
  final List<File> _fotoSukuCadang = [];

  List<String> _selectedTindakan = [];
  late ServisStatus _currentStatus;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _currentStatus = widget.servis.status;

    _selectedTindakan = _parseInitialTindakan(widget.servis.tindakanSummary);
    _diagnosaController.text = widget.servis.diagnosa ?? '';
    _catatanController.text = widget.servis.catatan ?? '';
    _biayaServisController.text = widget.servis.biayaServis == 0
        ? ''
        : widget.servis.biayaServis.toStringAsFixed(0);
    _biayaSukuCadangController.text = widget.servis.biayaSukuCadang == 0
        ? ''
        : widget.servis.biayaSukuCadang.toStringAsFixed(0);

    _setupAnimations();
  }

  List<String> _parseInitialTindakan(String? summary) {
    final raw = (summary ?? '').trim();
    if (raw.isEmpty) return [];
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
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
    _diagnosaController.dispose();
    _catatanController.dispose();
    _biayaServisController.dispose();
    _biayaSukuCadangController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(List<File> targetList) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      targetList.add(File(image.path));
    });

    _showSnackBar('Foto berhasil ditambahkan', kBoxMenuGreenColor);
  }

  void _removeImage(List<File> targetList, int index) {
    setState(() {
      targetList.removeAt(index);
    });
    _showSnackBar('Foto dihapus', Colors.orange);
  }

  void _updateStatus(ServisStatus newStatus) {
    setState(() {
      _currentStatus = newStatus;
    });

    HapticFeedback.lightImpact();

    String message;
    Color color;

    switch (newStatus) {
      case ServisStatus.menungguKonfirmasi:
        message = '⏳ Status: Menunggu Konfirmasi';
        color = Colors.orange;
        break;
      case ServisStatus.ditugaskan:
        message = '📋 Status: Ditugaskan';
        color = Colors.blue;
        break;
      case ServisStatus.dikerjakan:
        message = '🛠️ Status: Dikerjakan';
        color = Colors.purple;
        break;
      case ServisStatus.selesai:
        message = '✅ Servis selesai';
        color = kBoxMenuGreenColor;
        break;
      case ServisStatus.batal:
        message = '❌ Servis dibatalkan';
        color = Colors.red;
        break;
    }

    _showSnackBar(message, color);
  }

  void _toggleTindakan(String tindakan) {
    setState(() {
      if (_selectedTindakan.contains(tindakan)) {
        _selectedTindakan.remove(tindakan);
        _showSnackBar('$tindakan dihapus', Colors.orange, isShort: true);
      } else {
        _selectedTindakan.add(tindakan);
        _showSnackBar('$tindakan ditambahkan', kBoxMenuGreenColor,
            isShort: true);
      }
    });
  }

  void _kirimLaporan() {
    if (_selectedTindakan.isEmpty) {
      _showDialogError(
        'Tindakan Servis Belum Dipilih',
        'Minimal pilih satu tindakan servis yang telah dilakukan.',
        Icons.handyman,
      );
      return;
    }

    if (_diagnosaController.text.trim().isEmpty) {
      _showDialogError(
        'Diagnosa Masih Kosong',
        'Isi diagnosa masalah untuk menjelaskan kondisi AC.',
        Icons.medical_services,
      );
      return;
    }

    if (_fotoSebelum.isEmpty) {
      _showDialogError(
        'Foto Sebelum Servis Diperlukan',
        'Ambil foto kondisi AC sebelum melakukan servis.',
        Icons.photo_camera_front,
      );
      return;
    }

    if (_fotoSesudah.isEmpty) {
      _showDialogError(
        'Foto Setelah Servis Diperlukan',
        'Ambil foto kondisi AC setelah selesai servis.',
        Icons.photo_camera_back,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.send_rounded, color: kPrimaryColor, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Kirim Laporan Servis?'),
          ],
        ),
        content: Text(
          'Pastikan semua data sudah lengkap:\n'
              '• ${_selectedTindakan.length} tindakan servis\n'
              '• ${_fotoSebelum.length} foto sebelum\n'
              '• ${_fotoSesudah.length} foto sesudah\n'
              '• ${_fotoSukuCadang.length} foto sparepart',
          style: greyTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(ServisStatus.selesai);
              _showSuccessDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Kirim Laporan'),
          ),
        ],
      ),
    );
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
                color: kBoxMenuRedColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: kBoxMenuRedColor, size: 32),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(message, style: greyTextStyle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Mengerti', style: TextStyle(color: kPrimaryColor)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kBoxMenuGreenColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: kBoxMenuGreenColor,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Laporan Berhasil Dikirim!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Laporan servis telah diselesaikan dan siap ditinjau.',
              style: greyTextStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBoxMenuGreenColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Kembali ke Dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color, {bool isShort = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == kBoxMenuGreenColor
                  ? Icons.check_circle
                  : color == Colors.orange
                  ? Icons.warning
                  : Icons.info,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: whiteTextStyle)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isShort ? 1 : 3),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getJenisIcon(widget.servis.jenis),
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.servis.jenisDisplay,
              style:
              whiteTextStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                kPrimaryColor,
                kPrimaryColor.withValues(alpha: 0.8),
                const Color(0xFF2A5C8A),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildModernAppBar(),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildInfoCard(),
                  ),
                  const SizedBox(height: 16),
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildStatusStepper(),
                  ),
                  const SizedBox(height: 16),
                  if ((widget.servis.keluhanClient ?? '').trim().isNotEmpty)
                    SlideTransition(
                      position: _slideAnimation,
                      child: _buildKeluhanCard(),
                    ),
                  if ((widget.servis.keluhanClient ?? '').trim().isNotEmpty)
                    const SizedBox(height: 16),
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildTindakanSection(),
                  ),
                  const SizedBox(height: 16),
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildImageSection(
                      title: 'Foto Sebelum Servis',
                      description: 'Dokumentasi kondisi AC sebelum diperbaiki',
                      images: _fotoSebelum,
                      onAdd: () => _pickImage(_fotoSebelum),
                      color: Colors.orange,
                      isRequired: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildDiagnosaSection(),
                  ),
                  const SizedBox(height: 16),
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildImageSection(
                      title: 'Foto Sparepart',
                      description: 'Dokumentasi suku cadang yang diganti',
                      images: _fotoSukuCadang,
                      onAdd: () => _pickImage(_fotoSukuCadang),
                      color: Colors.purple,
                      isRequired: false,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildImageSection(
                      title: 'Foto Setelah Servis',
                      description: 'Dokumentasi kondisi AC setelah selesai',
                      images: _fotoSesudah,
                      onAdd: () => _pickImage(_fotoSesudah),
                      color: Colors.green,
                      isRequired: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildBiayaSection(),
                  ),
                  const SizedBox(height: 24),
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildActionButton(),
                  ),
                  const SizedBox(height: 30),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.location_on_rounded,
                    color: kPrimaryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.lokasi.nama,
                      style: primaryTextStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.lokasi.alamat,
                      style: greyTextStyle.copyWith(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kSecondaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.ac_unit_rounded,
                    color: kSecondaryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.ac.nama,
                      style: primaryTextStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildTag(widget.ac.merk),
                        _buildTag(widget.ac.type),
                        _buildTag(widget.ac.kapasitas),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: kGreyColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildKeluhanCard() {
    final keluhan = (widget.servis.keluhanClient ?? '').trim();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Keluhan Klien',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
            ),
            child: Text(
              keluhan,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStepper() {
    final stepperStatuses = _stepperStatuses;
    final currentIndex = stepperStatuses.indexOf(_currentStatus);
    final safeCurrentIndex = currentIndex == -1 ? 0 : currentIndex;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.speed_rounded, color: kPrimaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Progress Servis',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _currentStatusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _currentStatusShort,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _currentStatusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (safeCurrentIndex + 1) / stepperStatuses.length,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryColor, kPrimaryColor.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: List.generate(stepperStatuses.length, (i) {
              final status = stepperStatuses[i];
              final isActive = i <= safeCurrentIndex;
              final isCurrent = i == safeCurrentIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _onStatusTap(i, safeCurrentIndex, status),
                  child: Column(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isActive ? _statusColor(status) : Colors.grey[300],
                          shape: BoxShape.circle,
                          border: isCurrent
                              ? Border.all(
                            color: _statusColor(status),
                            width: 2,
                          )
                              : null,
                        ),
                        child: Icon(
                          _getStatusIcon(status),
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _statusShort(status),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isActive ? _statusColor(status) : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _onStatusTap(int targetIndex, int currentIndex, ServisStatus status) {
    if (_currentStatus == ServisStatus.selesai ||
        _currentStatus == ServisStatus.batal) {
      _showSnackBar('Status sudah final, tidak bisa diubah', kBoxMenuRedColor);
      return;
    }

    if (targetIndex == currentIndex) return;

    if (targetIndex > currentIndex) {
      if (targetIndex != currentIndex + 1) {
        _showSnackBar(
          'Tidak bisa loncat status. Naikkan satu per satu.',
          kBoxMenuRedColor,
        );
        return;
      }
      _updateStatus(status);
      return;
    }

    _showConfirmBackDialog(status);
  }

  void _showConfirmBackDialog(ServisStatus targetStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Kembalikan Status?'),
          ],
        ),
        content: Text(
          'Anda akan mengubah status dari "${_statusText(_currentStatus)}" ke "${_statusText(targetStatus)}". Lanjutkan?',
          style: greyTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(targetStatus);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Ya, Kembalikan'),
          ),
        ],
      ),
    );
  }

  Widget _buildTindakanSection() {
    final allTindakan = _tindakanByJenis;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.handyman, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Tindakan Servis',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              if (_selectedTindakan.isNotEmpty)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_selectedTindakan.length} dipilih',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: allTindakan.map((tindakan) {
              final isSelected = _selectedTindakan.contains(tindakan);

              return FilterChip(
                label: Text(tindakan),
                selected: isSelected,
                onSelected: (_) => _toggleTindakan(tindakan),
                selectedColor: Colors.blue,
                backgroundColor: Colors.grey[50],
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.blue[700],
                  fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
                avatar: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(
                    color: isSelected
                        ? Colors.blue
                        : Colors.blue.withValues(alpha: 0.3),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection({
    required String title,
    required String description,
    required List<File> images,
    required VoidCallback onAdd,
    required Color color,
    required bool isRequired,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  title.contains('Sebelum')
                      ? Icons.photo_camera_front
                      : title.contains('Sparepart')
                      ? Icons.inventory
                      : Icons.photo_camera_back,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isRequired) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: kBoxMenuRedColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Wajib',
                              style: TextStyle(
                                fontSize: 10,
                                color: kBoxMenuRedColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (images.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.add_photo_alternate_rounded,
                      size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada foto',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap tombol di bawah untuk menambahkan foto',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ] else ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(images[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(images, index),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: Icon(Icons.add_a_photo_rounded, color: color),
            label: Text(
              images.isEmpty ? 'Ambil Foto' : 'Tambah Foto Lagi',
              style: TextStyle(color: color),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: BorderSide(color: color),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosaSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                const Icon(Icons.medical_services, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Diagnosa & Catatan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextField(
              controller: _diagnosaController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                'Contoh: Kompressor mati, freon habis, PCB rusak, dll',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextField(
              controller: _catatanController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Catatan tambahan untuk klien (opsional)',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiayaSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.withValues(alpha: 0.05),
            Colors.teal.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Biaya Servis',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBiayaTextField(
                  controller: _biayaServisController,
                  label: 'Biaya Jasa',
                  icon: Icons.build,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBiayaTextField(
                  controller: _biayaSukuCadangController,
                  label: 'Biaya Sparepart',
                  icon: Icons.inventory,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Biaya',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                Text(
                  _calculateTotalBiaya(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiayaTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
          prefixIcon: Icon(icon, size: 18, color: Colors.grey[600]),
          prefixText: 'Rp ',
          prefixStyle:
          TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildActionButton() {
    final canSend = _currentStatus == ServisStatus.dikerjakan &&
        _selectedTindakan.isNotEmpty &&
        _diagnosaController.text.trim().isNotEmpty &&
        _fotoSebelum.isNotEmpty &&
        _fotoSesudah.isNotEmpty;

    if (!canSend) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [kPrimaryColor, Color(0xFF2A5C8A)],
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _kirimLaporan,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'KIRIM LAPORAN SERVIS',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> get _tindakanByJenis {
    switch (widget.servis.jenis) {
      case JenisPenanganan.cuci:
        return const [
          'Pembersihan',
          'Ganti Filter',
          'Tune Up',
          'Lainnya',
        ];
      case JenisPenanganan.perbaikan:
        return const [
          'Perbaikan Kompressor',
          'Perbaikan PCB',
          'Ganti Kapasitor',
          'Ganti Fan Motor',
          'Isi Freon',
          'Ganti Filter',
          'Lainnya',
        ];
      case JenisPenanganan.instalasi:
        return const [
          'Instalasi Unit',
          'Vakum',
          'Isi Freon',
          'Testing',
          'Lainnya',
        ];
    }
  }

  List<ServisStatus> get _stepperStatuses => const [
    ServisStatus.menungguKonfirmasi,
    ServisStatus.ditugaskan,
    ServisStatus.dikerjakan,
    ServisStatus.selesai,
  ];

  String _statusText(ServisStatus status) {
    switch (status) {
      case ServisStatus.menungguKonfirmasi:
        return 'Menunggu Konfirmasi';
      case ServisStatus.ditugaskan:
        return 'Ditugaskan';
      case ServisStatus.dikerjakan:
        return 'Dikerjakan';
      case ServisStatus.selesai:
        return 'Selesai';
      case ServisStatus.batal:
        return 'Batal';
    }
  }

  String _statusShort(ServisStatus status) {
    switch (status) {
      case ServisStatus.menungguKonfirmasi:
        return 'Menunggu';
      case ServisStatus.ditugaskan:
        return 'Tugas';
      case ServisStatus.dikerjakan:
        return 'Proses';
      case ServisStatus.selesai:
        return 'Done';
      case ServisStatus.batal:
        return 'Batal';
    }
  }

  Color _statusColor(ServisStatus status) {
    switch (status) {
      case ServisStatus.menungguKonfirmasi:
        return Colors.orange;
      case ServisStatus.ditugaskan:
        return Colors.blue;
      case ServisStatus.dikerjakan:
        return Colors.purple;
      case ServisStatus.selesai:
        return Colors.green;
      case ServisStatus.batal:
        return Colors.red;
    }
  }

  Color get _currentStatusColor => _statusColor(_currentStatus);
  String get _currentStatusShort => _statusShort(_currentStatus);

  IconData _getJenisIcon(JenisPenanganan jenis) {
    switch (jenis) {
      case JenisPenanganan.cuci:
        return Icons.cleaning_services;
      case JenisPenanganan.perbaikan:
        return Icons.build;
      case JenisPenanganan.instalasi:
        return Icons.settings;
    }
  }

  IconData _getStatusIcon(ServisStatus status) {
    switch (status) {
      case ServisStatus.menungguKonfirmasi:
        return Icons.access_time;
      case ServisStatus.ditugaskan:
        return Icons.assignment_ind;
      case ServisStatus.dikerjakan:
        return Icons.build;
      case ServisStatus.selesai:
        return Icons.check_circle;
      case ServisStatus.batal:
        return Icons.cancel;
    }
  }

  String _calculateTotalBiaya() {
    final biayaServis = double.tryParse(_biayaServisController.text) ?? 0;
    final biayaSukuCadang = double.tryParse(_biayaSukuCadangController.text) ?? 0;
    final total = biayaServis + biayaSukuCadang;

    return 'Rp ${total.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    )}';
  }
}