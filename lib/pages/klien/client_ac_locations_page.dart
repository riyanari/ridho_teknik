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

class _ClientAcLocationsPageState
    extends State<ClientAcLocationsPage> {
  final TextEditingController _searchController =
  TextEditingController();

  String _query = '';

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
          _searchController.text
              .trim()
              .toLowerCase();
    });
  }

  List<LokasiModel> _filterLocations(
      List<LokasiModel> locations,
      ) {
    if (_query.isEmpty) {
      return locations;
    }

    return locations.where((lokasi) {
      return lokasi.nama
          .toLowerCase()
          .contains(_query) ||
          lokasi.alamat
              .toLowerCase()
              .contains(_query);
    }).toList();
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

    final locations =
    _filterLocations(
      masterProvider.lokasi,
    );

    final totalAc =
        acProvider.allAc.length;

    final totalLokasi =
        masterProvider.lokasi.length;

    final loading =
        (masterProvider.loading &&
            masterProvider
                .lokasi.isEmpty) ||
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
              parent:
              BouncingScrollPhysics(),
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
                      // ====================================================
                      // HEADER
                      // ====================================================

                      _buildHeader(
                        totalLokasi:
                        totalLokasi,
                        totalAc: totalAc,
                      ),

                      const SizedBox(
                        height: 22,
                      ),

                      // ====================================================
                      // SEARCH
                      // ====================================================

                      _buildSearchField(),

                      const SizedBox(
                        height: 24,
                      ),

                      // ====================================================
                      // SECTION TITLE
                      // ====================================================

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Text(
                                  'Daftar Lokasi',
                                  style:
                                  primaryTextStyle
                                      .copyWith(
                                    fontSize: 18,
                                    fontWeight:
                                    bold,
                                  ),
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  'Pilih lokasi untuk melihat unit AC',
                                  style:
                                  greyTextStyle
                                      .copyWith(
                                    fontSize:
                                    11.5,
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
                              color: kPrimaryColor
                                  .withValues(
                                alpha: 0.08,
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                20,
                              ),
                            ),
                            child: Text(
                              '${locations.length} lokasi',
                              style: TextStyle(
                                color:
                                kPrimaryColor,
                                fontSize: 10,
                                fontWeight:
                                FontWeight
                                    .w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // ====================================================
                      // CONTENT
                      // ====================================================

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
          begin:
          Alignment.topLeft,
          end:
          Alignment.bottomRight,
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
            color: kPrimaryColor
                .withValues(
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
                  BorderRadius
                      .circular(
                    16,
                  ),
                ),
                child: const Icon(
                  Icons
                      .ac_unit_rounded,
                  color:
                  Colors.white,
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
                        fontWeight:
                        bold,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      'Kelola unit AC berdasarkan lokasi',
                      style:
                      whiteTextStyle
                          .copyWith(
                        fontSize: 11.5,
                        color:
                        Colors.white
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
                  totalLokasi
                      .toString(),
                  label:
                  'Lokasi',
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
                  totalAc
                      .toString(),
                  label:
                  'Unit AC',
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
        color: Colors.white
            .withValues(
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
              BorderRadius
                  .circular(
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

          Column(
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
                  fontWeight:
                  bold,
                ),
              ),
              Text(
                label,
                style:
                whiteTextStyle
                    .copyWith(
                  fontSize: 9.5,
                  color:
                  Colors.white
                      .withValues(
                    alpha: 0.72,
                  ),
                ),
              ),
            ],
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
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(
              alpha: 0.035,
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
        decoration:
        InputDecoration(
          hintText:
          'Cari lokasi...',
          hintStyle:
          greyTextStyle.copyWith(
            fontSize: 12,
          ),
          prefixIcon: Icon(
            Iconsax.search_normal,
            color:
            kPrimaryColor,
            size: 20,
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
                  : 12,
            ),
            child:
            _buildLocationCard(
              lokasi:
              lokasi,
              acList:
              acList,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationCard({
    required LokasiModel lokasi,
    required List<AcModel> acList,
  }) {
    final totalAc =
        acList.length;

    final servicedCount =
        acList
            .where(
              (ac) =>
          ac.terakhirService !=
              null,
        )
            .length;

    final neverServiced =
        totalAc -
            servicedCount;

    final latestService =
    _getLatestService(
      acList,
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
          22,
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
            const LinearGradient(
              begin:
              Alignment.topLeft,
              end:
              Alignment
                  .bottomRight,
              colors: [
                Color(
                  0xFFF6F7FF,
                ),
                Colors.white,
              ],
            ),
            borderRadius:
            BorderRadius
                .circular(
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
                  7,
                ),
              ),
            ],
          ),
          child:
          Column(
            children: [
              Row(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Container(
                    width:
                    48,
                    height:
                    48,
                    decoration:
                    BoxDecoration(
                      color:
                      kPrimaryColor
                          .withValues(
                        alpha:
                        0.09,
                      ),
                      borderRadius:
                      BorderRadius
                          .circular(
                        16,
                      ),
                    ),
                    child:
                    Icon(
                      Iconsax
                          .location,
                      color:
                      kPrimaryColor,
                      size:
                      22,
                    ),
                  ),

                  const SizedBox(
                    width:
                    12,
                  ),

                  Expanded(
                    child:
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Text(
                          lokasi
                              .nama,
                          maxLines:
                          2,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          primaryTextStyle
                              .copyWith(
                            fontSize:
                            14.5,
                            fontWeight:
                            bold,
                          ),
                        ),

                        const SizedBox(
                          height:
                          4,
                        ),

                        Text(
                          lokasi
                              .alamat
                              .trim()
                              .isEmpty
                              ? 'Alamat tidak tersedia'
                              : lokasi
                              .alamat,
                          maxLines:
                          2,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          greyTextStyle
                              .copyWith(
                            fontSize:
                            10.5,
                            height:
                            1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    width:
                    8,
                  ),

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
                      color:
                      kPrimaryColor
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
                    child:
                    Text(
                      '$totalAc AC',
                      style:
                      TextStyle(
                        color:
                        kPrimaryColor,
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

              const SizedBox(
                height:
                15,
              ),

              Container(
                padding:
                const EdgeInsets
                    .all(
                  12,
                ),
                decoration:
                BoxDecoration(
                  color:
                  Colors.white
                      .withValues(
                    alpha:
                    0.70,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    15,
                  ),
                ),
                child:
                Row(
                  children: [
                    Expanded(
                      child:
                      _buildLocationInfo(
                        icon:
                        Icons
                            .ac_unit_rounded,
                        label:
                        'Unit AC',
                        value:
                        totalAc.toString(),
                        color:
                        kPrimaryColor,
                      ),
                    ),

                    Container(
                      width:
                      1,
                      height:
                      38,
                      color:
                      Colors.grey
                          .withValues(
                        alpha:
                        0.12,
                      ),
                    ),

                    Expanded(
                      child:
                      _buildLocationInfo(
                        icon:
                        Iconsax
                            .tick_circle,
                        label:
                        'Pernah Servis',
                        value:
                        servicedCount
                            .toString(),
                        color:
                        Colors.green,
                      ),
                    ),

                    Container(
                      width:
                      1,
                      height:
                      38,
                      color:
                      Colors.grey
                          .withValues(
                        alpha:
                        0.12,
                      ),
                    ),

                    Expanded(
                      child:
                      _buildLocationInfo(
                        icon:
                        Iconsax
                            .info_circle,
                        label:
                        'Belum',
                        value:
                        neverServiced
                            .toString(),
                        color:
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height:
                12,
              ),

              Row(
                children: [
                  Icon(
                    Iconsax
                        .calendar_1,
                    size:
                    15,
                    color:
                    Colors.grey
                        .shade500,
                  ),

                  const SizedBox(
                    width:
                    7,
                  ),

                  Text(
                    'Servis terakhir',
                    style:
                    greyTextStyle
                        .copyWith(
                      fontSize:
                      10,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    latestService !=
                        null
                        ? _formatDate(
                      latestService,
                    )
                        : 'Belum pernah',
                    style:
                    primaryTextStyle
                        .copyWith(
                      fontSize:
                      10.5,
                      fontWeight:
                      medium,
                    ),
                  ),

                  const SizedBox(
                    width:
                    8,
                  ),

                  Icon(
                    Icons
                        .arrow_forward_ios_rounded,
                    size:
                    11,
                    color:
                    Colors.grey
                        .shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  // ============================================================
  // DATE
  // ============================================================

  DateTime? _getLatestService(
      List<AcModel> list,
      ) {
    final dates =
    list
        .map(
          (ac) =>
      ac.terakhirService,
    )
        .whereType<DateTime>()
        .toList();

    if (dates.isEmpty) {
      return null;
    }

    dates.sort(
          (a, b) =>
          b.compareTo(a),
    );

    return dates.first;
  }

  String _formatDate(
      DateTime date,
      ) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ============================================================
  // LOADING / EMPTY
  // ============================================================

  Widget _buildLoading() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          22,
        ),
      ),
      child: Center(
        child:
        CircularProgressIndicator(
          color: kPrimaryColor,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(
        28,
      ),
      decoration: BoxDecoration(
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
              Iconsax.location,
              color: kPrimaryColor,
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
            primaryTextStyle.copyWith(
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
            greyTextStyle.copyWith(
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}