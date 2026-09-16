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
import '../../services/notification_service.dart';

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

  static const Color _successColor = Color(0xFF16A34A);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
          (_) async {
        await NotificationService.instance
            .requestPermission();

        if (!mounted) return;

        await _loadHomeData();
      },
    );
  }

  Future<void> _loadHomeData() async {
    final masterProvider =
    context.read<ClientMasterProvider>();

    final acProvider =
    context.read<ClientAcProvider>();

    final servisProvider =
    context.read<ClientServisProvider>();

    await masterProvider.fetchLokasi();

    if (!mounted) return;

    await Future.wait([
      acProvider.fetchAllAcByLocations(
        masterProvider.lokasi,
      ),
      servisProvider.fetchAllServis(),
    ]);

    if (!mounted) return;

    await _scheduleMaintenanceNotifications(
      masterProvider.lokasi,
      acProvider.acByLocation,
    );
  }

  Future<void> _scheduleMaintenanceNotifications(
      List<LokasiModel> lokasiList,
      Map<int, List<AcModel>> acByLocation,
      ) async {
    for (final lokasi in lokasiList) {
      final acList =
          acByLocation[lokasi.id] ??
              <AcModel>[];

      if (acList.isEmpty) {
        continue;
      }

      final intervalMonths =
      _getServiceIntervalMonths(
        lokasi,
      );

      // ==========================================================
      // GROUP AC BERDASARKAN TANGGAL SERVICE BERIKUTNYA
      //
      // Contoh:
      //
      // AC 1  -> 27 Sep 2026
      // AC 2  -> 27 Sep 2026
      // AC 3  -> 28 Sep 2026
      //
      // Hasil:
      //
      // 27 Sep = 2 AC
      // 28 Sep = 1 AC
      //
      // ==========================================================

      final groupedByDate =
      <DateTime, List<AcModel>>{};

      for (final ac in acList) {
        final nextService =
        _getNextServiceDateForAc(
          ac,
          intervalMonths,
        );

        // AC belum pernah service
        if (nextService == null) {
          continue;
        }

        // Normalisasi agar jam tidak mempengaruhi grouping
        final serviceDate =
        DateTime(
          nextService.year,
          nextService.month,
          nextService.day,
        );

        groupedByDate.putIfAbsent(
          serviceDate,
              () => <AcModel>[],
        );

        groupedByDate[serviceDate]!.add(
          ac,
        );
      }

      // ==========================================================
      // SCHEDULE 1 NOTIF UNTUK 1 TANGGAL
      // ==========================================================

      for (final entry
      in groupedByDate.entries) {
        final serviceDate =
            entry.key;

        final acGroup =
            entry.value;

        if (acGroup.isEmpty) {
          continue;
        }

        await NotificationService.instance
            .scheduleMaintenanceReminder(
          locationId:
          lokasi.id,
          locationName:
          lokasi.nama,
          totalAc:
          acGroup.length,
          nextServiceDate:
          serviceDate,
        );
      }
    }
  }

  // ============================================================
  // USER
  // ============================================================

  String _getNamaUser(
      BuildContext context,
      ) {
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
      isScrollControlled: true,
      builder: (sheetContext) {
        final nama = _getNamaUser(
          context,
        );

        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.fromLTRB(
              18,
              11,
              18,
              18,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                24,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.08,
                  ),
                  blurRadius: 28,
                  offset: const Offset(
                    0,
                    14,
                  ),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(
                      20,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(
                      alpha: 0.09,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.user,
                    color: kPrimaryColor,
                    size: 27,
                  ),
                ),

                const SizedBox(
                  height: 11,
                ),

                Text(
                  nama,
                  textAlign: TextAlign.center,
                  style: primaryTextStyle.copyWith(
                    fontSize: 17,
                    fontWeight: bold,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  'Akun Klien',
                  style: greyTextStyle.copyWith(
                    fontSize: 11,
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(
                        sheetContext,
                      );

                      _confirmLogout();
                    },
                    borderRadius: BorderRadius.circular(
                      15,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(
                          alpha: 0.055,
                        ),
                        borderRadius: BorderRadius.circular(
                          15,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(
                                11,
                              ),
                            ),
                            child: Icon(
                              Iconsax.logout_1,
                              color: Colors.red[500],
                              size: 18,
                            ),
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          Expanded(
                            child: Text(
                              'Keluar dari akun',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.red[500],
                              ),
                            ),
                          ),

                          Icon(
                            Iconsax.arrow_right_3,
                            size: 15,
                            color: Colors.red[300],
                          ),
                        ],
                      ),
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
  Widget build(
      BuildContext context,
      ) {
    final masterProvider = context.watch<ClientMasterProvider>();
    final acProvider = context.watch<ClientAcProvider>();
    final servisProvider = context.watch<ClientServisProvider>();

    final lokasiList = masterProvider.lokasi;
    final allAc = acProvider.allAc;
    final activeServis = servisProvider.allActiveServis;

    final totalLokasi = lokasiList.length;
    final totalAc = allAc.length;

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
                  18,
                  14,
                  18,
                  120,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      // ====================================================
                      // HEADER
                      // ====================================================

                      _buildHeader(),

                      const SizedBox(
                        height: 24,
                      ),

                      // ====================================================
                      // SUMMARY
                      // ====================================================

                      _buildSectionHeader(
                        title: 'Ringkasan',
                        subtitle: 'Informasi aset AC Anda',
                      ),

                      const SizedBox(
                        height: 12,
                      ),

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
                                backgroundColor: const Color(
                                  0xFFF1F3FF,
                                ),
                                iconColor: kPrimaryColor,
                              ),
                            ),

                            const SizedBox(
                              width: 10,
                            ),

                            Expanded(
                              child: _buildSummaryCard(
                                icon: Iconsax.building_4,
                                value: totalLokasi.toString(),
                                title: 'Lokasi',
                                backgroundColor: const Color(
                                  0xFFF0F8F6,
                                ),
                                iconColor: const Color(
                                  0xFF2F8B7E,
                                ),
                              ),
                            ),
                          ],
                        ),

                      if (masterProvider.error != null &&
                          lokasiList.isEmpty) ...[
                        const SizedBox(
                          height: 10,
                        ),
                        _buildErrorCard(
                          masterProvider.error!,
                        ),
                      ],

                      if (acProvider.allError != null &&
                          allAc.isEmpty) ...[
                        const SizedBox(
                          height: 10,
                        ),
                        _buildErrorCard(
                          acProvider.allError!,
                        ),
                      ],

                      const SizedBox(
                        height: 28,
                      ),

                      // ====================================================
                      // ACTIVE SERVICE
                      // ====================================================

                      _buildSectionHeader(
                        title: 'Servis Berjalan',
                        subtitle:
                        'Permintaan dan pengerjaan yang belum selesai',
                        actionText:
                        activeServis.isNotEmpty ? 'Lihat Semua' : null,
                        onAction: widget.onOpenServis,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

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

                      const SizedBox(
                        height: 28,
                      ),

                      // ====================================================
                      // MAINTENANCE
                      // ====================================================

                      _buildSectionHeader(
                        title: 'Pengingat Servis AC',
                        subtitle:
                        'Lokasi yang paling membutuhkan perhatian',
                        actionText: lokasiList.length > _maxMaintenanceHome
                            ? 'Lihat Semua'
                            : null,
                        onAction: widget.onOpenDaftarAc,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      if (acProvider.loadingAll && allAc.isEmpty)
                        _buildMaintenanceLoading()
                      else
                        _buildMaintenanceSchedule(
                          lokasiList,
                          acProvider.acByLocation,
                        ),

                      const SizedBox(
                        height: 20,
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        18,
        16,
        14,
        16,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF535EC4),
            Color(0xFF34479D),
          ],
        ),
        borderRadius: BorderRadius.circular(
          23,
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(
              alpha: 0.18,
            ),
            blurRadius: 22,
            offset: const Offset(
              0,
              8,
            ),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -25,
            top: -45,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: 0.04,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, ${_getNamaUser(context)}!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: whiteTextStyle.copyWith(
                        fontSize: 19,
                        fontWeight: bold,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      'Pantau aset dan servis AC Anda',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.white.withValues(
                          alpha: 0.72,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openAccountMenu,
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.13,
                      ),
                      borderRadius: BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: const Icon(
                      Iconsax.user,
                      color: Colors.white,
                      size: 20,
                    ),
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
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader({
    required String title,
    String? subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: primaryTextStyle.copyWith(
                  fontSize: 17,
                  fontWeight: bold,
                ),
              ),

              if (subtitle != null) ...[
                const SizedBox(
                  height: 3,
                ),
                Text(
                  subtitle,
                  style: greyTextStyle.copyWith(
                    fontSize: 10,
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
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 3,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionText,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
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
      height: 84,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(
          19,
        ),
        border: Border.all(
          color: iconColor.withValues(
            alpha: 0.07,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.025,
            ),
            blurRadius: 14,
            offset: const Offset(
              0,
              5,
            ),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: iconColor.withValues(
                alpha: 0.09,
              ),
              borderRadius: BorderRadius.circular(
                13,
              ),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),

          const SizedBox(
            width: 11,
          ),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: primaryTextStyle.copyWith(
                    fontSize: 20,
                    height: 1,
                    fontWeight: bold,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  title,
                  style: greyTextStyle.copyWith(
                    fontSize: 10,
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
            height: 84,
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: _buildLoadingBox(
            height: 84,
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

    final raw = servis.lokasiData?['id'];

    if (raw is int) {
      return raw;
    }

    return int.tryParse(
      raw?.toString() ?? '',
    );
  }

  DateTime? _getLatestServiceDate(
      List<ServisModel> servisList,
      ) {
    DateTime? latest;

    for (final servis in servisList) {
      final date = servis.tanggalBerkunjung;

      if (date == null) {
        continue;
      }

      if (latest == null || date.isAfter(latest)) {
        latest = date;
      }
    }

    return latest;
  }

  Widget _buildActiveServiceList(
      List<ServisModel> servisList,
      List<LokasiModel> lokasiList,
      ClientServisProvider provider,
      ) {
    final grouped = <int, List<ServisModel>>{};

    for (final servis in servisList) {
      final locationId = _getServiceLocationId(
        servis,
      );

      if (locationId == null) {
        continue;
      }

      grouped.putIfAbsent(
        locationId,
            () => <ServisModel>[],
      );

      grouped[locationId]!.add(
        servis,
      );
    }

    final entries = grouped.entries.toList();

    // ==========================================================
    // URUTKAN BERDASARKAN TANGGAL SERVICE TERBARU
    // ==========================================================

    entries.sort(
          (a, b) {
        final dateA = _getLatestServiceDate(
          a.value,
        );

        final dateB = _getLatestServiceDate(
          b.value,
        );

        if (dateA == null && dateB == null) {
          final priorityA = _getHighestServicePriority(
            a.value,
            provider,
          );

          final priorityB = _getHighestServicePriority(
            b.value,
            provider,
          );

          return priorityB.compareTo(
            priorityA,
          );
        }

        if (dateA == null) {
          return 1;
        }

        if (dateB == null) {
          return -1;
        }

        final dateCompare = dateB.compareTo(
          dateA,
        );

        if (dateCompare != 0) {
          return dateCompare;
        }

        final priorityA = _getHighestServicePriority(
          a.value,
          provider,
        );

        final priorityB = _getHighestServicePriority(
          b.value,
          provider,
        );

        return priorityB.compareTo(
          priorityA,
        );
      },
    );

    if (entries.isEmpty) {
      return _buildEmptyActiveService();
    }

    final visibleEntries = entries
        .take(
      _maxActiveServiceHome,
    )
        .toList();

    return Column(
      children: [
        ...List.generate(
          visibleEntries.length,
              (index) {
            final entry = visibleEntries[index];

            final lokasi = _findLocation(
              lokasiList,
              entry.key,
            );

            return Padding(
              padding: EdgeInsets.only(
                bottom: index ==
                    visibleEntries.length - 1
                    ? 0
                    : 10,
              ),
              child: _buildActiveServiceCard(
                lokasi: lokasi,
                servisList: entry.value,
                provider: provider,
              ),
            );
          },
        ),

        if (entries.length > _maxActiveServiceHome) ...[
          const SizedBox(
            height: 11,
          ),
          _buildMoreInfoBar(
            text:
            'Menampilkan $_maxActiveServiceHome dari ${entries.length} lokasi servis aktif',
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

    final technicianNames = <String>{};

    DateTime? latestVisitDate;

    for (final servis in servisList) {
      if (servis.itemsData.isNotEmpty) {
        totalAc += servis.itemsData.length;
      } else if (servis.jumlahAc > 0) {
        totalAc += servis.jumlahAc;
      } else if (servis.acUnitId != null) {
        totalAc++;
      }

      final visitDate = servis.tanggalBerkunjung;

      if (visitDate != null) {
        if (latestVisitDate == null ||
            visitDate.isAfter(
              latestVisitDate,
            )) {
          latestVisitDate = visitDate;
        }
      }

      for (final technician in servis.techniciansData) {
        final name =
        (technician['name'] ??
            technician['nama'] ??
            '')
            .toString()
            .trim();

        if (name.isNotEmpty) {
          technicianNames.add(
            name,
          );
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

      for (final item in servis.itemsData) {
        final technician = item['technician'];

        if (technician is Map) {
          final map = Map<String, dynamic>.from(
            technician,
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

    final highestStatus = _getHighestServiceStatus(
      servisList,
      provider,
    );

    final statusInfo = _getServiceStatusInfo(
      highestStatus,
    );

    final rawLocationName =
        lokasi?.nama ?? servisList.first.lokasiNama;

    final locationName =
    rawLocationName.trim().isEmpty ||
        rawLocationName.trim() == '-'
        ? 'Lokasi Service'
        : rawLocationName.trim();

    final technicianText = technicianNames.isEmpty
        ? 'Belum ditugaskan'
        : technicianNames.join(
      ', ',
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onOpenServis,
        borderRadius: BorderRadius.circular(
          18,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              18,
            ),
            border: Border.all(
              color: statusInfo.color.withValues(
                alpha: 0.09,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.028,
                ),
                blurRadius: 13,
                offset: const Offset(
                  0,
                  4,
                ),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              18,
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    color: statusInfo.color,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    15,
                    13,
                    13,
                    13,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 43,
                            height: 43,
                            decoration: BoxDecoration(
                              color: statusInfo.color.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(
                                13,
                              ),
                            ),
                            child: Icon(
                              statusInfo.icon,
                              size: 19,
                              color: statusInfo.color,
                            ),
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  locationName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: primaryTextStyle.copyWith(
                                    fontSize: 13,
                                    height: 1.25,
                                    fontWeight: bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 5,
                                ),

                                Wrap(
                                  spacing: 6,
                                  runSpacing: 5,
                                  children: [
                                    _buildActiveServiceMeta(
                                      icon: Iconsax.setting_2,
                                      text:
                                      '${servisList.length} pekerjaan',
                                      color: statusInfo.color,
                                    ),
                                    _buildActiveServiceMeta(
                                      icon: Iconsax.cpu,
                                      text: '$totalAc AC',
                                      color: kPrimaryColor,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(
                            width: 7,
                          ),

                          _buildSmallStatusBadge(
                            text: statusInfo.label,
                            color: statusInfo.color,
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(
                          11,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF7F8FB,
                          ),
                          borderRadius: BorderRadius.circular(
                            12,
                          ),
                        ),
                        child: Column(
                          children: [
                            if (latestVisitDate != null)
                              _buildActiveServiceInfo(
                                icon: Iconsax.calendar_1,
                                title: 'Jadwal Kunjungan',
                                value: _formatServiceDateTime(
                                  latestVisitDate,
                                ),
                                iconColor: statusInfo.color,
                              ),

                            if (latestVisitDate != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Container(
                                  height: 1,
                                  color: Colors.grey[200],
                                ),
                              ),

                            _buildActiveServiceInfo(
                              icon: Iconsax.profile_2user,
                              title: technicianNames.length > 1
                                  ? 'Tim Teknisi'
                                  : 'Teknisi',
                              value: technicianText,
                              iconColor: technicianNames.isEmpty
                                  ? Colors.grey
                                  : kPrimaryColor,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      Row(
                        children: [
                          const Text(
                            'Lihat detail servis',
                            style: TextStyle(
                              color: kPrimaryColor,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(
                            width: 4,
                          ),

                          const Icon(
                            Iconsax.arrow_right_3,
                            size: 13,
                            color: kPrimaryColor,
                          ),

                          const Spacer(),

                          if (latestVisitDate != null)
                            Text(
                              _getRelativeServiceDate(
                                latestVisitDate,
                              ),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 7.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveServiceMeta({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.06,
        ),
        borderRadius: BorderRadius.circular(
          8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: color,
          ),
          const SizedBox(
            width: 4,
          ),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 7.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveServiceInfo({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              9,
            ),
          ),
          child: Icon(
            icon,
            size: 14,
            color: iconColor,
          ),
        ),

        const SizedBox(
          width: 8,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: greyTextStyle.copyWith(
                  fontSize: 7.5,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: primaryTextStyle.copyWith(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatServiceDateTime(
      DateTime date,
      ) {
    return DateFormat(
      'd MMM yyyy • HH:mm',
      'id_ID',
    ).format(
      date.toLocal(),
    );
  }

  String _getRelativeServiceDate(
      DateTime date,
      ) {
    final now = DateTime.now();

    final today = DateUtils.dateOnly(
      now,
    );

    final target = DateUtils.dateOnly(
      date.toLocal(),
    );

    final difference = target.difference(
      today,
    ).inDays;

    if (difference == 0) {
      return 'Hari ini';
    }

    if (difference == 1) {
      return 'Besok';
    }

    if (difference == -1) {
      return 'Kemarin';
    }

    if (difference > 1) {
      return '$difference hari lagi';
    }

    return '${difference.abs()} hari lalu';
  }

  ServisStatus _getHighestServiceStatus(
      List<ServisModel> servisList,
      ClientServisProvider provider,
      ) {
    final statuses = servisList
        .map(
      provider.effectiveStatus,
    )
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

    return ServisStatus.menungguKonfirmasi;
  }

  int _getHighestServicePriority(
      List<ServisModel> servisList,
      ClientServisProvider provider,
      ) {
    final status = _getHighestServiceStatus(
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

  _ServiceStatusInfo _getServiceStatusInfo(
      ServisStatus status,
      ) {
    switch (status) {
      case ServisStatus.dikerjakan:
        return const _ServiceStatusInfo(
          label: 'Dikerjakan',
          color: Color(0xFF9333EA),
          icon: Iconsax.setting_2,
        );

      case ServisStatus.ditugaskan:
        return const _ServiceStatusInfo(
          label: 'Ditugaskan',
          color: Color(0xFF2563EB),
          icon: Iconsax.user_tick,
        );

      case ServisStatus.menungguKonfirmasi:
        return const _ServiceStatusInfo(
          label: 'Menunggu',
          color: Color(0xFFF59E0B),
          icon: Iconsax.clock,
        );

      case ServisStatus.selesai:
        return const _ServiceStatusInfo(
          label: 'Selesai',
          color: Color(0xFF16A34A),
          icon: Iconsax.tick_circle,
        );

      case ServisStatus.batal:
        return const _ServiceStatusInfo(
          label: 'Batal',
          color: Color(0xFFEF4444),
          icon: Iconsax.close_circle,
        );
    }
  }

  Widget _buildEmptyActiveService() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        17,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: Colors.black.withValues(
            alpha: 0.025,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.02,
            ),
            blurRadius: 10,
            offset: const Offset(
              0,
              4,
            ),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: _successColor.withValues(
                alpha: 0.08,
              ),
              borderRadius: BorderRadius.circular(
                13,
              ),
            ),
            child: const Icon(
              Iconsax.tick_circle,
              color: _successColor,
              size: 20,
            ),
          ),

          const SizedBox(
            width: 11,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tidak Ada Servis Berjalan',
                  style: primaryTextStyle.copyWith(
                    fontSize: 12,
                    fontWeight: bold,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  'Semua permintaan servis telah selesai.',
                  style: greyTextStyle.copyWith(
                    fontSize: 9,
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
      height: 125,
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

    final summaries = lokasiList.map(
          (lokasi) {
        final acList =
            acByLocation[lokasi.id] ?? <AcModel>[];

        return _buildMaintenanceSummary(
          lokasi,
          acList,
        );
      },
    ).toList();

    summaries.sort(
          (a, b) {
        if (a.overdueCount != b.overdueCount) {
          return b.overdueCount.compareTo(
            a.overdueCount,
          );
        }

        if (a.neverServicedCount != b.neverServicedCount) {
          return b.neverServicedCount.compareTo(
            a.neverServicedCount,
          );
        }

        if (a.upcomingCount != b.upcomingCount) {
          return b.upcomingCount.compareTo(
            a.upcomingCount,
          );
        }

        final aDate = a.nearestServiceDate;
        final bDate = b.nearestServiceDate;

        if (aDate == null && bDate == null) {
          return a.lokasi.nama.compareTo(
            b.lokasi.nama,
          );
        }

        if (aDate == null) {
          return 1;
        }

        if (bDate == null) {
          return -1;
        }

        return aDate.compareTo(
          bDate,
        );
      },
    );

    final visible = summaries
        .take(
      _maxMaintenanceHome,
    )
        .toList();

    return Column(
      children: [
        ...List.generate(
          visible.length,
              (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == visible.length - 1 ? 0 : 10,
              ),
              child: _buildMaintenanceCard(
                visible[index],
              ),
            );
          },
        ),

        if (summaries.length > _maxMaintenanceHome) ...[
          const SizedBox(
            height: 11,
          ),

          _buildMoreInfoBar(
            text:
            'Menampilkan $_maxMaintenanceHome dari ${summaries.length} lokasi',
            onTap: widget.onOpenDaftarAc,
          ),
        ],
      ],
    );
  }

  // ============================================================
  // MAINTENANCE SUMMARY
  // ============================================================

  _LocationMaintenanceSummary _buildMaintenanceSummary(
      LokasiModel lokasi,
      List<AcModel> acList,
      ) {
    final intervalMonths = _getServiceIntervalMonths(
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
      final lastService = ac.terakhirService;

      if (lastService == null) {
        neverServicedCount++;
        continue;
      }

      final nextService = _getNextServiceDateForAc(
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
        nearestNextService = target;
        nearestAc = ac;
      }

      final difference = target.difference(
        today,
      ).inDays;

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
      neverServicedCount: neverServicedCount,
      lastServiceDate: nearestAc?.terakhirService,
      nearestServiceDate: nearestNextService,
    );
  }

  // ============================================================
  // MAINTENANCE CARD
  // ============================================================

  Widget _buildMaintenanceCard(
      _LocationMaintenanceSummary summary,
      ) {
    final lokasi = summary.lokasi;

    final lastServiceDate = summary.lastServiceDate;

    final nextServiceDate = summary.nearestServiceDate;

    final interval = _getServiceIntervalMonths(
      lokasi,
    );

    final status = _getSummaryStatus(
      summary,
    );

    final visual = _getMaintenanceVisual(
      status,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onOpenDaftarAc,
        borderRadius: BorderRadius.circular(
          19,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                visual.softColor,
                Colors.white,
              ],
            ),
            borderRadius: BorderRadius.circular(
              19,
            ),
            border: Border.all(
              color: status.color.withValues(
                alpha: 0.12,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.025,
                ),
                blurRadius: 13,
                offset: const Offset(
                  0,
                  5,
                ),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(
              14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: status.color.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius: BorderRadius.circular(
                          13,
                        ),
                      ),
                      child: Icon(
                        Iconsax.location,
                        size: 19,
                        color: status.color,
                      ),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lokasi.nama,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: primaryTextStyle.copyWith(
                              fontSize: 13,
                              height: 1.25,
                              fontWeight: bold,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Row(
                            children: [
                              Icon(
                                Icons.ac_unit_rounded,
                                size: 12,
                                color: Colors.grey[500],
                              ),

                              const SizedBox(
                                width: 4,
                              ),

                              Text(
                                '${summary.totalAc} Unit AC',
                                style: greyTextStyle.copyWith(
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      width: 6,
                    ),

                    _buildMaintenanceStatusBadge(
                      status,
                    ),
                  ],
                ),

                const SizedBox(
                  height: 12,
                ),

                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (summary.totalAc == 0)
                      _buildCountBadge(
                        count: 0,
                        label: 'Belum Ada AC',
                        color: Colors.grey,
                      ),

                    if (summary.overdueCount > 0)
                      _buildCountBadge(
                        count: summary.overdueCount,
                        label: 'Perlu Servis',
                        color: Colors.red,
                      ),

                    if (summary.upcomingCount > 0)
                      _buildCountBadge(
                        count: summary.upcomingCount,
                        label: 'Segera',
                        color: Colors.orange,
                      ),

                    if (summary.neverServicedCount > 0)
                      _buildCountBadge(
                        count: summary.neverServicedCount,
                        label: 'Belum Pernah',
                        color: Colors.blueGrey,
                      ),

                    if (summary.totalAc > 0 &&
                        summary.overdueCount == 0 &&
                        summary.upcomingCount == 0 &&
                        summary.neverServicedCount == 0)
                      _buildCountBadge(
                        count: summary.totalAc,
                        label: 'Aman',
                        color: Colors.green,
                      ),
                  ],
                ),

                const SizedBox(
                  height: 12,
                ),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(
                    11,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.75,
                    ),
                    borderRadius: BorderRadius.circular(
                      13,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildMaintenanceDateItem(
                          icon: Iconsax.tick_circle,
                          title: 'Terakhir',
                          value: lastServiceDate != null
                              ? _formatDate(
                            lastServiceDate,
                          )
                              : 'Belum pernah',
                          iconColor: const Color(
                            0xFF3C9B71,
                          ),
                        ),
                      ),

                      Container(
                        width: 1,
                        height: 47,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        color: Colors.grey.withValues(
                          alpha: 0.13,
                        ),
                      ),

                      Expanded(
                        child: _buildMaintenanceDateItem(
                          icon: Iconsax.calendar_1,
                          title: 'Berikutnya',
                          value: nextServiceDate != null
                              ? _formatDate(
                            nextServiceDate,
                          )
                              : summary.neverServicedCount > 0
                              ? 'Perlu dijadwalkan'
                              : '-',
                          iconColor: kPrimaryColor,
                          footer: nextServiceDate != null
                              ? _getCountdownText(
                            nextServiceDate,
                          )
                              : null,
                          footerColor: status.color,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: status.color.withValues(
                          alpha: 0.07,
                        ),
                        borderRadius: BorderRadius.circular(
                          8,
                        ),
                      ),
                      child: Icon(
                        Iconsax.timer_1,
                        size: 13,
                        color: status.color,
                      ),
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    Expanded(
                      child: Text(
                        'Perawatan setiap $interval bulan',
                        style: primaryTextStyle.copyWith(
                          fontSize: 9.5,
                          fontWeight: medium,
                        ),
                      ),
                    ),

                    Icon(
                      Iconsax.arrow_right_3,
                      size: 13,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ],
            ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: iconColor.withValues(
              alpha: 0.08,
            ),
            borderRadius: BorderRadius.circular(
              9,
            ),
          ),
          child: Icon(
            icon,
            size: 14,
            color: iconColor,
          ),
        ),

        const SizedBox(
          width: 7,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: greyTextStyle.copyWith(
                  fontSize: 7.5,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: primaryTextStyle.copyWith(
                  fontSize: 9,
                  fontWeight: bold,
                ),
              ),

              if (footer != null) ...[
                const SizedBox(
                  height: 2,
                ),
                Text(
                  footer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                    color: footerColor ?? Colors.grey,
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
  // MORE INFO
  // ============================================================

  Widget _buildMoreInfoBar({
    required String text,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          13,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: kPrimaryColor.withValues(
              alpha: 0.045,
            ),
            borderRadius: BorderRadius.circular(
              13,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius: BorderRadius.circular(
                    8,
                  ),
                ),
                child: const Icon(
                  Iconsax.more_circle,
                  size: 14,
                  color: kPrimaryColor,
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child: Text(
                  text,
                  style: primaryTextStyle.copyWith(
                    fontSize: 9,
                    fontWeight: medium,
                  ),
                ),
              ),

              const Text(
                'Lihat Semua',
                style: TextStyle(
                  color: kPrimaryColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(
                width: 3,
              ),

              const Icon(
                Iconsax.arrow_right_3,
                size: 12,
                color: kPrimaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BADGES
  // ============================================================

  Widget _buildCountBadge({
    required int count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.065,
        ),
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(
            width: 4,
          ),

          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.07,
        ),
        borderRadius: BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: color.withValues(
            alpha: 0.15,
          ),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
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
    final lastService = ac.terakhirService;

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
    return 3;
  }

  DateTime _addMonths(
      DateTime date,
      int months,
      ) {
    final totalMonthIndex =
        date.year * 12 + (date.month - 1) + months;

    final targetYear = totalMonthIndex ~/ 12;

    final targetMonth = (totalMonthIndex % 12) + 1;

    final lastDayTargetMonth = DateTime(
      targetYear,
      targetMonth + 1,
      0,
    ).day;

    final targetDay = date.day > lastDayTargetMonth
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

    if (summary.neverServicedCount > 0) {
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
        softColor: Color(
          0xFFFFF5F5,
        ),
      );
    }

    if (status.color == Colors.orange) {
      return const _MaintenanceVisual(
        softColor: Color(
          0xFFFFF8ED,
        ),
      );
    }

    if (status.color == Colors.green) {
      return const _MaintenanceVisual(
        softColor: Color(
          0xFFF2FAF5,
        ),
      );
    }

    if (status.color == Colors.blueGrey) {
      return const _MaintenanceVisual(
        softColor: Color(
          0xFFF4F6F8,
        ),
      );
    }

    return const _MaintenanceVisual(
      softColor: Color(
        0xFFF6F7FA,
      ),
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

    final difference = target.difference(
      today,
    ).inDays;

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
    ).format(
      date.toLocal(),
    );
  }

  // ============================================================
  // LOCATION
  // ============================================================

  LokasiModel? _findLocation(
      List<LokasiModel> lokasiList,
      int id,
      ) {
    for (final lokasi in lokasiList) {
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
      padding: const EdgeInsets.all(
        17,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: kPrimaryColor.withValues(
            alpha: 0.06,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(
                alpha: 0.08,
              ),
              borderRadius: BorderRadius.circular(
                13,
              ),
            ),
            child: const Icon(
              Iconsax.calendar_1,
              color: kPrimaryColor,
              size: 20,
            ),
          ),

          const SizedBox(
            width: 11,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Belum Ada Data Perawatan',
                  style: primaryTextStyle.copyWith(
                    fontSize: 12,
                    fontWeight: bold,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  'Informasi perawatan AC akan muncul di sini.',
                  style: greyTextStyle.copyWith(
                    fontSize: 9,
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
        borderRadius: BorderRadius.circular(
          18,
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 21,
          height: 21,
          child: CircularProgressIndicator(
            strokeWidth: 2.3,
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
      padding: const EdgeInsets.all(
        12,
      ),
      decoration: BoxDecoration(
        color: Colors.red.withValues(
          alpha: 0.05,
        ),
        borderRadius: BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: Colors.red.withValues(
            alpha: 0.09,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: Colors.red[500],
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 9,
                color: Colors.red[600],
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