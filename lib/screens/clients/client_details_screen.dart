import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/controllers/contactability_controller.dart';
import '../../core/models/client.dart';
import '../../core/models/contactability_history.dart';
import '../../core/utils/app_utils.dart' as AppUtils;
import '../../widgets/common_widgets.dart';
import '../contactability_form_screen.dart';
import '../contactability/contactability_details_screen.dart';

class ClientDetailsScreen extends StatefulWidget {
  final Client client;

  const ClientDetailsScreen({Key? key, required this.client}) : super(key: key);

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        // Get Skor User ID from client's raw API data with safety checks
        final String? skorUserId = widget.client.skorUserId;
        debugPrint(
            '🔍 Client raw data keys: ${widget.client.rawApiData?.keys.toList()}');
        debugPrint(
            '🔍 Client user_ID: ${widget.client.rawApiData?['user_ID']}');
        debugPrint(
            '🔍 Client User_ID: ${widget.client.rawApiData?['User_ID']}');
        debugPrint(
            '🔍 Client Skor_User_ID: ${widget.client.rawApiData?['Skor_User_ID']}');
        debugPrint('🔍 Final skorUserId: $skorUserId');

        context.read<ContactabilityController>().initialize(
              widget.client.id,
              skorUserId: skorUserId,
            );
      } catch (e) {
        debugPrint('Error initializing ContactabilityController: $e');
        // Initialize with empty skorUserId if there's an error
        context.read<ContactabilityController>().initialize(
              widget.client.id,
              skorUserId: null,
            );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ClientDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the client has changed, reinitialize the controller
    if (oldWidget.client.id != widget.client.id) {
      debugPrint(
          '🔄 Client changed from ${oldWidget.client.id} to ${widget.client.id}, reinitializing...');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          // Clear previous data first
          context.read<ContactabilityController>().clearData();

          // Get Skor User ID from new client's raw API data
          final String? skorUserId = widget.client.skorUserId;
          debugPrint('🔍 New client skorUserId: $skorUserId');

          context.read<ContactabilityController>().initialize(
                widget.client.id,
                skorUserId: skorUserId,
              );
        } catch (e) {
          debugPrint('Error reinitializing ContactabilityController: $e');
          // Initialize with empty skorUserId if there's an error
          context.read<ContactabilityController>().initialize(
                widget.client.id,
                skorUserId: null,
              );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.client.name),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Client Details'),
            Tab(text: 'Contactability History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildClientDetailsTab(),
          _buildContactabilityHistoryTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showContactabilityOptions(context),
        icon: const Icon(Icons.add),
        label: const Text('Contact'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildClientDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Client Header Card
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.blue[100],
                    child:
                        const Icon(Icons.person, size: 36, color: Colors.blue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.client.name,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppUtils.StringUtils.formatPhone(widget.client.phone),
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(AppUtils.ColorUtils.getStatusColor(
                                    widget.client.status))
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            AppUtils.StringUtils.capitalizeFirst(
                                widget.client.status),
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(AppUtils.ColorUtils.getStatusColor(
                                  widget.client.status)),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Basic Information
          const Text('Basic Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  _iconDetailRow(Icons.badge, 'Client ID', widget.client.id),
                  _iconDetailRow(Icons.person, 'Full Name', widget.client.name),
                  _iconDetailRow(Icons.phone, 'Mobile',
                      AppUtils.StringUtils.formatPhone(widget.client.phone)),
                  if (widget.client.email != null &&
                      widget.client.email!.isNotEmpty)
                    _iconDetailRow(Icons.email, 'Email', widget.client.email!),
                  _iconDetailRow(Icons.home, 'Address', widget.client.address),
                  if (widget.client.distance != null)
                    _iconDetailRow(
                        Icons.near_me,
                        'Distance',
                        AppUtils.DistanceUtils.formatDistance(
                            widget.client.distance!)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Contact & Emergency Information
          _buildContactSection(),
          const SizedBox(height: 16),

          // Personal Information
          _buildPersonalSection(),
          const SizedBox(height: 16),

          // Address Information
          _buildAddressSection(),
          const SizedBox(height: 16),

          // Financial Information
          _buildFinancialSection(),
          const SizedBox(height: 16),

          // Status & Dates
          _buildStatusSection(),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    // Get additional fields from the original API data if available
    final Map<String, dynamic>? clientData = _getClientApiData();

    List<Widget> contactRows = [];

    // Basic contact info
    if (_hasValue(clientData?['Mobile']))
      contactRows.add(_iconDetailRow(
          Icons.phone, 'Mobile', _safeStringValue(clientData!['Mobile'])));
    if (_hasValue(clientData?['Home_Phone']))
      contactRows.add(_iconDetailRow(Icons.home, 'Home Phone',
          _safeStringValue(clientData!['Home_Phone'])));
    if (_hasValue(clientData?['Office_Phone']))
      contactRows.add(_iconDetailRow(Icons.business, 'Office Phone',
          _safeStringValue(clientData!['Office_Phone'])));
    if (_hasValue(clientData?['Any_other_phone_No']))
      contactRows.add(_iconDetailRow(Icons.phone_android, 'Other Phone',
          _safeStringValue(clientData!['Any_other_phone_No'])));
    if (_hasValue(clientData?['Email']))
      contactRows.add(_iconDetailRow(
          Icons.email, 'Email', _safeStringValue(clientData!['Email'])));

    // Emergency contacts
    if (_hasValue(clientData?['EC1_Name']))
      contactRows.add(_iconDetailRow(Icons.contact_phone, 'Emergency Contact 1',
          _safeStringValue(clientData!['EC1_Name'])));
    if (_hasValue(clientData?['EC1_Phone']))
      contactRows.add(_iconDetailRow(Icons.phone, 'EC1 Phone',
          _safeStringValue(clientData!['EC1_Phone'])));
    if (_hasValue(clientData?['EC1_Relation']))
      contactRows.add(_iconDetailRow(Icons.people, 'EC1 Relation',
          _safeStringValue(clientData!['EC1_Relation'])));
    if (_hasValue(clientData?['EC2_Name']))
      contactRows.add(_iconDetailRow(Icons.contact_phone, 'Emergency Contact 2',
          _safeStringValue(clientData!['EC2_Name'])));
    if (_hasValue(clientData?['EC2_Phone']))
      contactRows.add(_iconDetailRow(Icons.phone, 'EC2 Phone',
          _safeStringValue(clientData!['EC2_Phone'])));
    if (_hasValue(clientData?['EC2_Relation']))
      contactRows.add(_iconDetailRow(Icons.people, 'EC2 Relation',
          _safeStringValue(clientData!['EC2_Relation'])));
    if (_hasValue(clientData?['Emegency_Contact_Name']))
      contactRows.add(_iconDetailRow(Icons.phone, 'Emergency Contact',
          _safeStringValue(clientData!['Emegency_Contact_Name'])));

    // If no contact data from API, show basic info
    if (contactRows.isEmpty) {
      contactRows = [
        _iconDetailRow(Icons.phone, 'Mobile',
            AppUtils.StringUtils.formatPhone(widget.client.phone)),
        if (widget.client.email != null && widget.client.email!.isNotEmpty)
          _iconDetailRow(Icons.email, 'Email', widget.client.email!),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Contact Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: contactRows,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalSection() {
    final Map<String, dynamic>? clientData = _getClientApiData();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Personal Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                if (_hasValue(clientData?['Gender']))
                  _iconDetailRow(Icons.person, 'Gender',
                      _safeStringValue(clientData!['Gender'])),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    final Map<String, dynamic>? clientData = _getClientApiData();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Address Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // Current Address
                if (_hasValue(clientData?['CA_Line_1']))
                  _iconDetailRow(Icons.home, 'Address Line 1',
                      _safeStringValue(clientData!['CA_Line_1'])),
                if (_hasValue(clientData?['CA_Line_2']))
                  _iconDetailRow(Icons.home, 'Address Line 2',
                      _safeStringValue(clientData!['CA_Line_2'])),
                if (_hasValue(clientData?['CA_City']))
                  _iconDetailRow(Icons.location_city, 'City',
                      _safeStringValue(clientData!['CA_City'])),
                if (_hasValue(clientData?['CA_District']))
                  _iconDetailRow(Icons.map, 'District',
                      _safeStringValue(clientData!['CA_District'])),
                if (_hasValue(clientData?['CA_Sub_District']))
                  _iconDetailRow(Icons.place, 'Sub District',
                      _safeStringValue(clientData!['CA_Sub_District'])),
                if (_hasValue(clientData?['CA_Province']))
                  _iconDetailRow(Icons.map_outlined, 'Province',
                      _safeStringValue(clientData!['CA_Province'])),
                if (_hasValue(clientData?['CA_ZipCode']))
                  _iconDetailRow(Icons.markunread_mailbox, 'Zip Code',
                      _safeStringValue(clientData!['CA_ZipCode'])),
                if (_hasValue(clientData?['CA_RT_RW']))
                  _iconDetailRow(Icons.home_outlined, 'RT/RW',
                      _safeStringValue(clientData!['CA_RT_RW'])),

                // KTP Address
                if (_hasValue(clientData?['KTP_Address']))
                  _iconDetailRow(Icons.credit_card, 'KTP Address',
                      _safeStringValue(clientData!['KTP_Address'])),
                if (_hasValue(clientData?['KTP_City']))
                  _iconDetailRow(Icons.location_city, 'KTP City',
                      _safeStringValue(clientData!['KTP_City'])),
                if (_hasValue(clientData?['KTP_District']))
                  _iconDetailRow(Icons.map, 'KTP District',
                      _safeStringValue(clientData!['KTP_District'])),
                if (_hasValue(clientData?['KTP_Village']))
                  _iconDetailRow(Icons.place, 'KTP Village',
                      _safeStringValue(clientData!['KTP_Village'])),
                if (_hasValue(clientData?['KTP_Province']))
                  _iconDetailRow(Icons.map_outlined, 'KTP Province',
                      _safeStringValue(clientData!['KTP_Province'])),
                if (_hasValue(clientData?['KTP_Postal_Code']))
                  _iconDetailRow(Icons.markunread_mailbox, 'KTP Postal Code',
                      _safeStringValue(clientData!['KTP_Postal_Code'])),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialSection() {
    final Map<String, dynamic>? clientData = _getClientApiData();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Financial Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // Loan Amounts
                if (_hasValue(clientData?['Last_Statement_MAD']))
                  _iconDetailRow(Icons.attach_money, 'Last Statement MAD',
                      _formatCurrency(clientData!['Last_Statement_MAD'])),
                if (_hasValue(clientData?['Last_Statement_TAD']))
                  _iconDetailRow(
                      Icons.account_balance_wallet,
                      'Last Statement TAD',
                      _formatCurrency(clientData!['Last_Statement_TAD'])),

                // Payment Information
                if (_hasValue(clientData?['Last_Payment_Amount']))
                  _iconDetailRow(Icons.payment, 'Last Payment Amount',
                      _formatCurrency(clientData!['Last_Payment_Amount'])),
                if (_hasValue(clientData?['Last_Payment_Date']))
                  _iconDetailRow(Icons.event, 'Last Payment Date',
                      _formatDate(clientData!['Last_Payment_Date'])),
                if (_hasValue(clientData?['Rep_Status_Current_Bill']))
                  _iconDetailRow(Icons.category, 'Bill Status',
                      _safeStringValue(clientData!['Rep_Status_Current_Bill'])),
                if (_hasValue(clientData?['Repayment_Amount']))
                  _iconDetailRow(Icons.event, 'Repayment Amount',
                      _formatCurrency(clientData!['Repayment_Amount'])),

                // DPD Information
                if (_hasValue(clientData?['Days_Past_Due']))
                  _iconDetailRow(Icons.warning, 'DPD',
                      '${_safeStringValue(clientData!['Days_Past_Due'])} days'),
                if (_hasValue(clientData?['DPD_Bucket']))
                  _iconDetailRow(Icons.category, 'DPD Bucket',
                      _safeStringValue(clientData!['DPD_Bucket'])),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    final Map<String, dynamic>? clientData = _getClientApiData();

    // Compose possible office address from common keys if available
    String? officeAddress;
    if (_hasValue(clientData?['Company_Address'])) {
      officeAddress = clientData!['Company_Address'].toString();
    } else if (_hasValue(clientData?['Office_Address'])) {
      officeAddress = clientData!['Office_Address'].toString();
    } else {
      // Try to build from separate office address lines if provided
      final parts = <String>[];
      if (_hasValue(clientData?['Office_Address_Line_1'])) {
        parts.add(clientData!['Office_Address_Line_1'].toString());
      }
      if (_hasValue(clientData?['Office_Address_Line_2'])) {
        parts.add(clientData!['Office_Address_Line_2'].toString());
      }
      if (_hasValue(clientData?['Office_City'])) {
        parts.add(clientData!['Office_City'].toString());
      }
      if (_hasValue(clientData?['Office_District'])) {
        parts.add(clientData!['Office_District'].toString());
      }
      if (_hasValue(clientData?['Office_Sub_District'])) {
        parts.add(clientData!['Office_Sub_District'].toString());
      }
      if (_hasValue(clientData?['Office_Province'])) {
        parts.add(clientData!['Office_Province'].toString());
      }
      if (_hasValue(clientData?['Office_ZipCode'])) {
        parts.add(clientData!['Office_ZipCode'].toString());
      }
      if (parts.isNotEmpty) {
        officeAddress = parts.join(', ');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Status & Employment',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                _iconDetailRow(Icons.info, 'Status',
                    AppUtils.StringUtils.capitalizeFirst(widget.client.status)),
                if (_hasValue(clientData?['Job_Details']))
                  _iconDetailRow(Icons.work, 'Job',
                      _safeStringValue(clientData!['Job_Details'])),
                if (_hasValue(clientData?['Position_Details']))
                  _iconDetailRow(Icons.badge, 'Position',
                      _safeStringValue(clientData!['Position_Details'])),
                if (_hasValue(clientData?['Company_Name']))
                  _iconDetailRow(Icons.business, 'Company',
                      _safeStringValue(clientData!['Company_Name'])),
                if (officeAddress != null && officeAddress.trim().isNotEmpty)
                  _iconDetailRow(
                      Icons.location_city, 'Office Address', officeAddress),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to get original API data (you might need to store this in Client model)
  Map<String, dynamic>? _getClientApiData() {
    // Return the raw API data stored in the client model
    return widget.client.rawApiData;
  }

  bool _hasValue(dynamic value) {
    if (value == null) return false;
    if (value is String &&
        (value.isEmpty ||
            value.toLowerCase() == 'null' ||
            value.toLowerCase() == 'na')) return false;
    if (value is bool && !value) return false;
    return true;
  }

  // Helper method to safely convert any value to string
  String _safeStringValue(dynamic value) {
    if (value == null) return 'N/A';
    if (value is String) return value;
    if (value is num) return value.toString();
    return value.toString();
  }

  // Helper method to format currency values in Indonesian Rupiah
  String _formatCurrency(dynamic value) {
    if (value == null) return 'N/A';

    // Convert to string and remove any existing formatting
    String valueStr = value.toString().replaceAll(RegExp(r'[^\d.]'), '');

    // Try to parse as double
    double? amount = double.tryParse(valueStr);
    if (amount == null) return value.toString();

    // Format with Indonesian Rupiah style
    final formatter = amount.toStringAsFixed(0);
    final parts = <String>[];

    // Add thousands separators
    for (int i = formatter.length; i > 0; i -= 3) {
      int start = i - 3 < 0 ? 0 : i - 3;
      parts.insert(0, formatter.substring(start, i));
    }

    return 'Rp ${parts.join('.')}';
  }

  // Helper method to format date from YYYY-MM-DD to Indonesian format
  String _formatDate(dynamic value) {
    if (value == null) return 'N/A';

    String dateStr = value.toString().trim();
    if (dateStr.isEmpty || dateStr.toLowerCase() == 'null') return 'N/A';

    try {
      // Parse the date assuming YYYY-MM-DD format
      final parts = dateStr.split('-');
      if (parts.length != 3)
        return dateStr; // Return original if not in expected format

      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      // Indonesian month names
      const monthNames = [
        '',
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember'
      ];

      if (month < 1 || month > 12) return dateStr;

      return '$day ${monthNames[month]} $year';
    } catch (e) {
      return dateStr; // Return original string if parsing fails
    }
  }

  Widget _buildContactabilityHistoryTab() {
    return Consumer<ContactabilityController>(
      builder: (context, controller, child) {
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
              return _buildEmptyHistoryState();
            }
            return _buildHistoryList(history, controller);

          case ContactabilityLoadingState.submitting:
            return const LoadingWidget(message: 'Submitting...');
        }
      },
    );
  }

  Widget _buildEmptyHistoryState() {
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
            'No contact history yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by contacting this client',
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
    return RefreshIndicator(
      onRefresh: () => controller.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final contactability = history[index];
          return _buildHistoryCard(contactability);
        },
      ),
    );
  }

  Widget _buildHistoryCard(ContactabilityHistory contactability) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _navigateToContactabilityDetails(contactability),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(_getChannelIcon(contactability.channel), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        contactability.channelDisplayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getResultColor(contactability.resultDisplayName)
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      contactability.resultDisplayName,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            _getResultColor(contactability.resultDisplayName),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(contactability.notes ?? 'No notes'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppUtils.DateUtils.formatDisplayDateTime(
                        contactability.contactedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
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

  Widget _iconDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showContactabilityOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Contact Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildContactOption(
                    Icons.call, 'Call', () => _navigateToForm('Call')),
                _buildContactOption(
                    Icons.message, 'Message', () => _navigateToForm('Message')),
                _buildContactOption(
                    Icons.location_on, 'Visit', () => _navigateToForm('Visit')),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 32, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _navigateToForm(String channel) {
    Navigator.pop(context); // Close bottom sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactabilityFormScreen(
          client: widget.client,
          channel: channel,
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Refresh contactability history
        context.read<ContactabilityController>().refresh();
      }
    });
  }

  void _navigateToContactabilityDetails(ContactabilityHistory contactability) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactabilityDetailsScreen(
          contactability: contactability,
        ),
      ),
    );
  }

  IconData _getChannelIcon(String channel) {
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
      case 'message':
        return Icons.message;
      case 'visit':
        return Icons.location_on;
      default:
        return Icons.contact_phone;
    }
  }

  Color _getResultColor(String result) {
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
