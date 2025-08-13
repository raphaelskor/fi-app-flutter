import 'package:flutter/material.dart';

class ContactabilityHistoryTab extends StatelessWidget {
  final List<Map<String, String>> allClientsContactability = [
    {
      'id': '1',
      'name': 'John Doe',
      'action': 'Visit',
      'status': 'Completed',
      'timestamp': '2024-01-10 10:00',
      'notes': 'Initial visit, discussed terms.',
      'channel': 'Visit'
    },
    {
      'id': '2',
      'name': 'Jane Smith',
      'action': 'Call',
      'status': 'No Answer',
      'timestamp': '2024-01-11 14:30',
      'notes': 'Tried calling, no response.',
      'channel': 'Call'
    },
    {
      'id': '3',
      'name': 'Bob Johnson',
      'action': 'Message',
      'status': 'Replied',
      'timestamp': '2024-01-12 09:15',
      'notes': 'Client replied, set up next meeting.',
      'channel': 'Message'
    },
    {
      'id': '4',
      'name': 'John Doe',
      'action': 'Call',
      'status': 'PTP Set',
      'timestamp': '2024-01-13 11:00',
      'notes': 'Client agreed to pay next week.',
      'channel': 'Call'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Clients Contactability History',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Comprehensive history of all contact attempts.',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: allClientsContactability.length,
            itemBuilder: (context, index) {
              final record = allClientsContactability[index];
              return Card(
                margin: EdgeInsets.only(bottom: 10),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${record['name']} - ${record['action']} (${record['channel']})',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Status: ${record['status']}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      Text(
                        'Timestamp: ${record['timestamp']}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      Text(
                        'Notes: ${record['notes']}',
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[800]),
                      ),
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
}
