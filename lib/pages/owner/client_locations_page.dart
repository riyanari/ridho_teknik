// pages/client_locations_page.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:ridho_teknik/models/client_model.dart';
import 'package:ridho_teknik/models/lokasi_model.dart';
import 'package:ridho_teknik/providers/location_provider.dart';
import 'package:ridho_teknik/theme/theme.dart';
import 'package:shimmer/shimmer.dart';
import 'package:badges/badges.dart' as badges;

import 'location_ac_page.dart';

class ClientLocationsPage extends StatefulWidget {
  final Client client;

  const ClientLocationsPage({super.key, required this.client});

  @override
  State<ClientLocationsPage> createState() => _ClientLocationsPageState();
}

class _ClientLocationsPageState extends State<ClientLocationsPage> {
  bool _showMapView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().fetchLocations(clientId: widget.client.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: _buildAppBar(),
      body: Consumer<LocationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return _buildLoadingShimmer();

          if (provider.error.isNotEmpty) return _buildError(provider.error, provider);

          final clientLocations = provider.getLocationsByClient(widget.client.id);
          provider.getClientTotalAc(widget.client.id);

          return Column(
            children: [
              // Client profile header
              _buildClientProfile(),

              // View toggle and stats
              // _buildViewToggleAndStats(provider, clientLocations, totalAc),

              // Map/Locations content
              Expanded(
                child: _showMapView
                    ? _buildMapView(clientLocations)
                    : _buildLocationsList(provider, clientLocations),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddLocationDialog();
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
            'Lokasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Text(
            widget.client.name,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha:0.8),
            ),
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
          icon: const Icon(Iconsax.map_1),
          onPressed: () {
            setState(() {
              _showMapView = !_showMapView;
            });
          },
        ),
        IconButton(
          icon: const Icon(Iconsax.more),
          onPressed: () {
            _showOptionsMenu();
          },
        ),
      ],
    );
  }

  Widget _buildClientProfile() {
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
      child: Row(
        children: [
          // Profile avatar
          badges.Badge(
            position: badges.BadgePosition.topEnd(top: -5, end: -5),
            badgeStyle: badges.BadgeStyle(
              badgeColor: widget.client.rating >= 4.5 ? Colors.amber : Colors.green,
            ),
            badgeContent: widget.client.rating >= 4.5
                ? const Icon(Iconsax.crown1, size: 10, color: Colors.white)
                : const Icon(Iconsax.tick_circle, size: 10, color: Colors.white),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kPrimaryColor.withValues(alpha:0.9),
                    kPrimaryColor.withValues(alpha:0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Text(
                  widget.client.name.isNotEmpty
                      ? widget.client.name[0].toUpperCase()
                      : 'C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Client info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.client.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    Icon(Iconsax.call, size: 14, color: kPrimaryColor),
                    const SizedBox(width: 6),
                    Text(
                      widget.client.phone,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    _buildMiniChip(
                      icon: Iconsax.receipt_text,
                      text: '${widget.client.totalService} Service',
                      color: kPrimaryColor,
                    ),
                    const SizedBox(width: 8),
                    _buildMiniChip(
                      icon: Iconsax.star1,
                      text: widget.client.rating.toStringAsFixed(1),
                      color: Colors.amber,
                    ),
                    // const Spacer(),
                    // Container(
                    //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    //   decoration: BoxDecoration(
                    //     color: widget.client.totalService > 0
                    //         ? Colors.green.withValues(alpha:0.1)
                    //         : Colors.grey.withValues(alpha:0.1),
                    //     borderRadius: BorderRadius.circular(20),
                    //   ),
                    //   child: Row(
                    //     children: [
                    //       Icon(
                    //         Iconsax.activity,
                    //         size: 12,
                    //         color: widget.client.totalService > 0 ? Colors.green : Colors.grey,
                    //       ),
                    //       const SizedBox(width: 4),
                    //       Text(
                    //         widget.client.totalService > 0 ? 'Aktif' : 'Belum Service',
                    //         style: TextStyle(
                    //           fontSize: 10,
                    //           fontWeight: FontWeight.w500,
                    //           color: widget.client.totalService > 0 ? Colors.green : Colors.grey,
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleAndStats(
      LocationProvider provider,
      List<LokasiModel> locations,
      int totalAc
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // View toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_showMapView) {
                        setState(() {
                          _showMapView = false;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_showMapView ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: !_showMapView ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.location,
                            size: 16,
                            color: !_showMapView ? kPrimaryColor : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Daftar Lokasi',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: !_showMapView ? FontWeight.w600 : FontWeight.normal,
                              color: !_showMapView ? kPrimaryColor : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (!_showMapView) {
                        setState(() {
                          _showMapView = true;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _showMapView ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _showMapView ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.map_1,
                            size: 16,
                            color: _showMapView ? kPrimaryColor : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Peta',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _showMapView ? FontWeight.w600 : FontWeight.normal,
                              color: _showMapView ? kPrimaryColor : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Stats cards
          Row(
            children: [
              _buildStatCard(
                icon: Iconsax.location,
                value: locations.length.toString(),
                label: 'Lokasi',
                color: kPrimaryColor,
                trend: locations.length > 0 ? '+${locations.length}' : null,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                icon: Iconsax.cpu,
                value: totalAc.toString(),
                label: 'Total AC',
                color: Colors.blue,
                trend: totalAc > 0 ? '+${totalAc}' : null,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                icon: Iconsax.star1,
                value: widget.client.rating.toStringAsFixed(1),
                label: 'Rating',
                color: Colors.amber,
                trend: widget.client.rating >= 4.5 ? 'Premium' : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    String? trend,
  }) {
    return Expanded(
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
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      trend,
                      style: TextStyle(
                        fontSize: 10,
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
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationsList(LocationProvider provider, List<LokasiModel> locations) {
    return RefreshIndicator.adaptive(
      onRefresh: () => provider.fetchLocations(clientId: widget.client.id),
      backgroundColor: Colors.white,
      color: kPrimaryColor,
      child: locations.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        itemCount: locations.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Semua Lokasi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${locations.length} Lokasi',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }

          final location = locations[index - 1];
          return _buildLocationCard(location);
        },
      ),
    );
  }

  Widget _buildLocationCard(LokasiModel location) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LocationAcPage(location: location),
              ),
            );
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
                // Location icon
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

                // Location info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              location.nama,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: kPrimaryColor.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Iconsax.cpu, size: 12, color: kPrimaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  '${location.jumlahAC} AC',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: kPrimaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Icon(Iconsax.location, size: 12, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              location.alamat,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          _buildInfoChip(
                            icon: Iconsax.calendar_1,
                            text: _formatDate(location.lastService),
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          if (location.jumlahAC > 5)
                            _buildInfoChip(
                              icon: Iconsax.crown1,
                              text: 'Banyak AC',
                              color: Colors.amber,
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

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView(List<LokasiModel> locations) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Peta Lokasi Client',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),

        // Simplified map view (placeholder)
        Expanded(
          child: SingleChildScrollView( // Bungkus dengan SingleChildScrollView
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20), // Tambahkan padding
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Ubah ke min
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.map_1,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Map View',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Integrasi peta akan segera tersedia',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (locations.isNotEmpty)
                    Column(
                      mainAxisSize: MainAxisSize.min, // Ubah ke min
                      children: locations.take(3).map((location) {
                        return ListTile(
                          leading: Icon(Iconsax.location, color: kPrimaryColor),
                          title: Text(
                            location.nama,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            location.alamat,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            '${location.jumlahAC} AC',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kPrimaryColor,
                            ),
                          ),
                          contentPadding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ),
                  // Tambahkan safe area jika perlu
                  SizedBox(height: MediaQuery.of(context).viewPadding.bottom > 0 ? 20 : 0),
                ],
              ),
            ),
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
            height: 120,
          ),
        );
      },
    );
  }

  Widget _buildError(String error, LocationProvider provider) {
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
              'Gagal Memuat Lokasi',
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
                  onPressed: () => provider.fetchLocations(clientId: widget.client.id),
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
                    // Navigate back
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
              child: Icon(Iconsax.location, color: Colors.grey[400], size: 80),
            ),
            const SizedBox(height: 32),
            Text(
              'Belum Ada Lokasi',
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
                '${widget.client.name} belum memiliki lokasi. Tambahkan lokasi pertama untuk memulai',
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
                _showAddLocationDialog();
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
                  Text('Tambah Lokasi'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddLocationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Tambah Lokasi Baru'),
          content: const Text('Fitur tambah lokasi akan segera tersedia!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
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
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.3,
          maxChildSize: 0.6,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Drag handle
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
                      'Opsi Lokasi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shrinkWrap: true,
                      children: [
                        _buildOptionItem(Iconsax.share, 'Bagikan Data Client', () {}),
                        _buildOptionItem(Iconsax.printer, 'Cetak Data', () {}),
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
                        // Safe area untuk bottom
                        SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
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