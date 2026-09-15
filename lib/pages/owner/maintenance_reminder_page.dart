import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/maintenance_reminder_model.dart';
import '../../models/user_model.dart';
import '../../theme/theme.dart';

class MaintenanceReminderPage extends StatefulWidget {
  final int intervalMonths;

  final List<MaintenanceReminderLocation> locations;

  const MaintenanceReminderPage({
    super.key,
    required this.intervalMonths,
    required this.locations,
  });

  @override
  State<MaintenanceReminderPage> createState() =>
      _MaintenanceReminderPageState();
}

class _MaintenanceReminderPageState extends State<MaintenanceReminderPage> {
  final TextEditingController _searchController = TextEditingController();

  String _search = '';

  // ============================================================
  // COLORS
  // ============================================================

  static const Color _safeColor = Color(0xFF16A34A);

  static const Color _warningColor = Color(0xFFF59E0B);

  static const Color _urgentColor = Color(0xFFEF4444);

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<MaintenanceReminderLocation> get _filteredLocations {
    final query = _search.trim().toLowerCase();

    final result = widget.locations.where((location) {
      if (query.isEmpty) {
        return true;
      }

      if (location.locationName.toLowerCase().contains(query)) {
        return true;
      }

      for (final user in location.users) {
        final name = (user.name ?? '').trim().toLowerCase();

        final email = (user.email ?? '').trim().toLowerCase();

        final phone = (user.phone ?? '').trim().toLowerCase();

        if (name.contains(query) ||
            email.contains(query) ||
            phone.contains(query)) {
          return true;
        }
      }

      return false;
    }).toList();

    // ==========================================================
    // PRIORITAS
    //
    // - paling terlambat
    // - paling dekat jatuh tempo
    // ==========================================================

    result.sort((a, b) {
      final aRemaining = a.remainingDays ?? 999999;

      final bRemaining = b.remainingDays ?? 999999;

      return aRemaining.compareTo(bRemaining);
    });

    return result;
  }

  // ============================================================
  // STATUS
  // ============================================================

  List<MaintenanceReminderLocation> get _urgentLocations {
    return _filteredLocations.where((location) {
      return location.status == MaintenanceStatus.urgent;
    }).toList();
  }

  List<MaintenanceReminderLocation> get _warningLocations {
    return _filteredLocations.where((location) {
      return location.status == MaintenanceStatus.warning;
    }).toList();
  }

  List<MaintenanceReminderLocation> get _safeLocations {
    return _filteredLocations.where((location) {
      return location.status == MaintenanceStatus.safe;
    }).toList();
  }

  // ============================================================
  // TOTAL
  // ============================================================

  int get _totalAc {
    return widget.locations.fold(0, (total, item) => total + item.acCount);
  }

  int get _totalPic {
    final ids = <String>{};

    for (final location in widget.locations) {
      for (final user in location.users) {
        if (user.id != null) {
          ids.add('id:${user.id}');

          continue;
        }

        final email = (user.email ?? '').trim().toLowerCase();

        if (email.isNotEmpty) {
          ids.add('email:$email');

          continue;
        }

        final phone = (user.phone ?? '').trim();

        if (phone.isNotEmpty) {
          ids.add('phone:$phone');
        }
      }
    }

    return ids.length;
  }

  int get _urgentTotal {
    return widget.locations
        .where((e) => e.status == MaintenanceStatus.urgent)
        .length;
  }

  int get _warningTotal {
    return widget.locations
        .where((e) => e.status == MaintenanceStatus.warning)
        .length;
  }

