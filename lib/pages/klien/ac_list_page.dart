// lib/pages/klien/ac_list_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridho_teknik/pages/klien/servis_history_page.dart';
import 'package:ridho_teknik/pages/klien/widgets/empty_state.dart';
import 'package:ridho_teknik/pages/klien/widgets/modern_ac_card.dart';
import '../../models/ac_model.dart';
import '../../models/lokasi_model.dart';
import '../../providers/client_ac_provider.dart';
import '../../theme/theme.dart';
import 'keluhan_create_page.dart';
import 'cuci_ac_page.dart'; // Halaman untuk cuci AC

class AcListPage extends StatefulWidget {
  final LokasiModel lokasi;
  const AcListPage({super.key, required this.lokasi});

  @override
  State<AcListPage> createState() => _AcListPageState();
}

class _AcListPageState extends State<AcListPage> {
  final TextEditingController _searchController = TextEditingController();
  List<AcModel> _filteredAC = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locId = int.tryParse(widget.lokasi.id) ?? 0;
      context.read<ClientAcProvider>().fetchAc(locationId: locId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    final list = context.read<ClientAcProvider>().ac;

    setState(() {
      _filteredAC = list.where((ac) {
        return (ac.nama.toLowerCase().contains(query) ||
            ac.merk.toLowerCase().contains(query) ||
            ac.type.toLowerCase().contains(query));
      }).toList();
    });
  }

  void _openCuciAcPage() {
    final listToShow = _searchController.text.isEmpty
        ? context.read<ClientAcProvider>().ac
        : _filteredAC;

    if (listToShow.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak ada AC di lokasi ini'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CuciAcPage(
          lokasi: widget.lokasi,
          acList: listToShow,
        ),
      ),
    );
  }

  Widget _buildHeader(List<AcModel> list) {
    final totalAC = list.length;
    final needService = list
        .where((ac) => DateTime.now().difference(ac.terakhirService).inDays > 60)
        .length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryColor, Color(0xFF5D6BC0)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha:0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button and title
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.lokasi.nama,
                      style: whiteTextStyle.copyWith(
                        fontSize: 16,
                        fontWeight: bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Kelola AC di lokasi ini',
                      style: whiteTextStyle.copyWith(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha:0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // Action buttons
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ServisHistoryPage(lokasi: widget.lokasi),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.history_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _openCuciAcPage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cleaning_services, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari AC...',
                hintStyle: greyTextStyle,
                prefixIcon: Icon(Icons.search, color: kPrimaryColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Stats Cards
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total AC',
                  value: totalAC.toString(),
                  icon: Icons.ac_unit_rounded,
                  color: Colors.white,
                  bgColor: Colors.white.withValues(alpha:0.2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  title: 'Normal',
                  value: (totalAC - needService).toString(),
                  icon: Icons.check_circle_rounded,
                  color: Colors.white,
                  bgColor: Colors.white.withValues(alpha:0.2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  title: 'Perlu Service',
                  value: needService.toString(),
                  icon: Icons.warning_rounded,
                  color: Colors.white,
                  bgColor: Colors.white.withValues(alpha:0.2),
                ),
              ),
            ],
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
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: whiteTextStyle.copyWith(
              fontSize: 18,
              fontWeight: bold,
            ),
          ),
          Text(
            title,
            style: whiteTextStyle.copyWith(
              fontSize: 10,
              color: Colors.white.withValues(alpha:0.8),
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
      body: SafeArea(
        child: Consumer<ClientAcProvider>(
          builder: (context, prov, _) {
            if (prov.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (prov.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    prov.error!,
                    style: greyTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final listToShow =
            _searchController.text.isEmpty ? prov.ac : _filteredAC;

            return Column(
              children: [
                _buildHeader(listToShow),

                // Quick Action Button untuk Cuci AC
                if (listToShow.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openCuciAcPage,
                        icon: Icon(Icons.cleaning_services, size: 20),
                        label: Text(
                          'CUCI SEMUA AC DI LOKASI INI',
                          style: whiteTextStyle.copyWith(
                            fontSize: 13,
                            fontWeight: bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ),
                  ),

                Expanded(
                  child: listToShow.isEmpty
                      ? EmptyState(
                    icon: Icons.ac_unit_outlined,
                    title: _searchController.text.isEmpty
                        ? 'Belum Ada AC'
                        : 'AC Tidak Ditemukan',
                    subtitle: _searchController.text.isEmpty
                        ? 'Belum ada AC dari server'
                        : 'Coba dengan kata kunci lain',
                    actionText: 'Refresh',
                    onAction: () async {
                      final locId = int.tryParse(widget.lokasi.id) ?? 0;
                      await context
                          .read<ClientAcProvider>()
                          .fetchAc(locationId: locId);
                      _onSearchChanged();
                    },
                    iconColor: kPrimaryColor,
                  )
                      : Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Daftar AC',
                              style: primaryTextStyle.copyWith(
                                fontSize: 14,
                                fontWeight: bold,
                              ),
                            ),
                            Text(
                              '${listToShow.length} ditemukan',
                              style:
                              greyTextStyle.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.separated(
                            itemCount: listToShow.length,
                            separatorBuilder: (_, __) =>
                            const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final ac = listToShow[index];
                              return ModernAcCard(
                                ac: ac,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => KeluhanCreatePage(
                                        ac: ac,
                                        lokasi: widget.lokasi,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => _openAcForm(),
      //   backgroundColor: kSecondaryColor,
      //   foregroundColor: Colors.white,
      //   elevation: 6,
      //   shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.circular(16),
      //   ),
      //   child: const Icon(Icons.add, size: 28),
      // ),
    );
  }
}