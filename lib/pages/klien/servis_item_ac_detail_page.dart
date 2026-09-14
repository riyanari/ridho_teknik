// lib/pages/klien/servis_item_ac_detail_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/token_store.dart';
import '../../theme/theme.dart';
import '../../utils/photo_url_helper.dart';

class ServisItemAcDetailPage extends StatefulWidget {
  final String servisId;
  final Map<String, dynamic> item;

  const ServisItemAcDetailPage({
    super.key,
    required this.servisId,
    required this.item,
  });

  @override
  State<ServisItemAcDetailPage> createState() =>
      _ServisItemAcDetailPageState();
}

class _ServisItemAcDetailPageState
    extends State<ServisItemAcDetailPage> {
  String? _token;
  bool _loadingToken = true;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    try {
      final store = context.read<TokenStore>();
      final token = await store.getToken();

      if (!mounted) return;

      setState(() {
        _token = token;
        _loadingToken = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _token = null;
        _loadingToken = false;
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    final itemId = int.tryParse(
      item['id']?.toString() ?? '',
    ) ??
        0;

    final ac = item['ac_unit'] is Map
        ? Map<String, dynamic>.from(
      item['ac_unit'],
    )
        : <String, dynamic>{};

    final room = _extractRoom(
      item,
      ac,
    );

    final acName = _firstNonEmpty([
      ac['name'],
      ac['nama'],
      'AC #${ac['id'] ?? item['ac_unit_id'] ?? '-'}',
    ]);

    final brand = _firstNonEmpty([
      ac['brand'],
      ac['merk'],
    ]);

    final type = _firstNonEmpty([
      ac['type'],
      ac['tipe'],
    ]);

    final capacity = _firstNonEmpty([
      ac['capacity'],
      ac['kapasitas'],
    ]);

    final serialNumber = _firstNonEmpty([
      ac['serial_number'],
      ac['serialNumber'],
    ]);

    final status =
    (item['status'] ?? '').toString().trim();

    final technician =
    item['technician'] is Map
        ? Map<String, dynamic>.from(
      item['technician'],
    )
        : <String, dynamic>{};

    final technicianName = _firstNonEmpty([
      technician['name'],
      technician['nama'],
    ]);

    final diagnosis =
    (item['diagnosa'] ?? '')
        .toString()
        .trim();

    final action =
    (item['tindakan'] ?? '')
        .toString()
        .trim();

    final visitDate = _parseDate(
      item['tanggal_berkunjung'],
    );

    final assignedDate = _parseDate(
      item['assigned_at'],
    );

    final startDate = _parseDate(
      item['tanggal_mulai'],
    );

    final finishDate = _parseDate(
      item['tanggal_selesai'],
    );

    // ==========================================================
    // PHOTO
    // ==========================================================

    final beforePhotos =
    asServiceItemPhotoUrls(
      itemId: itemId,
      type: 'sebelum',
      valueFromApi:
      item['foto_sebelum'],
    );

    final progressPhotos =
    asServiceItemPhotoUrls(
      itemId: itemId,
      type: 'pengerjaan',
      valueFromApi:
      item['foto_pengerjaan'],
    );

    final afterPhotos =
    asServiceItemPhotoUrls(
      itemId: itemId,
      type: 'sesudah',
      valueFromApi:
      item['foto_sesudah'],
    );

    final sparePartPhotos =
    asServiceItemPhotoUrls(
      itemId: itemId,
      type: 'suku_cadang',
      valueFromApi:
      item['foto_suku_cadang'],
    );

    final photoCategories =
    <_PhotoCategory>[
      if (beforePhotos.isNotEmpty)
        _PhotoCategory(
          title: 'Sebelum',
          photos: beforePhotos,
          color: Colors.orange,
        ),
      if (progressPhotos.isNotEmpty)
        _PhotoCategory(
          title: 'Proses',
          photos: progressPhotos,
          color: Colors.blue,
        ),
      if (afterPhotos.isNotEmpty)
        _PhotoCategory(
          title: 'Sesudah',
          photos: afterPhotos,
          color: Colors.green,
        ),
      if (sparePartPhotos.isNotEmpty)
        _PhotoCategory(
          title: 'Suku Cadang',
          photos: sparePartPhotos,
          color: Colors.purple,
        ),
    ];

    // ==========================================================
    // LOADING
    // ==========================================================

    if (_loadingToken) {
      return Scaffold(
        backgroundColor:
        kBackgroundColor,
        body: SafeArea(
          child: Center(
            child:
            CircularProgressIndicator(
              color:
              kPrimaryColor,
            ),
          ),
        ),
      );
    }

    if ((_token ?? '')
        .trim()
        .isEmpty) {
      return Scaffold(
        backgroundColor:
        kBackgroundColor,
        body: SafeArea(
          child:
          _buildTokenError(),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
      kBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics:
          const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child:
              _buildTopBar(
                roomName:
                room.name,
                acName:
                acName,
              ),
            ),

            SliverPadding(
              padding:
              const EdgeInsets
                  .fromLTRB(
                18,
                10,
                18,
                38,
              ),
              sliver:
              SliverList(
                delegate:
                SliverChildListDelegate(
                  [
                    // ==========================================
                    // HERO
                    // ==========================================

                    _buildHeroCard(
                      room:
                      room,
                      acName:
                      acName,
                      brand:
                      brand,
                      capacity:
                      capacity,
                      type:
                      type,
                      serialNumber:
                      serialNumber,
                      status:
                      status,
                    ),

                    const SizedBox(
                      height: 22,
                    ),

                    // ==========================================
                    // SERVICE INFO
                    // ==========================================

                    _buildServiceInfo(
                      technicianName:
                      technicianName,
                      visitDate:
                      visitDate,
                      assignedDate:
                      assignedDate,
                    ),

                    const SizedBox(
                      height: 22,
                    ),

                    // ==========================================
                    // PROGRESS
                    // ==========================================

                    _buildProgressSection(
                      status:
                      status,
                      startDate:
                      startDate,
                      finishDate:
                      finishDate,
                    ),

                    const SizedBox(
                      height: 22,
                    ),

                    // ==========================================
                    // RESULT
                    // ==========================================

                    _buildDiagnosisActionSection(
                      diagnosis:
                      diagnosis,
                      action:
                      action,
                    ),

                    const SizedBox(
                      height: 22,
                    ),

                    // ==========================================
                    // PHOTO
                    // ==========================================

                    _buildPhotoSection(
                      photoCategories,
                    ),

                    const SizedBox(
                      height: 32,
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
  // TOP BAR
  // ============================================================

  Widget _buildTopBar({
    required String roomName,
    required String acName,
  }) {
    return Padding(
      padding:
      const EdgeInsets.fromLTRB(
        18,
        14,
        18,
        12,
      ),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(
              15,
            ),
            elevation: 0,
            child: InkWell(
              onTap: () =>
                  Navigator.pop(
                    context,
                  ),
              borderRadius:
              BorderRadius.circular(
                15,
              ),
              child: SizedBox(
                width: 44,
                height: 44,
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
            width: 13,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  roomName.isNotEmpty
                      ? roomName
                      : 'Detail Unit AC',
                  maxLines: 1,
                  overflow:
                  TextOverflow
                      .ellipsis,
                  style:
                  primaryTextStyle
                      .copyWith(
                    fontSize: 18,
                    fontWeight:
                    bold,
                    color: const Color(
                      0xFF202236,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  acName,
                  maxLines: 1,
                  overflow:
                  TextOverflow
                      .ellipsis,
                  style: TextStyle(
                    color: Colors
                        .grey.shade600,
                    fontSize: 10.5,
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
  // HERO
  // ============================================================

  Widget _buildHeroCard({
    required _RoomInfo room,
    required String acName,
    required String brand,
    required String capacity,
    required String type,
    required String serialNumber,
    required String status,
  }) {
    final statusColor =
    _getStatusColor(
      status,
    );

    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          23,
        ),
        border: Border.all(
          color: kPrimaryColor
              .withValues(
            alpha: 0.14,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(
              alpha: 0.04,
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
        CrossAxisAlignment
            .start,
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration:
                BoxDecoration(
                  color: kPrimaryColor
                      .withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    18,
                  ),
                ),
                child: Icon(
                  Icons
                      .ac_unit_rounded,
                  color:
                  kPrimaryColor,
                  size: 29,
                ),
              ),

              const SizedBox(
                width: 13,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      room.name
                          .isNotEmpty
                          ? room.name
                          : acName,
                      maxLines: 1,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style:
                      primaryTextStyle
                          .copyWith(
                        fontSize: 18,
                        fontWeight:
                        bold,
                        color:
                        const Color(
                          0xFF202236,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    if (room.name
                        .isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons
                                .ac_unit_rounded,
                            size: 13,
                            color:
                            kPrimaryColor,
                          ),

                          const SizedBox(
                            width: 5,
                          ),

                          Expanded(
                            child: Text(
                              acName,
                              maxLines:
                              1,
                              overflow:
                              TextOverflow
                                  .ellipsis,
                              style:
                              TextStyle(
                                fontSize:
                                10.5,
                                color:
                                kPrimaryColor,
                                fontWeight:
                                FontWeight
                                    .w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                    if (room.floor
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 9,
                      ),

                      Container(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal:
                          9,
                          vertical:
                          5,
                        ),
                        decoration:
                        BoxDecoration(
                          color:
                          const Color(
                            0xFFF0F2F7,
                          ),
                          borderRadius:
                          BorderRadius
                              .circular(
                            20,
                          ),
                        ),
                        child: Row(
                          mainAxisSize:
                          MainAxisSize
                              .min,
                          children: [
                            Icon(
                              Icons
                                  .layers_outlined,
                              size: 12,
                              color: Colors
                                  .blueGrey
                                  .shade700,
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Text(
                              room.floor,
                              style:
                              TextStyle(
                                fontSize:
                                9,
                                fontWeight:
                                FontWeight
                                    .w600,
                                color: Colors
                                    .blueGrey
                                    .shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration:
                BoxDecoration(
                  color: statusColor
                      .withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    20,
                  ),
                ),
                child: Row(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(
                        status,
                      ),
                      size: 12,
                      color:
                      statusColor,
                    ),

                    const SizedBox(
                      width: 5,
                    ),

                    Text(
                      _getStatusDisplay(
                        status,
                      ),
                      style:
                      TextStyle(
                        fontSize: 9,
                        color:
                        statusColor,
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
            height: 18,
          ),

          Divider(
            height: 1,
            thickness: 1,
            color: Colors
                .grey.shade200,
          ),

          const SizedBox(
            height: 17,
          ),

          Row(
            children: [
              Expanded(
                child:
                _buildSpecification(
                  label:
                  'Merek',
                  value: brand
                      .isEmpty
                      ? '-'
                      : brand,
                  icon: Icons
                      .business_outlined,
                ),
              ),

              _buildVerticalDivider(),

              Expanded(
                child:
                _buildSpecification(
                  label:
                  'Kapasitas',
                  value: capacity
                      .isEmpty
                      ? '-'
                      : capacity,
                  icon: Icons
                      .speed_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 17,
          ),

          Row(
            children: [
              Expanded(
                child:
                _buildSpecification(
                  label:
                  'Tipe',
                  value: type
                      .isEmpty
                      ? '-'
                      : type,
                  icon: Icons
                      .category_outlined,
                ),
              ),

              _buildVerticalDivider(),

              Expanded(
                child:
                _buildSpecification(
                  label:
                  'Serial Number',
                  value: serialNumber
                      .isEmpty
                      ? '-'
                      : serialNumber,
                  icon: Icons
                      .numbers_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecification({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration:
          BoxDecoration(
            color: kPrimaryColor
                .withValues(
              alpha: 0.10,
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
          width: 9,
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
                TextStyle(
                  fontSize: 9,
                  color: Colors
                      .grey.shade600,
                  fontWeight:
                  FontWeight
                      .w500,
                ),
              ),

              const SizedBox(
                height: 3,
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
                  fontSize: 11,
                  fontWeight:
                  FontWeight.w600,
                  color:
                  const Color(
                    0xFF252637,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 38,
      margin:
      const EdgeInsets
          .symmetric(
        horizontal: 10,
      ),
      color: Colors
          .grey.shade200,
    );
  }

  // ============================================================
  // SERVICE INFO
  // ============================================================

  Widget _buildServiceInfo({
    required String technicianName,
    required DateTime? visitDate,
    required DateTime? assignedDate,
  }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          icon: Icons
              .info_outline_rounded,
          title:
          'Informasi Servis',
          subtitle:
          'Teknisi dan jadwal kunjungan',
          color:
          kPrimaryColor,
        ),

        const SizedBox(
          height: 12,
        ),

        Container(
          padding:
          const EdgeInsets.all(
            16,
          ),
          decoration:
          _cardDecoration(),
          child: Column(
            children: [
              _buildInfoRow(
                icon: Icons
                    .person_outline_rounded,
                title:
                'Teknisi',
                value:
                technicianName
                    .isEmpty
                    ? 'Belum ditugaskan'
                    : technicianName,
                color:
                Colors.blue,
              ),

              _divider(),

              _buildInfoRow(
                icon: Icons
                    .calendar_month_rounded,
                title:
                'Jadwal Kunjungan',
                value:
                visitDate !=
                    null
                    ? _formatDateTime(
                  visitDate,
                )
                    : 'Belum ditentukan',
                color:
                Colors.purple,
              ),

              if (assignedDate !=
                  null) ...[
                _divider(),

                _buildInfoRow(
                  icon: Icons
                      .assignment_turned_in_outlined,
                  title:
                  'Ditugaskan',
                  value:
                  _formatDateTime(
                    assignedDate,
                  ),
                  color:
                  Colors.orange,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
            BoxDecoration(
              color: color
                  .withValues(
                alpha: 0.10,
              ),
              borderRadius:
              BorderRadius
                  .circular(
                13,
              ),
            ),
            child: Icon(
              icon,
              size: 19,
              color: color,
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
                    fontSize: 9.5,
                    color: Colors
                        .grey.shade600,
                    fontWeight:
                    FontWeight
                        .w500,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  value,
                  style:
                  primaryTextStyle
                      .copyWith(
                    fontSize: 11.5,
                    fontWeight:
                    FontWeight
                        .w600,
                    color:
                    const Color(
                      0xFF252637,
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
  // PROGRESS
  // ============================================================

  Widget _buildProgressSection({
    required String status,
    required DateTime? startDate,
    required DateTime? finishDate,
  }) {
    final lower =
    status.toLowerCase();

    final completed =
        lower == 'selesai';

    final assigned =
        lower ==
            'ditugaskan' ||
            lower ==
                'dikerjakan' ||
            completed;

    final started =
        startDate != null ||
            lower ==
                'dikerjakan' ||
            completed;

    Duration? duration;

    if (startDate != null &&
        finishDate != null) {
      duration =
          finishDate.difference(
            startDate,
          );
    }

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          icon:
          Icons.timeline_rounded,
          title:
          'Progress Pengerjaan',
          subtitle:
          'Pantau proses pengerjaan unit',
          color:
          Colors.green,
        ),

        const SizedBox(
          height: 12,
        ),

        Container(
          padding:
          const EdgeInsets.all(
            17,
          ),
          decoration:
          _cardDecoration(),
          child: Column(
            children: [
              _buildProgressItem(
                icon: Icons
                    .assignment_turned_in_rounded,
                title:
                'Ditugaskan',
                subtitle:
                assigned
                    ? 'Teknisi telah menerima pekerjaan'
                    : 'Menunggu penugasan teknisi',
                active:
                assigned,
                completed:
                started,
                color:
                Colors.blue,
              ),

              _buildProgressLine(
                active:
                started,
              ),

              _buildProgressItem(
                icon: Icons
                    .build_circle_outlined,
                title:
                'Mulai Pengerjaan',
                subtitle:
                startDate !=
                    null
                    ? _formatDateTime(
                  startDate,
                )
                    : started
                    ? 'Pengerjaan sedang berlangsung'
                    : 'Belum dimulai',
                active:
                started,
                completed:
                completed,
                color:
                Colors.purple,
              ),

              _buildProgressLine(
                active:
                completed,
              ),

              _buildProgressItem(
                icon: Icons
                    .check_circle_outline,
                title:
                'Selesai',
                subtitle:
                finishDate !=
                    null
                    ? _formatDateTime(
                  finishDate,
                )
                    : completed
                    ? 'Pengerjaan selesai'
                    : 'Belum selesai',
                active:
                completed,
                completed:
                completed,
                color:
                Colors.green,
              ),

              if (duration !=
                  null) ...[
                const SizedBox(
                  height: 16,
                ),

                Container(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 13,
                    vertical: 11,
                  ),
                  decoration:
                  BoxDecoration(
                    color: const Color(
                      0xFFF0F8F3,
                    ),
                    borderRadius:
                    BorderRadius
                        .circular(
                      14,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons
                            .timer_outlined,
                        color:
                        Colors.green,
                        size: 18,
                      ),

                      const SizedBox(
                        width: 9,
                      ),

                      Text(
                        'Durasi pengerjaan',
                        style:
                        TextStyle(
                          fontSize:
                          9.5,
                          color: Colors
                              .grey
                              .shade600,
                          fontWeight:
                          FontWeight
                              .w500,
                        ),
                      ),

                      const Spacer(),

                      Text(
                        _formatDuration(
                          duration,
                        ),
                        style:
                        primaryTextStyle
                            .copyWith(
                          fontSize: 10.5,
                          fontWeight:
                          bold,
                          color:
                          const Color(
                            0xFF252637,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool active,
    required bool completed,
    required Color color,
  }) {
    final displayColor =
    active
        ? color
        : Colors
        .grey.shade400;

    return Row(
      crossAxisAlignment:
      CrossAxisAlignment
          .center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration:
          BoxDecoration(
            color: active
                ? color
                .withValues(
              alpha: 0.11,
            )
                : const Color(
              0xFFF1F2F5,
            ),
            shape:
            BoxShape.circle,
          ),
          child: Icon(
            completed
                ? Icons
                .check_rounded
                : icon,
            size: 19,
            color:
            displayColor,
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
                primaryTextStyle
                    .copyWith(
                  fontSize: 12,
                  fontWeight:
                  FontWeight
                      .w600,
                  color: active
                      ? const Color(
                    0xFF252637,
                  )
                      : Colors
                      .grey
                      .shade500,
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                subtitle,
                style:
                TextStyle(
                  fontSize: 9.5,
                  color: active
                      ? Colors
                      .grey
                      .shade600
                      : Colors
                      .grey
                      .shade400,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine({
    required bool active,
  }) {
    return Align(
      alignment:
      Alignment.centerLeft,
      child: Container(
        width: 2,
        height: 23,
        margin:
        const EdgeInsets.only(
          left: 20,
          top: 3,
          bottom: 3,
        ),
        decoration:
        BoxDecoration(
          color: active
              ? kPrimaryColor
              .withValues(
            alpha: 0.55,
          )
              : Colors
              .grey.shade300,
          borderRadius:
          BorderRadius.circular(
            2,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RESULT
  // ============================================================

  Widget _buildDiagnosisActionSection({
    required String diagnosis,
    required String action,
  }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          icon: Icons
              .handyman_outlined,
          title:
          'Hasil Pengerjaan',
          subtitle:
          'Diagnosa dan tindakan teknisi',
          color:
          Colors.orange,
        ),

        const SizedBox(
          height: 12,
        ),

        Container(
          padding:
          const EdgeInsets.all(
            16,
          ),
          decoration:
          _cardDecoration(),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              _buildResultBlock(
                icon: Icons
                    .search_rounded,
                title:
                'Diagnosa',
                value:
                diagnosis,
                emptyText:
                'Diagnosa belum diisi oleh teknisi.',
                color:
                Colors.orange,
              ),

              const SizedBox(
                height: 16,
              ),

              _buildResultBlock(
                icon: Icons
                    .build_outlined,
                title:
                'Tindakan',
                value:
                action,
                emptyText:
                'Tindakan belum dicatat oleh teknisi.',
                color:
                Colors.blue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultBlock({
    required IconData icon,
    required String title,
    required String value,
    required String emptyText,
    required Color color,
  }) {
    final hasValue =
        value.trim().isNotEmpty;

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration:
              BoxDecoration(
                color: color
                    .withValues(
                  alpha: 0.10,
                ),
                borderRadius:
                BorderRadius
                    .circular(
                  9,
                ),
              ),
              child: Icon(
                icon,
                size: 15,
                color:
                color,
              ),
            ),

            const SizedBox(
              width: 9,
            ),

            Text(
              title,
              style:
              primaryTextStyle
                  .copyWith(
                fontSize: 11.5,
                fontWeight:
                bold,
                color:
                const Color(
                  0xFF252637,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 9,
        ),

        Container(
          width:
          double.infinity,
          padding:
          const EdgeInsets.all(
            13,
          ),
          decoration:
          BoxDecoration(
            color: hasValue
                ? color
                .withValues(
              alpha: 0.06,
            )
                : const Color(
              0xFFF6F6F8,
            ),
            borderRadius:
            BorderRadius.circular(
              14,
            ),
            border: Border.all(
              color: hasValue
                  ? color
                  .withValues(
                alpha: 0.14,
              )
                  : Colors
                  .grey.shade200,
            ),
          ),
          child: Text(
            hasValue
                ? value
                : emptyText,
            style:
            TextStyle(
              fontSize: 10,
              height: 1.55,
              color: hasValue
                  ? const Color(
                0xFF414253,
              )
                  : Colors
                  .grey.shade500,
              fontStyle: hasValue
                  ? FontStyle
                  .normal
                  : FontStyle
                  .italic,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PHOTO
  // ============================================================

  Widget _buildPhotoSection(
      List<_PhotoCategory>
      categories,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          icon: Icons
              .photo_library_outlined,
          title:
          'Dokumentasi',
          subtitle:
          'Foto kondisi dan pengerjaan AC',
          color:
          Colors.blue,
        ),

        const SizedBox(
          height: 12,
        ),

        if (categories.isEmpty)
          _buildEmptyPhotoState()
        else
          ...List.generate(
            categories.length,
                (index) {
              return Padding(
                padding:
                EdgeInsets.only(
                  bottom: index ==
                      categories
                          .length -
                          1
                      ? 0
                      : 13,
                ),
                child:
                _buildPhotoCategory(
                  categories[
                  index],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildPhotoCategory(
      _PhotoCategory category,
      ) {
    return Container(
      padding:
      const EdgeInsets.all(
        15,
      ),
      decoration:
      _cardDecoration(),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment
            .start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration:
                BoxDecoration(
                  color:
                  category.color,
                  borderRadius:
                  BorderRadius
                      .circular(
                    4,
                  ),
                ),
              ),

              const SizedBox(
                width: 9,
              ),

              Text(
                category.title,
                style:
                primaryTextStyle
                    .copyWith(
                  fontSize: 12,
                  fontWeight:
                  bold,
                  color:
                  const Color(
                    0xFF252637,
                  ),
                ),
              ),

              const SizedBox(
                width: 8,
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
                  color: category
                      .color
                      .withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    20,
                  ),
                ),
                child: Text(
                  '${category.photos.length} foto',
                  style:
                  TextStyle(
                    color:
                    category.color,
                    fontSize: 8,
                    fontWeight:
                    FontWeight
                        .w700,
                  ),
                ),
              ),

              const Spacer(),

              if (category
                  .photos.length >
                  6)
                InkWell(
                  onTap: () =>
                      _showFullGallery(
                        category,
                      ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    10,
                  ),
                  child: Padding(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 5,
                      vertical: 4,
                    ),
                    child: Text(
                      'Lihat semua',
                      style:
                      TextStyle(
                        color:
                        kPrimaryColor,
                        fontSize:
                        9,
                        fontWeight:
                        FontWeight
                            .w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(
            height: 13,
          ),

          GridView.builder(
            shrinkWrap: true,
            physics:
            const NeverScrollableScrollPhysics(),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount:
            category.photos.length >
                6
                ? 6
                : category
                .photos.length,
            itemBuilder: (
                context,
                index,
                ) {
              if (index == 5 &&
                  category
                      .photos.length >
                      6) {
                return GestureDetector(
                  onTap: () =>
                      _showFullGallery(
                        category,
                      ),
                  child:
                  _buildMorePhotoTile(
                    category
                        .photos
                        .length -
                        5,
                  ),
                );
              }

              return _buildPhotoTile(
                category
                    .photos[index],
                category.photos,
                index,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoTile(
      String url,
      List<String> photos,
      int index,
      ) {
    return GestureDetector(
      onTap: () =>
          _showPhotoViewer(
            photos: photos,
            initialIndex:
            index,
          ),
      child: ClipRRect(
        borderRadius:
        BorderRadius.circular(
          13,
        ),
        child: Stack(
          fit:
          StackFit.expand,
          children: [
            Container(
              color: Colors
                  .grey.shade100,
            ),

            Image.network(
              url,
              fit:
              BoxFit.cover,
              headers: {
                'Authorization':
                'Bearer $_token',
                'Accept':
                'image/*',
              },
              loadingBuilder: (
                  context,
                  child,
                  progress,
                  ) {
                if (progress ==
                    null) {
                  return child;
                }

                return Container(
                  color: Colors
                      .grey.shade100,
                  child:
                  Center(
                    child:
                    SizedBox(
                      width: 22,
                      height: 22,
                      child:
                      CircularProgressIndicator(
                        strokeWidth:
                        2,
                        color:
                        kPrimaryColor,
                      ),
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
                      .grey.shade100,
                  child: Icon(
                    Icons
                        .broken_image_outlined,
                    color: Colors
                        .grey.shade400,
                    size: 25,
                  ),
                );
              },
            ),

            Positioned(
              left: 7,
              bottom: 7,
              child: Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration:
                BoxDecoration(
                  color: Colors.black
                      .withValues(
                    alpha: 0.55,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    12,
                  ),
                ),
                child: Text(
                  '${index + 1}',
                  style:
                  const TextStyle(
                    color:
                    Colors.white,
                    fontSize: 8,
                    fontWeight:
                    FontWeight
                        .w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMorePhotoTile(
      int remaining,
      ) {
    return Container(
      decoration:
      BoxDecoration(
        color:
        const Color(
          0xFFF0F2FA,
        ),
        borderRadius:
        BorderRadius.circular(
          13,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment
              .center,
          children: [
            Text(
              '+$remaining',
              style:
              primaryTextStyle
                  .copyWith(
                fontSize: 18,
                fontWeight:
                bold,
                color:
                kPrimaryColor,
              ),
            ),

            const SizedBox(
              height: 2,
            ),

            Text(
              'lainnya',
              style:
              TextStyle(
                fontSize: 8.5,
                color: Colors
                    .grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPhotoState() {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.symmetric(
        vertical: 30,
        horizontal: 20,
      ),
      decoration:
      _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration:
            BoxDecoration(
              color:
              const Color(
                0xFFF2F3F6,
              ),
              borderRadius:
              BorderRadius
                  .circular(
                18,
              ),
            ),
            child: Icon(
              Icons
                  .photo_camera_back_outlined,
              color: Colors
                  .grey.shade500,
              size: 26,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            'Belum Ada Dokumentasi',
            style:
            primaryTextStyle
                .copyWith(
              fontSize: 13,
              fontWeight:
              bold,
              color:
              const Color(
                0xFF252637,
              ),
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            'Foto pengerjaan unit ini belum tersedia.',
            textAlign:
            TextAlign.center,
            style:
            TextStyle(
              fontSize: 9.5,
              color: Colors
                  .grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FULL GALLERY
  // ============================================================

  void _showFullGallery(
      _PhotoCategory category,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled:
      true,
      backgroundColor:
      Colors.transparent,
      builder:
          (sheetContext) {
        return Container(
          height:
          MediaQuery.of(
            context,
          ).size.height *
              0.86,
          decoration:
          const BoxDecoration(
            color:
            Colors.white,
            borderRadius:
            BorderRadius.vertical(
              top: Radius.circular(
                28,
              ),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(
                height: 10,
              ),

              Container(
                width: 40,
                height: 4,
                decoration:
                BoxDecoration(
                  color: Colors
                      .grey.shade300,
                  borderRadius:
                  BorderRadius
                      .circular(
                    10,
                  ),
                ),
              ),

              Padding(
                padding:
                const EdgeInsets.all(
                  18,
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
                            'Foto ${category.title}',
                            style:
                            primaryTextStyle
                                .copyWith(
                              fontSize:
                              17,
                              fontWeight:
                              bold,
                              color:
                              const Color(
                                0xFF252637,
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 3,
                          ),

                          Text(
                            '${category.photos.length} dokumentasi',
                            style:
                            TextStyle(
                              fontSize:
                              9.5,
                              color: Colors
                                  .grey
                                  .shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      onPressed:
                          () =>
                          Navigator.pop(
                            sheetContext,
                          ),
                      icon:
                      const Icon(
                        Icons
                            .close_rounded,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child:
                GridView.builder(
                  padding:
                  const EdgeInsets
                      .fromLTRB(
                    18,
                    0,
                    18,
                    24,
                  ),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                    3,
                    crossAxisSpacing:
                    8,
                    mainAxisSpacing:
                    8,
                  ),
                  itemCount:
                  category
                      .photos.length,
                  itemBuilder:
                      (
                      context,
                      index,
                      ) {
                    return GestureDetector(
                      onTap:
                          () {
                        Navigator.pop(
                          sheetContext,
                        );

                        _showPhotoViewer(
                          photos:
                          category.photos,
                          initialIndex:
                          index,
                        );
                      },
                      child:
                      ClipRRect(
                        borderRadius:
                        BorderRadius
                            .circular(
                          13,
                        ),
                        child:
                        Image.network(
                          category
                              .photos[
                          index],
                          fit:
                          BoxFit.cover,
                          headers: {
                            'Authorization':
                            'Bearer $_token',
                            'Accept':
                            'image/*',
                          },
                          errorBuilder:
                              (
                              _,
                              __,
                              ___,
                              ) =>
                              Container(
                                color: Colors
                                    .grey
                                    .shade100,
                                child: Icon(
                                  Icons
                                      .broken_image_outlined,
                                  color: Colors
                                      .grey
                                      .shade400,
                                ),
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
      },
    );
  }

  // ============================================================
  // PHOTO VIEWER
  // ============================================================

  void _showPhotoViewer({
    required List<String> photos,
    required int initialIndex,
  }) {
    showDialog(
      context: context,
      barrierColor:
      Colors.black.withValues(
        alpha: 0.96,
      ),
      builder:
          (dialogContext) {
        return _PhotoViewerDialog(
          photos: photos,
          initialIndex:
          initialIndex,
          token: _token!,
        );
      },
    );
  }

  // ============================================================
  // TOKEN ERROR
  // ============================================================

  Widget _buildTokenError() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(
          30,
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment
              .center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration:
              BoxDecoration(
                color: Colors.red
                    .withValues(
                  alpha: 0.10,
                ),
                borderRadius:
                BorderRadius
                    .circular(
                  22,
                ),
              ),
              child:
              const Icon(
                Icons
                    .lock_outline_rounded,
                color:
                Colors.red,
                size: 30,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            Text(
              'Sesi Tidak Tersedia',
              style:
              primaryTextStyle
                  .copyWith(
                fontSize: 16,
                fontWeight:
                bold,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              'Token tidak ditemukan. Silakan login kembali.',
              textAlign:
              TextAlign.center,
              style:
              TextStyle(
                fontSize: 10.5,
                color: Colors
                    .grey.shade600,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            OutlinedButton(
              onPressed: () =>
                  Navigator.pop(
                    context,
                  ),
              child:
              const Text(
                'Kembali',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // COMMON
  // ============================================================

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration:
          BoxDecoration(
            color: color
                .withValues(
              alpha: 0.11,
            ),
            borderRadius:
            BorderRadius.circular(
              14,
            ),
          ),
          child: Icon(
            icon,
            size: 19,
            color: color,
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
                primaryTextStyle
                    .copyWith(
                  fontSize: 14,
                  fontWeight:
                  bold,
                  color:
                  const Color(
                    0xFF202236,
                  ),
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                subtitle,
                style:
                TextStyle(
                  fontSize: 9.5,
                  color: Colors
                      .grey.shade600,
                  fontWeight:
                  FontWeight
                      .w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius:
      BorderRadius.circular(
        20,
      ),
      border: Border.all(
        color: const Color(
          0xFFE8EAF1,
        ),
        width: 1,
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
            7,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Padding(
      padding:
      const EdgeInsets
          .symmetric(
        vertical: 10,
      ),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Colors
            .grey.shade200,
      ),
    );
  }

  // ============================================================
  // ROOM PARSER
  // ============================================================

  _RoomInfo _extractRoom(
      Map<String, dynamic> item,
      Map<String, dynamic> ac,
      ) {
    Map<String, dynamic> room =
    {};

    if (ac['room'] is Map) {
      room =
      Map<String, dynamic>.from(
        ac['room'],
      );
    } else if (item['room']
    is Map) {
      room =
      Map<String, dynamic>.from(
        item['room'],
      );
    }

    final roomName =
    _firstNonEmpty([
      room['name'],
      room['nama'],
      ac['room_name'],
      ac['nama_room'],
      item['room_name'],
      item['nama_room'],
    ]);

    dynamic floorRaw =
        room['floor'] ??
            room['lantai'] ??
            ac['floor'] ??
            ac['lantai'] ??
            item['floor'] ??
            item['lantai'];

    String floorName =
        '';

    // ==========================================================
    // FLOOR BERBENTUK MAP
    // ==========================================================

    if (floorRaw is Map) {
      final floorMap =
      Map<String, dynamic>.from(
        floorRaw,
      );

      floorName =
          _firstNonEmpty([
            floorMap['name'],
            floorMap['nama'],
          ]);

      if (floorName
          .isEmpty) {
        final number =
            floorMap[
            'number'] ??
                floorMap[
                'nomor'] ??
                floorMap['id'];

        if (number !=
            null) {
          floorName =
          'Lantai $number';
        }
      }
    }

    // ==========================================================
    // FLOOR STRING / INTEGER
    // ==========================================================

    else if (floorRaw !=
        null) {
      final value =
      floorRaw
          .toString()
          .trim();

      if (value.isNotEmpty &&
          value.toLowerCase() !=
              'null' &&
          value != '-') {
        floorName = value
            .toLowerCase()
            .contains(
          'lantai',
        )
            ? value
            : 'Lantai $value';
      }
    }

    // ==========================================================
    // FALLBACK
    // ==========================================================

    if (floorName.isEmpty) {
      final floorNumber =
          room[
          'floor_number'] ??
              room[
              'lantai_number'] ??
              ac[
              'floor_number'] ??
              ac[
              'lantai_number'];

      if (floorNumber !=
          null) {
        floorName =
        'Lantai $floorNumber';
      }
    }

    return _RoomInfo(
      name:
      roomName,
      floor:
      floorName,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _firstNonEmpty(
      List<dynamic> values,
      ) {
    for (final value
    in values) {
      if (value == null) {
        continue;
      }

      // Jangan mengubah Map menjadi "{id: ...}"
      if (value is Map) {
        continue;
      }

      final text =
      value
          .toString()
          .trim();

      if (text.isNotEmpty &&
          text.toLowerCase() !=
              'null' &&
          text != '-') {
        return text;
      }
    }

    return '';
  }

  DateTime? _parseDate(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    final text =
    value
        .toString()
        .trim();

    if (text.isEmpty ||
        text.toLowerCase() ==
            'null') {
      return null;
    }

    return DateTime.tryParse(
      text,
    );
  }

  String _formatDateTime(
      DateTime date,
      ) {
    return '${_formatDate(date)} • ${_formatTime(date)}';
  }

  String _formatDate(
      DateTime date,
      ) {
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

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  String _formatTime(
      DateTime date,
      ) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(
      Duration duration,
      ) {
    if (duration.inMinutes <
        1) {
      return '< 1 menit';
    }

    if (duration.inHours <
        1) {
      return '${duration.inMinutes} menit';
    }

    if (duration.inDays <
        1) {
      final hours =
          duration.inHours;

      final minutes =
          duration.inMinutes %
              60;

      if (minutes == 0) {
        return '$hours jam';
      }

      return '$hours jam $minutes menit';
    }

    final days =
        duration.inDays;

    final hours =
        duration.inHours %
            24;

    if (hours == 0) {
      return '$days hari';
    }

    return '$days hari $hours jam';
  }

  Color _getStatusColor(
      String status,
      ) {
    switch (status
        .toLowerCase()) {
      case 'menunggu_konfirmasi':
      case 'menunggukonfirmasi':
        return Colors.orange;

      case 'ditugaskan':
        return Colors.blue;

      case 'dikerjakan':
        return Colors.purple;

      case 'selesai':
        return Colors.green;

      case 'batal':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(
      String status,
      ) {
    switch (status
        .toLowerCase()) {
      case 'menunggu_konfirmasi':
      case 'menunggukonfirmasi':
        return Icons
            .access_time_rounded;

      case 'ditugaskan':
        return Icons
            .person_outline_rounded;

      case 'dikerjakan':
        return Icons
            .engineering_rounded;

      case 'selesai':
        return Icons
            .check_circle_rounded;

      case 'batal':
        return Icons
            .cancel_rounded;

      default:
        return Icons
            .info_outline_rounded;
    }
  }

  String _getStatusDisplay(
      String status,
      ) {
    switch (status
        .toLowerCase()) {
      case 'menunggu_konfirmasi':
      case 'menunggukonfirmasi':
        return 'Menunggu';

      case 'ditugaskan':
        return 'Ditugaskan';

      case 'dikerjakan':
        return 'Dikerjakan';

      case 'selesai':
        return 'Selesai';

      case 'batal':
        return 'Dibatalkan';

      default:
        return status.isEmpty
            ? '-'
            : status;
    }
  }
}

// ============================================================
// ROOM INFO
// ============================================================

class _RoomInfo {
  final String name;
  final String floor;

  const _RoomInfo({
    required this.name,
    required this.floor,
  });
}

// ============================================================
// PHOTO CATEGORY
// ============================================================

class _PhotoCategory {
  final String title;
  final List<String> photos;
  final Color color;

  const _PhotoCategory({
    required this.title,
    required this.photos,
    required this.color,
  });
}

// ============================================================
// PHOTO VIEWER
// ============================================================

class _PhotoViewerDialog
    extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;
  final String token;

  const _PhotoViewerDialog({
    required this.photos,
    required this.initialIndex,
    required this.token,
  });

  @override
  State<_PhotoViewerDialog>
  createState() =>
      _PhotoViewerDialogState();
}

class _PhotoViewerDialogState
    extends State<
        _PhotoViewerDialog> {
  late final PageController
  _controller;

  late int _currentIndex;

  @override
  void initState() {
    super.initState();

    _currentIndex =
        widget.initialIndex;

    _controller =
        PageController(
          initialPage:
          widget.initialIndex,
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Dialog.fullscreen(
      backgroundColor:
      Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller:
              _controller,
              itemCount:
              widget.photos.length,
              onPageChanged:
                  (index) {
                setState(() {
                  _currentIndex =
                      index;
                });
              },
              itemBuilder: (
                  context,
                  index,
                  ) {
                return InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Center(
                    child:
                    Image.network(
                      widget
                          .photos[index],
                      fit:
                      BoxFit.contain,
                      headers: {
                        'Authorization':
                        'Bearer ${widget.token}',
                        'Accept':
                        'image/*',
                      },
                      loadingBuilder:
                          (
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
                      errorBuilder:
                          (
                          _,
                          __,
                          ___,
                          ) {
                        return Center(
                          child:
                          Column(
                            mainAxisSize:
                            MainAxisSize
                                .min,
                            children: [
                              Icon(
                                Icons
                                    .broken_image_outlined,
                                size:
                                44,
                                color: Colors
                                    .white
                                    .withValues(
                                  alpha:
                                  0.65,
                                ),
                              ),
                              const SizedBox(
                                height:
                                10,
                              ),
                              const Text(
                                'Foto tidak dapat ditampilkan',
                                style:
                                TextStyle(
                                  color:
                                  Colors.white70,
                                  fontSize:
                                  12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),

            Positioned(
              top: 12,
              left: 14,
              child:
              CircleAvatar(
                backgroundColor:
                Colors.black
                    .withValues(
                  alpha: 0.55,
                ),
                child:
                IconButton(
                  onPressed: () =>
                      Navigator.pop(
                        context,
                      ),
                  icon:
                  const Icon(
                    Icons
                        .close_rounded,
                    color:
                    Colors.white,
                  ),
                ),
              ),
            ),

            if (widget
                .photos.length >
                1)
              Positioned(
                top: 18,
                right: 20,
                child:
                Container(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal:
                    11,
                    vertical:
                    6,
                  ),
                  decoration:
                  BoxDecoration(
                    color: Colors.black
                        .withValues(
                      alpha: 0.55,
                    ),
                    borderRadius:
                    BorderRadius
                        .circular(
                      20,
                    ),
                  ),
                  child:
                  Text(
                    '${_currentIndex + 1}/${widget.photos.length}',
                    style:
                    const TextStyle(
                      color:
                      Colors.white,
                      fontSize:
                      11,
                      fontWeight:
                      FontWeight
                          .w600,
                    ),
                  ),
                ),
              ),

            if (widget
                .photos.length >
                1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 18,
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .center,
                  children:
                  List.generate(
                    widget.photos
                        .length,
                        (index) {
                      final active =
                          index ==
                              _currentIndex;

                      return AnimatedContainer(
                        duration:
                        const Duration(
                          milliseconds:
                          180,
                        ),
                        margin:
                        const EdgeInsets
                            .symmetric(
                          horizontal:
                          3,
                        ),
                        width: active
                            ? 18
                            : 6,
                        height: 6,
                        decoration:
                        BoxDecoration(
                          color: active
                              ? Colors
                              .white
                              : Colors
                              .white
                              .withValues(
                            alpha:
                            0.35,
                          ),
                          borderRadius:
                          BorderRadius
                              .circular(
                            20,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}