import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/controllers/contactability_controller.dart';
import '../../core/models/contactability_history.dart';
import '../../core/utils/app_utils.dart' as AppUtils;
import '../../widgets/common_widgets.dart';

class ContactabilityHistoryTab extends StatefulWidget {
  @override
  State<ContactabilityHistoryTab> createState() =>
      _ContactabilityHistoryTabState();
}

class _ContactabilityHistoryTabState extends State<ContactabilityHistoryTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        // Initialize with empty client ID to get all history
        context
            .read<ContactabilityController>()
            .initialize('all', skorUserId: null);
      } catch (e) {
        print('Error initializing ContactabilityHistoryTab: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContactabilityController>(
      builder: (context, controller, child) {
        return RefreshIndicator(
          onRefresh: () => controller.refresh(),
          child: _buildContent(controller),
        );
      },
    );
  }

  Widget _buildContent(ContactabilityController controller) {
    switch (controller.loadingState) {
      case ContactabilityLoadingState.initial:
      case ContactabilityLoadingState.loading:
        return const LoadingWidget(
            message: 'Loading contactability history...');

      case ContactabilityLoadingState.error:
        return AppErrorWidget(
          message: controller.errorMessage ?? 'Failed to load history',
          onRetry: () => controller.refresh(),
        );

      case ContactabilityLoadingState.loaded:
      case ContactabilityLoadingState.submitted:
        final history = controller.contactabilityHistory;
        if (history.isEmpty) {
          return _buildEmptyState();
        }
        return _buildHistoryList(history, controller);

      case ContactabilityLoadingState.submitting:
        return const LoadingWidget(message: 'Loading...');
    }
  }

  Widget _buildEmptyState() {
    return Center(
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
            'No contactability history yet',
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
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<ContactabilityHistory> history,
      ContactabilityController controller) {
    return SingleChildScrollView(
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
              final contactability = history[index];
              return _buildHistoryCard(contactability);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(ContactabilityHistory contactability) {
    return Card(
      margin: EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User ID: ${contactability.skorUserId}',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(_getChannelIconFromString(contactability.channel),
                            size: 16),
                        const SizedBox(width: 4),
                        Text(
                          contactability.channelDisplayName,
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getResultColorFromString(contactability.result)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    contactability.resultDisplayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getResultColorFromString(contactability.result),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppUtils.DateUtils.formatDisplayDateTime(
                  contactability.contactedAt),
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 10),
            Text(
              contactability.notes ?? 'No notes',
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
          ],
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

  Color _getResultColorFromString(String? result) {
    if (result == null) return Colors.grey;

    switch (result.toLowerCase()) {
      case 'delivered':
      case 'contacted':
      case 'ptp':
        return Colors.green;
      case 'visited':
      case 'read':
        return Colors.blue;
      case 'sent':
      case 'not contacted':
        return Colors.orange;
      case 'not available':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
