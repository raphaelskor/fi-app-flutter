import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MetricsTab extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyData = [
    {'day': 'Mon', 'visits': 8, 'calls': 12, 'messages': 5},
    {'day': 'Tue', 'visits': 12, 'calls': 15, 'messages': 8},
    {'day': 'Wed', 'visits': 10, 'calls': 18, 'messages': 6},
    {'day': 'Thu', 'visits': 15, 'calls': 20, 'messages': 10},
    {'day': 'Fri', 'visits': 18, 'calls': 25, 'messages': 12},
    {'day': 'Sat', 'visits': 6, 'calls': 8, 'messages': 3},
    {'day': 'Sun', 'visits': 4, 'calls': 5, 'messages': 2},
  ];

  final List<Map<String, dynamic>> channelData = [
    {'name': 'Visit', 'value': 73, 'color': Colors.blue},
    {'name': 'Call', 'value': 103, 'color': Colors.green},
    {'name': 'Message', 'value': 46, 'color': Colors.orange},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contactability Metrics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Summary of channels, visit status in chart',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 20),
          // Summary Cards
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _buildSummaryCard('Total Visits', '73', Colors.blue),
              _buildSummaryCard('Total Calls', '103', Colors.green),
              _buildSummaryCard('Total Messages', '46', Colors.orange),
            ],
          ),
          SizedBox(height: 20),
          // Weekly Activity Chart
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Activity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        barGroups: weeklyData.map((data) => BarChartGroupData(
                          x: weeklyData.indexOf(data),
                          barRods: [
                            BarChartRodData(toY: data['visits'].toDouble(), color: Colors.blue, width: 7),
                            BarChartRodData(toY: data['calls'].toDouble(), color: Colors.green, width: 7),
                            BarChartRodData(toY: data['messages'].toDouble(), color: Colors.orange, width: 7),
                          ],
                        )).toList(),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text(weeklyData[value.toInt()]['day'], style: TextStyle(fontSize: 10));
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          // Channel Distribution
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Channel Distribution',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: channelData.map((data) => PieChartSectionData(
                          color: data['color'],
                          value: data['value'].toDouble(),
                          title: '${data['value']}',
                          radius: 50,
                          titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        )).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: channelData.map((data) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            color: data['color'],
                          ),
                          SizedBox(width: 5),
                          Text('${data['name']} (${data['value']})'),
                        ],
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            SizedBox(height: 5),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}

