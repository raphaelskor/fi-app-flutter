import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/controllers/client_contactability_history_controller.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/timezone_utils.dart';
import '../../widgets/common_widgets.dart';
import '../contactability/contactability_details_screen.dart';

class ContactabilityHistoryTab extends StatefulWidget {
  const ContactabilityHistoryTab({Key? key}) : super(key: key);

  @override
  State<ContactabilityHistoryTab> createState() =>
      _ContactabilityHistoryTabState();
}

class _ContactabilityHistoryTabState extends State<ContactabilityHistoryTab> {
  ClientContactabilityHistoryController? _controller;
  bool _isInitialized = false;

  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedContactResult;
  bool _showFilters = false;

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
      debugPrint('Error initializing ContactabilityHistoryTab: $e');
      setState(() {
        _isInitialized = true; // Still set as initialized even on error
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
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
        final history = _filterHistoryItems(controller.historyItems);
        if (history.isEmpty && controller.historyItems.isNotEmpty) {
          return _buildNoResultsState();
        } else if (history.isEmpty) {
          return _buildEmptyState();
        }
        return _buildHistoryList(history, controller);

      case ClientContactabilityHistoryLoadingState.refreshing:
        final history = _filterHistoryItems(controller.historyItems);
        if (history.isEmpty && controller.historyItems.isNotEmpty) {
          return _buildNoResultsState();
        } else if (history.isEmpty) {
          return const LoadingWidget(message: 'Loading...');
        }
        return _buildHistoryList(history, controller);
    }
  }

