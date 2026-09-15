import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/servis_model.dart';
import '../../providers/owner_master_provider.dart';
import '../../theme/theme.dart';

class OwnerServiceDetailPage extends StatefulWidget {
  final ServisModel service;
  final bool isReassign;

  const OwnerServiceDetailPage({
    super.key,
    required this.service,
    this.isReassign = false,
  });

  @override
  State<OwnerServiceDetailPage> createState() =>
      _OwnerServiceDetailPageState();
}

class _OwnerServiceDetailPageState extends State<OwnerServiceDetailPage> {
  // ============================================================
  // STATE
  // ============================================================

  int _currentStep = 0;

  final Set<int> _selectedAcIds = <int>{};

  /// Teknisi yang dipilih untuk service ini.
  /// Bisa lebih dari satu.
  final Set<int> _selectedTechnicianIds = <int>{};

  /// Teknisi yang sedang aktif ketika pembagian AC.
  int? _activeTechnicianId;

  /// Wajib dipilih.
  DateTime? _tanggalDitugaskan;

  int? _selectedFloorNumber;

  /// technician_id -> set(ac_unit_ids)
  final Map<int, Set<int>> _groups = <int, Set<int>>{};

  // ============================================================
  // COLORS
  // ============================================================

  static const Color _backgroundColor = Color(0xFFF5F6FA);
  static const Color _textPrimary = Color(0xFF20222E);
  static const Color _successColor = Color(0xFF16A34A);
  static const Color _warningColor = Color(0xFFF59E0B);
  static const Color _dangerColor = Color(0xFFEF4444);

  // ============================================================
  // STEPS
  // ============================================================

