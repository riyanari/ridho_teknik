import 'package:flutter/material.dart';

import '../theme/theme.dart';

class BackgroundPage extends StatelessWidget {
  const BackgroundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Image.asset(
        'assets/img_background_buble.png',
        fit: BoxFit.cover,
        color: kGreyColor.withValues(alpha: 0.15),
      ),
    );
  }
}
