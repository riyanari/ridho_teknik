import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/ac_model.dart';
import '../../models/lokasi_model.dart';
import '../../providers/client_ac_provider.dart';
import '../../theme/theme.dart';

import 'cuci_ac_page.dart';
import 'keluhan_create_page.dart';
import 'servis_history_page.dart';

class AcListPage extends StatefulWidget {
  final LokasiModel lokasi;

  const AcListPage({
    super.key,
    required this.lokasi,
  });

  @override
  State<AcListPage> createState() => _AcListPageState();
}

class _AcListPageState extends State<AcListPage> {
  final TextEditingController _searchController =
  TextEditingController();

  int? _selectedFloor;

  static const int _defaultServiceIntervalMonths = 3;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _loadData() async {
    await context.read<ClientAcProvider>().fetchAc(
      locationId: widget.lokasi.id,
    );
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  // ============================================================
  // FILTER
  // ============================================================

  void _onSearchChanged() {
    setState(() {});
  }

  List<AcModel> _getFilteredList(
      List<AcModel> source,
      ) {
    final query =
    _searchController.text.trim().toLowerCase();

    return source.where((ac) {
      final roomName =
      (ac.room?.name ?? '').toLowerCase();

      final matchesSearch =
          query.isEmpty ||
              ac.nama.toLowerCase().contains(query) ||
              ac.merk.toLowerCase().contains(query) ||
              ac.type.toLowerCase().contains(query) ||
              ac.kapasitas.toLowerCase().contains(query) ||
              roomName.contains(query);

      final matchesFloor =
          _selectedFloor == null ||
              ac.lantai == _selectedFloor;

      return matchesSearch && matchesFloor;
    }).toList();
  }

  List<int> _extractFloors(
      List<AcModel> list,
      ) {
    final floors = list
        .map((ac) => ac.lantai)
        .where((floor) => floor > 0)
        .toSet()
        .toList()
      ..sort();

    return floors;
  }

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _selectedFloor = null;
    });
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServisHistoryPage(
          lokasi: widget.lokasi,
        ),
      ),
    );
  }

  void _openCuciMultiple(
      List<AcModel> acList,
      ) {
    if (acList.isEmpty) {
      _showSnackBar(
        'Tidak ada AC pada lokasi ini.',
        Colors.orange,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CuciAcPage(
          lokasi: widget.lokasi,
          acList: acList,
        ),
      ),
    );
  }

  void _openCuciSingle(
      AcModel ac,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CuciAcPage(
          lokasi: widget.lokasi,
          acList: [ac],
        ),
      ),
    );
  }

  void _openComplaint(
      AcModel ac,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KeluhanCreatePage(
          ac: ac,
          lokasi: widget.lokasi,
        ),
      ),
    );
  }

  void _showSnackBar(
      String message,
      Color color,
      ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Consumer<ClientAcProvider>(
          builder: (context, provider, _) {
            final allAc = provider.ac;
            final filteredAc =
            _getFilteredList(allAc);

            final floorOptions =
            _extractFloors(allAc);

            final needServiceCount =
                allAc.where((ac) {
                  final status =
                  _getMaintenanceStatus(ac);

                  return status.type ==
                      _AcMaintenanceType.overdue ||
                      status.type ==
                          _AcMaintenanceType.neverServiced;
                }).length;

            return RefreshIndicator(
              color: kPrimaryColor,
              onRefresh: _refresh,
              child: CustomScrollView(
                physics:
                const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHeader(
                      totalAc: allAc.length,
                      needService:
                      needServiceCount,
                    ),
                  ),

                  if (provider.loading &&
                      allAc.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildLoading(),
                    )
                  else if (provider.error != null &&
                      allAc.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildError(
                        provider.error!,
                      ),
                    )
                  else ...[
                      SliverPadding(
                        padding:
                        const EdgeInsets.fromLTRB(
                          20,
                          20,
                          20,
                          0,
                        ),
                        sliver:
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              _buildActionSection(
                                allAc,
                              ),

                              const SizedBox(
                                height: 24,
                              ),

                              _buildSearchField(),

                              const SizedBox(
                                height: 14,
                              ),

                              if (floorOptions
                                  .isNotEmpty)
                                _buildFloorFilter(
                                  floorOptions,
                                ),

                              if (floorOptions
                                  .isNotEmpty)
                                const SizedBox(
                                  height: 22,
                                ),

                              _buildListHeader(
                                filteredAc.length,
                              ),

                              const SizedBox(
                                height: 14,
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (filteredAc.isEmpty)
                        SliverPadding(
                          padding:
                          const EdgeInsets.fromLTRB(
                            20,
                            10,
                            20,
                            100,
                          ),
                          sliver:
                          SliverToBoxAdapter(
                            child:
                            _buildEmptyFiltered(),
                          ),
                        )
                      else
                        SliverPadding(
                          padding:
                          const EdgeInsets.fromLTRB(
                            20,
                            0,
                            20,
                            110,
                          ),
                          sliver:
                          SliverList.separated(
                            itemCount:
                            filteredAc.length,
                            separatorBuilder:
                                (_, __) =>
                            const SizedBox(
                              height: 12,
                            ),
                            itemBuilder:
                                (context, index) {
                              return _buildAcCard(
                                filteredAc[index],
                              );
                            },
                          ),
                        ),
                    ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader({
    required int totalAc,
    required int needService,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        20,
        14,
        20,
        0,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kPrimaryColor,
            const Color(0xFF6372D0),
          ],
        ),
        borderRadius:
        BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor
                .withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () =>
                      Navigator.pop(context),
                  borderRadius:
                  BorderRadius.circular(15),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration:
                    BoxDecoration(
                      color: Colors.white
                          .withValues(
                        alpha: 0.14,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        15,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
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
                      widget.lokasi.nama,
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      whiteTextStyle.copyWith(
                        fontSize: 18,
                        fontWeight: bold,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 5),

                    if (widget.lokasi.alamat
                        .trim()
                        .isNotEmpty)
                      Text(
                        widget.lokasi.alamat,
                        maxLines: 2,
                        overflow:
                        TextOverflow.ellipsis,
                        style:
                        whiteTextStyle.copyWith(
                          fontSize: 10.5,
                          height: 1.35,
                          color: Colors.white
                              .withValues(
                            alpha: 0.72,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _buildHeaderInfo(
                  icon:
                  Icons.ac_unit_rounded,
                  value:
                  totalAc.toString(),
                  label: 'Unit AC',
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _buildHeaderInfo(
                  icon: Icons
                      .warning_amber_rounded,
                  value: needService
                      .toString(),
                  label:
                  'Perlu Perhatian',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white
            .withValues(alpha: 0.13),
        borderRadius:
        BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration:
            BoxDecoration(
              color: Colors.white
                  .withValues(
                alpha: 0.14,
              ),
              borderRadius:
              BorderRadius.circular(
                11,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 17,
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style:
                  whiteTextStyle.copyWith(
                    fontSize: 16,
                    fontWeight: bold,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  whiteTextStyle.copyWith(
                    fontSize: 9,
                    color: Colors.white
                        .withValues(
                      alpha: 0.70,
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

  // ============================================================
  // TOP ACTIONS
  // ============================================================

  Widget _buildActionSection(
      List<AcModel> allAc,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          'Layanan',
          style: primaryTextStyle.copyWith(
            fontSize: 16,
            fontWeight: bold,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          'Pilih layanan untuk lokasi ini',
          style: greyTextStyle.copyWith(
            fontSize: 10.5,
          ),
        ),

        const SizedBox(height: 13),

        Row(
          children: [
            Expanded(
              child:
              _buildCompactActionCard(
                icon: Icons
                    .cleaning_services_rounded,
                title:
                'Cuci Beberapa',
                subtitle:
                'Pilih satu / banyak AC',
                color:
                kPrimaryColor,
                filled: true,
                onTap: () =>
                    _openCuciMultiple(
                      allAc,
                    ),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child:
              _buildCompactActionCard(
                icon: Iconsax.clock,
                title: 'Riwayat',
                subtitle:
                'Servis lokasi ini',
                color:
                kSecondaryColor,
                filled: false,
                onTap: _openHistory,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(18),
        child: Ink(
          height: 76,
          padding:
          const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            gradient: filled
                ? LinearGradient(
              begin:
              Alignment.topLeft,
              end: Alignment
                  .bottomRight,
              colors: [
                color,
                const Color(
                  0xFF6372D0,
                ),
              ],
            )
                : LinearGradient(
              colors: [
                color.withValues(
                  alpha: 0.08,
                ),
                Colors.white,
              ],
            ),
            borderRadius:
            BorderRadius.circular(18),
            border: Border.all(
              color: filled
                  ? Colors.transparent
                  : color.withValues(
                alpha: 0.10,
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
                  color: filled
                      ? Colors.white
                      .withValues(
                    alpha: 0.16,
                  )
                      : color.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    13,
                  ),
                ),
                child: Icon(
                  icon,
                  color: filled
                      ? Colors.white
                      : color,
                  size: 19,
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: filled
                          ? whiteTextStyle
                          .copyWith(
                        fontSize: 11.5,
                        fontWeight: bold,
                      )
                          : primaryTextStyle
                          .copyWith(
                        fontSize: 11.5,
                        fontWeight: bold,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: filled
                          ? whiteTextStyle
                          .copyWith(
                        fontSize: 8,
                        color:
                        Colors.white
                            .withValues(
                          alpha: 0.74,
                        ),
                      )
                          : greyTextStyle
                          .copyWith(
                        fontSize: 8,
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

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearchField() {
    final hasText =
        _searchController.text
            .trim()
            .isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey
              .withValues(alpha: 0.10),
        ),
      ),
      child: TextField(
        controller:
        _searchController,
        style:
        primaryTextStyle.copyWith(
          fontSize: 13,
        ),
        decoration: InputDecoration(
          hintText:
          'Cari nama, merk, tipe atau ruang...',
          hintStyle:
          greyTextStyle.copyWith(
            fontSize: 11,
          ),
          prefixIcon: Icon(
            Iconsax.search_normal,
            color: kPrimaryColor,
            size: 19,
          ),
          suffixIcon: hasText
              ? IconButton(
            onPressed: () {
              _searchController
                  .clear();
            },
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: Colors
                  .grey.shade500,
            ),
          )
              : null,
          border: InputBorder.none,
        ),
      ),
    );
  }

  // ============================================================
  // FLOOR
  // ============================================================

  Widget _buildFloorFilter(
      List<int> floors,
      ) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection:
        Axis.horizontal,
        children: [
          _buildFloorChip(
            label: 'Semua',
            selected:
            _selectedFloor == null,
            onTap: () {
              setState(() {
                _selectedFloor = null;
              });
            },
          ),

          const SizedBox(width: 8),

          ...floors.expand(
                (floor) => [
              _buildFloorChip(
                label:
                'Lantai $floor',
                selected:
                _selectedFloor ==
                    floor,
                onTap: () {
                  setState(() {
                    _selectedFloor =
                        floor;
                  });
                },
              ),
              const SizedBox(width: 8),
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(30),
        child: AnimatedContainer(
          duration:
          const Duration(
            milliseconds: 180,
          ),
          padding:
          const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: selected
                ? kPrimaryColor
                : Colors.white,
            borderRadius:
            BorderRadius.circular(30),
            border: Border.all(
              color: selected
                  ? kPrimaryColor
                  : Colors.grey
                  .withValues(
                alpha: 0.15,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: selected
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: selected
                  ? Colors.white
                  : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LIST HEADER
  // ============================================================

  Widget _buildListHeader(
      int total,
      ) {
    final hasFilter =
        _searchController.text
            .trim()
            .isNotEmpty ||
            _selectedFloor != null;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'Unit AC',
                style:
                primaryTextStyle.copyWith(
                  fontSize: 16,
                  fontWeight: bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$total unit ditemukan',
                style:
                greyTextStyle.copyWith(
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),

        if (hasFilter)
          TextButton(
            onPressed: _clearFilters,
            child: Text(
              'Reset Filter',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight:
                FontWeight.w700,
                color:
                kPrimaryColor,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // AC CARD
  // ============================================================

  Widget _buildAcCard(
      AcModel ac,
      ) {
    final maintenance =
    _getMaintenanceStatus(ac);

    final roomName =
        ac.room?.name.trim() ?? '';

    final nextService =
    _getNextServiceDate(ac);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            maintenance.softColor,
            Colors.white,
          ],
        ),
        borderRadius:
        BorderRadius.circular(22),
        border: Border.all(
          color: maintenance.color
              .withValues(alpha: 0.13),
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
              Container(
                width: 46,
                height: 46,
                decoration:
                BoxDecoration(
                  color: maintenance.color
                      .withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    15,
                  ),
                ),
                child: Icon(
                  Icons.ac_unit_rounded,
                  size: 22,
                  color:
                  maintenance.color,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      ac.nama.trim().isEmpty
                          ? 'Unit AC #${ac.id}'
                          : ac.nama,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      primaryTextStyle.copyWith(
                        fontSize: 14,
                        fontWeight: bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _buildAcDescription(
                        ac,
                      ),
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

              const SizedBox(width: 8),

              _buildStatusBadge(
                maintenance,
              ),
            ],
          ),

          const SizedBox(height: 13),

          Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white
                  .withValues(alpha: 0.70),
              borderRadius:
              BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.location,
                  size: 15,
                  color:
                  Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    roomName.isNotEmpty
                        ? roomName
                        : ac.lantai > 0
                        ? 'Lantai ${ac.lantai}'
                        : 'Lokasi unit belum ditentukan',
                    style:
                    primaryTextStyle.copyWith(
                      fontSize: 10.5,
                      fontWeight: medium,
                    ),
                  ),
                ),
                if (ac.lantai > 0)
                  Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration:
                    BoxDecoration(
                      color: kPrimaryColor
                          .withValues(
                        alpha: 0.07,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: Text(
                      'Lantai ${ac.lantai}',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight:
                        FontWeight.w600,
                        color:
                        kPrimaryColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child:
                _buildServiceInfoBox(
                  icon:
                  Iconsax.tick_circle,
                  title:
                  'Terakhir Servis',
                  value:
                  ac.terakhirService != null
                      ? _formatDate(
                    ac.terakhirService!,
                  )
                      : 'Belum pernah',
                  color: const Color(
                    0xFF3C9B71,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child:
                _buildServiceInfoBox(
                  icon:
                  Iconsax.calendar_1,
                  title:
                  'Servis Berikutnya',
                  value:
                  nextService != null
                      ? _formatDate(
                    nextService,
                  )
                      : 'Belum tersedia',
                  color:
                  maintenance.color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ====================================================
          // EXPLICIT ACTIONS
          // ====================================================

          Row(
            children: [
              Expanded(
                child: _buildAcActionButton(
                  icon: Icons
                      .cleaning_services_rounded,
                  label: 'Cuci AC',
                  color:
                  kPrimaryColor,
                  filled: true,
                  onTap: () =>
                      _openCuciSingle(ac),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _buildAcActionButton(
                  icon:
                  Iconsax.message_question,
                  label:
                  'Laporkan Masalah',
                  color:
                  Colors.orange,
                  filled: false,
                  onTap: () =>
                      _openComplaint(ac),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            _getMaintenanceMessage(ac),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight:
              FontWeight.w600,
              color:
              maintenance.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(13),
        child: Ink(
          height: 40,
          decoration: BoxDecoration(
            color: filled
                ? color
                : color.withValues(
              alpha: 0.07,
            ),
            borderRadius:
            BorderRadius.circular(13),
            border: Border.all(
              color: filled
                  ? color
                  : color.withValues(
                alpha: 0.15,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: filled
                    ? Colors.white
                    : color,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight:
                    FontWeight.w700,
                    color: filled
                        ? Colors.white
                        : color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildAcDescription(
      AcModel ac,
      ) {
    final parts = <String>[];

    if (ac.merk.trim().isNotEmpty &&
        ac.merk != 'Unknown') {
      parts.add(ac.merk);
    }

    if (ac.type.trim().isNotEmpty &&
        ac.type != '-') {
      parts.add(ac.type);
    }

    if (ac.kapasitas.trim().isNotEmpty &&
        ac.kapasitas != '-') {
      parts.add(ac.kapasitas);
    }

    return parts.isEmpty
        ? 'Informasi AC belum lengkap'
        : parts.join(' • ');
  }

  Widget _buildServiceInfoBox({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white
            .withValues(alpha: 0.70),
        borderRadius:
        BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration:
            BoxDecoration(
              color: color.withValues(
                alpha: 0.09,
              ),
              borderRadius:
              BorderRadius.circular(
                10,
              ),
            ),
            child: Icon(
              icon,
              size: 15,
              color: color,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                  greyTextStyle.copyWith(
                    fontSize: 8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  primaryTextStyle.copyWith(
                    fontSize: 9.5,
                    fontWeight: bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(
      _AcMaintenanceStatus status,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: status.color
            .withValues(alpha: 0.08),
        borderRadius:
        BorderRadius.circular(30),
        border: Border.all(
          color: status.color
              .withValues(alpha: 0.16),
        ),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: 8.5,
          fontWeight:
          FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // MAINTENANCE
  // ============================================================

  _AcMaintenanceStatus
  _getMaintenanceStatus(
      AcModel ac,
      ) {
    final last =
        ac.terakhirService;

    if (last == null) {
      return const _AcMaintenanceStatus(
        type:
        _AcMaintenanceType.neverServiced,
        label: 'Belum Servis',
        color: Colors.blueGrey,
        softColor:
        Color(0xFFF4F6F8),
      );
    }

    final next =
    _getNextServiceDate(ac);

    if (next == null) {
      return const _AcMaintenanceStatus(
        type:
        _AcMaintenanceType.normal,
        label: 'Aman',
        color: Colors.green,
        softColor:
        Color(0xFFF3FAF6),
      );
    }

    final days = _dateOnly(next)
        .difference(
      _dateOnly(DateTime.now()),
    )
        .inDays;

    if (days <= 0) {
      return const _AcMaintenanceStatus(
        type:
        _AcMaintenanceType.overdue,
        label: 'Perlu Servis',
        color: Colors.red,
        softColor:
        Color(0xFFFFF5F5),
      );
    }

    if (days <= 14) {
      return const _AcMaintenanceStatus(
        type:
        _AcMaintenanceType.upcoming,
        label: 'Segera',
        color: Colors.orange,
        softColor:
        Color(0xFFFFF8ED),
      );
    }

    return const _AcMaintenanceStatus(
      type:
      _AcMaintenanceType.normal,
      label: 'Aman',
      color: Colors.green,
      softColor:
      Color(0xFFF3FAF6),
    );
  }

  DateTime? _getNextServiceDate(
      AcModel ac,
      ) {
    final last =
        ac.terakhirService;

    if (last == null) {
      return null;
    }

    return _addMonths(
      last,
      _defaultServiceIntervalMonths,
    );
  }

  String _getMaintenanceMessage(
      AcModel ac,
      ) {
    if (ac.terakhirService == null) {
      return 'Belum memiliki riwayat servis';
    }

    final next =
    _getNextServiceDate(ac);

    if (next == null) {
      return '';
    }

    final difference =
        _dateOnly(next)
            .difference(
          _dateOnly(
            DateTime.now(),
          ),
        )
            .inDays;

    if (difference < 0) {
      return 'Lewat ${difference.abs()} hari';
    }

    if (difference == 0) {
      return 'Servis diperlukan hari ini';
    }

    if (difference == 1) {
      return 'Jadwal servis besok';
    }

    if (difference <= 14) {
      return '$difference hari menuju jadwal servis';
    }

    return 'Perawatan masih dalam jadwal';
  }

  DateTime _dateOnly(
      DateTime date,
      ) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  DateTime _addMonths(
      DateTime date,
      int months,
      ) {
    final total =
        date.year * 12 +
            date.month -
            1 +
            months;

    final year = total ~/ 12;
    final month =
        total % 12 + 1;

    final maxDay =
        DateTime(
          year,
          month + 1,
          0,
        ).day;

    final day =
    date.day > maxDay
        ? maxDay
        : date.day;

    return DateTime(
      year,
      month,
      day,
    );
  }

  String _formatDate(
      DateTime date,
      ) {
    return DateFormat(
      'd MMM yyyy',
      'id_ID',
    ).format(date);
  }

  // ============================================================
  // EMPTY / LOADING / ERROR
  // ============================================================

  Widget _buildEmptyFiltered() {
    final hasFilter =
        _selectedFloor != null ||
            _searchController.text
                .trim()
                .isNotEmpty;

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(
            hasFilter
                ? Iconsax.search_status
                : Icons.ac_unit_rounded,
            size: 32,
            color: kPrimaryColor,
          ),
          const SizedBox(height: 12),
          Text(
            hasFilter
                ? 'AC Tidak Ditemukan'
                : 'Belum Ada AC',
            style:
            primaryTextStyle.copyWith(
              fontWeight: bold,
            ),
          ),
          if (hasFilter) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: _clearFilters,
              child: const Text(
                'Reset Filter',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child:
      CircularProgressIndicator(
        color: kPrimaryColor,
      ),
    );
  }

  Widget _buildError(
      String message,
      ) {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 46,
              color:
              Colors.red.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign:
              TextAlign.center,
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _refresh,
              child: const Text(
                'Coba Lagi',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _AcMaintenanceType {
  normal,
  upcoming,
  overdue,
  neverServiced,
}

class _AcMaintenanceStatus {
  final _AcMaintenanceType type;
  final String label;
  final Color color;
  final Color softColor;

  const _AcMaintenanceStatus({
    required this.type,
    required this.label,
    required this.color,
    required this.softColor,
  });
}