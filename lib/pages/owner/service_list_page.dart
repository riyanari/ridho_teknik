import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ridho_teknik/providers/owner_master_provider.dart';
import 'package:ridho_teknik/theme/theme.dart';
import 'package:ridho_teknik/models/servis_model.dart';

import 'owner_service_detail_page.dart';

class ServiceListPage extends StatefulWidget {
  const ServiceListPage({super.key});

  @override
  State<ServiceListPage> createState() => _ServiceListPageState();
}

class _ServiceListPageState extends State<ServiceListPage> {
  final ScrollController _scrollController = ScrollController();
  String _selectedStatus = 'Semua';
  String _selectedJenis = 'Semua';
  DateTime? _selectedDate;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  // PERBAIKAN: Update mapping status ke snake_case dan sesuai backend
  final List<Map<String, dynamic>> _statusChips = [
    {'value': 'Semua', 'display': 'Semua', 'color': kPrimaryColor},
    {'value': 'menunggu_konfirmasi', 'display': 'Menunggu Konfirmasi', 'color': Colors.orange},
    {'value': 'ditugaskan', 'display': 'Ditugaskan', 'color': Colors.blue},
    {'value': 'dikerjakan', 'display': 'Dikerjakan', 'color': Colors.purple},
    {'value': 'selesai', 'display': 'Selesai', 'color': Colors.green},
    {'value': 'batal', 'display': 'Dibatalkan', 'color': Colors.red},
  ];

  final List<Map<String, dynamic>> _jenisList = [
    {'value': 'Semua', 'display': 'Semua Jenis'},
    {'value': 'cuci', 'display': 'Cuci AC'},
    {'value': 'perbaikan', 'display': 'Perbaikan AC'},
    {'value': 'instalasi', 'display': 'Instalasi AC'},
  ];


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

  Future<void> _loadInitialData() async {
    final provider = context.read<OwnerMasterProvider>();
    await provider.fetchServices();
  }

  Future<void> _refreshData() async {
    final provider = context.read<OwnerMasterProvider>();

    await provider.fetchServices(
      status: _selectedStatus == 'Semua' ? null : _selectedStatus,
      jenis: _selectedJenis == 'Semua' ? null : _selectedJenis,
      keyword: _searchQuery.isEmpty ? null : _searchQuery,
      startDate: _selectedDate,
      endDate: _selectedDate,
    );
  }

