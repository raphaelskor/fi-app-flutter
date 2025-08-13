import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  final List<String> visitActions = ['OPC', 'RPC', 'TPC'];
  final List<String> visitStatuses = ['Negosiasi', 'Menghindar', 'Sudah Bayar'];
  final List<String> channelResults = ['Delivered', 'Read', 'Sent', 'Visit'];
  final List<String> contactResults = ['Dispute', 'Refuse to Pay', 'PTP', 'No Promise', 'Negotiation'];
  final List<String> visitLocations = ['Tempat Kerja', 'Tempat Lain', 'Tempat Tinggal'];

  @override
  Widget build(BuildContext context) {
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
              
              SizedBox(height: 20),
              Text('Photos (Max 3)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              // Dummy photo upload area
              Container(
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Text('Tap to add photos (Dummy)')), // Placeholder for photo upload
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
                  });
                },
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
                      print('Visit Action: $selectedVisitAction');
                      print('Visit Status: $selectedVisitStatus');
                      print('Channel Result: $selectedChannelResult');
                      print('Contact Result: $selectedContactResult');
                      print('Visit Location: $selectedVisitLocation');
                      
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
