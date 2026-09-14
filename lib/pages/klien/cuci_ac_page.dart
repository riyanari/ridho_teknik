import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../models/ac_model.dart';
import '../../models/lokasi_model.dart';
import '../../providers/client_servis_provider.dart';
import '../../theme/theme.dart';

class CuciAcPage extends StatefulWidget {
  final LokasiModel lokasi;
  final List<AcModel> acList;

  const CuciAcPage({
    super.key,
    required this.lokasi,
    required this.acList,
  });

  @override
  State<CuciAcPage> createState() => _CuciAcPageState();
}

class _CuciAcPageState extends State<CuciAcPage> {
  final TextEditingController _catatanController =
  TextEditingController();

  final TextEditingController _searchController =
  TextEditingController();

  final PageController _pageController =
  PageController();

  int _currentStep = 0;

  int? _selectedFloor;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final List<int> _selectedAcIds = [];

  bool get _singleMode =>
      widget.acList.length == 1;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    if (_singleMode) {
      _selectedAcIds.add(
        widget.acList.first.id,
      );
    }

    _searchController.addListener(
      _onSearchChanged,
    );
  }

  @override
  void dispose() {
    _catatanController.dispose();

    _searchController.removeListener(
      _onSearchChanged,
    );

    _searchController.dispose();

    _pageController.dispose();

    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<int> get _floorOptions {
    final floors = widget.acList
        .map(
          (ac) => ac.lantai,
    )
        .where(
          (floor) => floor > 0,
    )
        .toSet()
        .toList()
      ..sort();

    return floors;
  }

  List<AcModel> get _filteredAc {
    final query =
    _searchController.text
        .trim()
        .toLowerCase();

    return widget.acList.where(
          (ac) {
        final room =
        (ac.room?.name ?? '')
            .trim()
            .toLowerCase();

        final matchesQuery =
            query.isEmpty ||
                ac.nama
                    .toLowerCase()
                    .contains(query) ||
                ac.merk
                    .toLowerCase()
                    .contains(query) ||
                ac.type
                    .toLowerCase()
                    .contains(query) ||
                ac.kapasitas
                    .toLowerCase()
                    .contains(query) ||
                room.contains(query);

        final matchesFloor =
            _selectedFloor == null ||
                ac.lantai ==
                    _selectedFloor;

        return matchesQuery &&
            matchesFloor;
      },
    ).toList();
  }

  bool get _allVisibleSelected {
    final visible = _filteredAc;

    if (visible.isEmpty) {
      return false;
    }

    return visible.every(
          (ac) =>
          _selectedAcIds.contains(
            ac.id,
          ),
    );
  }

  int get _selectedVisibleCount {
    return _filteredAc
        .where(
          (ac) =>
          _selectedAcIds.contains(
            ac.id,
          ),
    )
        .length;
  }

  void _selectFloor(
      int? floor,
      ) {
    setState(() {
      _selectedFloor = floor;
    });
  }

  void _toggleSelectVisible() {
    final visible = _filteredAc;

    if (visible.isEmpty) {
      return;
    }

    setState(() {
      if (_allVisibleSelected) {
        for (final ac in visible) {
          _selectedAcIds.remove(
            ac.id,
          );
        }
      } else {
        for (final ac in visible) {
          if (!_selectedAcIds.contains(
            ac.id,
          )) {
            _selectedAcIds.add(
              ac.id,
            );
          }
        }
      }
    });
  }

  void _clearFilter() {
    _searchController.clear();

    setState(() {
      _selectedFloor = null;
    });
  }

  // ============================================================
  // STEP CONTROL
  // ============================================================

  void _nextStep() {
    if (!_validateCurrentStep()) {
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
      duration:
      const Duration(
        milliseconds: 250,
      ),
      curve:
      Curves.easeOutCubic,
    );
  }

  void _previousStep() {
    if (_currentStep <= 0) {
      Navigator.pop(
        context,
      );
      return;
    }

    setState(() {
      _currentStep--;
    });

    _pageController.animateToPage(
      _currentStep,
      duration:
      const Duration(
        milliseconds: 250,
      ),
      curve:
      Curves.easeOutCubic,
    );
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0 &&
        _selectedAcIds.isEmpty) {
      _showMessage(
        'Pilih minimal satu AC terlebih dahulu.',
        Colors.orange,
      );

      return false;
    }

    if (_currentStep == 1) {
      if (_selectedDate == null) {
        _showMessage(
          'Pilih tanggal kunjungan terlebih dahulu.',
          Colors.orange,
        );

        return false;
      }

      if (_selectedTime == null) {
        _showMessage(
          'Pilih waktu kunjungan terlebih dahulu.',
          Colors.orange,
        );

        return false;
      }
    }

    return true;
  }

  // ============================================================
  // AC SELECTION
  // ============================================================

  void _toggleAcSelection(
      int acId,
      ) {
    setState(() {
      if (_selectedAcIds.contains(
        acId,
      )) {
        _selectedAcIds.remove(
          acId,
        );
      } else {
        _selectedAcIds.add(
          acId,
        );
      }
    });
  }

  // ============================================================
  // TIME
  // ============================================================

  Future<void> _selectTime() async {
    final picked =
    await showTimePicker(
      context: context,
      initialTime:
      _selectedTime ??
          TimeOfDay.now(),
      builder:
          (context, child) {
        return Theme(
          data: ThemeData.light()
              .copyWith(
            colorScheme:
            ColorScheme.light(
              primary:
              kPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _submitRequest() async {
    if (_selectedAcIds.isEmpty ||
        _selectedDate == null ||
        _selectedTime == null) {
      _showMessage(
        'Lengkapi semua data terlebih dahulu.',
        Colors.orange,
      );

      return;
    }

    final provider =
    context.read<
        ClientServisProvider>();

    try {
      final tanggal =
      DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final semuaDipilih =
          _selectedAcIds.length ==
              widget.acList.length;

      await provider.requestCuci(
        locationId:
        widget.lokasi.id,
        semuaAc:
        semuaDipilih,
        acUnits:
        semuaDipilih
            ? null
            : _selectedAcIds,
        catatan:
        _catatanController.text
            .trim()
            .isEmpty
            ? null
            : _catatanController
            .text
            .trim(),
        tanggalBerkunjung:
        tanggal
            .toIso8601String(),
      );

      if (!mounted) return;

      _showMessage(
        'Permintaan cuci AC berhasil dikirim.',
        Colors.green,
      );

      await Future.delayed(
        const Duration(
          milliseconds: 700,
        ),
      );

      if (!mounted) return;

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e
            .toString()
            .replaceFirst(
          'Exception: ',
          '',
        ),
        Colors.red,
      );
    }
  }

  void _showMessage(
      String message,
      Color color,
      ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
        Text(message),
        backgroundColor:
        color,
        behavior:
        SnackBarBehavior
            .floating,
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
        child: Column(
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
                  _buildStepAc(),
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
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return Padding(
      padding:
      const EdgeInsets.fromLTRB(
        20,
        14,
        20,
        6,
      ),
      child: Row(
        children: [
          Material(
            color:
            Colors.transparent,
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

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  'Cuci AC',
                  style:
                  primaryTextStyle
                      .copyWith(
                    fontSize: 18,
                    fontWeight: bold,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  widget
                      .lokasi.nama,
                  maxLines: 1,
                  overflow:
                  TextOverflow
                      .ellipsis,
                  style:
                  greyTextStyle
                      .copyWith(
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding:
            const EdgeInsets
                .symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration:
            BoxDecoration(
              color:
              kPrimaryColor
                  .withValues(
                alpha: 0.07,
              ),
              borderRadius:
              BorderRadius.circular(
                20,
              ),
            ),
            child: Text(
              '${_selectedAcIds.length} AC',
              style: TextStyle(
                color:
                kPrimaryColor,
                fontSize: 9,
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
      padding:
      const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        14,
      ),
      child: Row(
        children: [
          _buildStepIndicator(
            0,
            'Pilih AC',
            Icons
                .ac_unit_rounded,
          ),

          _buildStepLine(0),

          _buildStepIndicator(
            1,
            'Jadwal',
            Iconsax.calendar_1,
          ),

          _buildStepLine(1),

          _buildStepIndicator(
            2,
            'Ajukan',
            Iconsax.tick_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(
      int index,
      String label,
      IconData icon,
      ) {
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

          const SizedBox(
            height: 5,
          ),

          Text(
            label,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight:
              active
                  ? FontWeight
                  .w700
                  : FontWeight
                  .w500,
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
        _currentStep >
            beforeStep;

    return Expanded(
      child: AnimatedContainer(
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
  // STEP 1
  // ============================================================

  Widget _buildStepAc() {
    if (_singleMode) {
      final ac =
          widget.acList.first;

      return Padding(
        padding:
        const EdgeInsets.all(
          20,
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment
              .start,
          children: [
            _buildStepTitle(
              'Unit AC',
              'Unit ini akan diajukan untuk dicuci',
            ),

            const SizedBox(
              height: 16,
            ),

            _buildAcTile(
              ac,
              selected: true,
              showCheckbox:
              false,
            ),
          ],
        ),
      );
    }

    final list =
        _filteredAc;

    final floors =
        _floorOptions;

    return Padding(
      padding:
      const EdgeInsets.fromLTRB(
        20,
        6,
        20,
        0,
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          // ====================================================
          // TITLE
          // ====================================================

          Row(
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [
              Expanded(
                child:
                _buildStepTitle(
                  'Pilih Unit AC',
                  '${_selectedAcIds.length} dari ${widget.acList.length} unit dipilih',
                ),
              ),

              if (_selectedAcIds
                  .isNotEmpty)
                Container(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    kPrimaryColor
                        .withValues(
                      alpha: 0.07,
                    ),
                    borderRadius:
                    BorderRadius
                        .circular(
                      20,
                    ),
                  ),
                  child: Text(
                    '${_selectedAcIds.length} dipilih',
                    style:
                    TextStyle(
                      color:
                      kPrimaryColor,
                      fontSize: 8.5,
                      fontWeight:
                      FontWeight
                          .w700,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(
            height: 13,
          ),

          // ====================================================
          // SEARCH
          // ====================================================

          _buildSearch(),

          const SizedBox(
            height: 11,
          ),

          // ====================================================
          // FLOOR
          // ====================================================

          if (floors.isNotEmpty)
            _buildFloorFilter(
              floors,
            ),

          if (floors.isNotEmpty)
            const SizedBox(
              height: 11,
            ),

          // ====================================================
          // CURRENT VIEW TOOLBAR
          // ====================================================

          _buildSelectionToolbar(
            visibleCount:
            list.length,
          ),

          const SizedBox(
            height: 10,
          ),

          // ====================================================
          // LIST
          // ====================================================

          Expanded(
            child: list.isEmpty
                ? _buildEmptyAcSearch()
                : ListView.separated(
              physics:
              const BouncingScrollPhysics(),
              padding:
              const EdgeInsets.only(
                bottom: 12,
              ),
              itemCount:
              list.length,
              separatorBuilder:
                  (_, __) =>
              const SizedBox(
                height: 8,
              ),
              itemBuilder:
                  (context, index) {
                final ac =
                list[index];

                return _buildAcTile(
                  ac,
                  selected:
                  _selectedAcIds
                      .contains(
                    ac.id,
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
  // FLOOR FILTER
  // ============================================================

  Widget _buildFloorFilter(
      List<int> floors,
      ) {
    return SizedBox(
      height: 37,
      child: ListView(
        scrollDirection:
        Axis.horizontal,
        physics:
        const BouncingScrollPhysics(),
        children: [
          _buildFloorChip(
            label: 'Semua',
            selected:
            _selectedFloor ==
                null,
            onTap: () =>
                _selectFloor(
                  null,
                ),
          ),

          const SizedBox(
            width: 7,
          ),

          ...floors.expand(
                (floor) => [
              _buildFloorChip(
                label:
                'Lantai $floor',
                selected:
                _selectedFloor ==
                    floor,
                onTap: () =>
                    _selectFloor(
                      floor,
                    ),
              ),

              const SizedBox(
                width: 7,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloorChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color:
      Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(
          30,
        ),
        child: AnimatedContainer(
          duration:
          const Duration(
            milliseconds: 170,
          ),
          padding:
          const EdgeInsets
              .symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration:
          BoxDecoration(
            color: selected
                ? kPrimaryColor
                : Colors.white,
            borderRadius:
            BorderRadius.circular(
              30,
            ),
            border:
            Border.all(
              color: selected
                  ? kPrimaryColor
                  : Colors.grey
                  .withValues(
                alpha: 0.13,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight:
              selected
                  ? FontWeight
                  .w700
                  : FontWeight
                  .w500,
              color: selected
                  ? Colors.white
                  : Colors
                  .grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SELECTION TOOLBAR
  // ============================================================

  Widget _buildSelectionToolbar({
    required int visibleCount,
  }) {
    final title =
    _selectedFloor == null
        ? 'Semua lantai'
        : 'Lantai $_selectedFloor';

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          15,
        ),
        border:
        Border.all(
          color: Colors.grey
              .withValues(
            alpha: 0.10,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration:
            BoxDecoration(
              color:
              kPrimaryColor
                  .withValues(
                alpha: 0.07,
              ),
              borderRadius:
              BorderRadius
                  .circular(
                10,
              ),
            ),
            child: Icon(
              Iconsax.filter,
              size: 15,
              color:
              kPrimaryColor,
            ),
          ),

          const SizedBox(
            width: 9,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  title,
                  style:
                  primaryTextStyle
                      .copyWith(
                    fontSize: 10.5,
                    fontWeight: bold,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  '$visibleCount unit • $_selectedVisibleCount dipilih',
                  style:
                  greyTextStyle
                      .copyWith(
                    fontSize: 8.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Material(
            color:
            Colors.transparent,
            child: InkWell(
              onTap:
              visibleCount == 0
                  ? null
                  : _toggleSelectVisible,
              borderRadius:
              BorderRadius.circular(
                20,
              ),
              child: Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration:
                BoxDecoration(
                  color:
                  kPrimaryColor
                      .withValues(
                    alpha: 0.07,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    20,
                  ),
                ),
                child: Text(
                  _allVisibleSelected
                      ? 'Batalkan'
                      : _selectedFloor ==
                      null
                      ? 'Pilih Semua'
                      : 'Pilih Lantai $_selectedFloor',
                  style:
                  TextStyle(
                    color:
                    kPrimaryColor,
                    fontSize: 8.8,
                    fontWeight:
                    FontWeight
                        .w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearch() {
    final hasText =
        _searchController.text
            .trim()
            .isNotEmpty;

    return Container(
      height: 48,
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        border:
        Border.all(
          color: Colors.grey
              .withValues(
            alpha: 0.10,
          ),
        ),
      ),
      child: TextField(
        controller:
        _searchController,
        style:
        primaryTextStyle
            .copyWith(
          fontSize: 11.5,
        ),
        decoration:
        InputDecoration(
          hintText:
          'Cari kamar atau nama AC...',
          hintStyle:
          greyTextStyle
              .copyWith(
            fontSize: 10,
          ),
          prefixIcon: Icon(
            Iconsax.search_normal,
            size: 18,
            color:
            kPrimaryColor,
          ),
          suffixIcon: hasText
              ? IconButton(
            onPressed: () {
              _searchController
                  .clear();
            },
            icon: Icon(
              Icons
                  .close_rounded,
              size: 17,
              color: Colors
                  .grey.shade500,
            ),
          )
              : null,
          border:
          InputBorder.none,
          contentPadding:
          const EdgeInsets
              .symmetric(
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // AC TILE
  // ============================================================

  Widget _buildAcTile(
      AcModel ac, {
        required bool selected,
        bool showCheckbox = true,
      }) {
    final roomName =
    (ac.room?.name ?? '')
        .trim();

    final roomTitle =
    roomName.isNotEmpty
        ? roomName
        : ac.lantai > 0
        ? 'Lantai ${ac.lantai}'
        : 'Ruang belum ditentukan';

    final acName =
    ac.nama
        .trim()
        .isNotEmpty
        ? ac.nama.trim()
        : 'AC #${ac.id}';

    final specParts =
    <String>[];

    if (ac.merk
        .trim()
        .isNotEmpty &&
        ac.merk !=
            'Unknown') {
      specParts.add(
        ac.merk,
      );
    }

    if (ac.type
        .trim()
        .isNotEmpty &&
        ac.type != '-') {
      specParts.add(
        ac.type,
      );
    }

    if (ac.kapasitas
        .trim()
        .isNotEmpty &&
        ac.kapasitas !=
            '-') {
      specParts.add(
        ac.kapasitas,
      );
    }

    final specification =
    specParts.join(' • ');

    return Material(
      color:
      Colors.transparent,
      child: InkWell(
        onTap: showCheckbox
            ? () =>
            _toggleAcSelection(
              ac.id,
            )
            : null,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        child: AnimatedContainer(
          duration:
          const Duration(
            milliseconds: 170,
          ),
          padding:
          const EdgeInsets
              .symmetric(
            horizontal: 13,
            vertical: 12,
          ),
          decoration:
          BoxDecoration(
            color: selected
                ? kPrimaryColor
                .withValues(
              alpha: 0.055,
            )
                : Colors.white,
            borderRadius:
            BorderRadius.circular(
              18,
            ),
            border:
            Border.all(
              color: selected
                  ? kPrimaryColor
                  .withValues(
                alpha: 0.70,
              )
                  : Colors.grey
                  .withValues(
                alpha: 0.09,
              ),
              width: selected
                  ? 1.2
                  : 1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                Colors.black
                    .withValues(
                  alpha: 0.018,
                ),
                blurRadius: 10,
                offset:
                const Offset(
                  0,
                  4,
                ),
              ),
            ],
          ),
          child: Row(
            children: [
              // CHECKBOX
              if (showCheckbox) ...[
                AnimatedContainer(
                  duration:
                  const Duration(
                    milliseconds:
                    150,
                  ),
                  width: 24,
                  height: 24,
                  decoration:
                  BoxDecoration(
                    color: selected
                        ? kPrimaryColor
                        : Colors
                        .white,
                    borderRadius:
                    BorderRadius
                        .circular(
                      7,
                    ),
                    border:
                    Border.all(
                      color: selected
                          ? kPrimaryColor
                          : Colors.grey
                          .shade400,
                      width: 1.3,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                    Icons
                        .check_rounded,
                    size: 15,
                    color:
                    Colors.white,
                  )
                      : null,
                ),

                const SizedBox(
                  width: 11,
                ),
              ],

              // ROOM ICON
              Container(
                width: 42,
                height: 42,
                decoration:
                BoxDecoration(
                  color: selected
                      ? kPrimaryColor
                      .withValues(
                    alpha:
                    0.09,
                  )
                      : Colors.grey
                      .withValues(
                    alpha:
                    0.055,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    13,
                  ),
                ),
                child: Icon(
                  Iconsax.location,
                  size: 19,
                  color: selected
                      ? kPrimaryColor
                      : Colors.grey
                      .shade500,
                ),
              ),

              const SizedBox(
                width: 11,
              ),

              // INFO
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    // ROOM
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            roomTitle,
                            maxLines: 1,
                            overflow:
                            TextOverflow
                                .ellipsis,
                            style:
                            primaryTextStyle
                                .copyWith(
                              fontSize:
                              13.5,
                              fontWeight:
                              bold,
                            ),
                          ),
                        ),

                        if (ac.lantai >
                            0)
                          Container(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal:
                              7,
                              vertical:
                              3,
                            ),
                            decoration:
                            BoxDecoration(
                              color: Colors
                                  .grey
                                  .withValues(
                                alpha:
                                0.07,
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                20,
                              ),
                            ),
                            child: Text(
                              'L${ac.lantai}',
                              style:
                              TextStyle(
                                fontSize:
                                7.8,
                                fontWeight:
                                FontWeight
                                    .w600,
                                color: Colors
                                    .grey
                                    .shade600,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    // AC NAME
                    Row(
                      children: [
                        Icon(
                          Icons
                              .ac_unit_rounded,
                          size: 12,
                          color:
                          kPrimaryColor,
                        ),

                        const SizedBox(
                          width: 5,
                        ),

                        Expanded(
                          child: Text(
                            acName,
                            maxLines: 1,
                            overflow:
                            TextOverflow
                                .ellipsis,
                            style:
                            TextStyle(
                              fontSize:
                              10,
                              fontWeight:
                              FontWeight
                                  .w600,
                              color:
                              kPrimaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (specification
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 3,
                      ),

                      Text(
                        specification,
                        maxLines: 1,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style:
                        greyTextStyle
                            .copyWith(
                          fontSize: 8.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STEP 2 - SCHEDULE
  // ============================================================

  Widget _buildStepSchedule() {
    return Padding(
      padding:
      const EdgeInsets.fromLTRB(
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
            'Waktu Kunjungan',
            'Pilih tanggal dan jam kunjungan teknisi',
          ),

          const SizedBox(
            height: 14,
          ),

          Expanded(
            child: ListView(
              physics:
              const BouncingScrollPhysics(),
              children: [
                _buildCalendar(),

                const SizedBox(
                  height: 16,
                ),

                _buildTimeSelector(),

                const SizedBox(
                  height: 14,
                ),

                _buildScheduleSummary(),

                const SizedBox(
                  height: 10,
                ),
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

    final today =
    DateTime(
      now.year,
      now.month,
      now.day,
    );

    return Container(
      padding:
      const EdgeInsets.all(
        10,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          20,
        ),
        border:
        Border.all(
          color: Colors.grey
              .withValues(
            alpha: 0.09,
          ),
        ),
      ),
      child: CalendarDatePicker(
        initialDate:
        _selectedDate ??
            today,
        firstDate:
        today,
        lastDate:
        today.add(
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

  Widget _buildTimeSelector() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          'Jam Kunjungan',
          style:
          primaryTextStyle
              .copyWith(
            fontSize: 13,
            fontWeight: bold,
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        Material(
          color:
          Colors.transparent,
          child: InkWell(
            onTap:
            _selectTime,
            borderRadius:
            BorderRadius.circular(
              16,
            ),
            child: Ink(
              padding:
              const EdgeInsets
                  .all(
                13,
              ),
              decoration:
              BoxDecoration(
                color:
                Colors.white,
                borderRadius:
                BorderRadius
                    .circular(
                  16,
                ),
                border:
                Border.all(
                  color: _selectedTime !=
                      null
                      ? kPrimaryColor
                      .withValues(
                    alpha:
                    0.25,
                  )
                      : Colors.grey
                      .withValues(
                    alpha:
                    0.10,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration:
                    BoxDecoration(
                      color:
                      kPrimaryColor
                          .withValues(
                        alpha:
                        0.08,
                      ),
                      borderRadius:
                      BorderRadius
                          .circular(
                        12,
                      ),
                    ),
                    child: Icon(
                      Iconsax.clock,
                      color:
                      kPrimaryColor,
                      size: 18,
                    ),
                  ),

                  const SizedBox(
                    width: 11,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Text(
                          'Waktu',
                          style:
                          greyTextStyle
                              .copyWith(
                            fontSize:
                            8.5,
                          ),
                        ),

                        const SizedBox(
                          height: 2,
                        ),

                        Text(
                          _selectedTime !=
                              null
                              ? _selectedTime!
                              .format(
                            context,
                          )
                              : 'Pilih jam kunjungan',
                          style:
                          primaryTextStyle
                              .copyWith(
                            fontSize:
                            11.5,
                            fontWeight:
                            bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    Icons
                        .arrow_forward_ios_rounded,
                    size: 13,
                    color: Colors
                        .grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleSummary() {
    if (_selectedDate ==
        null &&
        _selectedTime ==
            null) {
      return const SizedBox
          .shrink();
    }

    return Container(
      padding:
      const EdgeInsets
          .all(
        13,
      ),
      decoration:
      BoxDecoration(
        color:
        kPrimaryColor
            .withValues(
          alpha: 0.055,
        ),
        borderRadius:
        BorderRadius.circular(
          15,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax
                .info_circle,
            size: 17,
            color:
            kPrimaryColor,
          ),

          const SizedBox(
            width: 9,
          ),

          Expanded(
            child: Text(
              _selectedDate !=
                  null &&
                  _selectedTime !=
                      null
                  ? 'Kunjungan: '
                  '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} '
                  'pukul ${_selectedTime!.format(context)}'
                  : 'Lengkapi tanggal dan waktu kunjungan.',
              style:
              primaryTextStyle
                  .copyWith(
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 3
  // ============================================================

  Widget _buildStepConfirm() {
    return Padding(
      padding:
      const EdgeInsets.fromLTRB(
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
            'Catatan & Konfirmasi',
            'Pastikan data permintaan sudah benar',
          ),

          const SizedBox(
            height: 14,
          ),

          Expanded(
            child: ListView(
              physics:
              const BouncingScrollPhysics(),
              children: [
                _buildFinalSummary(),

                const SizedBox(
                  height: 16,
                ),

                _buildNoteField(),

                const SizedBox(
                  height: 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalSummary() {
    final selectedAc =
    widget.acList.where(
          (ac) =>
          _selectedAcIds
              .contains(
            ac.id,
          ),
    ).toList();

    final groupedByRoom =
    <String, List<AcModel>>{};

    for (final ac in selectedAc) {
      final room =
      (ac.room?.name ??
          '')
          .trim();

      final key =
      room.isNotEmpty
          ? room
          : ac.lantai >
          0
          ? 'Lantai ${ac.lantai}'
          : 'Tanpa Ruangan';

      groupedByRoom
          .putIfAbsent(
        key,
            () => [],
      )
          .add(
        ac,
      );
    }

    return Container(
      padding:
      const EdgeInsets.all(
        16,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          20,
        ),
        border:
        Border.all(
          color: Colors.grey
              .withValues(
            alpha: 0.09,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          _buildSummaryRow(
            icon:
            Iconsax.location,
            label: 'Lokasi',
            value:
            widget.lokasi.nama,
          ),

          const Divider(
            height: 24,
          ),

          _buildSummaryRow(
            icon:
            Icons.ac_unit_rounded,
            label: 'AC Dipilih',
            value:
            '${selectedAc.length} unit',
          ),

          const Divider(
            height: 24,
          ),

          _buildSummaryRow(
            icon:
            Iconsax.calendar_1,
            label: 'Tanggal',
            value:
            _selectedDate ==
                null
                ? '-'
                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
          ),

          const Divider(
            height: 24,
          ),

          _buildSummaryRow(
            icon:
            Iconsax.clock,
            label: 'Waktu',
            value:
            _selectedTime ==
                null
                ? '-'
                : _selectedTime!
                .format(
              context,
            ),
          ),

          const SizedBox(
            height: 17,
          ),

          Text(
            'Unit yang Dipilih',
            style:
            primaryTextStyle
                .copyWith(
              fontSize: 11.5,
              fontWeight: bold,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            '${groupedByRoom.length} kamar / area',
            style:
            greyTextStyle
                .copyWith(
              fontSize: 8.5,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          ...groupedByRoom
              .entries
              .map(
                (entry) =>
                _buildSelectedRoomSummary(
                  roomName:
                  entry.key,
                  acList:
                  entry.value,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedRoomSummary({
    required String roomName,
    required List<AcModel> acList,
  }) {
    return Container(
      width:
      double.infinity,
      margin:
      const EdgeInsets.only(
        bottom: 8,
      ),
      padding:
      const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 10,
      ),
      decoration:
      BoxDecoration(
        color:
        kPrimaryColor
            .withValues(
          alpha: 0.045,
        ),
        borderRadius:
        BorderRadius.circular(
          14,
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration:
            BoxDecoration(
              color:
              kPrimaryColor
                  .withValues(
                alpha: 0.08,
              ),
              borderRadius:
              BorderRadius.circular(
                10,
              ),
            ),
            child: Icon(
              Iconsax.location,
              size: 15,
              color:
              kPrimaryColor,
            ),
          ),

          const SizedBox(
            width: 9,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        roomName,
                        maxLines: 1,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style:
                        primaryTextStyle
                            .copyWith(
                          fontSize:
                          10.5,
                          fontWeight:
                          bold,
                        ),
                      ),
                    ),

                    Text(
                      '${acList.length} AC',
                      style:
                      TextStyle(
                        fontSize:
                        8.5,
                        color:
                        kPrimaryColor,
                        fontWeight:
                        FontWeight
                            .w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 6,
                ),

                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children:
                  acList.map(
                        (ac) {
                      final name =
                      ac.nama
                          .trim()
                          .isNotEmpty
                          ? ac
                          .nama
                          .trim()
                          : 'AC #${ac.id}';

                      return Container(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal:
                          7,
                          vertical:
                          4,
                        ),
                        decoration:
                        BoxDecoration(
                          color:
                          Colors.white,
                          borderRadius:
                          BorderRadius
                              .circular(
                            20,
                          ),
                        ),
                        child:
                        Text(
                          name,
                          style:
                          TextStyle(
                            fontSize:
                            8,
                            color:
                            kPrimaryColor,
                            fontWeight:
                            FontWeight
                                .w600,
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 35,
          height: 35,
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
          child: Icon(
            icon,
            size: 16,
            color:
            kPrimaryColor,
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              Text(
                label,
                style:
                greyTextStyle
                    .copyWith(
                  fontSize: 8.3,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                value,
                maxLines: 2,
                overflow:
                TextOverflow
                    .ellipsis,
                style:
                primaryTextStyle
                    .copyWith(
                  fontSize: 10.8,
                  fontWeight: bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // NOTE
  // ============================================================

  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Catatan',
              style:
              primaryTextStyle
                  .copyWith(
                fontSize: 14,
                fontWeight: bold,
              ),
            ),

            const SizedBox(
              width: 6,
            ),

            Container(
              padding:
              const EdgeInsets
                  .symmetric(
                horizontal: 7,
                vertical: 3,
              ),
              decoration:
              BoxDecoration(
                color: Colors.grey
                    .withValues(
                  alpha: 0.07,
                ),
                borderRadius:
                BorderRadius
                    .circular(
                  20,
                ),
              ),
              child: Text(
                'Opsional',
                style:
                greyTextStyle
                    .copyWith(
                  fontSize: 7.5,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 9,
        ),

        TextField(
          controller:
          _catatanController,
          maxLines: 4,
          decoration:
          InputDecoration(
            hintText:
            'Contoh: mohon datang setelah jam 10.00...',
            hintStyle:
            greyTextStyle
                .copyWith(
              fontSize: 10,
            ),
            filled: true,
            fillColor:
            Colors.white,
            contentPadding:
            const EdgeInsets
                .all(
              14,
            ),
            border:
            OutlineInputBorder(
              borderRadius:
              BorderRadius
                  .circular(
                16,
              ),
              borderSide:
              BorderSide.none,
            ),
            enabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius
                  .circular(
                16,
              ),
              borderSide:
              BorderSide(
                color: Colors.grey
                    .withValues(
                  alpha: 0.10,
                ),
              ),
            ),
            focusedBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius
                  .circular(
                16,
              ),
              borderSide:
              BorderSide(
                color:
                kPrimaryColor,
                width: 1.2,
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
    final canContinue =
        _currentStep != 0 ||
            _selectedAcIds
                .isNotEmpty;

    return Container(
      padding:
      EdgeInsets.fromLTRB(
        20,
        11,
        20,
        MediaQuery.of(
          context,
        ).padding.bottom +
            11,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color:
            Colors.black
                .withValues(
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
          if (_currentStep >
              0)
            Expanded(
              child:
              OutlinedButton(
                onPressed:
                _previousStep,
                style:
                OutlinedButton
                    .styleFrom(
                  minimumSize:
                  const Size
                      .fromHeight(
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
                    BorderRadius
                        .circular(
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
                    FontWeight
                        .w700,
                  ),
                ),
              ),
            ),

          if (_currentStep >
              0)
            const SizedBox(
              width: 10,
            ),

          Expanded(
            flex:
            _currentStep > 0
                ? 2
                : 1,
            child:
            ElevatedButton(
              onPressed:
              provider
                  .submittingCuci
                  ? null
                  : !canContinue
                  ? null
                  : _currentStep ==
                  2
                  ? _submitRequest
                  : _nextStep,
              style:
              ElevatedButton
                  .styleFrom(
                minimumSize:
                const Size
                    .fromHeight(
                  50,
                ),
                backgroundColor:
                kPrimaryColor,
                disabledBackgroundColor:
                Colors.grey
                    .shade300,
                foregroundColor:
                Colors.white,
                elevation: 0,
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius
                      .circular(
                    15,
                  ),
                ),
              ),
              child:
              provider
                  .submittingCuci
                  ? const SizedBox(
                width: 19,
                height: 19,
                child:
                CircularProgressIndicator(
                  strokeWidth:
                  2,
                  color:
                  Colors.white,
                ),
              )
                  : Row(
                mainAxisAlignment:
                MainAxisAlignment
                    .center,
                children: [
                  Text(
                    _currentStep ==
                        2
                        ? 'Ajukan Permintaan'
                        : _currentStep ==
                        0
                        ? _selectedAcIds
                        .isEmpty
                        ? 'Pilih AC'
                        : 'Lanjut • ${_selectedAcIds.length} AC'
                        : 'Lanjut',
                    style:
                    const TextStyle(
                      fontWeight:
                      FontWeight
                          .w700,
                    ),
                  ),

                  if (_currentStep !=
                      2) ...[
                    const SizedBox(
                      width: 7,
                    ),
                    const Icon(
                      Icons
                          .arrow_forward_rounded,
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
          primaryTextStyle
              .copyWith(
            fontSize: 16,
            fontWeight: bold,
          ),
        ),

        const SizedBox(
          height: 3,
        ),

        Text(
          subtitle,
          style:
          greyTextStyle
              .copyWith(
            fontSize: 9.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyAcSearch() {
    final hasFilter =
        _selectedFloor !=
            null ||
            _searchController
                .text
                .trim()
                .isNotEmpty;

    return Center(
      child: Padding(
        padding:
        const EdgeInsets
            .all(
          28,
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration:
              BoxDecoration(
                color:
                kPrimaryColor
                    .withValues(
                  alpha: 0.07,
                ),
                borderRadius:
                BorderRadius
                    .circular(
                  17,
                ),
              ),
              child: Icon(
                Iconsax
                    .search_status,
                size: 24,
                color:
                kPrimaryColor,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              'AC tidak ditemukan',
              style:
              primaryTextStyle
                  .copyWith(
                fontSize: 13,
                fontWeight: bold,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            Text(
              hasFilter
                  ? 'Coba ubah pencarian atau filter lantai.'
                  : 'Tidak ada unit AC tersedia.',
              textAlign:
              TextAlign.center,
              style:
              greyTextStyle
                  .copyWith(
                fontSize: 9.5,
              ),
            ),

            if (hasFilter) ...[
              const SizedBox(
                height: 12,
              ),

              TextButton.icon(
                onPressed:
                _clearFilter,
                icon:
                const Icon(
                  Iconsax.refresh,
                  size: 15,
                ),
                label:
                const Text(
                  'Reset Filter',
                ),
                style:
                TextButton
                    .styleFrom(
                  foregroundColor:
                  kPrimaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}