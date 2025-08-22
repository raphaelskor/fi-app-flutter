import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/controllers/dashboard_controller.dart';

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
                  const Text(
                    'Today\'s Performance',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.5,
                    children: [
                      _buildMetricCard(
                          'Visit', controller.performanceData['visit']!),
                      _buildMetricCard(
                          'RPC', controller.performanceData['rpc']!),
                      _buildMetricCard(
                          'TPC', controller.performanceData['tpc']!),
                      _buildMetricCard(
                          'PTP', controller.performanceData['ptp']!),
                      _buildMetricCard('KP', controller.performanceData['kp']!),
                      _buildMetricCard('BP', controller.performanceData['bp']!),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Performance Ratios',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildRatioRow(
                    'RPC/Visit Ratio',
                    controller.calculateRatio(
                        controller.performanceData['rpc']!,
                        controller.performanceData['visit']!),
                  ),
                  _buildRatioRow(
                    'PTP/Visit Ratio',
                    controller.calculateRatio(
                        controller.performanceData['ptp']!,
                        controller.performanceData['visit']!),
                  ),
                  _buildRatioRow(
                    'KP/PTP Ratio',
                    controller.calculateRatio(controller.performanceData['kp']!,
                        controller.performanceData['ptp']!),
                  ),
                  _buildRatioRow(
                    'BP/PTP Ratio',
                    controller.calculateRatio(controller.performanceData['bp']!,
                        controller.performanceData['ptp']!),
                  ),
                ],
              ),
            ),
          );
        },
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
