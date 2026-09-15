import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:ridho_teknik/models/servis_model.dart';
import 'package:ridho_teknik/providers/owner_master_provider.dart';
import 'package:ridho_teknik/theme/theme.dart';

import '../owner_service_detail_page.dart';
import '../owner_service_monitoring_page.dart';

class ServiceListPage extends StatefulWidget {
  const ServiceListPage({super.key});

  @override
  State<ServiceListPage> createState() => _ServiceListPageState();
}

class _ServiceListPageState extends State<ServiceListPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  Timer? _searchDebounce;

  String _selectedStatus = 'Semua';
  String _selectedJenis = 'Semua';
  DateTime? _selectedDate;
  String _searchQuery = '';

  final List<Map<String, dynamic>> _statusChips = [
    {
      'value': 'Semua',
      'display': 'Semua',
      'color': kPrimaryColor,
    },
    {
      'value': 'menunggu_konfirmasi',
      'display': 'Menunggu',
      'color': Colors.orange,
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
    {
      'value': 'batal',
      'display': 'Dibatalkan',
      'color': Colors.red,
    },
  ];

  final List<Map<String, dynamic>> _jenisList = [
    {
      'value': 'Semua',
      'display': 'Semua Jenis',
    },
    {
      'value': 'cuci',
      'display': 'Cuci AC',
    },
    {
      'value': 'perbaikan',
      'display': 'Perbaikan AC',
    },
    {
      'value': 'instalasi',
      'display': 'Instalasi AC',
    },
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    initializeDateFormatting('id_ID', null);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // DATA
  // ============================================================

  Future<void> _loadInitialData() async {
    await context.read<OwnerMasterProvider>().fetchServices();
  }

  Future<void> _refreshData() async {
    await context.read<OwnerMasterProvider>().fetchServices(
      status: _selectedStatus == 'Semua'
          ? null
          : _selectedStatus,
      jenis: _selectedJenis == 'Semua'
          ? null
          : _selectedJenis,
      keyword: _searchQuery.trim().isEmpty
          ? null
          : _searchQuery.trim(),
      startDate: _selectedDate,
      endDate: _selectedDate,
    );
  }

  void _resetFilters() {
    _searchDebounce?.cancel();

    setState(() {
      _selectedStatus = 'Semua';
      _selectedJenis = 'Semua';
      _selectedDate = null;
      _searchQuery = '';
      _searchController.clear();
    });

    _refreshData();
  }

  // ============================================================
  // TECHNICIAN
  // ============================================================

  List<String> _extractTechnicianNames(
      ServisModel service,
      ) {
    final names = <String>[];

    for (final item in service.techniciansData) {
      final name = (item['name'] ?? '')
          .toString()
          .trim();

      if (name.isNotEmpty && !names.contains(name)) {
        names.add(name);
      }
    }

    if (names.isEmpty && service.teknisiData != null) {
      final name = (service.teknisiData?['name'] ?? '')
          .toString()
          .trim();

      if (name.isNotEmpty) {
        names.add(name);
      }
    }

    if (names.isEmpty) {
      final fallback = service.teknisiNama.trim();

      if (fallback.isNotEmpty &&
          fallback != 'Belum ditugaskan') {
        names.add(fallback);
      }
    }

    return names;
  }

  String _technicianDisplay(
      ServisModel service,
      ) {
    final names = _extractTechnicianNames(service);

    if (names.isEmpty) {
      return 'Belum ditugaskan';
    }

    if (names.length == 1) {
      return names.first;
    }

    if (names.length == 2) {
      return names.join(', ');
    }

    return '${names.first} +${names.length - 1}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildAppBar(),
      body: Consumer<OwnerMasterProvider>(
        builder: (
            context,
            provider,
            child,
            ) {
          final services = provider.services;

          return Column(
            children: [
              _buildSearchBar(),

              _buildStatusFilter(),

              _buildJenisFilter(),

              _buildResultHeader(
                services.length,
              ),

              Expanded(
                child: RefreshIndicator(
                  color: kPrimaryColor,
                  onRefresh: _refreshData,
                  child: _buildServicesList(
                    provider,
                    services,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(
          Iconsax.arrow_left_2,
          color: kPrimaryColor,
          size: 20,
        ),
      ),
      title: Text(
        'Jadwal Service',
        style: primaryTextStyle.copyWith(
          fontSize: 18,
          fontWeight: bold,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(
            right: 12,
          ),
          child: Material(
            color: kPrimaryColor.withValues(
              alpha: 0.07,
            ),
            borderRadius: BorderRadius.circular(
              12,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(
                12,
              ),
              onTap: _showDateFilterDialog,
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  Iconsax.calendar,
                  color: kPrimaryColor,
                  size: 19,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        8,
      ),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            15,
          ),
          border: Border.all(
            color: Colors.black.withValues(
              alpha: 0.025,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.025,
              ),
              blurRadius: 12,
              offset: const Offset(
                0,
                4,
              ),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 14,
            ),

            Icon(
              Iconsax.search_normal_1,
              color: Colors.grey[500],
              size: 19,
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF20222E),
                ),
                decoration: InputDecoration(
                  hintText:
                  'Cari lokasi, client, atau jenis service...',
                  hintStyle: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[400],
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (
                    value,
                    ) {
                  setState(() {
                    _searchQuery = value;
                  });

                  _searchDebounce?.cancel();

                  _searchDebounce = Timer(
                    const Duration(
                      milliseconds: 500,
                    ),
                        () {
                      _refreshData();
                    },
                  );
                },
              ),
            ),

            if (_searchQuery.isNotEmpty)
              IconButton(
                onPressed: () {
                  _searchDebounce?.cancel();

                  _searchController.clear();

                  setState(() {
                    _searchQuery = '';
                  });

                  _refreshData();
                },
                icon: Icon(
                  Iconsax.close_circle,
                  color: Colors.grey[400],
                  size: 17,
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

  Widget _buildStatusFilter() {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 7,
        ),
        itemCount: _statusChips.length,
        separatorBuilder: (
            context,
            index,
            ) {
          return const SizedBox(
            width: 7,
          );
        },
        itemBuilder: (
            context,
            index,
            ) {
          final item = _statusChips[index];

          final value = item['value'] as String;
          final display = item['display'] as String;
          final color = item['color'] as Color;

          final selected =
              _selectedStatus == value;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(
                20,
              ),
              onTap: () {
                setState(() {
                  _selectedStatus = value;
                });

                _refreshData();
              },
              child: AnimatedContainer(
                duration: const Duration(
                  milliseconds: 180,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? color
                      : color.withValues(
                    alpha: 0.065,
                  ),
                  borderRadius: BorderRadius.circular(
                    20,
                  ),
                  border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : color.withValues(
                      alpha: 0.16,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selected) ...[
                      const Icon(
                        Iconsax.tick_circle,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                    ],

                    Text(
                      display,
                      style: TextStyle(
                        fontSize: 10,
                        color: selected
                            ? Colors.white
                            : color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // JENIS FILTER
  // ============================================================

  Widget _buildJenisFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        5,
        16,
        8,
      ),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            14,
          ),
          border: Border.all(
            color: Colors.black.withValues(
              alpha: 0.025,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(
                  alpha: 0.07,
                ),
                borderRadius: BorderRadius.circular(
                  9,
                ),
              ),
              child: const Icon(
                Iconsax.category,
                size: 16,
                color: kPrimaryColor,
              ),
            ),

            const SizedBox(
              width: 9,
            ),

            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedJenis,
                  isExpanded: true,
                  icon: const Icon(
                    Iconsax.arrow_down_1,
                    color: kPrimaryColor,
                    size: 17,
                  ),
                  items: _jenisList.map(
                        (
                        jenis,
                        ) {
                      return DropdownMenuItem<String>(
                        value: jenis['value'] as String,
                        child: Text(
                          jenis['display'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(
                              0xFF20222E,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ).toList(),
                  onChanged: (
                      newValue,
                      ) {
                    if (newValue == null) {
                      return;
                    }

                    setState(() {
                      _selectedJenis = newValue;
                    });

                    _refreshData();
                  },
                ),
              ),
            ),

            if (_selectedJenis != 'Semua')
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedJenis = 'Semua';
                  });

                  _refreshData();
                },
                child: Icon(
                  Iconsax.close_circle,
                  size: 17,
                  color: Colors.grey[400],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RESULT HEADER
  // ============================================================

  Widget _buildResultHeader(
      int total,
      ) {
    final hasFilter =
        _selectedStatus != 'Semua' ||
            _selectedJenis != 'Semua' ||
            _selectedDate != null ||
            _searchQuery.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        9,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(
                alpha: 0.08,
              ),
              borderRadius: BorderRadius.circular(
                9,
              ),
            ),
            child: Text(
              '$total service ditemukan',
              style: const TextStyle(
                fontSize: 9,
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const Spacer(),

          if (_selectedDate != null) ...[
            const Icon(
              Iconsax.calendar_1,
              size: 12,
              color: kPrimaryColor,
            ),

            const SizedBox(
              width: 4,
            ),

            Text(
              DateFormat(
                'dd MMM',
                'id_ID',
              ).format(
                _selectedDate!,
              ),
              style: const TextStyle(
                fontSize: 8,
                color: kPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(
              width: 8,
            ),
          ],

          if (hasFilter)
            InkWell(
              onTap: _resetFilters,
              borderRadius: BorderRadius.circular(
                8,
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 4,
                ),
                child: Text(
                  'Reset',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SERVICES
  // ============================================================

  Widget _buildServicesList(
      OwnerMasterProvider provider,
      List<ServisModel> services,
      ) {
    if (provider.loading && services.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: kPrimaryColor,
        ),
      );
    }

    if (services.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(
        16,
        5,
        16,
        30,
      ),
      itemCount: services.length,
      itemBuilder: (
          context,
          index,
          ) {
        return _buildServiceCard(
          services[index],
        );
      },
    );
  }

  // ============================================================
  // SERVICE CARD
  // ============================================================

  Widget _buildServiceCard(
      ServisModel service,
      ) {
    final statusKey = _normalizeStatus(
      service.status.name,
    );

    final statusColor = _getStatusColor(
      statusKey,
    );

    final statusLabel = _getStatusDisplay(
      statusKey,
    );

    final location = service.lokasiNama.trim();

    final client = service.clientNama.trim();

    final technician = _technicianDisplay(
      service,
    );

    final catatan = (service.catatan ?? '')
        .trim();

    final acCount = service.jumlahAc > 0
        ? service.jumlahAc
        : service.acUnits.length;

    final date = service.tanggalBerkunjung == null
        ? 'Belum dijadwalkan'
        : DateFormat(
      'EEE, dd MMM yyyy',
      'id_ID',
    ).format(
      service.tanggalBerkunjung!,
    );

    final time = service.tanggalBerkunjung == null
        ? '-'
        : DateFormat(
      'HH:mm',
    ).format(
      service.tanggalBerkunjung!,
    );

    return Container(
      margin: const EdgeInsets.only(
        bottom: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: statusColor.withValues(
            alpha: 0.08,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.03,
            ),
            blurRadius: 16,
            offset: const Offset(
              0,
              5,
            ),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          20,
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                color: statusColor,
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                17,
                15,
                15,
                15,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =============================================
                  // HEADER
                  // =============================================

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(
                            alpha: 0.075,
                          ),
                          borderRadius: BorderRadius.circular(
                            13,
                          ),
                        ),
                        child: Icon(
                          _getServiceIcon(
                            service.jenisDisplay,
                          ),
                          color: statusColor,
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
                              'Service ${service.jenisDisplay}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(
                                  0xFF20222E,
                                ),
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(
                              height: 5,
                            ),

                            Wrap(
                              spacing: 9,
                              runSpacing: 4,
                              children: [
                                _buildDateMeta(
                                  icon: Iconsax.calendar_1,
                                  value: date,
                                ),

                                _buildDateMeta(
                                  icon: Iconsax.clock,
                                  value: time,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        width: 7,
                      ),

                      _buildStatusBadge(
                        label: statusLabel,
                        color: statusColor,
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 13,
                  ),

                  // =============================================
                  // LOCATION
                  // =============================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(
                      12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFF7F8FB,
                      ),
                      borderRadius: BorderRadius.circular(
                        13,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withValues(
                              alpha: 0.07,
                            ),
                            borderRadius: BorderRadius.circular(
                              10,
                            ),
                          ),
                          child: const Icon(
                            Iconsax.location,
                            color: kPrimaryColor,
                            size: 17,
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
                                'LOKASI',
                                style: TextStyle(
                                  fontSize: 6.5,
                                  letterSpacing: 0.6,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(
                                height: 3,
                              ),

                              Text(
                                location.isEmpty || location == '-'
                                    ? 'Lokasi belum tersedia'
                                    : location,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  height: 1.25,
                                  color: Color(
                                    0xFF20222E,
                                  ),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  // =============================================
                  // META
                  // =============================================

                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      if (acCount > 0)
                        _buildInfoChip(
                          icon: Iconsax.cpu,
                          label: '$acCount Unit AC',
                          color: const Color(
                            0xFF7950C8,
                          ),
                        ),

                      if (client.isNotEmpty &&
                          client != '-')
                        _buildInfoChip(
                          icon: Iconsax.user,
                          label: client,
                          color: const Color(
                            0xFFB7791F,
                          ),
                        ),

                      _buildInfoChip(
                        icon: Iconsax.profile_2user,
                        label: technician,
                        color: technician ==
                            'Belum ditugaskan'
                            ? const Color(
                          0xFF858793,
                        )
                            : Colors.blue,
                      ),
                    ],
                  ),

                  // =============================================
                  // PROGRESS
                  // =============================================

                  if (_shouldShowProgress(
                    statusKey,
                  )) ...[
                    const SizedBox(
                      height: 14,
                    ),

                    _buildProgress(
                      statusKey,
                      statusColor,
                    ),
                  ],

                  // =============================================
                  // NOTE
                  // =============================================

                  if (catatan.isNotEmpty) ...[
                    const SizedBox(
                      height: 11,
                    ),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(
                          alpha: 0.04,
                        ),
                        borderRadius: BorderRadius.circular(
                          11,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Iconsax.note_1,
                            size: 13,
                            color: statusColor,
                          ),

                          const SizedBox(
                            width: 7,
                          ),

                          Expanded(
                            child: Text(
                              catatan,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 8.5,
                                height: 1.4,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(
                    height: 13,
                  ),

                  // =============================================
                  // ACTION
                  // =============================================

                  _buildActionButtons(
                    service,
                    statusKey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DATE META
  // ============================================================

  Widget _buildDateMeta({
    required IconData icon,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 11,
          color: Colors.grey[500],
        ),

        const SizedBox(
          width: 4,
        ),

        Text(
          value,
          style: TextStyle(
            fontSize: 8.5,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.075,
        ),
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(
            width: 5,
          ),

          Text(
            label,
            style: TextStyle(
              fontSize: 7.5,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO CHIP
  // ============================================================

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 190,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.065,
        ),
        borderRadius: BorderRadius.circular(
          10,
        ),
        border: Border.all(
          color: color.withValues(
            alpha: 0.10,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),

          const SizedBox(
            width: 5,
          ),

          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8.5,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROGRESS
  // ============================================================

  Widget _buildProgress(
      String statusKey,
      Color statusColor,
      ) {
    final step = _getProgressStep(
      statusKey,
    );

    return Column(
      children: [
        Row(
          children: [
            Text(
              'Progress Service',
              style: TextStyle(
                fontSize: 8,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),

            const Spacer(),

            Text(
              '$step / 4',
              style: TextStyle(
                fontSize: 8,
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 7,
        ),

        ClipRRect(
          borderRadius: BorderRadius.circular(
            10,
          ),
          child: LinearProgressIndicator(
            value: _getProgressValue(
              statusKey,
            ),
            minHeight: 5,
            color: statusColor,
            backgroundColor: const Color(
              0xFFF0F1F4,
            ),
          ),
        ),

        const SizedBox(
          height: 5,
        ),

        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _getProgressDescription(
              statusKey,
            ),
            style: TextStyle(
              fontSize: 8,
              color: Colors.grey[500],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ACTION
  // ============================================================

  Widget _buildActionButtons(
      ServisModel service,
      String statusKey,
      ) {
    if (statusKey == 'menunggu_konfirmasi') {
      return SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OwnerServiceDetailPage(
                  service: service,
                  isReassign: false,
                ),
              ),
            );

            if (!mounted) {
              return;
            }

            if (result == true) {
              await _refreshData();
            }
          },
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.document_text,
                size: 16,
              ),
              SizedBox(
                width: 7,
              ),
              Text(
                'Detail & Assign AC',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(
                width: 6,
              ),
              Icon(
                Iconsax.arrow_right_3,
                size: 13,
              ),
            ],
          ),
        ),
      );
    }

    if (statusKey == 'ditugaskan') {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 43,
              child: OutlinedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OwnerServiceDetailPage(
                        service: service,
                        isReassign: true,
                      ),
                    ),
                  );

                  if (!mounted) {
                    return;
                  }

                  if (result == true) {
                    await _refreshData();
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: EdgeInsets.zero,
                  side: BorderSide(
                    color: Colors.blue.withValues(
                      alpha: 0.45,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.profile_2user,
                      size: 15,
                    ),
                    SizedBox(
                      width: 6,
                    ),
                    Text(
                      'Ganti Teknisi',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Container(
              height: 43,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(
                  alpha: 0.07,
                ),
                borderRadius: BorderRadius.circular(
                  12,
                ),
              ),
              child: const Text(
                'Menunggu Teknisi',
                style: TextStyle(
                  fontSize: 9.5,
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (statusKey == 'dikerjakan') {
      return SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OwnerServiceMonitoringPage(
                  service: service,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.eye,
                size: 16,
              ),
              SizedBox(
                width: 7,
              ),
              Text(
                'Lihat Progress',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (statusKey == 'selesai') {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OwnerServiceMonitoringPage(
                        service: service,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.document_text,
                      size: 15,
                    ),
                    SizedBox(
                      width: 6,
                    ),
                    Text(
                      'Lihat Detail',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if ((service.noInvoice ?? '').trim().isNotEmpty) ...[
            const SizedBox(
              width: 8,
            ),

            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(
                      color: Colors.green,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.receipt,
                        size: 15,
                      ),
                      SizedBox(
                        width: 6,
                      ),
                      Text(
                        'Invoice',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }

    if (statusKey == 'batal') {
      return Container(
        width: double.infinity,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.red.withValues(
            alpha: 0.055,
          ),
          borderRadius: BorderRadius.circular(
            12,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.close_circle,
              size: 15,
              color: Colors.red,
            ),
            SizedBox(
              width: 6,
            ),
            Text(
              'Service Dibatalkan',
              style: TextStyle(
                fontSize: 9.5,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    final hasFilter =
        _selectedStatus != 'Semua' ||
            _selectedJenis != 'Semua' ||
            _selectedDate != null ||
            _searchQuery.isNotEmpty;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(
          height: 90,
        ),

        Center(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(
                    alpha: 0.06,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.calendar_remove,
                  size: 30,
                  color: kPrimaryColor.withValues(
                    alpha: 0.45,
                  ),
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              const Text(
                'Tidak ada jadwal service',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(
                    0xFF20222E,
                  ),
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              Text(
                hasFilter
                    ? 'Coba ubah atau reset filter pencarian.'
                    : 'Belum ada jadwal service yang tercatat.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),

              if (hasFilter) ...[
                const SizedBox(
                  height: 14,
                ),

                TextButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(
                    Iconsax.refresh,
                    size: 15,
                  ),
                  label: const Text(
                    'Reset Filter',
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
  // DATE FILTER
  // ============================================================

  void _showDateFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (
          sheetContext,
          ) {
        return _buildDateFilterSheet(
          sheetContext,
        );
      },
    );
  }

  Widget _buildDateFilterSheet(
      BuildContext sheetContext,
      ) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(
          12,
        ),
        padding: const EdgeInsets.fromLTRB(
          18,
          10,
          18,
          20,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            24,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(
                  10,
                ),
              ),
            ),

            const SizedBox(
              height: 17,
            ),

            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(
                      alpha: 0.08,
                    ),
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: const Icon(
                    Iconsax.calendar,
                    color: kPrimaryColor,
                    size: 19,
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter Tanggal',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(
                        height: 2,
                      ),
                      Text(
                        'Tampilkan service pada tanggal tertentu',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  onPressed: () {
                    Navigator.pop(
                      sheetContext,
                    );
                  },
                  icon: const Icon(
                    Iconsax.close_circle,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 18,
            ),

            StatefulBuilder(
              builder: (
                  context,
                  setSheetState,
                  ) {
                return Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(
                        14,
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate:
                          _selectedDate ??
                              DateTime.now(),
                          firstDate: DateTime(
                            2020,
                          ),
                          lastDate: DateTime(
                            2035,
                          ),
                        );

                        if (picked == null) {
                          return;
                        }

                        setState(() {
                          _selectedDate = picked;
                        });

                        setSheetState(() {});
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(
                          14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF7F8FB,
                          ),
                          borderRadius: BorderRadius.circular(
                            14,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Iconsax.calendar_1,
                              color: kPrimaryColor,
                              size: 18,
                            ),

                            const SizedBox(
                              width: 10,
                            ),

                            Expanded(
                              child: Text(
                                _selectedDate == null
                                    ? 'Pilih tanggal service'
                                    : DateFormat(
                                  'EEEE, dd MMMM yyyy',
                                  'id_ID',
                                ).format(
                                  _selectedDate!,
                                ),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _selectedDate == null
                                      ? Colors.grey[500]
                                      : const Color(
                                    0xFF20222E,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            const Icon(
                              Iconsax.arrow_right_3,
                              size: 15,
                              color: kPrimaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    Row(
                      children: [
                        if (_selectedDate != null) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedDate = null;
                                });

                                Navigator.pop(
                                  sheetContext,
                                );

                                _refreshData();
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(
                                  0,
                                  46,
                                ),
                                foregroundColor: Colors.red,
                                side: BorderSide(
                                  color: Colors.red.withValues(
                                    alpha: 0.35,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    12,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'Hapus',
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 9,
                          ),
                        ],

                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(
                                sheetContext,
                              );

                              _refreshData();
                            },
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              minimumSize: const Size(
                                0,
                                46,
                              ),
                              backgroundColor: kPrimaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  12,
                                ),
                              ),
                            ),
                            child: const Text(
                              'Terapkan Filter',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Color _getStatusColor(
      String status,
      ) {
    switch (status) {
      case 'menunggu_konfirmasi':
        return const Color(
          0xFFFF9800,
        );

      case 'ditugaskan':
        return const Color(
          0xFF2684FF,
        );

      case 'dikerjakan':
        return const Color(
          0xFF8B5CF6,
        );

      case 'selesai':
        return const Color(
          0xFF16A34A,
        );

      case 'batal':
        return const Color(
          0xFFEF4444,
        );

      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplay(
      String status,
      ) {
    switch (status) {
      case 'menunggu_konfirmasi':
        return 'Menunggu';

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

  String _normalizeStatus(
      String status,
      ) {
    switch (status) {
      case 'menungguKonfirmasi':
        return 'menunggu_konfirmasi';

      case 'sedangDikerjakan':
        return 'dikerjakan';

      default:
        return status;
    }
  }

  // ============================================================
  // PROGRESS
  // ============================================================

  bool _shouldShowProgress(
      String status,
      ) {
    return status == 'ditugaskan' ||
        status == 'dikerjakan';
  }

  int _getProgressStep(
      String status,
      ) {
    switch (status) {
      case 'menunggu_konfirmasi':
        return 1;

      case 'ditugaskan':
        return 2;

      case 'dikerjakan':
        return 3;

      case 'selesai':
        return 4;

      default:
        return 0;
    }
  }

  double _getProgressValue(
      String status,
      ) {
    return _getProgressStep(
      status,
    ) /
        4;
  }

  String _getProgressDescription(
      String status,
      ) {
    switch (status) {
      case 'ditugaskan':
        return 'Teknisi sudah ditugaskan dan menunggu pengerjaan';

      case 'dikerjakan':
        return 'Service sedang dalam proses pengerjaan';

      case 'selesai':
        return 'Service telah selesai';

      default:
        return '';
    }
  }

  // ============================================================
  // SERVICE ICON
  // ============================================================

  IconData _getServiceIcon(
      String jenis,
      ) {
    final value = jenis.toLowerCase();

    if (value.contains('cuci')) {
      return Iconsax.drop;
    }

    if (value.contains('instalasi')) {
      return Iconsax.cpu;
    }

    if (value.contains('perbaikan')) {
      return Iconsax.setting_2;
    }

    return Iconsax.activity;
  }
}