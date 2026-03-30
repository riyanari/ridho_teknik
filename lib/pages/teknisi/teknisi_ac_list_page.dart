import 'package:flutter/material.dart';

import '../../models/ac_model.dart';
import '../../models/lokasi_model.dart';
import '../../models/servis_model.dart';
import '../../theme/theme.dart';
import 'teknisi_servis_detail_page.dart';

class TeknisiAcListPage extends StatefulWidget {
  final LokasiModel lokasi;
  final List<ServisModel> servisList;
  final String? teknisiId;
  final String? teknisiNama;

  const TeknisiAcListPage({
    super.key,
    required this.lokasi,
    required this.servisList,
    this.teknisiId,
    this.teknisiNama,
  });

  @override
  State<TeknisiAcListPage> createState() => _TeknisiAcListPageState();
}

class _TeknisiAcListPageState extends State<TeknisiAcListPage> {
  List<_AssignedAcTask> get _assignedTasks {
    final result = <_AssignedAcTask>[];

    for (final servis in widget.servisList) {
      final sameLocation = servis.locationId?.toString() == widget.lokasi.id;
      if (!sameLocation) continue;

      if (servis.itemsData.isNotEmpty) {
        for (final item in servis.itemsData) {
          final acRaw = item['ac_unit'];
          final acMap = acRaw is Map<String, dynamic>
              ? acRaw
              : (acRaw is Map ? Map<String, dynamic>.from(acRaw) : null);

          if (acMap == null) continue;

          final itemTechnicianId =
          (item['technician_id'] ?? servis.technicianId)?.toString();
          if (widget.teknisiId != null &&
              widget.teknisiId!.isNotEmpty &&
              itemTechnicianId != widget.teknisiId) {
            continue;
          }

          final ac = _acFromMap(acMap, servis);
          result.add(
            _AssignedAcTask(
              ac: ac,
              servis: servis,
              item: item,
            ),
          );
        }
        continue;
      }

      if (servis.acData != null) {
        final serviceTechnicianId = servis.technicianId?.toString();
        if (widget.teknisiId != null &&
            widget.teknisiId!.isNotEmpty &&
            serviceTechnicianId != widget.teknisiId) {
          continue;
        }

        final ac = _acFromMap(servis.acData!, servis);
        result.add(
          _AssignedAcTask(
            ac: ac,
            servis: servis,
            item: null,
          ),
        );
      }
    }

    final seen = <String>{};
    final unique = <_AssignedAcTask>[];

    for (final task in result) {
      final key = '${task.servis.id}-${task.ac.id}';
      if (seen.add(key)) {
        unique.add(task);
      }
    }

    return unique;
  }

