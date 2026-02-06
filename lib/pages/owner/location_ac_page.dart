// pages/location_ac_page.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:ridho_teknik/models/ac_model.dart';
import 'package:ridho_teknik/models/lokasi_model.dart';
import 'package:ridho_teknik/providers/ac_unit_provider.dart';
import 'package:ridho_teknik/theme/theme.dart';

class LocationAcPage extends StatefulWidget {
  final LokasiModel location;

  const LocationAcPage({super.key, required this.location});

  @override
  State<LocationAcPage> createState() => _LocationAcPageState();
}

class _LocationAcPageState extends State<LocationAcPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcUnitProvider>().fetchAcUnits(
          locationId: int.tryParse(widget.location.id) ?? 0
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AC - ${widget.location.nama}'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AcUnitProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return _buildLoading();

          if (provider.error.isNotEmpty) return _buildError(provider.error, provider);

          final locationAcUnits = provider.getAcUnitsByLocation(
              int.tryParse(widget.location.id) ?? 0
          );

          return Column(
            children: [
              // Location info card
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Iconsax.location, color: kPrimaryColor, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.location.nama,
                            style: primaryTextStyle.copyWith(
                              fontSize: 16,
                              fontWeight: bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.location.alamat,
                      style: greyTextStyle.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildInfoChip(
                            '${widget.location.jumlahAC} AC',
                            Iconsax.cpu,
                            kPrimaryColor
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                            _formatDate(widget.location.lastService),
                            Iconsax.calendar_1,
                            kSecondaryColor
                        ),
                        if (widget.location.client != null) ...[
                          const SizedBox(width: 8),
                          _buildInfoChip(
                              widget.location.client!.name,
                              Iconsax.profile_circle,
                              kBoxMenuGreenColor
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // AC units list
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daftar AC',
                      style: primaryTextStyle.copyWith(
                        fontSize: 16,
                        fontWeight: bold,
                      ),
                    ),
                    Text(
                      '${locationAcUnits.length} unit',
                      style: greyTextStyle.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.fetchAcUnits(
                      locationId: int.tryParse(widget.location.id) ?? 0
                  ),
                  child: locationAcUnits.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: locationAcUnits.length,
                    itemBuilder: (context, index) {
                      final acUnit = locationAcUnits[index];
                      return _buildAcUnitCard(acUnit);
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

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha:0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcUnitCard(AcModel acUnit) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Iconsax.cpu, color: kPrimaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        acUnit.nama,
                        style: primaryTextStyle.copyWith(
                          fontSize: 16,
                          fontWeight: bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${acUnit.merk} • ${acUnit.type}',
                        style: greyTextStyle.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem('Kapasitas', acUnit.kapasitas, Iconsax.cpu),
                ),
                Expanded(
                  child: _buildDetailItem('Terakhir Service',
                      _formatDate(acUnit.terakhirService),
                      Iconsax.calendar_1
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: greyTextStyle.copyWith(fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: primaryTextStyle.copyWith(fontSize: 13, fontWeight: medium),
        ),
      ],
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
          Text('Memuat data AC...', style: greyTextStyle),
        ],
      ),
    );
  }

  Widget _buildError(String error, AcUnitProvider provider) {
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
              onPressed: () => provider.fetchAcUnits(
                  locationId: int.tryParse(widget.location.id) ?? 0
              ),
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
          Icon(Iconsax.cpu, color: Colors.grey[400], size: 80),
          const SizedBox(height: 16),
          Text(
            'Belum ada data AC',
            style: primaryTextStyle.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Lokasi ${widget.location.nama} belum memiliki AC',
            style: greyTextStyle,
          ),
        ],
      ),
    );
  }
}