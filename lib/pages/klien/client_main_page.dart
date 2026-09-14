// lib/pages/klien/client_main_page.dart

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../theme/theme.dart';
import 'client_ac_locations_page.dart';
import 'klien_page.dart';

class ClientMainPage extends StatefulWidget {
  const ClientMainPage({super.key});

  @override
  State<ClientMainPage> createState() => _ClientMainPageState();
}

class _ClientMainPageState extends State<ClientMainPage> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      KlienPage(
        onOpenServis: () => _changePage(1),
        onOpenDaftarAc: () => _changePage(2),
      ),

      const _ClientServicePlaceholder(),

      const ClientAcLocationsPage(),
    ];
  }

  void _changePage(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,

      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigation() {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          18,
          0,
          18,
          14,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildNavigationItem(
                index: 0,
                icon: Iconsax.home,
                activeIcon: Iconsax.home_15,
                label: 'Home',
              ),
            ),

            Expanded(
              child: _buildNavigationItem(
                index: 1,
                icon: Iconsax.setting_2,
                activeIcon: Iconsax.setting_25,
                label: 'Servis',
              ),
            ),

            Expanded(
              child: _buildNavigationItem(
                index: 2,
                icon: Iconsax.airdrop,
                activeIcon: Iconsax.airdrop5,
                label: 'Daftar AC',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NAV ITEM
  // ============================================================

  Widget _buildNavigationItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool selected = _currentIndex == index;

    return InkWell(
      onTap: () => _changePage(index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected
              ? kPrimaryColor.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                selected ? activeIcon : icon,
                key: ValueKey(
                  'nav-$index-$selected',
                ),
                color: selected
                    ? kPrimaryColor
                    : Colors.grey.shade500,
                size: 23,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: selected
                    ? kPrimaryColor
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SERVICE PLACEHOLDER
// Nanti kita ganti dengan halaman servis sebenarnya.
// ============================================================

class _ClientServicePlaceholder extends StatelessWidget {
  const _ClientServicePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Iconsax.setting_2,
                    size: 34,
                    color: kPrimaryColor,
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  'Servis',
                  style: primaryTextStyle.copyWith(
                    fontSize: 22,
                    fontWeight: bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Halaman servis akan menampilkan pekerjaan yang sedang berjalan dan riwayat servis.',
                  textAlign: TextAlign.center,
                  style: greyTextStyle.copyWith(
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}