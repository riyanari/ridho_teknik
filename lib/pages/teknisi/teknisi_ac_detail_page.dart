import 'dart:io';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  State<TeknisiAcDetailPage> createState() =>
      _TeknisiAcDetailPageState();
}

class _TeknisiAcDetailPageState extends State<TeknisiAcDetailPage> {
  late Map<String, dynamic> _item;
  late String? _token;
  late int _itemId;

  final ImagePicker _picker = ImagePicker();

  bool _pickingPhoto = false;
  bool _processing = false;

  int _currentStep = 0;

  static const int _totalSteps = 6;

  // ============================================================
  // DRAFT PHOTO
  // ============================================================

  final List<String> _draftSebelum = [];
  final List<String> _draftPengerjaan = [];
  final List<String> _draftSesudah = [];

  // ============================================================
  // INPUT
  // ============================================================

  late TextEditingController _diagnosaCtrl;
  late TextEditingController _tindakanCtrl;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _item = Map<String, dynamic>.from(widget.item);

    _token = widget.token;
    _itemId = widget.itemId;

    _diagnosaCtrl = TextEditingController(
      text: (_item['diagnosa'] ?? '').toString(),
    );

    _tindakanCtrl = TextEditingController(
      text: (_item['tindakan'] ?? '').toString(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _currentStep = _resolveInitialStep();
      });
    });
  }

  @override
  void dispose() {
    _diagnosaCtrl.dispose();
    _tindakanCtrl.dispose();

    super.dispose();
  }

  // ============================================================
  // AUTH
  // ============================================================

  Map<String, String> get _authHeaders {
    final token = (_token ?? '').trim();

    if (token.isEmpty) {
      return const {};
    }

    return {
      'Authorization': 'Bearer $token',
      'Accept': 'image/*',
    };
  }

  // ============================================================
  // AC DATA
  // ============================================================

  Map<String, dynamic> get _ac {
    final raw = _item['ac_unit'];

    if (raw is Map<String, dynamic>) {
      return raw;
    }

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    return {};
  }

  Map<String, dynamic> get _room {
    final raw = _ac['room'];

    if (raw is Map<String, dynamic>) {
      return raw;
    }

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    return {};
  }

  String get _acName {
    final value = (_ac['name'] ?? '').toString().trim();

    return value.isEmpty ? 'Unit AC' : value;
  }

  String get _roomName {
    final value = (_room['name'] ?? '').toString().trim();

    return value.isEmpty ? '-' : value;
  }

  String get _brand {
    final value = (_ac['brand'] ?? '').toString().trim();

    return value.isEmpty ? '-' : value;
  }

  String get _type {
    final value = (_ac['type'] ?? '').toString().trim();

    return value.isEmpty ? '-' : value;
  }

  String get _capacity {
    final value = (_ac['capacity'] ?? '').toString().trim();

    return value.isEmpty ? '-' : value;
  }

  String get _floorName {
    final raw = _room['floor'];

    if (raw is Map) {
      final name = (raw['name'] ?? '').toString().trim();

      if (name.isNotEmpty) {
        return name;
      }

      final number = (raw['number'] ?? '').toString().trim();

      if (number.isNotEmpty && number != '0') {
        return 'Lantai $number';
      }
    }

    return '-';
  }

  // ============================================================
  // STATUS
  // ============================================================

  String get _itemStatus =>
      (_item['status'] ?? '').toString().toLowerCase().trim();

  bool get _isDitugaskan => _itemStatus == 'ditugaskan';

  bool get _isDikerjakan => _itemStatus == 'dikerjakan';

  bool get _isSelesai => _itemStatus == 'selesai';

  Color get _statusColor {
    switch (_itemStatus) {
      case 'ditugaskan':
        return const Color(0xFF2F80ED);

      case 'dikerjakan':
        return const Color(0xFFA533C6);

      case 'selesai':
        return const Color(0xFF2EAF62);

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

  // ============================================================
  // SERVER PHOTOS
  // ============================================================

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

  // ============================================================
  // INITIAL STEP
  // ============================================================

  int _resolveInitialStep() {
    if (_isSelesai) {
      return 5;
    }

    if (_isDitugaskan) {
      return 0;
    }

    if (_serverSebelum.isEmpty) {
      return 1;
    }

    if (_serverPengerjaan.isEmpty) {
      return 2;
    }

    if (_serverSesudah.isEmpty) {
      return 3;
    }

    if (_diagnosaCtrl.text.trim().isEmpty ||
        _tindakanCtrl.text.trim().isEmpty) {
      return 4;
    }

    return 5;
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refreshLocalItem() async {
    await widget.onUpdate();

    if (!mounted) return;

    final provider = context.read<TeknisiProvider>();

    final servisIndex = provider.tasks.indexWhere(
          (s) => s.id == widget.servis.id,
    );

    if (servisIndex == -1) {
      return;
    }

    final updatedServis = provider.tasks[servisIndex];

    final updatedItem = updatedServis.itemsData.firstWhere(
          (item) => item['id'].toString() == _itemId.toString(),
      orElse: () => _item,
    );

    if (!mounted) return;

    setState(() {
      _item = Map<String, dynamic>.from(updatedItem);

      _diagnosaCtrl.text =
          (_item['diagnosa'] ?? '').toString();

      _tindakanCtrl.text =
          (_item['tindakan'] ?? '').toString();
    });
  }

  // ============================================================
  // START ITEM
  // ============================================================

  Future<void> _startItem() async {
    if (_processing) return;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.scale,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          18,
          18,
          18,
          8,
        ),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(
                  alpha: 0.10,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.play_circle,
                size: 34,
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'Mulai Pengerjaan?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              'Status unit akan berubah menjadi Dikerjakan dan proses dokumentasi dapat dimulai.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                children: [
                  _StaticInfoRow(
                    icon: Iconsax.camera,
                    text: 'Foto sebelum wajib',
                  ),
                  SizedBox(height: 8),
                  _StaticInfoRow(
                    icon: Iconsax.setting_2,
                    text: 'Foto pengerjaan wajib',
                  ),
                  SizedBox(height: 8),
                  _StaticInfoRow(
                    icon: Iconsax.gallery_tick,
                    text: 'Foto sesudah wajib',
                  ),
                  SizedBox(height: 8),
                  _StaticInfoRow(
                    icon: Iconsax.clipboard_text,
                    text: 'Diagnosa & tindakan wajib',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      btnCancelText: 'Batal',
      btnOkText: 'Mulai',
      btnCancelColor: Colors.grey,
      btnOkColor: Colors.blue,
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        setState(() {
          _processing = true;
        });

        try {
          final provider =
          context.read<TeknisiProvider>();

          final ok =
          await provider.startItem(
            _itemId,
          );

          if (!mounted) return;

          if (!ok) {
            _showError(
              provider.submitError ??
                  'Gagal memulai pekerjaan.',
            );

            return;
          }

          setState(() {
            _item['status'] = 'dikerjakan';
            _currentStep = 1;
          });

          await _refreshLocalItem();

          if (!mounted) return;

          HapticFeedback.mediumImpact();

          _showSnackBar(
            'Pengerjaan dimulai',
            Colors.green,
          );
        } catch (e) {
          _showError(
            'Terjadi kesalahan: $e',
          );
        } finally {
          if (mounted) {
            setState(() {
              _processing = false;
            });
          }
        }
      },
    ).show();
  }

  // ============================================================
  // UPLOAD
  // ============================================================

  Future<bool> _uploadProgress({
    List<String> fotoSebelum = const [],
    List<String> fotoPengerjaan = const [],
    List<String> fotoSesudah = const [],
    bool includeText = false,
  }) async {
    if (_processing) {
      return false;
    }

    final hasAnything =
        fotoSebelum.isNotEmpty ||
            fotoPengerjaan.isNotEmpty ||
            fotoSesudah.isNotEmpty ||
            includeText;

    if (!hasAnything) {
      return true;
    }

    setState(() {
      _processing = true;
    });

    try {
      final provider =
      context.read<TeknisiProvider>();

      final ok =
      await provider.updateItemProgress(
        _itemId,
        diagnosa: includeText
            ? _diagnosaCtrl.text.trim()
            : null,
        tindakan: includeText
            ? _tindakanCtrl.text.trim()
            : null,
        fotoSebelum: fotoSebelum,
        fotoPengerjaan: fotoPengerjaan,
        fotoSesudah: fotoSesudah,
      );

      if (!mounted) {
        return false;
      }

      if (!ok) {
        _showError(
          provider.submitError ??
              'Gagal menyimpan progress.',
        );

        return false;
      }

      if (fotoSebelum.isNotEmpty) {
        _draftSebelum.clear();
      }

      if (fotoPengerjaan.isNotEmpty) {
        _draftPengerjaan.clear();
      }

      if (fotoSesudah.isNotEmpty) {
        _draftSesudah.clear();
      }

      await _refreshLocalItem();

      return true;
    } catch (e) {
      if (mounted) {
        _showError(
          'Gagal menyimpan: $e',
        );
      }

      return false;
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  // ============================================================
  // NEXT STEP
  // ============================================================

  Future<void> _nextStep() async {
    FocusScope.of(context).unfocus();

    if (_processing) return;

    // ==========================================================
    // STEP 0
    // ==========================================================

    if (_currentStep == 0) {
      if (_isDitugaskan) {
        await _startItem();
        return;
      }

      setState(() {
        _currentStep = 1;
      });

      return;
    }

    // ==========================================================
    // STEP 1
    // ==========================================================

    if (_currentStep == 1) {
      if (_serverSebelum.isEmpty &&
          _draftSebelum.isEmpty) {
        _showValidationDialog(
          'Foto Sebelum Wajib',
          'Ambil minimal satu foto kondisi AC sebelum pengerjaan.',
          Iconsax.camera,
        );

        return;
      }

      if (_draftSebelum.isNotEmpty) {
        final ok =
        await _uploadProgress(
          fotoSebelum:
          List<String>.from(
            _draftSebelum,
          ),
        );

        if (!ok) return;
      }

      if (!mounted) return;

      setState(() {
        _currentStep = 2;
      });

      HapticFeedback.lightImpact();

      return;
    }

    // ==========================================================
    // STEP 2
    // ==========================================================

    if (_currentStep == 2) {
      if (_serverPengerjaan.isEmpty &&
          _draftPengerjaan.isEmpty) {
        _showValidationDialog(
          'Foto Pengerjaan Wajib',
          'Ambil minimal satu foto saat proses pengerjaan berlangsung.',
          Iconsax.setting_2,
        );

        return;
      }

      if (_draftPengerjaan.isNotEmpty) {
        final ok =
        await _uploadProgress(
          fotoPengerjaan:
          List<String>.from(
            _draftPengerjaan,
          ),
        );

        if (!ok) return;
      }

      if (!mounted) return;

      setState(() {
        _currentStep = 3;
      });

      HapticFeedback.lightImpact();

      return;
    }

    // ==========================================================
    // STEP 3
    // ==========================================================

    if (_currentStep == 3) {
      if (_serverSesudah.isEmpty &&
          _draftSesudah.isEmpty) {
        _showValidationDialog(
          'Foto Sesudah Wajib',
          'Ambil minimal satu foto kondisi AC setelah pekerjaan selesai.',
          Iconsax.gallery_tick,
        );

        return;
      }

      if (_draftSesudah.isNotEmpty) {
        final ok =
        await _uploadProgress(
          fotoSesudah:
          List<String>.from(
            _draftSesudah,
          ),
        );

        if (!ok) return;
      }

      if (!mounted) return;

      setState(() {
        _currentStep = 4;
      });

      HapticFeedback.lightImpact();

      return;
    }

    // ==========================================================
    // STEP 4
    // ==========================================================

    if (_currentStep == 4) {
      final diagnosa =
      _diagnosaCtrl.text.trim();

      final tindakan =
      _tindakanCtrl.text.trim();

      if (diagnosa.isEmpty) {
        _showValidationDialog(
          'Diagnosa Wajib',
          'Isi hasil pemeriksaan atau diagnosa kondisi AC.',
          Iconsax.clipboard_text,
        );

        return;
      }

      if (tindakan.isEmpty) {
        _showValidationDialog(
          'Tindakan Wajib',
          'Isi tindakan yang telah dilakukan pada unit AC.',
          Iconsax.setting_2,
        );

        return;
      }

      final ok =
      await _uploadProgress(
        includeText: true,
      );

      if (!ok || !mounted) {
        return;
      }

      setState(() {
        _currentStep = 5;
      });

      HapticFeedback.lightImpact();

      return;
    }

    // ==========================================================
    // STEP 5
    // ==========================================================

    if (_currentStep == 5) {
      if (_isSelesai) {
        Navigator.pop(context);
        return;
      }

      if (!_isAllComplete) {
        _showValidationDialog(
          'Laporan Belum Lengkap',
          'Lengkapi seluruh tahapan sebelum menyelesaikan item.',
          Iconsax.info_circle,
        );

        return;
      }

      _showFinishConfirmation();
    }
  }

  bool get _isAllComplete {
    return _serverSebelum.isNotEmpty &&
        _serverPengerjaan.isNotEmpty &&
        _serverSesudah.isNotEmpty &&
        _diagnosaCtrl.text.trim().isNotEmpty &&
        _tindakanCtrl.text.trim().isNotEmpty;
  }

  // ============================================================
  // PREVIOUS
  // ============================================================

  void _previousStep() {
    FocusScope.of(context).unfocus();

    if (_processing) return;

    if (_isSelesai ||
        _currentStep == 0) {
      Navigator.pop(context);

      return;
    }

    setState(() {
      _currentStep--;
    });

    HapticFeedback.selectionClick();
  }

  // ============================================================
  // FINISH
  // ============================================================

  void _showFinishConfirmation() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.scale,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.green
                    .withValues(
                  alpha: 0.10,
                ),
                shape:
                BoxShape.circle,
              ),
              child:
              const Icon(
                Iconsax.tick_circle,
                size: 38,
                color:
                Colors.green,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            const Text(
              'Selesaikan Item?',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              'Pastikan seluruh data pekerjaan sudah benar.',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color:
                Colors.grey[600],
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            _confirmRow(
              'Foto Sebelum',
              '${_serverSebelum.length} foto',
            ),

            _confirmRow(
              'Foto Pengerjaan',
              '${_serverPengerjaan.length} foto',
            ),

            _confirmRow(
              'Foto Sesudah',
              '${_serverSesudah.length} foto',
            ),

            _confirmRow(
              'Diagnosa',
              'Lengkap',
            ),

            _confirmRow(
              'Tindakan',
              'Lengkap',
              last: true,
            ),
          ],
        ),
      ),
      btnCancelText:
      'Periksa Lagi',
      btnOkText:
      'Selesaikan',
      btnCancelColor:
      Colors.grey,
      btnOkColor:
      Colors.green,
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        await _executeFinishItem();
      },
    ).show();
  }

  Future<void> _executeFinishItem() async {
    if (_processing) return;

    setState(() {
      _processing = true;
    });

    try {
      final provider =
      context.read<TeknisiProvider>();

      final ok =
      await provider.finishItem(
        _itemId,
        diagnosa:
        _diagnosaCtrl.text.trim(),
        tindakan:
        _tindakanCtrl.text.trim(),
        fotoSesudah: const [],
      );

      if (!mounted) return;

      if (!ok) {
        _showError(
          provider.submitError ??
              'Gagal menyelesaikan item.',
        );

        return;
      }

      setState(() {
        _item['status'] =
        'selesai';
      });

      await _refreshLocalItem();

      if (!mounted) return;

      _showSuccessDialog();
    } catch (e) {
      _showError(
        'Gagal menyelesaikan item: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  Widget _confirmRow(
      String label,
      String value, {
        bool last = false,
      }) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        vertical: 9,
      ),
      decoration:
      BoxDecoration(
        border: last
            ? null
            : Border(
          bottom:
          BorderSide(
            color:
            Colors.grey[100]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style:
              TextStyle(
                fontSize: 12,
                color:
                Colors.grey[600],
              ),
            ),
          ),

          const Icon(
            Iconsax.tick_circle,
            color:
            Colors.green,
            size: 15,
          ),

          const SizedBox(
            width: 5,
          ),

          Text(
            value,
            style:
            const TextStyle(
              fontSize: 12,
              fontWeight:
              FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUCCESS
  // ============================================================

  void _showSuccessDialog() {
    AwesomeDialog(
      context: context,
      dialogType:
      DialogType.noHeader,
      animType:
      AnimType.scale,
      dismissOnTouchOutside:
      false,
      dismissOnBackKeyPress:
      false,
      body: Padding(
        padding:
        const EdgeInsets.all(
          18,
        ),
        child: Column(
          children: [
            Container(
              width: 82,
              height: 82,
              decoration:
              BoxDecoration(
                color: Colors.green
                    .withValues(
                  alpha: 0.10,
                ),
                shape:
                BoxShape.circle,
              ),
              child:
              const Icon(
                Iconsax.tick_circle,
                size: 46,
                color:
                Colors.green,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            const Text(
              'Item Selesai',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 7,
            ),

            Text(
              'Laporan pekerjaan unit AC berhasil disimpan.',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color:
                Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
      btnOkText:
      'OK',
      btnOkColor:
      Colors.green,
      btnOkOnPress: () {
        Navigator.pop(context);
      },
    ).show();
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<List<String>>
  _pickImagesSheet() async {
    if (_pickingPhoto) {
      return [];
    }

    _pickingPhoto = true;

    try {
      final source =
      await showModalBottomSheet<
          ImageSource>(
        context: context,
        backgroundColor:
        Colors.transparent,
        builder: (
            bottomContext,
            ) {
          return Container(
            decoration:
            const BoxDecoration(
              color:
              Colors.white,
              borderRadius:
              BorderRadius.vertical(
                top:
                Radius.circular(
                  24,
                ),
              ),
            ),
            child:
            SafeArea(
              child:
              Padding(
                padding:
                const EdgeInsets.fromLTRB(
                  18,
                  10,
                  18,
                  22,
                ),
                child:
                Column(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration:
                      BoxDecoration(
                        color: Colors
                            .grey[300],
                        borderRadius:
                        BorderRadius.circular(
                          4,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    const Text(
                      'Tambah Foto',
                      style:
                      TextStyle(
                        fontSize: 17,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      'Pilih sumber foto dokumentasi',
                      style:
                      TextStyle(
                        fontSize: 11,
                        color:
                        Colors.grey[600],
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    Row(
                      children: [
                        Expanded(
                          child:
                          _sourceButton(
                            icon:
                            Iconsax.camera,
                            label:
                            'Kamera',
                            color:
                            Colors.blue,
                            onTap:
                                () {
                              Navigator.pop(
                                bottomContext,
                                ImageSource.camera,
                              );
                            },
                          ),
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        Expanded(
                          child:
                          _sourceButton(
                            icon:
                            Iconsax.gallery,
                            label:
                            'Galeri',
                            color:
                            Colors.purple,
                            onTap:
                                () {
                              Navigator.pop(
                                bottomContext,
                                ImageSource.gallery,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      if (source == null) {
        return [];
      }

      if (source ==
          ImageSource.camera) {
        final file =
        await _picker.pickImage(
          source:
          ImageSource.camera,
          imageQuality: 85,
        );

        if (file == null) {
          return [];
        }

        return [
          file.path,
        ];
      }

      final files =
      await _picker.pickMultiImage(
        imageQuality: 85,
      );

      return files
          .map(
            (file) => file.path,
      )
          .toList();
    } finally {
      _pickingPhoto = false;
    }
  }

  Widget _sourceButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
      BorderRadius.circular(
        16,
      ),
      child: Container(
        padding:
        const EdgeInsets.symmetric(
          vertical: 18,
        ),
        decoration:
        BoxDecoration(
          color:
          color.withValues(
            alpha: 0.06,
          ),
          borderRadius:
          BorderRadius.circular(
            16,
          ),
          border:
          Border.all(
            color:
            color.withValues(
              alpha: 0.15,
            ),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration:
              BoxDecoration(
                color:
                color.withValues(
                  alpha: 0.11,
                ),
                shape:
                BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 23,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              label,
              style:
              const TextStyle(
                fontSize: 12,
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndAppend(
      List<String> draft,
      ) async {
    final files =
    await _pickImagesSheet();

    if (!mounted ||
        files.isEmpty) {
      return;
    }

    setState(() {
      draft.addAll(files);
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return PopScope(
      canPop:
      !_processing,
      child: Scaffold(
        backgroundColor:
        const Color(
          0xFFF6F7FB,
        ),
        body:
        SafeArea(
          child:
          Column(
            children: [
              _buildAppBar(),

              _buildStepperHeader(),

              Expanded(
                child:
                SingleChildScrollView(
                  physics:
                  const BouncingScrollPhysics(),
                  padding:
                  const EdgeInsets.fromLTRB(
                    16,
                    14,
                    16,
                    24,
                  ),
                  child:
                  AnimatedSize(
                    duration:
                    const Duration(
                      milliseconds:
                      220,
                    ),
                    curve:
                    Curves.easeOut,
                    alignment:
                    Alignment.topCenter,
                    child:
                    KeyedSubtree(
                      key:
                      ValueKey(
                        _currentStep,
                      ),
                      child:
                      _buildCurrentStep(),
                    ),
                  ),
                ),
              ),

              _buildBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  Widget _buildAppBar() {
    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        10,
        6,
        14,
        7,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.white,
        border: Border(
          bottom:
          BorderSide(
            color:
            Colors.grey[100]!,
          ),
        ),
      ),
      child:
      Row(
        children: [
          InkWell(
            onTap: _processing
                ? null
                : _previousStep,
            borderRadius:
            BorderRadius.circular(
              12,
            ),
            child:
            Container(
              width: 40,
              height: 40,
              decoration:
              BoxDecoration(
                color:
                const Color(
                  0xFFF4F5F9,
                ),
                borderRadius:
                BorderRadius.circular(
                  12,
                ),
              ),
              child:
              const Icon(
                Iconsax.arrow_left_2,
                size: 19,
              ),
            ),
          ),

          const SizedBox(
            width: 11,
          ),

          Expanded(
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  _roomName != '-'
                      ? _roomName
                      : _acName,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    fontSize: 15,
                    fontWeight:
                    FontWeight.w800,
                    height: 1.1,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  _roomName != '-'
                      ? _acName
                      : '$_brand • $_type',
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  TextStyle(
                    fontSize: 10,
                    color:
                    Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration:
            BoxDecoration(
              color: _statusColor
                  .withValues(
                alpha: 0.09,
              ),
              borderRadius:
              BorderRadius.circular(
                20,
              ),
            ),
            child:
            Text(
              _statusLabel,
              style:
              TextStyle(
                fontSize: 10,
                fontWeight:
                FontWeight.w700,
                color:
                _statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEPPER HEADER
  // ============================================================

  Widget _buildStepperHeader() {
    final info =
    _stepInfo[_currentStep];

    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        11,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.white,
        border: Border(
          bottom:
          BorderSide(
            color:
            Colors.grey[100]!,
          ),
        ),
      ),
      child:
      Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration:
                BoxDecoration(
                  color: info.color
                      .withValues(
                    alpha: 0.09,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    11,
                  ),
                ),
                child:
                Icon(
                  info.icon,
                  color:
                  info.color,
                  size: 18,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child:
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.title,
                      style:
                      const TextStyle(
                        fontSize: 14,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 1,
                    ),

                    Text(
                      info.description,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      TextStyle(
                        fontSize: 10,
                        color:
                        Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFF6F7FB,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    10,
                  ),
                ),
                child:
                Text(
                  '${_currentStep + 1}/$_totalSteps',
                  style:
                  TextStyle(
                    fontSize: 10,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 9,
          ),

          Row(
            children:
            List.generate(
              _totalSteps,
                  (index) {
                final active =
                    index <=
                        _currentStep;

                return Expanded(
                  child:
                  AnimatedContainer(
                    duration:
                    const Duration(
                      milliseconds:
                      180,
                    ),
                    height: 4,
                    margin:
                    EdgeInsets.only(
                      right: index ==
                          _totalSteps -
                              1
                          ? 0
                          : 5,
                    ),
                    decoration:
                    BoxDecoration(
                      color: active
                          ? kPrimaryColor
                          : Colors
                          .grey[200],
                      borderRadius:
                      BorderRadius.circular(
                        10,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CURRENT STEP
  // ============================================================

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildInfoStep();

      case 1:
        return _buildPhotoStep(
          title:
          'Foto Sebelum',
          description:
          'Dokumentasikan kondisi unit sebelum pekerjaan dimulai.',
          color:
          Colors.orange,
          icon:
          Iconsax.camera,
          draft:
          _draftSebelum,
          server:
          _serverSebelum,
        );

      case 2:
        return _buildPhotoStep(
          title:
          'Foto Pengerjaan',
          description:
          'Dokumentasikan proses pekerjaan yang sedang dilakukan.',
          color:
          Colors.blue,
          icon:
          Iconsax.setting_2,
          draft:
          _draftPengerjaan,
          server:
          _serverPengerjaan,
        );

      case 3:
        return _buildPhotoStep(
          title:
          'Foto Sesudah',
          description:
          'Dokumentasikan kondisi akhir setelah pekerjaan selesai.',
          color:
          Colors.green,
          icon:
          Iconsax.gallery_tick,
          draft:
          _draftSesudah,
          server:
          _serverSesudah,
        );

      case 4:
        return _buildDiagnosisStep();

      case 5:
        return _buildReviewStep();

      default:
        return const SizedBox.shrink();
    }
  }

  // ============================================================
  // INFO STEP
  // ============================================================

  Widget _buildInfoStep() {
    return Column(
      children: [
        _sectionCard(
          child:
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration:
                    BoxDecoration(
                      color: Colors.purple
                          .withValues(
                        alpha: 0.09,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        15,
                      ),
                    ),
                    child:
                    const Icon(
                      Iconsax.building_3,
                      color:
                      Colors.purple,
                      size: 23,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child:
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          _roomName != '-'
                              ? _roomName
                              : 'Lokasi AC',
                          style:
                          const TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight.w800,
                          ),
                        ),

                        if (_floorName !=
                            '-') ...[
                          const SizedBox(
                            height: 3,
                          ),
                          Text(
                            _floorName,
                            style:
                            TextStyle(
                              fontSize: 11,
                              color: Colors
                                  .grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 16,
              ),

              Container(
                padding:
                const EdgeInsets.all(
                  14,
                ),
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFF8F9FC,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    16,
                  ),
                ),
                child:
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration:
                      BoxDecoration(
                        color:
                        kPrimaryColor
                            .withValues(
                          alpha: 0.08,
                        ),
                        borderRadius:
                        BorderRadius.circular(
                          12,
                        ),
                      ),
                      child:
                      const Icon(
                        Iconsax.airdrop,
                        size: 20,
                        color:
                        kPrimaryColor,
                      ),
                    ),

                    const SizedBox(
                      width: 11,
                    ),

                    Expanded(
                      child:
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            _acName,
                            maxLines: 1,
                            overflow:
                            TextOverflow.ellipsis,
                            style:
                            const TextStyle(
                              fontSize: 15,
                              fontWeight:
                              FontWeight.w800,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            '$_brand • $_type',
                            maxLines: 2,
                            overflow:
                            TextOverflow.ellipsis,
                            style:
                            TextStyle(
                              fontSize: 11,
                              color: Colors
                                  .grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 11,
              ),

              Row(
                children: [
                  Expanded(
                    child:
                    _infoBox(
                      label:
                      'Kapasitas',
                      value:
                      _capacity,
                      icon:
                      Iconsax.flash_1,
                      color:
                      Colors.blue,
                    ),
                  ),

                  const SizedBox(
                    width: 9,
                  ),

                  Expanded(
                    child:
                    _infoBox(
                      label:
                      'Jenis Servis',
                      value: widget
                          .servis
                          .jenisDisplay,
                      icon:
                      Iconsax.category,
                      color:
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        _buildWorkflowProgress(),

        if (_isDitugaskan) ...[
          const SizedBox(
            height: 12,
          ),

          _notice(
            icon:
            Iconsax.info_circle,
            text:
            'Periksa ruangan dan unit AC terlebih dahulu. Setelah pekerjaan dimulai, ikuti seluruh tahapan secara berurutan.',
            color:
            Colors.blue,
          ),
        ],
      ],
    );
  }

  Widget _infoBox({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      decoration:
      BoxDecoration(
        color:
        color.withValues(
          alpha: 0.055,
        ),
        borderRadius:
        BorderRadius.circular(
          14,
        ),
      ),
      child:
      Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: color,
          ),

          const SizedBox(
            width: 9,
          ),

          Expanded(
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                  TextStyle(
                    fontSize: 9,
                    color:
                    Colors.grey[600],
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  value,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PHOTO STEP
  // ============================================================

  Widget _buildPhotoStep({
    required String title,
    required String description,
    required Color color,
    required IconData icon,
    required List<String> draft,
    required List<String> server,
  }) {
    final total =
        server.length + draft.length;

    return Column(
      children: [
        _sectionCard(
          child:
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration:
                    BoxDecoration(
                      color: color
                          .withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                    ),
                    child:
                    Icon(
                      icon,
                      color: color,
                      size: 22,
                    ),
                  ),

                  const SizedBox(
                    width: 11,
                  ),

                  Expanded(
                    child:
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child:
                              Text(
                                title,
                                style:
                                const TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                  FontWeight.w800,
                                ),
                              ),
                            ),

                            const SizedBox(
                              width: 7,
                            ),

                            _requiredBadge(),
                          ],
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          description,
                          style:
                          TextStyle(
                            fontSize: 11,
                            height: 1.4,
                            color: Colors
                                .grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 16,
              ),

              // ================================================
              // LARGE PHOTO
              // ================================================

              if (total == 0)
                _buildLargeEmptyPhoto(
                  color: color,
                  onTap: _processing
                      ? null
                      : () {
                    _pickAndAppend(
                      draft,
                    );
                  },
                )
              else
                _buildLargePhotoPreview(
                  server:
                  server,
                  draft:
                  draft,
                  color:
                  color,
                ),

              if (total > 0) ...[
                const SizedBox(
                  height: 12,
                ),

                Row(
                  children: [
                    const Icon(
                      Iconsax.tick_circle,
                      color:
                      Colors.green,
                      size: 17,
                    ),

                    const SizedBox(
                      width: 6,
                    ),

                    Text(
                      '$total foto tersedia',
                      style:
                      const TextStyle(
                        color:
                        Colors.green,
                        fontSize: 11,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),

                    const Spacer(),

                    InkWell(
                      onTap: _processing
                          ? null
                          : () {
                        _pickAndAppend(
                          draft,
                        );
                      },
                      borderRadius:
                      BorderRadius.circular(
                        10,
                      ),
                      child:
                      Container(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration:
                        BoxDecoration(
                          color: color
                              .withValues(
                            alpha: 0.08,
                          ),
                          borderRadius:
                          BorderRadius.circular(
                            10,
                          ),
                        ),
                        child:
                        Row(
                          mainAxisSize:
                          MainAxisSize.min,
                          children: [
                            Icon(
                              Iconsax.add,
                              size: 14,
                              color: color,
                            ),

                            const SizedBox(
                              width: 4,
                            ),

                            Text(
                              'Tambah Foto',
                              style:
                              TextStyle(
                                fontSize: 10,
                                color: color,
                                fontWeight:
                                FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (total > 1) ...[
                const SizedBox(
                  height: 14,
                ),

                Text(
                  'Dokumentasi lainnya',
                  style:
                  TextStyle(
                    fontSize: 11,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Colors.grey[700],
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                _buildPhotoThumbnailList(
                  server:
                  server,
                  draft:
                  draft,
                  color:
                  color,
                ),
              ],

              if (draft.isNotEmpty) ...[
                const SizedBox(
                  height: 12,
                ),

                _notice(
                  icon:
                  Iconsax.cloud_plus,
                  text:
                  'Foto baru belum tersimpan. Foto akan otomatis di-upload saat Anda menekan Lanjut.',
                  color:
                  color,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        _buildCompactUnitSummary(),

        const SizedBox(
          height: 12,
        ),

        _buildWorkflowProgress(),
      ],
    );
  }

  Widget _requiredBadge() {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.red.withValues(
          alpha: 0.08,
        ),
        borderRadius:
        BorderRadius.circular(
          8,
        ),
      ),
      child:
      const Text(
        'Wajib',
        style:
        TextStyle(
          fontSize: 9,
          color:
          Colors.red,
          fontWeight:
          FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildLargeEmptyPhoto({
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
      BorderRadius.circular(
        18,
      ),
      child:
      Container(
        width:
        double.infinity,
        height:
        230,
        decoration:
        BoxDecoration(
          color:
          color.withValues(
            alpha: 0.045,
          ),
          borderRadius:
          BorderRadius.circular(
            18,
          ),
          border:
          Border.all(
            color:
            color.withValues(
              alpha: 0.22,
            ),
          ),
        ),
        child:
        Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration:
              BoxDecoration(
                color: color
                    .withValues(
                  alpha: 0.10,
                ),
                shape:
                BoxShape.circle,
              ),
              child:
              Icon(
                Iconsax.camera,
                color: color,
                size: 31,
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            Text(
              'Ambil Foto',
              style:
              TextStyle(
                color: color,
                fontSize: 16,
                fontWeight:
                FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            Text(
              'Gunakan kamera atau pilih dari galeri',
              style:
              TextStyle(
                fontSize: 11,
                color:
                Colors.grey[500],
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration:
              BoxDecoration(
                color:
                Colors.white,
                borderRadius:
                BorderRadius.circular(
                  20,
                ),
                border:
                Border.all(
                  color: color
                      .withValues(
                    alpha: 0.12,
                  ),
                ),
              ),
              child:
              Text(
                'Minimal 1 foto',
                style:
                TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargePhotoPreview({
    required List<String> server,
    required List<String> draft,
    required Color color,
  }) {
    final useDraft =
        draft.isNotEmpty;

    final image =
    useDraft
        ? draft.first
        : server.first;

    return GestureDetector(
      onTap: () {
        if (!useDraft) {
          _showFullScreenImage(
            image,
          );
        }
      },
      child:
      Container(
        width:
        double.infinity,
        height:
        250,
        decoration:
        BoxDecoration(
          color:
          Colors.grey[100],
          borderRadius:
          BorderRadius.circular(
            18,
          ),
          border:
          Border.all(
            color:
            color.withValues(
              alpha: 0.12,
            ),
          ),
        ),
        child:
        ClipRRect(
          borderRadius:
          BorderRadius.circular(
            17,
          ),
          child:
          Stack(
            fit:
            StackFit.expand,
            children: [
              if (useDraft)
                Image.file(
                  File(image),
                  fit:
                  BoxFit.cover,
                )
              else
                Image.network(
                  image,
                  fit:
                  BoxFit.cover,
                  headers:
                  _authHeaders,
                  loadingBuilder: (
                      context,
                      child,
                      loading,
                      ) {
                    if (loading ==
                        null) {
                      return child;
                    }

                    return Container(
                      color: Colors
                          .grey[100],
                      child:
                      const Center(
                        child:
                        CircularProgressIndicator(
                          strokeWidth:
                          2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (
                      _,
                      __,
                      ___,
                      ) {
                    return Container(
                      color: Colors
                          .grey[100],
                      child:
                      Center(
                        child:
                        Icon(
                          Icons
                              .broken_image,
                          size: 40,
                          color: Colors
                              .grey[400],
                        ),
                      ),
                    );
                  },
                ),

              Positioned(
                left: 10,
                bottom: 10,
                child:
                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration:
                  BoxDecoration(
                    color: Colors.black
                        .withValues(
                      alpha: 0.58,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      10,
                    ),
                  ),
                  child:
                  Row(
                    children: [
                      Icon(
                        useDraft
                            ? Iconsax.clock
                            : Iconsax.tick_circle,
                        size: 13,
                        color:
                        Colors.white,
                      ),

                      const SizedBox(
                        width: 5,
                      ),

                      Text(
                        useDraft
                            ? 'Belum tersimpan'
                            : 'Tersimpan',
                        style:
                        const TextStyle(
                          fontSize: 10,
                          color:
                          Colors.white,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (useDraft)
                Positioned(
                  top: 9,
                  right: 9,
                  child:
                  InkWell(
                    onTap: () {
                      setState(() {
                        draft.removeAt(
                          0,
                        );
                      });
                    },
                    child:
                    Container(
                      width: 34,
                      height: 34,
                      decoration:
                      BoxDecoration(
                        color: Colors.black
                            .withValues(
                          alpha: 0.60,
                        ),
                        shape:
                        BoxShape.circle,
                      ),
                      child:
                      const Icon(
                        Iconsax.trash,
                        size: 15,
                        color:
                        Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnailList({
    required List<String> server,
    required List<String> draft,
    required Color color,
  }) {
    final items = <_PhotoPreviewItem>[
      ...server.map(
            (path) =>
            _PhotoPreviewItem(
              path:
              path,
              isLocal:
              false,
            ),
      ),
      ...draft.map(
            (path) =>
            _PhotoPreviewItem(
              path:
              path,
              isLocal:
              true,
            ),
      ),
    ];

    return SizedBox(
      height: 86,
      child:
      ListView.separated(
        scrollDirection:
        Axis.horizontal,
        itemCount:
        items.length,
        separatorBuilder: (
            _,
            __,
            ) =>
        const SizedBox(
          width: 8,
        ),
        itemBuilder: (
            context,
            index,
            ) {
          final item =
          items[index];

          return GestureDetector(
            onTap: () {
              if (!item.isLocal) {
                _showFullScreenImage(
                  item.path,
                );
              }
            },
            child:
            Container(
              width: 86,
              height: 86,
              decoration:
              BoxDecoration(
                borderRadius:
                BorderRadius.circular(
                  12,
                ),
                border:
                Border.all(
                  color: color
                      .withValues(
                    alpha: 0.12,
                  ),
                ),
              ),
              child:
              ClipRRect(
                borderRadius:
                BorderRadius.circular(
                  11,
                ),
                child:
                item.isLocal
                    ? Image.file(
                  File(
                    item.path,
                  ),
                  fit:
                  BoxFit.cover,
                )
                    : Image.network(
                  item.path,
                  fit:
                  BoxFit.cover,
                  headers:
                  _authHeaders,
                  errorBuilder:
                      (
                      _,
                      __,
                      ___,
                      ) {
                    return Container(
                      color: Colors
                          .grey[100],
                      child:
                      Icon(
                        Icons
                            .broken_image,
                        color: Colors
                            .grey[400],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // COMPACT UNIT SUMMARY
  // ============================================================

  Widget _buildCompactUnitSummary() {
    return _sectionCard(
      child:
      Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration:
                BoxDecoration(
                  color:
                  kPrimaryColor
                      .withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    11,
                  ),
                ),
                child:
                const Icon(
                  Iconsax.airdrop,
                  size: 19,
                  color:
                  kPrimaryColor,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child:
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      _acName,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      const TextStyle(
                        fontSize: 13,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      _roomName != '-'
                          ? '$_roomName${_floorName != '-' ? ' • $_floorName' : ''}'
                          : _floorName,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      TextStyle(
                        fontSize: 10,
                        color:
                        Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration:
                BoxDecoration(
                  color: _statusColor
                      .withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    10,
                  ),
                ),
                child:
                Text(
                  _capacity,
                  style:
                  TextStyle(
                    fontSize: 10,
                    color:
                    _statusColor,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 13,
          ),

          Container(
            padding:
            const EdgeInsets.only(
              top: 12,
            ),
            decoration:
            BoxDecoration(
              border: Border(
                top:
                BorderSide(
                  color:
                  Colors.grey[100]!,
                ),
              ),
            ),
            child:
            Row(
              children: [
                Expanded(
                  child:
                  _miniInformation(
                    'Merk',
                    _brand,
                  ),
                ),

                _miniDivider(),

                Expanded(
                  child:
                  _miniInformation(
                    'Tipe',
                    _type,
                  ),
                ),

                _miniDivider(),

                Expanded(
                  child:
                  _miniInformation(
                    'Servis',
                    widget
                        .servis
                        .jenisDisplay,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniDivider() {
    return Container(
      width: 1,
      height: 30,
      margin:
      const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      color:
      Colors.grey[200],
    );
  }

  Widget _miniInformation(
      String title,
      String value,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
          TextStyle(
            fontSize: 9,
            color:
            Colors.grey[500],
          ),
        ),

        const SizedBox(
          height: 3,
        ),

        Text(
          value,
          maxLines: 1,
          overflow:
          TextOverflow.ellipsis,
          style:
          const TextStyle(
            fontSize: 10,
            fontWeight:
            FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // WORKFLOW PROGRESS
  // ============================================================

  Widget _buildWorkflowProgress() {
    final items =
    <_WorkflowItem>[
      _WorkflowItem(
        label:
        'Sebelum',
        icon:
        Iconsax.camera,
        done:
        _serverSebelum.isNotEmpty,
      ),
      _WorkflowItem(
        label:
        'Proses',
        icon:
        Iconsax.setting_2,
        done:
        _serverPengerjaan.isNotEmpty,
      ),
      _WorkflowItem(
        label:
        'Sesudah',
        icon:
        Iconsax.gallery_tick,
        done:
        _serverSesudah.isNotEmpty,
      ),
      _WorkflowItem(
        label:
        'Laporan',
        icon:
        Iconsax.clipboard_tick,
        done:
        _diagnosaCtrl.text
            .trim()
            .isNotEmpty &&
            _tindakanCtrl.text
                .trim()
                .isNotEmpty,
      ),
    ];

    return _sectionCard(
      child:
      Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress Pekerjaan',
            style:
            TextStyle(
              fontSize: 13,
              fontWeight:
              FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 3,
          ),

          Text(
            'Lengkapi seluruh tahapan sebelum pekerjaan diselesaikan.',
            style:
            TextStyle(
              fontSize: 10,
              color:
              Colors.grey[600],
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          Row(
            children:
            List.generate(
              items.length,
                  (index) {
                final item =
                items[index];

                return Expanded(
                  child:
                  Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration:
                        BoxDecoration(
                          color: item.done
                              ? Colors.green
                              .withValues(
                            alpha: 0.10,
                          )
                              : Colors
                              .grey[100],
                          shape:
                          BoxShape.circle,
                          border:
                          Border.all(
                            color: item.done
                                ? Colors.green
                                .withValues(
                              alpha: 0.25,
                            )
                                : Colors
                                .grey[200]!,
                          ),
                        ),
                        child:
                        Icon(
                          item.done
                              ? Iconsax.tick_circle
                              : item.icon,
                          size: 18,
                          color: item.done
                              ? Colors.green
                              : Colors.grey[400],
                        ),
                      ),

                      const SizedBox(
                        height: 7,
                      ),

                      Text(
                        item.label,
                        style:
                        TextStyle(
                          fontSize: 9,
                          fontWeight: item.done
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: item.done
                              ? Colors.green
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DIAGNOSIS
  // ============================================================

  Widget _buildDiagnosisStep() {
    return Column(
      children: [
        _buildCompactUnitSummary(),

        const SizedBox(
          height: 12,
        ),

        _sectionCard(
          child:
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              _formTitle(
                icon:
                Iconsax.clipboard_text,
                color:
                Colors.orange,
                title:
                'Diagnosa',
                subtitle:
                'Tuliskan hasil pemeriksaan kondisi unit AC.',
              ),

              const SizedBox(
                height: 12,
              ),

              _textArea(
                controller:
                _diagnosaCtrl,
                hint:
                'Contoh: Evaporator kotor, freon berkurang, kapasitor lemah...',
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        _sectionCard(
          child:
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              _formTitle(
                icon:
                Iconsax.setting_2,
                color:
                Colors.blue,
                title:
                'Tindakan',
                subtitle:
                'Tuliskan pekerjaan yang telah dilakukan.',
              ),

              const SizedBox(
                height: 12,
              ),

              _textArea(
                controller:
                _tindakanCtrl,
                hint:
                'Contoh: Membersihkan evaporator, isi freon, mengganti kapasitor...',
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        _buildWorkflowProgress(),
      ],
    );
  }

  Widget _formTitle({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration:
          BoxDecoration(
            color:
            color.withValues(
              alpha: 0.09,
            ),
            borderRadius:
            BorderRadius.circular(
              11,
            ),
          ),
          child:
          Icon(
            icon,
            color: color,
            size: 19,
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child:
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style:
                    const TextStyle(
                      fontSize: 14,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),

                  const SizedBox(
                    width: 6,
                  ),

                  _requiredBadge(),
                ],
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                subtitle,
                style:
                TextStyle(
                  fontSize: 10,
                  color:
                  Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _textArea({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      decoration:
      BoxDecoration(
        color:
        const Color(
          0xFFF8F9FC,
        ),
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        border:
        Border.all(
          color:
          Colors.grey[200]!,
        ),
      ),
      child:
      TextField(
        controller:
        controller,
        minLines: 4,
        maxLines: 7,
        onChanged: (_) {
          setState(() {});
        },
        style:
        const TextStyle(
          fontSize: 12,
          height: 1.45,
        ),
        decoration:
        InputDecoration(
          hintText:
          hint,
          hintStyle:
          TextStyle(
            fontSize: 11,
            height: 1.4,
            color:
            Colors.grey[400],
          ),
          border:
          InputBorder.none,
          contentPadding:
          const EdgeInsets.all(
            14,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // REVIEW
  // ============================================================

  Widget _buildReviewStep() {
    return Column(
      children: [
        _sectionCard(
          child:
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration:
                    BoxDecoration(
                      color: Colors.green
                          .withValues(
                        alpha: 0.09,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        12,
                      ),
                    ),
                    child:
                    const Icon(
                      Iconsax.clipboard_tick,
                      size: 20,
                      color:
                      Colors.green,
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child:
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isSelesai
                              ? 'Laporan Selesai'
                              : 'Review Pekerjaan',
                          style:
                          const TextStyle(
                            fontSize: 15,
                            fontWeight:
                            FontWeight.w800,
                          ),
                        ),

                        const SizedBox(
                          height: 2,
                        ),

                        Text(
                          _isSelesai
                              ? 'Pekerjaan unit AC telah diselesaikan.'
                              : 'Pastikan seluruh data pekerjaan sudah lengkap.',
                          style:
                          TextStyle(
                            fontSize: 10,
                            color: Colors
                                .grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 14,
              ),

              _reviewRow(
                label:
                'Foto Sebelum',
                value:
                '${_serverSebelum.length} foto',
                done:
                _serverSebelum.isNotEmpty,
              ),

              _reviewRow(
                label:
                'Foto Pengerjaan',
                value:
                '${_serverPengerjaan.length} foto',
                done:
                _serverPengerjaan.isNotEmpty,
              ),

              _reviewRow(
                label:
                'Foto Sesudah',
                value:
                '${_serverSesudah.length} foto',
                done:
                _serverSesudah.isNotEmpty,
              ),

              _reviewRow(
                label:
                'Diagnosa',
                value:
                _diagnosaCtrl.text
                    .trim()
                    .isNotEmpty
                    ? 'Terisi'
                    : 'Belum',
                done:
                _diagnosaCtrl.text
                    .trim()
                    .isNotEmpty,
              ),

              _reviewRow(
                label:
                'Tindakan',
                value:
                _tindakanCtrl.text
                    .trim()
                    .isNotEmpty
                    ? 'Terisi'
                    : 'Belum',
                done:
                _tindakanCtrl.text
                    .trim()
                    .isNotEmpty,
                last:
                true,
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        _buildCompactUnitSummary(),

        if (_diagnosaCtrl.text
            .trim()
            .isNotEmpty) ...[
          const SizedBox(
            height: 12,
          ),

          _summaryText(
            title:
            'Diagnosa',
            value:
            _diagnosaCtrl.text.trim(),
            color:
            Colors.orange,
          ),
        ],

        if (_tindakanCtrl.text
            .trim()
            .isNotEmpty) ...[
          const SizedBox(
            height: 12,
          ),

          _summaryText(
            title:
            'Tindakan',
            value:
            _tindakanCtrl.text.trim(),
            color:
            Colors.blue,
          ),
        ],

        if (_serverSebelum.isNotEmpty ||
            _serverPengerjaan.isNotEmpty ||
            _serverSesudah.isNotEmpty) ...[
          const SizedBox(
            height: 12,
          ),

          _sectionCard(
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dokumentasi',
                  style:
                  TextStyle(
                    fontSize: 14,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),

                if (_serverSebelum
                    .isNotEmpty) ...[
                  const SizedBox(
                    height: 12,
                  ),

                  _reviewPhotoCategory(
                    'Sebelum',
                    _serverSebelum,
                    Colors.orange,
                  ),
                ],

                if (_serverPengerjaan
                    .isNotEmpty) ...[
                  const SizedBox(
                    height: 14,
                  ),

                  _reviewPhotoCategory(
                    'Pengerjaan',
                    _serverPengerjaan,
                    Colors.blue,
                  ),
                ],

                if (_serverSesudah
                    .isNotEmpty) ...[
                  const SizedBox(
                    height: 14,
                  ),

                  _reviewPhotoCategory(
                    'Sesudah',
                    _serverSesudah,
                    Colors.green,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _reviewRow({
    required String label,
    required String value,
    required bool done,
    bool last = false,
  }) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        vertical: 10,
      ),
      decoration:
      BoxDecoration(
        border: last
            ? null
            : Border(
          bottom:
          BorderSide(
            color:
            Colors.grey[100]!,
          ),
        ),
      ),
      child:
      Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration:
            BoxDecoration(
              color: done
                  ? Colors.green
                  .withValues(
                alpha: 0.08,
              )
                  : Colors.red
                  .withValues(
                alpha: 0.07,
              ),
              shape:
              BoxShape.circle,
            ),
            child:
            Icon(
              done
                  ? Iconsax.tick_circle
                  : Iconsax.close_circle,
              size: 16,
              color: done
                  ? Colors.green
                  : Colors.red,
            ),
          ),

          const SizedBox(
            width: 9,
          ),

          Expanded(
            child:
            Text(
              label,
              style:
              const TextStyle(
                fontSize: 11,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),

          Text(
            value,
            style:
            TextStyle(
              fontSize: 10,
              color: done
                  ? Colors.green
                  : Colors.red,
              fontWeight:
              FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryText({
    required String title,
    required String value,
    required Color color,
  }) {
    return _sectionCard(
      child:
      Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration:
                BoxDecoration(
                  color: color,
                  borderRadius:
                  BorderRadius.circular(
                    4,
                  ),
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Text(
                title,
                style:
                TextStyle(
                  fontSize: 13,
                  fontWeight:
                  FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            value,
            style:
            TextStyle(
              fontSize: 12,
              height: 1.5,
              color:
              Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewPhotoCategory(
      String title,
      List<String> photos,
      Color color,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 15,
              decoration:
              BoxDecoration(
                color: color,
                borderRadius:
                BorderRadius.circular(
                  4,
                ),
              ),
            ),

            const SizedBox(
              width: 7,
            ),

            Text(
              'Foto $title',
              style:
              const TextStyle(
                fontSize: 11,
                fontWeight:
                FontWeight.w700,
              ),
            ),

            const Spacer(),

            Text(
              '${photos.length} foto',
              style:
              TextStyle(
                fontSize: 9,
                color: color,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 8,
        ),

        _reviewServerPhotoGrid(
          photos,
        ),
      ],
    );
  }

  Widget _reviewServerPhotoGrid(
      List<String> photos,
      ) {
    return GridView.builder(
      shrinkWrap:
      true,
      physics:
      const NeverScrollableScrollPhysics(),
      itemCount:
      photos.length,
      gridDelegate:
      const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
        3,
        crossAxisSpacing:
        8,
        mainAxisSpacing:
        8,
        childAspectRatio:
        1.15,
      ),
      itemBuilder: (
          context,
          index,
          ) {
        final url =
        photos[index];

        return InkWell(
          onTap: () {
            _showFullScreenImage(
              url,
            );
          },
          borderRadius:
          BorderRadius.circular(
            11,
          ),
          child:
          ClipRRect(
            borderRadius:
            BorderRadius.circular(
              11,
            ),
            child:
            Image.network(
              url,
              fit:
              BoxFit.cover,
              headers:
              _authHeaders,
              errorBuilder: (
                  _,
                  __,
                  ___,
                  ) {
                return Container(
                  color:
                  Colors.grey[100],
                  child:
                  Icon(
                    Icons
                        .broken_image,
                    color:
                    Colors.grey[400],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigation() {
    final isReview =
        _currentStep == 5;

    return Container(
      padding:
      EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10 +
            MediaQuery.of(
              context,
            ).padding.bottom,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.white,
        border: Border(
          top:
          BorderSide(
            color:
            Colors.grey[100]!,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(
              alpha: 0.035,
            ),
            blurRadius: 14,
            offset:
            const Offset(
              0,
              -3,
            ),
          ),
        ],
      ),
      child:
      Row(
        children: [
          if (_currentStep > 0 &&
              !_isSelesai) ...[
            SizedBox(
              width: 98,
              child:
              OutlinedButton(
                onPressed:
                _processing
                    ? null
                    : _previousStep,
                style:
                OutlinedButton.styleFrom(
                  foregroundColor:
                  kPrimaryColor,
                  minimumSize:
                  const Size(
                    0,
                    52,
                  ),
                  side:
                  BorderSide(
                    color:
                    kPrimaryColor
                        .withValues(
                      alpha: 0.22,
                    ),
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
                child:
                const Text(
                  'Kembali',
                  style:
                  TextStyle(
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(
              width: 9,
            ),
          ],

          Expanded(
            child:
            ElevatedButton(
              onPressed:
              _processing
                  ? null
                  : _nextStep,
              style:
              ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor:
                isReview &&
                    !_isSelesai
                    ? Colors.green
                    : kPrimaryColor,
                foregroundColor:
                Colors.white,
                disabledBackgroundColor:
                Colors.grey[300],
                minimumSize:
                const Size(
                  0,
                  52,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
              ),
              child:
              _processing
                  ? const SizedBox(
                width: 20,
                height: 20,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color:
                  Colors.white,
                ),
              )
                  : Row(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Text(
                    _buttonLabel,
                    style:
                    const TextStyle(
                      fontSize: 13,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    width: 7,
                  ),

                  Icon(
                    _buttonIcon,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _buttonLabel {
    if (_isSelesai &&
        _currentStep == 5) {
      return 'Kembali';
    }

    switch (_currentStep) {
      case 0:
        return _isDitugaskan
            ? 'Mulai Pengerjaan'
            : 'Lanjut';

      case 4:
        return 'Simpan & Review';

      case 5:
        return 'Selesaikan Item';

      default:
        return 'Lanjut';
    }
  }

  IconData get _buttonIcon {
    if (_isSelesai &&
        _currentStep == 5) {
      return Iconsax.arrow_left_2;
    }

    switch (_currentStep) {
      case 0:
        return Iconsax.play_circle;

      case 4:
        return Iconsax.clipboard_tick;

      case 5:
        return Iconsax.tick_circle;

      default:
        return Iconsax.arrow_right_3;
    }
  }

  // ============================================================
  // NOTICE
  // ============================================================

  Widget _notice({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration:
      BoxDecoration(
        color:
        color.withValues(
          alpha: 0.05,
        ),
        borderRadius:
        BorderRadius.circular(
          12,
        ),
      ),
      child:
      Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 15,
            color: color,
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child:
            Text(
              text,
              style:
              TextStyle(
                fontSize: 10,
                height: 1.45,
                color:
                Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _sectionCard({
    required Widget child,
  }) {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        16,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.white,
        borderRadius:
        BorderRadius.circular(
          20,
        ),
        border:
        Border.all(
          color:
          Colors.black.withValues(
            alpha: 0.025,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withValues(
              alpha: 0.035,
            ),
            blurRadius: 14,
            offset:
            const Offset(
              0,
              4,
            ),
          ),
        ],
      ),
      child:
      child,
    );
  }

  // ============================================================
  // FULL IMAGE
  // ============================================================

  void _showFullScreenImage(
      String url,
      ) {
    showDialog(
      context: context,
      builder: (
          dialogContext,
          ) {
        return Dialog(
          backgroundColor:
          Colors.transparent,
          insetPadding:
          const EdgeInsets.all(
            16,
          ),
          child:
          Stack(
            children: [
              Container(
                width:
                double.infinity,
                constraints:
                BoxConstraints(
                  maxHeight:
                  MediaQuery.of(
                    context,
                  ).size.height *
                      0.78,
                ),
                decoration:
                BoxDecoration(
                  color:
                  Colors.black,
                  borderRadius:
                  BorderRadius.circular(
                    18,
                  ),
                ),
                child:
                ClipRRect(
                  borderRadius:
                  BorderRadius.circular(
                    18,
                  ),
                  child:
                  Image.network(
                    url,
                    fit:
                    BoxFit.contain,
                    headers:
                    _authHeaders,
                    loadingBuilder: (
                        context,
                        child,
                        progress,
                        ) {
                      if (progress ==
                          null) {
                        return child;
                      }

                      return const Center(
                        child:
                        CircularProgressIndicator(
                          color:
                          Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (
                        _,
                        __,
                        ___,
                        ) {
                      return const Center(
                        child:
                        Icon(
                          Icons
                              .broken_image,
                          size: 42,
                          color:
                          Colors.white70,
                        ),
                      );
                    },
                  ),
                ),
              ),

              Positioned(
                top: 8,
                right: 8,
                child:
                InkWell(
                  onTap: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child:
                  Container(
                    width: 36,
                    height: 36,
                    decoration:
                    BoxDecoration(
                      color: Colors
                          .black
                          .withValues(
                        alpha: 0.55,
                      ),
                      shape:
                      BoxShape.circle,
                    ),
                    child:
                    const Icon(
                      Icons.close,
                      color:
                      Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showValidationDialog(
      String title,
      String message,
      IconData icon,
      ) {
    AwesomeDialog(
      context: context,
      dialogType:
      DialogType.warning,
      animType:
      AnimType.scale,
      title:
      title,
      desc:
      message,
      btnOkText:
      'Mengerti',
      btnOkColor:
      Colors.orange,
    ).show();
  }

  void _showError(
      String message,
      ) {
    if (!mounted) return;

    AwesomeDialog(
      context: context,
      dialogType:
      DialogType.error,
      animType:
      AnimType.scale,
      title:
      'Gagal',
      desc:
      message,
      btnOkText:
      'Mengerti',
    ).show();
  }

  void _showSnackBar(
      String message,
      Color color,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
          Row(
            children: [
              const Icon(
                Iconsax.tick_circle,
                color:
                Colors.white,
                size: 18,
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child:
                Text(
                  message,
                ),
              ),
            ],
          ),
          backgroundColor:
          color,
          behavior:
          SnackBarBehavior.floating,
          margin:
          const EdgeInsets.all(
            14,
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              12,
            ),
          ),
        ),
      );
  }

  // ============================================================
  // STEP META
  // ============================================================

  List<_AcStepInfo> get _stepInfo => const [
    _AcStepInfo(
      title:
      'Informasi Unit',
      description:
      'Periksa ruangan dan unit AC',
      icon:
      Iconsax.info_circle,
      color:
      kPrimaryColor,
    ),
    _AcStepInfo(
      title:
      'Foto Sebelum',
      description:
      'Dokumentasi kondisi awal',
      icon:
      Iconsax.camera,
      color:
      Colors.orange,
    ),
    _AcStepInfo(
      title:
      'Foto Pengerjaan',
      description:
      'Dokumentasi proses pekerjaan',
      icon:
      Iconsax.setting_2,
      color:
      Colors.blue,
    ),
    _AcStepInfo(
      title:
      'Foto Sesudah',
      description:
      'Dokumentasi hasil pekerjaan',
      icon:
      Iconsax.gallery_tick,
      color:
      Colors.green,
    ),
    _AcStepInfo(
      title:
      'Hasil Pekerjaan',
      description:
      'Diagnosa dan tindakan',
      icon:
      Iconsax.clipboard_text,
      color:
      Colors.purple,
    ),
    _AcStepInfo(
      title:
      'Review',
      description:
      'Periksa dan selesaikan',
      icon:
      Iconsax.clipboard_tick,
      color:
      Colors.green,
    ),
  ];
}

// ============================================================
// STEP INFO
// ============================================================

class _AcStepInfo {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _AcStepInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

// ============================================================
// PHOTO PREVIEW ITEM
// ============================================================

class _PhotoPreviewItem {
  final String path;
  final bool isLocal;

  const _PhotoPreviewItem({
    required this.path,
    required this.isLocal,
  });
}

// ============================================================
// WORKFLOW ITEM
// ============================================================

class _WorkflowItem {
  final String label;
  final IconData icon;
  final bool done;

  const _WorkflowItem({
    required this.label,
    required this.icon,
    required this.done,
  });
}

// ============================================================
// STATIC INFO ROW
// ============================================================

class _StaticInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _StaticInfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 15,
          color:
          Colors.blue,
        ),

        const SizedBox(
          width: 8,
        ),

        Expanded(
          child:
          Text(
            text,
            style:
            const TextStyle(
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}