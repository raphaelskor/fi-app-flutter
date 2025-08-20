import 'package:flutter/material.dart';
import 'metrics_tab.dart';
import 'history_list_tab.dart';

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Contactability History'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Metrics'),
              Tab(text: 'History List'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            MetricsTab(),
            const HistoryListTab(),
          ],
        ),
      ),
    );
  }
}
