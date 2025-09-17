import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/controllers/dashboard_controller.dart';
import '../locations/all_client_location_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<DashboardController>();
      controller.loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              context.read<DashboardController>().refresh();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: Consumer<DashboardController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (controller.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading dashboard data',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.errorMessage!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      controller.clearError();
                      controller.refresh();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Communication Channels Pie Chart
                  const Text(
                    'Communication Channels',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildCommunicationPieChart(controller),

                  const SizedBox(height: 30),

                  // Contact Results Bar Chart
                  const Text(
                    'Contact Results',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildContactResultsBarChart(controller),

                  const SizedBox(height: 30),

                  // PTP Performance
                  const Text(
                    'PTP Performance',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard('PTP All Time',
                            controller.performanceData['ptp_all_time'] ?? 0),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricCard('PTP This Month',
                            controller.performanceData['ptp_this_month'] ?? 0),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Performance Ratios
                  const Text(
                    'Performance Ratios',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildRatioRow(
                    'PTP/Visit Ratio',
                    controller.calculateRatio(
                        controller.performanceData['ptp_all_time'] ?? 0,
                        controller.performanceData['visit'] ?? 0),
                  ),
                  _buildRatioRow(
                    'RPC/Visit Ratio',
                    controller.calculateRatio(
                        controller.performanceData['rpc'] ?? 0,
                        controller.performanceData['visit'] ?? 0),
                  ),
                  _buildRatioRow(
                    'TPC/Visit Ratio',
                    controller.calculateRatio(
                        controller.performanceData['tpc'] ?? 0,
                        controller.performanceData['visit'] ?? 0),
                  ),
                  _buildRatioRow(
                    'OPC/Visit Ratio',
                    controller.calculateRatio(
                        controller.performanceData['opc'] ?? 0,
                        controller.performanceData['visit'] ?? 0),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AllClientLocationScreen(),
            ),
          );
        },
        backgroundColor: const Color.fromARGB(255, 129, 129, 129),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.map),
        label: const Text('Client Locations'),
        tooltip: 'View All Client Locations',
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
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent),
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

  Widget _buildCommunicationPieChart(DashboardController controller) {
    final visitCount = controller.performanceData['visit'] ?? 0;
    final callCount = controller.performanceData['call'] ?? 0;
    final messageCount = controller.performanceData['message'] ?? 0;

    final total = visitCount + callCount + messageCount;

    if (total == 0) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'No communication data available',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
        ),
      );
    }

    final channelData = [
      {'name': 'Visit', 'value': visitCount, 'color': Colors.blue},
      {'name': 'Call', 'value': callCount, 'color': Colors.green},
      {'name': 'Message', 'value': messageCount, 'color': Colors.orange},
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: channelData
                      .map((data) => PieChartSectionData(
                            color: data['color'] as Color,
                            value: (data['value'] as int).toDouble(),
                            title: '${data['value']}',
                            radius: 50,
                            titleStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ))
                      .toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              children: channelData
                  .map((data) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              color: data['color'] as Color,
                            ),
                            const SizedBox(width: 5),
                            Text('${data['name']} (${data['value']})'),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactResultsBarChart(DashboardController controller) {
    final rpcCount = controller.performanceData['rpc'] ?? 0;
    final tpcCount = controller.performanceData['tpc'] ?? 0;
    final opcCount = controller.performanceData['opc'] ?? 0;

    final maxValue = [rpcCount, tpcCount, opcCount]
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: maxValue > 0 ? maxValue + (maxValue * 0.1) : 10,
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: rpcCount.toDouble(),
                          color: Colors.blue,
                          width: 40,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: tpcCount.toDouble(),
                          color: Colors.green,
                          width: 40,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: opcCount.toDouble(),
                          color: Colors.orange,
                          width: 40,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return const Text('RPC',
                                  style: TextStyle(fontSize: 12));
                            case 1:
                              return const Text('TPC',
                                  style: TextStyle(fontSize: 12));
                            case 2:
                              return const Text('OPC',
                                  style: TextStyle(fontSize: 12));
                            default:
                              return const Text('');
                          }
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxValue > 10 ? (maxValue / 5) : 2,
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBarLegendItem('RPC', rpcCount, Colors.blue),
                _buildBarLegendItem('TPC', tpcCount, Colors.green),
                _buildBarLegendItem('OPC', opcCount, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarLegendItem(String label, int value, Color color) {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        Text(
          value.toString(),
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
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
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[700]),
          ),
        ],
      ),
    );
  }
}