  void _showDateFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildDateFilterSheet(),
    );
  }

  Widget _buildDateFilterSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.2),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Tanggal',
                style: primaryTextStyle.copyWith(
                  fontSize: 18,
                  fontWeight: bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Iconsax.close_circle),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Tanggal Service',
            style: primaryTextStyle.copyWith(
              fontSize: 14,
              fontWeight: semiBold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Iconsax.calendar_1, color: kPrimaryColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedDate == null
                              ? 'Pilih tanggal'
                              : DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate!),
                          style: greyTextStyle.copyWith(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                    if (!mounted) return;
                    Navigator.pop(context);
                    _refreshData();
                  }
                },
                icon: Icon(Iconsax.calendar_edit, color: kPrimaryColor),
              ),
              IconButton(
                onPressed: () {
                  setState(() => _selectedDate = null);
                  Navigator.pop(context);
                  _refreshData();
                },
                icon: Icon(Iconsax.close_circle, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _refreshData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Terapkan Filter',
                style: whiteTextStyle.copyWith(
                  fontSize: 14,
                  fontWeight: semiBold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Iconsax.arrow_left_2, color: kPrimaryColor),
        ),
        title: Text(
          'Jadwal Service',
          style: primaryTextStyle.copyWith(
            fontSize: 18,
            fontWeight: bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showDateFilterDialog,
            icon: const Icon(Iconsax.calendar, color: kPrimaryColor),
            tooltip: 'Filter Tanggal',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<OwnerMasterProvider>(
        builder: (context, provider, child) {
          final services = provider.services;

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha:0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.search_normal_1, color: kPrimaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() => _searchQuery = value);

                            _searchDebounce?.cancel();
                            _searchDebounce = Timer(const Duration(milliseconds: 500), () {
                              _refreshData();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Cari berdasarkan lokasi atau jenis service...',
                            hintStyle: greyTextStyle.copyWith(fontSize: 14),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            _searchDebounce?.cancel();
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _refreshData();
                          },
                          icon: const Icon(Iconsax.close_circle, color: Colors.red),
                        ),
                    ],
                  ),
                ),
              ),

              // Filter Status Chips
              SizedBox(
                height: 60,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: _statusChips.map((statusChip) {
                    final isSelected = _selectedStatus == statusChip['value'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          statusChip['display'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: medium,
                            color: isSelected ? Colors.white : (statusChip['color'] as Color),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: statusChip['color'] as Color,
                        backgroundColor: (statusChip['color'] as Color).withValues(alpha:0.1),
                        onSelected: (selected) {
                          setState(() => _selectedStatus = statusChip['value'] as String);
                          _refreshData();
                        },
                        avatar: isSelected
                            ? const Icon(Iconsax.tick_circle, size: 16, color: Colors.white)
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.transparent
                                : (statusChip['color'] as Color).withValues(alpha:0.3),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Dropdown Filter Jenis
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha:0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Iconsax.category, color: kPrimaryColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedJenis,
                          isExpanded: true,
                          underline: const SizedBox(),
                          icon: Icon(Iconsax.arrow_down_1, color: kPrimaryColor),
                          items: _jenisList.map((jenis) {
                            return DropdownMenuItem<String>(
                              value: jenis['value'] as String,
                              child: Text(
                                jenis['display'] as String,
                                style: primaryTextStyle.copyWith(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() => _selectedJenis = newValue);
                              _refreshData();
                            }
                          },
                        ),
                      ),
                      if (_selectedJenis != 'Semua')
                        IconButton(
                          onPressed: () {
                            setState(() => _selectedJenis = 'Semua');
                            _refreshData();
                          },
                          icon: Icon(Iconsax.close_circle, color: Colors.red, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ),
              ),

              // Info jumlah service ditemukan
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${services.length} service ditemukan',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_selectedStatus != 'Semua' ||
                        _selectedJenis != 'Semua' ||
                        _selectedDate != null ||
                        _searchQuery.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedStatus = 'Semua';
                            _selectedJenis = 'Semua';
                            _selectedDate = null;
                            _searchQuery = '';
                            _searchController.clear();
                          });
                          _refreshData();
                        },
                        child: Text(
                          'Reset Semua',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: medium,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshData,
                  child: _buildServicesList(provider, services),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildServicesList(OwnerMasterProvider provider, List<ServisModel> services) {
    if (provider.loading && services.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (services.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Column(
            children: [
              Icon(Iconsax.calendar_remove, color: Colors.grey[400], size: 80),
              const SizedBox(height: 16),
              Text(
                'Tidak ada jadwal service',
                style: greyTextStyle.copyWith(fontSize: 16, fontWeight: medium),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedStatus != 'Semua' ||
                    _selectedJenis != 'Semua' ||
                    _selectedDate != null ||
                    _searchQuery.isNotEmpty
                    ? 'Coba ubah filter pencarian'
                    : 'Belum ada jadwal service yang tercatat',
                style: greyTextStyle.copyWith(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (_selectedStatus != 'Semua' ||
                  _selectedJenis != 'Semua' ||
                  _selectedDate != null ||
                  _searchQuery.isNotEmpty)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = 'Semua';
                      _selectedJenis = 'Semua';
                      _selectedDate = null;
                      _searchQuery = '';
                      _searchController.clear();
                    });
                    _refreshData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Reset Filter', style: whiteTextStyle.copyWith(fontSize: 14)),
                ),
            ],
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return _buildModernServiceCard(service);
      },
    );
  }

  // Jika ingin ada dialog untuk melihat detail tim teknisi

  // ================= MODERN SERVICE CARD =================
  Widget _buildModernServiceCard(ServisModel service) {
    final statusColor = _getStatusColor(service.status.name);
    final statusDisplay = _getStatusDisplay(service.status.name);
    final time = service.tanggalBerkunjung != null ? DateFormat('HH:mm').format(service.tanggalBerkunjung!) : '-';
    final date = service.tanggalBerkunjung != null
        ? DateFormat('dd MMM y', 'id_ID').format(service.tanggalBerkunjung!)
        : 'Tanggal belum ditentukan';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 15, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey[100]!, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [statusColor.withValues(alpha:0.1), statusColor.withValues(alpha:0.05)],
                ),
                border: Border(bottom: BorderSide(color: statusColor.withValues(alpha:0.2), width: 1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: statusColor.withValues(alpha:0.1), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Icon(_getServiceIcon(service.jenisDisplay), color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Service ${service.jenisDisplay}',
                            style: primaryTextStyle.copyWith(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Iconsax.calendar_1, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Text(date, style: greyTextStyle.copyWith(fontSize: 10)),
                            const SizedBox(width: 12),
                            Icon(Iconsax.clock, size: 10, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Text(time, style: greyTextStyle.copyWith(fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha:0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha:0.3), width: 1),
                    ),
                    child: Text(
                      statusDisplay,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
                    ),
                  ),
                ],
              ),
            ),

            // Detail
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailCard(
                          icon: Iconsax.location,
                          title: 'Lokasi',
                          value: service.lokasiNama,
                          iconColor: kPrimaryColor,
                          backgroundColor: kPrimaryColor.withValues(alpha:0.05),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDetailCard(
                          icon: Iconsax.profile_2user,
                          title: service.technicianIds?.isEmpty ?? true
                              ? 'Teknisi'
                              : (service.technicianIds!.length == 1 ? 'Teknisi' : 'Tim Teknisi'),
                          value: service.techniciansNamesDisplay, // ✅ tampil "Andi Teknisi, Rina Teknisi"
                          iconColor: Colors.blue,
                          backgroundColor: Colors.blue.withValues(alpha:0.05),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _buildInfoChip(
                        icon: Iconsax.cpu,
                        label: '${service.jumlahAc} Unit',
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 8),
                      if (service.noInvoice != null && service.noInvoice!.isNotEmpty)
                        _buildInfoChip(icon: Iconsax.receipt, label: service.noInvoice!, color: Colors.green),
                    ],
                  ),

                  if (_shouldShowProgress(service.status.name)) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Proses Service', style: greyTextStyle.copyWith(fontSize: 11, fontWeight: FontWeight.w500)),
                              Text('${_getProgressStep(service.status.name)}/4', style: greyTextStyle.copyWith(fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _getProgressValue(service.status.name),
                              backgroundColor: Colors.grey[200],
                              color: statusColor,
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(_getProgressDescription(service.status.name), style: greyTextStyle.copyWith(fontSize: 10)),
                        ],
                      ),
                    ),
                  ],

                  if (service.catatan.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber[100]!),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Iconsax.note_text, color: Colors.amber[700], size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              service.catatan,
                              style: TextStyle(fontSize: 12, color: Colors.amber[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  _buildModernActionButtons(service),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withValues(alpha:0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Text(title, style: greyTextStyle.copyWith(fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: primaryTextStyle.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha:0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildModernActionButtons(ServisModel service) {

    switch (service.status.name) {
      case 'menunggu_konfirmasi':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OwnerServiceDetailPage(service: service, isReassign: false),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Iconsax.document, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Detail & Assign AC',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

      case 'ditugaskan':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                // ✅ FIX: ganti teknisi harus isReassign true
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OwnerServiceDetailPage(service: service, isReassign: true),
                    ),
                  );

                  // optional: kalau di detail kamu Navigator.pop(context, true) saat berhasil submit
                  if (!mounted) return;
                  if (result == true) {
                    await _refreshData();
                  }
                },

                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.blue, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Iconsax.profile_2user, size: 18, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Ganti Teknisi',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha:0.3)),
                ),
                child: const Center(
                  child: Text(
                    'Menunggu Teknisi',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue),
                  ),
                ),
              ),
            ),
          ],
        );

      case 'dikerjakan':
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.withValues(alpha:0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Iconsax.timer_start, size: 18, color: Colors.purple),
              SizedBox(width: 8),
              Text(
                'Sedang Dikerjakan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.purple),
              ),
            ],
          ),
        );

      case 'selesai':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.green, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Iconsax.receipt, size: 18, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Lihat Invoice', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withValues(alpha:0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Iconsax.tick_circle, size: 18, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Selesai', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green)),
                  ],
                ),
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'menunggu_konfirmasi':
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

  String _getStatusDisplay(String status) {
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

  bool _shouldShowProgress(String status) => status != 'selesai' && status != 'batal';

  int _getProgressStep(String status) {
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

  String _getProgressDescription(String status) {
    switch (status) {
      case 'menunggu_konfirmasi':
        return 'Menunggu konfirmasi dari owner';
      case 'ditugaskan':
        return 'Menunggu teknisi mulai bekerja';
      case 'dikerjakan':
        return 'Sedang dalam proses pengerjaan';
      case 'selesai':
        return 'Service telah selesai';
      default:
        return '';
    }
  }

  double _getProgressValue(String status) => _getProgressStep(status) / 4;

  IconData _getServiceIcon(String jenis) {
    switch (jenis.toLowerCase()) {
      case 'perbaikan ac':
        return Iconsax.pen_tool;
      case 'instalasi ac':
        return Iconsax.cpu;
      case 'cuci ac':
        return Iconsax.drop;
      default:
        return Iconsax.activity;
    }
  }
}
