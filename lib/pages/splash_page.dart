import 'package:flutter/material.dart';

import '../components/half_circle_painter.dart';
import '../theme/theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getInit();
      // checkForUpdate();
    });
  }

  Future<void> getInit() async {
    // Simulasi loading 2 detik
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    // Pindah ke halaman login, hapus splash dari stack
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundPrimaryColor,
      body: Stack(
        children: [
          // Positioned.fill(
          //   child: Image.asset(
          //     'assets/img_background_buble.png',
          //     fit: BoxFit.fill,
          //     color: const Color(0xffB8FFD8).withValues(alpha: 0.7),
          //   ),
          // ),
          Positioned(
            top: 90,
            right: -50,
            child: CustomPaint(
              size: const Size(100, 100),
              painter: HalfCirclePainter(
                  color: kBoxGreyColor.withValues(alpha: 0.1)), // Gunakan painter yang telah Anda buat
            ),
          ),
          Positioned(
            top: -30,
            right: -75,
            child: CustomPaint(
              size: const Size(100, 100),
              painter: HalfCirclePainter(
                  color: kBoxGreyColor.withValues(alpha: 0.15))), // Gunakan painter yang telah Anda buat
            ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(),
                Image.asset('assets/logo_ridho_teknik.png', width: MediaQuery.of(context).size.width * 0.7,),
                Spacer(),
                const CircularProgressIndicator(
                  strokeWidth: 5,
                  valueColor: AlwaysStoppedAnimation<Color>(kBoxGreyColor),
                  backgroundColor: kSecondaryColor,
                  semanticsLabel: 'Loading...',
                ),
                const SizedBox(
                  height: 80,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
