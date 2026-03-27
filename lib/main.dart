import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'api/api_client.dart';
import 'pages/splash_page.dart';
import 'pages/login_page.dart';
import 'pages/owner/home_page.dart';
import 'pages/klien/klien_page.dart';
import 'pages/teknisi/teknisi_dashboard_page.dart';
import 'pages/owner/client_list_page.dart';
import 'pages/owner/technician_list_page.dart';

import 'providers/auth_provider.dart';
import 'providers/ac_unit_provider.dart';
import 'providers/client_ac_provider.dart';
import 'providers/client_master_provider.dart';
import 'providers/client_provider.dart';
import 'providers/client_servis_provider.dart';
import 'providers/location_provider.dart';
import 'providers/owner_master_provider.dart';
import 'providers/technician_provider.dart';
import 'providers/teknisi_provider.dart';

import 'services/auth_service.dart';
import 'services/token_store.dart';
import 'services/ac_unit_service.dart';
import 'services/client_master_service.dart';
import 'services/client_service.dart';
import 'services/client_servis_service.dart';
import 'services/location_service.dart';
import 'services/owner_master_service.dart' hide ClientMasterService;
import 'services/technician_service.dart';
import 'services/teknisi_master_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', '');
  Intl.defaultLocale = 'id_ID';

  // 🔥 SINGLETON (PENTING)
  final tokenStore = TokenStore();
  final apiClient = ApiClient(store: tokenStore);
  final authService = AuthService(apiClient);

  runApp(
    MultiProvider(
      providers: [
        // CORE
        Provider<TokenStore>.value(value: tokenStore),
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthService>.value(value: authService),

        // SERVICES
        Provider<ClientMasterService>(
          create: (context) =>
              ClientMasterService(api: context.read<ApiClient>()),
        ),
        Provider<ClientServisService>(
          create: (context) => ClientServisService(
            api: context.read<ApiClient>(),
            store: tokenStore,
          ),
        ),
        Provider<ClientService>(
          create: (context) =>
              ClientService(api: context.read<ApiClient>()),
        ),
        Provider<TechnicianService>(
          create: (context) =>
              TechnicianService(api: context.read<ApiClient>()),
        ),
        Provider<LocationService>(
          create: (context) =>
              LocationService(api: context.read<ApiClient>()),
        ),
        Provider<AcUnitService>(
          create: (context) =>
              AcUnitService(api: context.read<ApiClient>()),
        ),
        Provider<OwnerMasterService>(
          create: (context) =>
              OwnerMasterService(api: context.read<ApiClient>()),
        ),
        Provider<TeknisiService>(
          create: (context) =>
              TeknisiService(api: context.read<ApiClient>()),
        ),

        // AUTH PROVIDER
        ChangeNotifierProvider(
          create: (context) => AuthProvider(
            service: context.read<AuthService>(),
            store: context.read<TokenStore>(),
          ),
        ),

        // OTHER PROVIDERS
        ChangeNotifierProvider(
          create: (context) =>
              ClientMasterProvider(service: context.read<ClientMasterService>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              ClientAcProvider(service: context.read<ClientMasterService>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              ClientServisProvider(service: context.read<ClientServisService>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              ClientProvider(service: context.read<ClientService>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              TechnicianProvider(service: context.read<TechnicianService>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              LocationProvider(service: context.read<LocationService>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              AcUnitProvider(service: context.read<AcUnitService>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              OwnerMasterProvider(service: context.read<OwnerMasterService>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              TeknisiProvider(service: context.read<TeknisiService>()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashPage(),
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
        '/klien': (_) => const KlienPage(),
        '/teknisi': (_) => const TeknisiDashboardPage(),
        '/client-list': (_) => const ClientListPage(),
        '/technician-list': (_) => const TechnicianListPage(),
      },
    );
  }
}