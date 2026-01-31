import 'package:flutter/material.dart';

import '../../../models/ac_model.dart';
import '../../../theme/theme.dart';

class ModernAcCard extends StatelessWidget {
  final AcModel ac;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ModernAcCard({
    required this.ac,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  Color _getStatusColor() {
    final daysSinceService = DateTime.now().difference(ac.terakhirService).inDays;
    if (daysSinceService <= 30) return kBoxMenuGreenColor;
    if (daysSinceService <= 60) return kSecondaryColor;
    return kBoxMenuRedColor;
  }

  String _getStatusText() {
    final daysSinceService = DateTime.now().difference(ac.terakhirService).inDays;
    if (daysSinceService <= 30) return 'Normal';
    if (daysSinceService <= 60) return 'Perlu Cek';
    return 'Perlu Service';
  }

  Widget _buildServiceIndicator() {
    final days = DateTime.now().difference(ac.terakhirService).inDays;
    final statusColor = _getStatusColor();
    final statusText = _getStatusText();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: days <= 30
            ? LinearGradient(
          colors: [statusColor.withValues(alpha:0.9), statusColor],
        )
            : LinearGradient(
          colors: [statusColor.withValues(alpha:0.1), statusColor.withValues(alpha:0.2)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: days > 30
            ? Border.all(color: statusColor.withValues(alpha:0.3))
            : null,
        boxShadow: days <= 30
            ? [
          BoxShadow(
            color: statusColor.withValues(alpha:0.3),
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
            _getStatusIcon(days),
            size: 14,
            color: days <= 30 ? Colors.white : statusColor,
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: primaryTextStyle.copyWith(
              fontSize: 12,
              fontWeight: medium,
              color: days <= 30 ? Colors.white : statusColor,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(int days) {
    if (days <= 30) return Icons.check_circle_rounded;
    if (days <= 60) return Icons.info_rounded;
    return Icons.warning_amber_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final daysSinceService = DateTime.now().difference(ac.terakhirService).inDays;
    final statusColor = _getStatusColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
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
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ac.nama,
                        style: primaryTextStyle.copyWith(
                          fontSize: 18,
                          fontWeight: bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Icon(Icons.branding_watermark_rounded, size: 14, color: kGreyColor),
                          const SizedBox(width: 6),
                          Text(
                            ac.merk,
                            style: greyTextStyle.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: kGreyColor.withValues(alpha:0.7),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: kBoxMenuDarkBlueColor.withValues(alpha:0.1),
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
                              'Edit AC',
                              style: primaryTextStyle.copyWith(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: kBoxMenuRedColor.withValues(alpha:0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.delete_rounded,
                                size: 16,
                                color: kBoxMenuRedColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Hapus AC',
                              style: errorTextStyle.copyWith(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // AC Details Row
              Row(
                children: [
                  _buildDetailItem(
                    icon: Icons.build_rounded,
                    title: 'Type',
                    value: ac.type,
                    color: kBoxMenuDarkBlueColor,
                  ),
                  const SizedBox(width: 16),
                  _buildDetailItem(
                    icon: Icons.bolt_rounded,
                    title: 'Kapasitas',
                    value: ac.kapasitas,
                    color: kBoxMenuGreenColor,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Last Service Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha:0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha:0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha:0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Terakhir Service',
                            style: greyTextStyle.copyWith(fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${daysSinceService} hari yang lalu',
                            style: primaryTextStyle.copyWith(
                              fontSize: 14,
                              fontWeight: medium,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildServiceIndicator(),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Single Action Button - Ajukan Keluhan
              ElevatedButton.icon(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                icon: Icon(Icons.message_rounded, size: 20),
                label: Text(
                  'Ajukan Keluhan',
                  style: whiteTextStyle.copyWith(
                    fontSize: 16,
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

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: greyTextStyle.copyWith(fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: primaryTextStyle.copyWith(
                fontSize: 14,
                fontWeight: bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}