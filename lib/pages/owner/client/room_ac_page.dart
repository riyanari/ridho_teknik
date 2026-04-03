import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:ridho_teknik/models/lokasi_model.dart';
import 'package:ridho_teknik/models/room_model.dart';
import 'package:ridho_teknik/providers/owner_master_provider.dart';
import 'package:ridho_teknik/theme/theme.dart';
import 'package:shimmer/shimmer.dart';
import 'package:badges/badges.dart' as badges;

import '../add_ac_unit_dialog.dart';

class RoomAcPage extends StatefulWidget {
  final LokasiModel location;
  final RoomModel room;

  const RoomAcPage({
    super.key,
    required this.location,
    required this.room,
  });

  @override
  State<RoomAcPage> createState() => _RoomAcPageState();
}

class _RoomAcPageState extends State<RoomAcPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OwnerMasterProvider>().fetchAcUnitsByRoom(widget.room.id);
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Belum pernah service';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'Hari ini';
    if (difference.inDays == 1) return 'Kemarin';
    if (difference.inDays < 7) return '${difference.inDays} hari lalu';
    if (difference.inDays < 30) return '${difference.inDays ~/ 7} minggu lalu';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unit AC',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              widget.room.name,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<OwnerMasterProvider>(
        builder: (context, provider, child) {
          if (provider.loading) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 6,
              itemBuilder: (_, __) => Shimmer.fromColors(
                baseColor: Colors.grey[200]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 100,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            );
          }

          final acUnits = provider.acUnits;

          if (acUnits.isEmpty) {
            return Center(
              child: Text(
                'Belum ada unit AC di ruangan ini',
                style: TextStyle(color: Colors.grey[600]),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                context.read<OwnerMasterProvider>().fetchAcUnitsByRoom(widget.room.id),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: acUnits.length,
              itemBuilder: (context, index) {
                final ac = acUnits[index];
                final needsService = ac.terakhirService == null ||
                    ac.terakhirService!.isBefore(
                      DateTime.now().subtract(const Duration(days: 90)),
                    );

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[100]!),
                        ),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: needsService
                                        ? Colors.orange.withValues(alpha: 0.1)
                                        : kPrimaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Iconsax.cpu,
                                    color: needsService
                                        ? Colors.orange
                                        : kPrimaryColor,
                                  ),
                                ),
                                if (needsService)
                                  Positioned(
                                    right: -2,
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ac.nama,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${ac.merk} • ${ac.type}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Text(
                                        ac.kapasitas,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: kPrimaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        _formatDate(ac.terakhirService),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Iconsax.arrow_right_3,
                              color: Colors.grey[400],
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: GestureDetector(
        onTap: () async {
          final result = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) => AddAcUnitDialog(roomId: widget.room.id),
          );

          if (result == true && context.mounted) {
            context.read<OwnerMasterProvider>().fetchAcUnitsByRoom(widget.room.id);
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kPrimaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Tambah AC',
                style: whiteTextStyle.copyWith(fontSize: 12),
              ),
            ),
            const SizedBox(width: 10),
            FloatingActionButton(
              onPressed: () async {
                final result = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => AddAcUnitDialog(roomId: widget.room.id),
                );

                if (result == true && context.mounted) {
                  context.read<OwnerMasterProvider>().fetchAcUnitsByRoom(widget.room.id);
                }
              },
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              child: const Icon(Iconsax.add),
            ),
          ],
        ),
      ),
    );
  }
}