import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:field_investigator_app/screens/auth/login_screen.dart';
import 'package:field_investigator_app/screens/main_screen.dart';
import 'package:field_investigator_app/services/auth_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Field Investigator',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
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
