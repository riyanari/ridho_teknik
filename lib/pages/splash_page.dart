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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthProvider>();

    bool isLoggedIn = false;

    try {
      isLoggedIn = await auth.tryAutoLogin();
    } catch (_) {
      isLoggedIn = false;
    }

    if (!mounted) return;

    if (isLoggedIn) {
      final role = auth.user?.role ?? 'klien';

      switch (role) {
        case 'owner':
          Navigator.pushReplacementNamed(context, '/home');
          break;
        case 'teknisi':
          Navigator.pushReplacementNamed(context, '/teknisi');
          break;
        default:
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
                color: kGreyColor.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            top: -30,
            right: -75,
            child: CustomPaint(
              size: const Size(100, 100),
              painter: HalfCirclePainter(
                color: kGreyColor.withValues(alpha: 0.15),
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