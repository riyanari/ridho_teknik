// pages/technician_list_page.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:ridho_teknik/providers/technician_provider.dart';
import 'package:ridho_teknik/theme/theme.dart';

import '../../models/technician_model.dart';

class TechnicianListPage extends StatefulWidget {
  const TechnicianListPage({super.key});

  @override
  State<TechnicianListPage> createState() => _TechnicianListPageState();
}

class _TechnicianListPageState extends State<TechnicianListPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TechnicianProvider>().fetchTechnicians();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Teknisi'),
        backgroundColor: kSecondaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Iconsax.close_circle : Iconsax.search_normal),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: Consumer<TechnicianProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return _buildLoading();
          if (provider.error.isNotEmpty) return _buildError(provider.error, provider);

          final technicians = _isSearching && _searchController.text.isNotEmpty
              ? provider.searchTechnicians(_searchController.text)
              : provider.technicians;

          return Column(
            children: [
              if (_isSearching)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari teknisi...',
                      prefixIcon: Icon(Iconsax.search_normal, color: kSecondaryColor),
                      suffixIcon: IconButton(
                        icon: Icon(Iconsax.close_circle, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),

              Container(
                padding: const EdgeInsets.all(16),
                color: kBackgroundColor,
                child: Row(
                  children: [
                    _buildSummaryCard('Total', provider.totalTechnicians.toString(), Iconsax.profile_2user),
                    const SizedBox(width: 12),
                    _buildSummaryCard('Aktif', provider.activeTechnicians.length.toString(), Iconsax.activity),
                    const SizedBox(width: 12),
                    _buildSummaryCard('Terbaik', provider.topTechnicians.length.toString(), Iconsax.star1),
                  ],
                ),
              ),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.fetchTechnicians(),
                  child: technicians.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: technicians.length,
                    itemBuilder: (context, index) {
                      return _buildTechnicianCard(technicians[index]);
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

  Widget _buildSummaryCard(String title, String value, IconData icon) {
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
            Icon(icon, color: kSecondaryColor, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: primaryTextStyle.copyWith(
                fontSize: 18,
                fontWeight: bold,
                color: kSecondaryColor,
              ),
            ),
            Text(
              title,
              style: greyTextStyle.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicianCard(Technician tech) {
    Color statusColor = tech.status == 'aktif' ? kBoxMenuGreenColor : kBoxMenuRedColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: kSecondaryColor.withValues(alpha:0.1),
          child: Text(
            tech.name.isNotEmpty ? tech.name[0].toUpperCase() : 'T',
            style: TextStyle(
              color: kSecondaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          tech.name,
          style: primaryTextStyle.copyWith(
            fontSize: 16,
            fontWeight: medium,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${tech.spesialisasi} • ${tech.phone}', style: greyTextStyle),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tech.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: bold,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Iconsax.receipt_text, size: 12, color: kSecondaryColor),
                const SizedBox(width: 4),
                Text(
                  '${tech.totalService} Service',
                  style: greyTextStyle.copyWith(fontSize: 11),
                ),
                const SizedBox(width: 12),
                Icon(Iconsax.star1, size: 12, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  tech.rating.toStringAsFixed(1),
                  style: greyTextStyle.copyWith(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(Iconsax.arrow_right_3, color: kSecondaryColor),
        onTap: () {
          // Navigate to technician detail
        },
      ),
    );
  }

  Widget _buildLoading() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: kSecondaryColor),
        const SizedBox(height: 16),
        Text('Memuat data teknisi...', style: greyTextStyle),
      ],
    ),
  );

  Widget _buildError(String error, TechnicianProvider provider) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.warning_2, color: Colors.orange, size: 60),
          const SizedBox(height: 16),
          Text('Gagal memuat data', style: primaryTextStyle.copyWith(fontSize: 16, fontWeight: bold)),
          const SizedBox(height: 8),
          Text(error, style: greyTextStyle, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => provider.fetchTechnicians(),
            style: ElevatedButton.styleFrom(
              backgroundColor: kSecondaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    ),
  );

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Iconsax.profile_2user, color: Colors.grey[400], size: 80),
        const SizedBox(height: 16),
        Text('Belum ada data teknisi', style: primaryTextStyle.copyWith(fontSize: 16)),
        const SizedBox(height: 8),
        Text('Data teknisi akan muncul di sini', style: greyTextStyle),
      ],
    ),
  );
}