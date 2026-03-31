import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:ridho_teknik/models/lokasi_model.dart';
import 'package:ridho_teknik/models/room_model.dart';
import 'package:ridho_teknik/theme/theme.dart';
import 'package:shimmer/shimmer.dart';
import 'package:badges/badges.dart' as badges;

import '../../../providers/owner_master_provider.dart';
import 'room_ac_page.dart';
import 'add_room_dialog.dart';

class LocationRoomsPage extends StatefulWidget {
  final LokasiModel location;

  const LocationRoomsPage({super.key, required this.location});

  @override
  State<LocationRoomsPage> createState() => _LocationRoomsPageState();
}

class _LocationRoomsPageState extends State<LocationRoomsPage> {
  int? _selectedFloor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OwnerMasterProvider>().fetchRoomsByLocation(
        widget.location.id,
      );
    });
  }

  List<int> _extractFloors(List<RoomModel> rooms) {
    final floors = rooms
        .map((e) => e.floor?.number ?? 0)
        .where((e) => e > 0)
        .toSet()
        .toList()
      ..sort();

    return floors;
  }

  Widget _buildFloorFilter(List<int> floors) {
    if (floors.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Iconsax.building_4, size: 18, color: kPrimaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _selectedFloor,
                isExpanded: true,
                hint: const Text('Semua lantai'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Semua lantai'),
                  ),
                  ...floors.map(
                        (floor) => DropdownMenuItem<int?>(
                      value: floor,
                      child: Text('Lantai $floor'),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedFloor = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Ruangan',
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
              color: Colors.white.withValues(alpha: 0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      centerTitle: false,
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
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildLocationHeader(int totalRooms, int totalAc) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Iconsax.location, color: kPrimaryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.location.nama,
                      style: const TextStyle(
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildHeaderChip(
                icon: Iconsax.building_4,
                text: '$totalRooms Ruangan',
                color: Colors.purple,
              ),
              _buildHeaderChip(
                icon: Iconsax.cpu,
                text: '$totalAc Unit AC',
                color: kPrimaryColor,
              ),
              _buildHeaderChip(
                icon: Iconsax.calendar_1,
                text: _formatDate(widget.location.lastService),
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsList(List<RoomModel> rooms) {
    return RefreshIndicator.adaptive(
      onRefresh: () => context.read<OwnerMasterProvider>().fetchRoomsByLocation(
        widget.location.id,
      ),
      backgroundColor: Colors.white,
      color: kPrimaryColor,
      child: rooms.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        itemCount: rooms.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Semua Ruangan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${rooms.length} Ruangan',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }

          final room = rooms[index - 1];
          final totalAc = room.acUnitsCount;
          final floorNumber = room.floor?.number ?? 0;
          final needsAttention = totalAc == 0;

          return _buildRoomCard(
            room: room,
            totalAc: totalAc,
            floorNumber: floorNumber,
            lastService: null,
            needsAttention: needsAttention,
          );
        },
      ),
    );
  }

  Widget _buildRoomCard({
    required RoomModel room,
    required int totalAc,
    required int floorNumber,
    required DateTime? lastService,
    required bool needsAttention,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 0,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RoomAcPage(
                  location: widget.location,
                  room: room,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[100]!),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: needsAttention
                            ? Colors.orange.withValues(alpha: 0.1)
                            : kPrimaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Iconsax.building_4,
                        color: needsAttention ? Colors.orange : kPrimaryColor,
                        size: 24,
                      ),
                    ),
                    if (needsAttention)
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
                      Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  room.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (needsAttention)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange),
                              ),
                              child: const Text(
                                'Perlu Dicek',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        room.code?.isNotEmpty == true
                            ? 'Kode: ${room.code}'
                            : 'Ruangan terdaftar di lokasi ini',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildRoomInfoItem(
                            icon: Iconsax.cpu,
                            label: 'Unit AC',
                            value: '$totalAc',
                            color: kPrimaryColor,
                          ),
                          const SizedBox(width: 16),
                          _buildRoomInfoItem(
                            icon: Iconsax.building4,
                            label: 'Lantai',
                            value: 'Lantai $floorNumber',
                            color: Colors.purple,
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

  Widget _buildRoomInfoItem({
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
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
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
              child: Icon(
                Iconsax.building_4,
                color: Colors.grey[400],
                size: 80,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Belum Ada Ruangan',
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
                'Lokasi ${widget.location.nama} belum memiliki ruangan. Tambahkan ruangan pertama untuk memulai.',
                style: TextStyle(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _showAddRoomDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
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
                  Text('Tambah Ruangan'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Belum ada';

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
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[200]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        );
      },
    );
  }

  Widget _buildError(String error) {
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
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.warning_2, color: Colors.orange, size: 60),
            ),
            const SizedBox(height: 24),
            const Text(
              'Gagal Memuat Ruangan',
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
            ElevatedButton(
              onPressed: () {
                context.read<OwnerMasterProvider>().fetchRoomsByLocation(
                  widget.location.id,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddRoomDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddRoomDialog(
        locationId: widget.location.id,
        initialFloorNumber: _selectedFloor,
      ),
    );

    if (result == true && mounted) {
      await context.read<OwnerMasterProvider>().fetchRoomsByLocation(
        widget.location.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: _buildAppBar(),
      body: Consumer<OwnerMasterProvider>(
        builder: (context, provider, child) {
          if (provider.loading) return _buildLoadingShimmer();

          if ((provider.error ?? '').isNotEmpty) {
            return _buildError(provider.error ?? "Terjadi kesalahan");
          }

          final allRooms = provider.getRoomsByLocation(widget.location.id);
          final floors = _extractFloors(allRooms);

          final rooms = _selectedFloor == null
              ? allRooms
              : allRooms
              .where((e) => (e.floor?.number ?? 0) == _selectedFloor)
              .toList();

          final totalAc = allRooms.fold<int>(
            0,
                (sum, room) => sum + room.acUnitsCount,
          );

          return Column(
            children: [
              _buildLocationHeader(allRooms.length, totalAc),
              _buildFloorFilter(floors),
              Expanded(
                child: _buildRoomsList(rooms),
              ),
            ],
          );
        },
      ),
      floatingActionButton: GestureDetector(
        onTap: _showAddRoomDialog,
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
                'Tambah Ruangan',
                style: whiteTextStyle.copyWith(fontSize: 12),
              ),
            ),
            const SizedBox(width: 10),
            FloatingActionButton(
              onPressed: _showAddRoomDialog,
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Iconsax.add, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}