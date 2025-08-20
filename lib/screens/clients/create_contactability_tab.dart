import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientController>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _filterClients(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Set up new timer for debouncing
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query.toLowerCase();
      });
    });
  }

  /// Format phone number for clean display: +62877662142182 -> 0877662142182
  String _formatPhoneClean(String phone) {
    // Remove all non-digit characters
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Handle +62 prefix - replace with 0
    if (cleaned.startsWith('62')) {
      cleaned = '0${cleaned.substring(2)}';
    }
    // Handle if it starts with 8 (missing country code)
    else if (cleaned.startsWith('8')) {
      cleaned = '0$cleaned';
    }
    // If it already starts with 0, keep as is
    else if (!cleaned.startsWith('0')) {
      // For any other format, try to clean and add 0
      cleaned = '0$cleaned';
    }

    return cleaned;
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
                const SizedBox(height: 16),
                _buildSearchBar(),
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
    return Consumer<ClientController>(
      builder: (context, controller, child) {
        final totalCount = controller.todaysClients.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Client List',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Text(
                  'Optimized by distance',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                if (totalCount > 0) ...[
                  Text(
                    ' • ',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalCount clients',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name or phone number...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _searchQuery.isNotEmpty
                ? Icon(Icons.search,
                    color: Colors.blue[600], key: const ValueKey('searching'))
                : Icon(Icons.search,
                    color: Colors.grey[500], key: const ValueKey('idle')),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: IconButton(
                    key: const ValueKey('clear'),
                    icon: Icon(Icons.clear, color: Colors.grey[500]),
                    onPressed: () {
                      _searchController.clear();
                      _filterClients('');
                    },
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        onChanged: _filterClients,
      ),
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
        final allClients = controller.todaysClients;
        final filteredClients = _getFilteredClients(allClients);

        if (allClients.isEmpty) {
          return _buildEmptyState();
        }

        if (filteredClients.isEmpty && _searchQuery.isNotEmpty) {
          return _buildNoSearchResultsState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultsHeader(filteredClients.length, allClients.length),
            const SizedBox(height: 16),
            _buildClientList(filteredClients),
          ],
        );
    }
  }

  List<Client> _getFilteredClients(List<Client> clients) {
    if (_searchQuery.isEmpty) {
      return clients;
    }

    return clients.where((client) {
      final nameMatch = client.name.toLowerCase().contains(_searchQuery);
      final phoneMatch = client.phone.contains(_searchQuery);
      final cleanPhoneMatch =
          _formatPhoneClean(client.phone).contains(_searchQuery);
      return nameMatch || phoneMatch || cleanPhoneMatch;
    }).toList();
  }

  Widget _buildResultsHeader(int filteredCount, int totalCount) {
    if (_searchQuery.isEmpty) {
      return Text(
        'Showing $totalCount clients',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      );
    } else {
      return RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          children: [
            TextSpan(
              text: 'Found ',
            ),
            TextSpan(
              text: '$filteredCount',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            TextSpan(
              text: ' of $totalCount clients',
            ),
          ],
        ),
      );
    }
  }

  Widget _buildNoSearchResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No clients found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with a different name or phone number',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              _filterClients('');
            },
            icon: const Icon(Icons.clear),
            label: const Text('Clear Search'),
          ),
        ],
      ),
    );
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
          child: _buildHighlightedText(
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

  Widget _buildHighlightedText(String text, {TextStyle? style}) {
    if (_searchQuery.isEmpty) {
      return Text(text, style: style);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = _searchQuery.toLowerCase();

    if (!lowerText.contains(lowerQuery)) {
      return Text(text, style: style);
    }

    final startIndex = lowerText.indexOf(lowerQuery);
    final endIndex = startIndex + lowerQuery.length;

    return RichText(
      text: TextSpan(
        style: style ?? const TextStyle(color: Colors.black),
        children: [
          TextSpan(text: text.substring(0, startIndex)),
          TextSpan(
            text: text.substring(startIndex, endIndex),
            style: (style ?? const TextStyle(color: Colors.black)).copyWith(
              backgroundColor: Colors.yellow[200],
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: text.substring(endIndex)),
        ],
      ),
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
            _buildHighlightedText(
              _formatPhoneClean(client.phone),
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
