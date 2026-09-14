// lib/pages/klien/client_ac_locations_page.dart

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../models/ac_model.dart';
import '../../models/lokasi_model.dart';
import '../../providers/client_ac_provider.dart';
import '../../providers/client_master_provider.dart';
import '../../theme/theme.dart';
import 'ac_list_page.dart';

class ClientAcLocationsPage extends StatefulWidget {
  const ClientAcLocationsPage({
    super.key,
  });

  @override
  State<ClientAcLocationsPage> createState() =>
      _ClientAcLocationsPageState();
}

class _ClientAcLocationsPageState extends State<ClientAcLocationsPage> {
  final TextEditingController _searchController =
  TextEditingController();

  String _query = '';

  // ============================================================
  // SERVICE INTERVAL
  // ============================================================
  //
  // SEMENTARA 3 BULAN.
  //
  // Nanti jika backend sudah menyediakan:
  //
  // service_interval_months
  //
  // nilai ini bisa dipindahkan ke LokasiModel.
  // ============================================================

  static const int _defaultServiceIntervalMonths = 3;

  // AC dianggap "segera servis" jika <= 14 hari.
  static const int _upcomingThresholdDays = 14;

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
    final masterProvider =
    context.read<ClientMasterProvider>();

    final acProvider =
    context.read<ClientAcProvider>();

    if (masterProvider.lokasi.isEmpty) {
      await masterProvider.fetchLokasi();
    }

    if (!mounted) return;

