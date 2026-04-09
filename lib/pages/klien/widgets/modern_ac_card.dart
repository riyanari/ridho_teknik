import 'package:flutter/material.dart';

import '../../../models/ac_model.dart';
import '../../../theme/theme.dart';

class ModernAcCard extends StatelessWidget {
  final AcModel ac;
  final VoidCallback onTap;

  const ModernAcCard({super.key, required this.ac, required this.onTap});

  int? get _daysSinceService {
    final last = ac.terakhirService;
    if (last == null) return null;
    return DateTime.now().difference(last).inDays;
  }

  bool get _isNeedService {
    final days = _daysSinceService;
    if (days == null) return true;
    return days >= 90;
  }

  Color _getStatusColor() {
    return _isNeedService ? kBoxMenuRedColor : kBoxMenuGreenColor;
  }

  String _getStatusText() {
    return _isNeedService ? 'Perlu Service' : 'Aman';
  }

  String get _roomName => ac.room?.name.trim() ?? '';

  IconData _getStatusIcon() {
    return _isNeedService
        ? Icons.warning_amber_rounded
        : Icons.check_circle_rounded;
  }

  Widget _buildServiceIndicator() {
    final statusColor = _getStatusColor();
    final statusText = _getStatusText();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: !_isNeedService
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
        border: _isNeedService
            ? Border.all(color: statusColor.withValues(alpha: 0.3))
            : null,
        boxShadow: !_isNeedService
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
            _getStatusIcon(),
            size: 14,
            color: !_isNeedService ? Colors.white : statusColor,
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: primaryTextStyle.copyWith(
              fontSize: 12,
              fontWeight: medium,
              color: !_isNeedService ? Colors.white : statusColor,
            ),
          ),
        ],
      ),
    );
  }

  String _serviceInfoText() {
    final days = _daysSinceService;
    if (days == null) return 'Belum pernah service';
    return '$days hari yang lalu';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_roomName.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _roomName,
                                  style: primaryTextStyle.copyWith(
                                    fontSize: 18,
                                    fontWeight: bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                ac.nama,
                                style: primaryTextStyle.copyWith(
                                  fontSize: 12,
                                  fontWeight: bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.branding_watermark_rounded,
                                  size: 14,
                                  color: kGreyColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  ac.merk,
                                  style: greyTextStyle.copyWith(fontSize: 13),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.business_outlined,
                                    size: 14,
                                    color: Colors.purple,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Lantai ${ac.lantai}',
                                    style: primaryTextStyle.copyWith(
                                      fontSize: 11,
                                      fontWeight: medium,
                                      color: Colors.purple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

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

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
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
                            _serviceInfoText(),
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
                icon: const Icon(Icons.message_rounded, size: 20),
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
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(title, style: greyTextStyle.copyWith(fontSize: 11)),
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
