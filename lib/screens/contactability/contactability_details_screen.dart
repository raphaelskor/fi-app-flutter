import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/contactability_history.dart';
import '../../core/utils/app_utils.dart' as AppUtils;

// Try to import cached_network_image, fallback to regular network image if not available
Widget buildNetworkImage({
  required String imageUrl,
  double? height,
  double? width,
  BoxFit? fit,
  Widget? placeholder,
  Widget? errorWidget,
}) {
  return Image.network(
    imageUrl,
    height: height,
    width: width,
    fit: fit ?? BoxFit.cover,
    loadingBuilder: (context, child, loadingProgress) {
      if (loadingProgress == null) return child;
      return placeholder ??
          Container(
            height: height,
            width: width,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
    },
    errorBuilder: (context, error, stackTrace) {
      return errorWidget ??
          Container(
            height: height,
            width: width,
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.error, color: Colors.red),
            ),
          );
    },
  );
}

class ContactabilityDetailsScreen extends StatefulWidget {
  final ContactabilityHistory contactability;

  const ContactabilityDetailsScreen({
    Key? key,
    required this.contactability,
  }) : super(key: key);

  @override
  State<ContactabilityDetailsScreen> createState() =>
      _ContactabilityDetailsScreenState();
}

class _ContactabilityDetailsScreenState
    extends State<ContactabilityDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Debug: Print all rawData fields to see what's available
    print('=== ContactabilityDetailsScreen Debug ===');
    print('All rawData fields:');
    widget.contactability.rawData.forEach((key, value) {
      print('  $key: $value');
    });
    print('Action Location value: ${_getActionLocation()}');
    print('=========================================');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contactability Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(),
            const SizedBox(height: 16),

            // Visit Images Section
            _buildVisitImagesSection(),

            // Contact Information
            _buildContactInformationSection(),
            const SizedBox(height: 16),

            // Agent Information (for all channels)
            _buildAgentInformationSection(),

            // Visit Details (if applicable)
            if (_isFieldVisit()) _buildVisitDetailsSection(),

            // Call Details (if applicable)
            if (_isCall()) _buildCallDetailsSection(),

            // WhatsApp/Message Details (if applicable)
            if (_isMessage() && _hasMessageData())
              _buildMessageDetailsSection(),

            // PTP Information (if available)
            _buildPTPSection(),

            // Additional Information
            _buildAdditionalInformationSection(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getChannelIcon(widget.contactability.channel),
                  size: 28,
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.contactability.channelDisplayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.contactability.name,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        _getResultColor(widget.contactability.resultDisplayName)
                            .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getResultColor(
                          widget.contactability.resultDisplayName),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.contactability.resultDisplayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getResultColor(
                          widget.contactability.resultDisplayName),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.access_time,
              'Contact Date',
              AppUtils.DateUtils.formatDisplayDateTime(
                  widget.contactability.contactedAt),
            ),
            if (widget.contactability.skorUserId.isNotEmpty)
              _buildInfoRow(
                Icons.account_circle,
                'Client ID',
                widget.contactability.skorUserId,
              ),
            // Always show client name if available
            if (_getClientName().isNotEmpty)
              _buildInfoRow(
                Icons.person,
                'Client Name',
                _getClientName(),
              ),
            // Show User ID if available and different from Skor User ID
            if (_getUserId().isNotEmpty &&
                _getUserId() != widget.contactability.skorUserId)
              _buildInfoRow(
                Icons.badge,
                'User ID',
                _getUserId(),
              ),
            // Add phone number if available
            if (_getPhoneNumber().isNotEmpty)
              _buildInfoRow(
                Icons.phone,
                'Phone Number',
                _getPhoneNumber(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitImagesSection() {
    final List<String> imageUrls = _getVisitImages();

    if (imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    // Determine the section title based on channel
    String sectionTitle = 'Images';
    if (_isFieldVisit()) {
      sectionTitle = 'Visit Images';
    } else if (_isMessage()) {
      sectionTitle = 'Message Images';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionTitle,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (imageUrls.length == 1)
                  _buildSingleImage(imageUrls[0])
                else
                  _buildImageGrid(imageUrls),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSingleImage(String imageUrl) {
    return GestureDetector(
      onTap: () => _showImageDialog(imageUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: buildNetworkImage(
          imageUrl: imageUrl,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: Container(
            height: 200,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: Container(
            height: 200,
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.error, color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageGrid(List<String> imageUrls) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: imageUrls.length > 2 ? 3 : 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _showImageDialog(imageUrls[index]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: buildNetworkImage(
              imageUrl: imageUrls[index],
              fit: BoxFit.cover,
              placeholder: Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.error, color: Colors.red),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              child: buildNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                placeholder: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: const Center(
                  child: Icon(Icons.error, color: Colors.white, size: 48),
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

  Widget _buildContactInformationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.record_voice_over,
                  'Channel',
                  widget.contactability.channelDisplayName,
                ),
                _buildInfoRow(
                  Icons.info_outline,
                  'Result',
                  widget.contactability.resultDisplayName,
                ),
                // Person Contacted
                if (_hasValue(_getPersonContacted()))
                  _buildInfoRow(
                    Icons.person_outline,
                    'Person Contacted',
                    _getPersonContacted(),
                  ),
                // Action Location
                if (_hasValue(_getActionLocation()))
                  _buildInfoRow(
                    Icons.location_on_outlined,
                    _getActionLocationLabel(),
                    _getActionLocation(),
                  ),
                if (widget.contactability.notes != null &&
                    widget.contactability.notes!.isNotEmpty)
                  _buildInfoRow(
                    Icons.note,
                    'Notes',
                    widget.contactability.notes!,
                  ),
                _buildInfoRow(
                  Icons.schedule,
                  'Created',
                  AppUtils.DateUtils.formatDisplayDateTime(
                      widget.contactability.createdTime),
                ),
                if (widget.contactability.modifiedTime != null)
                  _buildInfoRow(
                    Icons.update,
                    'Modified',
                    AppUtils.DateUtils.formatDisplayDateTime(
                        widget.contactability.modifiedTime!),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgentInformationSection() {
    // Check if any agent information exists
    final hasVisitAgent = widget.contactability.visitAgent != null ||
        _hasValue(widget.contactability.rawData['Visit_Agent']) ||
        _hasValue(widget.contactability.rawData['Call_Agent']) ||
        _hasValue(widget.contactability.rawData['Agent_WA_Sent_Name']);

    final hasTeamLead =
        _hasValue(widget.contactability.rawData['Visit_Agent_Team_Lead']);
    final hasVisitBySkorTeam =
        _hasValue(widget.contactability.rawData['Visit_by_Skor_Team']);

    if (!hasVisitAgent && !hasTeamLead && !hasVisitBySkorTeam) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Agent Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Visit Agent - check multiple possible fields
                if (widget.contactability.visitAgent != null)
                  _buildInfoRow(
                    Icons.person,
                    'Visit Agent',
                    widget.contactability.visitAgent!,
                  )
                else if (_hasValue(
                    widget.contactability.rawData['Visit_Agent']))
                  _buildInfoRow(
                    Icons.person,
                    'Visit Agent',
                    widget.contactability.rawData['Visit_Agent'].toString(),
                  )
                else if (_hasValue(widget.contactability.rawData['Call_Agent']))
                  _buildInfoRow(
                    Icons.person,
                    'Visit Agent',
                    widget.contactability.rawData['Call_Agent'].toString(),
                  )
                else if (_hasValue(
                    widget.contactability.rawData['Agent_WA_Sent_Name']))
                  _buildInfoRow(
                    Icons.person,
                    'Visit Agent',
                    widget.contactability.rawData['Agent_WA_Sent_Name']
                        .toString(),
                  ),

                // Visit Agent Team Lead
                if (_hasValue(
                    widget.contactability.rawData['Visit_Agent_Team_Lead']))
                  _buildInfoRow(
                    Icons.supervisor_account,
                    'Visit Agent Team Lead',
                    widget.contactability.rawData['Visit_Agent_Team_Lead']
                        .toString(),
                  ),

                // Visit by Skor Team
                if (_hasValue(
                    widget.contactability.rawData['Visit_by_Skor_Team']))
                  _buildInfoRow(
                    Icons.group,
                    'Visit by Skor Team',
                    widget.contactability.rawData['Visit_by_Skor_Team']
                        .toString(),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildVisitDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Visit Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (widget.contactability.visitLocation != null)
                  _buildInfoRow(
                    Icons.location_on,
                    'Visit Location',
                    widget.contactability.visitLocation!,
                  ),
                if (widget.contactability.status != null)
                  _buildInfoRow(
                    Icons.flag,
                    'Visit Status',
                    widget.contactability.status!,
                  ),
                if (widget.contactability.visitDate != null)
                  _buildInfoRow(
                    Icons.event,
                    'Visit Date',
                    AppUtils.DateUtils.formatDisplayDateTime(
                        widget.contactability.visitDate!),
                  ),
                if (widget.contactability.visitLatLong != null)
                  _buildCoordinatesRow(
                    widget.contactability.visitLatLong!,
                  ),
                if (_hasValue(widget.contactability.rawData['Vist_Action']))
                  _buildInfoRow(
                    Icons.directions_run,
                    'Visit Action',
                    widget.contactability.rawData['Vist_Action'].toString(),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCallDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Call Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (_hasValue(widget.contactability.rawData['Call_Done_to']))
                  _buildInfoRow(
                    Icons.phone,
                    'Called To',
                    widget.contactability.rawData['Call_Done_to'].toString(),
                  ),
                if (_hasValue(widget.contactability.rawData['If_Connected']))
                  _buildInfoRow(
                    Icons.check_circle,
                    'Connected',
                    widget.contactability.rawData['If_Connected'].toString(),
                  ),
                if (_hasValue(
                    widget.contactability.rawData['If_not_Connected']))
                  _buildInfoRow(
                    Icons.cancel,
                    'Not Connected Reason',
                    widget.contactability.rawData['If_not_Connected']
                        .toString(),
                  ),
                if (_hasValue(
                    widget.contactability.rawData['Agent_Call_Done_Time']))
                  _buildInfoRow(
                    Icons.access_time,
                    'Call Time',
                    widget.contactability.rawData['Agent_Call_Done_Time']
                        .toString(),
                  ),
                if (_hasValue(
                    widget.contactability.rawData['Robo_Call_Result']))
                  _buildInfoRow(
                    Icons.smart_toy,
                    'Robo Call Result',
                    widget.contactability.rawData['Robo_Call_Result']
                        .toString(),
                  ),
                if (_hasValue(
                    widget.contactability.rawData['Robo_Call_Twilio_Id']))
                  _buildInfoRow(
                    Icons.confirmation_number,
                    'Robo Call ID',
                    widget.contactability.rawData['Robo_Call_Twilio_Id']
                        .toString(),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMessageDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Message Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (widget.contactability.messageSentFor != null)
                  _buildInfoRow(
                    Icons.message,
                    'Message Content',
                    widget.contactability.messageSentFor!,
                  ),
                if (widget.contactability.deliveredTimeIfAny != null)
                  _buildInfoRow(
                    Icons.check,
                    'Delivered Time',
                    widget.contactability.deliveredTimeIfAny!,
                  ),
                if (widget.contactability.readTimeIfAny != null)
                  _buildInfoRow(
                    Icons.done_all,
                    'Read Time',
                    widget.contactability.readTimeIfAny!,
                  ),
                if (_hasValue(
                    widget.contactability.rawData['Whats_app_Channel']))
                  _buildInfoRow(
                    Icons.chat,
                    'WhatsApp Channel',
                    widget.contactability.rawData['Whats_app_Channel']
                        .toString(),
                  ),
                if (_hasValue(
                    widget.contactability.rawData['Agent_WA_Done_Time']))
                  _buildInfoRow(
                    Icons.schedule,
                    'Sent Time',
                    widget.contactability.rawData['Agent_WA_Done_Time']
                        .toString(),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPTPSection() {
    final ptpDate = widget.contactability.rawData['P2P_Date'] ??
        widget.contactability.rawData['P2p_Date'];
    final ptpAmount = widget.contactability.rawData['P2P_Amount'] ??
        widget.contactability.rawData['P2p_Amount'];

    if (!_hasValue(ptpDate) && !_hasValue(ptpAmount)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Promise to Pay (PTP)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          color: Colors.orange[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (_hasValue(ptpAmount))
                  _buildInfoRow(
                    Icons.attach_money,
                    'PTP Amount',
                    'Rp ${_formatCurrency(ptpAmount.toString())}',
                    iconColor: Colors.orange,
                  ),
                if (_hasValue(ptpDate))
                  _buildInfoRow(
                    Icons.event,
                    'PTP Date',
                    ptpDate.toString(),
                    iconColor: Colors.orange,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAdditionalInformationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Client Information first
                if (_getClientName().isNotEmpty)
                  _buildInfoRow(
                    Icons.person,
                    'Client Name',
                    _getClientName(),
                  ),
                if (_getPhoneNumber().isNotEmpty)
                  _buildInfoRow(
                    Icons.phone_android,
                    'Phone Number',
                    _getPhoneNumber(),
                  ),
                if (_hasValue(widget.contactability.rawData['Email']))
                  _buildInfoRow(
                    Icons.email,
                    'Email',
                    widget.contactability.rawData['Email'].toString(),
                  ),

                // New contact information (if provided during contactability)
                if (_getNewPhoneNumber().isNotEmpty)
                  _buildInfoRow(
                    Icons.phone_android,
                    'New Phone Number',
                    _getNewPhoneNumber(),
                    iconColor: Colors.green,
                  ),
                if (_getNewAddress().isNotEmpty)
                  _buildInfoRow(
                    Icons.home,
                    'New Address',
                    _getNewAddress(),
                    iconColor: Colors.green,
                  ),

                // Other information
                if (widget.contactability.dpdbucket != null)
                  _buildInfoRow(
                    Icons.category,
                    'DPD Bucket',
                    widget.contactability.dpdbucket!,
                  ),
                if (_hasValue(widget.contactability.rawData['Reachability']))
                  _buildInfoRow(
                    Icons.signal_cellular_alt,
                    'Reachability',
                    widget.contactability.rawData['Reachability'].toString(),
                  ),
                if (_hasValue(
                    widget.contactability.rawData['Record_Status__s']))
                  _buildInfoRow(
                    Icons.record_voice_over,
                    'Record Status',
                    widget.contactability.rawData['Record_Status__s']
                        .toString(),
                  ),
                if (_hasValue(widget.contactability.rawData['Agency_If_Any']))
                  _buildInfoRow(
                    Icons.business,
                    'Agency',
                    widget.contactability.rawData['Agency_If_Any'].toString(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor ?? Colors.blue,
            size: 20,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getVisitImages() {
    final List<String> images = [];
    final rawData = widget.contactability.rawData;

    // Check Visit_Image_1, Visit_Image_2, Visit_Image_3
    for (int i = 1; i <= 3; i++) {
      final imageUrl = rawData['Visit_Image_$i'];
      if (_hasValue(imageUrl) && imageUrl.toString().startsWith('http')) {
        images.add(imageUrl.toString());
      }
    }

    // Also check Visit_Image field
    final visitImage = rawData['Visit_Image'];
    if (_hasValue(visitImage) && visitImage.toString().startsWith('http')) {
      images.add(visitImage.toString());
    }

    return images;
  }

  bool _hasValue(dynamic value) {
    if (value == null) return false;
    if (value is String &&
        (value.isEmpty ||
            value.toLowerCase() == 'null' ||
            value.toLowerCase() == 'na')) return false;
    return true;
  }

  bool _hasMessageData() {
    // Check if any message-related data exists
    if (widget.contactability.messageSentFor != null &&
        widget.contactability.messageSentFor!.isNotEmpty) return true;

    if (widget.contactability.deliveredTimeIfAny != null &&
        widget.contactability.deliveredTimeIfAny!.isNotEmpty) return true;

    if (widget.contactability.readTimeIfAny != null &&
        widget.contactability.readTimeIfAny!.isNotEmpty) return true;

    if (_hasValue(widget.contactability.rawData['Whats_app_Channel']))
      return true;
    if (_hasValue(widget.contactability.rawData['Agent_WA_Sent_Name']))
      return true;
    if (_hasValue(widget.contactability.rawData['Agent_WA_Done_Time']))
      return true;

    return false;
  }

  bool _isFieldVisit() {
    return widget.contactability.channel.toLowerCase().contains('visit') ||
        widget.contactability.channel.toLowerCase().contains('field');
  }

  bool _isCall() {
    return widget.contactability.channel.toLowerCase().contains('call');
  }

  bool _isMessage() {
    return widget.contactability.channel.toLowerCase().contains('whatsapp') ||
        widget.contactability.channel.toLowerCase().contains('message') ||
        widget.contactability.channel.toLowerCase().contains('sms');
  }

  String _formatCurrency(String value) {
    try {
      final num amount = num.parse(value);
      return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},');
    } catch (e) {
      return value;
    }
  }

  IconData _getChannelIcon(String channel) {
    switch (channel.toLowerCase()) {
      case 'field visit':
        return Icons.location_on;
      case 'whatsapp':
        return Icons.message;
      case 'call':
      case 'robo call':
        return Icons.call;
      case 'sms':
        return Icons.sms;
      case 'email':
        return Icons.email;
      default:
        return Icons.contact_phone;
    }
  }

  Color _getResultColor(String result) {
    switch (result.toLowerCase()) {
      case 'delivered':
      case 'contacted':
      case 'ptp':
      case 'connected':
      case 'read':
        return Colors.green;
      case 'visited':
      case 'alamat ditemukan':
        return Colors.blue;
      case 'sent':
      case 'not contacted':
      case 'no answer':
      case 'no-answer':
        return Colors.orange;
      case 'not available':
      case 'alamat tidak ditemukan':
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCoordinatesRow(String coordinates) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(Icons.gps_fixed, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          const Text(
            'Coordinates: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(coordinates),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.map, color: Colors.blue, size: 20),
            onPressed: () {
              _openGoogleMaps(coordinates);
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Buka di Google Maps',
          ),
        ],
      ),
    );
  }

  void _openGoogleMaps(String coordinates) async {
    try {
      // Format: "latitude,longitude"
      final coords = coordinates.split(',');
      if (coords.length == 2) {
        final lat = coords[0].trim();
        final lng = coords[1].trim();

        final url = Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=$lat,$lng');

        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak dapat membuka Google Maps'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Format koordinat tidak valid'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error membuka Google Maps'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getClientName() {
    // Try to get client name from various possible fields in rawData
    final rawData = widget.contactability.rawData;

    // Primary source: User_ID.name (nested object from API)
    if (rawData['User_ID'] != null && rawData['User_ID'] is Map) {
      final userIdData = rawData['User_ID'] as Map<String, dynamic>;
      if (_hasValue(userIdData['name'])) {
        return userIdData['name'].toString();
      }
    }

    // Fallback to other client name fields
    if (_hasValue(rawData['Client_Name'])) {
      return rawData['Client_Name'].toString();
    }
    if (_hasValue(rawData['Customer_Name'])) {
      return rawData['Customer_Name'].toString();
    }
    if (_hasValue(rawData['Borrower_Name'])) {
      return rawData['Borrower_Name'].toString();
    }
    if (_hasValue(rawData['Full_Name'])) {
      return rawData['Full_Name'].toString();
    }

    // If no specific client name found, use the general 'name' field from contactability
    if (widget.contactability.name.isNotEmpty &&
        widget.contactability.name.toLowerCase() != 'unknown' &&
        widget.contactability.name.toLowerCase() != 'null') {
      return widget.contactability.name;
    }

    return '';
  }

  String _getUserId() {
    // Try to get user ID from User_ID field or other ID fields
    final rawData = widget.contactability.rawData;

    // Primary source: User_ID.id (nested object from API)
    if (rawData['User_ID'] != null && rawData['User_ID'] is Map) {
      final userIdData = rawData['User_ID'] as Map<String, dynamic>;
      if (_hasValue(userIdData['id'])) {
        return userIdData['id'].toString();
      }
    }

    // Check other possible user ID fields
    if (_hasValue(rawData['User_ID'])) {
      return rawData['User_ID'].toString();
    }
    if (_hasValue(rawData['Client_ID'])) {
      return rawData['Client_ID'].toString();
    }
    if (_hasValue(rawData['Customer_ID'])) {
      return rawData['Customer_ID'].toString();
    }

    return '';
  }

  String _getPhoneNumber() {
    // Try to get phone number from various possible fields in rawData
    final rawData = widget.contactability.rawData;

    // Check phone number fields
    if (_hasValue(rawData['Phone_Contact_Number'])) {
      return rawData['Phone_Contact_Number'].toString();
    }
    if (_hasValue(rawData['Mobile'])) {
      return rawData['Mobile'].toString();
    }
    if (_hasValue(rawData['Phone_Number'])) {
      return rawData['Phone_Number'].toString();
    }
    if (_hasValue(rawData['Contact_Number'])) {
      return rawData['Contact_Number'].toString();
    }
    if (_hasValue(rawData['Mobile_Number'])) {
      return rawData['Mobile_Number'].toString();
    }

    return '';
  }

  String _getPersonContacted() {
    // Try to get person contacted from various possible fields in rawData
    final rawData = widget.contactability.rawData;

    // Check person contacted fields
    if (_hasValue(rawData['Person_Contacted'])) {
      return rawData['Person_Contacted'].toString();
    }
    if (_hasValue(rawData['PersonContacted'])) {
      return rawData['PersonContacted'].toString();
    }
    if (_hasValue(rawData['Contact_Person'])) {
      return rawData['Contact_Person'].toString();
    }

    return '';
  }

  String _getActionLocation() {
    // Try to get action location from various possible fields in rawData
    final rawData = widget.contactability.rawData;

    // Primary field: Call_Done_to (this is what Action_Location from form gets saved as)
    if (_hasValue(rawData['Call_Done_to'])) {
      return rawData['Call_Done_to'].toString();
    }
    // Check other possible action location fields
    if (_hasValue(rawData['Action_Location'])) {
      return rawData['Action_Location'].toString();
    }

    return '';
  }

  String _getActionLocationLabel() {
    // Always return "Action Location" to match the form field name
    return 'Action Location';
  }

  String _getNewPhoneNumber() {
    // Try to get new phone number from various possible fields in rawData
    final rawData = widget.contactability.rawData;

    // Check new phone number fields
    if (_hasValue(rawData['New_Phone_Number'])) {
      return rawData['New_Phone_Number'].toString();
    }
    if (_hasValue(rawData['NewPhoneNumber'])) {
      return rawData['NewPhoneNumber'].toString();
    }
    if (_hasValue(rawData['Updated_Phone'])) {
      return rawData['Updated_Phone'].toString();
    }

    return '';
  }

  String _getNewAddress() {
    // Try to get new address from various possible fields in rawData
    final rawData = widget.contactability.rawData;

    // Check new address fields
    if (_hasValue(rawData['New_Address'])) {
      return rawData['New_Address'].toString();
    }
    if (_hasValue(rawData['NewAddress'])) {
      return rawData['NewAddress'].toString();
    }
    if (_hasValue(rawData['Updated_Address'])) {
      return rawData['Updated_Address'].toString();
    }

    return '';
  }
}