    await acProvider.fetchAllAcByLocations(
      masterProvider.lokasi,
    );
  }

  Future<void> _refresh() async {
    final masterProvider =
    context.read<ClientMasterProvider>();

    final acProvider =
    context.read<ClientAcProvider>();

    await masterProvider.fetchLokasi();

    if (!mounted) return;

    await acProvider.fetchAllAcByLocations(
      masterProvider.lokasi,
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _onSearchChanged() {
    setState(() {
      _query =
          _searchController.text.trim().toLowerCase();
    });
  }

  List<LokasiModel> _filterLocations(
      List<LokasiModel> locations,
      ) {
    if (_query.isEmpty) {
      return locations;
    }

    return locations.where(
          (lokasi) {
        return lokasi.nama
            .toLowerCase()
            .contains(_query) ||
            lokasi.alamat
                .toLowerCase()
                .contains(_query);
      },
    ).toList();
  }

  // ============================================================
  // OPEN LOCATION
  // ============================================================

  void _openLocation(
      LokasiModel lokasi,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AcListPage(
          lokasi: lokasi,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final masterProvider =
    context.watch<ClientMasterProvider>();

    final acProvider =
    context.watch<ClientAcProvider>();

    final locations = _filterLocations(
      masterProvider.lokasi,
    );

    final totalAc =
        acProvider.allAc.length;

    final totalLokasi =
        masterProvider.lokasi.length;

    final loading =
        (masterProvider.loading &&
            masterProvider.lokasi.isEmpty) ||
            (acProvider.loadingAll &&
                acProvider.allAc.isEmpty);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: kPrimaryColor,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics:
            const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding:
                const EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  120,
                ),
                sliver: SliverList(
                  delegate:
                  SliverChildListDelegate(
                    [
                      // ==================================================
                      // HEADER
                      // ==================================================

                      _buildHeader(
                        totalLokasi:
                        totalLokasi,
                        totalAc:
                        totalAc,
                      ),

                      const SizedBox(
                        height: 22,
                      ),

                      // ==================================================
                      // SEARCH
                      // ==================================================

                      _buildSearchField(),

                      const SizedBox(
                        height: 24,
                      ),

                      // ==================================================
                      // SECTION HEADER
                      // ==================================================

                      _buildSectionHeader(
                        locations.length,
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // ==================================================
                      // CONTENT
                      // ==================================================

                      if (loading)
                        _buildLoading()
                      else if (locations.isEmpty)
                        _buildEmpty()
                      else
                        _buildLocationList(
                          locations,
                          acProvider,
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
    required int totalLokasi,
    required int totalAc,
  }) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
            kPrimaryColor.withValues(
              alpha: 0.18,
            ),
            blurRadius: 24,
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
        CrossAxisAlignment.start,
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
                  BorderRadius.circular(
                    16,
                  ),
                ),
                child: const Icon(
                  Icons.ac_unit_rounded,
                  color: Colors.white,
                  size: 23,
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
                      'Daftar AC',
                      style:
                      whiteTextStyle
                          .copyWith(
                        fontSize: 19,
                        fontWeight: bold,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      'Pantau kondisi AC berdasarkan lokasi',
                      style:
                      whiteTextStyle
                          .copyWith(
                        fontSize: 11,
                        color: Colors.white
                            .withValues(
                          alpha: 0.78,
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
                  Iconsax.building_4,
                  value:
                  totalLokasi.toString(),
                  label: 'Lokasi',
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child:
                _buildHeaderStat(
                  icon: Icons
                      .ac_unit_rounded,
                  value:
                  totalAc.toString(),
                  label: 'Unit AC',
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
        horizontal: 13,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color:
        Colors.white.withValues(
          alpha: 0.13,
        ),
        borderRadius:
        BorderRadius.circular(
          16,
        ),
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
                  value,
                  style:
                  whiteTextStyle
                      .copyWith(
                    fontSize: 16,
                    fontWeight: bold,
                  ),
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
                    fontSize: 9.5,
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
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color:
          Colors.grey.withValues(
            alpha: 0.07,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withValues(
              alpha: 0.03,
            ),
            blurRadius: 16,
            offset:
            const Offset(
              0,
              6,
            ),
          ),
        ],
      ),
      child: TextField(
        controller:
        _searchController,
        style:
        primaryTextStyle.copyWith(
          fontSize: 12.5,
        ),
        decoration:
        InputDecoration(
          hintText:
          'Cari nama atau alamat lokasi...',
          hintStyle:
          greyTextStyle.copyWith(
            fontSize: 11.5,
          ),
          prefixIcon: Icon(
            Iconsax.search_normal,
            color: kPrimaryColor,
            size: 19,
          ),
          suffixIcon:
          _query.isNotEmpty
              ? IconButton(
            onPressed: () {
              _searchController
                  .clear();
            },
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: Colors.grey
                  .shade500,
            ),
          )
              : null,
          border:
          InputBorder.none,
          contentPadding:
          const EdgeInsets
              .symmetric(
            vertical: 15,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget _buildSectionHeader(
      int total,
      ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'Daftar Lokasi',
                style:
                primaryTextStyle.copyWith(
                  fontSize: 18,
                  fontWeight: bold,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              Text(
                'Pilih lokasi untuk melihat kondisi dan unit AC',
                style:
                greyTextStyle.copyWith(
                  fontSize: 11,
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
          decoration: BoxDecoration(
            color:
            kPrimaryColor.withValues(
              alpha: 0.08,
            ),
            borderRadius:
            BorderRadius.circular(
              20,
            ),
          ),
          child: Text(
            '$total lokasi',
            style: TextStyle(
              color: kPrimaryColor,
              fontSize: 10,
              fontWeight:
              FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOCATION LIST
  // ============================================================

  Widget _buildLocationList(
      List<LokasiModel> locations,
      ClientAcProvider acProvider,
      ) {
    return Column(
      children:
      List.generate(
        locations.length,
            (index) {
          final lokasi =
          locations[index];

          final acList =
          acProvider
              .getAcByLocation(
            lokasi.id,
          );

          return Padding(
            padding:
            EdgeInsets.only(
              bottom:
              index ==
                  locations.length -
                      1
                  ? 0
                  : 14,
            ),
            child:
            _buildLocationCard(
              lokasi: lokasi,
              acList: acList,
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // LOCATION CARD
  // ============================================================

  Widget _buildLocationCard({
    required LokasiModel lokasi,
    required List<AcModel> acList,
  }) {
    final summary =
    _buildMaintenanceSummary(
      lokasi,
      acList,
    );

    final status =
    _getLocationMaintenanceStatus(
      summary,
    );

    return Material(
      color:
      Colors.transparent,
      child: InkWell(
        onTap: () =>
            _openLocation(
              lokasi,
            ),
        borderRadius:
        BorderRadius.circular(
          24,
        ),
        child: Ink(
          width:
          double.infinity,
          padding:
          const EdgeInsets.all(
            17,
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
                status.softColor,
                Colors.white,
              ],
            ),
            borderRadius:
            BorderRadius.circular(
              24,
            ),
            border: Border.all(
              color: status.color
                  .withValues(
                alpha: 0.14,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(
                  alpha: 0.025,
                ),
                blurRadius: 18,
                offset:
                const Offset(
                  0,
                  7,
                ),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // ==================================================
              // HEADER
              // ==================================================

              Row(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration:
                    BoxDecoration(
                      color: kPrimaryColor
                          .withValues(
                        alpha: 0.09,
                      ),
                      borderRadius:
                      BorderRadius
                          .circular(
                        16,
                      ),
                    ),
                    child: Icon(
                      Iconsax.location,
                      color:
                      kPrimaryColor,
                      size: 22,
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
                          lokasi.nama,
                          maxLines: 2,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          primaryTextStyle
                              .copyWith(
                            fontSize: 14.5,
                            fontWeight:
                            bold,
                            height: 1.25,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          lokasi.alamat
                              .trim()
                              .isEmpty
                              ? 'Alamat tidak tersedia'
                              : lokasi.alamat,
                          maxLines: 2,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          greyTextStyle
                              .copyWith(
                            fontSize: 10,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  _buildMaintenanceStatusBadge(
                    status,
                  ),
                ],
              ),

              const SizedBox(
                height: 15,
              ),

              // ==================================================
              // STATS
              // ==================================================

              Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                decoration:
                BoxDecoration(
                  color: Colors.white
                      .withValues(
                    alpha: 0.74,
                  ),
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
                      _buildLocationInfo(
                        icon: Icons
                            .ac_unit_rounded,
                        label:
                        'Unit AC',
                        value: summary
                            .totalAc
                            .toString(),
                        color:
                        kPrimaryColor,
                      ),
                    ),

                    _buildVerticalDivider(),

                    Expanded(
                      child:
                      _buildLocationInfo(
                        icon:
                        Iconsax.warning_2,
                        label:
                        'Perlu Servis',
                        value: summary
                            .overdueCount
                            .toString(),
                        color:
                        Colors.red,
                      ),
                    ),

                    _buildVerticalDivider(),

                    Expanded(
                      child:
                      _buildLocationInfo(
                        icon:
                        Iconsax.clock,
                        label: 'Segera',
                        value: summary
                            .upcomingCount
                            .toString(),
                        color:
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // NEVER SERVICED
              // ==================================================

              if (summary
                  .neverServicedCount >
                  0) ...[
                const SizedBox(
                  height: 10,
                ),

                Container(
                  width:
                  double.infinity,
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    Colors.blueGrey
                        .withValues(
                      alpha: 0.055,
                    ),
                    borderRadius:
                    BorderRadius
                        .circular(
                      13,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax
                            .info_circle,
                        size: 15,
                        color: Colors
                            .blueGrey
                            .shade500,
                      ),

                      const SizedBox(
                        width: 7,
                      ),

                      Expanded(
                        child: Text(
                          '${summary.neverServicedCount} AC belum memiliki riwayat servis',
                          style:
                          TextStyle(
                            fontSize: 9.5,
                            fontWeight:
                            FontWeight
                                .w600,
                            color: Colors
                                .blueGrey
                                .shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(
                height: 12,
              ),

              // ==================================================
              // MAINTENANCE DETAIL
              // ==================================================

              Container(
                width:
                double.infinity,
                padding:
                const EdgeInsets.all(
                  13,
                ),
                decoration:
                BoxDecoration(
                  color: Colors.white
                      .withValues(
                    alpha: 0.76,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    16,
                  ),
                  border:
                  Border.all(
                    color: status.color
                        .withValues(
                      alpha: 0.07,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // ============================================
                    // NEXT SERVICE
                    // ============================================

                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration:
                          BoxDecoration(
                            color: status
                                .color
                                .withValues(
                              alpha: 0.08,
                            ),
                            borderRadius:
                            BorderRadius
                                .circular(
                              12,
                            ),
                          ),
                          child:
                          Icon(
                            Iconsax
                                .calendar_1,
                            size: 18,
                            color: status
                                .color,
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
                                'Servis berikutnya',
                                style:
                                greyTextStyle
                                    .copyWith(
                                  fontSize:
                                  8.5,
                                ),
                              ),

                              const SizedBox(
                                height:
                                3,
                              ),

                              Text(
                                _getNextServiceText(
                                  summary,
                                ),
                                maxLines:
                                1,
                                overflow:
                                TextOverflow
                                    .ellipsis,
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

                        if (summary
                            .nearestServiceDate !=
                            null)
                          Container(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal:
                              8,
                              vertical: 5,
                            ),
                            decoration:
                            BoxDecoration(
                              color: status
                                  .color
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
                            Text(
                              _getCountdownText(
                                summary
                                    .nearestServiceDate!,
                              ),
                              style:
                              TextStyle(
                                color: status
                                    .color,
                                fontSize:
                                8.5,
                                fontWeight:
                                FontWeight
                                    .w700,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Divider(
                      height: 1,
                      color: Colors.grey
                          .withValues(
                        alpha: 0.10,
                      ),
                    ),

                    const SizedBox(
                      height: 11,
                    ),

                    // ============================================
                    // LAST SERVICE + INTERVAL
                    // ============================================

                    Row(
                      children: [
                        Expanded(
                          child:
                          _buildMaintenanceMiniInfo(
                            icon:
                            Iconsax.tick_circle,
                            title:
                            'Terakhir Servis',
                            value: summary
                                .latestServiceDate !=
                                null
                                ? _formatDate(
                              summary
                                  .latestServiceDate!,
                            )
                                : 'Belum pernah',
                            color:
                            Colors.green,
                          ),
                        ),

                        Container(
                          width: 1,
                          height: 35,
                          margin:
                          const EdgeInsets
                              .symmetric(
                            horizontal:
                            10,
                          ),
                          color:
                          Colors.grey
                              .withValues(
                            alpha: 0.10,
                          ),
                        ),

                        Expanded(
                          child:
                          _buildMaintenanceMiniInfo(
                            icon:
                            Iconsax.timer_1,
                            title:
                            'Interval',
                            value:
                            'Setiap ${summary.intervalMonths} bulan',
                            color:
                            kPrimaryColor,
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

              // ==================================================
              // FOOTER
              // ==================================================

              Row(
                children: [
                  Expanded(
                    child: Text(
                      _getMaintenanceMessage(
                        summary,
                      ),
                      maxLines: 1,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style:
                      TextStyle(
                        fontSize: 9,
                        fontWeight:
                        FontWeight
                            .w600,
                        color:
                        status.color,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Text(
                    'Lihat ${summary.totalAc} unit AC',
                    style:
                    TextStyle(
                      color:
                      kPrimaryColor,
                      fontSize: 9.5,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    width: 5,
                  ),

                  Icon(
                    Icons
                        .arrow_forward_ios_rounded,
                    size: 11,
                    color:
                    kPrimaryColor,
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
  // LOCATION INFO
  // ============================================================

  Widget _buildLocationInfo({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 17,
          color: color,
        ),

        const SizedBox(
          height: 4,
        ),

        Text(
          value,
          style:
          primaryTextStyle.copyWith(
            fontSize: 14,
            fontWeight: bold,
          ),
        ),

        const SizedBox(
          height: 2,
        ),

        Text(
          label,
          textAlign:
          TextAlign.center,
          maxLines: 1,
          overflow:
          TextOverflow.ellipsis,
          style:
          greyTextStyle.copyWith(
            fontSize: 8.5,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 40,
      color:
      Colors.grey.withValues(
        alpha: 0.10,
      ),
    );
  }

  Widget _buildMaintenanceMiniInfo({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 31,
          height: 31,
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
          child: Icon(
            icon,
            size: 15,
            color: color,
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
                maxLines: 1,
                overflow:
                TextOverflow
                    .ellipsis,
                style:
                greyTextStyle
                    .copyWith(
                  fontSize: 7.8,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                value,
                maxLines: 1,
                overflow:
                TextOverflow
                    .ellipsis,
                style:
                primaryTextStyle
                    .copyWith(
                  fontSize: 9.5,
                  fontWeight: bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceStatusBadge(
      _LocationMaintenanceStatus status,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration:
      BoxDecoration(
        color: status.color
            .withValues(
          alpha: 0.08,
        ),
        borderRadius:
        BorderRadius.circular(
          20,
        ),
        border:
        Border.all(
          color: status.color
              .withValues(
            alpha: 0.16,
          ),
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
  // MAINTENANCE SUMMARY
  // ============================================================

  _LocationMaintenanceSummary _buildMaintenanceSummary(
      LokasiModel lokasi,
      List<AcModel> acList,
      ) {
    final intervalMonths =
    _getServiceIntervalMonths(
      lokasi,
    );

    final now =
    DateTime.now();

    final today =
    DateTime(
      now.year,
      now.month,
      now.day,
    );

    int overdueCount = 0;
    int upcomingCount = 0;
    int neverServicedCount = 0;

    DateTime? latestServiceDate;
    DateTime? nearestServiceDate;

    for (final ac in acList) {
      final lastService =
          ac.terakhirService;

      // ========================================================
      // BELUM PERNAH SERVICE
      // ========================================================

      if (lastService == null) {
        neverServicedCount++;
        continue;
      }

      // ========================================================
      // SERVICE TERAKHIR PALING BARU
      // ========================================================

      if (latestServiceDate == null ||
          lastService.isAfter(
            latestServiceDate,
          )) {
        latestServiceDate =
            lastService;
      }

      // ========================================================
      // SERVICE BERIKUTNYA
      // ========================================================

      final nextService =
      _addMonths(
        lastService,
        intervalMonths,
      );

      final nextDateOnly =
      _dateOnly(
        nextService,
      );

      if (nearestServiceDate == null ||
          nextDateOnly.isBefore(
            nearestServiceDate,
          )) {
        nearestServiceDate =
            nextDateOnly;
      }

      final difference =
          nextDateOnly
              .difference(
            today,
          )
              .inDays;

      if (difference <= 0) {
        overdueCount++;
      } else if (difference <=
          _upcomingThresholdDays) {
        upcomingCount++;
      }
    }

    return _LocationMaintenanceSummary(
      lokasi: lokasi,
      acList: acList,
      overdueCount: overdueCount,
      upcomingCount: upcomingCount,
      neverServicedCount:
      neverServicedCount,
      latestServiceDate:
      latestServiceDate,
      nearestServiceDate:
      nearestServiceDate,
      intervalMonths:
      intervalMonths,
    );
  }

  // ============================================================
  // INTERVAL
  // ============================================================

  int _getServiceIntervalMonths(
      LokasiModel lokasi,
      ) {
    // ==========================================================
    // TODO:
    //
    // Setelah backend memiliki:
    //
    // service_interval_months
    //
    // dan LokasiModel memiliki:
    //
    // final int serviceIntervalMonths;
    //
    // ubah menjadi:
    //
    // return lokasi.serviceIntervalMonths;
    // ==========================================================

    return _defaultServiceIntervalMonths;
  }

  // ============================================================
  // STATUS
  // ============================================================

  _LocationMaintenanceStatus
  _getLocationMaintenanceStatus(
      _LocationMaintenanceSummary summary,
      ) {
    if (summary.totalAc == 0) {
      return const _LocationMaintenanceStatus(
        label: 'Belum Ada AC',
        color: Colors.grey,
        softColor:
        Color(0xFFF8F8F8),
      );
    }

    if (summary.overdueCount > 0) {
      return const _LocationMaintenanceStatus(
        label: 'Perlu Servis',
        color: Colors.red,
        softColor:
        Color(0xFFFFF6F6),
      );
    }

    if (summary.upcomingCount > 0) {
      return const _LocationMaintenanceStatus(
        label: 'Segera',
        color: Colors.orange,
        softColor:
        Color(0xFFFFF9F0),
      );
    }

    if (summary.neverServicedCount > 0) {
      return const _LocationMaintenanceStatus(
        label: 'Belum Servis',
        color: Colors.blueGrey,
        softColor:
        Color(0xFFF6F8FA),
      );
    }

    return const _LocationMaintenanceStatus(
      label: 'Aman',
      color: Colors.green,
      softColor:
      Color(0xFFF5FBF7),
    );
  }

  // ============================================================
  // MAINTENANCE TEXT
  // ============================================================

  String _getNextServiceText(
      _LocationMaintenanceSummary summary,
      ) {
    if (summary.totalAc == 0) {
      return '-';
    }

    if (summary.nearestServiceDate !=
        null) {
      return _formatDate(
        summary.nearestServiceDate!,
      );
    }

    if (summary.neverServicedCount > 0) {
      return 'Perlu dijadwalkan';
    }

    return '-';
  }

  String _getCountdownText(
      DateTime nextService,
      ) {
    final now =
    DateTime.now();

    final today =
    _dateOnly(
      now,
    );

    final target =
    _dateOnly(
      nextService,
    );

    final difference =
        target
            .difference(today)
            .inDays;

    if (difference < 0) {
      return 'Lewat ${difference.abs()} hari';
    }

    if (difference == 0) {
      return 'Hari ini';
    }

    if (difference == 1) {
      return 'Besok';
    }

    return '$difference hari lagi';
  }

  String _getMaintenanceMessage(
      _LocationMaintenanceSummary summary,
      ) {
    if (summary.totalAc == 0) {
      return 'Belum ada unit AC';
    }

    if (summary.overdueCount > 0) {
      return '${summary.overdueCount} AC sudah melewati jadwal servis';
    }

    if (summary.upcomingCount > 0) {
      return '${summary.upcomingCount} AC akan segera jatuh tempo';
    }

    if (summary.neverServicedCount > 0) {
      return '${summary.neverServicedCount} AC belum pernah diservis';
    }

    return 'Seluruh AC masih dalam jadwal';
  }

  // ============================================================
  // DATE HELPER
  // ============================================================

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
    final totalMonthIndex =
        date.year * 12 +
            date.month -
            1 +
            months;

    final targetYear =
        totalMonthIndex ~/ 12;

    final targetMonth =
        totalMonthIndex % 12 + 1;

    final lastDay =
        DateTime(
          targetYear,
          targetMonth + 1,
          0,
        ).day;

    final targetDay =
    date.day > lastDay
        ? lastDay
        : date.day;

    return DateTime(
      targetYear,
      targetMonth,
      targetDay,
    );
  }

  String _formatDate(
      DateTime date,
      ) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return Container(
      height: 150,
      width:
      double.infinity,
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          22,
        ),
      ),
      child: Center(
        child:
        Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color:
              kPrimaryColor,
              strokeWidth: 2.5,
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              'Memuat lokasi dan AC...',
              style:
              greyTextStyle
                  .copyWith(
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        28,
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
              color: kPrimaryColor
                  .withValues(
                alpha: 0.08,
              ),
              borderRadius:
              BorderRadius
                  .circular(
                18,
              ),
            ),
            child: Icon(
              _query.isEmpty
                  ? Iconsax.location
                  : Iconsax.search_status,
              color:
              kPrimaryColor,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            _query.isEmpty
                ? 'Belum Ada Lokasi'
                : 'Lokasi Tidak Ditemukan',
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
            _query.isEmpty
                ? 'Belum ada data lokasi yang tersedia.'
                : 'Coba gunakan kata kunci pencarian lain.',
            textAlign:
            TextAlign.center,
            style:
            greyTextStyle
                .copyWith(
              fontSize: 10.5,
            ),
          ),

          if (_query.isNotEmpty) ...[
            const SizedBox(
              height: 12,
            ),

            TextButton.icon(
              onPressed: () {
                _searchController
                    .clear();
              },
              icon: const Icon(
                Iconsax.refresh,
                size: 16,
              ),
              label:
              const Text(
                'Reset Pencarian',
              ),
              style:
              TextButton.styleFrom(
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

// ============================================================
// LOCATION MAINTENANCE SUMMARY
// ============================================================

class _LocationMaintenanceSummary {
  final LokasiModel lokasi;
  final List<AcModel> acList;

  final int overdueCount;
  final int upcomingCount;
  final int neverServicedCount;

  final DateTime? latestServiceDate;
  final DateTime? nearestServiceDate;

  final int intervalMonths;

  const _LocationMaintenanceSummary({
    required this.lokasi,
    required this.acList,
    required this.overdueCount,
    required this.upcomingCount,
    required this.neverServicedCount,
    required this.latestServiceDate,
    required this.nearestServiceDate,
    required this.intervalMonths,
  });

  int get totalAc =>
      acList.length;
}

// ============================================================
// LOCATION MAINTENANCE STATUS
// ============================================================

class _LocationMaintenanceStatus {
  final String label;
  final Color color;
  final Color softColor;

  const _LocationMaintenanceStatus({
    required this.label,
    required this.color,
    required this.softColor,
  });
}