  final List<_AssignmentStep> _steps = const [
    _AssignmentStep(
      title: 'Detail',
      subtitle: 'Informasi service',
      icon: Iconsax.document_text,
    ),
    _AssignmentStep(
      title: 'Teknisi',
      subtitle: 'Pilih teknisi',
      icon: Iconsax.profile_2user,
    ),
    _AssignmentStep(
      title: 'Unit AC',
      subtitle: 'Bagi unit',
      icon: Iconsax.cpu,
    ),
    _AssignmentStep(
      title: 'Review',
      subtitle: 'Konfirmasi',
      icon: Iconsax.tick_circle,
    ),
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    initializeDateFormatting('id_ID', null);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<OwnerMasterProvider>();

      await provider.fetchTechnicians();

      _prefillFromItems();

      if (!mounted) {
        return;
      }

      setState(() {});
    });
  }

  // ============================================================
  // STEP NAVIGATION
  // ============================================================

  void _nextStep() {
    // ==========================================================
    // DETAIL -> TEKNISI
    // ==========================================================

    if (_currentStep == 0) {
      if (_tanggalDitugaskan == null) {
        _showMessage(
          'Tanggal penugasan wajib dipilih sebelum melanjutkan.',
          color: _warningColor,
          icon: Iconsax.calendar_remove,
        );

        return;
      }

      setState(() {
        _currentStep = 1;
      });

      return;
    }

    // ==========================================================
    // TEKNISI -> UNIT AC
    // ==========================================================

    if (_currentStep == 1) {
      if (_selectedTechnicianIds.isEmpty) {
        _showMessage(
          'Pilih minimal satu teknisi.',
          color: _warningColor,
          icon: Iconsax.profile_2user,
        );

        return;
      }

      setState(() {
        _activeTechnicianId ??= _selectedTechnicianIds.first;

        _currentStep = 2;
      });

      return;
    }

    // ==========================================================
    // UNIT AC -> REVIEW
    // ==========================================================

    if (_currentStep == 2) {
      if (_groups.isEmpty) {
        _showMessage(
          'Belum ada unit AC yang di-assign ke teknisi.',
          color: _warningColor,
          icon: Iconsax.warning_2,
        );

        return;
      }

      final acList = _getAcList();

      final assignedCount = acList.where((ac) {
        final id = int.tryParse(
          (ac['id'] ?? '').toString(),
        ) ??
            0;

        return _isAcAssigned(id);
      }).length;

      final unassignedCount = acList.length - assignedCount;

      if (unassignedCount > 0) {
        _showMessage(
          '$unassignedCount unit AC belum memiliki teknisi.',
          color: _warningColor,
          icon: Iconsax.warning_2,
        );

        return;
      }

      setState(() {
        _currentStep = 3;
      });

      return;
    }
  }

  void _previousStep() {
    if (_currentStep <= 0) {
      return;
    }

    setState(() {
      _currentStep--;
    });
  }

  void _goToStep(int index) {
    if (index < 0 || index >= _steps.length) {
      return;
    }

    if (index > 0 && _tanggalDitugaskan == null) {
      _showMessage(
        'Pilih tanggal penugasan terlebih dahulu.',
        color: _warningColor,
        icon: Iconsax.calendar_remove,
      );

      return;
    }

    if (index > 1 && _selectedTechnicianIds.isEmpty) {
      _showMessage(
        'Pilih teknisi terlebih dahulu.',
        color: _warningColor,
        icon: Iconsax.profile_2user,
      );

      return;
    }

    if (index > 2 && _groups.isEmpty) {
      return;
    }

    setState(() {
      _currentStep = index;
    });
  }

  // ============================================================
  // PREFILL
  // ============================================================

  void _prefillFromItems() {
    final items = widget.service.itemsData;

    for (final item in items) {
      final acId = int.tryParse(
        (item['ac_unit_id'] ?? '').toString(),
      ) ??
          int.tryParse(
            (
                item['ac_unit'] is Map
                    ? item['ac_unit']['id']
                    : ''
            ).toString(),
          ) ??
          0;

      final technicianId = int.tryParse(
        (item['technician_id'] ?? '').toString(),
      ) ??
          int.tryParse(
            (
                item['technician'] is Map
                    ? item['technician']['id']
                    : ''
            ).toString(),
          ) ??
          0;

      if (acId > 0 && technicianId > 0) {
        _groups.putIfAbsent(
          technicianId,
              () => <int>{},
        );

        _groups[technicianId]!.add(acId);

        _selectedTechnicianIds.add(
          technicianId,
        );
      }
    }

    if (_selectedTechnicianIds.isNotEmpty) {
      _activeTechnicianId ??=
          _selectedTechnicianIds.first;
    }

    if (widget.isReassign &&
        widget.service.tanggalDitugaskan != null) {
      _tanggalDitugaskan = DateUtils.dateOnly(
        widget.service.tanggalDitugaskan!.toLocal(),
      );
    }
  }

  // ============================================================
  // AC LIST
  // ============================================================

  List<Map<String, dynamic>> _getAcList() {
    final items = widget.service.itemsData;

    final fromItems = items
        .map(
          (item) => item['ac_unit'],
    )
        .where(
          (item) => item is Map,
    )
        .map(
          (item) => Map<String, dynamic>.from(
        item as Map,
      ),
    )
        .toList();

    final seen = <int>{};

    final unique = <Map<String, dynamic>>[];

    for (final ac in fromItems) {
      final id = int.tryParse(
        (ac['id'] ?? '').toString(),
      ) ??
          0;

      if (id <= 0 || seen.contains(id)) {
        continue;
      }

      seen.add(id);
      unique.add(ac);
    }

    unique.sort(
          (a, b) {
        final floorA = _getFloorNumberFromAc(a);
        final floorB = _getFloorNumberFromAc(b);

        if (floorA != floorB) {
          return floorA.compareTo(floorB);
        }

        final roomA = _getRoomNameFromAc(a).toLowerCase();
        final roomB = _getRoomNameFromAc(b).toLowerCase();

        if (roomA != roomB) {
          return roomA.compareTo(roomB);
        }

        final nameA = (a['name'] ?? '')
            .toString()
            .toLowerCase();

        final nameB = (b['name'] ?? '')
            .toString()
            .toLowerCase();

        return nameA.compareTo(nameB);
      },
    );

    return unique;
  }

  int _getFloorNumberFromAc(
      Map<String, dynamic> ac,
      ) {
    final room = ac['room'];

    if (room is Map) {
      final floor = room['floor'];

      if (floor is Map) {
        return int.tryParse(
          (floor['number'] ?? 0).toString(),
        ) ??
            0;
      }
    }

    return int.tryParse(
      (ac['lantai'] ?? 0).toString(),
    ) ??
        0;
  }

  String _getFloorLabelFromAc(
      Map<String, dynamic> ac,
      ) {
    final room = ac['room'];

    if (room is Map) {
      final floor = room['floor'];

      if (floor is Map) {
        final name = (floor['name'] ?? '')
            .toString()
            .trim();

        final number = int.tryParse(
          (floor['number'] ?? 0).toString(),
        ) ??
            0;

        if (name.isNotEmpty) {
          return name;
        }

        if (number > 0) {
          return 'Lantai $number';
        }
      }
    }

    final floor = int.tryParse(
      (ac['lantai'] ?? 0).toString(),
    ) ??
        0;

    if (floor > 0) {
      return 'Lantai $floor';
    }

    return '-';
  }

  String _getRoomNameFromAc(
      Map<String, dynamic> ac,
      ) {
    final room = ac['room'];

    if (room is Map) {
      return (room['name'] ?? '')
          .toString()
          .trim();
    }

    return '';
  }

  List<int> _extractFloorOptions(
      List<Map<String, dynamic>> acList,
      ) {
    final floors = acList
        .map(
      _getFloorNumberFromAc,
    )
        .where(
          (floor) => floor > 0,
    )
        .toSet()
        .toList()
      ..sort();

    return floors;
  }

  // ============================================================
  // ASSIGNMENT HELPERS
  // ============================================================

  bool _isAcAssigned(int acId) {
    for (final entry in _groups.entries) {
      if (entry.value.contains(acId)) {
        return true;
      }
    }

    return false;
  }

  int? _assignedTechIdOfAc(int acId) {
    for (final entry in _groups.entries) {
      if (entry.value.contains(acId)) {
        return entry.key;
      }
    }

    return null;
  }

  String _techNameById(
      OwnerMasterProvider provider,
      int technicianId,
      ) {
    final index = provider.technicians.indexWhere(
          (technician) => technician.id == technicianId,
    );

    if (index == -1) {
      return 'Teknisi #$technicianId';
    }

    final name = provider.technicians[index]
        .name
        ?.trim();

    if (name == null || name.isEmpty) {
      return 'Teknisi #$technicianId';
    }

    return name;
  }

  int _getAssignedCountForTechnician(
      int technicianId,
      ) {
    return _groups[technicianId]?.length ?? 0;
  }

  int _getTotalAssignedCount() {
    final ids = <int>{};

    for (final group in _groups.values) {
      ids.addAll(group);
    }

    return ids.length;
  }

  // ============================================================
  // SELECT ALL
  // ============================================================

  void _toggleSelectAll(
      List<Map<String, dynamic>> acList,
      ) {
    final availableIds = acList
        .map(
          (ac) =>
      int.tryParse(
        (ac['id'] ?? '').toString(),
      ) ??
          0,
    )
        .where(
          (id) => id > 0,
    )
        .where(
          (id) => !_isAcAssigned(id),
    )
        .toList();

    final allSelected = availableIds.isNotEmpty &&
        availableIds.every(
          _selectedAcIds.contains,
        );

    setState(() {
      if (allSelected) {
        _selectedAcIds.removeAll(
          availableIds,
        );
      } else {
        _selectedAcIds.addAll(
          availableIds,
        );
      }
    });
  }

  // ============================================================
  // ASSIGN SELECTED
  // ============================================================

  void _assignSelectedToTechnician() {
    if (_activeTechnicianId == null) {
      _showMessage(
        'Pilih teknisi tujuan terlebih dahulu.',
        color: _warningColor,
        icon: Iconsax.profile_2user,
      );

      return;
    }

    if (_selectedAcIds.isEmpty) {
      _showMessage(
        'Pilih minimal satu unit AC.',
        color: _warningColor,
        icon: Iconsax.cpu,
      );

      return;
    }

    final technicianId = _activeTechnicianId!;

    final ids = Set<int>.from(
      _selectedAcIds,
    );

    setState(() {
      // ========================================================
      // 1 AC hanya boleh ada pada satu teknisi.
      // ========================================================

      for (final entry in _groups.entries) {
        if (entry.key == technicianId) {
          continue;
        }

        entry.value.removeAll(ids);
      }

      _groups.removeWhere(
            (
            key,
            value,
            ) =>
        value.isEmpty,
      );

      _groups.putIfAbsent(
        technicianId,
            () => <int>{},
      );

      _groups[technicianId]!.addAll(
        ids,
      );

      _selectedAcIds.clear();
    });

    final technicianName = _techNameById(
      context.read<OwnerMasterProvider>(),
      technicianId,
    );

    _showMessage(
      '${ids.length} unit AC diberikan ke $technicianName.',
      color: _successColor,
      icon: Iconsax.tick_circle,
    );
  }

  void _removeAcFromGroup(
      int technicianId,
      int acId,
      ) {
    setState(() {
      final units = _groups[technicianId];

      if (units == null) {
        return;
      }

      units.remove(acId);

      if (units.isEmpty) {
        _groups.remove(technicianId);
      }
    });
  }

  // ============================================================
  // MULTI TECHNICIAN SELECTION
  // ============================================================

  void _toggleTechnician(
      int technicianId,
      ) {
    final selected = _selectedTechnicianIds.contains(
      technicianId,
    );

    final assignedCount =
    _getAssignedCountForTechnician(
      technicianId,
    );

    if (selected && assignedCount > 0) {
      _showMessage(
        'Teknisi masih memiliki $assignedCount unit AC. Pindahkan atau hapus unit terlebih dahulu.',
        color: _warningColor,
        icon: Iconsax.warning_2,
      );

      return;
    }

    setState(() {
      if (selected) {
        _selectedTechnicianIds.remove(
          technicianId,
        );

        if (_activeTechnicianId ==
            technicianId) {
          _activeTechnicianId =
          _selectedTechnicianIds.isEmpty
              ? null
              : _selectedTechnicianIds.first;
        }
      } else {
        _selectedTechnicianIds.add(
          technicianId,
        );

        _activeTechnicianId ??=
            technicianId;
      }

      _selectedAcIds.clear();
    });
  }

  // ============================================================
  // MOVE AC
  // ============================================================

  Future<void> _handleLockedAcTap(
      OwnerMasterProvider provider, {
        required int acId,
        required int fromTechId,
      }) async {
    if (_activeTechnicianId == null) {
      _showMessage(
        'Pilih teknisi tujuan terlebih dahulu.',
        color: _warningColor,
        icon: Iconsax.info_circle,
      );

      return;
    }

    final toTechId = _activeTechnicianId!;

    if (toTechId == fromTechId) {
      _showMessage(
        'AC ini sudah ditugaskan ke teknisi tersebut.',
        color: _warningColor,
        icon: Iconsax.info_circle,
      );

      return;
    }

    final fromName = _techNameById(
      provider,
      fromTechId,
    );

    final toName = _techNameById(
      provider,
      toTechId,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (
          dialogContext,
          ) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              20,
            ),
          ),
          title: const Row(
            children: [
              Icon(
                Iconsax.refresh,
                color: kPrimaryColor,
                size: 21,
              ),
              SizedBox(width: 9),
              Text(
                'Pindahkan AC?',
              ),
            ],
          ),
          content: Text(
            'Unit AC saat ini ditangani oleh $fromName.\n\n'
                'Pindahkan ke $toName?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Batal',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Pindahkan',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _groups[fromTechId]?.remove(
        acId,
      );

      if (_groups[fromTechId]?.isEmpty ??
          false) {
        _groups.remove(
          fromTechId,
        );
      }

      _groups.putIfAbsent(
        toTechId,
            () => <int>{},
      );

      _groups[toTechId]!.add(
        acId,
      );

      _selectedAcIds.remove(
        acId,
      );
    });

    _showMessage(
      'Unit AC dipindahkan dari $fromName ke $toName.',
      color: _successColor,
      icon: Iconsax.tick_circle,
    );
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _pickAssignmentDate() async {
    final today = DateUtils.dateOnly(
      DateTime.now(),
    );

    final selected = await showDatePicker(
      context: context,
      initialDate:
      _tanggalDitugaskan ?? today,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'PILIH TANGGAL PENUGASAN',
      cancelText: 'BATAL',
      confirmText: 'PILIH',
      fieldLabelText: 'Tanggal Penugasan',
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _tanggalDitugaskan = DateUtils.dateOnly(
        selected,
      );
    });

    _showMessage(
      'Tanggal penugasan berhasil dipilih.',
      color: _successColor,
      icon: Iconsax.calendar_tick,
    );
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _submit() async {
    final provider =
    context.read<OwnerMasterProvider>();

    final serviceId = widget.service.id;

    if (serviceId <= 0) {
      _showMessage(
        'Service ID tidak valid.',
        color: Colors.red,
        icon: Iconsax.close_circle,
      );

      return;
    }

    if (_tanggalDitugaskan == null) {
      _showMessage(
        'Tanggal penugasan wajib dipilih.',
        color: _warningColor,
        icon: Iconsax.calendar_remove,
      );

      setState(() {
        _currentStep = 0;
      });

      return;
    }

    if (_selectedTechnicianIds.isEmpty) {
      _showMessage(
        'Belum ada teknisi yang dipilih.',
        color: _warningColor,
        icon: Iconsax.profile_2user,
      );

      setState(() {
        _currentStep = 1;
      });

      return;
    }

    final groups = _groups.entries
        .map(
          (entry) => <String, dynamic>{
        'technician_id': entry.key,
        'ac_unit_ids':
        entry.value.toList(),
      },
    )
        .where(
          (group) =>
      (group['ac_unit_ids'] as List)
          .isNotEmpty,
    )
        .toList();

    if (groups.isEmpty) {
      _showMessage(
        'Belum ada AC yang di-assign.',
        color: _warningColor,
        icon: Iconsax.warning_2,
      );

      setState(() {
        _currentStep = 2;
      });

      return;
    }

    final acList = _getAcList();

    final totalAssigned =
    _getTotalAssignedCount();

    if (totalAssigned < acList.length) {
      _showMessage(
        '${acList.length - totalAssigned} unit AC belum memiliki teknisi.',
        color: _warningColor,
        icon: Iconsax.warning_2,
      );

      setState(() {
        _currentStep = 2;
      });

      return;
    }

    final confirmed =
    await _showSubmitConfirmation();

    if (confirmed != true) {
      return;
    }

    final success =
    await provider.assignTechnicianPerAcGroups(
      serviceId,
      groups: groups,
      tanggalDitugaskan:
      _tanggalDitugaskan!,
      isReassign:
      widget.isReassign,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      _showMessage(
        provider.submitError ??
            'Gagal menyimpan penugasan.',
        color: Colors.red,
        icon: Iconsax.close_circle,
      );

      return;
    }

    _showMessage(
      widget.isReassign
          ? 'Perubahan penugasan berhasil disimpan.'
          : 'Penugasan teknisi berhasil disimpan.',
      color: _successColor,
      icon: Iconsax.tick_circle,
    );

    await provider.fetchServices(
      useLastQuery: true,
    );

    if (!mounted) {
      return;
    }

    Navigator.pop(
      context,
      true,
    );
  }

  Future<bool?> _showSubmitConfirmation() {
    final totalAc =
    _getTotalAssignedCount();

    final assignmentDate =
    _tanggalDitugaskan == null
        ? '-'
        : DateFormat(
      'dd MMMM yyyy',
      'id_ID',
    ).format(
      _tanggalDitugaskan!,
    );

    return showDialog<bool>(
      context: context,
      builder: (
          dialogContext,
          ) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              20,
            ),
          ),
          title: const Text(
            'Simpan Penugasan?',
            style: TextStyle(
              fontWeight:
              FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize:
            MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                '${_groups.length} teknisi akan menangani $totalAc unit AC.',
              ),

              const SizedBox(
                height: 12,
              ),

              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.all(
                  11,
                ),
                decoration:
                BoxDecoration(
                  color: kPrimaryColor
                      .withValues(
                    alpha: 0.06,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Iconsax.calendar_tick,
                      size: 18,
                      color: kPrimaryColor,
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          Text(
                            'Tanggal Penugasan',
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors
                                  .grey[600],
                            ),
                          ),

                          const SizedBox(
                            height: 2,
                          ),

                          Text(
                            assignmentDate,
                            style:
                            const TextStyle(
                              fontSize: 11,
                              fontWeight:
                              FontWeight
                                  .w700,
                              color:
                              kPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              const Text(
                'Pastikan pembagian unit AC ke masing-masing teknisi sudah benar.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Periksa Lagi',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                _successColor,
                foregroundColor:
                Colors.white,
              ),
              child: const Text(
                'Ya, Simpan',
              ),
            ),
          ],
        );
      },
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
    context.watch<OwnerMasterProvider>();

    final acList = _getAcList();

    return Scaffold(
      backgroundColor:
      _backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildStepHeader(),

            Expanded(
              child:
              AnimatedSwitcher(
                duration:
                const Duration(
                  milliseconds: 220,
                ),
                child:
                _buildStepContent(
                  provider,
                  acList,
                ),
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
  // APPBAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor:
      Colors.transparent,
      backgroundColor: Colors.white,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(
            context,
          );
        },
        icon: const Icon(
          Iconsax.arrow_left_2,
          color: kPrimaryColor,
          size: 20,
        ),
      ),
      title: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            widget.isReassign
                ? 'Ganti Penugasan'
                : 'Assign Teknisi',
            style:
            primaryTextStyle.copyWith(
              fontSize: 17,
              fontWeight: bold,
            ),
          ),
          const SizedBox(
            height: 1,
          ),
          Text(
            'Service #${widget.service.id}',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 9,
              fontWeight:
              FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        if (widget.isReassign)
          Padding(
            padding:
            const EdgeInsets.only(
              right: 14,
            ),
            child: Center(
              child: Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration:
                BoxDecoration(
                  color: Colors.blue
                      .withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),
                child: const Text(
                  'Reassign',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 8,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // STEP HEADER
  // ============================================================

  Widget _buildStepHeader() {
    return Container(
      color: Colors.white,
      padding:
      const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        14,
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(
              _steps.length,
                  (
                  index,
                  ) {
                final active =
                    index ==
                        _currentStep;

                final completed =
                    index <
                        _currentStep;

                return Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child:
                        _buildStepItem(
                          index:
                          index,
                          active:
                          active,
                          completed:
                          completed,
                        ),
                      ),
                      if (index !=
                          _steps.length -
                              1)
                        Container(
                          width: 14,
                          height: 2,
                          color:
                          completed
                              ? kPrimaryColor
                              : const Color(
                            0xFFE8E9EE,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(
            height: 11,
          ),

          ClipRRect(
            borderRadius:
            BorderRadius.circular(
              10,
            ),
            child:
            LinearProgressIndicator(
              value:
              (_currentStep + 1) /
                  _steps.length,
              minHeight: 4,
              backgroundColor:
              const Color(
                0xFFEDEEF3,
              ),
              color: kPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required int index,
    required bool active,
    required bool completed,
  }) {
    final step = _steps[index];

    final enabled =
        index == 0 ||
            (index == 1 &&
                _tanggalDitugaskan !=
                    null) ||
            (index == 2 &&
                _tanggalDitugaskan !=
                    null &&
                _selectedTechnicianIds
                    .isNotEmpty) ||
            (index == 3 &&
                _tanggalDitugaskan !=
                    null &&
                _selectedTechnicianIds
                    .isNotEmpty &&
                _groups.isNotEmpty) ||
            index < _currentStep;

    final color =
    active || completed
        ? kPrimaryColor
        : const Color(
      0xFFB6B8C2,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled
            ? () {
          _goToStep(
            index,
          );
        }
            : null,
        borderRadius:
        BorderRadius.circular(
          12,
        ),
        child: Padding(
          padding:
          const EdgeInsets
              .symmetric(
            vertical: 3,
          ),
          child: Column(
            children: [
              AnimatedContainer(
                duration:
                const Duration(
                  milliseconds:
                  180,
                ),
                width: 34,
                height: 34,
                decoration:
                BoxDecoration(
                  color: active
                      ? kPrimaryColor
                      : completed
                      ? kPrimaryColor
                      .withValues(
                    alpha:
                    0.10,
                  )
                      : const Color(
                    0xFFF5F6FA,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    10,
                  ),
                ),
                child: Icon(
                  completed
                      ? Iconsax
                      .tick_circle
                      : step.icon,
                  size: 16,
                  color: active
                      ? Colors.white
                      : color,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              Text(
                step.title,
                maxLines: 1,
                overflow:
                TextOverflow
                    .ellipsis,
                style: TextStyle(
                  fontSize: 7.5,
                  color: active
                      ? _textPrimary
                      : color,
                  fontWeight: active
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STEP CONTENT
  // ============================================================

  Widget _buildStepContent(
      OwnerMasterProvider provider,
      List<Map<String, dynamic>>
      acList,
      ) {
    switch (_currentStep) {
      case 0:
        return _buildDetailStep();

      case 1:
        return _buildTechnicianStep(
          provider,
        );

      case 2:
        return _buildAcStep(
          provider,
          acList,
        );

      case 3:
        return _buildReviewStep(
          provider,
          acList,
        );

      default:
        return const SizedBox
            .shrink();
    }
  }

  // ============================================================
  // STEP 1 - DETAIL
  // ============================================================

  Widget _buildDetailStep() {
    final service =
        widget.service;

    final visitDate =
        service.tanggalBerkunjung;

    final date =
    visitDate == null
        ? '-'
        : DateFormat(
      'EEEE, dd MMMM yyyy',
      'id_ID',
    ).format(
      visitDate.toLocal(),
    );

    final time =
    visitDate == null
        ? '-'
        : DateFormat(
      'HH:mm',
    ).format(
      visitDate.toLocal(),
    );

    final client =
    service.clientNama.trim();

    final location =
    service.lokasiNama.trim();

    return ListView(
      key: const ValueKey(
        'detail-step',
      ),
      physics:
      const BouncingScrollPhysics(),
      padding:
      const EdgeInsets.all(
        16,
      ),
      children: [
        _buildStepIntro(
          icon:
          Iconsax.document_text,
          title:
          'Detail Service',
          subtitle:
          'Periksa informasi service dan tentukan tanggal penugasan sebelum memilih teknisi.',
        ),

        const SizedBox(
          height: 14,
        ),

        _buildWhiteCard(
          child: Column(
            children: [
              _buildDetailRow(
                icon:
                Iconsax.location,
                label:
                'Lokasi Service',
                value:
                location.isEmpty ||
                    location ==
                        '-'
                    ? 'Lokasi belum tersedia'
                    : location,
                color:
                kPrimaryColor,
              ),

              _buildDivider(),

              _buildDetailRow(
                icon: Iconsax.user,
                label:
                'Client / PIC',
                value:
                client.isEmpty ||
                    client == '-'
                    ? 'Belum tersedia'
                    : client,
                color:
                const Color(
                  0xFFB7791F,
                ),
              ),

              _buildDivider(),

              _buildDetailRow(
                icon:
                Iconsax.setting_2,
                label:
                'Jenis Service',
                value:
                service
                    .jenisDisplay,
                color:
                service
                    .statusColor,
              ),

              _buildDivider(),

              _buildDetailRow(
                icon: Iconsax.cpu,
                label:
                'Jumlah Unit',
                value:
                '${service.jumlahAc > 0 ? service.jumlahAc : service.acUnits.length} AC',
                color:
                const Color(
                  0xFF7950C8,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        _buildWhiteCard(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              const Text(
                'Jadwal Kunjungan',
                style: TextStyle(
                  color:
                  _textPrimary,
                  fontSize: 12,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Row(
                children: [
                  Expanded(
                    child:
                    _buildScheduleBox(
                      icon: Iconsax
                          .calendar_1,
                      title:
                      'Tanggal',
                      value: date,
                    ),
                  ),

                  const SizedBox(
                    width: 9,
                  ),

                  Expanded(
                    child:
                    _buildScheduleBox(
                      icon:
                      Iconsax.clock,
                      title: 'Jam',
                      value: time,
                      valueColor:
                      kPrimaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 16,
        ),

        Row(
          children: [
            const Expanded(
              child: Text(
                'Tanggal Penugasan',
                style: TextStyle(
                  color:
                  _textPrimary,
                  fontSize: 13,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ),

            Container(
              padding:
              const EdgeInsets
                  .symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration:
              BoxDecoration(
                color: _dangerColor
                    .withValues(
                  alpha: 0.08,
                ),
                borderRadius:
                BorderRadius
                    .circular(
                  20,
                ),
              ),
              child: const Row(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  Icon(
                    Iconsax
                        .info_circle,
                    size: 11,
                    color:
                    _dangerColor,
                  ),

                  SizedBox(
                    width: 4,
                  ),

                  Text(
                    'WAJIB DIISI',
                    style:
                    TextStyle(
                      fontSize: 7.5,
                      color:
                      _dangerColor,
                      fontWeight:
                      FontWeight
                          .w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 5,
        ),

        Text(
          'Tanggal ini digunakan sebagai tanggal resmi penugasan teknisi.',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 8.5,
            height: 1.4,
          ),
        ),

        const SizedBox(
          height: 9,
        ),

        _buildAssignmentDateCard(),

        if (_tanggalDitugaskan ==
            null) ...[
          const SizedBox(
            height: 8,
          ),

          Container(
            padding:
            const EdgeInsets
                .symmetric(
              horizontal: 10,
              vertical: 9,
            ),
            decoration:
            BoxDecoration(
              color: _warningColor
                  .withValues(
                alpha: 0.055,
              ),
              borderRadius:
              BorderRadius
                  .circular(
                11,
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Iconsax.warning_2,
                  size: 14,
                  color:
                  _warningColor,
                ),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Anda belum memilih tanggal penugasan. Tombol Lanjutkan belum dapat digunakan.',
                    style:
                    TextStyle(
                      color:
                      _warningColor,
                      fontSize: 8,
                      height: 1.35,
                      fontWeight:
                      FontWeight
                          .w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (widget.isReassign) ...[
          const SizedBox(
            height: 12,
          ),

          Container(
            padding:
            const EdgeInsets.all(
              13,
            ),
            decoration:
            BoxDecoration(
              color: Colors.blue
                  .withValues(
                alpha: 0.06,
              ),
              borderRadius:
              BorderRadius
                  .circular(
                14,
              ),
              border: Border.all(
                color: Colors.blue
                    .withValues(
                  alpha: 0.10,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                const Icon(
                  Iconsax.info_circle,
                  size: 18,
                  color: Colors.blue,
                ),

                const SizedBox(
                  width: 9,
                ),

                Expanded(
                  child: Text(
                    'Mode ganti teknisi aktif. Penugasan sebelumnya sudah dimuat dan dapat Anda ubah.',
                    style: TextStyle(
                      color: Colors
                          .blue[700],
                      fontSize: 9,
                      height: 1.45,
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

  // ============================================================
  // ASSIGNMENT DATE CARD
  // ============================================================

  Widget _buildAssignmentDateCard() {
    final selected =
        _tanggalDitugaskan != null;

    final cardColor = selected
        ? _successColor
        : _warningColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
        _pickAssignmentDate,
        borderRadius:
        BorderRadius.circular(
          17,
        ),
        child: AnimatedContainer(
          duration:
          const Duration(
            milliseconds: 180,
          ),
          width: double.infinity,
          padding:
          const EdgeInsets.all(
            14,
          ),
          decoration:
          BoxDecoration(
            color: selected
                ? _successColor
                .withValues(
              alpha: 0.045,
            )
                : _warningColor
                .withValues(
              alpha: 0.055,
            ),
            borderRadius:
            BorderRadius.circular(
              17,
            ),
            border: Border.all(
              color: cardColor
                  .withValues(
                alpha: selected
                    ? 0.22
                    : 0.35,
              ),
              width:
              selected ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: cardColor
                    .withValues(
                  alpha: selected
                      ? 0.035
                      : 0.07,
                ),
                blurRadius: 13,
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
              Container(
                width: 50,
                height: 50,
                decoration:
                BoxDecoration(
                  color: cardColor
                      .withValues(
                    alpha: 0.11,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    14,
                  ),
                ),
                child: Icon(
                  selected
                      ? Iconsax
                      .calendar_tick
                      : Iconsax
                      .calendar_edit,
                  size: 21,
                  color: cardColor,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selected
                                ? 'Tanggal Penugasan'
                                : 'Pilih Tanggal Penugasan',
                            style:
                            TextStyle(
                              color: selected
                                  ? _textPrimary
                                  : _warningColor,
                              fontSize:
                              11.5,
                              fontWeight:
                              FontWeight
                                  .w800,
                            ),
                          ),
                        ),

                        if (selected)
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
                              color: _successColor
                                  .withValues(
                                alpha:
                                0.08,
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                20,
                              ),
                            ),
                            child:
                            const Row(
                              mainAxisSize:
                              MainAxisSize
                                  .min,
                              children: [
                                Icon(
                                  Iconsax
                                      .tick_circle,
                                  size:
                                  10,
                                  color:
                                  _successColor,
                                ),
                                SizedBox(
                                  width:
                                  3,
                                ),
                                Text(
                                  'Dipilih',
                                  style:
                                  TextStyle(
                                    color:
                                    _successColor,
                                    fontSize:
                                    7,
                                    fontWeight:
                                    FontWeight
                                        .w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    if (selected)
                      Text(
                        DateFormat(
                          'EEEE, dd MMMM yyyy',
                          'id_ID',
                        ).format(
                          _tanggalDitugaskan!,
                        ),
                        style:
                        const TextStyle(
                          color:
                          _successColor,
                          fontSize: 10,
                          fontWeight:
                          FontWeight
                              .w700,
                        ),
                      )
                    else
                      const Text(
                        'Belum dipilih • wajib sebelum melanjutkan',
                        style:
                        TextStyle(
                          color:
                          _warningColor,
                          fontSize: 8.5,
                          fontWeight:
                          FontWeight
                              .w600,
                        ),
                      ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      selected
                          ? 'Ketuk untuk mengganti tanggal.'
                          : 'Ketuk card ini untuk membuka kalender.',
                      style: TextStyle(
                        color:
                        Colors.grey[500],
                        fontSize: 7.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Container(
                width: 34,
                height: 34,
                decoration:
                BoxDecoration(
                  color: cardColor
                      .withValues(
                    alpha: 0.08,
                  ),
                  shape:
                  BoxShape.circle,
                ),
                child: Icon(
                  selected
                      ? Iconsax.edit_2
                      : Iconsax
                      .arrow_right_3,
                  size: 15,
                  color: cardColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STEP 2 - MULTI TECHNICIAN
  // ============================================================

  Widget _buildTechnicianStep(
      OwnerMasterProvider provider,
      ) {
    return ListView(
      key: const ValueKey(
        'technician-step',
      ),
      physics:
      const BouncingScrollPhysics(),
      padding:
      const EdgeInsets.all(
        16,
      ),
      children: [
        _buildStepIntro(
          icon:
          Iconsax.profile_2user,
          title:
          'Pilih Teknisi',
          subtitle:
          'Pilih satu atau beberapa teknisi. Unit AC akan dibagi ke masing-masing teknisi pada langkah berikutnya.',
        ),

        const SizedBox(
          height: 14,
        ),

        _buildSelectedAssignmentDateSummary(),

        const SizedBox(
          height: 14,
        ),

        // ========================================================
        // SUMMARY SELECTED TECHNICIANS
        // ========================================================

        Container(
          padding:
          const EdgeInsets.all(
            12,
          ),
          decoration:
          BoxDecoration(
            color: kPrimaryColor
                .withValues(
              alpha: 0.055,
            ),
            borderRadius:
            BorderRadius.circular(
              14,
            ),
            border: Border.all(
              color: kPrimaryColor
                  .withValues(
                alpha: 0.08,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 41,
                height: 41,
                decoration:
                BoxDecoration(
                  color: kPrimaryColor
                      .withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    11,
                  ),
                ),
                child: const Icon(
                  Iconsax
                      .profile_2user,
                  color:
                  kPrimaryColor,
                  size: 18,
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
                    const Text(
                      'Teknisi Dipilih',
                      style:
                      TextStyle(
                        color:
                        _textPrimary,
                        fontSize: 9,
                        fontWeight:
                        FontWeight
                            .w600,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      '${_selectedTechnicianIds.length} teknisi',
                      style:
                      const TextStyle(
                        color:
                        kPrimaryColor,
                        fontSize: 13,
                        fontWeight:
                        FontWeight
                            .w800,
                      ),
                    ),
                  ],
                ),
              ),

              if (_selectedTechnicianIds
                  .isNotEmpty)
                const Icon(
                  Iconsax.tick_circle,
                  color:
                  _successColor,
                  size: 20,
                ),
            ],
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        if (provider.technicians
            .isEmpty)
          _buildEmptyCard(
            icon:
            Iconsax.profile_delete,
            title:
            'Teknisi belum tersedia',
            subtitle:
            'Belum ada data teknisi yang dapat dipilih.',
          )
        else
          ...provider.technicians
              .where(
                (technician) =>
            (technician.id ??
                0) >
                0,
          )
              .map(
                (
                technician,
                ) {
              final technicianId =
              technician.id!;

              final selected =
              _selectedTechnicianIds
                  .contains(
                technicianId,
              );

              final assignedCount =
              _getAssignedCountForTechnician(
                technicianId,
              );

              return Padding(
                padding:
                const EdgeInsets
                    .only(
                  bottom: 9,
                ),
                child: Material(
                  color: Colors
                      .transparent,
                  child: InkWell(
                    borderRadius:
                    BorderRadius
                        .circular(
                      16,
                    ),
                    onTap: () {
                      _toggleTechnician(
                        technicianId,
                      );
                    },
                    child:
                    AnimatedContainer(
                      duration:
                      const Duration(
                        milliseconds:
                        170,
                      ),
                      padding:
                      const EdgeInsets
                          .all(
                        13,
                      ),
                      decoration:
                      BoxDecoration(
                        color: selected
                            ? kPrimaryColor
                            .withValues(
                          alpha:
                          0.055,
                        )
                            : Colors.white,
                        borderRadius:
                        BorderRadius
                            .circular(
                          16,
                        ),
                        border:
                        Border.all(
                          color: selected
                              ? kPrimaryColor
                              .withValues(
                            alpha:
                            0.35,
                          )
                              : Colors
                              .black
                              .withValues(
                            alpha:
                            0.025,
                          ),
                          width: selected
                              ? 1.3
                              : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors
                                .black
                                .withValues(
                              alpha:
                              0.025,
                            ),
                            blurRadius:
                            10,
                            offset:
                            const Offset(
                              0,
                              3,
                            ),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration:
                            BoxDecoration(
                              color: selected
                                  ? kPrimaryColor
                                  .withValues(
                                alpha:
                                0.11,
                              )
                                  : const Color(
                                0xFFF5F6FA,
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                14,
                              ),
                            ),
                            child: Icon(
                              Iconsax.user,
                              color: selected
                                  ? kPrimaryColor
                                  : Colors
                                  .grey[500],
                              size: 21,
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
                                  technician
                                      .name ??
                                      'Teknisi',
                                  style:
                                  const TextStyle(
                                    color:
                                    _textPrimary,
                                    fontSize:
                                    12,
                                    fontWeight:
                                    FontWeight
                                        .w700,
                                  ),
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Text(
                                  assignedCount >
                                      0
                                      ? '$assignedCount AC dialokasikan'
                                      : selected
                                      ? 'Teknisi siap menerima unit AC'
                                      : 'Ketuk untuk memilih teknisi',
                                  style:
                                  TextStyle(
                                    fontSize:
                                    8,
                                    color: assignedCount >
                                        0
                                        ? _successColor
                                        : selected
                                        ? kPrimaryColor
                                        : Colors.grey[
                                    500],
                                    fontWeight:
                                    FontWeight
                                        .w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(
                            width: 8,
                          ),

                          AnimatedContainer(
                            duration:
                            const Duration(
                              milliseconds:
                              170,
                            ),
                            width: 30,
                            height: 30,
                            decoration:
                            BoxDecoration(
                              color: selected
                                  ? kPrimaryColor
                                  : const Color(
                                0xFFF3F4F7,
                              ),
                              shape:
                              BoxShape
                                  .circle,
                            ),
                            child: Icon(
                              selected
                                  ? Iconsax.link
                                  : Iconsax.add,
                              color: selected
                                  ? Colors.white
                                  : Colors
                                  .grey[500],
                              size: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

        if (_selectedTechnicianIds
            .length >
            1) ...[
          const SizedBox(
            height: 4,
          ),

          Container(
            padding:
            const EdgeInsets.all(
              11,
            ),
            decoration:
            BoxDecoration(
              color: _successColor
                  .withValues(
                alpha: 0.055,
              ),
              borderRadius:
              BorderRadius
                  .circular(
                12,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Iconsax.info_circle,
                  color:
                  _successColor,
                  size: 15,
                ),

                const SizedBox(
                  width: 7,
                ),

                Expanded(
                  child: Text(
                    '${_selectedTechnicianIds.length} teknisi dipilih. Unit AC dapat dibagi berbeda untuk setiap teknisi.',
                    style:
                    const TextStyle(
                      color:
                      _successColor,
                      fontSize: 8,
                      height: 1.4,
                      fontWeight:
                      FontWeight
                          .w500,
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

  Widget _buildSelectedAssignmentDateSummary() {
    if (_tanggalDitugaskan ==
        null) {
      return const SizedBox
          .shrink();
    }

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration:
      BoxDecoration(
        color: _successColor
            .withValues(
          alpha: 0.055,
        ),
        borderRadius:
        BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: _successColor
              .withValues(
            alpha: 0.10,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Iconsax.calendar_tick,
            size: 15,
            color: _successColor,
          ),

          const SizedBox(
            width: 7,
          ),

          Expanded(
            child: Text(
              'Tanggal penugasan: ${DateFormat('dd MMMM yyyy', 'id_ID').format(_tanggalDitugaskan!)}',
              style:
              const TextStyle(
                color:
                _successColor,
                fontSize: 8.5,
                fontWeight:
                FontWeight
                    .w600,
              ),
            ),
          ),

          InkWell(
            onTap: () {
              setState(() {
                _currentStep = 0;
              });
            },
            child: const Text(
              'Ubah',
              style: TextStyle(
                color:
                kPrimaryColor,
                fontSize: 8,
                fontWeight:
                FontWeight
                    .w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 3 - AC DISTRIBUTION
  // ============================================================

  Widget _buildAcStep(
      OwnerMasterProvider provider,
      List<Map<String, dynamic>>
      acList,
      ) {
    final floorOptions =
    _extractFloorOptions(
      acList,
    );

    final filtered =
    _selectedFloorNumber ==
        null
        ? acList
        : acList
        .where(
          (ac) =>
      _getFloorNumberFromAc(
        ac,
      ) ==
          _selectedFloorNumber,
    )
        .toList();

    final activeTechnicianName =
    _activeTechnicianId ==
        null
        ? 'Belum dipilih'
        : _techNameById(
      provider,
      _activeTechnicianId!,
    );

    final assignedCount =
    _getTotalAssignedCount();

    final unassignedCount =
        acList.length -
            assignedCount;

    return ListView(
      key: const ValueKey(
        'ac-step',
      ),
      physics:
      const BouncingScrollPhysics(),
      padding:
      const EdgeInsets.all(
        16,
      ),
      children: [
        _buildStepIntro(
          icon: Iconsax.cpu,
          title:
          'Pembagian Unit AC',
          subtitle:
          'Pilih teknisi tujuan, lalu pilih unit AC yang akan ditangani teknisi tersebut.',
        ),

        const SizedBox(
          height: 12,
        ),

        // ========================================================
        // TECHNICIAN SELECTOR
        // ========================================================

        Container(
          width: double.infinity,
          padding:
          const EdgeInsets.all(
            14,
          ),
          decoration:
          BoxDecoration(
            gradient:
            const LinearGradient(
              begin:
              Alignment.topLeft,
              end:
              Alignment.bottomRight,
              colors: [
                Color(
                  0xFF5059C8,
                ),
                Color(
                  0xFF34449B,
                ),
              ],
            ),
            borderRadius:
            BorderRadius.circular(
              17,
            ),
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              Row(
                children: [
                  Container(
                    width: 41,
                    height: 41,
                    decoration:
                    BoxDecoration(
                      color: Colors.white
                          .withValues(
                        alpha: 0.14,
                      ),
                      borderRadius:
                      BorderRadius
                          .circular(
                        12,
                      ),
                    ),
                    child: const Icon(
                      Iconsax
                          .profile_2user,
                      color:
                      Colors.white,
                      size: 18,
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
                          'Pembagian Unit AC',
                          style: TextStyle(
                            color: Colors
                                .white
                                .withValues(
                              alpha:
                              0.75,
                            ),
                            fontSize: 8,
                          ),
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        const Text(
                          'Pilih teknisi tujuan',
                          style:
                          TextStyle(
                            color:
                            Colors.white,
                            fontSize:
                            12,
                            fontWeight:
                            FontWeight
                                .w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  InkWell(
                    onTap: () {
                      setState(() {
                        _currentStep = 1;
                      });
                    },
                    child: Container(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal:
                        8,
                        vertical:
                        5,
                      ),
                      decoration:
                      BoxDecoration(
                        color: Colors.white
                            .withValues(
                          alpha:
                          0.12,
                        ),
                        borderRadius:
                        BorderRadius
                            .circular(
                          9,
                        ),
                      ),
                      child: Text(
                        '${_selectedTechnicianIds.length} Teknisi',
                        style:
                        const TextStyle(
                          color:
                          Colors.white,
                          fontSize:
                          8,
                          fontWeight:
                          FontWeight
                              .w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 13,
              ),

              SingleChildScrollView(
                scrollDirection:
                Axis.horizontal,
                child: Row(
                  children:
                  _selectedTechnicianIds
                      .map(
                        (
                        technicianId,
                        ) {
                      final active =
                          technicianId ==
                              _activeTechnicianId;

                      final count =
                      _getAssignedCountForTechnician(
                        technicianId,
                      );

                      return Padding(
                        padding:
                        const EdgeInsets
                            .only(
                          right: 8,
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _activeTechnicianId =
                                  technicianId;

                              _selectedAcIds
                                  .clear();
                            });
                          },
                          borderRadius:
                          BorderRadius
                              .circular(
                            12,
                          ),
                          child:
                          AnimatedContainer(
                            duration:
                            const Duration(
                              milliseconds:
                              150,
                            ),
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal:
                              11,
                              vertical:
                              9,
                            ),
                            decoration:
                            BoxDecoration(
                              color: active
                                  ? Colors
                                  .white
                                  : Colors
                                  .white
                                  .withValues(
                                alpha:
                                0.10,
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                12,
                              ),
                              border:
                              Border.all(
                                color: active
                                    ? Colors
                                    .white
                                    : Colors
                                    .white
                                    .withValues(
                                  alpha:
                                  0.12,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize:
                              MainAxisSize
                                  .min,
                              children: [
                                Icon(
                                  active
                                      ? Iconsax
                                      .user_tick
                                      : Iconsax
                                      .user,
                                  size: 14,
                                  color: active
                                      ? kPrimaryColor
                                      : Colors
                                      .white,
                                ),

                                const SizedBox(
                                  width: 6,
                                ),

                                Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                                  children: [
                                    Text(
                                      _techNameById(
                                        provider,
                                        technicianId,
                                      ),
                                      style:
                                      TextStyle(
                                        color: active
                                            ? kPrimaryColor
                                            : Colors
                                            .white,
                                        fontSize:
                                        8.5,
                                        fontWeight:
                                        FontWeight
                                            .w700,
                                      ),
                                    ),

                                    Text(
                                      '$count AC',
                                      style:
                                      TextStyle(
                                        color: active
                                            ? kPrimaryColor
                                            .withValues(
                                          alpha:
                                          0.65,
                                        )
                                            : Colors
                                            .white
                                            .withValues(
                                          alpha:
                                          0.65,
                                        ),
                                        fontSize:
                                        7,
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
                  ).toList(),
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              Container(
                width:
                double.infinity,
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration:
                BoxDecoration(
                  color: Colors.white
                      .withValues(
                    alpha: 0.09,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    10,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Iconsax
                          .arrow_right,
                      size: 13,
                      color:
                      Colors.white,
                    ),

                    const SizedBox(
                      width: 6,
                    ),

                    Expanded(
                      child: Text(
                        'Unit yang dipilih akan diberikan ke $activeTechnicianName',
                        style:
                        TextStyle(
                          color: Colors
                              .white
                              .withValues(
                            alpha:
                            0.82,
                          ),
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        // ========================================================
        // COUNTERS
        // ========================================================

        Row(
          children: [
            Expanded(
              child:
              _buildMiniStatistic(
                value:
                '${acList.length}',
                label:
                'Total AC',
                icon: Iconsax.cpu,
                color:
                kPrimaryColor,
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            Expanded(
              child:
              _buildMiniStatistic(
                value:
                '$assignedCount',
                label:
                'Assigned',
                icon: Iconsax
                    .tick_circle,
                color:
                _successColor,
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            Expanded(
              child:
              _buildMiniStatistic(
                value:
                '$unassignedCount',
                label:
                'Belum',
                icon: Iconsax
                    .warning_2,
                color:
                unassignedCount >
                    0
                    ? _warningColor
                    : _successColor,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 12,
        ),

        if (floorOptions
            .isNotEmpty)
          _buildFloorFilter(
            floorOptions,
          ),

        if (floorOptions
            .isNotEmpty)
          const SizedBox(
            height: 12,
          ),

        Row(
          children: [
            Expanded(
              child: Text(
                '${filtered.length} unit ditampilkan',
                style: TextStyle(
                  color:
                  Colors.grey[600],
                  fontSize: 9,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),

            TextButton.icon(
              onPressed: () {
                _toggleSelectAll(
                  filtered,
                );
              },
              icon: const Icon(
                Iconsax.tick_square,
                size: 14,
              ),
              label: const Text(
                'Pilih Semua',
                style: TextStyle(
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),

        if (filtered.isEmpty)
          _buildEmptyCard(
            icon: Iconsax.cpu,
            title:
            'Tidak ada AC',
            subtitle:
            'Tidak ada unit pada filter lantai ini.',
          )
        else
          ...filtered.map(
                (
                ac,
                ) =>
                _buildAcItem(
                  provider,
                  ac,
                ),
          ),

        if (_selectedAcIds
            .isNotEmpty) ...[
          const SizedBox(
            height: 6,
          ),

          Container(
            width:
            double.infinity,
            padding:
            const EdgeInsets.all(
              12,
            ),
            decoration:
            BoxDecoration(
              color: kPrimaryColor
                  .withValues(
                alpha: 0.06,
              ),
              borderRadius:
              BorderRadius
                  .circular(
                14,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Text(
                        '${_selectedAcIds.length} unit dipilih',
                        style:
                        const TextStyle(
                          color:
                          kPrimaryColor,
                          fontSize: 10,
                          fontWeight:
                          FontWeight
                              .w700,
                        ),
                      ),

                      const SizedBox(
                        height: 2,
                      ),

                      Text(
                        'Tujuan: $activeTechnicianName',
                        style:
                        TextStyle(
                          color: Colors
                              .grey[600],
                          fontSize: 7.5,
                        ),
                      ),
                    ],
                  ),
                ),

                ElevatedButton(
                  onPressed:
                  _assignSelectedToTechnician,
                  style:
                  ElevatedButton
                      .styleFrom(
                    elevation: 0,
                    backgroundColor:
                    kPrimaryColor,
                    foregroundColor:
                    Colors.white,
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal:
                      13,
                      vertical: 9,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius
                          .circular(
                        10,
                      ),
                    ),
                  ),
                  child:
                  const Text(
                    'Assign',
                    style:
                    TextStyle(
                      fontSize: 9,
                      fontWeight:
                      FontWeight
                          .w700,
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

  // ============================================================
  // FLOOR FILTER
  // ============================================================

  Widget _buildFloorFilter(
      List<int> floors,
      ) {
    return Container(
      height: 48,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          13,
        ),
        border: Border.all(
          color: Colors.black
              .withValues(
            alpha: 0.025,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration:
            BoxDecoration(
              color: kPrimaryColor
                  .withValues(
                alpha: 0.07,
              ),
              borderRadius:
              BorderRadius
                  .circular(
                9,
              ),
            ),
            child: const Icon(
              Iconsax.building_4,
              color:
              kPrimaryColor,
              size: 15,
            ),
          ),

          const SizedBox(
            width: 9,
          ),

          Expanded(
            child:
            DropdownButtonHideUnderline(
              child:
              DropdownButton<int?>(
                value:
                _selectedFloorNumber,
                isExpanded: true,
                hint: const Text(
                  'Semua lantai',
                ),
                icon: const Icon(
                  Iconsax
                      .arrow_down_1,
                  size: 16,
                  color:
                  kPrimaryColor,
                ),
                style:
                const TextStyle(
                  color:
                  _textPrimary,
                  fontSize: 10,
                  fontWeight:
                  FontWeight
                      .w600,
                ),
                items: [
                  const DropdownMenuItem<
                      int?>(
                    value: null,
                    child: Text(
                      'Semua lantai',
                    ),
                  ),
                  ...floors.map(
                        (
                        floor,
                        ) =>
                        DropdownMenuItem<
                            int?>(
                          value: floor,
                          child: Text(
                            'Lantai $floor',
                          ),
                        ),
                  ),
                ],
                onChanged: (
                    value,
                    ) {
                  setState(() {
                    _selectedFloorNumber =
                        value;

                    _selectedAcIds
                        .clear();
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AC ITEM
  // ============================================================

  Widget _buildAcItem(
      OwnerMasterProvider provider,
      Map<String, dynamic> ac,
      ) {
    final acId = int.tryParse(
      (ac['id'] ?? '').toString(),
    ) ??
        0;

    final name = (ac['name'] ?? 'AC')
        .toString()
        .trim();

    final brand = (ac['brand'] ?? '')
        .toString()
        .trim();

    final type = (ac['type'] ?? '')
        .toString()
        .trim();

    final capacity =
    (ac['capacity'] ?? '')
        .toString()
        .trim();

    final roomName =
    _getRoomNameFromAc(
      ac,
    );

    final floorLabel =
    _getFloorLabelFromAc(
      ac,
    );

    final selected =
    _selectedAcIds.contains(
      acId,
    );

    final assignedTechId =
    _assignedTechIdOfAc(
      acId,
    );

    final assigned =
        assignedTechId != null;

    final sameTechnician =
        assignedTechId ==
            _activeTechnicianId;

    final technicalInfo = [
      brand,
      type,
      capacity,
    ].where(
          (item) =>
      item.isNotEmpty,
    ).join(
      ' • ',
    );

    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 9,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
          BorderRadius.circular(
            15,
          ),
          onTap: () async {
            if (_activeTechnicianId ==
                null) {
              _showMessage(
                'Pilih teknisi tujuan terlebih dahulu.',
                color:
                _warningColor,
                icon: Iconsax
                    .profile_2user,
              );

              return;
            }

            if (assigned) {
              await _handleLockedAcTap(
                provider,
                acId: acId,
                fromTechId:
                assignedTechId,
              );

              return;
            }

            setState(() {
              if (selected) {
                _selectedAcIds
                    .remove(
                  acId,
                );
              } else {
                _selectedAcIds
                    .add(
                  acId,
                );
              }
            });
          },
          child:
          AnimatedContainer(
            duration:
            const Duration(
              milliseconds: 160,
            ),
            padding:
            const EdgeInsets.all(
              12,
            ),
            decoration:
            BoxDecoration(
              color: selected
                  ? kPrimaryColor
                  .withValues(
                alpha:
                0.055,
              )
                  : Colors.white,
              borderRadius:
              BorderRadius
                  .circular(
                15,
              ),
              border:
              Border.all(
                color: selected
                    ? kPrimaryColor
                    .withValues(
                  alpha:
                  0.30,
                )
                    : assigned
                    ? _successColor
                    .withValues(
                  alpha:
                  0.18,
                )
                    : Colors
                    .black
                    .withValues(
                  alpha:
                  0.025,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(
                    alpha:
                    0.022,
                  ),
                  blurRadius: 9,
                  offset:
                  const Offset(
                    0,
                    3,
                  ),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration:
                  BoxDecoration(
                    color: assigned
                        ? _successColor
                        .withValues(
                      alpha:
                      0.08,
                    )
                        : kPrimaryColor
                        .withValues(
                      alpha:
                      0.07,
                    ),
                    borderRadius:
                    BorderRadius
                        .circular(
                      12,
                    ),
                  ),
                  child: Icon(
                    assigned
                        ? Iconsax
                        .tick_circle
                        : Iconsax.cpu,
                    color: assigned
                        ? _successColor
                        : kPrimaryColor,
                    size: 18,
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
                      // ==========================================================
// ROOM NAME -> JUDUL UTAMA
// ==========================================================

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              roomName.isNotEmpty
                                  ? roomName
                                  : name.isNotEmpty
                                  ? name
                                  : 'AC #$acId',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          if (floorLabel != '-')
                            _buildTinyBadge(
                              floorLabel,
                              const Color(
                                0xFF7950C8,
                              ),
                            ),
                        ],
                      ),

// ==========================================================
// AC NAME -> SUBTITLE
// ==========================================================

                      if (name.isNotEmpty) ...[
                        const SizedBox(
                          height: 3,
                        ),

                        Row(
                          children: [
                            Icon(
                              Iconsax.cpu,
                              size: 10,
                              color: Colors.grey[500],
                            ),

                            const SizedBox(
                              width: 4,
                            ),

                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 8,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (technicalInfo
                          .isNotEmpty) ...[
                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          technicalInfo,
                          maxLines: 2,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          TextStyle(
                            fontSize: 8,
                            height: 1.35,
                            color: Colors
                                .grey[500],
                          ),
                        ),
                      ],

                      if (assigned) ...[
                        const SizedBox(
                          height: 6,
                        ),

                        Row(
                          children: [
                            const Icon(
                              Iconsax
                                  .user_tick,
                              size: 11,
                              color:
                              _successColor,
                            ),

                            const SizedBox(
                              width: 4,
                            ),

                            Expanded(
                              child: Text(
                                sameTechnician
                                    ? 'Sudah di ${_techNameById(provider, assignedTechId)}'
                                    : 'Ditugaskan ke ${_techNameById(provider, assignedTechId)} • ketuk untuk pindahkan',
                                style:
                                const TextStyle(
                                  color:
                                  _successColor,
                                  fontSize:
                                  8,
                                  fontWeight:
                                  FontWeight
                                      .w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(
                  width: 7,
                ),

                Container(
                  width: 29,
                  height: 29,
                  decoration:
                  BoxDecoration(
                    color: selected
                        ? kPrimaryColor
                        : assigned
                        ? _successColor
                        .withValues(
                      alpha:
                      0.09,
                    )
                        : const Color(
                      0xFFF4F5F8,
                    ),
                    shape:
                    BoxShape.circle,
                  ),
                  child: Icon(
                    selected
                        ? Iconsax
                        .tick_circle
                        : assigned
                        ? sameTechnician
                        ? Iconsax
                        .tick_circle
                        : Iconsax
                        .refresh
                        : Iconsax
                        .add_circle,
                    color: selected
                        ? Colors.white
                        : assigned
                        ? _successColor
                        : Colors
                        .grey[500],
                    size: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STEP 4 - REVIEW
  // ============================================================

  Widget _buildReviewStep(
      OwnerMasterProvider provider,
      List<Map<String, dynamic>>
      acList,
      ) {
    final acNameById =
    <int, String>{};

    final acRoomById =
    <int, String>{};

    final acFloorById =
    <int, String>{};

    for (final ac in acList) {
      final id = int.tryParse(
        (ac['id'] ?? '').toString(),
      ) ??
          0;

      if (id <= 0) {
        continue;
      }

      acNameById[id] =
          (ac['name'] ??
              'AC #$id')
              .toString();

      acRoomById[id] =
          _getRoomNameFromAc(
            ac,
          );

      acFloorById[id] =
          _getFloorLabelFromAc(
            ac,
          );
    }

    final totalAssigned =
    _getTotalAssignedCount();

    final unassigned =
        acList.length -
            totalAssigned;

    return ListView(
      key: const ValueKey(
        'review-step',
      ),
      physics:
      const BouncingScrollPhysics(),
      padding:
      const EdgeInsets.all(
        16,
      ),
      children: [
        _buildStepIntro(
          icon:
          Iconsax.tick_circle,
          title:
          'Review Penugasan',
          subtitle:
          'Periksa kembali pembagian AC untuk setiap teknisi sebelum menyimpan.',
        ),

        const SizedBox(
          height: 14,
        ),

        _buildReviewAssignmentDate(),

        const SizedBox(
          height: 13,
        ),

        Row(
          children: [
            Expanded(
              child:
              _buildMiniStatistic(
                value:
                '${_groups.length}',
                label:
                'Teknisi',
                icon: Iconsax
                    .profile_2user,
                color:
                kPrimaryColor,
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            Expanded(
              child:
              _buildMiniStatistic(
                value:
                '$totalAssigned',
                label:
                'Assigned',
                icon: Iconsax
                    .tick_circle,
                color:
                _successColor,
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            Expanded(
              child:
              _buildMiniStatistic(
                value:
                '$unassigned',
                label:
                'Belum',
                icon: Iconsax
                    .warning_2,
                color:
                unassigned > 0
                    ? _warningColor
                    : _successColor,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 13,
        ),

        if (unassigned > 0)
          Container(
            margin:
            const EdgeInsets.only(
              bottom: 12,
            ),
            padding:
            const EdgeInsets.all(
              12,
            ),
            decoration:
            BoxDecoration(
              color: _warningColor
                  .withValues(
                alpha: 0.055,
              ),
              borderRadius:
              BorderRadius
                  .circular(
                13,
              ),
              border: Border.all(
                color: _warningColor
                    .withValues(
                  alpha: 0.13,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Iconsax.warning_2,
                  color:
                  _warningColor,
                  size: 18,
                ),

                const SizedBox(
                  width: 9,
                ),

                Expanded(
                  child: Text(
                    '$unassigned unit AC belum memiliki teknisi.',
                    style:
                    const TextStyle(
                      color:
                      _warningColor,
                      fontSize: 8.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

        ..._groups.entries.map(
              (
              entry,
              ) {
            final technicianId =
                entry.key;

            final acIds =
            entry.value
                .toList();

            acIds.sort();

            return Container(
              margin:
              const EdgeInsets.only(
                bottom: 10,
              ),
              decoration:
              BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius
                    .circular(
                  16,
                ),
                border: Border.all(
                  color: Colors.black
                      .withValues(
                    alpha: 0.025,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors
                        .black
                        .withValues(
                      alpha: 0.025,
                    ),
                    blurRadius: 10,
                    offset:
                    const Offset(
                      0,
                      3,
                    ),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding:
                    const EdgeInsets
                        .all(
                      13,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration:
                          BoxDecoration(
                            color: kPrimaryColor
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
                          child:
                          const Icon(
                            Iconsax
                                .user_tick,
                            size: 18,
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
                                _techNameById(
                                  provider,
                                  technicianId,
                                ),
                                style:
                                const TextStyle(
                                  color:
                                  _textPrimary,
                                  fontSize:
                                  11.5,
                                  fontWeight:
                                  FontWeight
                                      .w700,
                                ),
                              ),

                              const SizedBox(
                                height: 3,
                              ),

                              Text(
                                '${acIds.length} unit AC',
                                style:
                                TextStyle(
                                  color: Colors
                                      .grey[500],
                                  fontSize:
                                  8,
                                ),
                              ),
                            ],
                          ),
                        ),

                        InkWell(
                          onTap: () {
                            setState(() {
                              _activeTechnicianId =
                                  technicianId;

                              _selectedTechnicianIds
                                  .add(
                                technicianId,
                              );

                              _selectedAcIds
                                  .clear();

                              _currentStep =
                              2;
                            });
                          },
                          child:
                          Container(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal:
                              9,
                              vertical:
                              6,
                            ),
                            decoration:
                            BoxDecoration(
                              color: kPrimaryColor
                                  .withValues(
                                alpha:
                                0.065,
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                9,
                              ),
                            ),
                            child:
                            const Text(
                              'Edit',
                              style:
                              TextStyle(
                                color:
                                kPrimaryColor,
                                fontSize:
                                8,
                                fontWeight:
                                FontWeight
                                    .w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width:
                    double.infinity,
                    height: 1,
                    color:
                    const Color(
                      0xFFF1F2F5,
                    ),
                  ),

                  ...acIds.map(
                        (
                        acId,
                        ) {
                      final room =
                          acRoomById[
                          acId] ??
                              '';

                      final floor =
                          acFloorById[
                          acId] ??
                              '-';

                      return Padding(
                        padding:
                        const EdgeInsets
                            .fromLTRB(
                          13,
                          10,
                          13,
                          10,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 31,
                              height: 31,
                              decoration:
                              BoxDecoration(
                                color:
                                const Color(
                                  0xFFF5F6FA,
                                ),
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  9,
                                ),
                              ),
                              child:
                              const Icon(
                                Iconsax.cpu,
                                size: 14,
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
                                    acNameById[
                                    acId] ??
                                        'AC #$acId',
                                    style:
                                    const TextStyle(
                                      color:
                                      _textPrimary,
                                      fontSize:
                                      9.5,
                                      fontWeight:
                                      FontWeight
                                          .w600,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 2,
                                  ),

                                  Text(
                                    [
                                      if (room
                                          .isNotEmpty)
                                        room,
                                      if (floor !=
                                          '-')
                                        floor,
                                    ].join(
                                      ' • ',
                                    ),
                                    style:
                                    TextStyle(
                                      color: Colors
                                          .grey[500],
                                      fontSize:
                                      7.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            IconButton(
                              onPressed: () {
                                _removeAcFromGroup(
                                  technicianId,
                                  acId,
                                );
                              },
                              visualDensity:
                              VisualDensity
                                  .compact,
                              icon:
                              const Icon(
                                Iconsax
                                    .close_circle,
                                size: 16,
                                color:
                                Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // REVIEW DATE
  // ============================================================

  Widget _buildReviewAssignmentDate() {
    final selected =
        _tanggalDitugaskan != null;

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(
        13,
      ),
      decoration:
      BoxDecoration(
        color: selected
            ? _successColor
            .withValues(
          alpha: 0.055,
        )
            : _dangerColor
            .withValues(
          alpha: 0.055,
        ),
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: (selected
              ? _successColor
              : _dangerColor)
              .withValues(
            alpha: 0.15,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
            BoxDecoration(
              color: (selected
                  ? _successColor
                  : _dangerColor)
                  .withValues(
                alpha: 0.09,
              ),
              borderRadius:
              BorderRadius
                  .circular(
                12,
              ),
            ),
            child: Icon(
              selected
                  ? Iconsax
                  .calendar_tick
                  : Iconsax
                  .calendar_remove,
              color: selected
                  ? _successColor
                  : _dangerColor,
              size: 18,
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
                  'Tanggal Penugasan',
                  style: TextStyle(
                    color:
                    Colors.grey[600],
                    fontSize: 7.5,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  selected
                      ? DateFormat(
                    'EEEE, dd MMMM yyyy',
                    'id_ID',
                  ).format(
                    _tanggalDitugaskan!,
                  )
                      : 'Belum dipilih',
                  style: TextStyle(
                    color: selected
                        ? _successColor
                        : _dangerColor,
                    fontSize: 10.5,
                    fontWeight:
                    FontWeight
                        .w700,
                  ),
                ),
              ],
            ),
          ),

          TextButton(
            onPressed: () {
              setState(() {
                _currentStep = 0;
              });
            },
            child: const Text(
              'Ubah',
              style: TextStyle(
                fontSize: 8.5,
                fontWeight:
                FontWeight
                    .w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM NAV
  // ============================================================

  Widget _buildBottomNavigation(
      OwnerMasterProvider provider,
      ) {
    final isLast =
        _currentStep ==
            _steps.length - 1;

    final canContinueFromDetail =
        _currentStep != 0 ||
            _tanggalDitugaskan !=
                null;

    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        16,
        11,
        16,
        12,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.black
                .withValues(
              alpha: 0.035,
            ),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(
              alpha: 0.035,
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
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            if (_currentStep == 0 &&
                _tanggalDitugaskan ==
                    null) ...[
              Row(
                children: [
                  const Icon(
                    Iconsax.warning_2,
                    size: 13,
                    color:
                    _warningColor,
                  ),

                  const SizedBox(
                    width: 6,
                  ),

                  Expanded(
                    child: Text(
                      'Pilih tanggal penugasan untuk melanjutkan.',
                      style: TextStyle(
                        color: Colors
                            .grey[600],
                        fontSize: 8,
                        fontWeight:
                        FontWeight
                            .w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 8,
              ),
            ],

            Row(
              children: [
                if (_currentStep >
                    0) ...[
                  SizedBox(
                    width: 48,
                    height: 46,
                    child:
                    OutlinedButton(
                      onPressed:
                      _previousStep,
                      style:
                      OutlinedButton
                          .styleFrom(
                        padding:
                        EdgeInsets
                            .zero,
                        foregroundColor:
                        kPrimaryColor,
                        side:
                        BorderSide(
                          color: kPrimaryColor
                              .withValues(
                            alpha:
                            0.25,
                          ),
                        ),
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            13,
                          ),
                        ),
                      ),
                      child:
                      const Icon(
                        Iconsax
                            .arrow_left_2,
                        size: 18,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 9,
                  ),
                ],

                Expanded(
                  child: SizedBox(
                    height: 46,
                    child:
                    ElevatedButton(
                      onPressed: provider
                          .submitting
                          ? null
                          : !canContinueFromDetail
                          ? null
                          : isLast
                          ? _submit
                          : _nextStep,
                      style:
                      ElevatedButton
                          .styleFrom(
                        elevation: 0,
                        disabledBackgroundColor:
                        Colors
                            .grey[300],
                        disabledForegroundColor:
                        Colors
                            .grey[500],
                        backgroundColor:
                        isLast
                            ? _successColor
                            : kPrimaryColor,
                        foregroundColor:
                        Colors.white,
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            13,
                          ),
                        ),
                      ),
                      child: provider
                          .submitting
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                        CircularProgressIndicator(
                          strokeWidth:
                          2,
                          color: Colors
                              .white,
                        ),
                      )
                          : Row(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                        children: [
                          Icon(
                            isLast
                                ? Iconsax
                                .tick_circle
                                : Iconsax
                                .arrow_right_3,
                            size: 16,
                          ),

                          const SizedBox(
                            width: 7,
                          ),

                          Text(
                            isLast
                                ? widget
                                .isReassign
                                ? 'Simpan Perubahan'
                                : 'Simpan Penugasan'
                                : _currentStep ==
                                2
                                ? 'Review Penugasan'
                                : _currentStep ==
                                1
                                ? 'Atur Unit AC'
                                : 'Lanjutkan',
                            style:
                            const TextStyle(
                              fontSize:
                              10.5,
                              fontWeight:
                              FontWeight
                                  .w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SHARED UI
  // ============================================================

  Widget _buildStepIntro({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration:
          BoxDecoration(
            color: kPrimaryColor
                .withValues(
              alpha: 0.08,
            ),
            borderRadius:
            BorderRadius.circular(
              13,
            ),
          ),
          child: Icon(
            icon,
            color: kPrimaryColor,
            size: 19,
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
                title,
                style:
                const TextStyle(
                  color:
                  _textPrimary,
                  fontSize: 15,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                subtitle,
                style: TextStyle(
                  color:
                  Colors.grey[600],
                  fontSize: 9,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWhiteCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(
        14,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: Colors.black
              .withValues(
            alpha: 0.025,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(
              alpha: 0.025,
            ),
            blurRadius: 12,
            offset:
            const Offset(
              0,
              4,
            ),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration:
          BoxDecoration(
            color: color.withValues(
              alpha: 0.075,
            ),
            borderRadius:
            BorderRadius.circular(
              10,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
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
                style: TextStyle(
                  color:
                  Colors.grey[500],
                  fontSize: 7.5,
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                value,
                style:
                const TextStyle(
                  color:
                  _textPrimary,
                  fontSize: 10,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding:
      const EdgeInsets
          .symmetric(
        vertical: 11,
      ),
      child: Container(
        height: 1,
        color:
        const Color(
          0xFFF1F2F5,
        ),
      ),
    );
  }

  Widget _buildScheduleBox({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding:
      const EdgeInsets.all(
        11,
      ),
      decoration:
      BoxDecoration(
        color:
        const Color(
          0xFFF7F8FB,
        ),
        borderRadius:
        BorderRadius.circular(
          12,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration:
            BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius
                  .circular(
                9,
              ),
            ),
            child: Icon(
              icon,
              color:
              Colors.grey[500],
              size: 14,
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 7,
                    color: Colors
                        .grey[500],
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
                  style: TextStyle(
                    fontSize: 9,
                    color: valueColor ??
                        _textPrimary,
                    fontWeight:
                    FontWeight
                        .w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatistic({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 10,
      ),
      decoration:
      BoxDecoration(
        color: color.withValues(
          alpha: 0.06,
        ),
        borderRadius:
        BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: color.withValues(
            alpha: 0.09,
          ),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 15,
            color: color,
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight:
              FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 1,
          ),

          Text(
            label,
            style: TextStyle(
              color:
              Colors.grey[600],
              fontSize: 7.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTinyBadge(
      String label,
      Color color,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration:
      BoxDecoration(
        color: color.withValues(
          alpha: 0.07,
        ),
        borderRadius:
        BorderRadius.circular(
          8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 7,
          color: color,
          fontWeight:
          FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 25,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration:
            BoxDecoration(
              color: kPrimaryColor
                  .withValues(
                alpha: 0.065,
              ),
              shape:
              BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: kPrimaryColor
                  .withValues(
                alpha: 0.55,
              ),
              size: 22,
            ),
          ),

          const SizedBox(
            height: 11,
          ),

          Text(
            title,
            style:
            const TextStyle(
              color:
              _textPrimary,
              fontSize: 11,
              fontWeight:
              FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            subtitle,
            textAlign:
            TextAlign.center,
            style: TextStyle(
              color:
              Colors.grey[500],
              fontSize: 8.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
      String message, {
        required Color color,
        required IconData icon,
      }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                icon,
                color:
                Colors.white,
                size: 18,
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child: Text(
                  message,
                ),
              ),
            ],
          ),
          backgroundColor:
          color,
          behavior:
          SnackBarBehavior
              .floating,
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
}

// ============================================================
// STEP MODEL
// ============================================================

class _AssignmentStep {
  final String title;
  final String subtitle;
  final IconData icon;

  const _AssignmentStep({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}