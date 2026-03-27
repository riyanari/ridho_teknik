import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/background_page.dart';
import '../components/loading_button.dart';
import '../providers/auth_provider.dart';
import '../theme/theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode passwordFocusNode = FocusNode();

  bool isLoading = false;
  bool obscurePassword = true;
  bool isUsernameError = false;
  bool isPasswordError = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<Offset> _cardSlideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    passwordFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void togglePasswordVisibility() {
    setState(() {
      obscurePassword = !obscurePassword;
    });
  }

  Future<void> handleSignIn() async {
    final usernameValue = usernameController.text.trim();
    final passwordValue = passwordController.text.trim();

    setState(() {
      isUsernameError = usernameValue.isEmpty;
      isPasswordError = passwordValue.isEmpty;
    });

    if (isUsernameError || isPasswordError) {
      _showErrorSnackBar(
        isUsernameError
            ? 'Username / Email harus diisi'
            : 'Password harus diisi',
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();

      final ok = await authProvider.login(
        email: usernameValue,
        password: passwordValue,
      );

      if (!mounted) return;

      if (ok) {
        final role = authProvider.user?.role ?? 'klien';

        if (role == 'owner') {
          Navigator.pushReplacementNamed(context, '/home');
        } else if (role == 'teknisi') {
          Navigator.pushReplacementNamed(context, '/teknisi');
        } else {
          Navigator.pushReplacementNamed(context, '/klien');
        }
      } else {
        _showErrorSnackBar('Email atau password salah');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Gagal login: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _onForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kPrimaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: const Text(
          'Fitur lupa password belum tersedia',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _buildBackground(),
          const BackgroundPage(),
          SafeArea(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Column(
                  children: [
                    Expanded(
                      flex: 9,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: size.height - MediaQuery.of(context).padding.top,
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                  height: MediaQuery.sizeOf(context).height * 0.02
                              ),
                              _buildTopSection(size),
                              SizedBox(
                                  height: MediaQuery.sizeOf(context).height * 0.05
                              ),
                              _buildLoginCard(size),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2D4E9D),
            const Color(0xFF4C59B8),
            const Color(0xFF6A59C8),
            const Color(0xFF7A67D8),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -80,
            child: _bubble(
              size: 180,
              color: Colors.white.withValues(alpha:0.08),
            ),
          ),
          Positioned(
            top: 50,
            left: -90,
            child: _bubble(
              size: 140,
              color: Colors.cyanAccent.withValues(alpha:0.08),
            ),
          ),
          Positioned(
            bottom: 180,
            right: -30,
            child: _bubble(
              size: 160,
              color: Colors.white.withValues(alpha:0.06),
            ),
          ),
          Positioned(
            bottom: 90,
            left: 20,
            child: _bubble(
              size: 90,
              color: Colors.lightBlueAccent.withValues(alpha:0.08),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  Widget _buildTopSection(Size size) {
    return SlideTransition(
      position: _headerSlideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha:0.12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha:0.18),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.12),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha:0.10),
                  ),
                  child: Image.asset(
                    'assets/cvrt-lg.png',
                    height: size.width * 0.6,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard(Size size) {
    return SlideTransition(
      position: _cardSlideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: Colors.white.withValues(alpha:0.92),
                border: Border.all(
                  color: Colors.white.withValues(alpha:0.65),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.12),
                    blurRadius: 30,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat Datang 👋',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: kPrimaryColor,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Silakan masuk ke akun Anda untuk melanjutkan.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.45,
                    ),
                  ),
                  // const SizedBox(height: 8),
                  // Text(
                  //   'Masuk ke akun Anda untuk melanjutkan pengelolaan servis AC.',
                  //   style: TextStyle(
                  //     fontSize: 14,
                  //     color: Colors.grey.shade700,
                  //     height: 1.45,
                  //   ),
                  // ),
                  const SizedBox(height: 26),

                  _buildModernTextField(
                    controller: usernameController,
                    hint: 'Masukkan Username / Email',
                    icon: Icons.person_outline_rounded,
                    isError: isUsernameError,
                    errorText: 'Username / Email harus diisi',
                    keyboardType: TextInputType.text,
                    enabled: !isLoading,
                    onSubmitted: (_) {
                      FocusScope.of(context).requestFocus(passwordFocusNode);
                    },
                  ),

                  const SizedBox(height: 16),

                  _buildModernTextField(
                    controller: passwordController,
                    hint: 'Masukkan Password',
                    icon: Icons.lock_outline_rounded,
                    isError: isPasswordError,
                    errorText: 'Password harus diisi',
                    obscureText: obscurePassword,
                    enabled: !isLoading,
                    focusNode: passwordFocusNode,
                    suffix: GestureDetector(
                      onTap: isLoading ? null : togglePasswordVisibility,
                      child: Icon(
                        obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: Colors.grey.shade500,
                        size: 22,
                      ),
                    ),
                    onSubmitted: (_) {
                      if (!isLoading) {
                        handleSignIn();
                      }
                    },
                  ),

                  // const SizedBox(height: 8),
                  //
                  // Align(
                  //   alignment: Alignment.centerRight,
                  //   child: TextButton(
                  //     onPressed: isLoading ? null : _onForgotPassword,
                  //     style: TextButton.styleFrom(
                  //       padding: const EdgeInsets.symmetric(
                  //         horizontal: 4,
                  //         vertical: 4,
                  //       ),
                  //       minimumSize: Size.zero,
                  //       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  //     ),
                  //     child: Text(
                  //       'Lupa Password?',
                  //       style: TextStyle(
                  //         fontSize: 13,
                  //         fontWeight: FontWeight.w700,
                  //         color: kPrimaryColor,
                  //       ),
                  //     ),
                  //   ),
                  // ),

                  const SizedBox(height: 30),

                  _buildLoginButton(size),

                  const SizedBox(height: 18),

                  // Row(
                  //   children: [
                  //     Expanded(
                  //       child: Divider(
                  //         color: Colors.grey.shade300,
                  //         thickness: 1,
                  //       ),
                  //     ),
                  //     Padding(
                  //       padding: const EdgeInsets.symmetric(horizontal: 10),
                  //       child: Text(
                  //         'Akses Aman',
                  //         style: TextStyle(
                  //           color: Colors.grey.shade600,
                  //           fontSize: 12,
                  //           fontWeight: FontWeight.w600,
                  //         ),
                  //       ),
                  //     ),
                  //     Expanded(
                  //       child: Divider(
                  //         color: Colors.grey.shade300,
                  //         thickness: 1,
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  //
                  // const SizedBox(height: 16),
                  //
                  // Row(
                  //   children: [
                  //     Expanded(
                  //       child: _buildInfoChip(
                  //         Icons.verified_user_outlined,
                  //         'Terproteksi',
                  //       ),
                  //     ),
                  //     const SizedBox(width: 10),
                  //     Expanded(
                  //       child: _buildInfoChip(
                  //         Icons.build_circle_outlined,
                  //         'Teknisi Ready',
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isError,
    required String errorText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool enabled = true,
    FocusNode? focusNode,
    Widget? suffix,
    Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isError
                    ? Colors.red.withValues(alpha:0.10)
                    : kPrimaryColor.withValues(alpha:0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            obscureText: obscureText,
            keyboardType: keyboardType,
            focusNode: focusNode,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(
                icon,
                color: isError ? Colors.red.shade400 : kPrimaryColor,
                size: 22,
              ),
              suffixIcon: suffix,
              filled: true,
              fillColor: Colors.white.withValues(alpha:0.82),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1.4,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: kPrimaryColor,
                  width: 1.8,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1.2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: Colors.red.shade400,
                  width: 1.6,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: Colors.red.shade500,
                  width: 1.8,
                ),
              ),
            ),
            onChanged: (_) {
              if (isError) {
                setState(() {
                  if (controller == usernameController) {
                    isUsernameError = false;
                  } else if (controller == passwordController) {
                    isPasswordError = false;
                  }
                });
              }
            },
            onFieldSubmitted: onSubmitted,
          ),
        ),
        if (isError) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              errorText,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.red.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoginButton(Size size) {
    return AnimatedScale(
      scale: isLoading ? 0.985 : 1,
      duration: const Duration(milliseconds: 180),
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              kPrimaryColor,
              const Color(0xFF5F6DD9),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withValues(alpha:0.28),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : handleSignIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: isLoading
              ? const SizedBox(
            height: 26,
            width: 26,
            child: LoadingButton(),
          )
              : Text(
            'Masuk Sekarang',
            style: whiteTextStyle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha:0.72),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: kPrimaryColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}