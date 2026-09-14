// lib/pages/klien/klien_page.dart

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/ac_model.dart';
import '../../models/lokasi_model.dart';
import '../../models/servis_model.dart';

import '../../providers/auth_provider.dart';
import '../../providers/client_ac_provider.dart';
import '../../providers/client_master_provider.dart';
import '../../providers/client_servis_provider.dart';

import '../../theme/theme.dart';

class KlienPage extends StatefulWidget {
  final VoidCallback? onOpenServis;
  final VoidCallback? onOpenDaftarAc;

  const KlienPage({
    super.key,
    this.onOpenServis,
    this.onOpenDaftarAc,
  });

  @override
  State<KlienPage> createState() => _KlienPageState();
}

class _KlienPageState extends State<KlienPage> {
  static const int _maxMaintenanceHome = 3;
  static const int _maxActiveServiceHome = 3;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHomeData();
    });
  }

  Future<void> _loadHomeData() async {
    final masterProvider =
    context.read<ClientMasterProvider>();

    final acProvider =
    context.read<ClientAcProvider>();

    final servisProvider =
    context.read<ClientServisProvider>();

    // Lokasi harus diambil dulu karena endpoint AC wajib location_id.
    await masterProvider.fetchLokasi();

    if (!mounted) return;

    await Future.wait([
      acProvider.fetchAllAcByLocations(
        masterProvider.lokasi,
      ),
      servisProvider.fetchAllServis(),
    ]);
  }

  // ============================================================
  // USER
  // ============================================================

  String _getNamaUser(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final name = auth.user?.name?.trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    return 'Klien';
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _confirmLogout() async {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Logout',
      desc: 'Yakin ingin keluar dari aplikasi?',
      btnCancelText: 'Batal',
      btnOkText: 'Keluar',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        await context.read<AuthProvider>().logout();

        if (!mounted) return;

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
              (route) => false,
        );
      },
    ).show();
  }

  // ============================================================
  // ACCOUNT
  // ============================================================

  void _openAccountMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final nama = _getNamaUser(context);

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 22),

                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.user,
                    size: 28,
                    color: kPrimaryColor,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  nama,
                  textAlign: TextAlign.center,
                  style: primaryTextStyle.copyWith(
                    fontSize: 18,
                    fontWeight: bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Akun Klien',
                  style: greyTextStyle.copyWith(
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 22),

                InkWell(
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _confirmLogout();
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.logout_1,
                          color: Colors.red.shade500,
                          size: 21,
                        ),

                        const SizedBox(width: 12),

                        Text(
                          'Keluar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.red.shade500,
                          ),
                        ),

                        const Spacer(),

                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Colors.red.shade300,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refresh() async {
    await _loadHomeData();
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

    final servisProvider =
    context.watch<ClientServisProvider>();

    final lokasiList =
        masterProvider.lokasi;

    final allAc =
        acProvider.allAc;

    final activeServis =
        servisProvider.allActiveServis;

    final totalLokasi =
        lokasiList.length;

    final totalAc =
        allAc.length;

    final isInitialLoading =
        (masterProvider.loading && lokasiList.isEmpty) ||
            (acProvider.loadingAll && allAc.isEmpty);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: kPrimaryColor,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  120,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      // ====================================================
                      // HEADER
                      // ====================================================

                      _buildHeader(),

                      const SizedBox(height: 28),

                      // ====================================================
                      // RINGKASAN
                      // ====================================================

                      _buildSectionHeader(
                        title: 'Ringkasan',
                        subtitle: 'Informasi aset AC Anda',
                      ),

                      const SizedBox(height: 14),

                      if (isInitialLoading)
                        _buildSummaryLoading()
                      else
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                icon: Icons.ac_unit_rounded,
                                value: totalAc.toString(),
                                title: 'Unit AC',
                                backgroundColor:
                                const Color(0xFFF1F4FF),
                                iconColor: kPrimaryColor,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: _buildSummaryCard(
                                icon: Iconsax.building_4,
                                value: totalLokasi.toString(),
                                title: 'Lokasi',
                                backgroundColor:
                                const Color(0xFFF2F8F7),
                                iconColor:
                                const Color(0xFF3B8C80),
                              ),
                            ),
                          ],
                        ),

                      if (masterProvider.error != null &&
                          lokasiList.isEmpty) ...[
                        const SizedBox(height: 12),
                        _buildErrorCard(
                          masterProvider.error!,
                        ),
                      ],

                      if (acProvider.allError != null &&
                          allAc.isEmpty) ...[
                        const SizedBox(height: 12),
                        _buildErrorCard(
                          acProvider.allError!,
                        ),
                      ],

                      const SizedBox(height: 32),

                      // ====================================================
                      // SERVIS BERJALAN
                      // ====================================================

                      _buildSectionHeader(
                        title: 'Servis Berjalan',
                        subtitle:
                        'Permintaan dan pengerjaan yang belum selesai',
                        actionText:
                        activeServis.isNotEmpty
                            ? 'Lihat Semua'
                            : null,
                        onAction: widget.onOpenServis,
                      ),

                      const SizedBox(height: 14),

                      if (servisProvider.loadingAll &&
                          activeServis.isEmpty)
                        _buildServiceLoading()
                      else if (activeServis.isEmpty)
                        _buildEmptyActiveService()
                      else
                        _buildActiveServiceList(
                          activeServis,
                          lokasiList,
                          servisProvider,
                        ),

                      const SizedBox(height: 32),

                      // ====================================================
                      // PENGINGAT SERVIS
                      // ====================================================

                      _buildSectionHeader(
                        title: 'Pengingat Servis AC',
                        subtitle:
                        'Lokasi yang paling membutuhkan perhatian',
                        actionText:
                        lokasiList.length >
                            _maxMaintenanceHome
                            ? 'Lihat Semua'
                            : null,
                        onAction:
                        widget.onOpenDaftarAc,
                      ),

                      const SizedBox(height: 14),

                      if (acProvider.loadingAll &&
                          allAc.isEmpty)
                        _buildMaintenanceLoading()
                      else
                        _buildMaintenanceSchedule(
                          lokasiList,
                          acProvider.acByLocation,
                        ),

                      const SizedBox(height: 20),
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        17,
        15,
        17,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kPrimaryColor,
            const Color(0xFF6372D0),
          ],
        ),
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha: 0.20),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, ${_getNamaUser(context)}!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: whiteTextStyle.copyWith(
                    fontSize: 20,
                    fontWeight: bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Selamat datang kembali',
                  style: whiteTextStyle.copyWith(
                    fontSize: 12.5,
                    fontWeight: regular,
                    color: Colors.white.withValues(
                      alpha: 0.78,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openAccountMenu,
              borderRadius:
              BorderRadius.circular(18),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white
                      .withValues(alpha: 0.15),
                  borderRadius:
                  BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white
                        .withValues(alpha: 0.18),
                  ),
                ),
                child: const Icon(
                  Iconsax.user,
                  color: Colors.white,
                  size: 23,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader({
    required String title,
    String? subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: primaryTextStyle.copyWith(
                  fontSize: 17,
                  fontWeight: bold,
                ),
              ),

              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: greyTextStyle.copyWith(
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),

        if (actionText != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: kPrimaryColor,
              padding:
              const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 2,
              ),
              minimumSize: Size.zero,
              tapTargetSize:
              MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionText,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                FontWeight.w700,
                color: kPrimaryColor,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummaryCard({
    required IconData icon,
    required String value,
    required String title,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor,
            Colors.white,
          ],
        ),
        borderRadius:
        BorderRadius.circular(22),
        border: Border.all(
          color:
          iconColor.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconColor.withValues(
                alpha: 0.10,
              ),
              borderRadius:
              BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style:
                  primaryTextStyle.copyWith(
                    fontSize: 21,
                    height: 1,
                    fontWeight: bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  title,
                  style:
                  greyTextStyle.copyWith(
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLoading() {
    return Row(
      children: [
        Expanded(
          child: _buildLoadingBox(
            height: 80,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildLoadingBox(
            height: 80,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ACTIVE SERVICE
  // ============================================================

  int? _getServiceLocationId(
      ServisModel servis,
      ) {
    if (servis.locationId != null) {
      return servis.locationId;
    }

    final raw =
    servis.lokasiData?['id'];

    if (raw is int) {
      return raw;
    }

    return int.tryParse(
      raw?.toString() ?? '',
    );
  }

  Widget _buildActiveServiceList(
      List<ServisModel> servisList,
      List<LokasiModel> lokasiList,
      ClientServisProvider provider,
      ) {
    final grouped =
    <int, List<ServisModel>>{};

    for (final servis in servisList) {
      final locationId =
      _getServiceLocationId(servis);

      if (locationId == null) {
        continue;
      }

      grouped.putIfAbsent(
        locationId,
            () => [],
      );

      grouped[locationId]!.add(servis);
    }

    final entries =
    grouped.entries.toList();

    entries.sort((a, b) {
      final aPriority =
      _getHighestServicePriority(
        a.value,
        provider,
      );

      final bPriority =
      _getHighestServicePriority(
        b.value,
        provider,
      );

      return bPriority.compareTo(aPriority);
    });

    if (entries.isEmpty) {
      return _buildEmptyActiveService();
    }

    final visibleEntries =
    entries
        .take(_maxActiveServiceHome)
        .toList();

    return Column(
      children: [
        ...List.generate(
          visibleEntries.length,
              (index) {
            final entry =
            visibleEntries[index];

            final lokasi =
            _findLocation(
              lokasiList,
              entry.key,
            );

            return Padding(
              padding: EdgeInsets.only(
                bottom:
                index ==
                    visibleEntries.length -
                        1
                    ? 0
                    : 12,
              ),
              child:
              _buildActiveServiceCard(
                lokasi: lokasi,
                servisList: entry.value,
                provider: provider,
              ),
            );
          },
        ),

        if (entries.length >
            _maxActiveServiceHome) ...[
          const SizedBox(height: 12),
          _buildMoreInfoBar(
            text:
            'Menampilkan $_maxActiveServiceHome dari ${entries.length} lokasi servis',
            onTap: widget.onOpenServis,
          ),
        ],
      ],
    );
  }

  Widget _buildActiveServiceCard({
    LokasiModel? lokasi,
    required List<ServisModel> servisList,
    required ClientServisProvider provider,
  }) {
    int totalAc = 0;

    final technicianNames =
    <String>{};

    DateTime? nearestVisitDate;

    for (final servis in servisList) {
      if (servis.itemsData.isNotEmpty) {
        totalAc += servis.itemsData.length;
      } else if (servis.jumlahAc > 0) {
        totalAc += servis.jumlahAc;
      } else if (servis.acUnitId != null) {
        totalAc++;
      }

      final visitDate =
          servis.tanggalBerkunjung;

      if (visitDate != null) {
        if (nearestVisitDate == null ||
            visitDate.isBefore(
              nearestVisitDate,
            )) {
          nearestVisitDate =
              visitDate;
        }
      }

      for (final t
      in servis.techniciansData) {
        final name =
        (t['name'] ??
            t['nama'] ??
            '')
            .toString()
            .trim();

        if (name.isNotEmpty) {
          technicianNames.add(name);
        }
      }

      final legacyName =
      (servis.teknisiData?['name'] ??
          servis.teknisiData?['nama'] ??
          '')
          .toString()
          .trim();

      if (legacyName.isNotEmpty) {
        technicianNames.add(
          legacyName,
        );
      }

      for (final item
      in servis.itemsData) {
        final tech =
        item['technician'];

        if (tech is Map) {
          final map =
          Map<String, dynamic>.from(
            tech,
          );

          final name =
          (map['name'] ??
              map['nama'] ??
              '')
              .toString()
              .trim();

          if (name.isNotEmpty) {
            technicianNames.add(
              name,
            );
          }
        }
      }
    }

    final highestStatus =
    _getHighestServiceStatus(
      servisList,
      provider,
    );

    final statusInfo =
    _getServiceStatusInfo(
      highestStatus,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onOpenServis,
        borderRadius:
        BorderRadius.circular(23),
        child: Ink(
          width: double.infinity,
          padding:
          const EdgeInsets.all(17),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end:
              Alignment.bottomRight,
              colors: [
                statusInfo.color
                    .withValues(alpha: 0.07),
                Colors.white,
              ],
            ),
            borderRadius:
            BorderRadius.circular(23),
            border: Border.all(
              color: statusInfo.color
                  .withValues(alpha: 0.13),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(
                  alpha: 0.025,
                ),
                blurRadius: 16,
                offset:
                const Offset(0, 7),
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
                  Container(
                    width: 45,
                    height: 45,
                    decoration:
                    BoxDecoration(
                      color: statusInfo.color
                          .withValues(
                        alpha: 0.11,
                      ),
                      borderRadius:
                      BorderRadius
                          .circular(15),
                    ),
                    child: Icon(
                      statusInfo.icon,
                      size: 21,
                      color:
                      statusInfo.color,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Text(
                          lokasi?.nama ??
                              servisList
                                  .first
                                  .lokasiNama,
                          maxLines: 2,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          primaryTextStyle
                              .copyWith(
                            fontSize: 14,
                            fontWeight: bold,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          '${servisList.length} pekerjaan • $totalAc AC',
                          style:
                          greyTextStyle
                              .copyWith(
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  _buildSmallStatusBadge(
                    text:
                    statusInfo.label,
                    color:
                    statusInfo.color,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              if (nearestVisitDate !=
                  null) ...[
                _buildServiceInfoRow(
                  icon:
                  Iconsax.calendar_1,
                  label:
                  'Jadwal Kunjungan',
                  value: _formatDate(
                    nearestVisitDate,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
              ],

              _buildServiceInfoRow(
                icon: Iconsax.user,
                label: 'Teknisi',
                value:
                technicianNames.isEmpty
                    ? 'Belum ditugaskan'
                    : technicianNames
                    .join(', '),
              ),

              const SizedBox(height: 13),

              Row(
                children: [
                  Text(
                    'Lihat detail',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: kPrimaryColor,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons
                        .arrow_forward_rounded,
                    size: 15,
                    color: kPrimaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade500,
        ),

        const SizedBox(width: 7),

        Text(
          label,
          style: greyTextStyle.copyWith(
            fontSize: 10,
          ),
        ),

        const Spacer(),

        const SizedBox(width: 12),

        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style:
            primaryTextStyle.copyWith(
              fontSize: 11,
              fontWeight: medium,
            ),
          ),
        ),
      ],
    );
  }

  ServisStatus _getHighestServiceStatus(
      List<ServisModel> servisList,
      ClientServisProvider provider,
      ) {
    final statuses =
    servisList
        .map(provider.effectiveStatus)
        .toList();

    if (statuses.contains(
      ServisStatus.dikerjakan,
    )) {
      return ServisStatus.dikerjakan;
    }

    if (statuses.contains(
      ServisStatus.ditugaskan,
    )) {
      return ServisStatus.ditugaskan;
    }

    return ServisStatus
        .menungguKonfirmasi;
  }

  int _getHighestServicePriority(
      List<ServisModel> servisList,
      ClientServisProvider provider,
      ) {
    final status =
    _getHighestServiceStatus(
      servisList,
      provider,
    );

    switch (status) {
      case ServisStatus.dikerjakan:
        return 3;

      case ServisStatus.ditugaskan:
        return 2;

      case ServisStatus.menungguKonfirmasi:
        return 1;

      case ServisStatus.selesai:
      case ServisStatus.batal:
        return 0;
    }
  }

  _ServiceStatusInfo
  _getServiceStatusInfo(
      ServisStatus status,
      ) {
    switch (status) {
      case ServisStatus.dikerjakan:
        return const _ServiceStatusInfo(
          label: 'Dikerjakan',
          color: Colors.purple,
          icon: Iconsax.setting_2,
        );

      case ServisStatus.ditugaskan:
        return const _ServiceStatusInfo(
          label: 'Ditugaskan',
          color: Colors.blue,
          icon: Iconsax.user_tick,
        );

      case ServisStatus.menungguKonfirmasi:
        return const _ServiceStatusInfo(
          label: 'Menunggu',
          color: Colors.orange,
          icon: Iconsax.clock,
        );

      case ServisStatus.selesai:
        return const _ServiceStatusInfo(
          label: 'Selesai',
          color: Colors.green,
          icon: Iconsax.tick_circle,
        );

      case ServisStatus.batal:
        return const _ServiceStatusInfo(
          label: 'Batal',
          color: Colors.red,
          icon: Iconsax.close_circle,
        );
    }
  }

  Widget _buildEmptyActiveService() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green
                .withValues(alpha: 0.06),
            Colors.white,
          ],
        ),
        borderRadius:
        BorderRadius.circular(22),
        border: Border.all(
          color: Colors.green
              .withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.green
                  .withValues(alpha: 0.10),
              borderRadius:
              BorderRadius.circular(16),
            ),
            child: const Icon(
              Iconsax.tick_circle,
              color: Colors.green,
              size: 23,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Tidak Ada Servis Berjalan',
                  style:
                  primaryTextStyle.copyWith(
                    fontSize: 13.5,
                    fontWeight: bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Tidak ada permintaan atau pengerjaan servis aktif.',
                  style:
                  greyTextStyle.copyWith(
                    fontSize: 10.5,
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

  Widget _buildServiceLoading() {
    return _buildLoadingBox(
      height: 105,
    );
  }

  // ============================================================
  // MAINTENANCE SCHEDULE
  // ============================================================

  Widget _buildMaintenanceSchedule(
      List<LokasiModel> lokasiList,
      Map<int, List<AcModel>> acByLocation,
      ) {
    if (lokasiList.isEmpty) {
      return _buildEmptyMaintenance();
    }

    final summaries =
    lokasiList.map((lokasi) {
      final acList =
          acByLocation[lokasi.id] ??
              <AcModel>[];

      return _buildMaintenanceSummary(
        lokasi,
        acList,
      );
    }).toList();

    // ==========================================================
    // PRIORITAS:
    // 1. overdue
    // 2. belum pernah
    // 3. segera
    // 4. tanggal paling dekat
    // ==========================================================

    summaries.sort((a, b) {
      if (a.overdueCount !=
          b.overdueCount) {
        return b.overdueCount
            .compareTo(
          a.overdueCount,
        );
      }

      if (a.neverServicedCount !=
          b.neverServicedCount) {
        return b.neverServicedCount
            .compareTo(
          a.neverServicedCount,
        );
      }

      if (a.upcomingCount !=
          b.upcomingCount) {
        return b.upcomingCount
            .compareTo(
          a.upcomingCount,
        );
      }

      final aDate =
          a.nearestServiceDate;

      final bDate =
          b.nearestServiceDate;

      if (aDate == null &&
          bDate == null) {
        return a.lokasi.nama
            .compareTo(b.lokasi.nama);
      }

      if (aDate == null) {
        return 1;
      }

      if (bDate == null) {
        return -1;
      }

      return aDate.compareTo(bDate);
    });

    final visible =
    summaries
        .take(_maxMaintenanceHome)
        .toList();

    return Column(
      children: [
        ...List.generate(
          visible.length,
              (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom:
                index ==
                    visible.length -
                        1
                    ? 0
                    : 12,
              ),
              child:
              _buildMaintenanceCard(
                visible[index],
              ),
            );
          },
        ),

        if (summaries.length >
            _maxMaintenanceHome) ...[
          const SizedBox(height: 12),

          _buildMoreInfoBar(
            text:
            'Menampilkan $_maxMaintenanceHome dari ${summaries.length} lokasi',
            onTap:
            widget.onOpenDaftarAc,
          ),
        ],
      ],
    );
  }

  // ============================================================
  // MAINTENANCE SUMMARY
  // ============================================================

  _LocationMaintenanceSummary
  _buildMaintenanceSummary(
      LokasiModel lokasi,
      List<AcModel> acList,
      ) {
    final intervalMonths =
    _getServiceIntervalMonths(
      lokasi,
    );

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    int overdueCount = 0;
    int upcomingCount = 0;
    int neverServicedCount = 0;

    AcModel? nearestAc;
    DateTime? nearestNextService;

    for (final ac in acList) {
      final lastService =
          ac.terakhirService;

      if (lastService == null) {
        neverServicedCount++;
        continue;
      }

      final nextService =
      _getNextServiceDateForAc(
        ac,
        intervalMonths,
      );

      if (nextService == null) {
        continue;
      }

      final target = DateTime(
        nextService.year,
        nextService.month,
        nextService.day,
      );

      if (nearestNextService == null ||
          target.isBefore(
            nearestNextService,
          )) {
        nearestNextService =
            target;
        nearestAc = ac;
      }

      final difference =
          target.difference(today).inDays;

      if (difference <= 0) {
        overdueCount++;
      } else if (difference <= 14) {
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
      lastServiceDate:
      nearestAc?.terakhirService,
      nearestServiceDate:
      nearestNextService,
    );
  }

  // ============================================================
  // MAINTENANCE CARD
  // ============================================================

  Widget _buildMaintenanceCard(
      _LocationMaintenanceSummary summary,
      ) {
    final lokasi =
        summary.lokasi;

    final lastServiceDate =
        summary.lastServiceDate;

    final nextServiceDate =
        summary.nearestServiceDate;

    final interval =
    _getServiceIntervalMonths(
      lokasi,
    );

    final status =
    _getSummaryStatus(
      summary,
    );

    final visual =
    _getMaintenanceVisual(status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onOpenDaftarAc,
        borderRadius:
        BorderRadius.circular(24),
        child: Ink(
          width: double.infinity,
          padding:
          const EdgeInsets.all(17),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end:
              Alignment.bottomRight,
              colors: [
                visual.softColor,
                Colors.white,
              ],
            ),
            borderRadius:
            BorderRadius.circular(24),
            border: Border.all(
              color: status.color
                  .withValues(alpha: 0.16),
            ),
            boxShadow: [
              BoxShadow(
                color: status.color
                    .withValues(
                  alpha: 0.035,
                ),
                blurRadius: 20,
                offset:
                const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // ==================================================
              // TOP
              // ==================================================

              Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration:
                    BoxDecoration(
                      color: status.color
                          .withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                      BorderRadius
                          .circular(17),
                    ),
                    child: Icon(
                      Iconsax.location,
                      size: 22,
                      color:
                      status.color,
                    ),
                  ),

                  const SizedBox(width: 12),

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
                            fontWeight: bold,
                            height: 1.25,
                          ),
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        Row(
                          children: [
                            Icon(
                              Icons
                                  .ac_unit_rounded,
                              size: 14,
                              color: Colors
                                  .grey
                                  .shade500,
                            ),

                            const SizedBox(
                              width: 5,
                            ),

                            Text(
                              '${summary.totalAc} Unit AC',
                              style:
                              greyTextStyle
                                  .copyWith(
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  _buildMaintenanceStatusBadge(
                    status,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ==================================================
              // COUNT STATUS
              // ==================================================

              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  if (summary.totalAc ==
                      0)
                    _buildCountBadge(
                      count: 0,
                      label: 'Belum Ada AC',
                      color: Colors.grey,
                    ),

                  if (summary.overdueCount >
                      0)
                    _buildCountBadge(
                      count:
                      summary.overdueCount,
                      label:
                      'Perlu Servis',
                      color: Colors.red,
                    ),

                  if (summary.upcomingCount >
                      0)
                    _buildCountBadge(
                      count:
                      summary.upcomingCount,
                      label: 'Segera',
                      color:
                      Colors.orange,
                    ),

                  if (summary
                      .neverServicedCount >
                      0)
                    _buildCountBadge(
                      count: summary
                          .neverServicedCount,
                      label:
                      'Belum Pernah',
                      color:
                      Colors.blueGrey,
                    ),

                  if (summary.totalAc >
                      0 &&
                      summary.overdueCount ==
                          0 &&
                      summary.upcomingCount ==
                          0 &&
                      summary
                          .neverServicedCount ==
                          0)
                    _buildCountBadge(
                      count:
                      summary.totalAc,
                      label: 'Aman',
                      color:
                      Colors.green,
                    ),
                ],
              ),

              const SizedBox(height: 15),

              // ==================================================
              // DATE INFORMATION
              // ==================================================

              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.all(
                  13,
                ),
                decoration:
                BoxDecoration(
                  color: Colors.white
                      .withValues(
                    alpha: 0.72,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    17,
                  ),
                  border: Border.all(
                    color: Colors.white,
                  ),
                ),
                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Expanded(
                      child:
                      _buildMaintenanceDateItem(
                        icon:
                        Iconsax.tick_circle,
                        title:
                        'Terakhir Servis',
                        value:
                        lastServiceDate !=
                            null
                            ? _formatDate(
                          lastServiceDate,
                        )
                            : 'Belum pernah',
                        iconColor:
                        const Color(
                          0xFF3C9B71,
                        ),
                      ),
                    ),

                    Container(
                      width: 1,
                      height: 54,
                      margin:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 10,
                      ),
                      color: Colors.grey
                          .withValues(
                        alpha: 0.13,
                      ),
                    ),

                    Expanded(
                      child:
                      _buildMaintenanceDateItem(
                        icon:
                        Iconsax.calendar_1,
                        title:
                        'Servis Berikutnya',
                        value:
                        nextServiceDate !=
                            null
                            ? _formatDate(
                          nextServiceDate,
                        )
                            : summary.neverServicedCount >
                            0
                            ? 'Perlu dijadwalkan'
                            : '-',
                        iconColor:
                        kPrimaryColor,
                        footer:
                        nextServiceDate !=
                            null
                            ? _getCountdownText(
                          nextServiceDate,
                        )
                            : null,
                        footerColor:
                        status.color,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // INTERVAL
              // ==================================================

              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration:
                    BoxDecoration(
                      color: status.color
                          .withValues(
                        alpha: 0.08,
                      ),
                      borderRadius:
                      BorderRadius
                          .circular(10),
                    ),
                    child: Icon(
                      Iconsax.timer_1,
                      size: 15,
                      color:
                      status.color,
                    ),
                  ),

                  const SizedBox(width: 9),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Text(
                          'Interval Perawatan',
                          style:
                          greyTextStyle
                              .copyWith(
                            fontSize: 9,
                          ),
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        Text(
                          'Setiap $interval bulan',
                          style:
                          primaryTextStyle
                              .copyWith(
                            fontSize: 10.5,
                            fontWeight:
                            medium,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    Icons
                        .arrow_forward_ios_rounded,
                    size: 11,
                    color:
                    Colors.grey.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaintenanceDateItem({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
    String? footer,
    Color? footerColor,
  }) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconColor.withValues(
              alpha: 0.09,
            ),
            borderRadius:
            BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            size: 16,
            color: iconColor,
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
                  fontSize: 8.5,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                value,
                maxLines: 2,
                overflow:
                TextOverflow.ellipsis,
                style:
                primaryTextStyle.copyWith(
                  fontSize: 10.5,
                  fontWeight: bold,
                  height: 1.25,
                ),
              ),

              if (footer != null) ...[
                const SizedBox(height: 3),
                Text(
                  footer,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    footerColor ??
                        Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MORE INFO BAR
  // ============================================================

  Widget _buildMoreInfoBar({
    required String text,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(16),
        child: Ink(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: kPrimaryColor
                .withValues(alpha: 0.055),
            borderRadius:
            BorderRadius.circular(16),
            border: Border.all(
              color: kPrimaryColor
                  .withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: kPrimaryColor
                      .withValues(
                    alpha: 0.09,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    10,
                  ),
                ),
                child: Icon(
                  Iconsax.more_circle,
                  size: 16,
                  color: kPrimaryColor,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  text,
                  style:
                  primaryTextStyle.copyWith(
                    fontSize: 10.5,
                    fontWeight: medium,
                  ),
                ),
              ),

              Text(
                'Lihat Semua',
                style: TextStyle(
                  color: kPrimaryColor,
                  fontSize: 10.5,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),

              const SizedBox(width: 4),

              Icon(
                Icons
                    .arrow_forward_ios_rounded,
                size: 11,
                color: kPrimaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGES
  // ============================================================

  Widget _buildCountBadge({
    required int count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.075,
        ),
        borderRadius:
        BorderRadius.circular(30),
        border: Border.all(
          color: color.withValues(
            alpha: 0.16,
          ),
        ),
      ),
      child: Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight:
              FontWeight.w800,
            ),
          ),

          const SizedBox(width: 4),

          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceStatusBadge(
      _MaintenanceStatus status,
      ) {
    return _buildSmallStatusBadge(
      text: status.label,
      color: status.color,
    );
  }

  Widget _buildSmallStatusBadge({
    required String text,
    required Color color,
  }) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color:
        color.withValues(alpha: 0.08),
        borderRadius:
        BorderRadius.circular(30),
        border: Border.all(
          color:
          color.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight:
          FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ============================================================
  // MAINTENANCE LOGIC
  // ============================================================

  DateTime? _getNextServiceDateForAc(
      AcModel ac,
      int intervalMonths,
      ) {
    final lastService =
        ac.terakhirService;

    if (lastService == null) {
      return null;
    }

    return _addMonths(
      lastService,
      intervalMonths,
    );
  }

  int _getServiceIntervalMonths(
      LokasiModel lokasi,
      ) {
    // SEMENTARA DEFAULT 3 BULAN.
    //
    // Nanti:
    //
    // return lokasi.serviceIntervalMonths;

    return 3;
  }

  DateTime _addMonths(
      DateTime date,
      int months,
      ) {
    final totalMonthIndex =
        date.year * 12 +
            (date.month - 1) +
            months;

    final targetYear =
        totalMonthIndex ~/ 12;

    final targetMonth =
        (totalMonthIndex % 12) + 1;

    final lastDayTargetMonth =
        DateTime(
          targetYear,
          targetMonth + 1,
          0,
        ).day;

    final targetDay =
    date.day > lastDayTargetMonth
        ? lastDayTargetMonth
        : date.day;

    return DateTime(
      targetYear,
      targetMonth,
      targetDay,
    );
  }

  _MaintenanceStatus _getSummaryStatus(
      _LocationMaintenanceSummary summary,
      ) {
    if (summary.totalAc == 0) {
      return const _MaintenanceStatus(
        label: 'Belum Ada AC',
        color: Colors.grey,
      );
    }

    if (summary.overdueCount > 0) {
      return const _MaintenanceStatus(
        label: 'Perlu Servis',
        color: Colors.red,
      );
    }

    if (summary.neverServicedCount >
        0) {
      return const _MaintenanceStatus(
        label: 'Belum Pernah',
        color: Colors.blueGrey,
      );
    }

    if (summary.upcomingCount > 0) {
      return const _MaintenanceStatus(
        label: 'Segera',
        color: Colors.orange,
      );
    }

    return const _MaintenanceStatus(
      label: 'Aman',
      color: Colors.green,
    );
  }

  _MaintenanceVisual _getMaintenanceVisual(
      _MaintenanceStatus status,
      ) {
    if (status.color == Colors.red) {
      return const _MaintenanceVisual(
        softColor: Color(0xFFFFF5F5),
      );
    }

    if (status.color == Colors.orange) {
      return const _MaintenanceVisual(
        softColor: Color(0xFFFFF8ED),
      );
    }

    if (status.color == Colors.green) {
      return const _MaintenanceVisual(
        softColor: Color(0xFFF2FAF5),
      );
    }

    if (status.color ==
        Colors.blueGrey) {
      return const _MaintenanceVisual(
        softColor: Color(0xFFF4F6F8),
      );
    }

    return const _MaintenanceVisual(
      softColor: Color(0xFFF6F7FA),
    );
  }

  String _getCountdownText(
      DateTime nextService,
      ) {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final target = DateTime(
      nextService.year,
      nextService.month,
      nextService.day,
    );

    final difference =
        target.difference(today).inDays;

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

  String _formatDate(
      DateTime date,
      ) {
    return DateFormat(
      'd MMM yyyy',
      'id_ID',
    ).format(date);
  }

  // ============================================================
  // LOCATION
  // ============================================================

  LokasiModel? _findLocation(
      List<LokasiModel> lokasiList,
      int id,
      ) {
    for (final lokasi
    in lokasiList) {
      if (lokasi.id == id) {
        return lokasi;
      }
    }

    return null;
  }

  // ============================================================
  // EMPTY MAINTENANCE
  // ============================================================

  Widget _buildEmptyMaintenance() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kPrimaryColor
                .withValues(alpha: 0.05),
            Colors.white,
          ],
        ),
        borderRadius:
        BorderRadius.circular(22),
        border: Border.all(
          color: kPrimaryColor
              .withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kPrimaryColor
                  .withValues(alpha: 0.09),
              borderRadius:
              BorderRadius.circular(16),
            ),
            child: Icon(
              Iconsax.calendar_1,
              color: kPrimaryColor,
              size: 23,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Belum Ada Data Perawatan',
                  style:
                  primaryTextStyle.copyWith(
                    fontSize: 13.5,
                    fontWeight: bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Informasi perawatan AC akan muncul di sini.',
                  style:
                  greyTextStyle.copyWith(
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceLoading() {
    return _buildLoadingBox(
      height: 130,
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoadingBox({
    required double height,
  }) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(22),
      ),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child:
          CircularProgressIndicator(
            strokeWidth: 2.5,
            color: kPrimaryColor,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorCard(
      String message,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
        Colors.red.withValues(alpha: 0.06),
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red
              .withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: Colors.red.shade500,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 11,
                color:
                Colors.red.shade600,
              ),
            ),
          ),

          TextButton(
            onPressed: _refresh,
            child: const Text(
              'Ulangi',
            ),
          ),
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

  final DateTime? lastServiceDate;
  final DateTime? nearestServiceDate;

  const _LocationMaintenanceSummary({
    required this.lokasi,
    required this.acList,
    required this.overdueCount,
    required this.upcomingCount,
    required this.neverServicedCount,
    required this.lastServiceDate,
    required this.nearestServiceDate,
  });

  int get totalAc => acList.length;
}

// ============================================================
// MAINTENANCE STATUS
// ============================================================

class _MaintenanceStatus {
  final String label;
  final Color color;

  const _MaintenanceStatus({
    required this.label,
    required this.color,
  });
}

// ============================================================
// MAINTENANCE VISUAL
// ============================================================

class _MaintenanceVisual {
  final Color softColor;

  const _MaintenanceVisual({
    required this.softColor,
  });
}

// ============================================================
// SERVICE STATUS
// ============================================================

class _ServiceStatusInfo {
  final String label;
  final Color color;
  final IconData icon;

  const _ServiceStatusInfo({
    required this.label,
    required this.color,
    required this.icon,
  });
}