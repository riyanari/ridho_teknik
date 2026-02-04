import 'package:flutter/material.dart';

import '../../../models/lokasi_model.dart';
import '../../../theme/theme.dart';

class ModernLokasiCard extends StatelessWidget {
  final LokasiModel lokasi;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  // final VoidCallback onDelete;

  const ModernLokasiCard({super.key,
    required this.lokasi,
    required this.onTap,
    required this.onEdit,
    // required this.onDelete,
  });

  Color _getStatusColor() {
    final daysSinceService = DateTime.now().difference(lokasi.lastService).inDays;
    if (daysSinceService <= 30) return kBoxMenuGreenColor;
    if (daysSinceService <= 60) return kSecondaryColor;
    return kBoxMenuRedColor;
  }

  String _getStatusText() {
    final daysSinceService = DateTime.now().difference(lokasi.lastService).inDays;
    if (daysSinceService <= 30) return 'Aktif';
    if (daysSinceService <= 60) return 'Perlu Cek';
    return 'Perlu Service';
  }

  Widget _buildServiceIndicator() {
    final days = DateTime.now().difference(lokasi.lastService).inDays;
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
              fontSize: 10,
              fontWeight: medium,
              color: days <= 30 ? Colors.white : statusColor,
            ),
            maxLines: 2,
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
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     // Container(
              //     //   padding: const EdgeInsets.all(12),
              //     //   decoration: BoxDecoration(
              //     //     gradient: LinearGradient(
              //     //       colors: [
              //     //         kPrimaryColor.withValues(alpha:0.1),
              //     //         kPrimaryColor.withValues(alpha:0.2),
              //     //       ],
              //     //     ),
              //     //     shape: BoxShape.circle,
              //     //   ),
              //     //   child: Icon(
              //     //     Icons.location_on_rounded,
              //     //     color: kPrimaryColor,
              //     //     size: 24,
              //     //   ),
              //     // ),
              //
              //   ],
              // ),
              // const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                      // if (value == 'delete') onDelete();
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
                              'Edit Lokasi',
                              style: primaryTextStyle.copyWith(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      // const PopupMenuDivider(),
                      // PopupMenuItem(
                      //   value: 'delete',
                      //   child: Row(
                      //     children: [
                      //       Container(
                      //         padding: const EdgeInsets.all(4),
                      //         decoration: BoxDecoration(
                      //           color: kBoxMenuRedColor.withValues(alpha:0.1),
                      //           shape: BoxShape.circle,
                      //         ),
                      //         child: Icon(
                      //           Icons.delete_rounded,
                      //           size: 16,
                      //           color: kBoxMenuRedColor,
                      //         ),
                      //       ),
                      //       const SizedBox(width: 12),
                      //       Text(
                      //         'Hapus Lokasi',
                      //         style: errorTextStyle.copyWith(fontSize: 14),
                      //       ),
                      //     ],
                      //   ),
                      // ),
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
                    text: '${DateTime.now().difference(lokasi.lastService).inDays} hari',
                    color: kBoxMenuCoklatColor,
                  ),
                  const Spacer(),
                  _buildServiceIndicator(),
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                color: kGreyColor.withValues(alpha:0.2),
                height: 1,
              ),
              const SizedBox(height: 12),

              // Single Action Button - Lihat AC
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
                icon: Icon(Icons.air_rounded, size: 20),
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
          color: color.withValues(alpha:0.08),
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
        )
    );
  }
}