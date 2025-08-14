import 'package:flutter/material.dart';
import '../contactability_form_screen.dart';

class ClientDetailsScreen extends StatefulWidget {
  final Map<String, String> client;

  ClientDetailsScreen({required this.client});

  @override
  _ClientDetailsScreenState createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.client['name']!),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Client Details'),
            Tab(text: 'Client Contactability'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildClientDetailsTab(),
          _buildClientContactabilityTab(),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'callBtn',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContactabilityFormScreen(
                    clientName: widget.client['name']!,
                    channel: 'Call',
                  ),
                ),
              );
              if (result == 'contactability') {
                _tabController
                    .animateTo(1); // Switch to Client Contactability tab
              }
            },
            label: Text('Call'),
            icon: Icon(Icons.call),
            backgroundColor: Colors.white,
          ),
          SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'messageBtn',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContactabilityFormScreen(
                    clientName: widget.client['name']!,
                    channel: 'Message',
                  ),
                ),
              );
              if (result == 'contactability') {
                _tabController
                    .animateTo(1); // Switch to Client Contactability tab
              }
            },
            label: Text('Message'),
            icon: Icon(Icons.message),
            backgroundColor: Colors.white,
          ),
          SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'visitBtn',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContactabilityFormScreen(
                    clientName: widget.client['name']!,
                    channel: 'Visit',
                  ),
                ),
              );
              if (result == 'contactability') {
                _tabController
                    .animateTo(1); // Switch to Client Contactability tab
              }
            },
            label: Text('Visit'),
            icon: Icon(Icons.location_on),
            backgroundColor: Colors.white,
          ),
        ],
      ),
    );
  }

  // ...existing code...

  Widget _buildClientDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    child: Icon(Icons.person, size: 36),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.client['name']!,
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text(widget.client['phone']!,
                            style: TextStyle(color: Colors.grey[700])),
                        SizedBox(height: 4),
                        Text(widget.client['address']!,
                            style: TextStyle(color: Colors.grey[700])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Text('Personal Info',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  _iconDetailRow(Icons.badge, 'User ID', widget.client['id']!),
                  _iconDetailRow(Icons.cake, 'Date of Birth', '1990-01-01'),
                  _iconDetailRow(Icons.person_outline, 'Gender', 'Male'),
                  _iconDetailRow(
                      Icons.family_restroom, 'Marital Status', 'Single'),
                  _iconDetailRow(Icons.home, 'KTP Address', 'Jl. KTP No. 123'),
                  _iconDetailRow(Icons.home_work, 'Home Address',
                      widget.client['address']!),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Text('Job Info',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  _iconDetailRow(
                      Icons.business, 'Office Name', 'PT Dummy Jaya'),
                  _iconDetailRow(Icons.location_city, 'Office Address',
                      'Jl. Office No. 456'),
                  _iconDetailRow(Icons.work, 'Job Status', 'Employed'),
                  _iconDetailRow(Icons.work_outline, 'Job Position', 'Manager'),
                  _iconDetailRow(Icons.timer, 'Length of Work', '5 Years'),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Text('Other Info',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  _iconDetailRow(Icons.person, 'Mother Name', 'Ny. Dummy'),
                  _iconDetailRow(Icons.info_outline, 'DPD Bucket', 'N/A'),
                  _iconDetailRow(Icons.info_outline, 'DPD', 'N/A'),
                  _iconDetailRow(Icons.info_outline, 'TAD', 'N/A'),
                  _iconDetailRow(Icons.info_outline, 'MAD', 'N/A'),
                  _iconDetailRow(Icons.person, 'Agent Name', 'Agent Smith'),
                  _iconDetailRow(
                      Icons.email, 'Agent Email', 'agent.smith@example.com'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 20),
          SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

// ...existing code...

  Widget _buildClientContactabilityTab() {
    final List<Map<String, String>> clientContactabilityHistory = [
      {
        'id': '1',
        'action': 'Visit',
        'status': 'Completed',
        'timestamp': '2024-01-10 10:00',
        'notes': 'Initial visit, discussed terms.',
        'channel': 'Visit'
      },
      {
        'id': '2',
        'action': 'Call',
        'status': 'No Answer',
        'timestamp': '2024-01-11 14:30',
        'notes': 'Tried calling, no response.',
        'channel': 'Call'
      },
      {
        'id': '3',
        'action': 'Message',
        'status': 'Replied',
        'timestamp': '2024-01-12 09:15',
        'notes': 'Client replied, set up next meeting.',
        'channel': 'Message'
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contactability History for ${widget.client['name']}',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: clientContactabilityHistory.length,
            itemBuilder: (context, index) {
              final record = clientContactabilityHistory[index];
              return Card(
                margin: EdgeInsets.only(bottom: 10),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${record['action']} - ${record['status']}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      Text(record['timestamp']!),
                      Text(record['notes']!),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
