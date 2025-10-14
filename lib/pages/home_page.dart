import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ridho_teknik/theme/theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Welcome dengan info bisnis
              _buildBusinessHeader(),
              const SizedBox(height: 24),

              // Statistik Cepat dengan animasi
              _buildQuickStats(),
              const SizedBox(height: 24),

              // Menu Utama - Grid dengan efek modern
              _buildMainMenuGrid(),
              const SizedBox(height: 24),

              // Reminder Service dengan gradient
              _buildServiceReminders(),
              const SizedBox(height: 24),

              // Jadwal Hari Ini dengan design card modern
              _buildTodaySchedule(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessHeader() {
    DateTime now = DateTime.now();
    String dayName = _getDayName(now.weekday);
    String monthName = _getMonthName(now.month);
    String formattedDate = '$dayName, ${now.day} $monthName ${now.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryColor, kBoxMenuDarkBlueColor],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha:0.3),
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Iconsax.personalcard, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ridho Teknik - AC Service',
                  style: whiteTextStyle.copyWith(
                    fontSize: 16,
                    fontWeight: semiBold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Selamat Datang, Owner! 👋',
            style: whiteTextStyle.copyWith(
              fontSize: 18,
              fontWeight: bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formattedDate,
            style: whiteTextStyle.copyWith(
              fontSize: 14,
              fontWeight: regular,
              color: Colors.white.withValues(alpha:0.8),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatChip('${_getTodayServices()} Service Hari Ini', Iconsax.calendar_1),
              const SizedBox(width: 8),
              _buildStatChip('${_getPendingReminders()} Reminder', Iconsax.notification_bing),
            ],
          ),
        ],
      ),
    );
  }

  // Helper functions untuk data dinamis
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Senin';
      case 2: return 'Selasa';
      case 3: return 'Rabu';
      case 4: return 'Kamis';
      case 5: return 'Jumat';
      case 6: return 'Sabtu';
      case 7: return 'Minggu';
      default: return '';
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'Januari';
      case 2: return 'Februari';
      case 3: return 'Maret';
      case 4: return 'April';
      case 5: return 'Mei';
      case 6: return 'Juni';
      case 7: return 'Juli';
      case 8: return 'Agustus';
      case 9: return 'September';
      case 10: return 'Oktober';
      case 11: return 'November';
      case 12: return 'Desember';
      default: return '';
    }
  }

  int _getTodayServices() => 7; // 7 service hari ini
  int _getPendingReminders() => 4; // 4 reminder
  int _getTotalClients() => 156; // Total client
  int _getMonthlyServices() => 42; // Service bulan ini
  int _getPendingServices() => 3; // Pending service

  Widget _buildStatChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha:0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: whiteTextStyle.copyWith(
              fontSize: 12,
              fontWeight: medium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Client',
              _getTotalClients().toString(),
              Iconsax.people,
              kBoxMenuGreenColor,
              '↑ 15% dari bulan lalu',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Service Bulan Ini',
              _getMonthlyServices().toString(),
              Iconsax.activity,
              kSecondaryColor,
              '↑ 12% dari target',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Pending',
              _getPendingServices().toString(),
              Iconsax.clock,
              kBoxMenuRedColor,
              'Butuh konfirmasi',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 100,
        maxHeight: 160,
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha:0.05),
              color.withValues(alpha:0.02),
            ],
          ),
          border: Border.all(color: color.withValues(alpha:0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Iconsax.arrow_up_3,
                        color: color,
                        size: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  value,
                  style: primaryTextStyle.copyWith(
                    fontSize: 20,
                    fontWeight: bold,
                    color: color,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  title,
                  style: greyTextStyle.copyWith(
                    fontSize: 11,
                    fontWeight: medium,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: greyTextStyle.copyWith(
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainMenuGrid() {
    final List<MainMenu> mainMenus = [
      MainMenu(
        icon: Iconsax.archive,
        title: 'Arsip',
        color: kPrimaryColor,
        description: 'Data client dengan maps & keluhan',
        gradient: [kPrimaryColor, kBoxMenuDarkBlueColor],
      ),
      MainMenu(
        icon: Iconsax.receipt,
        title: 'Invoice PDF',
        color: kBoxMenuGreenColor,
        description: 'Cetak invoice output PDF',
        gradient: [kBoxMenuGreenColor, Color(0xFF1B998B)],
      ),
      MainMenu(
        icon: Iconsax.box_tick,
        title: 'Stok Baru',
        color: kBoxMenuLightBlueColor,
        description: 'Arsip stok barang B to C',
        gradient: [kBoxMenuLightBlueColor, Color(0xFF2E3A7A)],
      ),
      MainMenu(
        icon: Iconsax.box_remove,
        title: 'Stok Rusak',
        color: kBoxMenuRedColor,
        description: 'Arsip stok barang rusak',
        gradient: [kBoxMenuRedColor, Color(0xFFD1495B)],
      ),
      MainMenu(
        icon: Iconsax.pen_tool,
        title: 'Stok Alat',
        color: kBoxMenuCoklatColor,
        description: 'Management stok alat AC',
        gradient: [kBoxMenuCoklatColor, Color(0xFF8B4513)],
      ),
      MainMenu(
        icon: Iconsax.chart_square,
        title: 'Finance',
        color: kSecondaryColor,
        description: 'Payroll, cashflow, operasional',
        gradient: [kSecondaryColor, Color(0xFFFF6B35)],
      ),
      MainMenu(
        icon: Iconsax.calendar_edit,
        title: 'Jadwal',
        color: kBoxMenuDarkBlueColor,
        description: 'Input jadwal service',
        gradient: [kBoxMenuDarkBlueColor, Color(0xFF4851A5)],
      ),
      MainMenu(
        icon: Iconsax.notification_bing,
        title: 'Reminder',
        color: Colors.purple,
        description: 'Reminder WA 3 bulan',
        gradient: [Colors.purple, Color(0xFF8B5CF6)],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Menu Utama',
                style: primaryTextStyle.copyWith(
                  fontSize: 18,
                  fontWeight: bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${mainMenus.length} Menu',
                  style: primaryTextStyle.copyWith(
                    fontSize: 12,
                    fontWeight: medium,
                    color: kPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: mainMenus.length,
          itemBuilder: (context, index) {
            return _buildMainMenuCard(context, mainMenus[index]);
          },
        ),
      ],
    );
  }

  Widget _buildMainMenuCard(BuildContext context, MainMenu menu) {
    return GestureDetector(
      onTap: () {
        _navigateToPage(context, menu.title);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: menu.gradient,
          ),
          boxShadow: [
            BoxShadow(
              color: menu.color.withValues(alpha:0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                menu.icon,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(height: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  menu.title,
                  style: whiteTextStyle.copyWith(
                    fontSize: 13,
                    fontWeight: bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  menu.description,
                  style: whiteTextStyle.copyWith(
                    fontSize: 9,
                    fontWeight: regular,
                    color: Colors.white.withValues(alpha:0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPage(BuildContext context, String menuTitle) {
    switch (menuTitle) {
      case 'Arsip':
      // Navigate to Arsip page
        break;
      case 'Invoice PDF':
      // Navigate to Invoice PDF Output
        break;
      case 'Stok Baru':
      // Navigate to Arsip stok barang baru B to C
        break;
      case 'Stok Rusak':
      // Navigate to Arsip stok barang rusak
        break;
      case 'Stok Alat':
      // Navigate to Stok alat AC
        break;
      case 'Finance':
      // Navigate to Finance Tracker
        break;
      case 'Jadwal':
      // Navigate to Jadwal Internal
        break;
      case 'Reminder':
      // Navigate to Reminder WA
        break;
    }
  }

  Widget _buildServiceReminders() {
    final List<ReminderItem> reminders = [
      ReminderItem(
        name: 'Bapak Ahmad Rizki',
        service: 'Service AC Split - Terakhir 15 Sep 2024',
        phone: '08123456789',
        icon: Iconsax.profile_circle,
        daysLeft: 2,
      ),
      ReminderItem(
        name: 'Ibu Sari Dewi',
        service: 'Service AC Standing - Terakhir 18 Sep 2024',
        phone: '08129876543',
        icon: Iconsax.profile_2user,
        daysLeft: 5,
      ),
      ReminderItem(
        name: 'PT. Maju Jaya Abadi',
        service: 'Service Central AC - Terakhir 20 Sep 2024',
        phone: '081511223344',
        icon: Iconsax.building,
        daysLeft: 7,
      ),
      ReminderItem(
        name: 'Bapak Hendra Gunawan',
        service: 'Service AC Cassette - Terakhir 22 Sep 2024',
        phone: '081355667788',
        icon: Iconsax.profile_circle,
        daysLeft: 1,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kSecondaryColor.withValues(alpha:0.1),
            kSecondaryColor.withValues(alpha:0.05),
          ],
        ),
        border: Border.all(color: kSecondaryColor.withValues(alpha:0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      clipBehavior: Clip.none,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: kSecondaryColor.withValues(alpha:0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Iconsax.notification, color: kSecondaryColor, size: 20),
                          ),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                reminders.length.toString(),
                                style: whiteTextStyle.copyWith(
                                  fontSize: 8,
                                  fontWeight: bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Reminder Service 3 Bulan',
                      style: primaryTextStyle.copyWith(
                        fontSize: 14,
                        fontWeight: bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha:0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: reminders.map((reminder) => _buildReminderItem(reminder)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderItem(ReminderItem reminder) {
    Color statusColor = reminder.daysLeft <= 2 ? Colors.red : kSecondaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha:0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(reminder.icon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.name,
                  style: primaryTextStyle.copyWith(
                    fontSize: 14,
                    fontWeight: semiBold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reminder.service,
                  style: greyTextStyle.copyWith(fontSize: 11),
                ),
                Text(
                  reminder.phone,
                  style: greyTextStyle.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          SizedBox(width: 8,),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${reminder.daysLeft}h',
              style: TextStyle(
                fontSize: 10,
                fontWeight: bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySchedule() {
    final List<ScheduleItem> schedules = [
      ScheduleItem(
        title: 'Service AC Split - Bapak Budi Santoso',
        time: '08:00 - 10:00',
        address: 'Jl. Merdeka No. 123, Jakarta Pusat',
        color: kPrimaryColor,
        icon: Iconsax.home,
        type: 'Regular Service',
      ),
      ScheduleItem(
        title: 'Pemasangan AC Baru - Ibu Ani Wijaya',
        time: '11:00 - 13:00',
        address: 'Perumahan Griya Asri Blok C5, Bekasi',
        color: kBoxMenuGreenColor,
        icon: Iconsax.home_hashtag,
        type: 'Installation',
      ),
      ScheduleItem(
        title: 'Maintenance Central AC - Hotel Grand Palace',
        time: '14:00 - 17:00',
        address: 'Jl. Sudirman No. 456, Jakarta Selatan',
        color: kSecondaryColor,
        icon: Iconsax.building,
        type: 'Maintenance',
      ),
      ScheduleItem(
        title: 'Troubleshoot AC - Kantor PT. Sejahtera',
        time: '19:00 - 21:00',
        address: 'Kuningan City Lt. 15, Jakarta Selatan',
        color: Colors.purple,
        icon: Iconsax.buildings,
        type: 'Emergency',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      clipBehavior: Clip.none,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: kPrimaryColor.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Iconsax.calendar_1, color: kPrimaryColor, size: 20),
                          ),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                schedules.length.toString(),
                                style: whiteTextStyle.copyWith(
                                  fontSize: 8,
                                  fontWeight: bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Jadwal Service Hari Ini',
                      style: primaryTextStyle.copyWith(
                        fontSize: 14,
                        fontWeight: bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Column(
              children: schedules.map((schedule) => _buildScheduleItem(schedule)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(ScheduleItem schedule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: schedule.color.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: schedule.color.withValues(alpha:0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: schedule.color.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(schedule.icon, color: schedule.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.title,
                  style: primaryTextStyle.copyWith(
                    fontSize: 14,
                    fontWeight: semiBold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Iconsax.clock, size: 12, color: schedule.color),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        schedule.time,
                        style: greyTextStyle.copyWith(fontSize: 10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: schedule.color.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        schedule.type,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: bold,
                          color: schedule.color,
                        ),
                      ),
                    ),

                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Iconsax.location, size: 12, color: schedule.color),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        schedule.address,
                        style: greyTextStyle.copyWith(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: schedule.color.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Iconsax.arrow_right_3, color: schedule.color, size: 16),
          ),
        ],
      ),
    );
  }
}

class MainMenu {
  final IconData icon;
  final String title;
  final Color color;
  final String description;
  final List<Color> gradient;

  MainMenu({
    required this.icon,
    required this.title,
    required this.color,
    required this.description,
    required this.gradient,
  });
}

class ReminderItem {
  final String name;
  final String service;
  final String phone;
  final IconData icon;
  final int daysLeft;

  ReminderItem({
    required this.name,
    required this.service,
    required this.phone,
    required this.icon,
    required this.daysLeft,
  });
}

class ScheduleItem {
  final String title;
  final String time;
  final String address;
  final Color color;
  final IconData icon;
  final String type;

  ScheduleItem({
    required this.title,
    required this.time,
    required this.address,
    required this.color,
    required this.icon,
    required this.type,
  });
}