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

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode passwordFocusNode = FocusNode();

  bool isLoading = false;
  bool kunciPassword = true;
  bool isUsernameError = false;
  bool isPasswordError = false;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  void togglePasswordVisibility() {
    setState(() {
      kunciPassword = !kunciPassword;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUsernameError ? 'Username/Email harus diisi' : 'Password harus diisi',
          ),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();

      // NOTE:
      // Kalau backend kamu pakai field "email", ya tetap kirim usernameValue sebagai email
      final ok = await authProvider.login(
        email: usernameValue,
        password: passwordValue,
      );

      if (!mounted) return;

      if (ok) {
        // Kalau mau berdasarkan role:
        // final role = authProvider.user?.role;
        // if (role == 'klien') Navigator.pushReplacementNamed(context, '/klien');
        // else Navigator.pushReplacementNamed(context, '/teknisi');

        Navigator.pushReplacementNamed(context, '/teknisi');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: kBoxMenuRedColor,
            content: const Text('Gagal Login!', textAlign: TextAlign.center),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: kBoxMenuRedColor,
          content: Text(
            'Gagal login: ${e.toString()}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget imageLogin() {
      return Center(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.08),
            Image.asset(
              'assets/logo_ridho_teknik.png',
              height: MediaQuery.of(context).size.height * 0.4,
            ),
            const Text("data"),
          ],
        ),
      );
    }

    Widget formLogin() {
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
            decoration: BoxDecoration(
              color: kWhiteColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(40.0),
                topRight: Radius.circular(40.0),
              ),
            ),
            child: Column(
              children: [
                TextFormField(
                  controller: usernameController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    hintText: 'Masukkan Username / Email',
                    hintStyle: const TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.w300,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.person, color: kPrimaryColor),
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(color: kPrimaryColor, width: 1.0),
                      borderRadius: BorderRadius.circular(40.0),
                    ),
                    errorText: isUsernameError ? 'Username/Email harus diisi' : null,
                  ),
                  onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(passwordFocusNode),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  obscureText: kunciPassword,
                  controller: passwordController,
                  focusNode: passwordFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Masukkan Password',
                    hintStyle: const TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.w300,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.lock_outlined, color: kPrimaryColor),
                    suffixIcon: GestureDetector(
                      onTap: togglePasswordVisibility,
                      child: Semantics(
                        label: kunciPassword ? 'Show password' : 'Hide password',
                        child: Icon(
                          kunciPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: kPrimaryColor,
                        ),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(40.0),
                      borderSide: const BorderSide(color: kPrimaryColor, width: 1.0),
                    ),
                    errorText: isPasswordError ? 'Password harus diisi' : null,
                  ),
                ),
                const SizedBox(height: 10),

                isLoading
                    ? const LoadingButton()
                    : SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    onPressed: handleSignIn, // ✅ ini yang penting
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Login",
                        style: whiteTextStyle.copyWith(
                          fontWeight: bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Belum punya akun? ", style: greyTextStyle),
                    Text(
                      "Daftar",
                      style: primaryTextStyle.copyWith(fontWeight: semiBold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: kPrimaryColor,
      body: Stack(
        children: [
          const BackgroundPage(),
          imageLogin(),
          formLogin(),
        ],
      ),
    );
  }
}