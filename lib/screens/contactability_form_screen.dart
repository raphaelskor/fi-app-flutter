import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart'; // For FilteringTextInputFormatter
import 'package:provider/provider.dart'; // For accessing AuthService
import 'package:field_investigator_app/services/auth_service.dart'; // Import AuthService

class ContactabilityFormScreen extends StatefulWidget {
  final String clientName;
  final String channel;

  ContactabilityFormScreen({required this.clientName, required this.channel});

  @override
  _ContactabilityFormScreenState createState() => _ContactabilityFormScreenState();
}

class _ContactabilityFormScreenState extends State<ContactabilityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  List<String> photos = []; // Dummy for photos
  String? selectedVisitAction;
  String? selectedVisitStatus;
  String? selectedChannelResult;
  String? selectedContactResult;
  String? selectedVisitLocation;

  DateTime? _ptpDate; // New state for PTP Date
  final TextEditingController _ptpAmountController = TextEditingController(); // New controller for PTP Amount

  final List<String> visitActions = ['OPC', 'RPC', 'TPC'];
  final List<String> visitStatuses = ['Negosiasi', 'Menghindar', 'Sudah Bayar'];
  final List<String> channelResults = ['Delivered', 'Read', 'Sent', 'Visit'];
  final List<String> contactResults = ['Dispute', 'Refuse to Pay', 'PTP', 'No Promise', 'Negotiation'];
  final List<String> visitLocations = ['Tempat Kerja', 'Tempat Lain', 'Tempat Tinggal'];

  @override
  void initState() {
    super.initState();
    // _getCurrentLocation(); // Moved to AuthService
  }

  @override
  void dispose() {
    _ptpAmountController.dispose();
    super.dispose();
  }

  Future<void> _launchMapUrl(double latitude, double longitude) async {
    final String googleMapsUrl = 'https://maps.google.com/?q=$latitude,$longitude';
    final Uri uri = Uri.parse(googleMapsUrl );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback for web or if direct app launch fails
        final String webUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
        final Uri webUri = Uri.parse(webUrl );
        if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri, mode: LaunchMode.externalApplication); // Use externalApplication for web
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch Google Maps or web browser.')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error launching map: $e')),
      );
    }
  }

  Future<void> _selectPTPDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _ptpDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(Duration(days: 5)), // Max 5 days from today
    );
    if (picked != null && picked != _ptpDate) {
      setState(() {
        _ptpDate = picked;
      });
    }
  }

  // Dummy function for adding photos
  void _addPhoto() {
    if (photos.length < 3) {
      setState(() {
        photos.add('photo_${photos.length + 1}.jpg'); // Add a dummy photo name
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dummy photo added! Total: ${photos.length}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum 3 photos allowed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    String currentLocation = authService.currentLocation ?? 'Getting location...';
    double? latitude = authService.latitude;
    double? longitude = authService.longitude;

    String contactabilityDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String contactabilityTime = DateFormat('HH:mm:ss').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text('Contactability Form'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoField('Client Name', widget.clientName),
              _buildInfoField('Contactability Date', contactabilityDate),
              _buildInfoField('Contactability Time', contactabilityTime),
              _buildInfoField('Channel', widget.channel),
              _buildGeolocationField('Geolocation', currentLocation, latitude, longitude), // Modified Geolocation field
              
              SizedBox(height: 20),
              Text('Photos (Max 3)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              // Dummy photo upload area
              GestureDetector(
                onTap: _addPhoto,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: photos.isEmpty
                        ? Text('Tap to add photos (Dummy)')
                        : Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: photos.map((photo) => Chip(label: Text(photo))).toList(),
                          ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              _buildDropdownField(
                'Visit Action',
                visitActions,
                selectedVisitAction,
                (value) {
                  setState(() {
                    selectedVisitAction = value;
                  });
                },
              ),
              _buildDropdownField(
                'Visit Status',
                visitStatuses,
                selectedVisitStatus,
                (value) {
                  setState(() {
                    selectedVisitStatus = value;
                  });
                },
              ),
              _buildDropdownField(
                'Channel Result',
                channelResults,
                selectedChannelResult,
                (value) {
                  setState(() {
                    selectedChannelResult = value;
                  });
                },
              ),
              _buildDropdownField(
                'Contact Result',
                contactResults,
                selectedContactResult,
                (value) {
                  setState(() {
                    selectedContactResult = value;
                    // Reset PTP fields if PTP is not selected
                    if (value != 'PTP') {
                      _ptpDate = null;
                      _ptpAmountController.clear();
                    }
                  });
                },
              ),

              if (selectedContactResult == 'PTP') // Conditionally show PTP fields
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    Text(
                      'PTP Date',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: _ptpDate == null ? '' : DateFormat('yyyy-MM-dd').format(_ptpDate!),
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Select PTP Date',
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () => _selectPTPDate(context),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select PTP Date';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    Text(
                      'PTP Amount',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _ptpAmountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter PTP Amount',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter PTP Amount';
                        }
                        return null;
                      },
                    ),
                  ],
                ),

              _buildDropdownField(
                'Visit Location',
                visitLocations,
                selectedVisitLocation,
                (value) {
                  setState(() {
                    selectedVisitLocation = value;
                  });
                },
              ),

              SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Process data (currently dummy)
                      print('Form Submitted!');
                      print('Client: ${widget.clientName}');
                      print('Channel: ${widget.channel}');
                      print('Geolocation: $currentLocation');
                      print('Visit Action: $selectedVisitAction');
                      print('Visit Status: $selectedVisitStatus');
                      print('Channel Result: $selectedChannelResult');
                      print('Contact Result: $selectedContactResult');
                      if (selectedContactResult == 'PTP') {
                        print('PTP Date: ${_ptpDate?.toIso8601String()}');
                        print('PTP Amount: ${_ptpAmountController.text}');
                      }
                      print('Visit Location: $selectedVisitLocation');
                      print('Photos: ${photos.join(', ')}');
                      
                      // Navigate back to Client Contactability tab
                      Navigator.pop(context, 'contactability'); // Pass a result to indicate which tab to show
                    }
                  },
                  child: Text('Submit Contactability'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGeolocationField(String label, String value, double? lat, double? long) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              if (lat != null && long != null) // Only show button if location is available
                IconButton(
                  icon: Icon(Icons.map, color: Colors.blue),
                  onPressed: () => _launchMapUrl(lat, long),
                  tooltip: 'Open in Google Maps',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> items, String? selectedValue, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedValue,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            hint: Text('Select $label'),
            onChanged: onChanged,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a $label';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
