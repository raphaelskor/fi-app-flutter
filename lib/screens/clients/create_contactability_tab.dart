import 'package:flutter/material.dart';

class CreateContactabilityTab extends StatelessWidget {
  final List<Map<String, String>> todaysClients = [
    {
      'id': '1',
      'name': 'John Doe',
      'address': 'Jl. Sudirman No. 123, Jakarta',
      'phone': '+62 812-3456-7890',
      'distance': '2.5 km',
      'status': 'pending'
    },
    {
      'id': '2',
      'name': 'Jane Smith',
      'address': 'Jl. Thamrin No. 456, Jakarta',
      'phone': '+62 821-9876-5432',
      'distance': '1.8 km',
      'status': 'contacted'
    },
    {
      'id': '3',
      'name': 'Bob Johnson',
      'address': 'Jl. Gatot Subroto No. 789, Jakarta',
      'phone': '+62 813-1111-2222',
      'distance': '3.2 km',
      'status': 'visited'
    }
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Client List',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Optimized by distance',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: todaysClients.length,
            itemBuilder: (context, index) {
              final client = todaysClients[index];
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
                            client['name']!,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: client['status'] == 'pending' ? Colors.orange[100] : (client['status'] == 'contacted' ? Colors.blue[100] : Colors.green[100]),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              client['status']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: client['status'] == 'pending' ? Colors.orange[800] : (client['status'] == 'contacted' ? Colors.blue[800] : Colors.green[800]),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Text(
                        client['address']!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 5),
                      Text(
                        client['phone']!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                          SizedBox(width: 5),
                          Text(
                            client['distance']!,
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: Icon(Icons.call, size: 18),
                            label: Text('Call'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: Icon(Icons.message, size: 18),
                            label: Text('Message'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: Icon(Icons.location_on, size: 18),
                            label: Text('Visit'),
                          ),
                        ],
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

