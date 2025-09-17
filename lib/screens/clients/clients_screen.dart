import 'package:flutter/material.dart';
import 'list_client_tab.dart';
import 'contactability_history_tab.dart';

class ClientsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Client Management'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'List Clients'),
              Tab(text: 'Contactability History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListClientTab(),
            ContactabilityHistoryTab(),
          ],
        ),
      ),
    );
  }
}
