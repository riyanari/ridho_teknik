import 'package:flutter/material.dart';

import '../../../models/lokasi_model.dart';
import '../../../theme/theme.dart';

class ModernLokasiCard extends StatelessWidget {
  final LokasiModel lokasi;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const ModernLokasiCard({
    super.key,
    required this.lokasi,
    required this.onTap,
    required this.onEdit,
  });

  DateTime? get _lastService => lokasi.lastService;

  int? get _daysSinceService {
    final last = _lastService;
    if (last == null) return null;
    return DateTime.now().difference(last).inDays;
  }

  Color _getStatusColor() {
    final daysSinceService = _daysSinceService;

    if (daysSinceService == null) return kBoxMenuRedColor;
    if (daysSinceService < 90) return kBoxMenuGreenColor;
    return kBoxMenuRedColor;
  }

  String _getStatusText() {
    final daysSinceService = _daysSinceService;

    if (daysSinceService == null) return 'Perlu Service';
    if (daysSinceService < 90) return 'Aman';
    return 'Perlu Service';
  }

  Widget _buildServiceIndicator() {
    final days = _daysSinceService;
    final safeDays = days ?? 9999;
    final statusColor = _getStatusColor();
    final statusText = _getStatusText();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: safeDays < 90
            ? LinearGradient(
          colors: [statusColor.withValues(alpha: 0.9), statusColor],
        )
            : LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.1),
            statusColor.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: safeDays > 90
            ? Border.all(color: statusColor.withValues(alpha: 0.3))
            : null,
        boxShadow: safeDays < 90
            ? [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(safeDays),
            size: 14,
            color: safeDays < 90 ? Colors.white : statusColor,
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: primaryTextStyle.copyWith(
              fontSize: 10,
              fontWeight: medium,
              color: safeDays < 90 ? Colors.white : statusColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(int days) {
    if (days < 90) return Icons.check_circle_rounded;
    return Icons.warning_amber_rounded;
  }

  String _daysText() {
    final days = _daysSinceService;
    if (days == null) return 'Belum service';
    return '$days hari';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lokasi.nama,
                          style: primaryTextStyle.copyWith(
                            fontSize: 14,
                            fontWeight: bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          lokasi.alamat,
                          style: greyTextStyle.copyWith(
                            fontSize: 10,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: kGreyColor.withValues(alpha: 0.7),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color:
                                kBoxMenuDarkBlueColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.edit_rounded,
                                size: 16,
                                color: kBoxMenuDarkBlueColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Edit Lokasi',
                              style: primaryTextStyle.copyWith(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoBadge(
                    icon: Icons.ac_unit_rounded,
                    text: '${lokasi.jumlahAC} AC',
                    color: kBoxMenuLightBlueColor,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoBadge(
                    icon: Icons.calendar_month_rounded,
                    text: _daysText(),
                    color: kBoxMenuCoklatColor,
                  ),
                  const Spacer(),
                  _buildServiceIndicator(),
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                color: kGreyColor.withValues(alpha: 0.2),
                height: 1,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.air_rounded, size: 20),
                label: Text(
                  'Lihat AC',
                  style: whiteTextStyle.copyWith(
                    fontSize: 18,
                    fontWeight: medium,
                  ),
                ),
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
        color: color.withValues(alpha: 0.08),
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
              fontSize: 10,
              fontWeight: medium,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}