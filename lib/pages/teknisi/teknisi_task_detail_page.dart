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
  State<TeknisiTaskDetailPage> createState() =>
      _TeknisiTaskDetailPageState();
}

class _TeknisiTaskDetailPageState extends State<TeknisiTaskDetailPage> {
  late ServisModel _servis;

  String? _token;
  int? _selectedFloor;

  bool _showAllDetails = false;

  final ScrollController _scrollController = ScrollController();

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _servis = widget.servis;
    _loadToken();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _refreshFromProvider() async {
    final prov = context.read<TeknisiProvider>();

    await prov.fetchTasks();

    if (!mounted) return;

    final idx = prov.tasks.indexWhere(
          (e) => e.id == _servis.id,
    );

    if (idx != -1) {
      setState(() {
        _servis = prov.tasks[idx];
      });
    }
  }

  // ============================================================
  // FLOOR
  // ============================================================

  int _getFloorNumberFromItem(
      Map<String, dynamic> item,
      ) {
    final acRaw = item['ac_unit'];

    final ac = acRaw is Map<String, dynamic>
        ? acRaw
        : acRaw is Map
        ? Map<String, dynamic>.from(acRaw)
        : <String, dynamic>{};

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

  String _getFloorLabelFromItem(
      Map<String, dynamic> item,
      ) {
    final acRaw = item['ac_unit'];

    final ac = acRaw is Map<String, dynamic>
        ? acRaw
        : acRaw is Map
        ? Map<String, dynamic>.from(acRaw)
        : <String, dynamic>{};

    final room = ac['room'];

    if (room is Map) {
      final floor = room['floor'];

      if (floor is Map) {
        final name =
        (floor['name'] ?? '').toString().trim();

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

    final lantai = int.tryParse(
      (ac['lantai'] ?? 0).toString(),
    ) ??
        0;

    return lantai > 0
        ? 'Lantai $lantai'
        : '-';
  }

  List<int> _extractFloorOptions(
      List<Map<String, dynamic>> items,
      ) {
    final floors = items
        .map(_getFloorNumberFromItem)
        .where((e) => e > 0)
        .toSet()
        .toList()
      ..sort();

    return floors;
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _statusKey() {
    final items = _servis.itemsData;

    if (items.isEmpty) {
      return _servis.status.name.toLowerCase();
    }

    final statuses = items
        .map(
          (it) => (it['status'] ?? '')
          .toString()
          .toLowerCase()
          .trim(),
    )
        .where((e) => e.isNotEmpty)
        .toList();

    if (statuses.isEmpty) {
      return _servis.status.name.toLowerCase();
    }

    if (statuses.every((x) => x == 'selesai')) {
      return 'selesai';
    }

    if (statuses.any((x) => x == 'dikerjakan')) {
      return 'dikerjakan';
    }

    if (statuses.any((x) => x == 'ditugaskan')) {
      return 'ditugaskan';
    }

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
        return const Color(0xFF8E44AD);

      case 'selesai':
        return const Color(0xFF2EAF62);

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

  // ============================================================
  // DATA HELPERS
  // ============================================================

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '-';

    return DateFormat(
      'dd MMM yyyy',
      'id_ID',
    ).format(dt);
  }

  String _jumlahAcDisplay(
      ServisModel s,
      ) {
    if (s.itemsData.isNotEmpty) {
      return '${s.itemsData.length}';
    }

    if (s.jumlahAc > 0) {
      return '${s.jumlahAc}';
    }

    if (s.acUnits.isNotEmpty) {
      return '${s.acUnits.length}';
    }

    if (s.acUnitId != null) {
      return '1';
    }

    return '-';
  }

  List<String> _technicianNames(
      ServisModel s,
      ) {
    final names = <String>[];

    for (final tech in s.techniciansData) {
      final name =
      (tech['name'] ?? '').toString().trim();

      if (name.isNotEmpty &&
          !names.contains(name)) {
        names.add(name);
      }
    }

    final fallback =
    (s.teknisiData?['name'] ?? '')
        .toString()
        .trim();

    if (fallback.isNotEmpty &&
        !names.contains(fallback)) {
      names.add(fallback);
    }

    if (names.isEmpty &&
        s.technicianId != null) {
      names.add(
        'Teknisi #${s.technicianId}',
      );
    }

    return names;
  }

  String _lokasiAlamat(
      ServisModel s,
      ) {
    return (s.lokasiData?['address'] ?? '-')
        .toString();
  }

  String? _durationDisplay(
      ServisModel s,
      ) {
    final start = s.tanggalMulai;
    final end = s.tanggalSelesai;

    if (start == null) {
      return null;
    }

    final effectiveEnd =
        end ?? DateTime.now();

    final diff =
    effectiveEnd.difference(start);

    if (diff.inMinutes < 1) {
      return 'Baru dimulai';
    }

    if (diff.inHours < 1) {
      return '${diff.inMinutes} menit';
    }

    if (diff.inDays < 1) {
      final hours = diff.inHours;
      final minutes =
          diff.inMinutes % 60;

      if (minutes == 0) {
        return '$hours jam';
      }

      return '$hours jam $minutes menit';
    }

    final days = diff.inDays;
    final hours =
        diff.inHours % 24;

    if (hours == 0) {
      return '$days hari';
    }

    return '$days hari $hours jam';
  }

  int _calculateProgress(
      List<Map<String, dynamic>> items,
      ) {
    if (items.isEmpty) {
      return 0;
    }

    final completed = items.where(
          (item) {
        final status =
        (item['status'] ?? '')
            .toString()
            .toLowerCase();

        return status == 'selesai';
      },
    ).length;

    return (
        completed *
            100 /
            items.length
    ).round();
  }

  bool _hasFoto(
      Map<String, dynamic> item,
      ) {
    final sebelum =
    item['foto_sebelum'];

    final pengerjaan =
    item['foto_pengerjaan'];

    final sesudah =
    item['foto_sesudah'];

    if (sebelum is List &&
        sebelum.isNotEmpty) {
      return true;
    }

    if (sebelum is String &&
        sebelum.trim().isNotEmpty) {
      return true;
    }

    if (pengerjaan is List &&
        pengerjaan.isNotEmpty) {
      return true;
    }

    if (pengerjaan is String &&
        pengerjaan.trim().isNotEmpty) {
      return true;
    }

    if (sesudah is List &&
        sesudah.isNotEmpty) {
      return true;
    }

    if (sesudah is String &&
        sesudah.trim().isNotEmpty) {
      return true;
    }

    return false;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final status =
    _statusKey();

    final statusColor =
    _statusColor(status);

    final technicianNames =
    _technicianNames(_servis);

    return Scaffold(
      backgroundColor:
      const Color(0xFFF6F7FB),

      body: RefreshIndicator(
        onRefresh:
        _refreshFromProvider,
        color:
        kPrimaryColor,

        child: CustomScrollView(
          controller:
          _scrollController,
          physics:
          const AlwaysScrollableScrollPhysics(
            parent:
            BouncingScrollPhysics(),
          ),

          slivers: [
            SliverAppBar(
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor:
              statusColor,
              surfaceTintColor:
              Colors.transparent,

              leading: Padding(
                padding:
                const EdgeInsets.all(
                  8,
                ),
                child: Material(
                  color: Colors.white
                      .withValues(
                    alpha: 0.18,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                  child: InkWell(
                    borderRadius:
                    BorderRadius.circular(
                      12,
                    ),
                    onTap: () {
                      Navigator.pop(
                        context,
                      );
                    },
                    child: const Icon(
                      Iconsax.arrow_left_2,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),

              title: const Text(
                'Detail Pekerjaan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight:
                  FontWeight.w700,
                  fontSize: 16,
                ),
              ),

              centerTitle: false,
              expandedHeight: 240,

              flexibleSpace:
              FlexibleSpaceBar(
                collapseMode:
                CollapseMode.parallax,

                background:
                _buildHeader(
                  status,
                  statusColor,
                ),
              ),
            ),

            SliverPadding(
              padding:
              const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                40,
              ),

              sliver:
              SliverList(
                delegate:
                SliverChildListDelegate(
                  [
                    _buildSummaryCard(),

                    const SizedBox(
                      height: 14,
                    ),

                    _buildAcListSection(
                      context,
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    _buildDetailsSection(),

                    if (technicianNames
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 14,
                      ),

                      _buildTechniciansCard(
                        technicianNames,
                      ),
                    ],

                    const SizedBox(
                      height: 40,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
      String status,
      Color statusColor,
      ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin:
          Alignment.topLeft,
          end:
          Alignment.bottomRight,
          colors: [
            statusColor,
            statusColor.withValues(
              alpha: 0.78,
            ),
          ],
        ),
      ),

      child: SafeArea(
        bottom: false,
        child: Padding(
          padding:
          const EdgeInsets.fromLTRB(
            20,
            78,
            20,
            20,
          ),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            mainAxisAlignment:
            MainAxisAlignment.end,

            children: [
              Row(
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration:
                    BoxDecoration(
                      color: Colors.white
                          .withValues(
                        alpha: 0.18,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        20,
                      ),
                    ),

                    child: Row(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: [
                        Icon(
                          _statusIcon(
                            status,
                          ),
                          size: 14,
                          color:
                          Colors.white,
                        ),

                        const SizedBox(
                          width: 6,
                        ),

                        Text(
                          _statusLabel(
                            status,
                          ),
                          style:
                          const TextStyle(
                            fontSize: 11,
                            fontWeight:
                            FontWeight.w700,
                            color:
                            Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration:
                    BoxDecoration(
                      color: Colors.white
                          .withValues(
                        alpha: 0.18,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: Text(
                      _servis.jenisDisplay,
                      style:
                      const TextStyle(
                        fontSize: 11,
                        color:
                        Colors.white,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 14,
              ),

              Text(
                _servis.lokasiNama,
                maxLines: 2,
                overflow:
                TextOverflow.ellipsis,
                style:
                const TextStyle(
                  fontSize: 21,
                  height: 1.15,
                  fontWeight:
                  FontWeight.w800,
                  color:
                  Colors.white,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Icon(
                    Iconsax.location,
                    size: 16,
                    color: Colors.white
                        .withValues(
                      alpha: 0.85,
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Expanded(
                    child: Text(
                      _lokasiAlamat(
                        _servis,
                      ),
                      maxLines: 2,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style:
                      TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Colors.white
                            .withValues(
                          alpha: 0.90,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummaryCard() {
    final technicianNames =
    _technicianNames(_servis);

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color:
          Colors.black.withValues(
            alpha: 0.04,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withValues(
              alpha: 0.045,
            ),
            blurRadius: 16,
            offset:
            const Offset(0, 5),
          ),
        ],
      ),

      child: Row(
        children: [
          Expanded(
            child:
            _summaryItem(
              icon:
              Iconsax.calendar_1,
              label: 'Tanggal',
              value: _fmtDate(
                _servis.tanggalDitugaskan,
              ),
              color: Colors.blue,
            ),
          ),

          _verticalDivider(),

          Expanded(
            child:
            _summaryItem(
              icon: Iconsax.cpu,
              label: 'Unit AC',
              value:
              _jumlahAcDisplay(
                _servis,
              ),
              color:
              Colors.green,
            ),
          ),

          _verticalDivider(),

          Expanded(
            child:
            _summaryItem(
              icon: Iconsax.profile_2user,
              label: 'Teknisi',
              value:
              '${technicianNames.length}',
              color:
              Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration:
          BoxDecoration(
            color:
            color.withValues(
              alpha: 0.10,
            ),
            borderRadius:
            BorderRadius.circular(
              11,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        Text(
          value,
          maxLines: 1,
          overflow:
          TextOverflow.ellipsis,
          textAlign:
          TextAlign.center,
          style:
          const TextStyle(
            fontSize: 12,
            fontWeight:
            FontWeight.w700,
            color:
            Colors.black87,
          ),
        ),

        const SizedBox(
          height: 2,
        ),

        Text(
          label,
          style:
          TextStyle(
            fontSize: 10,
            color:
            Colors.grey[600],
            fontWeight:
            FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 56,
      margin:
      const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      color:
      Colors.grey[200],
    );
  }

  // ============================================================
  // AC SECTION
  // ============================================================

  Widget _buildAcListSection(
      BuildContext context,
      ) {
    final items =
        _servis.itemsData;

    final hasItems =
        items.isNotEmpty;

    final progress =
    _calculateProgress(items);

    final floorOptions =
    _extractFloorOptions(
      items,
    );

    final filteredItems =
    _selectedFloor == null
        ? items
        : items
        .where(
          (item) =>
      _getFloorNumberFromItem(
        item,
      ) ==
          _selectedFloor,
    )
        .toList();

    return _sectionCard(
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              _sectionIcon(
                Iconsax.cpu,
                kPrimaryColor,
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Unit AC',
                      style:
                      TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.w700,
                        color:
                        Colors.black87,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      '${items.length} unit dalam pekerjaan ini',
                      style:
                      TextStyle(
                        fontSize: 11,
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
                  vertical: 6,
                ),
                decoration:
                BoxDecoration(
                  color: progress == 100
                      ? Colors.green
                      .withValues(
                    alpha: 0.10,
                  )
                      : kPrimaryColor
                      .withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),

                child: Text(
                  '$progress%',
                  style:
                  TextStyle(
                    fontSize: 11,
                    fontWeight:
                    FontWeight.w700,
                    color: progress == 100
                        ? Colors.green
                        : kPrimaryColor,
                  ),
                ),
              ),
            ],
          ),

          if (hasItems) ...[
            const SizedBox(
              height: 16,
            ),

            _buildProgressBar(
              progress,
            ),
          ],

          if (floorOptions
              .isNotEmpty) ...[
            const SizedBox(
              height: 18,
            ),

            _buildFloorFilter(
              floorOptions,
            ),
          ],

          const SizedBox(
            height: 16,
          ),

          if (!hasItems)
            _buildFallbackAcList()
          else if (filteredItems
              .isEmpty)
            _buildEmptyFloor()
          else
            Column(
              children:
              filteredItems
                  .asMap()
                  .entries
                  .map(
                    (entry) {
                  final index =
                      entry.key;

                  final item =
                      entry.value;

                  final itemId =
                      int.tryParse(
                        (
                            item['id'] ??
                                ''
                        )
                            .toString(),
                      ) ??
                          0;

                  return Padding(
                    padding:
                    EdgeInsets.only(
                      bottom:
                      index ==
                          filteredItems.length -
                              1
                          ? 0
                          : 10,
                    ),
                    child:
                    _buildAcListItem(
                      context,
                      item,
                      itemId,
                    ),
                  );
                },
              ).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildFloorFilter(
      List<int> floorOptions,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          'Filter lantai',
          style:
          TextStyle(
            fontSize: 11,
            fontWeight:
            FontWeight.w600,
            color:
            Colors.grey[600],
          ),
        ),

        const SizedBox(
          height: 7,
        ),

        Container(
          height: 46,
          padding:
          const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          decoration:
          BoxDecoration(
            color:
            const Color(
              0xFFF8F9FC,
            ),
            borderRadius:
            BorderRadius.circular(
              13,
            ),
            border: Border.all(
              color:
              Colors.grey[200]!,
            ),
          ),

          child:
          DropdownButtonHideUnderline(
            child:
            DropdownButton<int?>(
              value:
              _selectedFloor,

              isExpanded: true,

              icon: Icon(
                Iconsax.arrow_down_1,
                size: 17,
                color:
                Colors.grey[600],
              ),

              style:
              const TextStyle(
                fontSize: 13,
                color:
                Colors.black87,
                fontWeight:
                FontWeight.w600,
              ),

              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child:
                  Text(
                    'Semua lantai',
                  ),
                ),

                ...floorOptions.map(
                      (floor) {
                    return DropdownMenuItem<int?>(
                      value: floor,
                      child:
                      Text(
                        'Lantai $floor',
                      ),
                    );
                  },
                ),
              ],

              onChanged: (
                  value,
                  ) {
                setState(() {
                  _selectedFloor =
                      value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(
      int progress,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Progress pengerjaan',
              style:
              TextStyle(
                fontSize: 11,
                color:
                Colors.grey[600],
                fontWeight:
                FontWeight.w500,
              ),
            ),

            const Spacer(),

            Text(
              '$progress%',
              style:
              TextStyle(
                fontSize: 11,
                fontWeight:
                FontWeight.w700,
                color:
                kPrimaryColor,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 8,
        ),

        ClipRRect(
          borderRadius:
          BorderRadius.circular(
            10,
          ),
          child:
          LinearProgressIndicator(
            value:
            progress / 100,
            minHeight: 7,
            backgroundColor:
            Colors.grey[200],
            valueColor:
            AlwaysStoppedAnimation<Color>(
              progress == 100
                  ? Colors.green
                  : kPrimaryColor,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // AC ITEM
  // ROOM NAME PRIORITAS UTAMA
  // AC NAME TETAP DITAMPILKAN
  // ============================================================

  Widget _buildAcListItem(
      BuildContext context,
      Map<String, dynamic> item,
      int itemId,
      ) {
    final acRaw =
    item['ac_unit'];

    final ac = acRaw is Map<String, dynamic>
        ? acRaw
        : acRaw is Map
        ? Map<String, dynamic>.from(
      acRaw,
    )
        : <String, dynamic>{};

    final itemStatus =
    (item['status'] ?? '')
        .toString()
        .toLowerCase()
        .trim();

    final statusColor =
    _statusColor(
      itemStatus,
    );

    final floorLabel =
    _getFloorLabelFromItem(
      item,
    );

    // ==========================================================
    // ROOM
    // ==========================================================

    final roomRaw =
    ac['room'];

    final room = roomRaw is Map<String, dynamic>
        ? roomRaw
        : roomRaw is Map
        ? Map<String, dynamic>.from(
      roomRaw,
    )
        : <String, dynamic>{};

    final roomName =
    (room['name'] ?? '')
        .toString()
        .trim();

    // ==========================================================
    // AC
    // ==========================================================

    final acName =
    (ac['name'] ?? '')
        .toString()
        .trim();

    final brand =
    (ac['brand'] ?? '-')
        .toString()
        .trim();

    final type =
    (ac['type'] ?? '-')
        .toString()
        .trim();

    final capacity =
    (ac['capacity'] ?? '-')
        .toString()
        .trim();

    final hasFoto =
    _hasFoto(item);

    // ROOM jadi title utama
    // fallback ke nama AC kalau room kosong
    final title =
    roomName.isNotEmpty
        ? roomName
        : acName.isNotEmpty
        ? acName
        : 'Unit AC';

    return Material(
      color:
      Colors.transparent,

      child: InkWell(
        borderRadius:
        BorderRadius.circular(
          16,
        ),

        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (
                  context,
                  ) =>
                  TeknisiAcDetailPage(
                    servis:
                    _servis,
                    item:
                    item,
                    itemId:
                    itemId,
                    token:
                    _token,
                    onUpdate:
                    _refreshFromProvider,
                  ),
            ),
          );

          if (mounted) {
            await _refreshFromProvider();
          }
        },

        child: Container(
          padding:
          const EdgeInsets.all(
            14,
          ),
          decoration:
          BoxDecoration(
            color:
            const Color(
              0xFFF9FAFC,
            ),
            borderRadius:
            BorderRadius.circular(
              16,
            ),
            border: Border.all(
              color:
              statusColor.withValues(
                alpha: 0.12,
              ),
            ),
          ),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  // ===============================================
                  // ROOM ICON
                  // ===============================================

                  Container(
                    width: 44,
                    height: 44,
                    decoration:
                    BoxDecoration(
                      color:
                      statusColor
                          .withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        13,
                      ),
                    ),
                    child: Icon(
                      Iconsax.building_3,
                      color:
                      statusColor,
                      size: 21,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  // ===============================================
                  // ROOM + AC NAME
                  // ===============================================

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [
                        Row(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow:
                                TextOverflow.ellipsis,
                                style:
                                const TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                  FontWeight.w800,
                                  color:
                                  Colors.black87,
                                  height: 1.2,
                                ),
                              ),
                            ),

                            const SizedBox(
                              width: 8,
                            ),

                            _buildStatusBadge(
                              itemStatus,
                              statusColor,
                            ),
                          ],
                        ),

                        // =========================================
                        // AC NAME
                        // =========================================

                        if (acName.isNotEmpty) ...[
                          const SizedBox(
                            height: 7,
                          ),

                          Row(
                            children: [
                              Icon(
                                Iconsax.airdrop,
                                size: 13,
                                color:
                                Colors.grey[600],
                              ),

                              const SizedBox(
                                width: 5,
                              ),

                              Expanded(
                                child: Text(
                                  acName,
                                  maxLines: 1,
                                  overflow:
                                  TextOverflow.ellipsis,
                                  style:
                                  TextStyle(
                                    fontSize: 11,
                                    fontWeight:
                                    FontWeight.w600,
                                    color:
                                    Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(
                          height: 4,
                        ),

                        // =========================================
                        // BRAND & TYPE
                        // =========================================

                        Text(
                          '$brand • $type',
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style:
                          TextStyle(
                            fontSize: 10,
                            color:
                            Colors.grey[600],
                            fontWeight:
                            FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Icon(
                    Iconsax.arrow_right_3,
                    size: 17,
                    color:
                    Colors.grey[400],
                  ),
                ],
              ),

              const SizedBox(
                height: 12,
              ),

              // ===================================================
              // BADGES
              // ===================================================

              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _smallInfoBadge(
                    icon:
                    Iconsax.flash_1,
                    label:
                    capacity,
                    color:
                    kPrimaryColor,
                  ),

                  if (floorLabel != '-')
                    _smallInfoBadge(
                      icon:
                      Iconsax.building,
                      label:
                      floorLabel,
                      color:
                      Colors.purple,
                    ),

                  _buildCompletionBadge(
                    label:
                    'Foto',
                    isCompleted:
                    hasFoto,
                    color:
                    Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
      String status,
      Color color,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration:
      BoxDecoration(
        color:
        color.withValues(
          alpha: 0.10,
        ),
        borderRadius:
        BorderRadius.circular(
          20,
        ),
      ),
      child: Text(
        _statusLabel(status),
        style:
        TextStyle(
          fontSize: 9,
          fontWeight:
          FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _smallInfoBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration:
      BoxDecoration(
        color:
        color.withValues(
          alpha: 0.08,
        ),
        borderRadius:
        BorderRadius.circular(
          10,
        ),
      ),
      child: Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: color,
          ),

          const SizedBox(
            width: 4,
          ),

          Text(
            label,
            style:
            TextStyle(
              fontSize: 9,
              fontWeight:
              FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionBadge({
    required String label,
    required bool isCompleted,
    required Color color,
  }) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration:
      BoxDecoration(
        color:
        isCompleted
            ? color.withValues(
          alpha: 0.10,
        )
            : Colors.grey[100],
        borderRadius:
        BorderRadius.circular(
          10,
        ),
      ),
      child: Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            isCompleted
                ? Icons.check_circle
                : Icons.circle_outlined,
            size: 11,
            color:
            isCompleted
                ? color
                : Colors.grey[400],
          ),

          const SizedBox(
            width: 4,
          ),

          Text(
            label,
            style:
            TextStyle(
              fontSize: 9,
              fontWeight:
              FontWeight.w600,
              color:
              isCompleted
                  ? color
                  : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFloor() {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.symmetric(
        vertical: 28,
      ),
      child: Column(
        children: [
          Icon(
            Iconsax.cpu,
            size: 38,
            color:
            Colors.grey[300],
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            'Tidak ada unit AC',
            style:
            TextStyle(
              fontSize: 13,
              fontWeight:
              FontWeight.w600,
              color:
              Colors.grey[600],
            ),
          ),

          const SizedBox(
            height: 3,
          ),

          Text(
            'Tidak ada AC pada lantai yang dipilih.',
            style:
            TextStyle(
              fontSize: 11,
              color:
              Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackAcList() {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.symmetric(
        vertical: 28,
      ),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration:
            BoxDecoration(
              color:
              kPrimaryColor
                  .withValues(
                alpha: 0.06,
              ),
              shape:
              BoxShape.circle,
            ),
            child: Icon(
              Iconsax.cpu,
              color:
              kPrimaryColor
                  .withValues(
                alpha: 0.4,
              ),
              size: 30,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            'Belum ada unit AC',
            style:
            TextStyle(
              fontSize: 14,
              fontWeight:
              FontWeight.w600,
              color:
              Colors.grey[700],
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            'Unit AC akan muncul setelah ditambahkan.',
            style:
            TextStyle(
              fontSize: 11,
              color:
              Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DETAILS
  // ============================================================

  Widget _buildDetailsSection() {
    final catatan =
    (_servis.catatan ?? '')
        .trim();

    final tindakan =
    (_servis.tindakanSummary ?? '')
        .trim();

    final diagnosa =
    (_servis.diagnosa ?? '')
        .trim();

    return _sectionCard(
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          InkWell(
            borderRadius:
            BorderRadius.circular(
              12,
            ),

            onTap: () {
              setState(() {
                _showAllDetails =
                !_showAllDetails;
              });
            },

            child: Row(
              children: [
                _sectionIcon(
                  Iconsax.document_text,
                  kPrimaryColor,
                ),

                const SizedBox(
                  width: 10,
                ),

                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detail Servis',
                        style:
                        TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),

                      SizedBox(
                        height: 2,
                      ),

                      Text(
                        'Informasi pekerjaan',
                        style:
                        TextStyle(
                          fontSize: 11,
                          color:
                          Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: 34,
                  height: 34,
                  decoration:
                  BoxDecoration(
                    color:
                    Colors.grey[100],
                    borderRadius:
                    BorderRadius.circular(
                      10,
                    ),
                  ),
                  child: Icon(
                    _showAllDetails
                        ? Iconsax.arrow_up_2
                        : Iconsax.arrow_down_1,
                    size: 17,
                    color:
                    Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          _buildDetailRow(
            icon:
            Iconsax.message_text,
            title:
            'Keluhan / Catatan',
            content:
            catatan.isNotEmpty
                ? catatan
                : 'Tidak ada keluhan',
            color:
            Colors.orange,
          ),

          const SizedBox(
            height: 10,
          ),

          _buildDetailRow(
            icon:
            Iconsax.setting_2,
            title:
            'Tindakan',
            content:
            tindakan.isNotEmpty
                ? tindakan
                : 'Belum ada tindakan',
            color:
            Colors.green,
          ),

          if (diagnosa
              .isNotEmpty) ...[
            const SizedBox(
              height: 10,
            ),

            _buildDetailRow(
              icon:
              Iconsax.clipboard_text,
              title:
              'Diagnosa',
              content:
              diagnosa,
              color:
              Colors.purple,
            ),
          ],

          if (_showAllDetails) ...[
            const SizedBox(
              height: 10,
            ),

            _buildDetailRow(
              icon:
              Iconsax.timer_1,
              title:
              'Durasi',
              content:
              _durationDisplay(
                _servis,
              ) ??
                  'Belum tersedia',
              color:
              Colors.blue,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        13,
      ),
      decoration:
      BoxDecoration(
        color:
        color.withValues(
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
            width: 36,
            height: 36,
            decoration:
            BoxDecoration(
              color:
              color.withValues(
                alpha: 0.10,
              ),
              borderRadius:
              BorderRadius.circular(
                10,
              ),
            ),
            child: Icon(
              icon,
              size: 17,
              color: color,
            ),
          ),

          const SizedBox(
            width: 11,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style:
                  TextStyle(
                    fontSize: 11,
                    fontWeight:
                    FontWeight.w700,
                    color: color,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  content,
                  style:
                  TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color:
                    Colors.grey[800],
                    fontWeight:
                    FontWeight.w500,
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
  // TECHNICIANS
  // ============================================================

  Widget _buildTechniciansCard(
      List<String> technicianNames,
      ) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              _sectionIcon(
                Iconsax.profile_2user,
                kPrimaryColor,
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tim Teknisi',
                      style:
                      TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      '${technicianNames.length} teknisi bertugas',
                      style:
                      TextStyle(
                        fontSize: 11,
                        color:
                        Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 15,
          ),

          Column(
            children:
            technicianNames
                .asMap()
                .entries
                .map(
                  (entry) {
                final index =
                    entry.key;

                final name =
                    entry.value;

                final colors = [
                  Colors.blue,
                  Colors.green,
                  Colors.purple,
                  Colors.orange,
                  Colors.pink,
                ];

                final color =
                colors[
                index %
                    colors.length
                ];

                return Container(
                  margin:
                  EdgeInsets.only(
                    bottom:
                    index ==
                        technicianNames.length -
                            1
                        ? 0
                        : 9,
                  ),
                  padding:
                  const EdgeInsets.all(
                    11,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    const Color(
                      0xFFF9FAFC,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      14,
                    ),
                  ),

                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration:
                        BoxDecoration(
                          color:
                          color,
                          shape:
                          BoxShape.circle,
                        ),
                        child:
                        Center(
                          child: Text(
                            name.isNotEmpty
                                ? name[0]
                                .toUpperCase()
                                : 'T',
                            style:
                            const TextStyle(
                              color:
                              Colors.white,
                              fontWeight:
                              FontWeight.w700,
                              fontSize:
                              14,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 11,
                      ),

                      Expanded(
                        child:
                        Text(
                          name,
                          style:
                          const TextStyle(
                            fontSize:
                            13,
                            fontWeight:
                            FontWeight.w600,
                            color:
                            Colors.black87,
                          ),
                        ),
                      ),

                      Icon(
                        Iconsax.tick_circle,
                        size: 18,
                        color:
                        Colors.green[400],
                      ),
                    ],
                  ),
                );
              },
            ).toList(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMMON SECTION COMPONENT
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
        border: Border.all(
          color:
          Colors.black.withValues(
            alpha: 0.035,
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
      child: child,
    );
  }

  Widget _sectionIcon(
      IconData icon,
      Color color,
      ) {
    return Container(
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
          12,
        ),
      ),
      child: Icon(
        icon,
        size: 19,
        color: color,
      ),
    );
  }
}