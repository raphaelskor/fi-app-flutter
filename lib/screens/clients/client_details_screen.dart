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
      contactRows
          .add(_iconDetailRow(Icons.phone, 'Mobile', clientData!['Mobile']));
    if (_hasValue(clientData?['Home_Phone']))
      contactRows.add(
          _iconDetailRow(Icons.home, 'Home Phone', clientData!['Home_Phone']));
    if (_hasValue(clientData?['Office_Phone']))
      contactRows.add(_iconDetailRow(
          Icons.business, 'Office Phone', clientData!['Office_Phone']));
    if (_hasValue(clientData?['Any_other_phone_No']))
      contactRows.add(_iconDetailRow(Icons.phone_android, 'Other Phone',
          clientData!['Any_other_phone_No']));
    if (_hasValue(clientData?['Email']))
      contactRows
          .add(_iconDetailRow(Icons.email, 'Email', clientData!['Email']));

    // Emergency contacts
    if (_hasValue(clientData?['EC1_Name']))
      contactRows.add(_iconDetailRow(
          Icons.contact_phone, 'Emergency Contact 1', clientData!['EC1_Name']));
    if (_hasValue(clientData?['EC1_Phone']))
      contactRows.add(
          _iconDetailRow(Icons.phone, 'EC1 Phone', clientData!['EC1_Phone']));
    if (_hasValue(clientData?['EC1_Relation']))
      contactRows.add(_iconDetailRow(
          Icons.people, 'EC1 Relation', clientData!['EC1_Relation']));
    if (_hasValue(clientData?['EC2_Name']))
      contactRows.add(_iconDetailRow(
          Icons.contact_phone, 'Emergency Contact 2', clientData!['EC2_Name']));
    if (_hasValue(clientData?['EC2_Phone']))
      contactRows.add(
          _iconDetailRow(Icons.phone, 'EC2 Phone', clientData!['EC2_Phone']));
    if (_hasValue(clientData?['EC2_Relation']))
      contactRows.add(_iconDetailRow(
          Icons.people, 'EC2 Relation', clientData!['EC2_Relation']));
    if (_hasValue(clientData?['Emegency_Contact_Name']))
      contactRows.add(_iconDetailRow(Icons.phone, 'Emergency Contact',
          clientData!['Emegency_Contact_Name']));

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
                if (_hasValue(clientData?['Date_of_Birth']))
                  _iconDetailRow(Icons.cake, 'Date of Birth',
                      clientData!['Date_of_Birth']),
                if (_hasValue(clientData?['Place_of_Birth']))
                  _iconDetailRow(Icons.location_city, 'Place of Birth',
                      clientData!['Place_of_Birth']),
                if (_hasValue(clientData?['Gender']))
                  _iconDetailRow(Icons.person, 'Gender', clientData!['Gender']),
                if (_hasValue(clientData?['Marital_Status']))
                  _iconDetailRow(Icons.favorite, 'Marital Status',
                      clientData!['Marital_Status']),
                if (_hasValue(clientData?['Spouse_Name']))
                  _iconDetailRow(Icons.person_outline, 'Spouse Name',
                      clientData!['Spouse_Name']),
                if (_hasValue(clientData?['Mother_Name']))
                  _iconDetailRow(
                      Icons.woman, 'Mother Name', clientData!['Mother_Name']),
                if (_hasValue(clientData?['Religion']))
                  _iconDetailRow(
                      Icons.place, 'Religion', clientData!['Religion']),
                if (_hasValue(clientData?['Nationality']))
                  _iconDetailRow(
                      Icons.flag, 'Nationality', clientData!['Nationality']),
                if (_hasValue(clientData?['NIK']))
                  _iconDetailRow(Icons.credit_card, 'NIK', clientData!['NIK']),
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
                  _iconDetailRow(
                      Icons.home, 'Address Line 1', clientData!['CA_Line_1']),
                if (_hasValue(clientData?['CA_Line_2']))
                  _iconDetailRow(
                      Icons.home, 'Address Line 2', clientData!['CA_Line_2']),
                if (_hasValue(clientData?['CA_City']))
                  _iconDetailRow(
                      Icons.location_city, 'City', clientData!['CA_City']),
                if (_hasValue(clientData?['CA_District']))
                  _iconDetailRow(
                      Icons.map, 'District', clientData!['CA_District']),
                if (_hasValue(clientData?['CA_Sub_District']))
                  _iconDetailRow(Icons.place, 'Sub District',
                      clientData!['CA_Sub_District']),
                if (_hasValue(clientData?['CA_Province']))
                  _iconDetailRow(Icons.map_outlined, 'Province',
                      clientData!['CA_Province']),
                if (_hasValue(clientData?['CA_ZipCode']))
                  _iconDetailRow(Icons.markunread_mailbox, 'Zip Code',
                      clientData!['CA_ZipCode']),
                if (_hasValue(clientData?['CA_RT_RW']))
                  _iconDetailRow(
                      Icons.home_outlined, 'RT/RW', clientData!['CA_RT_RW']),

                // KTP Address
                if (_hasValue(clientData?['KTP_Address']))
                  _iconDetailRow(Icons.credit_card, 'KTP Address',
                      clientData!['KTP_Address']),
                if (_hasValue(clientData?['KTP_City']))
                  _iconDetailRow(
                      Icons.location_city, 'KTP City', clientData!['KTP_City']),
                if (_hasValue(clientData?['KTP_District']))
                  _iconDetailRow(
                      Icons.map, 'KTP District', clientData!['KTP_District']),
                if (_hasValue(clientData?['KTP_Village']))
                  _iconDetailRow(
                      Icons.place, 'KTP Village', clientData!['KTP_Village']),
                if (_hasValue(clientData?['KTP_Province']))
                  _iconDetailRow(Icons.map_outlined, 'KTP Province',
                      clientData!['KTP_Province']),
                if (_hasValue(clientData?['KTP_Postal_Code']))
                  _iconDetailRow(Icons.markunread_mailbox, 'KTP Postal Code',
                      clientData!['KTP_Postal_Code']),
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
                if (_hasValue(clientData?['User_ID']))
                  _iconDetailRow(
                      Icons.account_circle, 'User ID', clientData!['User_ID']),
                if (_hasValue(clientData?['Income_IDR']))
                  _iconDetailRow(Icons.attach_money, 'Income (IDR)',
                      _formatCurrency(clientData!['Income_IDR'])),
                if (_hasValue(clientData?['Credit_Limit']))
                  _iconDetailRow(Icons.credit_card, 'Credit Limit',
                      _formatCurrency(clientData!['Credit_Limit'])),
                if (_hasValue(clientData?['Current_Outstanding_Balance']))
                  _iconDetailRow(
                      Icons.account_balance,
                      'Outstanding Balance',
                      _formatCurrency(
                          clientData!['Current_Outstanding_Balance'])),
                if (_hasValue(clientData?['Last_Payment_Amount']))
                  _iconDetailRow(Icons.payment, 'Last Payment',
                      _formatCurrency(clientData!['Last_Payment_Amount'])),
                if (_hasValue(clientData?['Last_Payment_Date']))
                  _iconDetailRow(Icons.date_range, 'Last Payment Date',
                      clientData!['Last_Payment_Date']),
                if (_hasValue(clientData?['Days_Past_Due']))
                  _iconDetailRow(Icons.warning, 'Days Past Due',
                      '${clientData!['Days_Past_Due']} days'),
                if (_hasValue(clientData?['DPD_Bucket']))
                  _iconDetailRow(
                      Icons.category, 'DPD Bucket', clientData!['DPD_Bucket']),
                if (_hasValue(clientData?['Age_in_Bank']))
                  _iconDetailRow(Icons.schedule, 'Age in Bank',
                      '${clientData!['Age_in_Bank']} days'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    final Map<String, dynamic>? clientData = _getClientApiData();

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
                  _iconDetailRow(Icons.work, 'Job', clientData!['Job_Details']),
                if (_hasValue(clientData?['Position_Details']))
                  _iconDetailRow(
                      Icons.badge, 'Position', clientData!['Position_Details']),
                if (_hasValue(clientData?['Company_Name']))
                  _iconDetailRow(
                      Icons.business, 'Company', clientData!['Company_Name']),
                if (_hasValue(clientData?['Length_of_Work']))
                  _iconDetailRow(Icons.schedule, 'Work Length',
                      clientData!['Length_of_Work']),
                if (_hasValue(clientData?['Education_Details']))
                  _iconDetailRow(Icons.school, 'Education',
                      clientData!['Education_Details']),
                _iconDetailRow(
                    Icons.calendar_today,
                    'Created',
                    AppUtils.DateUtils.formatDisplayDate(
                        widget.client.createdAt)),
                _iconDetailRow(
                    Icons.update,
                    'Updated',
                    AppUtils.DateUtils.formatDisplayDate(
                        widget.client.updatedAt)),
                if (widget.client.notes != null &&
                    widget.client.notes!.isNotEmpty)
                  _iconDetailRow(Icons.note, 'Notes', widget.client.notes!),
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

  String _formatCurrency(dynamic value) {
    if (value == null) return 'N/A';
    final String valueStr = value.toString();
    if (valueStr.isEmpty || valueStr.toLowerCase() == 'null') return 'N/A';

    try {
      final num amount = num.parse(valueStr);
      return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}';
    } catch (e) {
      return valueStr;
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