  int get _safeTotal {
    return widget.locations
        .where((e) => e.status == MaintenanceStatus.safe)
        .length;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final locations = _filteredLocations;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFF5F6FA),
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              child: InkWell(
                borderRadius: BorderRadius.circular(13),
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.035),
                    ),
                  ),
                  child: const Icon(
                    Iconsax.arrow_left_2,
                    size: 19,
                    color: Color(0xFF1B1E2D),
                  ),
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          'Reminder Perawatan',
          style: TextStyle(
            color: Color(0xFF1B1E2D),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeader(),

                  const SizedBox(height: 14),

                  _buildSearch(),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Status Perawatan',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF1B1E2D),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Prioritas lokasi berdasarkan waktu menuju jadwal servis',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${locations.length} Lokasi',
                          style: const TextStyle(
                            fontSize: 9,
                            color: kPrimaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  if (locations.isEmpty)
                    _buildEmptySearch()
                  else ...[
                    if (_urgentLocations.isNotEmpty)
                      _buildStatusSection(
                        title: 'Mendesak',
                        subtitle:
                            'H-7, jatuh tempo, atau sudah terlambat servis',
                        color: _urgentColor,
                        icon: Iconsax.danger,
                        locations: _urgentLocations,
                      ),

                    if (_urgentLocations.isNotEmpty &&
                        (_warningLocations.isNotEmpty ||
                            _safeLocations.isNotEmpty))
                      const SizedBox(height: 24),

                    if (_warningLocations.isNotEmpty)
                      _buildStatusSection(
                        title: 'Segera Servis',
                        subtitle: 'Sudah memasuki H-30 menuju jadwal perawatan',
                        color: _warningColor,
                        icon: Iconsax.warning_2,
                        locations: _warningLocations,
                      ),

                    if (_warningLocations.isNotEmpty &&
                        _safeLocations.isNotEmpty)
                      const SizedBox(height: 24),

                    if (_safeLocations.isNotEmpty)
                      _buildStatusSection(
                        title: 'Aman',
                        subtitle: 'Jadwal perawatan masih lebih dari 1 bulan',
                        color: _safeColor,
                        icon: Iconsax.tick_circle,
                        locations: _safeLocations,
                      ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5059C8), Color(0xFF263B89)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4353B3).withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -25,
            top: -40,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            left: 120,
            bottom: -80,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.035),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Iconsax.timer_1,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: 11),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Perawatan ${widget.intervalMonths} Bulan',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Monitoring jadwal perawatan rutin AC',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.80),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: _buildHeaderStatistic(
                      icon: Iconsax.location,
                      value: '${widget.locations.length}',
                      label: 'Lokasi',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeaderStatistic(
                      icon: Iconsax.cpu,
                      value: '$_totalAc',
                      label: 'Unit AC',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeaderStatistic(
                      icon: Iconsax.people,
                      value: '$_totalPic',
                      label: 'PIC',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 13),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildLegendItem(
                        color: _urgentColor,
                        value: '$_urgentTotal',
                        label: 'Mendesak',
                      ),
                    ),

                    Expanded(
                      child: _buildLegendItem(
                        color: _warningColor,
                        value: '$_warningTotal',
                        label: 'Segera',
                      ),
                    ),

                    Expanded(
                      child: _buildLegendItem(
                        color: _safeColor,
                        value: '$_safeTotal',
                        label: 'Aman',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStatistic({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 13),
              const SizedBox(width: 5),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String value,
    required String label,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 7,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.025)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _search = value;
          });
        },
        style: const TextStyle(fontSize: 11, color: Color(0xFF1B1E2D)),
        decoration: InputDecoration(
          hintText: 'Cari lokasi atau PIC...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 10),
          prefixIcon: Icon(
            Iconsax.search_normal,
            size: 18,
            color: Colors.grey[500],
          ),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();

                    setState(() {
                      _search = '';
                    });
                  },
                  icon: const Icon(Iconsax.close_circle, size: 17),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS SECTION
  // ============================================================

  Widget _buildStatusSection({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required List<MaintenanceReminderLocation> locations,
  }) {
    if (locations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 19, color: color),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1B1E2D),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 9,
                        height: 1.3,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${locations.length} Lokasi',
                  style: TextStyle(
                    fontSize: 8,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ...List.generate(locations.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == locations.length - 1 ? 0 : 9,
              ),
              child: _buildLocationCard(locations[index]),
            );
          }),
        ],
      ),
    );
  }

  // ============================================================
  // LOCATION CARD
  // ============================================================

  Widget _buildLocationCard(MaintenanceReminderLocation location) {
    final color = location.statusColor;

    final whatsappUsers = _getWhatsappUsers(location.users);

    final hasWhatsApp = whatsappUsers.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // ====================================================
            // STATUS STRIPE
            // ====================================================
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 4, color: color),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(15, 13, 13, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =================================================
                  // MAIN ROW
                  // =================================================
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // =============================================
                      // STATUS ICON
                      // =============================================
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          location.statusIcon,
                          size: 19,
                          color: color,
                        ),
                      ),

                      const SizedBox(width: 11),

                      // =============================================
                      // LOCATION CONTENT
                      // =============================================
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    location.locationName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF20222E),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      height: 1.25,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 7),

                                _buildMaintenanceStatusBadge(location),
                              ],
                            ),

                            const SizedBox(height: 7),

                            Wrap(
                              spacing: 11,
                              runSpacing: 5,
                              children: [
                                _buildReminderMeta(
                                  icon: Iconsax.cpu,
                                  text: '${location.acCount} AC',
                                ),

                                if (location.roomCount > 0)
                                  _buildReminderMeta(
                                    icon: Iconsax.building,
                                    text: '${location.roomCount} ruang',
                                  ),

                                if (location.users.isNotEmpty)
                                  _buildReminderMeta(
                                    icon: Iconsax.people,
                                    text: '${location.users.length} PIC',
                                  ),
                              ],
                            ),

                            const SizedBox(height: 7),

                            // =======================================
                            // REMAINING
                            // =======================================
                            Row(
                              children: [
                                Icon(Iconsax.clock, size: 12, color: color),

                                const SizedBox(width: 5),

                                Expanded(
                                  child: Text(
                                    location.remainingLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // =============================================
                      // WHATSAPP
                      // =============================================
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (hasWhatsApp) {
                              _showWhatsAppPicSheet(location);
                            } else {
                              _showNoWhatsAppMessage();
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: hasWhatsApp
                                  ? const Color(
                                      0xFF25D366,
                                    ).withValues(alpha: 0.09)
                                  : Colors.grey.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Iconsax.message,
                              size: 18,
                              color: hasWhatsApp
                                  ? const Color(0xFF25D366)
                                  : Colors.grey[400],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 11),

                  // =================================================
                  // DATE INFORMATION
                  // =================================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildCompactDateInfo(
                            icon: Iconsax.calendar_1,
                            title: 'Terakhir',
                            value: location.lastServiceLabel,
                          ),
                        ),

                        Container(
                          width: 1,
                          height: 31,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          color: Colors.grey[200],
                        ),

                        Expanded(
                          child: _buildCompactDateInfo(
                            icon: Iconsax.calendar_tick,
                            title: 'Berikutnya',
                            value: location.nextServiceLabel,
                            valueColor: color,
                          ),
                        ),

                        const SizedBox(width: 7),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withValues(alpha: 0.065),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${location.intervalMonths} Bln',
                            style: const TextStyle(
                              color: kPrimaryColor,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildMaintenanceStatusBadge(MaintenanceReminderLocation location) {
    final color = location.statusColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),

          const SizedBox(width: 5),

          Text(
            location.statusTitle,
            style: TextStyle(
              color: color,
              fontSize: 7.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // META INFO
  // ============================================================

  Widget _buildReminderMeta({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: const Color(0xFF9A9CA7)),

        const SizedBox(width: 4),

        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF82848F),
            fontSize: 8,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // COMPACT DATE INFO
  // ============================================================

  Widget _buildCompactDateInfo({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          width: 29,
          height: 29,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 13, color: Colors.grey[500]),
        ),

        const SizedBox(width: 7),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 7,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: valueColor ?? const Color(0xFF474955),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY SEARCH
  // ============================================================

  Widget _buildEmptySearch() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.search_normal,
              color: kPrimaryColor,
              size: 25,
            ),
          ),

          const SizedBox(height: 13),

          const Text(
            'Lokasi tidak ditemukan',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 5),

          Text(
            'Coba gunakan kata kunci lainnya.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WHATSAPP USERS
  // ============================================================

  List<UserModel> _getWhatsappUsers(List<UserModel> users) {
    return users.where((user) {
      return (user.phone ?? '').trim().isNotEmpty;
    }).toList();
  }

  // ============================================================
  // PIC BOTTOM SHEET
  // ============================================================

  Future<void> _showWhatsAppPicSheet(
    MaintenanceReminderLocation location,
  ) async {
    final users = _getWhatsappUsers(location.users);

    if (users.isEmpty) {
      _showNoWhatsAppMessage();

      return;
    }

    if (users.length == 1) {
      await _openWhatsApp(location: location, user: users.first);

      return;
    }

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(12),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.70,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),

                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF25D366,
                          ).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Iconsax.message,
                          color: Color(0xFF25D366),
                          size: 20,
                        ),
                      ),

                      const SizedBox(width: 11),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pilih PIC',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              location.locationName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF25D366,
                          ).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${users.length} PIC',
                          style: const TextStyle(
                            color: Color(0xFF25D366),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                    itemCount: users.length,
                    separatorBuilder: (_, __) {
                      return const SizedBox(height: 8);
                    },
                    itemBuilder: (_, index) {
                      final user = users[index];

                      return _buildPicItem(
                        sheetContext: sheetContext,
                        location: location,
                        user: user,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // PIC ITEM
  // ============================================================

  Widget _buildPicItem({
    required BuildContext sheetContext,
    required MaintenanceReminderLocation location,
    required UserModel user,
  }) {
    final name = (user.name ?? '').trim();

    final phone = (user.phone ?? '').trim();

    final email = (user.email ?? '').trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () async {
          Navigator.pop(sheetContext);

          await _openWhatsApp(location: location, user: user);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FC),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[100]!),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Iconsax.user, color: kPrimaryColor, size: 19),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isNotEmpty ? name : 'PIC',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      phone,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),

                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 8, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),
              ),

              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Iconsax.message,
                  color: Color(0xFF25D366),
                  size: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // OPEN WHATSAPP
  // ============================================================

  Future<void> _openWhatsApp({
    required MaintenanceReminderLocation location,
    required UserModel user,
  }) async {
    final rawPhone = (user.phone ?? '').trim();

    if (rawPhone.isEmpty) {
      _showNoWhatsAppMessage();

      return;
    }

    final phone = _normalizeWhatsAppPhone(rawPhone);

    if (phone.isEmpty) {
      _showNoWhatsAppMessage();

      return;
    }

    final name = (user.name ?? '').trim();

    final greeting = name.isNotEmpty ? name : 'Bapak/Ibu';

    final message =
        '''
Halo $greeting,

Kami dari Ridho Teknik ingin menginformasikan jadwal perawatan rutin AC di lokasi *${location.locationName}*.

Interval perawatan: *${location.intervalMonths} bulan*
Servis terakhir: *${location.lastServiceLabel}*
Jadwal berikutnya: *${location.nextServiceLabel}*
Status: *${location.statusTitle}*
${location.remainingLabel}

Saat ini terdapat *${location.acCount} unit AC* yang tercatat dalam reminder perawatan.

Apakah kami dapat membantu menjadwalkan kunjungan servis rutin?

Terima kasih.
Ridho Teknik
AC Service Specialist
''';

    final uri = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        _showWhatsappError();
      }
    } catch (_) {
      _showWhatsappError();
    }
  }

  // ============================================================
  // NORMALIZE PHONE
  // ============================================================

  String _normalizeWhatsAppPhone(String value) {
    var phone = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (phone.isEmpty) {
      return '';
    }

    if (phone.startsWith('0')) {
      phone = '62${phone.substring(1)}';
    } else if (phone.startsWith('8')) {
      phone = '62$phone';
    }

    return phone;
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showNoWhatsAppMessage() {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Iconsax.info_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Nomor WhatsApp PIC belum tersedia.')),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  void _showWhatsappError() {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Iconsax.close_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('WhatsApp tidak dapat dibuka.')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }
}
