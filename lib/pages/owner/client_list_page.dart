// pages/client_list_page.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:ridho_teknik/providers/client_provider.dart';
import 'package:ridho_teknik/theme/theme.dart';
import 'package:shimmer/shimmer.dart';
import 'package:badges/badges.dart' as badges;

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
  String _selectedFilter = 'Semua';
  final List<String> _filterOptions = ['Semua', 'Aktif', 'Baru', 'Premium'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientProvider>().fetchClients();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: _buildAppBar(),
      body: Consumer<ClientProvider>(
        builder: (context, provider, child) {
          // Tampilkan loading dengan shimmer
          if (provider.isLoading) {
            return _buildLoadingShimmer();
          }

          // Tampilkan error
          if (provider.error.isNotEmpty) {
            return _buildError(provider.error, provider);
          }

          // Filter clients berdasarkan search dan filter
          List<Client> filteredClients = provider.clients;

          if (_isSearching && _searchController.text.isNotEmpty) {
            filteredClients = provider.searchClients(_searchController.text);
          }

          // Apply additional filters menggunakan properti yang ada
          if (_selectedFilter == 'Aktif') {
            // Gunakan totalService > 0 sebagai indikator aktif
            filteredClients = filteredClients.where((c) => c.totalService > 0).toList();
          } else if (_selectedFilter == 'Baru') {
            // Ambil 3 client teratas sebagai "baru" (simulasi)
            filteredClients = provider.clients.length > 3
                ? provider.clients.sublist(0, 3)
                : provider.clients;
          } else if (_selectedFilter == 'Premium') {
            filteredClients = filteredClients.where((c) => c.rating >= 4.5).toList();
          }

          return Column(
            children: [
              // Search Bar dengan animasi
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isSearching ? _buildSearchBar() : const SizedBox.shrink(),
              ),

              // Filter chips
              // _buildFilterChips(),

              // Statistik cards dengan carousel effect
              _buildStatisticsCards(provider),

              // List clients dengan header
              Expanded(
                child: _buildClientList(provider, filteredClients),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Tambah client baru
          _showAddClientDialog();
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
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isSearching
            ? TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Cari client...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          autofocus: true,
          onChanged: (value) => setState(() {}),
        )
            : const Text(
          'Data Client',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
      ),
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isSearching
                ? const Icon(Iconsax.close_circle, key: ValueKey('close'))
                : const Icon(Iconsax.search_normal, key: ValueKey('search')),
          ),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
              }
            });
          },
        ),
        // IconButton(
        //   icon: const Icon(Iconsax.filter),
        //   onPressed: () {
        //     _showFilterBottomSheet();
        //   },
        // ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: kBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari berdasarkan nama, telepon, atau alamat...',
                  hintStyle: greyTextStyle.copyWith(fontSize: 14),
                  prefixIcon: Icon(Iconsax.search_normal, color: kPrimaryColor),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Iconsax.close_circle, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final option = _filterOptions[index];
          final isSelected = _selectedFilter == option;

          return Padding(
            padding: const EdgeInsets.only(right: 8, top: 12),
            child: ChoiceChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = option;
                });
              },
              selectedColor: kPrimaryColor,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87, // Ubah dari kTextColor
                fontWeight: FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? kPrimaryColor : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: isSelected ? 2 : 0,
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsCards(ClientProvider provider) {
    // Hitung statistik berdasarkan data yang ada
    final totalClients = provider.clients.length;
    final activeClients = provider.clients.where((c) => c.totalService > 0).length;
    final newClients = provider.clients.length > 5 ? 5 : provider.clients.length; // Simulasi

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildStatCard(
            title: 'Total',
            value: totalClients.toString(),
            icon: Iconsax.people,
            color: kPrimaryColor,
            trend: '+${provider.clients.length > 10 ? '12' : '5'}%',
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            title: 'Aktif',
            value: activeClients.toString(),
            icon: Iconsax.activity,
            color: Colors.green,
            trend: activeClients > 0 ? '+5%' : null,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            title: 'Baru',
            value: newClients.toString(),
            icon: Iconsax.user_add,
            color: Colors.blue,
            trend: newClients > 0 ? '+23%' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
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
                  child: Icon(icon, color: color, size: 20),
                ),
                // if (trend != null)
                //   Container(
                //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                //     decoration: BoxDecoration(
                //       color: Colors.green.withValues(alpha:0.1),
                //       borderRadius: BorderRadius.circular(8),
                //     ),
                //     child: Row(
                //       children: [
                //         Icon(Iconsax.arrow_up_2, size: 12, color: Colors.green),
                //         const SizedBox(width: 2),
                //         Text(
                //           trend,
                //           style: TextStyle(
                //             fontSize: 10,
                //             fontWeight: FontWeight.bold,
                //             color: Colors.green,
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
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

  Widget _buildClientList(ClientProvider provider, List<Client> clients) {
    return RefreshIndicator.adaptive(
      onRefresh: () => provider.fetchClients(),
      backgroundColor: Colors.white,
      color: kPrimaryColor,
      child: clients.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        itemCount: clients.length + 1, // +1 untuk header
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daftar Client',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87, // Ubah dari primaryTextStyle
                    ),
                  ),
                  Text(
                    '${clients.length} ditemukan',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }

          final client = clients[index - 1];
          return _buildClientCard(client);
        },
      ),
    );
  }

  Widget _buildClientCard(Client client) {
    final provider = context.read<ClientProvider>();
    // Tentukan status berdasarkan properti yang ada
    final isActive = client.totalService > 0; // Client dengan service dianggap aktif
    final isNew = provider.clients.indexOf(client) < 3; // 3 pertama dianggap baru
    final isPremium = client.rating >= 4.5;

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
                builder: (_) => ClientLocationsPage(client: client),
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
                // Avatar dengan badge
                Stack(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kPrimaryColor.withValues(alpha:0.8),
                            kPrimaryColor.withValues(alpha:0.4),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          client.name.isNotEmpty ? client.name[0].toUpperCase() : 'C',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (isNew)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: badges.Badge(
                          badgeStyle: badges.BadgeStyle(
                            badgeColor: Colors.red,
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
                  ],
                ),

                const SizedBox(width: 16),

                // Client info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            client.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isPremium)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha:0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber),
                              ),
                              child: Row(
                                children: [
                                  Icon(Iconsax.star1, size: 10, color: Colors.amber),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Premium',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          Icon(Iconsax.call, size: 12, color: kPrimaryColor),
                          const SizedBox(width: 4),
                          Text(
                            client.phone,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          _buildInfoChip(
                            icon: Iconsax.receipt_text,
                            text: '${client.totalService} Service',
                            color: kPrimaryColor,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            icon: Iconsax.star,
                            text: client.rating.toStringAsFixed(1),
                            color: Colors.amber,
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            _buildInfoChip(
                              icon: Iconsax.activity,
                              text: 'Aktif',
                              color: Colors.green,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Arrow
                Icon(
                  Iconsax.arrow_right_3,
                  color: Colors.grey[400],
                  size: 20,
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

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
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

  Widget _buildError(String error, ClientProvider provider) {
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
              'Oops! Gagal Memuat Data',
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
                  onPressed: () => provider.fetchClients(),
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
                    // TODO: Buka offline mode
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
                      Icon(Iconsax.activity, size: 18),
                      SizedBox(width: 8),
                      Text('Mode Offline'),
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
              child: Icon(Iconsax.people, color: Colors.grey[400], size: 80),
            ),
            const SizedBox(height: 32),
            Text(
              'Belum Ada Data Client',
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
                'Tambahkan client pertama Anda untuk memulai manajemen pelanggan yang lebih baik',
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
                _showAddClientDialog();
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
                  Text('Tambah Client Pertama'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
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
              const SizedBox(height: 16),
              Text(
                'Filter Client',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              ..._filterOptions.map((option) {
                return ListTile(
                  leading: Icon(
                    _getFilterIcon(option),
                    color: kPrimaryColor,
                  ),
                  title: Text(option),
                  trailing: _selectedFilter == option
                      ? Icon(Iconsax.tick_circle, color: kPrimaryColor)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedFilter = option;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedFilter = 'Semua';
                    });
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    'Reset Filter',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'Aktif':
        return Iconsax.activity;
      case 'Baru':
        return Iconsax.user_add;
      case 'Premium':
        return Iconsax.crown;
      default:
        return Iconsax.filter;
    }
  }

  void _showAddClientDialog() {
    // TODO: Implement add client dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Tambah Client Baru'),
          content: const Text('Fitur tambah client akan segera tersedia!'),
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
}