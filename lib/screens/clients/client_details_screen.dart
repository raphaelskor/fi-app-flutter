import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../../core/controllers/contactability_controller.dart';
import '../../core/models/client.dart';
import '../../core/models/contactability_history.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/photo_service.dart';
import '../../core/utils/app_utils.dart' as AppUtils;
import '../../core/utils/timezone_utils.dart';
import '../../widgets/common_widgets.dart';
import '../contactability_form_screen.dart';
import '../contactability/contactability_details_screen.dart';
import 'client_location_history_screen.dart';
import 'skip_tracing_screen.dart';

class ClientDetailsScreen extends StatefulWidget {
  final Client client;

  const ClientDetailsScreen({Key? key, required this.client}) : super(key: key);

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PhotoService _photoService = PhotoService();

  // Photo state management
  Map<String, String?> _photoPaths = {'ktp': null, 'selfie': null};
  bool _isLoadingPhotos = false;
  String? _photoError;

  // Filter state for contactability history
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedContactResult;
  bool _showFilters = false;

  // EMI Restructuring state
  Map<String, dynamic>? _emiRestructuringData;
  bool _isLoadingEmiData = false;
  bool _hasEmiData = false;

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

        // Enhanced debugging for photo loading
        if (skorUserId != null && skorUserId.isNotEmpty) {
          debugPrint('✅ skorUserId is available, will load photos');
        } else {
          debugPrint('❌ skorUserId is null or empty, photos will not load');
          debugPrint('🔍 Raw API data dump:');
          widget.client.rawApiData?.forEach((key, value) {
            if (key.toLowerCase().contains('user') ||
                key.toLowerCase().contains('id')) {
              debugPrint('   - $key: $value');
            }
          });
        }

        context.read<ContactabilityController>().initialize(
              widget.client.id,
              skorUserId: skorUserId,
            );

        // Load user photos if skorUserId is available
        if (skorUserId != null && skorUserId.isNotEmpty) {
          _loadUserPhotos(skorUserId);
        }

