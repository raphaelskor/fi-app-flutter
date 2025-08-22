import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/controllers/agent_history_controller.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../contactability/contactability_details_screen.dart';

class HistoryListTab extends StatefulWidget {
  const HistoryListTab({Key? key}) : super(key: key);

  @override
  State<HistoryListTab> createState() => _HistoryListTabState();
}

class _HistoryListTabState extends State<HistoryListTab> {
  late AgentHistoryController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Get AuthService from context and create controller
      final authService = context.read<AuthService>();
      _controller = AgentHistoryController(ApiService(), authService);
      _controller.loadHistory();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when near bottom
      _controller.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<AgentHistoryController>(
        builder: (context, controller, child) {
          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My History (All-Time)',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'All contactability made by you',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  if (controller.isLoading && controller.historyItems.isEmpty)
                    _buildLoadingWidget()
                  else if (controller.loadingState ==
                          AgentHistoryLoadingState.error &&
                      controller.historyItems.isEmpty)
                    _buildErrorWidget(controller)
                  else if (controller.historyItems.isEmpty)
                    _buildEmptyWidget()
                  else
                    _buildHistoryList(controller),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorWidget(AgentHistoryController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              controller.errorMessage ?? 'An error occurred',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => controller.refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No history found',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Your contactability history will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(AgentHistoryController controller) {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.historyItems.length,
          itemBuilder: (context, index) {
            final item = controller.historyItems[index];
            return _buildHistoryCard(item);
          },
        ),

        // Load more indicator
        if (controller.isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          ),

        // End of data indicator
        if (!controller.hasMoreRecords && controller.historyItems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'End of history',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryCard(AgentHistoryItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => _navigateToContactabilityDetails(item),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.clientName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(item.contactResult),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                '${item.channel} • ${_controller.formatDateTime(item.createdTime)}',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              if (item.notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  item.notes,
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
              ],

              // Show additional info for visits
              if (item.channel.toLowerCase().contains('visit')) ...[
                if (item.visitLocation != null ||
                    item.visitAction != null ||
                    item.visitStatus != null) ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  if (item.visitLocation != null)
                    _buildInfoRow('Location', item.visitLocation!),
                  if (item.visitAction != null)
                    _buildInfoRow('Action', item.visitAction!),
                  if (item.visitStatus != null)
                    _buildInfoRow('Status', item.visitStatus!),
                ],
              ],

              // Show PTP info if available
              if (item.ptpAmount != null || item.ptpDate != null) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.payment, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    const Text(
                      'PTP: ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                    if (item.ptpAmount != null) Text('R ${item.ptpAmount}'),
                    if (item.ptpAmount != null && item.ptpDate != null)
                      const Text(' • '),
                    if (item.ptpDate != null) Text(item.ptpDate!),
                  ],
                ),
              ],

              // Show navigation hint
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'yes':
      case 'success':
      case 'completed':
      case 'replied':
      case 'connected':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case 'no':
      case 'no answer':
      case 'busy':
      case 'failed':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToContactabilityDetails(AgentHistoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactabilityDetailsScreen(
          contactability: item.toContactabilityHistory(),
        ),
      ),
    );
  }
}
