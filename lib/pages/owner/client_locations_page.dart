// pages/client_locations_page.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:ridho_teknik/models/client_model.dart';
import 'package:ridho_teknik/models/lokasi_model.dart';
import 'package:ridho_teknik/providers/location_provider.dart';
import 'package:ridho_teknik/theme/theme.dart';

import 'location_ac_page.dart';

class ClientLocationsPage extends StatefulWidget {
  final Client client;

  const ClientLocationsPage({super.key, required this.client});

  @override
  State<ClientLocationsPage> createState() => _ClientLocationsPageState();
}

class _ClientLocationsPageState extends State<ClientLocationsPage> {
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
      appBar: AppBar(
        title: Text('Lokasi - ${widget.client.name}'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<LocationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return _buildLoading();

          if (provider.error.isNotEmpty) return _buildError(provider.error, provider);

          final clientLocations = provider.getLocationsByClient(widget.client.id);

          return Column(
            children: [
              // Client info card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
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
                    CircleAvatar(
                      backgroundColor: kPrimaryColor.withValues(alpha:0.1),
                      radius: 25,
                      child: Text(
                        widget.client.name.isNotEmpty
                            ? widget.client.name[0].toUpperCase()
                            : 'C',
                        style: TextStyle(
                          color: kPrimaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.client.name,
                            style: primaryTextStyle.copyWith(
                              fontSize: 16,
                              fontWeight: bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.client.phone,
                            style: greyTextStyle,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Iconsax.receipt_text, size: 14, color: kPrimaryColor),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.client.totalService} Service',
                                style: greyTextStyle.copyWith(fontSize: 12),
                              ),
                              const SizedBox(width: 12),
                              Icon(Iconsax.star, size: 14, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                widget.client.rating.toStringAsFixed(1),
                                style: greyTextStyle.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Summary stats
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: kBackgroundColor,
                child: Row(
                  children: [
                    _buildStatCard('Lokasi', clientLocations.length.toString(), Iconsax.location),
                    const SizedBox(width: 12),
                    _buildStatCard('Total AC',
                        provider.getClientTotalAc(widget.client.id).toString(),
                        Iconsax.cpu
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard('Rating',
                        widget.client.rating.toStringAsFixed(1),
                        Iconsax.star1
                    ),
                  ],
                ),
              ),

              // Locations list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.fetchLocations(clientId: widget.client.id),
                  child: clientLocations.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: clientLocations.length,
                    itemBuilder: (context, index) {
                      final location = clientLocations[index];
                      return _buildLocationCard(location);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha:0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: kPrimaryColor, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: primaryTextStyle.copyWith(
                fontSize: 16,
                fontWeight: bold,
              ),
            ),
            Text(
              title,
              style: greyTextStyle.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(LokasiModel location) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to AC units page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LocationAcPage(location: location),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      location.nama,
                      style: primaryTextStyle.copyWith(
                        fontSize: 16,
                        fontWeight: bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          style: primaryTextStyle.copyWith(
                            fontSize: 12,
                            color: kPrimaryColor,
                            fontWeight: medium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Iconsax.location, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location.alamat,
                      style: greyTextStyle.copyWith(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Iconsax.calendar_1, size: 12, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Terakhir service: ${_formatDate(location.lastService)}',
                    style: greyTextStyle.copyWith(fontSize: 11),
                  ),
                  const Spacer(),
                  Icon(Iconsax.arrow_right_3, size: 16, color: kPrimaryColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: kPrimaryColor),
          const SizedBox(height: 16),
          Text('Memuat data lokasi...', style: greyTextStyle),
        ],
      ),
    );
  }

  Widget _buildError(String error, LocationProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.warning_2, color: Colors.orange, size: 60),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat data',
              style: primaryTextStyle.copyWith(fontSize: 16, fontWeight: bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: greyTextStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => provider.fetchLocations(clientId: widget.client.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.location, color: Colors.grey[400], size: 80),
          const SizedBox(height: 16),
          Text(
            'Belum ada data lokasi',
            style: primaryTextStyle.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.client.name} belum memiliki lokasi',
            style: greyTextStyle,
          ),
        ],
      ),
    );
  }
}