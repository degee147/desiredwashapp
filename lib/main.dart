import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// 🔽 NEW: Firebase + Notifications
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/push_notification_service.dart';
import 'providers/notification_provider.dart';

// Existing imports
import 'theme/app_theme.dart';
import 'widgets/main_shell.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'screens/auth/auth_screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 🔽 Firebase init
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔽 Push notifications init
  await PushNotificationService().init();

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

        // 🔽 NEW: Notification provider
        ChangeNotifierProvider(create: (_) => NotificationProvider(api)),
      ],
      child: MaterialApp(
        title: 'DesiredWash',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const _AppGate(),
      ),
    );
  }
}

/// Checks stored token on cold start.
/// → authenticated  : shows MainShell
/// → unauthenticated: shows WelcomeScreen
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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _init();
      _initPushCallbacks(context); // 🔽 NEW
    });
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    await auth.tryAutoLogin();

    if (auth.isAuthenticated) {
      context.read<OrderProvider>().load();
    }

    if (mounted) setState(() => _ready = true);
  }

  // 🔽 NEW: Push callback wiring
  void _initPushCallbacks(BuildContext context) {
    PushNotificationService().onForegroundMessage = (notification) {
      context.read<NotificationProvider>().addLocalNotification(notification);
    };

    PushNotificationService().onNotificationTap = (orderId) {
      if (orderId != null) {
        // TODO: Navigate to order details screen
        // Navigator.push(context, MaterialPageRoute(
        //   builder: (_) => OrderDetailScreen(orderId: orderId),
        // ));
      } else {
        // TODO: Replace with your actual Notifications screen
        // Navigator.push(context,
        //   MaterialPageRoute(builder: (_) => const NotificationsScreen()));
      }
    };
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
