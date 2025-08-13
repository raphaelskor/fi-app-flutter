import 'package:flutter/material.dart';
import 'create_contactability_tab.dart';
import 'contactability_history_tab.dart';

class ClientsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Today\'s Client List'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Create Contactability'),
              Tab(text: 'Contactability History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            CreateContactabilityTab(),
            ContactabilityHistoryTab(),
          ],
        ),
      ),
    );
  }
}
