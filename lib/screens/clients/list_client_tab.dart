import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../../core/controllers/client_controller.dart';
import '../../core/models/client.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/app_utils.dart' as AppUtils;
import '../../widgets/common_widgets.dart';
import '../contactability_form_screen.dart';
import 'client_details_screen.dart';

/// ListClientTab - Halaman utama untuk menampilkan daftar client
///
/// Halaman ini sangat penting karena:
/// 1. Menampilkan list client dari API response
/// 2. Dari API response, kita mendapatkan Client ID dan Skor User ID
/// 3. Berguna untuk mapping Client ID ke attribut client lain seperti nama dan nomor telepon
/// 4. Data ini dapat digunakan di banyak tempat dalam aplikasi untuk keperluan mapping
class ListClientTab extends StatefulWidget {
  const ListClientTab({Key? key}) : super(key: key);

  @override
  State<ListClientTab> createState() => _ListClientTabState();
}

class _ListClientTabState extends State<ListClientTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer;

  // Filter and sort state
  String? _selectedCity;
  String? _sortBy;
  bool _sortAscending = true;
  bool _isFilterExpanded = false; // Add this for hide/unhide functionality

  // Helper method to check if current user is from Skorcard team
  bool _isSkorCardUser() {
    final authService = context.read<AuthService>();
    final userTeam = authService.userData?['team'] as String?;
    final isSkorcard = userTeam != null && userTeam.toLowerCase() == 'skorcard';
    debugPrint(
        '🏢 User team: "$userTeam" - Sort options available: ${isSkorcard ? 'Full (including MAD/TAD/BuyBack)' : 'Limited (no MAD/TAD/BuyBack)'}');
    return isSkorcard;
  }

  // Get available sort options based on user team
  List<Map<String, String>> get _sortOptions {
    List<Map<String, String>> options = [
      {'key': 'Total_OS_Yesterday1', 'label': 'Total OS'},
      {'key': 'Last_Payment_Amount', 'label': 'Last Payment Amount'},
      {'key': 'Last_Payment_Date', 'label': 'Last Payment Date'},
    ];

    // Add Skorcard-specific options only for Skorcard team members
    if (_isSkorCardUser()) {
      options.addAll([
        {'key': 'Last_Statement_MAD', 'label': 'MAD'},
        {'key': 'Last_Statement_TAD', 'label': 'TAD'},
        {'key': 'Buy_Back_Status', 'label': 'BuyBack Status'},
      ]);
    }

    return options;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientController>().initialize();
      _validateSortOption();
    });
  }

  // Validate if current sort option is available for user's team
  void _validateSortOption() {
    if (_sortBy != null &&
        !_sortOptions.any((option) => option['key'] == _sortBy)) {
      setState(() {
        _sortBy = null;
        _sortAscending = true;
      });
    }
  }

  void _showCacheDebugInfo() async {
    final controller = context.read<ClientController>();
    final cacheInfo = await controller.getCacheInfo();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cache Debug Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Cached Date: ${cacheInfo['cachedDate'] ?? 'None'}'),
              Text('Today Date: ${cacheInfo['todayDate']}'),
              Text('Is Valid: ${cacheInfo['isValid']}'),
              Text('Client Count: ${cacheInfo['clientCount']}'),
              Text('Has Data: ${cacheInfo['hasData']}'),
              if (cacheInfo['error'] != null)
                Text('Error: ${cacheInfo['error']}',
                    style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await controller.clearCache();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared!')),
              );
            },
            child: const Text('Clear Cache'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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

  /// Get distinct cities from all client data
  List<String> _getDistinctCities(List<Client> clients) {
    final Set<String> cities = {};

    for (final client in clients) {
      final caCity = client.rawApiData?['CA_City']?.toString();
      if (caCity != null &&
          caCity.isNotEmpty &&
          caCity.toLowerCase() != 'null' &&
          caCity.toLowerCase() != 'na') {
        cities.add(caCity.trim());
      }
    }

    final sortedCities = cities.toList()..sort();
    return sortedCities;
  }

  /// Apply filtering and sorting to client list
  List<Client> _getFilteredAndSortedClients(List<Client> clients) {
    List<Client> filtered = clients;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((client) {
        final nameMatch = client.name.toLowerCase().contains(_searchQuery);
        final phoneMatch = client.phone.contains(_searchQuery);
        final cleanPhoneMatch =
            _formatPhoneClean(client.phone).contains(_searchQuery);
        return nameMatch || phoneMatch || cleanPhoneMatch;
      }).toList();
    }

    // Apply city filter
    if (_selectedCity != null && _selectedCity!.isNotEmpty) {
      filtered = filtered.where((client) {
        final caCity = client.rawApiData?['CA_City']?.toString();
        return caCity != null && caCity.trim() == _selectedCity;
      }).toList();
    }

    // Apply sorting
    if (_sortBy != null && _sortBy!.isNotEmpty) {
      filtered.sort((a, b) {
        final aValue = a.rawApiData?[_sortBy!];
        final bValue = b.rawApiData?[_sortBy!];

        // Handle null values
        if (aValue == null && bValue == null) return 0;
        if (aValue == null) return _sortAscending ? 1 : -1;
        if (bValue == null) return _sortAscending ? -1 : 1;

        int comparison;

        // Special handling for date fields
        if (_sortBy == 'Last_Payment_Date') {
          try {
            final aDate = DateTime.tryParse(aValue.toString());
            final bDate = DateTime.tryParse(bValue.toString());

            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return _sortAscending ? 1 : -1;
            if (bDate == null) return _sortAscending ? -1 : 1;

            comparison = aDate.compareTo(bDate);
          } catch (e) {
            comparison = aValue.toString().compareTo(bValue.toString());
          }
        } else if (_sortBy == 'Buy_Back_Status') {
          // Special handling for Buy_Back_Status - string comparison
          comparison = aValue.toString().compareTo(bValue.toString());
        } else {
          // Numeric fields
          try {
            final aNum = double.tryParse(
                aValue.toString().replaceAll(RegExp(r'[^\d.-]'), ''));
            final bNum = double.tryParse(
                bValue.toString().replaceAll(RegExp(r'[^\d.-]'), ''));

            if (aNum == null && bNum == null) return 0;
            if (aNum == null) return _sortAscending ? 1 : -1;
            if (bNum == null) return _sortAscending ? -1 : 1;

            comparison = aNum.compareTo(bNum);
          } catch (e) {
            comparison = aValue.toString().compareTo(bValue.toString());
          }
        }

        return _sortAscending ? comparison : -comparison;
      });
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ClientController>(
      builder: (context, clientController, child) {
        return Column(
          children: [
            // Loading bar for cache operations
            if (clientController.loadingState == ClientLoadingState.caching)
              Container(
                height: 3,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                ),
              ),

            // Main content
            Expanded(
              child: RefreshIndicator(
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
                      const SizedBox(height: 16),
                      _buildFilterAndSortControls(clientController),
                      const SizedBox(height: 20),
                      _buildMainContent(clientController),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
            GestureDetector(
              onLongPress: _showCacheDebugInfo,
              child: const Text(
                'Today\'s Client List',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
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
            const SizedBox(height: 8),
            // Cache status indicator
            FutureBuilder<bool>(
              future: controller.isDataFromCache(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data == true) {
                  return Row(
                    children: [
                      Icon(
                        Icons.cached,
                        size: 14,
                        color: Colors.green[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Data loaded from cache (today)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  );
                } else if (snapshot.hasData && snapshot.data == false) {
                  return Row(
                    children: [
                      Icon(
                        Icons.cloud_download,
                        size: 14,
                        color: Colors.blue[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Fresh data from server',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
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
            color: Colors.grey.withValues(alpha: 0.1),
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

  Widget _buildFilterAndSortControls(ClientController controller) {
    final allClients = controller.todaysClients;
    final distinctCities = _getDistinctCities(allClients);

    // Check if any filters are active
    final hasActiveFilters = _selectedCity != null || _sortBy != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with toggle button
          InkWell(
            onTap: () {
              setState(() {
                _isFilterExpanded = !_isFilterExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.filter_list, size: 20, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filter & Sort',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        // Show active filters summary when collapsed
                        if (!_isFilterExpanded && hasActiveFilters) ...[
                          const SizedBox(height: 2),
                          Text(
                            _getFilterSummary(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Active filter indicator
                  if (hasActiveFilters)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _getActiveFilterCount().toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isFilterExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isFilterExpanded ? null : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isFilterExpanded ? 1.0 : 0.0,
              child: _isFilterExpanded
                  ? Container(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: [
                          const Divider(height: 1),
                          const SizedBox(height: 16),

                          // City Filter
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Filter by City',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _selectedCity,
                                          hint: const Text('All Cities'),
                                          isExpanded: true,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          items: [
                                            const DropdownMenuItem<String>(
                                              value: null,
                                              child: Text('All Cities'),
                                            ),
                                            ...distinctCities.map((city) =>
                                                DropdownMenuItem<String>(
                                                  value: city,
                                                  child: Text(city),
                                                )),
                                          ],
                                          onChanged: (String? value) {
                                            setState(() {
                                              _selectedCity = value;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Sort Controls
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sort by',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.grey[300]!),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                value: _sortBy,
                                                hint: const Text('None'),
                                                isExpanded: true,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12),
                                                items: [
                                                  const DropdownMenuItem<
                                                      String>(
                                                    value: null,
                                                    child: Text('None'),
                                                  ),
                                                  ..._sortOptions.map(
                                                      (option) =>
                                                          DropdownMenuItem<
                                                              String>(
                                                            value:
                                                                option['key'],
                                                            child: Text(option[
                                                                'label']!),
                                                          )),
                                                ],
                                                onChanged: (String? value) {
                                                  setState(() {
                                                    _sortBy = value;
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Sort order toggle
                                        if (_sortBy != null)
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _sortAscending =
                                                    !_sortAscending;
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.blue[50],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                    color: Colors.blue[200]!),
                                              ),
                                              child: Icon(
                                                _sortAscending
                                                    ? Icons.arrow_upward
                                                    : Icons.arrow_downward,
                                                size: 20,
                                                color: Colors.blue[700],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Clear filters button
                          if (hasActiveFilters) ...[
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _selectedCity = null;
                                    _sortBy = null;
                                    _sortAscending = true;
                                  });
                                },
                                icon: const Icon(Icons.clear, size: 18),
                                label: const Text('Clear Filters'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  /// Get summary of active filters for collapsed view
  String _getFilterSummary() {
    List<String> filters = [];

    if (_selectedCity != null) {
      filters.add('City: $_selectedCity');
    }
    if (_sortBy != null) {
      final sortOption =
          _sortOptions.where((option) => option['key'] == _sortBy).firstOrNull;
      if (sortOption != null) {
        filters
            .add('Sort: ${sortOption['label']} ${_sortAscending ? '↑' : '↓'}');
      }
    }

    return filters.join(' • ');
  }

  /// Get count of active filters
  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedCity != null) count++;
    if (_sortBy != null) count++;
    return count;
  }

  Widget _buildMainContent(ClientController controller) {
    switch (controller.loadingState) {
      case ClientLoadingState.initial:
      case ClientLoadingState.loading:
        return const LoadingWidget(message: 'Loading today\'s clients...');

      case ClientLoadingState.caching:
        return Column(
          children: [
            const LoadingWidget(
                message: 'Processing client data and creating mappings...'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.cached, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Creating client ID mappings for location features...',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case ClientLoadingState.error:
        return AppErrorWidget(
          message: controller.errorMessage ?? 'An error occurred',
          onRetry: () => controller.refresh(),
        );

      case ClientLoadingState.loaded:
        final allClients = controller.todaysClients;
        final filteredClients = _getFilteredAndSortedClients(allClients);

        if (allClients.isEmpty) {
          return _buildEmptyState();
        }

        if (filteredClients.isEmpty &&
            (_searchQuery.isNotEmpty || _selectedCity != null)) {
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

  Widget _buildResultsHeader(int filteredCount, int totalCount) {
    List<String> filterInfo = [];

    if (_searchQuery.isNotEmpty) {
      filterInfo.add('search: "$_searchQuery"');
    }
    if (_selectedCity != null) {
      filterInfo.add('city: "$_selectedCity"');
    }
    if (_sortBy != null) {
      final sortOption =
          _sortOptions.where((option) => option['key'] == _sortBy).firstOrNull;
      if (sortOption != null) {
        filterInfo.add(
            'sorted by: ${sortOption['label']} ${_sortAscending ? '↑' : '↓'}');
      }
    }

    if (filterInfo.isEmpty) {
      return Text(
        'Showing $totalCount clients',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              children: [
                const TextSpan(text: 'Found '),
                TextSpan(
                  text: '$filteredCount',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                TextSpan(text: ' of $totalCount clients'),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Filters: ${filterInfo.join(', ')}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildNoSearchResultsState() {
    List<String> activeFilters = [];

    if (_searchQuery.isNotEmpty) {
      activeFilters.add('search term');
    }
    if (_selectedCity != null) {
      activeFilters.add('city filter');
    }

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
            'Try adjusting your ${activeFilters.join(' or ')}',
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
              setState(() {
                _searchQuery = '';
                _selectedCity = null;
                _sortBy = null;
                _sortAscending = true;
              });
            },
            icon: const Icon(Icons.clear),
            label: const Text('Clear All Filters'),
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
                .withValues(alpha: 0.2),
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

    // Ensure base style has black color
    final baseStyle =
        (style ?? const TextStyle()).copyWith(color: Colors.black);

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: text.substring(0, startIndex)),
          TextSpan(
            text: text.substring(startIndex, endIndex),
            style: baseStyle.copyWith(
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
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _copyToClipboard(client.address, 'Address'),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.copy,
                  size: 16,
                  color: Colors.blueGrey[600],
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _openGoogleMaps(client.address),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.map,
                  size: 16,
                  color: Colors.blue[600],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Icon(Icons.phone, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 5),
            Expanded(
              child: _buildHighlightedText(
                _formatPhoneClean(client.phone),
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ),
            const SizedBox(width: 8),
            // WhatsApp icon
            GestureDetector(
              onTap: () => _openWhatsApp(client.phone),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.chat,
                  size: 16,
                  color: Colors.green[600],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Call icon
            GestureDetector(
              onTap: () => _makePhoneCall(client.phone),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.call,
                  size: 16,
                  color: Colors.blue[600],
                ),
              ),
            ),
          ],
        ),

        // Show sorted field value if sorting is active
        if (_sortBy != null && client.rawApiData?[_sortBy!] != null) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(Icons.sort, size: 16, color: Colors.blue[600]),
              const SizedBox(width: 5),
              Builder(builder: (context) {
                final sortOption = _sortOptions
                    .where((option) => option['key'] == _sortBy)
                    .firstOrNull;
                return Text(
                  '${sortOption?['label'] ?? 'Sort'}: ',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w500),
                );
              }),
              Expanded(
                child: Text(
                  _formatSortValue(client.rawApiData![_sortBy!], _sortBy!),
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],

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

  /// Format sort value for display
  String _formatSortValue(dynamic value, String sortBy) {
    if (value == null) return 'N/A';

    // Format currency fields
    if ([
      'Last_Statement_MAD',
      'Last_Statement_TAD',
      'Total_OS_Yesterday1',
      'Last_Payment_Amount'
    ].contains(sortBy)) {
      try {
        final numValue =
            double.tryParse(value.toString().replaceAll(RegExp(r'[^\d.]'), ''));
        if (numValue != null) {
          return 'Rp ${numValue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
        }
      } catch (e) {
        // Fall through to default formatting
      }
    }

    // Format date field
    if (sortBy == 'Last_Payment_Date') {
      try {
        final date = DateTime.tryParse(value.toString());
        if (date != null) {
          return '${date.day}/${date.month}/${date.year}';
        }
      } catch (e) {
        // Fall through to default formatting
      }
    }

    // Format Buy_Back_Status field
    if (sortBy == 'Buy_Back_Status') {
      return value.toString().toUpperCase();
    }

    return value.toString();
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

  void _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label copied to clipboard'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openGoogleMaps(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final url =
        'https://www.google.com/maps/search/?api=1&query=$encodedAddress';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open Google Maps'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening Google Maps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openWhatsApp(String phone) async {
    // Format phone for WhatsApp (remove leading 0, add 62)
    String formattedPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '62${formattedPhone.substring(1)}';
    } else if (!formattedPhone.startsWith('62')) {
      formattedPhone = '62$formattedPhone';
    }

    final url = 'https://wa.me/$formattedPhone';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open WhatsApp'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening WhatsApp: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _makePhoneCall(String phone) async {
    final url = 'tel:$phone';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not make phone call'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making phone call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
