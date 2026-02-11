// pages/location_ac_page.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:ridho_teknik/models/ac_model.dart';
import 'package:ridho_teknik/models/lokasi_model.dart';
import 'package:ridho_teknik/providers/ac_unit_provider.dart';
import 'package:ridho_teknik/theme/theme.dart';
import 'package:shimmer/shimmer.dart';
import 'package:badges/badges.dart' as badges;

import 'add_ac_unit_dialog.dart';

class LocationAcPage extends StatefulWidget {
  final LokasiModel location;

  const LocationAcPage({super.key, required this.location});

  @override
  State<LocationAcPage> createState() => _LocationAcPageState();
}

class _LocationAcPageState extends State<LocationAcPage> {
  int _selectedTabIndex = 0;
  final List<String> _tabOptions = ['Semua', 'Butuh Service', 'Aktif'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcUnitProvider>().fetchAcUnits(
        locationId: int.tryParse(widget.location.id) ?? 0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: _buildAppBar(),
      body: Consumer<AcUnitProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return _buildLoadingShimmer();

          if (provider.error.isNotEmpty) return _buildError(provider.error, provider);

          final locationAcUnits = provider.getAcUnitsByLocation(
            int.tryParse(widget.location.id) ?? 0,
          );

          // Filter AC units berdasarkan tab yang dipilih
          List<AcModel> filteredAcUnits = locationAcUnits;
          if (_selectedTabIndex == 1) { // Butuh Service
            final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
            filteredAcUnits = locationAcUnits.where((ac) =>
                ac.terakhirService.isBefore(sixMonthsAgo)
            ).toList();
          } else if (_selectedTabIndex == 2) { // Aktif
            filteredAcUnits = locationAcUnits.where((ac) =>
                ac.terakhirService.isAfter(DateTime.now().subtract(const Duration(days: 30)))
            ).toList();
          }

          return Column(
            children: [
              // Location header dengan informasi lengkap
              _buildLocationHeader(),

              // Tab filter
              // _buildTabBar(),

              // Statistics cards
              // _buildStatisticsCards(provider, locationAcUnits),

              // AC units list
              Expanded(
                child: _buildAcList(provider, filteredAcUnits),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddAcDialog();
        },
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Iconsax.add, size: 24),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Unit AC',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Text(
            widget.location.nama,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha:0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Iconsax.arrow_left_2),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Iconsax.more),
          onPressed: () {
            _showOptionsMenu();
          },
        ),
      ],
    );
  }

  Widget _buildLocationHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Iconsax.location,
                  color: kPrimaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.location.nama,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.location.alamat,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              _buildLocationChip(
                icon: Iconsax.cpu,
                text: '${widget.location.jumlahAC} Unit AC',
                color: kPrimaryColor,
              ),
              const SizedBox(width: 8),
              _buildLocationChip(
                icon: Iconsax.calendar_1,
                text: _formatDate(widget.location.lastService),
                color: Colors.blue,
              ),
              // const Spacer(),
              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              //   decoration: BoxDecoration(
              //     gradient: LinearGradient(
              //       colors: [
              //         kPrimaryColor.withValues(alpha:0.8),
              //         kPrimaryColor.withValues(alpha:0.6),
              //       ],
              //       begin: Alignment.topLeft,
              //       end: Alignment.bottomRight,
              //     ),
              //     borderRadius: BorderRadius.circular(12),
              //   ),
              //   child: Row(
              //     children: [
              //       Icon(
              //         Iconsax.building_4,
              //         size: 12,
              //         color: Colors.white,
              //       ),
              //       const SizedBox(width: 6),
              //       Text(
              //         'Lokasi',
              //         style: TextStyle(
              //           fontSize: 12,
              //           fontWeight: FontWeight.w600,
              //           color: Colors.white,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_tabOptions.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? kPrimaryColor.withValues(alpha:0.1) : Colors.transparent,
                  borderRadius: _getTabBorderRadius(index),
                ),
                child: Column(
                  children: [
                    Text(
                      _tabOptions[index],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? kPrimaryColor : Colors.grey[600],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 24,
                        height: 3,
                        decoration: BoxDecoration(
                          color: kPrimaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  BorderRadius _getTabBorderRadius(int index) {
    if (index == 0) {
      return const BorderRadius.only(
        topLeft: Radius.circular(16),
        bottomLeft: Radius.circular(16),
      );
    } else if (index == _tabOptions.length - 1) {
      return const BorderRadius.only(
        topRight: Radius.circular(16),
        bottomRight: Radius.circular(16),
      );
    }
    return BorderRadius.zero;
  }

  Widget _buildStatisticsCards(AcUnitProvider provider, List<AcModel> acUnits) {
    final now = DateTime.now();
    final threeMonthsAgo = now.subtract(const Duration(days: 90));

    final needServiceCount = acUnits.where((ac) =>
        ac.terakhirService.isBefore(threeMonthsAgo)
    ).length;

    final activeCount = acUnits.where((ac) =>
        ac.terakhirService.isAfter(now.subtract(const Duration(days: 30)))
    ).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildAcStatCard(
            title: 'Total',
            value: acUnits.length.toString(),
            icon: Iconsax.cpu,
            color: kPrimaryColor,
            count: acUnits.length,
          ),
          const SizedBox(width: 12),
          _buildAcStatCard(
            title: 'Aktif',
            value: activeCount.toString(),
            icon: Iconsax.activity,
            color: Colors.green,
            count: activeCount,
            isActive: _selectedTabIndex == 2,
            onTap: () => setState(() => _selectedTabIndex = 2),
          ),
          const SizedBox(width: 12),
          _buildAcStatCard(
            title: 'Butuh Service',
            value: needServiceCount.toString(),
            icon: Iconsax.warning_2,
            color: Colors.orange,
            count: needServiceCount,
            isActive: _selectedTabIndex == 1,
            onTap: () => setState(() => _selectedTabIndex = 1),
          ),
        ],
      ),
    );
  }

  Widget _buildAcStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required int count,
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: isActive ? Border.all(color: color, width: 2) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  if (count > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              if (isActive)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: double.infinity,
                  height: 3,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAcList(AcUnitProvider provider, List<AcModel> acUnits) {
    return RefreshIndicator.adaptive(
      onRefresh: () => provider.fetchAcUnits(
        locationId: int.tryParse(widget.location.id) ?? 0,
      ),
      backgroundColor: Colors.white,
      color: kPrimaryColor,
      child: acUnits.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        itemCount: acUnits.length + 1, // +1 untuk header
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getListTitle(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${acUnits.length} Unit',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }

          final acUnit = acUnits[index - 1];
          return _buildAcUnitCard(acUnit);
        },
      ),
    );
  }

  String _getListTitle() {
    switch (_selectedTabIndex) {
      case 0:
        return 'Semua Unit AC';
      case 1:
        return 'Unit Butuh Service';
      case 2:
        return 'Unit Aktif';
      default:
        return 'Daftar Unit AC';
    }
  }

  Widget _buildAcUnitCard(AcModel acUnit) {
    final now = DateTime.now();
    final threeMonthsAgo = now.subtract(const Duration(days: 90));
    final needsService = acUnit.terakhirService.isBefore(threeMonthsAgo);
    final isNew = acUnit.terakhirService.isAfter(now.subtract(const Duration(days: 30)));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: () {
            _showAcDetailDialog(acUnit);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[100]!),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // AC Icon dengan status badge
                Stack(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: needsService
                            ? Colors.orange.withValues(alpha:0.1)
                            : kPrimaryColor.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Iconsax.cpu,
                        color: needsService ? Colors.orange : kPrimaryColor,
                        size: 24,
                      ),
                    ),
                    if (isNew)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: badges.Badge(
                          badgeStyle: badges.BadgeStyle(
                            badgeColor: Colors.green,
                            padding: const EdgeInsets.all(4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          badgeContent: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 6,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    if (needsService)
                      Positioned(
                        left: -2,
                        top: -2,
                        child: badges.Badge(
                          badgeStyle: badges.BadgeStyle(
                            badgeColor: Colors.orange,
                            padding: const EdgeInsets.all(4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          badgeContent: const Icon(
                            Iconsax.warning_2,
                            size: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 16),

                // AC Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              acUnit.nama,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (needsService)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha:0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Iconsax.warning_2, size: 10, color: Colors.orange),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Butuh Service',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '${acUnit.merk} • ${acUnit.type}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          _buildAcDetailItem(
                            icon: Iconsax.cpu,
                            label: 'Kapasitas',
                            value: acUnit.kapasitas,
                            color: kPrimaryColor,
                          ),
                          const SizedBox(width: 16),
                          _buildAcDetailItem(
                            icon: Iconsax.calendar_1,
                            label: 'Terakhir Service',
                            value: _formatDate(acUnit.terakhirService),
                            color: Colors.blue,
                          ),
                          const Spacer(),
                          Icon(
                            Iconsax.arrow_right_3,
                            color: Colors.grey[400],
                            size: 18,
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

  Widget _buildAcDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hari ini';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inDays < 30) {
      return '${difference.inDays ~/ 7} minggu lalu';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[200]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            height: 100,
          ),
        );
      },
    );
  }

  Widget _buildError(String error, AcUnitProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha:0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.warning_2, color: Colors.orange, size: 60),
            ),
            const SizedBox(height: 24),
            Text(
              'Gagal Memuat Data AC',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                error,
                style: TextStyle(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => provider.fetchAcUnits(
                    locationId: int.tryParse(widget.location.id) ?? 0,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    children: [
                      Icon(Iconsax.refresh, size: 18),
                      SizedBox(width: 8),
                      Text('Coba Lagi'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: kPrimaryColor),
                  ),
                  child: const Row(
                    children: [
                      Icon(Iconsax.arrow_left, size: 18),
                      SizedBox(width: 8),
                      Text('Kembali'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final emptyTitle = _getEmptyStateTitle();
    final emptyMessage = _getEmptyStateMessage();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: kBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getEmptyStateIcon(),
                color: Colors.grey[400],
                size: 80,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              emptyTitle,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                emptyMessage,
                style: TextStyle(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                _showAddAcDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.add, size: 20),
                  SizedBox(width: 8),
                  Text('Tambah AC'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEmptyStateTitle() {
    switch (_selectedTabIndex) {
      case 0:
        return 'Belum Ada Unit AC';
      case 1:
        return 'Tidak Ada Unit Butuh Service';
      case 2:
        return 'Tidak Ada Unit Aktif';
      default:
        return 'Belum Ada Data';
    }
  }

  String _getEmptyStateMessage() {
    switch (_selectedTabIndex) {
      case 0:
        return 'Lokasi ${widget.location.nama} belum memiliki unit AC. Tambahkan AC pertama untuk memulai';
      case 1:
        return 'Semua unit AC dalam kondisi baik dan tidak memerlukan service saat ini';
      case 2:
        return 'Tidak ada unit AC yang aktif dalam 30 hari terakhir';
      default:
        return 'Tidak ada data yang ditemukan';
    }
  }

  IconData _getEmptyStateIcon() {
    switch (_selectedTabIndex) {
      case 1:
        return Iconsax.tick_circle;
      case 2:
        return Iconsax.activity;
      default:
        return Iconsax.cpu;
    }
  }

  void _showAddAcDialog() async {
    final locationId = int.tryParse(widget.location.id) ?? 0;
    if (locationId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Location ID tidak valid')),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddAcUnitDialog(locationId: locationId),
    );

    // kalau dialog return true -> refresh list AC
    if (result == true && mounted) {
      context.read<AcUnitProvider>().fetchAcUnits(locationId: locationId);
    }
  }

  void _showAcDetailDialog(AcModel acUnit) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Iconsax.cpu,
                      color: kPrimaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          acUnit.nama,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '${acUnit.merk} • ${acUnit.type}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Detail Unit AC',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Kapasitas', acUnit.kapasitas, Iconsax.cpu),
              _buildDetailRow('Merk', acUnit.merk, Iconsax.tag),
              _buildDetailRow('Type', acUnit.type, Iconsax.box),
              _buildDetailRow('Terakhir Service', _formatDate(acUnit.terakhirService), Iconsax.calendar_1),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.receipt_text, size: 20),
                      SizedBox(width: 8),
                      Text('Buat Laporan Service'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      isScrollControlled: true, // Penting untuk scrollable content
      builder: (context) {
        return DraggableScrollableSheet( // Gunakan DraggableScrollableSheet
          initialChildSize: 0.4, // 40% dari tinggi layar
          minChildSize: 0.3, // Minimal 30%
          maxChildSize: 0.8, // Maksimal 80%
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle untuk drag
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Opsi Unit AC',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded( // Gunakan Expanded untuk mengambil sisa ruang
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shrinkWrap: true,
                      children: [
                        _buildOptionItem(Iconsax.printer, 'Cetak Daftar AC', () {}),
                        _buildOptionItem(Iconsax.share, 'Bagikan Data', () {}),
                        _buildOptionItem(Iconsax.export, 'Ekspor Data', () {}),
                        _buildOptionItem(Iconsax.setting, 'Pengaturan', () {}),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              'Tutup',
                              style: TextStyle(color: Colors.black87),
                            ),
                          ),
                        ),
                        // Tambahkan safe area untuk notched devices
                        SizedBox(height: MediaQuery.of(context).padding.bottom),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  ListTile _buildOptionItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: kPrimaryColor),
      title: Text(title),
      trailing: Icon(Iconsax.arrow_right_3, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}