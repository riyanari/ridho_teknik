import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/half_circle_painter.dart';
import '../providers/auth_provider.dart';
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

    // lebih aman: jalankan setelah widget ter-render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _go();
    });
  }

  Future<void> _go() async {
    final auth = context.read<AuthProvider>();

    bool ok = false;
    try {
      ok = await auth.tryAutoLogin();
    } catch (_) {
      ok = false;
    }

    if (!mounted) return;

    if (ok) {
      final role = auth.user?.role ?? 'klien';
      if (role == 'owner') {
        Navigator.pushReplacementNamed(context, '/home');
      } else if (role == 'teknisi') {
        Navigator.pushReplacementNamed(context, '/teknisi');
      } else {
        Navigator.pushReplacementNamed(context, '/klien');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      body: Stack(
        children: [
          Positioned(
            top: 90,
            right: -50,
            child: CustomPaint(
              size: const Size(100, 100),
              painter: HalfCirclePainter(
                color: kGreyColor.withValues(alpha:0.1),
              ),
            ),
          ),
          Positioned(
            top: -30,
            right: -75,
            child: CustomPaint(
              size: const Size(100, 100),
              painter: HalfCirclePainter(
                color: kGreyColor.withValues(alpha:0.15),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Image.asset(
                  'assets/cvrt-lg.png',
                  width: MediaQuery.of(context).size.width * 0.7,
                ),
                const Spacer(),
                const CircularProgressIndicator(
                  strokeWidth: 5,
                  valueColor: AlwaysStoppedAnimation<Color>(kGreyColor),
                  backgroundColor: kSecondaryColor,
                  semanticsLabel: 'Loading...',
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