  // Filter history items based on search query, date range, and contact result
  List<ClientContactabilityHistoryItem> _filterHistoryItems(
      List<ClientContactabilityHistoryItem> items) {
    return items.where((item) {
      // Search filter
      bool matchesSearch = _searchQuery.isEmpty ||
          item.clientName.toLowerCase().contains(_searchQuery.toLowerCase());

      // Date filter
      bool matchesDateRange = true;
      if (_startDate != null || _endDate != null) {
        final itemDate = DateTime(
          item.createdTime.year,
          item.createdTime.month,
          item.createdTime.day,
        );

        if (_startDate != null) {
          final startDate = DateTime(
            _startDate!.year,
            _startDate!.month,
            _startDate!.day,
          );
          matchesDateRange = matchesDateRange && !itemDate.isBefore(startDate);
        }

        if (_endDate != null) {
          final endDate = DateTime(
            _endDate!.year,
            _endDate!.month,
            _endDate!.day,
          );
          matchesDateRange = matchesDateRange && !itemDate.isAfter(endDate);
        }
      }

      // Contact result filter
      bool matchesContactResult = _selectedContactResult == null ||
          item.contactResult.toLowerCase() ==
              _selectedContactResult!.toLowerCase();

      return matchesSearch && matchesDateRange && matchesContactResult;
    }).toList();
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: () => _controller?.refresh() ?? Future.value(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
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

  Widget _buildNoResultsState() {
    return RefreshIndicator(
      onRefresh: () => _controller?.refresh() ?? Future.value(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
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
                  'No results found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your search or date filters',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                      _startDate = null;
                      _endDate = null;
                      _selectedContactResult = null;
                    });
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear Filters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[50],
                    foregroundColor: Colors.blue[700],
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
            const Text(
              'Contactability History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'All prior conversations/calls with clients',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),

            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by client name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),

            const SizedBox(height: 12),

            // Filter button and active filters display
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                  icon: Icon(
                    _showFilters ? Icons.filter_list_off : Icons.filter_list,
                    size: 20,
                  ),
                  label: const Text('Filters'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: (_startDate != null ||
                            _endDate != null ||
                            _selectedContactResult != null)
                        ? Colors.blue[50]
                        : null,
                    foregroundColor: (_startDate != null ||
                            _endDate != null ||
                            _selectedContactResult != null)
                        ? Colors.blue[700]
                        : null,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${history.length} contactability',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Date filter section
            if (_showFilters) ...[
              const SizedBox(height: 12),
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter by Date Range',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectStartDate(),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Start Date',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  _startDate != null
                                      ? TimezoneUtils.formatIndonesianDate(
                                          _startDate!)
                                      : 'Select start date',
                                  style: TextStyle(
                                    color: _startDate != null
                                        ? Colors.black87
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectEndDate(),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'End Date',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  _endDate != null
                                      ? TimezoneUtils.formatIndonesianDate(
                                          _endDate!)
                                      : 'Select end date',
                                  style: TextStyle(
                                    color: _endDate != null
                                        ? Colors.black87
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Contact Result Filter
                      const Text(
                        'Filter by Contact Result',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: DropdownButtonFormField<String>(
                          value: _selectedContactResult,
                          decoration: const InputDecoration(
                            labelText: 'Contact Result',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.check_circle_outline),
                          ),
                          hint: const Text('Select contact result'),
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text('All Results'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Alamat Ditemukan, Rumah Kosong',
                              child: Text('Alamat Ditemukan, Rumah Kosong'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Dilarang Masuk Perumahan',
                              child: Text('Dilarang Masuk Perumahan'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Dilarang Masuk Kantor',
                              child: Text('Dilarang Masuk Kantor'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Menghindar',
                              child: Text('Menghindar'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Titip Surat',
                              child: Text('Titip Surat'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Alamat Tidak Ditemukan',
                              child: Text('Alamat Tidak Ditemukan'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Alamat Salah',
                              child: Text('Alamat Salah'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Konsumen Tidak Dikenal',
                              child: Text('Konsumen Tidak Dikenal'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Pindah, Tidak Ditemukan',
                              child: Text('Pindah, Tidak Ditemukan'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Pindah, Alamat Baru',
                              child: Text('Pindah, Alamat Baru'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Meninggal Dunia',
                              child: Text('Meninggal Dunia'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Mengundurkan Diri',
                              child: Text('Mengundurkan Diri'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Berhenti Bekerja',
                              child: Text('Berhenti Bekerja'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Sedang Renovasi',
                              child: Text('Sedang Renovasi'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Bencana Alam',
                              child: Text('Bencana Alam'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Kondisi Medis',
                              child: Text('Kondisi Medis'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Sengketa Hukum',
                              child: Text('Sengketa Hukum'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Kunjungan Ulang',
                              child: Text('Kunjungan Ulang'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Promise to Pay (PTP)',
                              child: Text('Promise to Pay (PTP)'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Negotiation',
                              child: Text('Negotiation'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Hot Prospect',
                              child: Text('Hot Prospect'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Already Paid',
                              child: Text('Already Paid'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Refuse to Pay',
                              child: Text('Refuse to Pay'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Dispute',
                              child: Text('Dispute'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Not Recognized',
                              child: Text('Not Recognized'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Partial Payment',
                              child: Text('Partial Payment'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Failed to Pay',
                              child: Text('Failed to Pay'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'WA One Tick',
                              child: Text('WA One Tick'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'WA Two Tick',
                              child: Text('WA Two Tick'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'WA Blue Tick',
                              child: Text('WA Blue Tick'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'WA Not Registered',
                              child: Text('WA Not Registered'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'SP 1',
                              child: Text('SP 1'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'SP 2',
                              child: Text('SP 2'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'SP 3',
                              child: Text('SP 3'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'No Respond',
                              child: Text('No Respond'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedContactResult = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (_startDate != null ||
                              _endDate != null ||
                              _selectedContactResult != null)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _startDate = null;
                                  _endDate = null;
                                  _selectedContactResult = null;
                                });
                              },
                              icon: const Icon(Icons.clear),
                              label: const Text('Clear All Filters'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.clientName,
                          style: const TextStyle(
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
                '${_formatAdjustedDate(item.createdTime)} • ${_formatAdjustedTime(item.createdTime)}',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),

              // Show notes if available
              if (item.notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.notes,
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[800]),
                        ),
                      ),
                    ],
                  ),
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

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? TimezoneUtils.todayInJakarta(),
      firstDate: DateTime(2020),
      lastDate: TimezoneUtils.todayInJakarta(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Ensure start date is not after end date
        if (_endDate != null && _startDate!.isAfter(_endDate!)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? TimezoneUtils.todayInJakarta(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: TimezoneUtils.todayInJakarta(),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        // Ensure end date is not before start date
        if (_startDate != null && _endDate!.isBefore(_startDate!)) {
          _startDate = _endDate;
        }
      });
    }
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

  // Helper method to format time with 7 hours subtraction
  String _formatAdjustedTime(DateTime dateTime) {
    final adjustedTime = dateTime.subtract(const Duration(hours: 7));
    return TimezoneUtils.formatTime(adjustedTime);
  }

  // Helper method to format date with 7 hours subtraction
  String _formatAdjustedDate(DateTime dateTime) {
    final adjustedDateTime = dateTime.subtract(const Duration(hours: 7));
    return TimezoneUtils.formatIndonesianDate(adjustedDateTime);
  }
}
