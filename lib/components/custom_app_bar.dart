import 'package:flutter/material.dart';
import '../theme/theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize;
  final String title;
  final List<Widget>? action;
  final PreferredSize? tabBar;
  final Color? colors;
  final double iconSize;

  const CustomAppBar(
      this.title, {
        super.key,
        this.action,
        this.tabBar,
        this.colors,
        this.iconSize = 20.0,
      }) : preferredSize = const Size.fromHeight(50.0);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kGreyColor,
          ),
          child: Image.asset(
            'assets/ic_back.png',
            width: iconSize, // Menggunakan parameter iconSize
            height: iconSize, // Menggunakan parameter iconSize
          ),
        ),
        iconSize: iconSize + 8, // IconButton size sedikit lebih besar dari gambar
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      title: Align(
        alignment: action == null ? Alignment.centerRight : Alignment.center,
        child: Text(
          title,
          style: primaryTextStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      titleSpacing: 18,
      backgroundColor: colors ?? kBackgroundColor, // Gunakan warna custom jika ada
      elevation: 0,
      iconTheme: const IconThemeData(color: kPrimaryColor),
      automaticallyImplyLeading: false,
      actions: action,
      bottom: tabBar,
    );
  }
}