// pages/client_list_page.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:ridho_teknik/providers/client_provider.dart';
import 'package:ridho_teknik/theme/theme.dart';

import '../../models/client_model.dart';
import 'client_locations_page.dart';

class ClientListPage extends StatefulWidget {
  const ClientListPage({super.key});

  @override
  State<ClientListPage> createState() => _ClientListPageState();
}

class _ClientListPageState extends State<ClientListPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientProvider>().fetchClients();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Client'),
        backgroundColor: kPrimaryColor,
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
      body: Consumer<ClientProvider>(
        builder: (context, provider, child) {
          // Tampilkan loading
          if (provider.isLoading) {
            return _buildLoading();
          }

          // Tampilkan error
          if (provider.error.isNotEmpty) {
            return _buildError(provider.error, provider);
          }

          // Filter clients berdasarkan search
          final clients = _isSearching && _searchController.text.isNotEmpty
              ? provider.searchClients(_searchController.text)
              : provider.clients;

          return Column(
            children: [
              // Search Bar (jika sedang searching)
              if (_isSearching)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari client...',
                      prefixIcon: Icon(Iconsax.search_normal, color: kPrimaryColor),
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
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),

              // Summary cards
              Container(
                padding: const EdgeInsets.all(16),
                color: kBackgroundColor,
                child: Row(
                  children: [
                    _buildSummaryCard('Total', provider.totalClients.toString(), Iconsax.people),
                    const SizedBox(width: 12),
                    _buildSummaryCard('Aktif', provider.activeClients.length.toString(), Iconsax.activity),
                    const SizedBox(width: 12),
                    _buildSummaryCard('Baru', provider.newClients.length.toString(), Iconsax.user_add),
                  ],
                ),
              ),

              // List clients
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.fetchClients(),
                  child: clients.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: clients.length,
                    itemBuilder: (context, index) {
                      final client = clients[index];
                      return _buildClientCard(client);
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
            Icon(icon, color: kPrimaryColor, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: primaryTextStyle.copyWith(
                fontSize: 18,
                fontWeight: bold,
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

  Widget _buildClientCard(Client client) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: kPrimaryColor.withValues(alpha:0.1),
          child: Text(
            client.name.isNotEmpty ? client.name[0].toUpperCase() : 'C',
            style: TextStyle(
              color: kPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          client.name,
          style: primaryTextStyle.copyWith(
            fontSize: 16,
            fontWeight: medium,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(client.phone, style: greyTextStyle),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Iconsax.receipt_text, size: 12, color: kPrimaryColor),
                const SizedBox(width: 4),
                Text(
                  '${client.totalService} Service',
                  style: greyTextStyle.copyWith(fontSize: 11),
                ),
                const SizedBox(width: 12),
                Icon(Iconsax.star, size: 12, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  client.rating.toStringAsFixed(1),
                  style: greyTextStyle.copyWith(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(Iconsax.arrow_right_3, color: kPrimaryColor),
        onTap: () {
          // 🔵 NAVIGASI KE CLIENT LOCATIONS PAGE
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClientLocationsPage(client: client),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: kPrimaryColor),
          const SizedBox(height: 16),
          Text('Memuat data client...', style: greyTextStyle),
        ],
      ),
    );
  }

  Widget _buildError(String error, ClientProvider provider) {
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
              onPressed: () => provider.fetchClients(),
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
          Icon(Iconsax.people, color: Colors.grey[400], size: 80),
          const SizedBox(height: 16),
          Text(
            'Belum ada data client',
            style: primaryTextStyle.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Data client akan muncul di sini',
            style: greyTextStyle,
          ),
        ],
      ),
    );
  }
}