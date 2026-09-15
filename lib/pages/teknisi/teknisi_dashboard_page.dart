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
  State<TeknisiDashboardPage> createState() =>
      _TeknisiDashboardPageState();
}

class _TeknisiDashboardPageState
    extends State<TeknisiDashboardPage> {
  String _selectedStatus = 'Semua';
  String _selectedJenis = 'Semua';
  String _searchQuery = '';

  final TextEditingController _searchController =
  TextEditingController();

  Timer? _searchDebounce;

  final List<Map<String, dynamic>> _statusChips = [
    {
      'value': 'Semua',
      'display': 'Semua',
      'color': kPrimaryColor,
    },
    {
      'value': 'ditugaskan',
      'display': 'Ditugaskan',
      'color': Colors.blue,
    },
    {
      'value': 'dikerjakan',
      'display': 'Dikerjakan',
      'color': Colors.purple,
    },
    {
      'value': 'selesai',
      'display': 'Selesai',
      'color': Colors.green,
    },
  ];

  final List<Map<String, String>> _jenisList = const [
    {
      'value': 'Semua',
      'display': 'Semua Jenis',
    },
    {
      'value': 'cuci',
      'display': 'Cuci',
    },
    {
      'value': 'perbaikan',
      'display': 'Perbaikan',
    },
    {
      'value': 'instalasi',
      'display': 'Instalasi',
    },
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

  // ============================================================
  // FILTERING
  // ============================================================

  String _statusKey(ServisModel s) {
    final items = s.itemsData;

    if (items.isEmpty) {
      return s.status.name.toLowerCase();
    }

    final statuses = items
        .map(
          (it) =>
          (it['status'] ?? '')
              .toString()
              .toLowerCase()
              .trim(),
    )
        .where((x) => x.isNotEmpty)
        .toList();

    if (statuses.isEmpty) {
      return s.status.name.toLowerCase();
    }

    final allSelesai =
    statuses.every((x) => x == 'selesai');

    if (allSelesai) {
      return 'selesai';
    }

    final anyDitugaskan =
    statuses.any((x) => x == 'ditugaskan');

    if (anyDitugaskan) {
      return 'ditugaskan';
    }

    return 'dikerjakan';
  }

  String _jenisKey(ServisModel s) {
    return s.jenis.name;
  }

  bool _matchStatus(ServisModel s) {
    if (_selectedStatus == 'Semua') {
      return true;
    }

    return _statusKey(s) == _selectedStatus;
  }

  bool _matchJenis(ServisModel s) {
    if (_selectedJenis == 'Semua') {
      return true;
    }

    return _jenisKey(s) == _selectedJenis;
  }

  bool _matchSearch(ServisModel s) {
    if (_searchQuery.trim().isEmpty) {
      return true;
    }

    final q = _searchQuery.toLowerCase();

    final id = s.id.toString();

    final lokasiNama =
    s.lokasiNama.toLowerCase();

    final lokasiAlamat =
    (s.lokasiData?['address'] ?? '')
        .toString()
        .toLowerCase();

    final acText = s.itemsData
        .map(
          (it) =>
          (it['ac_unit']?['name'] ?? '')
              .toString()
              .toLowerCase(),
    )
        .join(' ');

    final tindakanText =
    (s.tindakanSummary ?? '')
        .toLowerCase();

    return id.contains(q) ||
        lokasiNama.contains(q) ||
        lokasiAlamat.contains(q) ||
        acText.contains(q) ||
        tindakanText.contains(q);
  }

  List<ServisModel> _filtered(
      List<ServisModel> all,
      ) {
    final rows = all
        .where(_matchStatus)
        .where(_matchJenis)
        .where(_matchSearch)
        .toList();

    rows.sort((a, b) {
      final aKey =
          a.tanggalSelesai ??
              a.tanggalDitugaskan ??
              DateTime(2000);

      final bKey =
          b.tanggalSelesai ??
              b.tanggalDitugaskan ??
              DateTime(2000);

      return bKey.compareTo(aKey);
    });

    return rows;
  }

  Future<void> _refresh() async {
    await context
        .read<TeknisiProvider>()
        .fetchTasks();
  }

  // ============================================================
  // UI HELPERS
  // ============================================================

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
    if (dt == null) {
      return '-';
    }

    return DateFormat(
      'dd MMM y • HH:mm',
      'id_ID',
    ).format(dt);
  }

  Future<void> _confirmLogout(
      BuildContext context,
      ) async {
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
        await context
            .read<AuthProvider>()
            .logout();

        if (!context.mounted) {
          return;
        }

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
              (route) => false,
        );
      },
    ).show();
  }

  // ============================================================
  // HEADER
  // ============================================================

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
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kPrimaryColor,
            const Color(0xFF5D6BC0),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(
              alpha: 0.25,
            ),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
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
                      nama,
                      style:
                      whiteTextStyle.copyWith(
                        fontSize: 20,
                        fontWeight: bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style:
                      whiteTextStyle.copyWith(
                        fontSize: 12,
                        color: Colors.white
                            .withValues(
                          alpha: 0.85,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () =>
                      _confirmLogout(context),
                  borderRadius:
                  BorderRadius.circular(12),
                  child: Container(
                    padding:
                    const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withValues(
                        alpha: 0.16,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: const Icon(
                      Iconsax.logout_1,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildHeaderStat(
                  icon:
                  Iconsax.task_square,
                  value: '$ditugaskan',
                  label: 'Ditugaskan',
                  statusValue:
                  'ditugaskan',
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _buildHeaderStat(
                  icon:
                  Iconsax.timer_start,
                  value: '$dikerjakan',
                  label: 'Dikerjakan',
                  statusValue:
                  'dikerjakan',
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _buildHeaderStat(
                  icon:
                  Iconsax.tick_circle,
                  value: '$selesai',
                  label: 'Selesai',
                  statusValue: 'selesai',
                ),
              ),
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
    required String statusValue,
  }) {
    final isActive =
        _selectedStatus == statusValue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
        BorderRadius.circular(14),
        onTap: () {
          setState(() {
            if (_selectedStatus ==
                statusValue) {
              _selectedStatus = 'Semua';
            } else {
              _selectedStatus =
                  statusValue;
            }
          });
        },
        child: AnimatedContainer(
          duration:
          const Duration(
            milliseconds: 180,
          ),
          padding:
          const EdgeInsets.symmetric(
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withValues(
              alpha: 0.24,
            )
                : Colors.white.withValues(
              alpha: 0.12,
            ),
            borderRadius:
            BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? Colors.white.withValues(
                alpha: 0.45,
              )
                  : Colors.white.withValues(
                alpha: 0.10,
              ),
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 16,
                  ),

                  const SizedBox(width: 6),

                  Text(
                    value,
                    style:
                    whiteTextStyle.copyWith(
                      fontSize: 18,
                      fontWeight: bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Text(
                label,
                style:
                whiteTextStyle.copyWith(
                  fontSize: 10,
                  fontWeight:
                  isActive
                      ? bold
                      : medium,
                  color: Colors.white
                      .withValues(
                    alpha: 0.90,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        10,
      ),
      child: Container(
        height: 54,
        padding:
        const EdgeInsets.symmetric(
          horizontal: 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey
                .withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: 0.05),
              blurRadius: 14,
              offset:
              const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: kPrimaryColor
                    .withValues(
                  alpha: 0.08,
                ),
                borderRadius:
                BorderRadius.circular(
                  10,
                ),
              ),
              child: const Icon(
                Iconsax.search_normal_1,
                color: kPrimaryColor,
                size: 18,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: TextField(
                controller:
                _searchController,

                onChanged: (v) {
                  // rebuild langsung supaya tombol
                  // clear segera tampil
                  setState(() {});

                  _searchDebounce
                      ?.cancel();

                  _searchDebounce =
                      Timer(
                        const Duration(
                          milliseconds: 350,
                        ),
                            () {
                          if (!mounted) {
                            return;
                          }

                          setState(() {
                            _searchQuery = v;
                          });
                        },
                      );
                },

                decoration:
                InputDecoration(
                  hintText:
                  'Cari lokasi, AC, tindakan...',
                  hintStyle:
                  greyTextStyle.copyWith(
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),

            if (_searchController
                .text
                .isNotEmpty)
              InkWell(
                onTap: () {
                  _searchDebounce
                      ?.cancel();

                  _searchController
                      .clear();

                  setState(() {
                    _searchQuery = '';
                  });
                },
                borderRadius:
                BorderRadius.circular(
                  20,
                ),
                child: const Padding(
                  padding:
                  EdgeInsets.all(6),
                  child: Icon(
                    Iconsax.close_circle,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATUS FILTER
  // ============================================================

  Widget _buildStatusChips() {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection:
        Axis.horizontal,
        padding:
        const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 7,
        ),
        children:
        _statusChips.map((chip) {
          final isSelected =
              _selectedStatus ==
                  chip['value'];

          final color =
          chip['color'] as Color;

          return Padding(
            padding:
            const EdgeInsets.only(
              right: 8,
            ),
            child: ChoiceChip(
              label: Text(
                chip['display']
                as String,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                  FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : color,
                ),
              ),
              selected:
              isSelected,
              selectedColor:
              color,
              backgroundColor:
              color.withValues(
                alpha: 0.07,
              ),
              avatar:
              isSelected
                  ? const Icon(
                Iconsax
                    .tick_circle,
                size: 15,
                color:
                Colors.white,
              )
                  : null,
              onSelected: (_) {
                setState(() {
                  _selectedStatus =
                  chip['value']
                  as String;
                });
              },
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(
                  20,
                ),
                side: BorderSide(
                  color: isSelected
                      ? Colors
                      .transparent
                      : color
                      .withValues(
                    alpha:
                    0.20,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // JENIS FILTER
  // ============================================================

  Widget _buildJenisDropdown() {
    return Padding(
      padding:
      const EdgeInsets.fromLTRB(
        16,
        2,
        16,
        14,
      ),
      child: Container(
        height: 52,
        padding:
        const EdgeInsets.symmetric(
          horizontal: 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey
                .withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: 0.04),
              blurRadius: 10,
              offset:
              const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: kPrimaryColor
                    .withValues(
                  alpha: 0.08,
                ),
                borderRadius:
                BorderRadius.circular(
                  10,
                ),
              ),
              child: const Icon(
                Iconsax.category,
                color: kPrimaryColor,
                size: 18,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child:
              DropdownButtonHideUnderline(
                child:
                DropdownButton<String>(
                  value:
                  _selectedJenis,
                  isExpanded: true,

                  icon: Icon(
                    Iconsax
                        .arrow_down_1,
                    color:
                    Colors.grey[600],
                    size: 18,
                  ),

                  items:
                  _jenisList.map(
                        (e) {
                      return DropdownMenuItem<
                          String>(
                        value:
                        e['value']!,
                        child: Text(
                          e['display']!,
                          style:
                          primaryTextStyle
                              .copyWith(
                            fontSize:
                            13,
                            fontWeight:
                            medium,
                          ),
                        ),
                      );
                    },
                  ).toList(),

                  onChanged: (v) {
                    if (v == null) {
                      return;
                    }

                    setState(() {
                      _selectedJenis =
                          v;
                    });
                  },
                ),
              ),
            ),

            if (_selectedJenis !=
                'Semua')
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedJenis =
                    'Semua';
                  });
                },
                borderRadius:
                BorderRadius.circular(
                  20,
                ),
                child: const Padding(
                  padding:
                  EdgeInsets.all(5),
                  child: Icon(
                    Iconsax
                        .close_circle,
                    color: Colors.red,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RESULT INFO
  // ============================================================

  Widget _buildResultInfo(
      int count,
      ) {
    return Padding(
      padding:
      const EdgeInsets.fromLTRB(
        18,
        0,
        18,
        12,
      ),
      child: Row(
        children: [
          Text(
            '$count pekerjaan',
            style:
            primaryTextStyle.copyWith(
              fontSize: 13,
              fontWeight: bold,
            ),
          ),

          const Spacer(),

          if (_selectedStatus !=
              'Semua' ||
              _selectedJenis !=
                  'Semua' ||
              _searchQuery.isNotEmpty)
            InkWell(
              onTap: () {
                _searchDebounce
                    ?.cancel();

                _searchController
                    .clear();

                setState(() {
                  _selectedStatus =
                  'Semua';

                  _selectedJenis =
                  'Semua';

                  _searchQuery = '';
                });
              },
              borderRadius:
              BorderRadius.circular(
                10,
              ),
              child: Padding(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                child: Text(
                  'Reset filter',
                  style: TextStyle(
                    color:
                    kPrimaryColor,
                    fontSize: 11,
                    fontWeight:
                    FontWeight.w600,
                  ),
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

  Widget _buildTaskCard(
      ServisModel s,
      ) {
    final status =
    _statusKey(s);

    final statusColor =
    _statusColor(status);

    final statusText =
    _statusLabel(status);

    final statusIcon =
    _statusIcon(status);

    final jumlahText =
    s.itemsData.isNotEmpty
        ? '${s.itemsData.length}'
        : s.jumlahAc.toString();

    final lokasiText =
    (s.lokasiData?['address'] ??
        '-')
        .toString();

    final assignedAt =
    _fmtDateTime(
      s.tanggalDitugaskan,
    );

    final keluhanText =
    (s.catatan ?? '').trim();

    final tindakanText =
    (s.tindakanSummary ?? '')
        .trim();

    final infoUtama =
    status == 'ditugaskan'
        ? (
        keluhanText
            .isNotEmpty
            ? keluhanText
            : 'Belum ada keluhan'
    )
        : (
        tindakanText
            .isNotEmpty
            ? tindakanText
            : (
            keluhanText
                .isNotEmpty
                ? keluhanText
                : 'Belum ada tindakan'
        )
    );

    final clientName =
    s.lokasiNama.trim();

    final titleText =
    clientName.isNotEmpty
        ? clientName
        : 'Client #${s.id}';

    final techNames =
    s.itemsData
        .map(
          (it) =>
          (it['technician_name'] ??
              '')
              .toString(),
    )
        .where(
          (e) =>
      e.trim().isNotEmpty,
    )
        .toSet()
        .toList();

    return Container(
      margin:
      const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(22),
        border: Border.all(
          color: Colors.grey
              .withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.06),
            blurRadius: 16,
            offset:
            const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // ======================================================
          // CARD HEADER
          // ======================================================

          Container(
            padding:
            const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor
                  .withValues(
                alpha: 0.07,
              ),
              borderRadius:
              const BorderRadius.only(
                topLeft:
                Radius.circular(22),
                topRight:
                Radius.circular(22),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration:
                  BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius
                        .circular(
                      13,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                        statusColor
                            .withValues(
                          alpha:
                          0.12,
                        ),
                        blurRadius: 8,
                        offset:
                        const Offset(
                          0,
                          2,
                        ),
                      ),
                    ],
                  ),
                  child: Icon(
                    statusIcon,
                    color:
                    statusColor,
                    size: 21,
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
                        titleText,
                        maxLines: 2,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style:
                        const TextStyle(
                          fontSize: 14,
                          fontWeight:
                          FontWeight
                              .w700,
                          height: 1.25,
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      Row(
                        children: [
                          Icon(
                            Iconsax
                                .calendar_1,
                            size: 12,
                            color: Colors
                                .grey[600],
                          ),

                          const SizedBox(
                            width: 5,
                          ),

                          Expanded(
                            child: Text(
                              assignedAt,
                              maxLines: 1,
                              overflow:
                              TextOverflow
                                  .ellipsis,
                              style:
                              TextStyle(
                                fontSize:
                                10,
                                color:
                                Colors
                                    .grey[
                                600],
                                fontWeight:
                                FontWeight
                                    .w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                Container(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    statusColor
                        .withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                    BorderRadius
                        .circular(
                      20,
                    ),
                    border:
                    Border.all(
                      color:
                      statusColor
                          .withValues(
                        alpha:
                        0.20,
                      ),
                    ),
                  ),
                  child: Text(
                    statusText,
                    style:
                    TextStyle(
                      fontSize: 9,
                      fontWeight:
                      FontWeight
                          .w800,
                      color:
                      statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // CARD CONTENT
          // ======================================================

          Padding(
            padding:
            const EdgeInsets.all(
              16,
            ),
            child: Column(
              children: [
                Container(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration:
                  BoxDecoration(
                    color: Colors
                        .grey[50],
                    borderRadius:
                    BorderRadius
                        .circular(
                      16,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child:
                        _infoItemForTechnician(
                          icon:
                          Iconsax.cpu,
                          title:
                          'Jumlah AC',
                          value:
                          '$jumlahText Unit',
                          color:
                          Colors.blue,
                        ),
                      ),

                      Container(
                        width: 1,
                        height: 38,
                        margin:
                        const EdgeInsets
                            .symmetric(
                          horizontal:
                          14,
                        ),
                        color: Colors
                            .grey[200],
                      ),

                      Expanded(
                        child:
                        _infoItemForTechnician(
                          icon:
                          Iconsax
                              .info_circle,
                          title:
                          'Jenis',
                          value: s
                              .jenisDisplay,
                          color: Colors
                              .purple,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                if (status !=
                    'selesai') ...[
                  _modernDetailTile(
                    icon:
                    Iconsax.location,
                    title: 'Alamat',
                    value:
                    lokasiText,
                    iconColor:
                    kPrimaryColor,
                    gradientColors: [
                      kPrimaryColor
                          .withValues(
                        alpha: 0.08,
                      ),
                      kPrimaryColor
                          .withValues(
                        alpha: 0.03,
                      ),
                    ],
                    maxLines: 2,
                  ),

                  const SizedBox(
                    height: 10,
                  ),
                ],

                _modernDetailTile(
                  icon:
                  status ==
                      'ditugaskan'
                      ? Iconsax
                      .message_text
                      : Iconsax
                      .note_text,
                  title:
                  status ==
                      'ditugaskan'
                      ? 'Keluhan Client'
                      : 'Tindakan',
                  value:
                  infoUtama,
                  iconColor:
                  status ==
                      'ditugaskan'
                      ? Colors.orange
                      : Colors.purple,
                  gradientColors:
                  status ==
                      'ditugaskan'
                      ? [
                    Colors
                        .orange
                        .withValues(
                      alpha:
                      0.08,
                    ),
                    Colors
                        .orange
                        .withValues(
                      alpha:
                      0.03,
                    ),
                  ]
                      : [
                    Colors
                        .purple
                        .withValues(
                      alpha:
                      0.08,
                    ),
                    Colors
                        .purple
                        .withValues(
                      alpha:
                      0.03,
                    ),
                  ],
                  maxLines: 3,
                ),

                if (techNames.length >
                    1) ...[
                  const SizedBox(
                    height: 10,
                  ),

                  _modernDetailTile(
                    icon:
                    Iconsax
                        .profile_2user,
                    title:
                    'Tim Teknisi',
                    value:
                    techNames.join(
                      ', ',
                    ),
                    iconColor:
                    Colors.indigo,
                    gradientColors: [
                      Colors.indigo
                          .withValues(
                        alpha: 0.08,
                      ),
                      Colors.indigo
                          .withValues(
                        alpha: 0.03,
                      ),
                    ],
                  ),
                ],

                const SizedBox(
                  height: 16,
                ),

                _buildActionButtonForTechnician(
                  statusColor,
                  s,
                ),
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
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: color.withValues(
                alpha: 0.80,
              ),
            ),

            const SizedBox(
              width: 7,
            ),

            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color:
                Colors.grey[600],
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 5),

        Text(
          value,
          maxLines: 1,
          overflow:
          TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight:
            FontWeight.w800,
            color:
            Colors.grey[900],
            height: 1.2,
          ),
        ),

        if (subtitle.isNotEmpty) ...[
          const SizedBox(
            height: 2,
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color:
              Colors.grey[500],
            ),
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
    required List<Color>
    gradientColors,
    int maxLines = 2,
  }) {
    return Container(
      padding:
      const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin:
          Alignment.topLeft,
          end:
          Alignment.bottomRight,
        ),
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color:
          iconColor.withValues(
            alpha: 0.10,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration:
            BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(
                11,
              ),
            ),
            child: Icon(
              icon,
              size: 19,
              color:
              iconColor,
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
                  title,
                  style:
                  TextStyle(
                    fontSize: 11,
                    fontWeight:
                    FontWeight
                        .w700,
                    color:
                    iconColor,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  value,
                  maxLines:
                  maxLines,
                  overflow:
                  TextOverflow
                      .ellipsis,
                  style:
                  TextStyle(
                    fontSize: 12,
                    fontWeight:
                    FontWeight
                        .w600,
                    color:
                    Colors
                        .grey[800],
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

  Widget
  _buildActionButtonForTechnician(
      Color statusColor,
      ServisModel s,
      ) {
    return Material(
      color:
      Colors.transparent,
      child: InkWell(
        onTap:
            () => _openDetail(s),
        borderRadius:
        BorderRadius.circular(14),
        child: Container(
          width:
          double.infinity,
          padding:
          const EdgeInsets
              .symmetric(
            vertical: 14,
          ),
          decoration:
          BoxDecoration(
            gradient:
            LinearGradient(
              colors: [
                statusColor
                    .withValues(
                  alpha: 0.95,
                ),
                statusColor
                    .withValues(
                  alpha: 0.78,
                ),
              ],
            ),
            borderRadius:
            BorderRadius.circular(
              14,
            ),
            boxShadow: [
              BoxShadow(
                color:
                statusColor
                    .withValues(
                  alpha: 0.20,
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
          child: const Row(
            mainAxisAlignment:
            MainAxisAlignment
                .center,
            children: [
              Icon(
                Iconsax
                    .document_text,
                size: 18,
                color:
                Colors.white,
              ),

              SizedBox(
                width: 8,
              ),

              Text(
                'Lihat Detail',
                style:
                TextStyle(
                  fontSize: 13,
                  fontWeight:
                  FontWeight
                      .w700,
                  color:
                  Colors.white,
                ),
              ),

              SizedBox(
                width: 6,
              ),

              Icon(
                Iconsax
                    .arrow_right_3,
                size: 16,
                color:
                Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(
      ServisModel s,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TeknisiTaskDetailPage(
              servis: s,
            ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError(
      String message,
      ) {
    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        14,
      ),
      padding:
      const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.red
            .withValues(alpha: 0.06),
        borderRadius:
        BorderRadius.circular(14),
        border: Border.all(
          color: Colors.red
              .withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration:
            BoxDecoration(
              color: Colors.red
                  .withValues(
                alpha: 0.08,
              ),
              borderRadius:
              BorderRadius.circular(
                10,
              ),
            ),
            child: const Icon(
              Iconsax.warning_2,
              color:
              Colors.red,
              size: 18,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Text(
              message,
              style:
              primaryTextStyle
                  .copyWith(
                fontSize: 11,
                color:
                Colors.red,
              ),
            ),
          ),

          TextButton(
            onPressed:
            _refresh,
            child:
            const Text(
              'Ulangi',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 30,
      ),
      child: Column(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration:
            BoxDecoration(
              color: Colors.grey
                  .withValues(
                alpha: 0.07,
              ),
              shape:
              BoxShape.circle,
            ),
            child: Icon(
              Iconsax.note_remove,
              color:
              Colors.grey[400],
              size: 46,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          Text(
            'Tidak ada pekerjaan',
            style:
            primaryTextStyle.copyWith(
              fontSize: 17,
              fontWeight: bold,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            'Tidak ada data yang cocok dengan filter atau pencarian saat ini.',
            textAlign:
            TextAlign.center,
            style:
            greyTextStyle.copyWith(
              fontSize: 12,
              height: 1.5,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          ElevatedButton.icon(
            onPressed: () {
              _searchDebounce
                  ?.cancel();

              _searchController
                  .clear();

              setState(() {
                _selectedStatus =
                'Semua';

                _selectedJenis =
                'Semua';

                _searchQuery = '';
              });
            },
            icon: const Icon(
              Iconsax.refresh,
              size: 17,
            ),
            label:
            const Text(
              'Reset Filter',
            ),
            style:
            ElevatedButton
                .styleFrom(
              backgroundColor:
              kPrimaryColor,
              foregroundColor:
              Colors.white,
              elevation: 0,
              padding:
              const EdgeInsets
                  .symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius
                    .circular(
                  12,
                ),
              ),
            ),
          ),
        ],
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
    return Consumer2<
        TeknisiProvider,
        AuthProvider>(
      builder:
          (
          context,
          prov,
          auth,
          _,
          ) {
        final all =
            prov.tasks;

        final list =
        _filtered(all);

        // ========================================================
        // SUMMARY
        // ========================================================

        final ditugaskan =
            all
                .where(
                  (s) =>
              _statusKey(
                s,
              ) ==
                  'ditugaskan',
            )
                .length;

        final dikerjakan =
            all
                .where(
                  (s) =>
              _statusKey(
                s,
              ) ==
                  'dikerjakan',
            )
                .length;

        final selesai =
            all
                .where(
                  (s) =>
              _statusKey(
                s,
              ) ==
                  'selesai',
            )
                .length;

        // ========================================================
        // USER
        // ========================================================

        final user =
            auth.user;

        final nama =
        (
            user
                ?.name
                ?.toString()
                .trim()
                .isNotEmpty ??
                false
        )
            ? user!.name!
            : 'Teknisi';

        final subtitle =
        (
            user
                ?.role
                ?.toString()
                .trim()
                .isNotEmpty ??
                false
        )
            ? user!.role!
            .toString()
            .toUpperCase()
            : 'TEKNISI';

        return Scaffold(
          backgroundColor:
          kBackgroundColor,

          body: SafeArea(
            child:
            RefreshIndicator(
              onRefresh:
              _refresh,
              color:
              kPrimaryColor,

              child:
              CustomScrollView(
                physics:
                const AlwaysScrollableScrollPhysics(),

                slivers: [
                  // ===============================================
                  // HEADER
                  // HEADER IKUT SCROLL
                  // ===============================================

                  SliverToBoxAdapter(
                    child:
                    _buildHeader(
                      context:
                      context,
                      nama: nama,
                      subtitle:
                      subtitle,
                      ditugaskan:
                      ditugaskan,
                      dikerjakan:
                      dikerjakan,
                      selesai:
                      selesai,
                    ),
                  ),

                  // ===============================================
                  // SEARCH
                  // ===============================================

                  SliverToBoxAdapter(
                    child:
                    _buildSearchBar(),
                  ),

                  // ===============================================
                  // STATUS FILTER
                  // ===============================================

                  SliverToBoxAdapter(
                    child:
                    _buildStatusChips(),
                  ),

                  // ===============================================
                  // JENIS FILTER
                  // ===============================================

                  SliverToBoxAdapter(
                    child:
                    _buildJenisDropdown(),
                  ),

                  // ===============================================
                  // ERROR
                  // ===============================================

                  if (prov.error !=
                      null)
                    SliverToBoxAdapter(
                      child:
                      _buildError(
                        prov.error!,
                      ),
                    ),

                  // ===============================================
                  // RESULT COUNTER
                  // ===============================================

                  if (!(prov.loading &&
                      all.isEmpty))
                    SliverToBoxAdapter(
                      child:
                      _buildResultInfo(
                        list.length,
                      ),
                    ),

                  // ===============================================
                  // LOADING
                  // ===============================================

                  if (prov.loading &&
                      all.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody:
                      false,
                      child: Center(
                        child:
                        CircularProgressIndicator(),
                      ),
                    )

                  // ===============================================
                  // EMPTY
                  // ===============================================

                  else if (list
                      .isEmpty)
                    SliverFillRemaining(
                      hasScrollBody:
                      false,
                      child: Center(
                        child:
                        _buildEmptyState(),
                      ),
                    )

                  // ===============================================
                  // LIST
                  // ===============================================

                  else
                    SliverPadding(
                      padding:
                      const EdgeInsets.only(
                        top: 2,
                        bottom: 100,
                      ),

                      sliver:
                      SliverList(
                        delegate:
                        SliverChildBuilderDelegate(
                              (
                              context,
                              index,
                              ) {
                            return _buildTaskCard(
                              list[index],
                            );
                          },
                          childCount:
                          list.length,
                        ),
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
}