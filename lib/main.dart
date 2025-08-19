import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:field_investigator_app/screens/auth/login_screen.dart';
import 'package:field_investigator_app/screens/main_screen.dart';
import 'package:field_investigator_app/core/services/auth_service.dart';
import 'package:field_investigator_app/core/controllers/client_controller.dart';
import 'package:field_investigator_app/core/controllers/contactability_controller.dart';
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

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ClientController()),
        ChangeNotifierProvider(create: (_) => ContactabilityController()),
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
