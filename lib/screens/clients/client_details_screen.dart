import 'package:flutter/material.dart';
import '../contactability_form_screen.dart';

class ClientDetailsScreen extends StatefulWidget {
  final Map<String, String> client;

  ClientDetailsScreen({required this.client});

  @override
  _ClientDetailsScreenState createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> with SingleTickerProviderStateMixin {
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
                _tabController.animateTo(1); // Switch to Client Contactability tab
              }
            },
            label: Text('Call'),
            icon: Icon(Icons.call),
            backgroundColor: Colors.green,
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
                _tabController.animateTo(1); // Switch to Client Contactability tab
              }
            },
            label: Text('Message'),
            icon: Icon(Icons.message),
            backgroundColor: Colors.orange,
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
                _tabController.animateTo(1); // Switch to Client Contactability tab
              }
            },
            label: Text('Visit'),
            icon: Icon(Icons.location_on),
            backgroundColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildClientDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('User ID', widget.client['id']!),
          _buildDetailRow('Name', widget.client['name']!),
          _buildDetailRow('Mobile', widget.client['phone']!),
          _buildDetailRow('DPD Bucket', 'N/A'), // Dummy
          _buildDetailRow('DPD', 'N/A'), // Dummy
          _buildDetailRow('Gender', 'Male'), // Dummy
          _buildDetailRow('Date of Birth', '1990-01-01'), // Dummy
          _buildDetailRow('Marital Status', 'Single'), // Dummy
          _buildDetailRow('KTP Address', 'Jl. KTP No. 123'), // Dummy
          _buildDetailRow('Home Address', widget.client['address']!),
          _buildDetailRow('Office Address', 'Jl. Office No. 456'), // Dummy
          _buildDetailRow('Office Name', 'PT Dummy Jaya'), // Dummy
          _buildDetailRow('Job Status', 'Employed'), // Dummy
          _buildDetailRow('Job Position', 'Manager'), // Dummy
          _buildDetailRow('Length of Work', '5 Years'), // Dummy
          _buildDetailRow('Mother Name', 'Ny. Dummy'), // Dummy
          _buildDetailRow('TAD', 'N/A'), // Dummy
          _buildDetailRow('MAD', 'N/A'), // Dummy
          _buildDetailRow('Agent Name', 'Agent Smith'), // Dummy
          _buildDetailRow('Agent Email', 'agent.smith@example.com'), // Dummy
        ],
      ),
    );
  }

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