  AcModel _acFromMap(Map<String, dynamic> map, ServisModel servis) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return AcModel(
      id: parseInt(map['id']),
      roomId: parseInt(map['room_id']),
      locationId: parseInt(map['location_id'] ?? servis.locationId),
      nama: (map['name'] ?? 'Unit AC').toString(),
      merk: (map['brand'] ?? '-').toString(),
      type: (map['type'] ?? '-').toString(),
      kapasitas: (map['capacity'] ?? '-').toString(),
      lantai: parseInt(map['lantai']),
      terakhirService: parseDate(map['last_service']),
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
      room: null,
    );
  }

  Widget _buildHeader() {
    final totalAc = _assignedTasks.length;

    final dalamPengerjaan = _assignedTasks.where((task) {
      final status = _itemStatus(task).toLowerCase();
      return status == 'dikerjakan';
    }).length;

    final menunggu = _assignedTasks.where((task) {
      final status = _itemStatus(task).toLowerCase();
      return status == 'menunggukonfirmasi' ||
          status == 'menunggu_konfirmasi' ||
          status == 'ditugaskan';
    }).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryColor, const Color(0xFF5D6BC0)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
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
                    const SizedBox(height: 4),
                    Text(
                      widget.teknisiNama?.isNotEmpty == true
                          ? 'Tugas untuk ${widget.teknisiNama}'
                          : 'AC yang perlu ditangani',
                      style: whiteTextStyle.copyWith(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total AC',
                  value: totalAc.toString(),
                  icon: Icons.ac_unit_rounded,
                  color: Colors.white,
                  bgColor: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  title: 'Dikerjakan',
                  value: dalamPengerjaan.toString(),
                  icon: Icons.build_rounded,
                  color: Colors.white,
                  bgColor: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  title: 'Menunggu',
                  value: menunggu.toString(),
                  icon: Icons.hourglass_top_rounded,
                  color: Colors.white,
                  bgColor: Colors.white.withValues(alpha: 0.2),
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
              color: Colors.white.withValues(alpha: 0.3),
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
          const SizedBox(height: 4),
          Text(
            title,
            style: whiteTextStyle.copyWith(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _itemStatus(_AssignedAcTask task) {
    if (task.item != null) {
      final raw = (task.item!['status'] ?? '').toString().trim();
      if (raw.isNotEmpty) return raw;
    }
    return task.servis.status.name;
  }

  Color _statusColorFromKey(String key) {
    switch (key.toLowerCase()) {
      case 'menunggukonfirmasi':
      case 'menunggu_konfirmasi':
        return Colors.orange;
      case 'ditugaskan':
        return Colors.blue;
      case 'dikerjakan':
        return Colors.purple;
      case 'selesai':
        return Colors.green;
      case 'batal':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusTextFromKey(String key) {
    switch (key.toLowerCase()) {
      case 'menunggukonfirmasi':
      case 'menunggu_konfirmasi':
        return 'Menunggu Konfirmasi';
      case 'ditugaskan':
        return 'Ditugaskan';
      case 'dikerjakan':
        return 'Dikerjakan';
      case 'selesai':
        return 'Selesai';
      case 'batal':
        return 'Batal';
      default:
        return key;
    }
  }

  String _statusEmojiFromKey(String key) {
    switch (key.toLowerCase()) {
      case 'menunggukonfirmasi':
      case 'menunggu_konfirmasi':
        return '⏰';
      case 'ditugaskan':
        return '📋';
      case 'dikerjakan':
        return '🔧';
      case 'selesai':
        return '✅';
      case 'batal':
        return '❌';
      default:
        return '📄';
    }
  }

  Widget _buildAcCard(_AssignedAcTask task) {
    final ac = task.ac;
    final servis = task.servis;

    final lastService = ac.terakhirService;
    final daysSinceService = lastService == null
        ? null
        : DateTime.now().difference(lastService).inDays;

    final statusKey = _itemStatus(task);
    final statusColor = _statusColorFromKey(statusKey);
    final statusText = _statusTextFromKey(statusKey);

    final keluhan =
    (servis.keluhanClient ?? servis.catatan ?? '').toString().trim();
    final tindakan = (servis.tindakanSummary ?? '').toString().trim();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeknisiServisDetailPage(
              lokasi: widget.lokasi,
              ac: ac,
              servis: servis,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor.withValues(alpha: 0.1),
                          statusColor.withValues(alpha: 0.2),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _statusEmojiFromKey(statusKey),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      statusText,
                      style: primaryTextStyle.copyWith(
                        fontSize: 12,
                        fontWeight: medium,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                ac.nama,
                style: primaryTextStyle.copyWith(
                  fontSize: 18,
                  fontWeight: bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '${ac.merk} • ${ac.type} • ${ac.kapasitas}',
                style: greyTextStyle.copyWith(fontSize: 13),
              ),
              if (keluhan.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_rounded,
                            size: 14,
                            color: statusColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              keluhan,
                              style: primaryTextStyle.copyWith(
                                fontSize: 14,
                                fontWeight: medium,
                                color: statusColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (tindakan.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Tindakan: $tindakan',
                          style: greyTextStyle.copyWith(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoBadge(
                    icon: Icons.calendar_today_rounded,
                    text: daysSinceService == null
                        ? 'Belum pernah service'
                        : '$daysSinceService hari',
                    color: kBoxMenuCoklatColor,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoBadge(
                    icon: Icons.receipt_long_rounded,
                    text: 'Rp ${servis.totalBiaya.toInt()}',
                    color: kBoxMenuGreenColor,
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TeknisiServisDetailPage(
                            lokasi: widget.lokasi,
                            ac: ac,
                            servis: servis,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: Text(
                      'Tangani',
                      style: whiteTextStyle.copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            style: primaryTextStyle.copyWith(
              fontSize: 12,
              fontWeight: medium,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.ac_unit,
            size: 64,
            color: kGreyColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak Ada AC',
            style: primaryTextStyle.copyWith(
              fontSize: 18,
              fontWeight: bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tidak ada AC yang perlu ditangani di lokasi ini',
            style: greyTextStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _assignedTasks;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: tasks.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    ...tasks.map(_buildAcCard),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignedAcTask {
  final AcModel ac;
  final ServisModel servis;
  final Map<String, dynamic>? item;

  const _AssignedAcTask({
    required this.ac,
    required this.servis,
    required this.item,
  });
}