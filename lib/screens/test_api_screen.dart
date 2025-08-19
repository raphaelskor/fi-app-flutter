import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../core/models/client.dart';

class TestSkorcardApiScreen extends StatefulWidget {
  @override
  _TestSkorcardApiScreenState createState() => _TestSkorcardApiScreenState();
}

class _TestSkorcardApiScreenState extends State<TestSkorcardApiScreen> {
  final ApiService _apiService = ApiService();
  List<Client> clients = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _apiService.initialize();
  }

  Future<void> _testApi() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      clients.clear();
    });

    try {
      final clientsData = await _apiService.fetchSkorcardClients('Skorcard');

      setState(() {
        clients = clientsData
            .map((clientData) => Client.fromSkorcardApi(clientData))
            .toList();
        isLoading = false;
      });

      print('✅ API Success: Found ${clients.length} clients');
      for (var client in clients) {
        print('Client: ${client.name} - ${client.phone} - ${client.address}');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
      print('❌ API Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Skorcard API'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: isLoading ? null : _testApi,
              child: Text(isLoading ? 'Loading...' : 'Test Skorcard API'),
            ),
            SizedBox(height: 20),
            if (errorMessage != null)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Error: $errorMessage',
                  style: TextStyle(color: Colors.red[800]),
                ),
              ),
            if (isLoading) CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Found ${clients.length} clients:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: clients.length,
                itemBuilder: (context, index) {
                  final client = clients[index];
                  return Card(
                    child: ListTile(
                      title: Text(client.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Phone: ${client.phone}'),
                          Text('Address: ${client.address}'),
                          Text('Status: ${client.status}'),
                          Text('ID: ${client.id}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
