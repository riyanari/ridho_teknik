import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridho_teknik/providers/client_ac_provider.dart';
import 'package:ridho_teknik/providers/client_master_provider.dart';
import 'package:ridho_teknik/services/client_master_service.dart';

import 'api/api_client.dart';
import 'pages/splash_page.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/klien/klien_page.dart';
import 'pages/teknisi/teknisi_dashboard_page.dart';

import 'providers/auth_provider.dart';
import 'services/auth_service.dart';
import 'services/token_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final TokenStore _tokenStore = TokenStore();
  static final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TokenStore>.value(value: _tokenStore),
        Provider<AuthService>.value(value: _authService),

        // ApiClient (pakai tokenStore)
        Provider<ApiClient>(
          create: (_) => ApiClient(store: _tokenStore),
        ),

        // Auth Provider kamu (tetap)
        ChangeNotifierProvider(
          create: (context) => AuthProvider(
            service: context.read<AuthService>(),
            store: context.read<TokenStore>(),
          ),
        ),

        // Client services + provider
        Provider<ClientMasterService>(
          create: (context) => ClientMasterService(api: context.read<ApiClient>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ClientMasterProvider(
            service: context.read<ClientMasterService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ClientAcProvider(
            service: context.read<ClientMasterService>(),
          ),
        ),


      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        routes: {
          '/': (_) => const SplashPage(),
          '/login': (_) => const LoginPage(),
          '/home': (_) => const HomePage(),
          '/klien': (_) => const KlienPage(),
          '/teknisi': (_) => const TeknisiDashboardPage(),
        },
      ),
    );
  }
}