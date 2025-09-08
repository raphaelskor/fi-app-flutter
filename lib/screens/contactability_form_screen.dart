import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../core/controllers/contactability_controller.dart';
import '../core/models/client.dart';
import '../core/models/contactability.dart';
import '../core/utils/app_utils.dart';
import '../core/utils/timezone_utils.dart';
import '../core/services/auth_service.dart';

class ContactabilityFormScreen extends StatefulWidget {
  final Client client;
  final String channel;

  const ContactabilityFormScreen({
    Key? key,
    required this.client,
    required this.channel,
  }) : super(key: key);

  @override
  State<ContactabilityFormScreen> createState() =>
      _ContactabilityFormScreenState();
}

class _ContactabilityFormScreenState extends State<ContactabilityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _visitNotesController = TextEditingController();
  final _visitAgentController = TextEditingController();
  final _visitAgentTeamLeadController = TextEditingController();
  final _ptpAmountController = TextEditingController();
  final _newPhoneNumberController = TextEditingController();
  final _newAddressController = TextEditingController();

  ContactabilityChannel? _selectedChannel;
  DateTime? _selectedPtpDate;
  bool _showPtpFields = false;
  bool _hasAttemptedSubmit = false; // Track if user has attempted to submit

  @override
  void initState() {
    super.initState();
    _selectedChannel = _parseChannel(widget.channel);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = context.read<ContactabilityController>();
      final authService = context.read<AuthService>();
      final userData = authService.userData;

      controller.initialize(widget.client.id,
          skorUserId: widget.client.skorUserId);
      controller.setSelectedChannel(_selectedChannel!);

      // Auto-refresh location every time form is opened
      try {
        await controller.refreshLocation();
      } catch (e) {
        debugPrint('Failed to refresh location on form open: $e');
      }

      // Auto-set Visit by Skor Team based on user's team
      if (userData != null && userData['team'] != null) {
        final userTeam = userData['team'].toString();
        final visitBySkorTeam = userTeam.toLowerCase() == 'skorcard'
            ? VisitBySkorTeam.yes
            : VisitBySkorTeam.no;
        controller.setSelectedVisitBySkorTeam(visitBySkorTeam);

        // Auto-set agent information from user data
        final userName = userData['name']?.toString() ?? '';
        final userTeamName = userData['team']?.toString() ?? '';

        _visitAgentController.text = userName;
        _visitAgentTeamLeadController.text = userTeamName;

        controller.setVisitAgent(userName);
        controller.setVisitAgentTeamLead(userTeamName);
      }

      // Set initial PTP fields visibility
      setState(() {
        _showPtpFields = _shouldShowPtpFields(controller);
      });
    });
  }

  // Helper method to determine if PTP fields should be shown
  bool _shouldShowPtpFields(ContactabilityController controller) {
    return controller.selectedContactResult == ContactResult.ptp;
  }

  @override
  void dispose() {
    _visitNotesController.dispose();
    _visitAgentController.dispose();
    _visitAgentTeamLeadController.dispose();
    _ptpAmountController.dispose();
    _newPhoneNumberController.dispose();
    _newAddressController.dispose();
    super.dispose();
  }

  ContactabilityChannel _parseChannel(String channel) {
    switch (channel.toLowerCase()) {
      case 'call':
        return ContactabilityChannel.call;
      case 'message':
        return ContactabilityChannel.message;
      case 'visit':
        return ContactabilityChannel.visit;
      default:
        return ContactabilityChannel.call;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.channel} ${widget.client.name}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ContactabilityController>(
        builder: (context, controller, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildClientInfo(),
                  const SizedBox(height: 24),
                  _buildDateTimeInfo(controller),
                  const SizedBox(height: 20),
                  _buildChannelSection(controller),
                  const SizedBox(height: 20),
                  _buildPersonContactedSection(controller),
                  const SizedBox(height: 20),
                  // Action Location tampil untuk semua channel (Visit, Call, Message)
                  _buildActionLocationSection(controller),
                  const SizedBox(height: 20),
                  if (_selectedChannel == ContactabilityChannel.visit) ...[
                    _buildImageUploadSection(controller),
                    const SizedBox(height: 20),
                  ],
                  if (_selectedChannel == ContactabilityChannel.message) ...[
                    _buildImageUploadSection(controller),
                    const SizedBox(height: 20),
                  ],
                  _buildContactResultSection(controller),
                  const SizedBox(height: 20),
                  _buildPtpFieldsSection(controller),
                  if (_shouldShowPtpFields(controller))
                    const SizedBox(height: 20),
                  _buildVisitNotesSection(),
                  const SizedBox(height: 20),
                  _buildNewPhoneNumberSection(),
                  const SizedBox(height: 20),
                  _buildNewAddressSection(),
                  const SizedBox(height: 24),
                  _buildSubmitButton(controller),
                  if (controller.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _buildErrorMessage(controller.errorMessage!),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClientInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Client Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const CircleAvatar(
                  radius: 25,
                  child: Icon(Icons.person, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.client.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        StringUtils.formatPhone(widget.client.phone),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.client.address,
                        style: TextStyle(color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeInfo(ContactabilityController controller) {
    final timeFormat = DateFormat('HH:mm');
    // Use Jakarta timezone for current time display
    final now =
        controller.contactabilityDateTime ?? TimezoneUtils.nowInJakarta();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contactability Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Date',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        TimezoneUtils.formatIndonesianDate(now),
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Time',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeFormat.format(now),
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (controller.currentLocation != null &&
                _selectedChannel == ContactabilityChannel.visit) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Location',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${controller.currentLocation!.latitude.toStringAsFixed(6)}, ${controller.currentLocation!.longitude.toStringAsFixed(6)}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Klik tombol peta untuk memastikan lokasi sudah tepat',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _refreshLocation(controller),
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh Location',
                        iconSize: 20,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: const EdgeInsets.all(4),
                      ),
                      IconButton(
                        onPressed: () => _openGoogleMaps(controller),
                        icon: const Icon(Icons.map),
                        tooltip: 'Open in Maps',
                        iconSize: 20,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: const EdgeInsets.all(4),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChannelSection(ContactabilityController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Channel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final channel in ContactabilityChannel.values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _buildChannelOption(channel, controller),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelOption(
      ContactabilityChannel channel, ContactabilityController controller) {
    final isSelected = controller.selectedChannel == channel;

    return GestureDetector(
      onTap: () {
        controller.setSelectedChannel(channel);
        setState(() {
          _selectedChannel = channel;

          // Clear images when switching channels if exceeding new limits
          if (channel == ContactabilityChannel.call) {
            // If switching to call (no images allowed), clear all
            controller.clearImages();
          }

          // Reset Action Location ketika berganti channel karena opsi berbeda
          controller.setSelectedActionLocation(null);

          // Reset Contact Result karena opsi berbeda untuk setiap channel
          controller.setSelectedContactResult(null);

          // Reset PTP fields jika ada
          _showPtpFields = false;
          _ptpAmountController.clear();
          _selectedPtpDate = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _getChannelIcon(channel),
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              _getChannelDisplayName(channel),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonContactedSection(ContactabilityController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Person Contacted',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PersonContacted>(
              decoration: const InputDecoration(
                labelText: 'Select Person Contacted',
                border: OutlineInputBorder(),
              ),
              value: controller.selectedPersonContacted,
              items: PersonContacted.values.map((person) {
                return DropdownMenuItem(
                  value: person,
                  child: Text(person.displayName),
                );
              }).toList(),
              onChanged: (person) {
                controller.setSelectedPersonContacted(person);
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select person contacted';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionLocationSection(ContactabilityController controller) {
    // Opsi berbeda berdasarkan channel
    List<ActionLocation> availableLocations;

    if (_selectedChannel == ContactabilityChannel.visit) {
      // Opsi untuk Visit channel
      availableLocations = [
        ActionLocation.alamatKorespondensi,
        ActionLocation.alamatKantor,
        ActionLocation.alamatRumah,
        ActionLocation.alamatKtp,
        ActionLocation.alamatLain,
      ];
    } else if (_selectedChannel == ContactabilityChannel.call ||
        _selectedChannel == ContactabilityChannel.message) {
      // Opsi untuk Call dan Message channel (sama)
      availableLocations = [
        ActionLocation.customerMobile,
        ActionLocation.emergencyContact1,
        ActionLocation.emergencyContact2,
        ActionLocation.office,
        ActionLocation.skipTracingNumber,
        ActionLocation.phoneContact,
      ];
    } else {
      // Default (tidak seharusnya terjadi karena sudah dikondisikan)
      availableLocations = [];
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Action Location',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ActionLocation>(
              decoration: const InputDecoration(
                labelText: 'Select Action Location',
                border: OutlineInputBorder(),
              ),
              value:
                  availableLocations.contains(controller.selectedActionLocation)
                      ? controller.selectedActionLocation
                      : null,
              items: availableLocations.map((location) {
                return DropdownMenuItem(
                  value: location,
                  child: Text(location.displayName),
                );
              }).toList(),
              onChanged: (location) {
                controller.setSelectedActionLocation(location);
              },
              validator: (value) {
                // Required untuk semua channel
                if (value == null) {
                  return 'Please select action location';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactResultSection(ContactabilityController controller) {
    // Opsi berbeda berdasarkan channel
    List<ContactResult> availableResults;

    // Opsi yang selalu ada untuk semua channel
    final commonResults = [
      ContactResult.ptp,
      ContactResult.negotiation,
      ContactResult.hotProspect,
      ContactResult.alreadyPaid,
      ContactResult.refuseToPay,
      ContactResult.dispute,
      ContactResult.notRecognized,
      ContactResult.partialPayment,
      ContactResult.failedToPay,
    ];

    if (_selectedChannel == ContactabilityChannel.visit) {
      // 18 opsi khusus untuk Visit + opsi common
      availableResults = [
        ContactResult.alamatDitemukanRumahKosong,
        ContactResult.dilarangMasukPerumahan,
        ContactResult.dilarangMasukKantor,
        ContactResult.menghindar,
        ContactResult.titipSurat,
        ContactResult.alamatTidakDitemukan,
        ContactResult.alamatSalah,
        ContactResult.konsumenTidakDikenal,
        ContactResult.pindahTidakDitemukan,
        ContactResult.pindahAlamatBaru,
        ContactResult.meninggalDunia,
        ContactResult.mengundurkanDiri,
        ContactResult.berhentiBekerja,
        ContactResult.sedangRenovasi,
        ContactResult.bencanaAlam,
        ContactResult.kondisiMedis,
        ContactResult.sengketaHukum,
        ContactResult.kunjunganUlang,
        ...commonResults,
      ];
    } else if (_selectedChannel == ContactabilityChannel.call) {
      // Hanya opsi common untuk Call
      availableResults = commonResults;
    } else {
      // 7 opsi untuk Message (WA/SP) + opsi common
      availableResults = [
        ContactResult.waOneTick,
        ContactResult.waTwoTick,
        ContactResult.waBlueTick,
        ContactResult.waNotRegistered,
        ContactResult.sp1,
        ContactResult.sp2,
        ContactResult.sp3,
        ...commonResults,
      ];
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Result',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ContactResult>(
              decoration: const InputDecoration(
                labelText: 'Select Contact Result',
                border: OutlineInputBorder(),
              ),
              value: availableResults.contains(controller.selectedContactResult)
                  ? controller.selectedContactResult
                  : null,
              items: availableResults.map((result) {
                return DropdownMenuItem(
                  value: result,
                  child: Text(result.displayName),
                );
              }).toList(),
              onChanged: (result) {
                controller.setSelectedContactResult(result);
                setState(() {
                  _showPtpFields = _shouldShowPtpFields(controller);
                  _hasAttemptedSubmit =
                      false; // Reset submit attempt when changing selection
                  if (!_showPtpFields) {
                    _ptpAmountController.clear();
                    _selectedPtpDate = null;
                  }
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a contact result';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPtpFieldsSection(ContactabilityController controller) {
    if (!_shouldShowPtpFields(controller)) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Promise to Pay (PTP) Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ptpAmountController,
              decoration: const InputDecoration(
                labelText: 'PTP Amount',
                border: OutlineInputBorder(),
                hintText: 'Enter amount',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (_shouldShowPtpFields(
                        context.read<ContactabilityController>()) &&
                    (value == null || value.isEmpty)) {
                  return 'Please enter PTP amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectPtpDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'PTP Date',
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today),
                  errorText: _hasAttemptedSubmit &&
                          _shouldShowPtpFields(
                              context.read<ContactabilityController>()) &&
                          _selectedPtpDate == null
                      ? 'Please select PTP date'
                      : null,
                ),
                child: Text(
                  _selectedPtpDate != null
                      ? TimezoneUtils.formatIndonesianDate(_selectedPtpDate!)
                      : 'Select PTP date',
                  style: TextStyle(
                    color: _selectedPtpDate != null
                        ? Colors.black87
                        : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection(ContactabilityController controller) {
    // Both visit and message channels now support up to 3 images
    final int maxImages = 3;
    final String channelName =
        _selectedChannel == ContactabilityChannel.visit ? 'visit' : 'message';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Images',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Add up to $maxImages ${maxImages == 1 ? 'image' : 'images'} for this $channelName',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const Text(
                  ' *',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Display selected images
            if (controller.selectedImages.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.selectedImages.length,
                  itemBuilder: (context, index) {
                    final image = controller.selectedImages[index];
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              image,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => controller.removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Add image buttons
            Row(
              children: [
                if (controller.selectedImages.length < maxImages) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _pickImage(ImageSource.camera, controller),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[50],
                        foregroundColor: Colors.blue[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _pickImage(ImageSource.gallery, controller),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[50],
                        foregroundColor: Colors.green[700],
                      ),
                    ),
                  ),
                ],
                if (controller.selectedImages.length >= maxImages)
                  Expanded(
                    child: Text(
                      'Maximum $maxImages ${maxImages == 1 ? 'image' : 'images'} reached',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitNotesSection() {
    String title;
    String labelText;
    String hintText;

    switch (_selectedChannel) {
      case ContactabilityChannel.visit:
        title = 'Visit Notes';
        labelText = 'Enter visit notes';
        hintText = 'Describe what happened during the visit...';
        break;
      case ContactabilityChannel.message:
        title = 'Message Content';
        labelText = 'Enter message content';
        hintText = 'Enter the message sent to the client...';
        break;
      case ContactabilityChannel.call:
        title = 'Call Notes';
        labelText = 'Enter call notes';
        hintText = 'Describe what happened during the call...';
        break;
      case null:
        title = 'Notes';
        labelText = 'Enter notes';
        hintText = 'Enter your notes...';
        break;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _visitNotesController,
              decoration: InputDecoration(
                labelText: labelText,
                hintText: hintText,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'This field is required';
                }
                return null;
              },
              onChanged: (value) {
                context.read<ContactabilityController>().setVisitNotes(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewPhoneNumberSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Phone Number',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newPhoneNumberController,
              decoration: const InputDecoration(
                labelText: 'Enter new phone number (optional)',
                hintText: 'New phone number found during contact...',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                context
                    .read<ContactabilityController>()
                    .setNewPhoneNumber(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewAddressSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Address',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newAddressController,
              decoration: const InputDecoration(
                labelText: 'Enter new address (optional)',
                hintText: 'New address found during contact...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              onChanged: (value) {
                context.read<ContactabilityController>().setNewAddress(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ContactabilityController controller) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: controller.isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: controller.isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'Submit Contactability',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red[600]),
            ),
          ),
        ],
      ),
    );
  }

  void _submitForm() async {
    setState(() {
      _hasAttemptedSubmit = true;
    });

    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<ContactabilityController>();

    // Validate required fields
    if (controller.selectedPersonContacted == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select person contacted'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate Action Location untuk semua channel
    if (controller.selectedActionLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select action location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate images for message and visit channels
    if (_selectedChannel == ContactabilityChannel.message ||
        _selectedChannel == ContactabilityChannel.visit) {
      if (controller.selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Please upload at least 1 image for ${_getChannelDisplayName(_selectedChannel!).toLowerCase()}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Validate PTP fields if PTP is selected or Visit Status is Janji Bayar
    if (_shouldShowPtpFields(controller)) {
      if (_ptpAmountController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter PTP amount'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_selectedPtpDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select PTP date'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    controller.clearError();

    final success = await controller.submitContactability(
      ptpAmount:
          _shouldShowPtpFields(controller) ? _ptpAmountController.text : null,
      ptpDate: _shouldShowPtpFields(controller) ? _selectedPtpDate : null,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contactability submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to the client details screen with success result
      // This will trigger the refresh in client_details_screen.dart
      Navigator.pop(context, true);
    } else if (mounted) {
      // Show error message if submission failed
      final errorMessage =
          controller.errorMessage ?? 'Failed to submit contactability';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  IconData _getChannelIcon(ContactabilityChannel channel) {
    switch (channel) {
      case ContactabilityChannel.call:
        return Icons.call;
      case ContactabilityChannel.message:
        return Icons.message;
      case ContactabilityChannel.visit:
        return Icons.location_on;
    }
  }

  String _getChannelDisplayName(ContactabilityChannel channel) {
    switch (channel) {
      case ContactabilityChannel.call:
        return 'Call';
      case ContactabilityChannel.message:
        return 'Message';
      case ContactabilityChannel.visit:
        return 'Visit';
    }
  }

  Future<void> _selectPtpDate() async {
    // Use Jakarta timezone for date selection
    final today = TimezoneUtils.todayInJakarta();
    final maxDate = today.add(const Duration(days: 5)); // 5 days from today

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedPtpDate ?? today,
      firstDate: today, // Can only select from today
      lastDate: maxDate, // Maximum 5 days ahead
      selectableDayPredicate: (DateTime date) {
        // Block Sundays (weekday 7)
        return date.weekday != DateTime.sunday;
      },
    );
    if (picked != null) {
      setState(() {
        _selectedPtpDate = picked;
        _hasAttemptedSubmit =
            false; // Reset submit attempt when user selects a date
      });
    }
  }

  Future<void> _pickImage(
      ImageSource source, ContactabilityController controller) async {
    try {
      // Determine maximum images based on channel
      final int maxImages =
          _selectedChannel == ContactabilityChannel.call ? 0 : 3;

      // Check if maximum limit is reached
      if (controller.selectedImages.length >= maxImages) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Maximum $maxImages ${maxImages == 1 ? 'image' : 'images'} reached'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        controller.addImage(imageFile, maxImages: maxImages);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshLocation(ContactabilityController controller) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 8),
              Text('Refreshing location...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Refresh location through controller
      await controller.refreshLocation();

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location refreshed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openGoogleMaps(ContactabilityController controller) async {
    if (controller.currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final latitude = controller.currentLocation!.latitude;
    final longitude = controller.currentLocation!.longitude;
    final googleMapsUrl = 'https://www.google.com/maps?q=$latitude,$longitude';

    try {
      final Uri url = Uri.parse(googleMapsUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch Google Maps';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open Google Maps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
