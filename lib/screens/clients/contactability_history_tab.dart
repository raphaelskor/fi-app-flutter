import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/controllers/client_contactability_history_controller.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../widgets/common_widgets.dart';
import '../contactability/contactability_details_screen.dart';

class ContactabilityHistoryTab extends StatefulWidget {
  @override
  State<ContactabilityHistoryTab> createState() =>
      _ContactabilityHistoryTabState();
}

class _ContactabilityHistoryTabState extends State<ContactabilityHistoryTab> {
  ClientContactabilityHistoryController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeController();
    });
  }

  void _initializeController() async {
    try {
      // Get AuthService from context and create controller
      final authService = context.read<AuthService>();
      _controller =
          ClientContactabilityHistoryController(ApiService(), authService);

      setState(() {
        _isInitialized = true;
      });

      // Load history after controller is set
      await _controller?.loadHistory();
    } catch (e) {
      print('Error initializing ContactabilityHistoryTab: $e');
      setState(() {
        _isInitialized = true; // Still set as initialized even on error
      });
    }
  }

  @override
  void dispose() {
    // _controller.dispose(); // No dispose method in this controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_isInitialized) {
      return const LoadingWidget(message: 'Initializing...');
    }
    return ChangeNotifierProvider.value(
      value: _controller!,
      child: Consumer<ClientContactabilityHistoryController>(
        builder: (context, controller, child) {
          return _buildContent(controller);
        },
      ),
    );
  }

  Widget _buildContent(ClientContactabilityHistoryController controller) {
    switch (controller.loadingState) {
      case ClientContactabilityHistoryLoadingState.initial:
      case ClientContactabilityHistoryLoadingState.loading:
        return const LoadingWidget(
            message: 'Loading contactability history...');

      case ClientContactabilityHistoryLoadingState.error:
        return AppErrorWidget(
          message: controller.errorMessage ?? 'Failed to load history',
          onRetry: () => controller.refresh(),
        );

      case ClientContactabilityHistoryLoadingState.loaded:
        final history = controller.historyItems;
        if (history.isEmpty) {
          return _buildEmptyState();
        }
        return _buildHistoryList(history, controller);

      case ClientContactabilityHistoryLoadingState.refreshing:
        final history = controller.historyItems;
        if (history.isEmpty) {
          return const LoadingWidget(message: 'Loading...');
        }
        return _buildHistoryList(history, controller);
    }
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: () => _controller?.refresh() ?? Future.value(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No contactability history available yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start contacting clients to see history here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Pull down to refresh',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<ClientContactabilityHistoryItem> history,
      ClientContactabilityHistoryController controller) {
    return RefreshIndicator(
      onRefresh: () => controller.refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contactability History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'All prior conversations/calls with clients',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return _buildHistoryCard(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(ClientContactabilityHistoryItem item) {
    return Card(
      margin: EdgeInsets.only(bottom: 15),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.clientName,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(_getChannelIconFromString(item.channel),
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              item.channel,
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(item.contactResult),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _controller?.formatDateTime(item.createdTime) ?? 'Unknown date',
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
                    if (item.ptpAmount != null) Text('Rp${item.ptpAmount}'),
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

  void _navigateToContactabilityDetails(ClientContactabilityHistoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactabilityDetailsScreen(
          contactability: item.toContactabilityHistory(),
        ),
      ),
    );
  }

  IconData _getChannelIconFromString(String channel) {
    switch (channel.toLowerCase()) {
      case 'field visit':
        return Icons.location_on;
      case 'whatsapp':
        return Icons.message;
      case 'call':
        return Icons.call;
      case 'sms':
        return Icons.sms;
      case 'email':
        return Icons.email;
      default:
        return Icons.contact_phone;
    }
  }
}
