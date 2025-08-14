import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  final Map<String, int> performanceData = {
    'visit': 12,
    'rpc': 8,
    'tpc': 15,
    'ptp': 6,
    'kp': 2,
    'bp': 3,
  };

  double calculateRatio(int numerator, int denominator) {
    if (denominator == 0) return 0.0;
    return (numerator / denominator) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Performance Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Performance',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                _buildMetricCard('Visit', performanceData['visit']!),
                _buildMetricCard('RPC', performanceData['rpc']!),
                _buildMetricCard('TPC', performanceData['tpc']!),
                _buildMetricCard('PTP', performanceData['ptp']!),
                _buildMetricCard('KP', performanceData['kp']!),
                _buildMetricCard('BP', performanceData['bp']!),
              ],
            ),
            SizedBox(height: 30),
            Text(
              'Performance Ratios',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildRatioRow(
              'RPC/Visit Ratio',
              calculateRatio(performanceData['rpc']!, performanceData['visit']!),
            ),
            _buildRatioRow(
              'PTP/Visit Ratio',
              calculateRatio(performanceData['ptp']!, performanceData['visit']!),
            ),
            _buildRatioRow(
              'KP/PTP Ratio',
              calculateRatio(performanceData['kp']!, performanceData['ptp']!),
            ),
            _buildRatioRow(
              'BP/PTP Ratio',
              calculateRatio(performanceData['bp']!, performanceData['ptp']!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, int value) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value.toString(),
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            SizedBox(height: 8),
            Text(
              '# ' + title,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatioRow(String label, double ratio) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 18, color: Colors.grey[800]),
          ),
          Text(
            '${ratio.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[700]),
          ),
        ],
      ),
    );
  }
}