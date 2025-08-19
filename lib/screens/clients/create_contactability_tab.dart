import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/controllers/client_controller.dart';
import '../../core/models/client.dart';
import '../../core/utils/app_utils.dart' as AppUtils;
import '../../widgets/common_widgets.dart';
import '../contactability_form_screen.dart';
import 'client_details_screen.dart';

class CreateContactabilityTab extends StatefulWidget {
  @override
  State<CreateContactabilityTab> createState() =>
      _CreateContactabilityTabState();
}

class _CreateContactabilityTabState extends State<CreateContactabilityTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientController>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ClientController>(
      builder: (context, clientController, child) {
        return RefreshIndicator(
          onRefresh: () => clientController.refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildContent(clientController),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s Client List',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          'Optimized by distance',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildContent(ClientController controller) {
    switch (controller.loadingState) {
      case ClientLoadingState.initial:
      case ClientLoadingState.loading:
        return const LoadingWidget(message: 'Loading today\'s clients...');

      case ClientLoadingState.error:
        return AppErrorWidget(
          message: controller.errorMessage ?? 'An error occurred',
          onRetry: () => controller.refresh(),
        );

      case ClientLoadingState.loaded:
        final clients = controller.todaysClients;
        if (clients.isEmpty) {
          return _buildEmptyState();
        }
        return _buildClientList(clients);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No clients for today',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later or refresh to see updates',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientList(List<Client> clients) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: clients.length,
      itemBuilder: (context, index) {
        final client = clients[index];
        return _buildClientCard(client);
      },
    );
  }

  Widget _buildClientCard(Client client) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClientDetailsScreen(client: client),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 15),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildClientHeader(client),
              const SizedBox(height: 10),
              _buildClientInfo(client),
              const SizedBox(height: 15),
              _buildActionButtons(client),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientHeader(Client client) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            client.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Color(AppUtils.ColorUtils.getStatusColor(client.status))
                .withOpacity(0.2),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            AppUtils.StringUtils.capitalizeFirst(client.status),
            style: TextStyle(
              fontSize: 12,
              color: Color(AppUtils.ColorUtils.getStatusColor(client.status)),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClientInfo(Client client) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                client.address,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Icon(Icons.phone, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 5),
            Text(
              AppUtils.StringUtils.formatPhone(client.phone),
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
        if (client.distance != null) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(Icons.near_me, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 5),
              Text(
                AppUtils.DistanceUtils.formatDistance(client.distance!),
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(Client client) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(
          icon: Icons.call,
          label: 'Call',
          onPressed: () => _navigateToContactabilityForm(client, 'Call'),
        ),
        _buildActionButton(
          icon: Icons.message,
          label: 'Message',
          onPressed: () => _navigateToContactabilityForm(client, 'Message'),
        ),
        _buildActionButton(
          icon: Icons.location_on,
          label: 'Visit',
          onPressed: () => _navigateToContactabilityForm(client, 'Visit'),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  void _navigateToContactabilityForm(Client client, String channel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactabilityFormScreen(
          client: client,
          channel: channel,
        ),
      ),
    );
  }
}
