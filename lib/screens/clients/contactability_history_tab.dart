import 'package:flutter/material.dart';

class ContactabilityHistoryTab extends StatelessWidget {
  final List<Map<String, String>> contactHistory = [
    {
      'id': '1',
      'clientName': 'John Doet',
      'action': 'Visit',
      'status': 'Completed',
      'timestamp': '2024-01-15 14:30',
      'notes': 'Client was available, discussed product features'
    },
    {
      'id': '2',
      'clientName': 'Jane Smith',
      'action': 'Call',
      'status': 'No Answer',
      'timestamp': '2024-01-15 13:15',
      'notes': 'Phone rang but no answer, will try again later'
    },
    {
      'id': '3',
      'clientName': 'Bob Johnson',
      'action': 'Message',
      'status': 'Replied',
      'timestamp': '2024-01-14 16:45',
      'notes': 'Interested in meeting next week'
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
            'Contactability History',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'All prior conversations/calls with clients',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: contactHistory.length,
            itemBuilder: (context, index) {
              final record = contactHistory[index];
              return Card(
                margin: EdgeInsets.only(bottom: 15),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            record['clientName']!,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: record['status'] == 'Completed' || record['status'] == 'Replied' ? Colors.green[100] : Colors.red[100],
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              record['status']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: record['status'] == 'Completed' || record['status'] == 'Replied' ? Colors.green[800] : Colors.red[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Text(
                        '${record['action']} • ${record['timestamp']}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 10),
                      Text(
                        record['notes']!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[800]),
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