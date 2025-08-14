import 'package:flutter/material.dart';

class HistoryListTab extends StatelessWidget {
  final List<Map<String, String>> historyList = [
    {
      'id': '1',
      'date': '2024-01-15',
      'client': 'John Doe',
      'channel': 'Visit',
      'status': 'Completed',
      'notes': 'Successful product demonstration',
      'time': '14:30'
    },
    {
      'id': '2',
      'date': '2024-01-15',
      'client': 'Jane Smith',
      'channel': 'Call',
      'status': 'No Answer',
      'notes': 'Will try again tomorrow',
      'time': '13:15'
    },
    {
      'id': '3',
      'date': '2024-01-14',
      'client': 'Bob Johnson',
      'channel': 'Message',
      'status': 'Replied',
      'notes': 'Interested in meeting next week',
      'time': '16:45'
    },
    {
      'id': '4',
      'date': '2024-01-14',
      'client': 'Alice Brown',
      'channel': 'Visit',
      'status': 'Completed',
      'notes': 'Signed contract',
      'time': '11:20'
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
            'My History (All-Time)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'All contactability made by you',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final record = historyList[index];
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
                            record['client']!,
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
                        '${record['channel']} • ${record['date']} ${record['time']}',
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

