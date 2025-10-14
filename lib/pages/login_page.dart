import 'package:flutter/material.dart';
import '../components/background_page.dart';
import '../components/loading_button.dart';
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

  @override
  Widget build(BuildContext context) {
    // AuthProvider authProvider = Provider.of<AuthProvider>(context);

    // Future<void> handleSignIn() async {
    //   String usernameValue = usernameController.text.trim();
    //   String passwordValue = passwordController.text.trim();
    //
    //   // Validate username and Password
    //   setState(() {
    //     isusernameError = usernameValue.isEmpty;
    //     isPasswordError = passwordValue.isEmpty;
    //   });
    //
    //   if (isusernameError || isPasswordError) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(
    //         content: Semantics(
    //           liveRegion: true,
    //           child: Text(
    //             isusernameError
    //                 ? 'username Harus diisi'
    //                 : 'Password Harus diisi',
    //           ),
    //         ),
    //       ),
    //     );
    //     return;
    //   }
    //
    //   setState(() {
    //     isLoading = true;
    //   });
    //
    //   try {
    //     if (await authProvider.login(username: usernameValue, password: passwordValue)) {
    //       Navigator.pushReplacementNamed(context, '/home');
    //     } else {
    //       ScaffoldMessenger.of(context).showSnackBar(
    //         SnackBar(
    //           backgroundColor: kBoxMenuRedColor,
    //           content: Semantics(
    //             liveRegion: true,
    //             child: const Text(
    //               'Gagal Login!',
    //               textAlign: TextAlign.center,
    //             ),
    //           ),
    //         ),
    //       );
    //     }
    //   } catch (e) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(
    //         backgroundColor: kBoxMenuRedColor,
    //         content: Semantics(
    //           liveRegion: true,
    //           child: const Text(
    //             'Gagal melakukan login. Periksa koneksi internet Anda.',
    //             textAlign: TextAlign.center,
    //           ),
    //         ),
    //       ),
    //     );
    //   } finally {
    //     setState(() {
    //       isLoading = false;
    //     });
    //   }
    // }

    void togglePasswordVisibility() {
      setState(() {
        kunciPassword = !kunciPassword;
      });
    }


    Widget imageLogin() {
      return Center(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.08,
            ),
            Image.asset(
              'assets/logo_ridho_teknik.png',
              height: MediaQuery.of(context).size.height * 0.4,
            ),
            Text("data")
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
              borderRadius: BorderRadius.only(
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
                    hintText: 'Masukkan Username',
                    hintStyle: const TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.w300,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      Icons.person,
                      color: kPrimaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: kPrimaryColor,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(40.0),
                    ),
                    errorText: isUsernameError ? 'username Harus diisi' : null,
                  ),
                  onFieldSubmitted: (value) {
                    FocusScope.of(context).requestFocus(passwordFocusNode);
                  },
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
                    prefixIcon: const Icon(
                      Icons.lock_outlined,
                      color: kPrimaryColor,
                    ),
                    suffixIcon: GestureDetector(
                      onTap: togglePasswordVisibility,
                      child: Semantics(
                        label: kunciPassword
                            ? 'Show password'
                            : 'Hide password',
                        child: Icon(
                          kunciPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: kPrimaryColor,
                        ),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(40.0),
                      borderSide: const BorderSide(
                        color: kPrimaryColor,
                        width: 1.0,
                      ),
                    ),
                    errorText: isPasswordError ? 'Password Harus diisi' : null,
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
                    onPressed: (){
                      Navigator.of(context).pushReplacementNamed('/home');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Login",
                        style: whiteTextStyle.copyWith(
                          fontWeight: extraBold,
                          fontSize: 14
                        )
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Belum punya akun? ", style: greyTextStyle,),
                    Text("Daftar", style: primaryTextStyle.copyWith(
                      fontWeight: semiBold
                    ),),
                  ],
                )
              ],
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundPrimaryColor,
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