        // Load EMI Restructuring data
        _loadEmiRestructuringData();
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
    _searchController.dispose();
    super.dispose();
  }

  /// Loads EMI Restructuring data from the API
  Future<void> _loadEmiRestructuringData() async {
    setState(() {
      _isLoadingEmiData = true;
      _hasEmiData = false;
      _emiRestructuringData = null;
    });

    try {
      final response = await http.post(
        Uri.parse(
            'https://n8n.skorcard.app/webhook/6894fe90-b82f-48b8-bb16-8397a3b54c32'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id': widget.client.id,
        }),
      );

      debugPrint(
          '🔍 EMI Restructuring API response status: ${response.statusCode}');
      debugPrint('🔍 EMI Restructuring API response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        if (responseData.isNotEmpty &&
            responseData[0]['data'] != null &&
            responseData[0]['data'] is List &&
            responseData[0]['data'].isNotEmpty) {
          final emiData = responseData[0]['data'][0];

          setState(() {
            _emiRestructuringData = emiData;
            _hasEmiData = true;
            _isLoadingEmiData = false;
          });

          debugPrint('✅ EMI Restructuring data loaded successfully');
        } else {
          // No data available for this client
          setState(() {
            _hasEmiData = false;
            _isLoadingEmiData = false;
          });
          debugPrint('ℹ️ No EMI Restructuring data available for client');
        }
      } else {
        throw Exception(
            'API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error loading EMI Restructuring data: $e');
      setState(() {
        _hasEmiData = false;
        _isLoadingEmiData = false;
      });
      // Don't show error to user, just hide the section
    }
  }

  /// Loads user photos (KTP and Selfie) from the API
  Future<void> _loadUserPhotos(String skorUserId) async {
    print('🔍 _loadUserPhotos called with skorUserId: "$skorUserId"');

    setState(() {
      _isLoadingPhotos = true;
      _photoError = null;
    });

    try {
      // First check if photos exist locally
      print('🔍 Checking local photos for userId: $skorUserId');
      final localPaths = await _photoService.getLocalPhotoPaths(skorUserId);
      print('🔍 Local paths result: $localPaths');

      bool hasLocalPhotos =
          localPaths['ktp'] != null || localPaths['selfie'] != null;

      if (hasLocalPhotos) {
        // Use local photos
        print('✅ Using local photos');
        setState(() {
          _photoPaths = localPaths;
          _isLoadingPhotos = false;
        });
      } else {
        // Fetch from API
        print('🔍 No local photos found, fetching from API...');
        final fetchedPaths = await _photoService.fetchUserPhotos(skorUserId);
        print('✅ API fetch complete, result: $fetchedPaths');

        setState(() {
          _photoPaths = fetchedPaths;
          _isLoadingPhotos = false;
        });
      }
    } catch (e) {
      print('❌ Error in _loadUserPhotos: $e');
      setState(() {
        _photoError = e.toString();
        _isLoadingPhotos = false;
      });

      // Show error but don't block UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load photos: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
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

          // Load user photos if skorUserId is available
          if (skorUserId != null && skorUserId.isNotEmpty) {
            _loadUserPhotos(skorUserId);
          }

          // Load EMI Restructuring data
          _loadEmiRestructuringData();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_in_talk),
            tooltip: 'Skip Tracing',
            onPressed: () => _navigateToSkipTracing(),
          ),
          IconButton(
            icon: const Icon(Icons.location_history),
            tooltip: 'Location History',
            onPressed: () => _navigateToLocationHistory(),
          ),
        ],
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
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Contact',
          style: TextStyle(color: Colors.white),
        ),
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
                  _iconDetailRow(Icons.badge, 'Client ID', widget.client.id,
                      isCopyable: true),
                  if (widget.client.skorUserId != null)
                    _iconDetailRow(Icons.fingerprint, 'Skor User ID',
                        widget.client.skorUserId!,
                        isCopyable: true),
                  _iconDetailRow(Icons.person, 'Full Name', widget.client.name,
                      isCopyable: true),
                  _iconDetailRowWithActions(
                    Icons.phone,
                    'Mobile',
                    AppUtils.StringUtils.formatPhone(widget.client.phone),
                    phone: widget.client.phone,
                  ),
                  if (widget.client.email != null &&
                      widget.client.email!.isNotEmpty)
                    _iconDetailRow(Icons.email, 'Email', widget.client.email!),
                  _iconDetailRow(Icons.home, 'Address', widget.client.address,
                      isCopyable: true),
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

          // Photos Section (KTP and Selfie)
          if (widget.client.skorUserId != null &&
              widget.client.skorUserId!.isNotEmpty)
            _buildPhotosSection(),
          const SizedBox(height: 16),

          // Contact & Emergency Information
          _buildContactSection(),
          const SizedBox(height: 16),

          // Personal Information
          _buildPersonalSection(),
          const SizedBox(height: 16),

          // Correspondence Address (CA)
          _buildCorrespondenceAddressSection(),
          const SizedBox(height: 16),

          // KTP Address
          _buildKtpAddressSection(),
          const SizedBox(height: 16),

          // Residence Address (RA)
          _buildResidenceAddressSection(),
          const SizedBox(height: 16),

          // Financial Information
          _buildFinancialSection(),
          const SizedBox(height: 16),

          // EMI Restructuring Information (if available and user is Skorcard team)
          if (_hasEmiData && _isSkorCardUser()) _buildEmiRestructuringSection(),
          if (_hasEmiData && _isSkorCardUser()) const SizedBox(height: 16),

          // Status & Employment (with Office Address)
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
    // Skip Mobile field here since it's already shown in Basic Information
    if (_hasValue(clientData?['Home_Phone']))
      contactRows.add(_iconDetailRowWithActions(
        Icons.home,
        'Home Phone',
        _safeStringValue(clientData!['Home_Phone']),
        phone: _safeStringValue(clientData['Home_Phone']),
      ));
    if (_hasValue(clientData?['Office_Phone']))
      contactRows.add(_iconDetailRowWithActions(
        Icons.business,
        'Office Phone',
        _safeStringValue(clientData!['Office_Phone']),
        phone: _safeStringValue(clientData['Office_Phone']),
      ));
    if (_hasValue(clientData?['Any_other_phone_No']))
      contactRows.add(_iconDetailRowWithActions(
        Icons.phone_android,
        'Other Phone',
        _safeStringValue(clientData!['Any_other_phone_No']),
        phone: _safeStringValue(clientData['Any_other_phone_No']),
      ));
    if (_hasValue(clientData?['Email']))
      contactRows.add(_iconDetailRow(
          Icons.email, 'Email', _safeStringValue(clientData!['Email'])));

    // Emergency contacts
    if (_hasValue(clientData?['EC1_Name']))
      contactRows.add(_iconDetailRow(Icons.contact_phone, 'Emergency Contact 1',
          _safeStringValue(clientData!['EC1_Name'])));
    if (_hasValue(clientData?['EC1_Phone']))
      contactRows.add(_iconDetailRowWithActions(
        Icons.phone,
        'EC1 Phone',
        _safeStringValue(clientData!['EC1_Phone']),
        phone: _safeStringValue(clientData['EC1_Phone']),
      ));
    if (_hasValue(clientData?['EC1_Relation']))
      contactRows.add(_iconDetailRow(Icons.people, 'EC1 Relation',
          _safeStringValue(clientData!['EC1_Relation'])));
    if (_hasValue(clientData?['EC2_Name']))
      contactRows.add(_iconDetailRow(Icons.contact_phone, 'Emergency Contact 2',
          _safeStringValue(clientData!['EC2_Name'])));
    if (_hasValue(clientData?['EC2_Phone']))
      contactRows.add(_iconDetailRowWithActions(
        Icons.phone,
        'EC2 Phone',
        _safeStringValue(clientData!['EC2_Phone']),
        phone: _safeStringValue(clientData['EC2_Phone']),
      ));
    if (_hasValue(clientData?['EC2_Relation']))
      contactRows.add(_iconDetailRow(Icons.people, 'EC2 Relation',
          _safeStringValue(clientData!['EC2_Relation'])));
    if (_hasValue(clientData?['Emegency_Contact_Name']))
      contactRows.add(_iconDetailRow(Icons.phone, 'Emergency Contact',
          _safeStringValue(clientData!['Emegency_Contact_Name'])));

    // If no contact data from API, show basic info
    if (contactRows.isEmpty) {
      contactRows = [
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

  Widget _buildCorrespondenceAddressSection() {
    final Map<String, dynamic>? clientData = _getClientApiData();

    // Combine CA_Line_1 to CA_Line_4
    String? caAddressLine;
    final caLineParts = <String>[];
    if (_hasValue(clientData?['CA_Line_1'])) {
      caLineParts.add(clientData!['CA_Line_1'].toString());
    }
    if (_hasValue(clientData?['CA_Line_2'])) {
      caLineParts.add(clientData!['CA_Line_2'].toString());
    }
    if (_hasValue(clientData?['CA_Line_3'])) {
      caLineParts.add(clientData!['CA_Line_3'].toString());
    }
    if (_hasValue(clientData?['CA_Line_4'])) {
      caLineParts.add(clientData!['CA_Line_4'].toString());
    }
    if (caLineParts.isNotEmpty) {
      caAddressLine = caLineParts.join(', ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Correspondence Address',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // Address Line (combined)
                if (caAddressLine != null && caAddressLine.trim().isNotEmpty)
                  _iconDetailRow(Icons.home, 'Address', caAddressLine,
                      isCopyable: true),

                // RT/RW
                if (_hasValue(clientData?['CA_RT_RW']))
                  _iconDetailRow(Icons.home_outlined, 'RT/RW',
                      _safeStringValue(clientData!['CA_RT_RW']),
                      isCopyable: true),

                // Sub District
                if (_hasValue(clientData?['CA_Sub_District']))
                  _iconDetailRow(Icons.place, 'Sub District',
                      _safeStringValue(clientData!['CA_Sub_District']),
                      isCopyable: true),

                // District
                if (_hasValue(clientData?['CA_District']))
                  _iconDetailRow(Icons.map, 'District',
                      _safeStringValue(clientData!['CA_District']),
                      isCopyable: true),

                // City
                if (_hasValue(clientData?['CA_City']))
                  _iconDetailRow(Icons.location_city, 'City',
                      _safeStringValue(clientData!['CA_City']),
                      isCopyable: true),

                // Province
                if (_hasValue(clientData?['CA_Province']))
                  _iconDetailRow(Icons.map_outlined, 'Province',
                      _safeStringValue(clientData!['CA_Province']),
                      isCopyable: true),

                // Zip Code
                if (_hasValue(clientData?['CA_ZipCode']))
                  _iconDetailRow(Icons.markunread_mailbox, 'Zip Code',
                      _safeStringValue(clientData!['CA_ZipCode']),
                      isCopyable: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKtpAddressSection() {
    final Map<String, dynamic>? clientData = _getClientApiData();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('KTP Address',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // KTP Address (full text field)
                if (_hasValue(clientData?['KTP_Address']))
                  _iconDetailRow(Icons.credit_card, 'Address',
                      _safeStringValue(clientData!['KTP_Address']),
                      isCopyable: true),

                // Village
                if (_hasValue(clientData?['KTP_Village']))
                  _iconDetailRow(Icons.place, 'Village',
                      _safeStringValue(clientData!['KTP_Village']),
                      isCopyable: true),

                // District
                if (_hasValue(clientData?['KTP_District']))
                  _iconDetailRow(Icons.map, 'District',
                      _safeStringValue(clientData!['KTP_District']),
                      isCopyable: true),

                // City
                if (_hasValue(clientData?['KTP_City']))
                  _iconDetailRow(Icons.location_city, 'City',
                      _safeStringValue(clientData!['KTP_City']),
                      isCopyable: true),

                // Province
                if (_hasValue(clientData?['KTP_Province']))
                  _iconDetailRow(Icons.map_outlined, 'Province',
                      _safeStringValue(clientData!['KTP_Province']),
                      isCopyable: true),

                // Postal Code
                if (_hasValue(clientData?['KTP_Postal_Code']))
                  _iconDetailRow(Icons.markunread_mailbox, 'Postal Code',
                      _safeStringValue(clientData!['KTP_Postal_Code']),
                      isCopyable: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResidenceAddressSection() {
    final Map<String, dynamic>? clientData = _getClientApiData();

    // Combine RA_Line_1 to RA_Line_4
    String? raAddressLine;
    final raLineParts = <String>[];
    if (_hasValue(clientData?['RA_Line_1'])) {
      raLineParts.add(clientData!['RA_Line_1'].toString());
    }
    if (_hasValue(clientData?['RA_Line_2'])) {
      raLineParts.add(clientData!['RA_Line_2'].toString());
    }
    if (_hasValue(clientData?['RA_Line_3'])) {
      raLineParts.add(clientData!['RA_Line_3'].toString());
    }
    if (_hasValue(clientData?['RA_Line_4'])) {
      raLineParts.add(clientData!['RA_Line_4'].toString());
    }
    if (raLineParts.isNotEmpty) {
      raAddressLine = raLineParts.join(', ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Residence Address',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // Address Line (combined)
                if (raAddressLine != null && raAddressLine.trim().isNotEmpty)
                  _iconDetailRow(Icons.home, 'Address', raAddressLine,
                      isCopyable: true),

                // RT/RW
                if (_hasValue(clientData?['RA_RT_RW']))
                  _iconDetailRow(Icons.home_outlined, 'RT/RW',
                      _safeStringValue(clientData!['RA_RT_RW']),
                      isCopyable: true),

                // Sub District
                if (_hasValue(clientData?['Residence_Address_SubDistrict']))
                  _iconDetailRow(
                      Icons.place,
                      'Sub District',
                      _safeStringValue(
                          clientData!['Residence_Address_SubDistrict']),
                      isCopyable: true),

                // District
                if (_hasValue(clientData?['RA_District']))
                  _iconDetailRow(Icons.map, 'District',
                      _safeStringValue(clientData!['RA_District']),
                      isCopyable: true),

                // City
                if (_hasValue(clientData?['Residence_Address_City']))
                  _iconDetailRow(Icons.location_city, 'City',
                      _safeStringValue(clientData!['Residence_Address_City']),
                      isCopyable: true),

                // Province
                if (_hasValue(clientData?['Residence_Address_Province']))
                  _iconDetailRow(
                      Icons.map_outlined,
                      'Province',
                      _safeStringValue(
                          clientData!['Residence_Address_Province']),
                      isCopyable: true),

                // Zip Code
                if (_hasValue(clientData?['RA_Zip_Code']))
                  _iconDetailRow(Icons.markunread_mailbox, 'Zip Code',
                      _safeStringValue(clientData!['RA_Zip_Code']),
                      isCopyable: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialSection() {
    final Map<String, dynamic>? clientData = _getClientApiData();

    // Debug: Log financial data availability
    debugPrint('🔍 _buildFinancialSection - Debug financial data:');
    if (clientData != null) {
      debugPrint(
          '   - Total_OS_Yesterday1: ${clientData['Total_OS_Yesterday1']}');
      debugPrint(
          '   - Type: ${clientData['Total_OS_Yesterday1']?.runtimeType}');
      debugPrint(
          '   - _hasValue result: ${_hasValue(clientData['Total_OS_Yesterday1'])}');
    } else {
      debugPrint('   - clientData is NULL');
    }

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
                // Outstanding Amount
                if (_hasValue(clientData?['Total_OS_Yesterday1']))
                  _iconDetailRow(Icons.account_balance, 'Total Outstanding',
                      _formatCurrency(clientData!['Total_OS_Yesterday1']),
                      isCopyable: true),

                // Loan Amounts - Only show for Skorcard team and if Buy_Back_Status is not "True"
                if (_hasValue(clientData?['Last_Statement_MAD']) &&
                    clientData?['Buy_Back_Status'] != "True" &&
                    _isSkorCardUser())
                  _iconDetailRow(Icons.attach_money, 'Last Statement MAD',
                      _formatCurrency(clientData!['Last_Statement_MAD']),
                      isCopyable: true),
                if (_hasValue(clientData?['Last_Statement_TAD']) &&
                    clientData?['Buy_Back_Status'] != "True" &&
                    _isSkorCardUser())
                  _iconDetailRow(
                      Icons.account_balance_wallet,
                      'Last Statement TAD',
                      _formatCurrency(clientData!['Last_Statement_TAD']),
                      isCopyable: true),

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
                if (_hasValue(clientData?['Buy_Back_Status']) &&
                    _isSkorCardUser())
                  _iconDetailRow(Icons.shopping_cart, 'BuyBack Status',
                      _safeStringValue(clientData!['Buy_Back_Status'])),

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

  Widget _buildEmiRestructuringSection() {
    if (!_hasEmiData || _emiRestructuringData == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('EMI Restructuring Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                if (_hasValue(_emiRestructuringData!['Original_Due_Amount']))
                  _iconDetailRow(
                    Icons.account_balance_wallet,
                    'Original Due Amount',
                    _formatCurrency(
                        _emiRestructuringData!['Original_Due_Amount']),
                  ),
                if (_hasValue(_emiRestructuringData!['Due_Date']))
                  _iconDetailRow(
                    Icons.event,
                    'Restructure Due Date',
                    _formatDate(_emiRestructuringData!['Due_Date']),
                  ),
                if (_hasValue(_emiRestructuringData!['Tenure']))
                  _iconDetailRow(
                    Icons.schedule,
                    'Restructure Tenure',
                    '${_emiRestructuringData!['Tenure']} months',
                  ),
                if (_hasValue(_emiRestructuringData!['Current_Due_Amount']))
                  _iconDetailRow(
                    Icons.monetization_on,
                    'Current Due Amount',
                    _formatCurrency(
                        _emiRestructuringData!['Current_Due_Amount']),
                  ),
                if (_hasValue(_emiRestructuringData!['Total_Paid_Amount']))
                  _iconDetailRow(
                    Icons.payment,
                    'Total Paid Amount',
                    _formatCurrency(
                        _emiRestructuringData!['Total_Paid_Amount']),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    final Map<String, dynamic>? clientData = _getClientApiData();

    // Compose Office Address Line (combine OA_Line_1 to OA_Line_4 only)
    String? officeAddressLine;
    final lineParts = <String>[];
    if (_hasValue(clientData?['OA_Line_1'])) {
      lineParts.add(clientData!['OA_Line_1'].toString());
    }
    if (_hasValue(clientData?['OA_Line_2'])) {
      lineParts.add(clientData!['OA_Line_2'].toString());
    }
    if (_hasValue(clientData?['OA_Line_3'])) {
      lineParts.add(clientData!['OA_Line_3'].toString());
    }
    if (_hasValue(clientData?['OA_Line_4'])) {
      lineParts.add(clientData!['OA_Line_4'].toString());
    }
    if (lineParts.isNotEmpty) {
      officeAddressLine = lineParts.join(', ');
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

                // Office Address (gabungan OA_Line_1 sampai 4)
                if (officeAddressLine != null &&
                    officeAddressLine.trim().isNotEmpty)
                  _iconDetailRow(
                      Icons.location_on, 'Office Address', officeAddressLine,
                      isCopyable: true),

                // RT/RW terpisah
                if (_hasValue(clientData?['OA_RT_RW']))
                  _iconDetailRow(Icons.home_outlined, 'Office RT/RW',
                      _safeStringValue(clientData!['OA_RT_RW']),
                      isCopyable: true),

                // Sub District terpisah
                if (_hasValue(clientData?['Office_Address_SubDistrict']))
                  _iconDetailRow(
                      Icons.place,
                      'Office Sub District',
                      _safeStringValue(
                          clientData!['Office_Address_SubDistrict']),
                      isCopyable: true),

                // District terpisah
                if (_hasValue(clientData?['Office_Address_District']))
                  _iconDetailRow(Icons.map, 'Office District',
                      _safeStringValue(clientData!['Office_Address_District']),
                      isCopyable: true),

                // City terpisah
                if (_hasValue(clientData?['Office_Address_City']))
                  _iconDetailRow(Icons.location_city, 'Office City',
                      _safeStringValue(clientData!['Office_Address_City']),
                      isCopyable: true),

                // Province terpisah
                if (_hasValue(clientData?['Office_Address_Province']))
                  _iconDetailRow(Icons.map_outlined, 'Office Province',
                      _safeStringValue(clientData!['Office_Address_Province']),
                      isCopyable: true),

                // Zipcode terpisah
                if (_hasValue(clientData?['Office_Address_Zipcode']))
                  _iconDetailRow(Icons.markunread_mailbox, 'Office Zipcode',
                      _safeStringValue(clientData!['Office_Address_Zipcode']),
                      isCopyable: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photos',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                if (_isLoadingPhotos)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Loading photos...'),
                      ],
                    ),
                  ),
                if (!_isLoadingPhotos) ...[
                  // KTP Photo
                  _buildPhotoRow(
                    'KTP Photo',
                    _photoPaths['ktp'],
                    Icons.credit_card,
                  ),
                  const SizedBox(height: 12),

                  // Selfie Photo
                  _buildPhotoRow(
                    'Selfie Photo',
                    _photoPaths['selfie'],
                    Icons.face,
                    height: 130, // Increased height for selfie
                  ),
                ],
                if (_photoError != null && !_isLoadingPhotos)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Photos could not be loaded',
                            style: TextStyle(color: Colors.orange[700]),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final skorUserId = widget.client.skorUserId;
                            if (skorUserId != null && skorUserId.isNotEmpty) {
                              _loadUserPhotos(skorUserId);
                            }
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoRow(String label, String? photoPath, IconData icon,
      {double height = 100}) {
    return Row(
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
          child: photoPath != null
              ? GestureDetector(
                  onTap: () => _showPhotoDialog(photoPath, label),
                  child: Container(
                    height: height, // Use dynamic height
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(photoPath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.error, color: Colors.red),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                )
              : Container(
                  height: height, // Use dynamic height
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'No photo available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  void _showPhotoDialog(String photoPath, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.file(
                File(photoPath),
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.white, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'Could not load image',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
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

  // Helper method to check if current user is from Skorcard team
  bool _isSkorCardUser() {
    final authService = context.read<AuthService>();
    final userTeam = authService.userData?['team'] as String?;
    debugPrint('🏢 User team: "$userTeam"');
    debugPrint(
        '🔍 Is Skorcard user: ${userTeam != null && userTeam.toLowerCase() == 'skorcard'}');
    return userTeam != null && userTeam.toLowerCase() == 'skorcard';
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

  // Filter contactability history items based on search query, date range, and contact result
  List<ContactabilityHistory> _filterContactabilityHistory(
      List<ContactabilityHistory> items) {
    return items.where((item) {
      // Search filter - search in notes and contact result
      bool matchesSearch = _searchQuery.isEmpty ||
          (item.notes?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false) ||
          item.resultDisplayName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          item.channelDisplayName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      // Date filter
      bool matchesDateRange = true;
      if (_startDate != null || _endDate != null) {
        final itemDate = DateTime(
          item.contactedAt.year,
          item.contactedAt.month,
          item.contactedAt.day,
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
          item.resultDisplayName.toLowerCase() ==
              _selectedContactResult!.toLowerCase();

      return matchesSearch && matchesDateRange && matchesContactResult;
    }).toList();
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
            final allHistory = controller.contactabilityHistory;
            final filteredHistory = _filterContactabilityHistory(allHistory);

            if (allHistory.isEmpty) {
              return _buildEmptyHistoryState();
            } else if (filteredHistory.isEmpty && allHistory.isNotEmpty) {
              return _buildNoResultsState();
            }
            return _buildHistoryListWithFilters(filteredHistory, controller);

          case ContactabilityLoadingState.submitting:
            return const LoadingWidget(message: 'Submitting...');
        }
      },
    );
  }

  // Date picker methods
  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Widget _buildEmptyHistoryState() {
    return RefreshIndicator(
      onRefresh: () => context.read<ContactabilityController>().refresh(),
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
      onRefresh: () => context.read<ContactabilityController>().refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
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

  Widget _buildHistoryListWithFilters(List<ContactabilityHistory> history,
      ContactabilityController controller) {
    return RefreshIndicator(
      onRefresh: () => controller.refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by notes, contact result, or channel...',
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
                        '${history.length} records',
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

            // Filter section
            if (_showFilters) ..._buildFilterSection(),

            const SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final contactability = history[index];
                return _buildHistoryCard(contactability);
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFilterSection() {
    return [
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
                              ? TimezoneUtils.formatIndonesianDate(_startDate!)
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
                              ? TimezoneUtils.formatIndonesianDate(_endDate!)
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
              Container(
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
                  items: _getContactResultDropdownItems(),
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
    ];
  }

  List<DropdownMenuItem<String>> _getContactResultDropdownItems() {
    return [
      const DropdownMenuItem<String>(
        value: null,
        child: Text('All Results'),
      ),
      const DropdownMenuItem<String>(
        value: 'Promise to Pay (PTP)',
        child: Text('Promise to Pay (PTP)'),
      ),
      const DropdownMenuItem<String>(
        value: 'Already Paid',
        child: Text('Already Paid'),
      ),
      const DropdownMenuItem<String>(
        value: 'Refuse to Pay',
        child: Text('Refuse to Pay'),
      ),
      const DropdownMenuItem<String>(
        value: 'Negotiation',
        child: Text('Negotiation'),
      ),
      const DropdownMenuItem<String>(
        value: 'Hot Prospect',
        child: Text('Hot Prospect'),
      ),
      const DropdownMenuItem<String>(
        value: 'Dispute',
        child: Text('Dispute'),
      ),
      const DropdownMenuItem<String>(
        value: 'Not Recognized',
        child: Text('Not Recognized'),
      ),
      const DropdownMenuItem<String>(
        value: 'Partial Payment',
        child: Text('Partial Payment'),
      ),
      const DropdownMenuItem<String>(
        value: 'Failed to Pay',
        child: Text('Failed to Pay'),
      ),
      const DropdownMenuItem<String>(
        value: 'Alamat Ditemukan, Rumah Kosong',
        child: Text('Alamat Ditemukan, Rumah Kosong'),
      ),
      const DropdownMenuItem<String>(
        value: 'Alamat Tidak Ditemukan',
        child: Text('Alamat Tidak Ditemukan'),
      ),
      const DropdownMenuItem<String>(
        value: 'Alamat Salah',
        child: Text('Alamat Salah'),
      ),
      const DropdownMenuItem<String>(
        value: 'Menghindar',
        child: Text('Menghindar'),
      ),
      const DropdownMenuItem<String>(
        value: 'No Respond',
        child: Text('No Respond'),
      ),
    ];
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

  Widget _iconDetailRow(IconData icon, String label, String value,
      {bool isCopyable = false}) {
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
          if (isCopyable) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _copyToClipboard(value, label),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(
                  Icons.copy,
                  size: 16,
                  color: Colors.blueGrey,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _iconDetailRowWithActions(IconData icon, String label, String value,
      {String? phone}) {
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
          if (phone != null) ...[
            const SizedBox(width: 8),
            // WhatsApp icon
            GestureDetector(
              onTap: () => _openWhatsApp(phone),
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
              onTap: () => _makePhoneCall(phone),
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

  void _navigateToLocationHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientLocationHistoryScreen(
          client: widget.client,
        ),
      ),
    );
  }

  void _navigateToSkipTracing() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SkipTracingScreen(
          client: widget.client,
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
