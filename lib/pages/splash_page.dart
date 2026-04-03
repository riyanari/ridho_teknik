import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
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
  bool _isBlockedByUpdate = false;
  String _updateMessage = 'Memeriksa pembaruan aplikasi...';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    final canContinue = await _checkPlayStoreForceUpdate();

    if (!mounted) return;

    if (!canContinue) {
      return;
    }

    await _continueToApp();
  }

  Future<bool> _checkPlayStoreForceUpdate() async {
    if (kDebugMode) {
      log('Skipping Play Store update check in debug mode');
      return true;
    }

    try {
      setState(() {
        _updateMessage = 'Memeriksa pembaruan aplikasi...';
      });

      final updateInfo = await InAppUpdate.checkForUpdate();
      log('Update info: $updateInfo');

      if (updateInfo.updateAvailability != UpdateAvailability.updateAvailable) {
        log('No Play Store update available');
        return true;
      }

      log('Update available, starting immediate update...');

      setState(() {
        _isBlockedByUpdate = true;
        _updateMessage = 'Pembaruan wajib tersedia. Aplikasi harus diperbarui.';
      });

      final result = await InAppUpdate.performImmediateUpdate();
      log('Immediate update result: $result');

      if (result == AppUpdateResult.success) {
        log('Update success');
        return true;
      }

      log('Update not completed: $result');

      if (mounted) {
        setState(() {
          _isBlockedByUpdate = true;
          _updateMessage =
          'Pembaruan wajib belum selesai. Silakan buka Play Store lalu update aplikasi.';
        });
      }

      return false;
    } catch (e, st) {
      log('Error checking/updating app: $e', stackTrace: st);

      if (mounted) {
        setState(() {
          _isBlockedByUpdate = true;
          _updateMessage =
          'Gagal memproses pembaruan wajib. Coba buka ulang aplikasi dan update melalui Play Store.';
        });
      }

      return false;
    }
  }

  Future<void> _continueToApp() async {
    final auth = context.read<AuthProvider>();

    bool isLoggedIn = false;

    try {
      isLoggedIn = await auth.tryAutoLogin();
    } catch (e, st) {
      log('Auto login error: $e', stackTrace: st);
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

  Future<void> _retryUpdateCheck() async {
    if (!mounted) return;

    setState(() {
      _updateMessage = 'Memeriksa ulang pembaruan aplikasi...';
    });

    final canContinue = await _checkPlayStoreForceUpdate();

    if (!mounted) return;

    if (canContinue) {
      await _continueToApp();
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
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _updateMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: kGreyColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Spacer(),
                if (_isBlockedByUpdate) ...[
                  ElevatedButton(
                    onPressed: _retryUpdateCheck,
                    child: const Text('Cek Lagi'),
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  const CircularProgressIndicator(
                    strokeWidth: 5,
                    valueColor: AlwaysStoppedAnimation<Color>(kGreyColor),
                    backgroundColor: kSecondaryColor,
                  ),
                  const SizedBox(height: 80),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}