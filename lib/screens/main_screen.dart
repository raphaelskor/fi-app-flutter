import 'package:flutter/material.dart';
import 'package:field_investigator_app/widgets/bottom_navigation.dart';
import 'package:field_investigator_app/screens/dashboard/dashboard_screen.dart';
import 'package:field_investigator_app/screens/clients/clients_screen.dart';
import 'package:field_investigator_app/screens/history/history_screen.dart';
import 'package:field_investigator_app/screens/profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    DashboardScreen(),
    ClientsScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigation(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
      ),
    );
  }
}
