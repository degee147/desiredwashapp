import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'widgets/main_shell.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'screens/auth/auth_screens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const LaundryApp());
}

class LaundryApp extends StatelessWidget {
  const LaundryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiService();

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: api),
        ChangeNotifierProvider(create: (_) => AuthProvider(api)),
        ChangeNotifierProvider(create: (_) => OrderProvider(api)),
      ],
      child: MaterialApp(
        title: 'DesiredWash',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme, // ← original theme, untouched
        home: const _AppGate(),
      ),
    );
  }
}

/// Checks stored token on cold start.
/// → authenticated  : shows MainShell (your existing bottom nav)
/// → unauthenticated: shows WelcomeScreen (new auth flow)
class _AppGate extends StatefulWidget {
  const _AppGate();
  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    await auth.tryAutoLogin();
    if (auth.isAuthenticated) {
      context.read<OrderProvider>().load();
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final auth = context.watch<AuthProvider>();
    return auth.isAuthenticated ? const MainShell() : const WelcomeScreen();
  }
}
