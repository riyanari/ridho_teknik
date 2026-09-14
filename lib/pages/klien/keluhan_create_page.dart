// lib/pages/klien/keluhan_create_page.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import '../../models/ac_model.dart';
import '../../models/lokasi_model.dart';
import '../../providers/client_servis_provider.dart';
import '../../theme/theme.dart';

class KeluhanCreatePage extends StatefulWidget {
  final AcModel ac;
  final LokasiModel lokasi;

  const KeluhanCreatePage({
    super.key,
    required this.ac,
    required this.lokasi,
  });

  @override
  State<KeluhanCreatePage> createState() =>
      _KeluhanCreatePageState();
}

class _KeluhanCreatePageState
    extends State<KeluhanCreatePage> {
  // ============================================================
  // CONTROLLER
  // ============================================================

  final TextEditingController _keluhanController =
  TextEditingController();

  final PageController _pageController =
  PageController();

  final ImagePicker _picker =
  ImagePicker();

  // ============================================================
  // STATE
  // ============================================================

  int _currentStep = 0;

  String _priority = 'sedang';

  final List<File> _fotoKeluhan = [];

  DateTime? _selectedDate;

  bool _isDateFormattingInitialized = false;

  // ============================================================
  // PRIORITY
  // ============================================================

  final List<Map<String, dynamic>> _priorityOptions = [
    {
      'value': 'rendah',
      'label': 'Rendah',
      'description': 'AC masih dapat digunakan',
      'color': Colors.green,
      'icon': Iconsax.arrow_down_1,
    },
    {
      'value': 'sedang',
      'label': 'Sedang',
      'description': 'Mengganggu kenyamanan',
      'color': Colors.orange,
      'icon': Iconsax.info_circle,
    },
    {
      'value': 'tinggi',
      'label': 'Tinggi',
      'description': 'AC tidak dapat digunakan',
      'color': Colors.red,
      'icon': Iconsax.warning_2,
    },
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _initializeDateFormatting();
  }

  Future<void> _initializeDateFormatting() async {
    try {
      await initializeDateFormatting(
        'id_ID',
      );

      if (!mounted) return;

      setState(() {
        _isDateFormattingInitialized = true;
      });
    } catch (e) {
      debugPrint(
        'Date formatting error: $e',
      );

      if (!mounted) return;

      setState(() {
        _isDateFormattingInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _keluhanController.dispose();
    _pageController.dispose();

    super.dispose();
  }

  // ============================================================
  // STEP CONTROL
  // ============================================================

  void _nextStep() {
    if (!_validateStep()) {
      return;
    }

    if (_currentStep >= 2) {
      return;
    }

    setState(() {
      _currentStep++;
    });

    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(
        milliseconds: 260,
      ),
      curve: Curves.easeOutCubic,
    );
  }

  void _previousStep() {
    if (_currentStep == 0) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _currentStep--;
    });

    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(
        milliseconds: 260,
      ),
      curve: Curves.easeOutCubic,
    );
  }

  bool _validateStep() {
    // ==========================================================
    // STEP 1
    // ==========================================================

    if (_currentStep == 0) {
      final keluhan =
      _keluhanController.text.trim();

      if (keluhan.isEmpty) {
        _showSnackBar(
          'Ceritakan masalah AC terlebih dahulu.',
          Colors.orange,
        );

        return false;
      }

      if (keluhan.length < 10) {
        _showSnackBar(
          'Keluhan minimal 10 karakter agar teknisi memahami masalah.',
          Colors.orange,
        );

        return false;
      }
    }

    // ==========================================================
    // STEP 2
    // ==========================================================

    if (_currentStep == 1) {
      if (_selectedDate == null) {
        _showSnackBar(
          'Pilih tanggal kunjungan terlebih dahulu.',
          Colors.orange,
        );

        return false;
      }
    }

    return true;
  }

  // ============================================================
  // IMAGE
  // ============================================================

  Future<void> _showImageSourceDialog() async {
    if (_fotoKeluhan.length >= 5) {
      _showSnackBar(
        'Maksimal 5 foto.',
        Colors.orange,
      );

      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(
              14,
            ),
            padding: const EdgeInsets.fromLTRB(
              18,
              10,
              18,
              18,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                26,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius:
                    BorderRadius.circular(
                      20,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tambahkan Foto',
                        style:
                        primaryTextStyle.copyWith(
                          fontSize: 17,
                          fontWeight: bold,
                        ),
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    ),
                  ],
                ),

                Text(
                  'Foto membantu teknisi memahami kondisi AC sebelum datang.',
                  style: greyTextStyle.copyWith(
                    fontSize: 10.5,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: _buildImageSourceButton(
                        icon:
                        Iconsax.camera,
                        title: 'Kamera',
                        subtitle:
                        'Ambil foto',
                        color:
                        kPrimaryColor,
                        onTap: () {
                          Navigator.pop(
                            context,
                          );

                          _pickImage(
                            ImageSource.camera,
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: _buildImageSourceButton(
                        icon:
                        Iconsax.gallery,
                        title: 'Galeri',
                        subtitle:
                        'Pilih foto',
                        color:
                        Colors.green,
                        onTap: () {
                          Navigator.pop(
                            context,
                          );

                          _pickImage(
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
        );
      },
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        child: Ink(
          padding: const EdgeInsets.all(
            15,
          ),
          decoration: BoxDecoration(
            color: color.withValues(
              alpha: 0.06,
            ),
            borderRadius:
            BorderRadius.circular(
              18,
            ),
            border: Border.all(
              color: color.withValues(
                alpha: 0.12,
              ),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 21,
                ),
              ),

              const SizedBox(height: 9),

              Text(
                title,
                style:
                primaryTextStyle.copyWith(
                  fontSize: 12,
                  fontWeight: bold,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                subtitle,
                style: greyTextStyle.copyWith(
                  fontSize: 8.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(
      ImageSource source,
      ) async {
    try {
      final image =
      await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (image == null) {
        return;
      }

      if (!mounted) return;

      setState(() {
        _fotoKeluhan.add(
          File(image.path),
        );
      });
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        'Gagal mengambil gambar.',
        Colors.red,
      );
    }
  }

  void _removeImage(
      int index,
      ) {
    setState(() {
      _fotoKeluhan.removeAt(
        index,
      );
    });
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _submitPerbaikan() async {
    if (!_validateStep()) {
      return;
    }

    if (_selectedDate == null) {
      _showSnackBar(
        'Tanggal kunjungan belum dipilih.',
        Colors.orange,
      );
      return;
    }

    final provider =
    context.read<
        ClientServisProvider>();

    try {
      final formattedDate =
      DateFormat(
        'yyyy-MM-dd',
      ).format(
        _selectedDate!,
      );

      await provider.requestPerbaikan(
        locationId:
        widget.lokasi.id,
        acUnitId:
        widget.ac.id,
        keluhan:
        _keluhanController.text
            .trim(),
        priority:
        _priority,
        tanggalBerkunjung:
        formattedDate,
        fotoKeluhan:
        _fotoKeluhan.isEmpty
            ? null
            : _fotoKeluhan,
      );

      if (!mounted) return;

      _showSnackBar(
        'Permintaan perbaikan berhasil dikirim.',
        Colors.green,
      );

      await Future.delayed(
        const Duration(
          milliseconds: 600,
        ),
      );

      if (!mounted) return;

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) return;

      final message =
          provider.submitPerbaikanError ??
              e.toString().replaceFirst(
                'Exception: ',
                '',
              );

      _showSnackBar(
        message,
        Colors.red,
      );
    }
  }

  void _showSnackBar(
      String message,
      Color color,
      ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
        backgroundColor:
        color,
        behavior:
        SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final provider =
    context.watch<
        ClientServisProvider>();

    return Scaffold(
      backgroundColor:
      kBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(),

                _buildStepper(),

                Expanded(
                  child: PageView(
                    controller:
                    _pageController,
                    physics:
                    const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStepProblem(),
                      _buildStepSchedule(),
                      _buildStepConfirm(),
                    ],
                  ),
                ),

                _buildBottomNavigation(
                  provider,
                ),
              ],
            ),

            if (!_isDateFormattingInitialized ||
                provider.submittingPerbaikan)
              Positioned.fill(
                child: Container(
                  color:
                  Colors.black.withValues(
                    alpha: 0.18,
                  ),
                  child: Center(
                    child: Container(
                      padding:
                      const EdgeInsets.all(
                        20,
                      ),
                      decoration: BoxDecoration(
                        color:
                        Colors.white,
                        borderRadius:
                        BorderRadius.circular(
                          18,
                        ),
                      ),
                      child: Column(
                        mainAxisSize:
                        MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color:
                            kPrimaryColor,
                            strokeWidth:
                            2.5,
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          Text(
                            provider
                                .submittingPerbaikan
                                ? 'Mengirim permintaan...'
                                : 'Menyiapkan formulir...',
                            style:
                            primaryTextStyle.copyWith(
                              fontSize: 11,
                              fontWeight:
                              medium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        14,
        20,
        6,
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap:
              _previousStep,
              borderRadius:
              BorderRadius.circular(
                14,
              ),
              child: Ink(
                width: 44,
                height: 44,
                decoration:
                BoxDecoration(
                  color:
                  Colors.white,
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  Icons
                      .arrow_back_rounded,
                  color:
                  kPrimaryColor,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Perbaikan AC',
                  style:
                  primaryTextStyle.copyWith(
                    fontSize: 18,
                    fontWeight: bold,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  widget.lokasi.nama,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  greyTextStyle.copyWith(
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration:
            BoxDecoration(
              color:
              Colors.orange.withValues(
                alpha: 0.08,
              ),
              borderRadius:
              BorderRadius.circular(
                20,
              ),
            ),
            child: const Text(
              'Perbaikan',
              style: TextStyle(
                color:
                Colors.orange,
                fontSize: 8.5,
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEPPER
  // ============================================================

  Widget _buildStepper() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        14,
      ),
      child: Row(
        children: [
          _buildStepIndicator(
            index: 0,
            label: 'Keluhan',
            icon:
            Iconsax.message_question,
          ),

          _buildStepLine(0),

          _buildStepIndicator(
            index: 1,
            label: 'Jadwal',
            icon:
            Iconsax.calendar_1,
          ),

          _buildStepLine(1),

          _buildStepIndicator(
            index: 2,
            label: 'Ajukan',
            icon:
            Iconsax.tick_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final active =
        _currentStep == index;

    final completed =
        _currentStep > index;

    final enabled =
        active || completed;

    return Expanded(
      child: Column(
        children: [
          AnimatedContainer(
            duration:
            const Duration(
              milliseconds: 180,
            ),
            width: 36,
            height: 36,
            decoration:
            BoxDecoration(
              color: enabled
                  ? kPrimaryColor
                  : Colors.white,
              shape:
              BoxShape.circle,
              border:
              Border.all(
                color: enabled
                    ? kPrimaryColor
                    : Colors
                    .grey.shade300,
              ),
            ),
            child: Icon(
              completed
                  ? Icons
                  .check_rounded
                  : icon,
              size: 17,
              color: enabled
                  ? Colors.white
                  : Colors
                  .grey.shade400,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            label,
            style:
            TextStyle(
              fontSize: 8.5,
              fontWeight:
              active
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: active
                  ? kPrimaryColor
                  : Colors
                  .grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(
      int beforeStep,
      ) {
    final completed =
        _currentStep > beforeStep;

    return Expanded(
      child:
      AnimatedContainer(
        duration:
        const Duration(
          milliseconds: 180,
        ),
        height: 2,
        margin:
        const EdgeInsets.only(
          bottom: 20,
        ),
        color: completed
            ? kPrimaryColor
            : Colors
            .grey.shade300,
      ),
    );
  }

  // ============================================================
  // STEP 1 - PROBLEM
  // ============================================================

  Widget _buildStepProblem() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        6,
        20,
        0,
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          _buildStepTitle(
            'Apa masalahnya?',
            'Ceritakan kondisi AC agar teknisi dapat mempersiapkan penanganan',
          ),

          const SizedBox(height: 14),

          _buildAcInfo(),

          const SizedBox(height: 14),

          Expanded(
            child: ListView(
              physics:
              const BouncingScrollPhysics(),
              children: [
                _buildComplaintField(),

                const SizedBox(height: 18),

                _buildPrioritySection(),

                const SizedBox(height: 18),

                _buildPhotoSection(),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AC INFO
  // ============================================================

  Widget _buildAcInfo() {
    final room =
    (widget.ac.room?.name ?? '')
        .trim();

    final roomName =
    room.isNotEmpty
        ? room
        : widget.ac.lantai > 0
        ? 'Lantai ${widget.ac.lantai}'
        : 'Ruangan belum ditentukan';

    final acName =
    widget.ac.nama.trim().isNotEmpty
        ? widget.ac.nama
        : 'AC #${widget.ac.id}';

    final specs = [
      widget.ac.merk,
      widget.ac.type,
      widget.ac.kapasitas,
    ]
        .where(
          (e) =>
      e.trim().isNotEmpty &&
          e != '-',
    )
        .join(' • ');

    return Container(
      padding:
      const EdgeInsets.all(
        14,
      ),
      decoration:
      BoxDecoration(
        gradient:
        LinearGradient(
          begin:
          Alignment.topLeft,
          end:
          Alignment.bottomRight,
          colors: [
            kPrimaryColor
                .withValues(
              alpha: 0.07,
            ),
            Colors.white,
          ],
        ),
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border:
        Border.all(
          color:
          kPrimaryColor.withValues(
            alpha: 0.09,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration:
            BoxDecoration(
              color:
              kPrimaryColor.withValues(
                alpha: 0.09,
              ),
              borderRadius:
              BorderRadius.circular(
                14,
              ),
            ),
            child: Icon(
              Iconsax.location,
              color:
              kPrimaryColor,
              size: 21,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  roomName,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  primaryTextStyle.copyWith(
                    fontSize: 13,
                    fontWeight: bold,
                  ),
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    Icon(
                      Icons.ac_unit_rounded,
                      size: 12,
                      color:
                      kPrimaryColor,
                    ),

                    const SizedBox(width: 5),

                    Expanded(
                      child: Text(
                        acName,
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style:
                        TextStyle(
                          color:
                          kPrimaryColor,
                          fontSize: 9.5,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                if (specs.isNotEmpty) ...[
                  const SizedBox(height: 3),

                  Text(
                    specs,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    greyTextStyle.copyWith(
                      fontSize: 8.5,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (widget.ac.lantai > 0)
            Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 5,
              ),
              decoration:
              BoxDecoration(
                color: Colors.grey.withValues(
                  alpha: 0.07,
                ),
                borderRadius:
                BorderRadius.circular(
                  20,
                ),
              ),
              child: Text(
                'L${widget.ac.lantai}',
                style:
                TextStyle(
                  fontSize: 8,
                  color:
                  Colors.grey.shade600,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // COMPLAINT
  // ============================================================

  Widget _buildComplaintField() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          'Keluhan',
          style:
          primaryTextStyle.copyWith(
            fontSize: 13.5,
            fontWeight: bold,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          'Jelaskan gejala atau kondisi yang terjadi',
          style:
          greyTextStyle.copyWith(
            fontSize: 9,
          ),
        ),

        const SizedBox(height: 9),

        TextField(
          controller:
          _keluhanController,
          maxLines: 5,
          minLines: 4,
          maxLength: 500,
          decoration:
          InputDecoration(
            hintText:
            'Contoh: AC tidak dingin sejak kemarin, terdengar suara keras dan terdapat tetesan air...',
            hintStyle:
            greyTextStyle.copyWith(
              fontSize: 10,
              height: 1.45,
            ),
            filled: true,
            fillColor:
            Colors.white,
            counterStyle:
            greyTextStyle.copyWith(
              fontSize: 8,
            ),
            border:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                17,
              ),
              borderSide:
              BorderSide.none,
            ),
            enabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                17,
              ),
              borderSide:
              BorderSide(
                color: Colors.grey.withValues(
                  alpha: 0.10,
                ),
              ),
            ),
            focusedBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                17,
              ),
              borderSide:
              BorderSide(
                color:
                kPrimaryColor,
                width: 1.2,
              ),
            ),
            contentPadding:
            const EdgeInsets.all(
              15,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PRIORITY
  // ============================================================

  Widget _buildPrioritySection() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          'Tingkat Prioritas',
          style:
          primaryTextStyle.copyWith(
            fontSize: 13.5,
            fontWeight: bold,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          'Pilih sesuai kondisi AC saat ini',
          style:
          greyTextStyle.copyWith(
            fontSize: 9,
          ),
        ),

        const SizedBox(height: 10),

        Row(
          children:
          List.generate(
            _priorityOptions.length,
                (index) {
              final option =
              _priorityOptions[index];

              return Expanded(
                child: Padding(
                  padding:
                  EdgeInsets.only(
                    right: index ==
                        _priorityOptions.length -
                            1
                        ? 0
                        : 8,
                  ),
                  child:
                  _buildPriorityCard(
                    option,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityCard(
      Map<String, dynamic> option,
      ) {
    final value =
    option['value'] as String;

    final color =
    option['color'] as Color;

    final selected =
        _priority == value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _priority = value;
          });
        },
        borderRadius:
        BorderRadius.circular(
          17,
        ),
        child: AnimatedContainer(
          duration:
          const Duration(
            milliseconds: 170,
          ),
          padding:
          const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 12,
          ),
          decoration:
          BoxDecoration(
            color: selected
                ? color.withValues(
              alpha: 0.09,
            )
                : Colors.white,
            borderRadius:
            BorderRadius.circular(
              17,
            ),
            border:
            Border.all(
              color: selected
                  ? color
                  : Colors.grey.withValues(
                alpha: 0.10,
              ),
              width: selected
                  ? 1.3
                  : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration:
                BoxDecoration(
                  color: color.withValues(
                    alpha: selected
                        ? 0.14
                        : 0.07,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    11,
                  ),
                ),
                child: Icon(
                  option['icon']
                  as IconData,
                  size: 17,
                  color: color,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                option['label']
                as String,
                style:
                TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                option['description']
                as String,
                textAlign:
                TextAlign.center,
                maxLines: 2,
                overflow:
                TextOverflow.ellipsis,
                style:
                greyTextStyle.copyWith(
                  fontSize: 7.2,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PHOTO
  // ============================================================

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    'Foto Keluhan',
                    style:
                    primaryTextStyle.copyWith(
                      fontSize: 13.5,
                      fontWeight: bold,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    'Opsional • Maksimal 5 foto',
                    style:
                    greyTextStyle.copyWith(
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),

            if (_fotoKeluhan.isNotEmpty)
              Text(
                '${_fotoKeluhan.length}/5',
                style:
                TextStyle(
                  color:
                  kPrimaryColor,
                  fontSize: 9,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
          ],
        ),

        const SizedBox(height: 10),

        if (_fotoKeluhan.isEmpty)
          _buildEmptyPhoto()
        else
          _buildPhotoGrid(),

        if (_fotoKeluhan.isNotEmpty &&
            _fotoKeluhan.length < 5) ...[
          const SizedBox(height: 10),

          OutlinedButton.icon(
            onPressed:
            _showImageSourceDialog,
            icon: const Icon(
              Iconsax.add,
              size: 16,
            ),
            label:
            const Text(
              'Tambah Foto',
            ),
            style:
            OutlinedButton.styleFrom(
              foregroundColor:
              kPrimaryColor,
              minimumSize:
              const Size.fromHeight(
                44,
              ),
              side: BorderSide(
                color: kPrimaryColor.withValues(
                  alpha: 0.30,
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
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyPhoto() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
        _showImageSourceDialog,
        borderRadius:
        BorderRadius.circular(
          17,
        ),
        child: Ink(
          width:
          double.infinity,
          padding:
          const EdgeInsets.all(
            16,
          ),
          decoration:
          BoxDecoration(
            color:
            kPrimaryColor.withValues(
              alpha: 0.035,
            ),
            borderRadius:
            BorderRadius.circular(
              17,
            ),
            border:
            Border.all(
              color: kPrimaryColor.withValues(
                alpha: 0.15,
              ),
              style:
              BorderStyle.solid,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration:
                BoxDecoration(
                  color:
                  kPrimaryColor.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    13,
                  ),
                ),
                child: Icon(
                  Iconsax.camera,
                  color:
                  kPrimaryColor,
                  size: 20,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tambahkan Foto',
                      style:
                      primaryTextStyle.copyWith(
                        fontSize: 11.5,
                        fontWeight: bold,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      'Foto AC atau bagian yang bermasalah',
                      style:
                      greyTextStyle.copyWith(
                        fontSize: 8.5,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons
                    .arrow_forward_ios_rounded,
                size: 13,
                color:
                Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection:
        Axis.horizontal,
        physics:
        const BouncingScrollPhysics(),
        itemCount:
        _fotoKeluhan.length,
        separatorBuilder:
            (_, __) =>
        const SizedBox(
          width: 8,
        ),
        itemBuilder:
            (context, index) {
          return Stack(
            clipBehavior:
            Clip.none,
            children: [
              ClipRRect(
                borderRadius:
                BorderRadius.circular(
                  14,
                ),
                child:
                Image.file(
                  _fotoKeluhan[index],
                  width: 86,
                  height: 86,
                  fit:
                  BoxFit.cover,
                ),
              ),

              Positioned(
                top: 5,
                right: 5,
                child:
                GestureDetector(
                  onTap: () {
                    _removeImage(
                      index,
                    );
                  },
                  child:
                  Container(
                    width: 23,
                    height: 23,
                    decoration:
                    BoxDecoration(
                      color:
                      Colors.black.withValues(
                        alpha: 0.60,
                      ),
                      shape:
                      BoxShape.circle,
                    ),
                    child:
                    const Icon(
                      Icons.close,
                      size: 13,
                      color:
                      Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // STEP 2 - SCHEDULE
  // ============================================================

  Widget _buildStepSchedule() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        6,
        20,
        0,
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          _buildStepTitle(
            'Pilih Jadwal',
            'Tentukan tanggal yang nyaman untuk kunjungan teknisi',
          ),

          const SizedBox(height: 14),

          Expanded(
            child: ListView(
              physics:
              const BouncingScrollPhysics(),
              children: [
                _buildCalendar(),

                const SizedBox(height: 14),

                if (_selectedDate != null)
                  _buildSelectedDateCard(),

                const SizedBox(height: 14),

                _buildScheduleInformation(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final now =
    DateTime.now();

    final firstDate =
    DateTime(
      now.year,
      now.month,
      now.day,
    ).add(
      const Duration(
        days: 1,
      ),
    );

    return Container(
      padding:
      const EdgeInsets.all(
        10,
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
          color: Colors.grey.withValues(
            alpha: 0.09,
          ),
        ),
      ),
      child:
      CalendarDatePicker(
        initialDate:
        _selectedDate ??
            firstDate,
        firstDate:
        firstDate,
        lastDate:
        firstDate.add(
          const Duration(
            days: 30,
          ),
        ),
        onDateChanged:
            (date) {
          setState(() {
            _selectedDate =
                date;
          });
        },
      ),
    );
  }

  Widget _buildSelectedDateCard() {
    return Container(
      padding:
      const EdgeInsets.all(
        14,
      ),
      decoration:
      BoxDecoration(
        gradient:
        LinearGradient(
          begin:
          Alignment.topLeft,
          end:
          Alignment.bottomRight,
          colors: [
            kPrimaryColor.withValues(
              alpha: 0.09,
            ),
            kPrimaryColor.withValues(
              alpha: 0.035,
            ),
          ],
        ),
        borderRadius:
        BorderRadius.circular(
          17,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration:
            BoxDecoration(
              color:
              kPrimaryColor,
              borderRadius:
              BorderRadius.circular(
                13,
              ),
            ),
            child:
            const Icon(
              Iconsax.calendar_tick,
              color:
              Colors.white,
              size: 20,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Tanggal Kunjungan',
                  style:
                  greyTextStyle.copyWith(
                    fontSize: 8.5,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  _formatLongDate(
                    _selectedDate!,
                  ),
                  style:
                  primaryTextStyle.copyWith(
                    fontSize: 11.5,
                    fontWeight: bold,
                  ),
                ),
              ],
            ),
          ),

          Icon(
            Iconsax.tick_circle,
            color:
            kPrimaryColor,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleInformation() {
    return Container(
      padding:
      const EdgeInsets.all(
        14,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.orange.withValues(
          alpha: 0.055,
        ),
        borderRadius:
        BorderRadius.circular(
          16,
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            Iconsax.info_circle,
            color:
            Colors.orange,
            size: 18,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              'Tanggal yang dipilih merupakan preferensi kunjungan. Jadwal dapat dikonfirmasi kembali oleh admin atau teknisi.',
              style:
              primaryTextStyle.copyWith(
                fontSize: 9.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 3 - CONFIRM
  // ============================================================

  Widget _buildStepConfirm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        6,
        20,
        0,
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          _buildStepTitle(
            'Konfirmasi Perbaikan',
            'Periksa kembali data sebelum mengirim permintaan',
          ),

          const SizedBox(height: 14),

          Expanded(
            child: ListView(
              physics:
              const BouncingScrollPhysics(),
              children: [
                _buildConfirmationCard(),

                const SizedBox(height: 14),

                _buildProcessPreview(),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationCard() {
    final room =
    (widget.ac.room?.name ?? '')
        .trim();

    final roomName =
    room.isNotEmpty
        ? room
        : 'Unit AC';

    return Container(
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
          color: Colors.grey.withValues(
            alpha: 0.09,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildConfirmationRow(
            icon:
            Iconsax.location,
            label:
            'Lokasi',
            value:
            widget.lokasi.nama,
          ),

          const Divider(
            height: 24,
          ),

          _buildConfirmationRow(
            icon:
            Icons.ac_unit_rounded,
            label:
            roomName,
            value:
            widget.ac.nama,
          ),

          const Divider(
            height: 24,
          ),

          _buildConfirmationRow(
            icon:
            Iconsax.message_question,
            label:
            'Keluhan',
            value:
            _keluhanController.text
                .trim(),
            maxLines: 4,
          ),

          const Divider(
            height: 24,
          ),

          _buildConfirmationRow(
            icon:
            Iconsax.warning_2,
            label:
            'Prioritas',
            value:
            _priorityLabel(),
            valueColor:
            _priorityColor(),
          ),

          const Divider(
            height: 24,
          ),

          _buildConfirmationRow(
            icon:
            Iconsax.calendar_1,
            label:
            'Tanggal',
            value:
            _selectedDate == null
                ? '-'
                : _formatLongDate(
              _selectedDate!,
            ),
          ),

          if (_fotoKeluhan.isNotEmpty) ...[
            const Divider(
              height: 24,
            ),

            _buildConfirmationPhotos(),
          ],
        ],
      ),
    );
  }

  Widget _buildConfirmationRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    int maxLines = 2,
  }) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration:
          BoxDecoration(
            color:
            kPrimaryColor.withValues(
              alpha: 0.08,
            ),
            borderRadius:
            BorderRadius.circular(
              11,
            ),
          ),
          child: Icon(
            icon,
            size: 17,
            color:
            kPrimaryColor,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style:
                greyTextStyle.copyWith(
                  fontSize: 8.5,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                value,
                maxLines:
                maxLines,
                overflow:
                TextOverflow.ellipsis,
                style:
                primaryTextStyle.copyWith(
                  fontSize: 10.8,
                  height: 1.35,
                  fontWeight: bold,
                  color:
                  valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationPhotos() {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration:
          BoxDecoration(
            color:
            kPrimaryColor.withValues(
              alpha: 0.08,
            ),
            borderRadius:
            BorderRadius.circular(
              11,
            ),
          ),
          child: Icon(
            Iconsax.gallery,
            size: 17,
            color:
            kPrimaryColor,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'Foto Keluhan',
                style:
                greyTextStyle.copyWith(
                  fontSize: 8.5,
                ),
              ),

              const SizedBox(height: 7),

              SizedBox(
                height: 54,
                child:
                ListView.separated(
                  scrollDirection:
                  Axis.horizontal,
                  itemCount:
                  _fotoKeluhan.length,
                  separatorBuilder:
                      (_, __) =>
                  const SizedBox(
                    width: 6,
                  ),
                  itemBuilder:
                      (context, index) {
                    return ClipRRect(
                      borderRadius:
                      BorderRadius.circular(
                        9,
                      ),
                      child:
                      Image.file(
                        _fotoKeluhan[index],
                        width: 54,
                        height: 54,
                        fit:
                        BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PROCESS PREVIEW
  // ============================================================

  Widget _buildProcessPreview() {
    return Container(
      padding:
      const EdgeInsets.all(
        14,
      ),
      decoration:
      BoxDecoration(
        color:
        kPrimaryColor.withValues(
          alpha: 0.045,
        ),
        borderRadius:
        BorderRadius.circular(
          17,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax
                    .info_circle,
                color:
                kPrimaryColor,
                size: 17,
              ),

              const SizedBox(width: 8),

              Text(
                'Setelah diajukan',
                style:
                primaryTextStyle.copyWith(
                  fontSize: 11,
                  fontWeight: bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _buildProcessMiniStep(
            number: '1',
            text:
            'Permintaan diterima admin',
          ),

          _buildProcessMiniStep(
            number: '2',
            text:
            'Teknisi ditugaskan',
          ),

          _buildProcessMiniStep(
            number: '3',
            text:
            'Teknisi datang dan melakukan pemeriksaan',
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _buildProcessMiniStep({
    required String number,
    required String text,
    bool last = false,
  }) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 25,
              height: 25,
              decoration:
              BoxDecoration(
                color:
                kPrimaryColor,
                shape:
                BoxShape.circle,
              ),
              alignment:
              Alignment.center,
              child: Text(
                number,
                style:
                const TextStyle(
                  color:
                  Colors.white,
                  fontSize: 8.5,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ),

            if (!last)
              Container(
                width: 1.5,
                height: 22,
                color:
                kPrimaryColor.withValues(
                  alpha: 0.18,
                ),
              ),
          ],
        ),

        const SizedBox(width: 9),

        Expanded(
          child: Padding(
            padding:
            const EdgeInsets.only(
              top: 5,
            ),
            child: Text(
              text,
              style:
              greyTextStyle.copyWith(
                fontSize: 9.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BOTTOM NAV
  // ============================================================

  Widget _buildBottomNavigation(
      ClientServisProvider provider,
      ) {
    return Container(
      padding:
      EdgeInsets.fromLTRB(
        20,
        11,
        20,
        MediaQuery.of(context)
            .padding
            .bottom +
            11,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.white,
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withValues(
              alpha: 0.055,
            ),
            blurRadius: 18,
            offset:
            const Offset(
              0,
              -5,
            ),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child:
              OutlinedButton(
                onPressed:
                _previousStep,
                style:
                OutlinedButton.styleFrom(
                  minimumSize:
                  const Size.fromHeight(
                    50,
                  ),
                  foregroundColor:
                  kPrimaryColor,
                  side:
                  BorderSide(
                    color:
                    kPrimaryColor,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      15,
                    ),
                  ),
                ),
                child:
                const Text(
                  'Kembali',
                  style:
                  TextStyle(
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ),

          if (_currentStep > 0)
            const SizedBox(width: 10),

          Expanded(
            flex:
            _currentStep > 0
                ? 2
                : 1,
            child:
            ElevatedButton(
              onPressed:
              provider.submittingPerbaikan
                  ? null
                  : _currentStep ==
                  2
                  ? _submitPerbaikan
                  : _nextStep,
              style:
              ElevatedButton.styleFrom(
                minimumSize:
                const Size.fromHeight(
                  50,
                ),
                backgroundColor:
                kPrimaryColor,
                foregroundColor:
                Colors.white,
                elevation: 0,
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    15,
                  ),
                ),
              ),
              child:
              provider.submittingPerbaikan
                  ? const SizedBox(
                width: 19,
                height: 19,
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
                    _currentStep ==
                        2
                        ? 'Ajukan Perbaikan'
                        : 'Lanjut',
                    style:
                    const TextStyle(
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),

                  if (_currentStep !=
                      2) ...[
                    const SizedBox(width: 7),

                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Widget _buildStepTitle(
      String title,
      String subtitle,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
          primaryTextStyle.copyWith(
            fontSize: 16,
            fontWeight: bold,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          subtitle,
          style:
          greyTextStyle.copyWith(
            fontSize: 9.5,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  String _priorityLabel() {
    for (final option
    in _priorityOptions) {
      if (option['value'] ==
          _priority) {
        return option['label']
        as String;
      }
    }

    return 'Sedang';
  }

  Color _priorityColor() {
    for (final option
    in _priorityOptions) {
      if (option['value'] ==
          _priority) {
        return option['color']
        as Color;
      }
    }

    return Colors.orange;
  }

  String _formatLongDate(
      DateTime date,
      ) {
    if (_isDateFormattingInitialized) {
      try {
        return DateFormat(
          'EEEE, d MMMM yyyy',
          'id_ID',
        ).format(date);
      } catch (_) {}
    }

    return DateFormat(
      'd MMM yyyy',
    ).format(date);
  }
}