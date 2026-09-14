// lib/pages/klien/client_servis_page.dart

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../models/lokasi_model.dart';
import '../../models/servis_model.dart';
import '../../providers/client_master_provider.dart';
import '../../providers/client_servis_provider.dart';
import '../../theme/theme.dart';

import 'servis_detail_page.dart';
import 'servis_history_page.dart';

class ClientServisPage extends StatefulWidget {
  const ClientServisPage({
    super.key,
  });

  @override
  State<ClientServisPage> createState() =>
      _ClientServisPageState();
}

class _ClientServisPageState
    extends State<ClientServisPage> {
  final TextEditingController _searchController =
  TextEditingController();

  int _selectedTab = 0;

  JenisPenanganan? _selectedJenis;

  String _query = '';

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(
      _onSearchChanged,
    );

    WidgetsBinding.instance.addPostFrameCallback(
          (_) {
        _loadData();
      },
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(
      _onSearchChanged,
    );

    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _loadData() async {
    final servisProvider =
    context.read<ClientServisProvider>();

    final masterProvider =
    context.read<ClientMasterProvider>();

    await Future.wait([
      servisProvider.fetchServis(),
      if (masterProvider.lokasi.isEmpty)
        masterProvider.fetchLokasi(),
    ]);
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _onSearchChanged() {
    setState(() {
      _query =
          _searchController.text
              .trim()
              .toLowerCase();
    });
  }

  // ============================================================
  // EFFECTIVE STATUS
  // ============================================================

  ServisStatus _effectiveStatus(
      ServisModel servis,
      ) {
    final items =
        servis.itemsData;

    if (items.isEmpty) {
      return servis.status;
    }

    final statuses =
    items
        .map(
          (item) =>
          (item['status'] ?? '')
              .toString()
              .toLowerCase()
              .trim(),
    )
        .where(
          (status) =>
      status.isNotEmpty,
    )
        .toList();

    if (statuses.isEmpty) {
      return servis.status;
    }

    if (statuses.every(
          (status) =>
      status == 'selesai',
    )) {
      return ServisStatus.selesai;
    }

    if (statuses.any(
          (status) =>
      status == 'dikerjakan',
    )) {
      return ServisStatus.dikerjakan;
    }

    if (statuses.any(
          (status) =>
      status == 'ditugaskan',
    )) {
      return ServisStatus.ditugaskan;
    }

    if (statuses.any(
          (status) =>
      status == 'batal',
    )) {
      return ServisStatus.batal;
    }

    return servis.status;
  }

  // ============================================================
  // FILTER
  // ============================================================

  bool _isActive(
      ServisModel servis,
      ) {
    final status =
    _effectiveStatus(
      servis,
    );

    return status !=
        ServisStatus.selesai &&
        status !=
            ServisStatus.batal;
  }

  bool _isHistory(
      ServisModel servis,
      ) {
    final status =
    _effectiveStatus(
      servis,
    );

    return status ==
        ServisStatus.selesai ||
        status ==
            ServisStatus.batal;
  }

  List<ServisModel> _filteredServices(
      List<ServisModel> source,
      ) {
    Iterable<ServisModel> result =
        source;

    // ==========================================================
    // TAB
    // ==========================================================

    if (_selectedTab == 0) {
      result = result.where(
        _isActive,
      );
    } else if (_selectedTab == 1) {
      result = result.where(
        _isHistory,
      );
    }

    // ==========================================================
    // TYPE
    // ==========================================================

    if (_selectedJenis != null) {
      result = result.where(
            (servis) =>
        servis.jenis ==
            _selectedJenis,
      );
    }

    // ==========================================================
    // SEARCH
    // ==========================================================

    if (_query.isNotEmpty) {
      result = result.where(
            (servis) {
          final location =
          servis.lokasiNama
              .toLowerCase();

          final client =
          servis.clientNama
              .toLowerCase();

          final technician =
          _technicianDisplay(
            servis,
          ).toLowerCase();

          final ac =
          _acDisplay(
            servis,
          ).toLowerCase();

          return location.contains(
            _query,
          ) ||
              client.contains(
                _query,
              ) ||
              technician.contains(
                _query,
              ) ||
              ac.contains(
                _query,
              ) ||
              servis.jenisDisplay
                  .toLowerCase()
                  .contains(
                _query,
              );
        },
      );
    }

    final list =
    result.toList();

    list.sort(
          (a, b) {
        final dateA =
        _serviceSortDate(a);

        final dateB =
        _serviceSortDate(b);

        return dateB.compareTo(
          dateA,
        );
      },
    );

    return list;
  }

  DateTime _serviceSortDate(
      ServisModel servis,
      ) {
    return servis.tanggalBerkunjung ??
        servis.tanggalDitugaskan ??
        servis.tanggalMulai ??
        DateTime(2000);
  }

  // ============================================================
  // GROUP LOCATION
  // ============================================================

  Map<int, List<ServisModel>>
  _groupByLocation(
      List<ServisModel> list,
      ) {
    final result =
    <int, List<ServisModel>>{};

    for (final servis in list) {
      final locationId =
          servis.locationId ??
              _parseInt(
                servis.lokasiData?['id'],
              );

      if (locationId == null) {
        continue;
      }

      result.putIfAbsent(
        locationId,
            () => [],
      );

      result[locationId]!.add(
        servis,
      );
    }

    return result;
  }

  int? _parseInt(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }

  // ============================================================
  // OPEN DETAIL
  // ============================================================

  void _openDetail(
      ServisModel servis,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ServisDetailPage(
              servis: servis,
            ),
      ),
    );
  }

  // ============================================================
  // OPEN LOCATION HISTORY
  // ============================================================

  void _openLocationHistory(
      int locationId,
      ) {
    final locations =
        context
            .read<
            ClientMasterProvider>()
            .lokasi;

    LokasiModel? location;

    for (final item in locations) {
      if (item.id ==
          locationId) {
        location = item;
        break;
      }
    }

    if (location == null) {
      _showMessage(
        'Data lokasi tidak ditemukan.',
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ServisHistoryPage(
              lokasi: location!,
            ),
      ),
    );
  }

  void _showMessage(
      String message,
      ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
        Text(message),
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final provider =
    context.watch<
        ClientServisProvider>();

    final allServices =
        provider.servisList;

    final services =
    _filteredServices(
      allServices,
    );

    final grouped =
    _groupByLocation(
      services,
    );

    final activeCount =
        allServices
            .where(
          _isActive,
        )
            .length;

    final completedCount =
        allServices
            .where(
              (s) =>
          _effectiveStatus(s) ==
              ServisStatus.selesai,
        )
            .length;

    final waitingCount =
        allServices
            .where(
              (s) =>
          _effectiveStatus(s) ==
              ServisStatus
                  .menungguKonfirmasi,
        )
            .length;

    return Scaffold(
      backgroundColor:
      kBackgroundColor,
      body: SafeArea(
        bottom: false,
        child:
        RefreshIndicator(
          color:
          kPrimaryColor,
          onRefresh:
          _refresh,
          child:
          CustomScrollView(
            physics:
            const AlwaysScrollableScrollPhysics(
              parent:
              BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding:
                const EdgeInsets
                    .fromLTRB(
                  20,
                  18,
                  20,
                  120,
                ),
                sliver:
                SliverList(
                  delegate:
                  SliverChildListDelegate(
                    [
                      // ==================================================
                      // HEADER
                      // ==================================================

                      _buildHeader(
                        activeCount:
                        activeCount,
                        waitingCount:
                        waitingCount,
                        completedCount:
                        completedCount,
                      ),

                      const SizedBox(
                        height: 22,
                      ),

                      // ==================================================
                      // TABS
                      // ==================================================

                      _buildTabs(
                        activeCount:
                        activeCount,
                        historyCount:
                        allServices
                            .where(
                          _isHistory,
                        )
                            .length,
                        allCount:
                        allServices
                            .length,
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ==================================================
                      // SEARCH
                      // ==================================================

                      _buildSearch(),

                      const SizedBox(
                        height: 14,
                      ),

                      // ==================================================
                      // TYPE FILTER
                      // ==================================================

                      _buildJenisFilter(),

                      const SizedBox(
                        height: 22,
                      ),

                      // ==================================================
                      // TITLE
                      // ==================================================

                      _buildListHeader(
                        services.length,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      // ==================================================
                      // CONTENT
                      // ==================================================

                      if (provider.loading &&
                          allServices.isEmpty)
                        _buildLoading()
                      else if (provider.error !=
                          null &&
                          allServices.isEmpty)
                        _buildError(
                          provider.error!,
                        )
                      else if (services.isEmpty)
                          _buildEmpty()
                        else
                          _buildGroupedList(
                            grouped,
                          ),
                    ],
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
  // HEADER
  // ============================================================

  Widget _buildHeader({
    required int activeCount,
    required int waitingCount,
    required int completedCount,
  }) {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        18,
      ),
      decoration:
      BoxDecoration(
        gradient:
        LinearGradient(
          begin:
          Alignment.topLeft,
          end: Alignment
              .bottomRight,
          colors: [
            kPrimaryColor,
            const Color(
              0xFF6372D0,
            ),
          ],
        ),
        borderRadius:
        BorderRadius.circular(
          26,
        ),
        boxShadow: [
          BoxShadow(
            color:
            kPrimaryColor
                .withValues(
              alpha: 0.18,
            ),
            blurRadius:
            24,
            offset:
            const Offset(
              0,
              10,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment
            .start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration:
                BoxDecoration(
                  color: Colors.white
                      .withValues(
                    alpha: 0.15,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    16,
                  ),
                ),
                child:
                const Icon(
                  Iconsax.setting_2,
                  color:
                  Colors.white,
                  size: 22,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child:
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      'Servis',
                      style:
                      whiteTextStyle
                          .copyWith(
                        fontSize: 19,
                        fontWeight:
                        bold,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      'Pantau permintaan dan pekerjaan teknisi',
                      style:
                      whiteTextStyle
                          .copyWith(
                        fontSize:
                        10.5,
                        color: Colors
                            .white
                            .withValues(
                          alpha:
                          0.78,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          Row(
            children: [
              Expanded(
                child:
                _buildHeaderStat(
                  icon:
                  Iconsax.activity,
                  value:
                  activeCount
                      .toString(),
                  label:
                  'Berjalan',
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child:
                _buildHeaderStat(
                  icon: Iconsax
                      .clock,
                  value:
                  waitingCount
                      .toString(),
                  label:
                  'Menunggu',
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child:
                _buildHeaderStat(
                  icon: Iconsax
                      .tick_circle,
                  value:
                  completedCount
                      .toString(),
                  label:
                  'Selesai',
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
  }) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 9,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.white
            .withValues(
          alpha: 0.13,
        ),
        borderRadius:
        BorderRadius.circular(
          15,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color:
            Colors.white,
            size: 16,
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            value,
            style:
            whiteTextStyle
                .copyWith(
              fontSize: 15,
              fontWeight: bold,
            ),
          ),

          const SizedBox(
            height: 2,
          ),

          Text(
            label,
            maxLines: 1,
            overflow:
            TextOverflow
                .ellipsis,
            style:
            whiteTextStyle
                .copyWith(
              fontSize: 8,
              color:
              Colors.white
                  .withValues(
                alpha: 0.72,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTabs({
    required int activeCount,
    required int historyCount,
    required int allCount,
  }) {
    return Container(
      padding:
      const EdgeInsets.all(
        5,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(
              alpha: 0.025,
            ),
            blurRadius:
            12,
            offset:
            const Offset(
              0,
              5,
            ),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child:
            _buildTabItem(
              index: 0,
              label:
              'Berjalan',
              count:
              activeCount,
            ),
          ),

          Expanded(
            child:
            _buildTabItem(
              index: 1,
              label:
              'Riwayat',
              count:
              historyCount,
            ),
          ),

          Expanded(
            child:
            _buildTabItem(
              index: 2,
              label: 'Semua',
              count:
              allCount,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required String label,
    required int count,
  }) {
    final selected =
        _selectedTab ==
            index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab =
              index;
        });
      },
      borderRadius:
      BorderRadius.circular(
        14,
      ),
      child:
      AnimatedContainer(
        duration:
        const Duration(
          milliseconds:
          180,
        ),
        padding:
        const EdgeInsets
            .symmetric(
          vertical: 10,
          horizontal: 6,
        ),
        decoration:
        BoxDecoration(
          color: selected
              ? kPrimaryColor
              .withValues(
            alpha: 0.10,
          )
              : Colors
              .transparent,
          borderRadius:
          BorderRadius
              .circular(
            14,
          ),
        ),
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment
              .center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow:
                TextOverflow
                    .ellipsis,
                style:
                TextStyle(
                  fontSize: 10,
                  fontWeight:
                  selected
                      ? FontWeight
                      .w700
                      : FontWeight
                      .w500,
                  color: selected
                      ? kPrimaryColor
                      : Colors.grey
                      .shade600,
                ),
              ),
            ),

            const SizedBox(
              width: 5,
            ),

            Container(
              constraints:
              const BoxConstraints(
                minWidth: 20,
              ),
              padding:
              const EdgeInsets
                  .symmetric(
                horizontal: 5,
                vertical: 2,
              ),
              decoration:
              BoxDecoration(
                color: selected
                    ? kPrimaryColor
                    : Colors.grey
                    .withValues(
                  alpha:
                  0.10,
                ),
                borderRadius:
                BorderRadius
                    .circular(
                  20,
                ),
              ),
              child: Text(
                count
                    .toString(),
                textAlign:
                TextAlign
                    .center,
                style:
                TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.grey
                      .shade600,
                  fontSize:
                  8,
                  fontWeight:
                  FontWeight
                      .w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearch() {
    return Container(
      height: 49,
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        border:
        Border.all(
          color:
          Colors.grey.withValues(
            alpha: 0.10,
          ),
        ),
      ),
      child: TextField(
        controller:
        _searchController,
        style:
        primaryTextStyle.copyWith(
          fontSize: 12,
        ),
        decoration:
        InputDecoration(
          hintText:
          'Cari lokasi, AC atau teknisi...',
          hintStyle:
          greyTextStyle.copyWith(
            fontSize: 10.5,
          ),
          prefixIcon: Icon(
            Iconsax.search_normal,
            color:
            kPrimaryColor,
            size: 18,
          ),
          suffixIcon:
          _query.isNotEmpty
              ? IconButton(
            onPressed: () {
              _searchController
                  .clear();
            },
            icon:
            const Icon(
              Icons
                  .close_rounded,
              size: 18,
            ),
          )
              : null,
          border:
          InputBorder.none,
        ),
      ),
    );
  }

  // ============================================================
  // TYPE FILTER
  // ============================================================

  Widget _buildJenisFilter() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection:
        Axis.horizontal,
        physics:
        const BouncingScrollPhysics(),
        children: [
          _buildJenisChip(
            label: 'Semua',
            icon:
            Iconsax.category,
            color:
            kPrimaryColor,
            selected:
            _selectedJenis ==
                null,
            onTap: () {
              setState(() {
                _selectedJenis =
                null;
              });
            },
          ),

          const SizedBox(
            width: 8,
          ),

          _buildJenisChip(
            label: 'Cuci AC',
            icon: Icons
                .cleaning_services_rounded,
            color:
            Colors.blue,
            selected:
            _selectedJenis ==
                JenisPenanganan
                    .cuci,
            onTap: () {
              setState(() {
                _selectedJenis =
                    JenisPenanganan
                        .cuci;
              });
            },
          ),

          const SizedBox(
            width: 8,
          ),

          _buildJenisChip(
            label:
            'Perbaikan',
            icon:
            Icons.build_rounded,
            color:
            Colors.orange,
            selected:
            _selectedJenis ==
                JenisPenanganan
                    .perbaikan,
            onTap: () {
              setState(() {
                _selectedJenis =
                    JenisPenanganan
                        .perbaikan;
              });
            },
          ),

          const SizedBox(
            width: 8,
          ),

          _buildJenisChip(
            label:
            'Instalasi',
            icon: Icons
                .install_desktop_rounded,
            color:
            Colors.green,
            selected:
            _selectedJenis ==
                JenisPenanganan
                    .instalasi,
            onTap: () {
              setState(() {
                _selectedJenis =
                    JenisPenanganan
                        .instalasi;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildJenisChip({
    required String label,
    required IconData icon,
    required Color color,
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
        child:
        AnimatedContainer(
          duration:
          const Duration(
            milliseconds:
            160,
          ),
          padding:
          const EdgeInsets
              .symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration:
          BoxDecoration(
            color: selected
                ? color
                : Colors.white,
            borderRadius:
            BorderRadius
                .circular(
              30,
            ),
            border:
            Border.all(
              color: selected
                  ? color
                  : Colors.grey
                  .withValues(
                alpha:
                0.15,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: selected
                    ? Colors.white
                    : color,
              ),

              const SizedBox(
                width: 6,
              ),

              Text(
                label,
                style:
                TextStyle(
                  fontSize:
                  9.5,
                  fontWeight:
                  selected
                      ? FontWeight
                      .w700
                      : FontWeight
                      .w500,
                  color: selected
                      ? Colors.white
                      : Colors.grey
                      .shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LIST HEADER
  // ============================================================

  Widget _buildListHeader(
      int count,
      ) {
    String title;

    if (_selectedTab == 0) {
      title =
      'Servis Berjalan';
    } else if (_selectedTab ==
        1) {
      title =
      'Riwayat Servis';
    } else {
      title =
      'Semua Servis';
    }

    return Row(
      children: [
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
                  fontSize: 16,
                  fontWeight: bold,
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                '$count pekerjaan ditemukan',
                style:
                greyTextStyle
                    .copyWith(
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),

        if (_selectedJenis !=
            null ||
            _query.isNotEmpty)
          TextButton(
            onPressed: () {
              _searchController
                  .clear();

              setState(() {
                _selectedJenis =
                null;
              });
            },
            child:
            const Text(
              'Reset',
              style:
              TextStyle(
                fontSize:
                10.5,
                fontWeight:
                FontWeight
                    .w700,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // GROUPED LIST
  // ============================================================

  Widget _buildGroupedList(
      Map<int, List<ServisModel>>
      grouped,
      ) {
    final entries =
    grouped.entries
        .toList();

    entries.sort(
          (a, b) {
        final dateA =
        a.value.isEmpty
            ? DateTime(2000)
            : _serviceSortDate(
          a.value.first,
        );

        final dateB =
        b.value.isEmpty
            ? DateTime(2000)
            : _serviceSortDate(
          b.value.first,
        );

        return dateB.compareTo(
          dateA,
        );
      },
    );

    return Column(
      children:
      List.generate(
        entries.length,
            (index) {
          final entry =
          entries[index];

          final locationId =
              entry.key;

          final services =
              entry.value;

          return Padding(
            padding:
            EdgeInsets.only(
              bottom:
              index ==
                  entries.length -
                      1
                  ? 0
                  : 16,
            ),
            child:
            _buildLocationGroup(
              locationId:
              locationId,
              services:
              services,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationGroup({
    required int locationId,
    required List<ServisModel> services,
  }) {
    if (services.isEmpty) {
      return const SizedBox
          .shrink();
    }

    final locationName =
        services.first.lokasiNama;

    final active =
        services
            .where(
          _isActive,
        )
            .length;

    return Container(
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          22,
        ),
        border:
        Border.all(
          color:
          kPrimaryColor
              .withValues(
            alpha: 0.07,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black
                .withValues(
              alpha: 0.025,
            ),
            blurRadius:
            16,
            offset:
            const Offset(
              0,
              6,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          // ====================================================
          // GROUP HEADER
          // ====================================================

          Padding(
            padding:
            const EdgeInsets
                .fromLTRB(
              15,
              14,
              12,
              11,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration:
                  BoxDecoration(
                    color: kPrimaryColor
                        .withValues(
                      alpha: 0.08,
                    ),
                    borderRadius:
                    BorderRadius
                        .circular(
                      13,
                    ),
                  ),
                  child: Icon(
                    Iconsax
                        .location,
                    color:
                    kPrimaryColor,
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
                    CrossAxisAlignment
                        .start,
                    children: [
                      Text(
                        locationName,
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

                      const SizedBox(
                        height: 2,
                      ),

                      Text(
                        active > 0
                            ? '$active pekerjaan berjalan'
                            : '${services.length} riwayat pekerjaan',
                        style:
                        greyTextStyle
                            .copyWith(
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),

                TextButton(
                  onPressed: () =>
                      _openLocationHistory(
                        locationId,
                      ),
                  style:
                  TextButton
                      .styleFrom(
                    foregroundColor:
                    kPrimaryColor,
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal:
                      8,
                      vertical:
                      6,
                    ),
                    minimumSize:
                    Size.zero,
                    tapTargetSize:
                    MaterialTapTargetSize
                        .shrinkWrap,
                  ),
                  child:
                  const Text(
                    'Riwayat Lokasi',
                    style:
                    TextStyle(
                      fontSize:
                      9.5,
                      fontWeight:
                      FontWeight
                          .w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color:
            Colors.grey.withValues(
              alpha: 0.08,
            ),
          ),

          // ====================================================
          // SERVICES
          // ====================================================

          ...List.generate(
            services.length,
                (index) {
              return Column(
                children: [
                  _buildServiceCard(
                    services[index],
                  ),

                  if (index !=
                      services.length -
                          1)
                    Padding(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal:
                        15,
                      ),
                      child:
                      Divider(
                        height:
                        1,
                        color: Colors
                            .grey
                            .withValues(
                          alpha:
                          0.08,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SERVICE CARD
  // ============================================================

  Widget _buildServiceCard(
      ServisModel servis,
      ) {
    final status =
    _effectiveStatus(
      servis,
    );

    final statusColor =
    _statusColor(
      status,
    );

    final typeColor =
    _jenisColor(
      servis.jenis,
    );

    final unitCount =
    servis.itemsData.isNotEmpty
        ? servis.itemsData.length
        : servis.jumlahAc;

    return Material(
      color:
      Colors.transparent,
      child: InkWell(
        onTap: () =>
            _openDetail(
              servis,
            ),
        child: Padding(
          padding:
          const EdgeInsets.all(
            15,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              // ==================================================
              // STATUS + TYPE
              // ==================================================

              Row(
                children: [
                  _buildSmallBadge(
                    icon:
                    _jenisIcon(
                      servis.jenis,
                    ),
                    text: servis
                        .jenisDisplay,
                    color:
                    typeColor,
                  ),

                  const Spacer(),

                  _buildSmallBadge(
                    icon:
                    _statusIcon(
                      status,
                    ),
                    text:
                    _statusText(
                      status,
                    ),
                    color:
                    statusColor,
                  ),
                ],
              ),

              const SizedBox(
                height: 12,
              ),

              // ==================================================
              // MAIN
              // ==================================================

              Row(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration:
                    BoxDecoration(
                      color: typeColor
                          .withValues(
                        alpha: 0.08,
                      ),
                      borderRadius:
                      BorderRadius
                          .circular(
                        14,
                      ),
                    ),
                    child: Icon(
                      _jenisIcon(
                        servis.jenis,
                      ),
                      color:
                      typeColor,
                      size: 20,
                    ),
                  ),

                  const SizedBox(
                    width: 11,
                  ),

                  Expanded(
                    child:
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Text(
                          _serviceTitle(
                            servis,
                          ),
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          primaryTextStyle
                              .copyWith(
                            fontSize:
                            13,
                            fontWeight:
                            bold,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          _acDisplay(
                            servis,
                          ),
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          greyTextStyle
                              .copyWith(
                            fontSize:
                            9.5,
                          ),
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        Wrap(
                          spacing: 7,
                          runSpacing: 6,
                          children: [
                            _buildMetaBadge(
                              icon: Icons
                                  .ac_unit_rounded,
                              text:
                              '$unitCount unit',
                            ),

                            _buildMetaBadge(
                              icon:
                              Iconsax.user,
                              text:
                              _technicianDisplay(
                                servis,
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

                  Icon(
                    Icons
                        .arrow_forward_ios_rounded,
                    size: 13,
                    color:
                    Colors.grey
                        .shade400,
                  ),
                ],
              ),

              const SizedBox(
                height: 12,
              ),

              // ==================================================
              // SCHEDULE
              // ==================================================

              Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                decoration:
                BoxDecoration(
                  color: Colors.grey
                      .withValues(
                    alpha: 0.045,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    12,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax
                          .calendar_1,
                      size: 15,
                      color:
                      kPrimaryColor,
                    ),

                    const SizedBox(
                      width: 7,
                    ),

                    Text(
                      'Jadwal',
                      style:
                      greyTextStyle
                          .copyWith(
                        fontSize:
                        8.5,
                      ),
                    ),

                    const Spacer(),

                    Text(
                      _formatDateTime(
                        servis
                            .tanggalBerkunjung ??
                            servis
                                .tanggalDitugaskan,
                      ),
                      style:
                      primaryTextStyle
                          .copyWith(
                        fontSize:
                        9.5,
                        fontWeight:
                        medium,
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

  Widget _buildSmallBadge({
    required IconData icon,
    required String text,
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
          20,
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
            text,
            style:
            TextStyle(
              fontSize: 8.5,
              color: color,
              fontWeight:
              FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaBadge({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration:
      BoxDecoration(
        color:
        kPrimaryColor
            .withValues(
          alpha: 0.05,
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
            icon,
            size: 10,
            color:
            kPrimaryColor,
          ),

          const SizedBox(
            width: 4,
          ),

          ConstrainedBox(
            constraints:
            const BoxConstraints(
              maxWidth: 130,
            ),
            child: Text(
              text,
              maxLines: 1,
              overflow:
              TextOverflow
                  .ellipsis,
              style:
              TextStyle(
                fontSize: 8,
                color:
                kPrimaryColor,
                fontWeight:
                FontWeight
                    .w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS - SERVICE
  // ============================================================

  String _serviceTitle(
      ServisModel servis,
      ) {
    switch (servis.jenis) {
      case JenisPenanganan.cuci:
        return 'Cuci AC';

      case JenisPenanganan.perbaikan:
        return 'Perbaikan AC';

      case JenisPenanganan.instalasi:
        return 'Instalasi AC';
    }
  }

  List<String> _acNames(
      ServisModel servis,
      ) {
    final names =
    <String>[];

    if (servis.acData != null) {
      final name =
      (servis.acData!['name'] ??
          '')
          .toString()
          .trim();

      if (name.isNotEmpty) {
        names.add(name);
      }
    }

    for (final item
    in servis.itemsData) {
      final ac =
      item['ac_unit'];

      if (ac is Map) {
        final name =
        (ac['name'] ?? '')
            .toString()
            .trim();

        if (name.isNotEmpty &&
            !names.contains(
              name,
            )) {
          names.add(name);
        }
      }
    }

    return names;
  }

  String _acDisplay(
      ServisModel servis,
      ) {
    if (servis.jenis ==
        JenisPenanganan
            .instalasi) {
      if (servis.jumlahAc > 0) {
        return 'Instalasi ${servis.jumlahAc} unit AC';
      }

      return 'Pekerjaan instalasi AC';
    }

    final names =
    _acNames(
      servis,
    );

    if (names.isEmpty) {
      final count =
      servis.itemsData.isNotEmpty
          ? servis.itemsData
          .length
          : servis.jumlahAc;

      return count > 0
          ? '$count unit AC'
          : 'Unit AC';
    }

    if (names.length == 1) {
      return names.first;
    }

    if (names.length == 2) {
      return names.join(
        ', ',
      );
    }

    return '${names.first} +${names.length - 1} unit';
  }

  List<String> _technicianNames(
      ServisModel servis,
      ) {
    final names =
    <String>[];

    for (final technician
    in servis
        .techniciansData) {
      final name =
      (technician['name'] ??
          technician['nama'] ??
          '')
          .toString()
          .trim();

      if (name.isNotEmpty &&
          !names.contains(
            name,
          )) {
        names.add(name);
      }
    }

    final legacy =
    (servis.teknisiData?[
    'name'] ??
        servis.teknisiData?[
        'nama'] ??
        '')
        .toString()
        .trim();

    if (legacy.isNotEmpty &&
        !names.contains(
          legacy,
        )) {
      names.add(legacy);
    }

    for (final item
    in servis.itemsData) {
      final tech =
      item['technician'];

      if (tech is Map) {
        final name =
        (tech['name'] ??
            tech['nama'] ??
            '')
            .toString()
            .trim();

        if (name.isNotEmpty &&
            !names.contains(
              name,
            )) {
          names.add(name);
        }
      }
    }

    return names;
  }

  String _technicianDisplay(
      ServisModel servis,
      ) {
    final names =
    _technicianNames(
      servis,
    );

    if (names.isNotEmpty) {
      if (names.length == 1) {
        return names.first;
      }

      return '${names.first} +${names.length - 1}';
    }

    final assigned =
    servis.itemsData.any(
          (item) {
        final id =
        item[
        'technician_id'];

        return id != null &&
            id
                .toString()
                .trim()
                .isNotEmpty;
      },
    );

    return assigned
        ? 'Teknisi ditugaskan'
        : 'Belum ditugaskan';
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _statusText(
      ServisStatus status,
      ) {
    switch (status) {
      case ServisStatus
          .menungguKonfirmasi:
        return 'Menunggu';

      case ServisStatus
          .ditugaskan:
        return 'Ditugaskan';

      case ServisStatus
          .dikerjakan:
        return 'Dikerjakan';

      case ServisStatus
          .selesai:
        return 'Selesai';

      case ServisStatus
          .batal:
        return 'Dibatalkan';
    }
  }

  Color _statusColor(
      ServisStatus status,
      ) {
    switch (status) {
      case ServisStatus
          .menungguKonfirmasi:
        return Colors.orange;

      case ServisStatus
          .ditugaskan:
        return Colors.blue;

      case ServisStatus
          .dikerjakan:
        return Colors.purple;

      case ServisStatus
          .selesai:
        return Colors.green;

      case ServisStatus
          .batal:
        return Colors.red;
    }
  }

  IconData _statusIcon(
      ServisStatus status,
      ) {
    switch (status) {
      case ServisStatus
          .menungguKonfirmasi:
        return Iconsax.clock;

      case ServisStatus
          .ditugaskan:
        return Iconsax.user_tick;

      case ServisStatus
          .dikerjakan:
        return Iconsax.setting_2;

      case ServisStatus
          .selesai:
        return Iconsax.tick_circle;

      case ServisStatus
          .batal:
        return Iconsax.close_circle;
    }
  }

  // ============================================================
  // TYPE
  // ============================================================

  Color _jenisColor(
      JenisPenanganan jenis,
      ) {
    switch (jenis) {
      case JenisPenanganan.cuci:
        return Colors.blue;

      case JenisPenanganan
          .perbaikan:
        return Colors.orange;

      case JenisPenanganan
          .instalasi:
        return Colors.green;
    }
  }

  IconData _jenisIcon(
      JenisPenanganan jenis,
      ) {
    switch (jenis) {
      case JenisPenanganan.cuci:
        return Icons
            .cleaning_services_rounded;

      case JenisPenanganan
          .perbaikan:
        return Icons
            .build_rounded;

      case JenisPenanganan
          .instalasi:
        return Icons
            .install_desktop_rounded;
    }
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDateTime(
      DateTime? date,
      ) {
    if (date == null) {
      return 'Belum dijadwalkan';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    final dateText =
        '${date.day} ${months[date.month - 1]} ${date.year}';

    final timeText =
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';

    if (date.hour == 0 &&
        date.minute == 0) {
      return dateText;
    }

    return '$dateText • $timeText';
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return Container(
      height: 180,
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          22,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment
              .center,
          children: [
            CircularProgressIndicator(
              color:
              kPrimaryColor,
              strokeWidth:
              2.5,
            ),

            const SizedBox(
              height: 13,
            ),

            Text(
              'Memuat data servis...',
              style:
              greyTextStyle
                  .copyWith(
                fontSize:
                10.5,
              ),
            ),
          ],
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
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        26,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          22,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration:
            BoxDecoration(
              color:
              Colors.red
                  .withValues(
                alpha: 0.08,
              ),
              borderRadius:
              BorderRadius
                  .circular(
                18,
              ),
            ),
            child:
            const Icon(
              Icons
                  .error_outline_rounded,
              color:
              Colors.red,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            'Gagal Memuat Servis',
            style:
            primaryTextStyle
                .copyWith(
              fontSize: 14,
              fontWeight: bold,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            message,
            textAlign:
            TextAlign.center,
            style:
            greyTextStyle
                .copyWith(
              fontSize: 10,
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          ElevatedButton.icon(
            onPressed:
            _refresh,
            icon:
            const Icon(
              Iconsax.refresh,
              size: 16,
            ),
            label:
            const Text(
              'Coba Lagi',
            ),
            style:
            ElevatedButton
                .styleFrom(
              backgroundColor:
              kPrimaryColor,
              foregroundColor:
              Colors.white,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    String title;
    String subtitle;
    IconData icon;

    if (_selectedTab == 0) {
      title =
      'Tidak Ada Servis Berjalan';

      subtitle =
      'Saat ini tidak ada pekerjaan servis yang sedang diproses.';

      icon =
          Iconsax.tick_circle;
    } else if (_selectedTab ==
        1) {
      title =
      'Belum Ada Riwayat';

      subtitle =
      'Riwayat servis yang selesai atau dibatalkan akan tampil di sini.';

      icon =
          Iconsax.clock;
    } else {
      title =
      'Servis Tidak Ditemukan';

      subtitle =
      'Coba ubah pencarian atau filter jenis servis.';

      icon =
          Iconsax.search_status;
    }

    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets
          .symmetric(
        horizontal: 24,
        vertical: 32,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          22,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration:
            BoxDecoration(
              color: kPrimaryColor
                  .withValues(
                alpha: 0.08,
              ),
              borderRadius:
              BorderRadius
                  .circular(
                19,
              ),
            ),
            child: Icon(
              icon,
              color:
              kPrimaryColor,
              size: 26,
            ),
          ),

          const SizedBox(
            height: 13,
          ),

          Text(
            title,
            style:
            primaryTextStyle
                .copyWith(
              fontSize: 14,
              fontWeight: bold,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            subtitle,
            textAlign:
            TextAlign.center,
            style:
            greyTextStyle
                .copyWith(
              fontSize: 10.5,
              height: 1.4,
            ),
          ),

          if (_query.isNotEmpty ||
              _selectedJenis !=
                  null) ...[
            const SizedBox(
              height: 12,
            ),

            TextButton.icon(
              onPressed: () {
                _searchController
                    .clear();

                setState(() {
                  _selectedJenis =
                  null;
                });
              },
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
    );
  }
}