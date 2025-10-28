import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:field_investigator_app/screens/auth/login_screen.dart';
import 'package:field_investigator_app/screens/main_screen.dart';
import 'package:field_investigator_app/core/services/auth_service.dart';
import 'package:field_investigator_app/core/controllers/client_controller.dart';
import 'package:field_investigator_app/core/controllers/contactability_controller.dart';
import 'package:field_investigator_app/core/controllers/dashboard_controller.dart';
import 'package:field_investigator_app/core/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API service
  ApiService().initialize();

  // Ensure system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  // Disable screenshot for Android and iOS
  if (Platform.isAndroid || Platform.isIOS) {
    await _disableScreenshot();
  }

  runApp(MyApp());
}

// Method to disable screenshot on Android
Future<void> _disableScreenshot() async {
  try {
    const platform = MethodChannel('com.skorcard.fiapp/screenshot');
    await platform.invokeMethod('disableScreenshot');
    debugPrint('✅ Screenshot disabled successfully');
  } catch (e) {
    debugPrint('❌ Failed to disable screenshot: $e');
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProxyProvider<AuthService, ClientController>(
          create: (context) => ClientController(context.read<AuthService>()),
          update: (context, authService, previous) =>
              previous ?? ClientController(authService),
        ),
        ChangeNotifierProxyProvider<AuthService, ContactabilityController>(
          create: (context) =>
              ContactabilityController(context.read<AuthService>()),
          update: (context, authService, previous) =>
              previous ?? ContactabilityController(authService),
        ),
        ChangeNotifierProxyProvider<AuthService, DashboardController>(
          create: (context) => DashboardController(context.read<AuthService>()),
          update: (context, authService, previous) =>
              previous ?? DashboardController(authService),
        ),
      ],
      child: MaterialApp(
        title: 'Field Investigator',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          // Explicitly set font family to ensure Material Icons work
          fontFamily: 'Roboto',
          // Ensure icon theme is properly set
          iconTheme: const IconThemeData(
            color: Colors.black87,
          ),
        ),
        home: AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.isAuthenticated) {
          return MainScreen();
        } else {
          return LoginScreen();
        }
      },
    );
  }
}
