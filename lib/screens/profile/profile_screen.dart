import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Map<String, String> userInfo = {
    'name': 'Field Investigator 007',
    'email': 'fi.007@example.com',
    'role': 'Field Investigator',
    'team': 'Alpha Team',
  };

  // Dummy data attendance 2 minggu terakhir (rotasi H/I/S/A)
  Map<DateTime, String> attendanceMap = {};

  String? selectedAttendance;
  bool submittedToday = false;

  DateTime today = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Generate dummy data untuk 14 hari terakhir
    for (int i = 0; i < 14; i++) {
      DateTime date = _dateOnly(today.subtract(Duration(days: i)));
      String status;
      switch (i % 4) {
        case 0:
          status = 'H';
          break;
        case 1:
          status = 'I';
          break;
        case 2:
          status = 'S';
          break;
        default:
          status = 'A';
      }
      attendanceMap[date] = status;
    }
    // Cek apakah sudah submit hari ini
    submittedToday = attendanceMap.containsKey(_dateOnly(today));
    selectedAttendance = attendanceMap[_dateOnly(today)];
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  void _submitAttendance() {
    final now = DateTime.now();
    final deadline = DateTime(now.year, now.month, now.day, 8, 0, 0);
    String status = selectedAttendance ?? 'A';

    if (now.isAfter(deadline)) {
      status = 'A'; // Alpha jika lewat jam 8 pagi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terlambat submit, otomatis Alpha')),
      );
    }

    setState(() {
      attendanceMap[_dateOnly(now)] = status;
      submittedToday = true;
      selectedAttendance = status;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Attendance hari ini: ${_statusLabel(status)}')),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'H':
        return Colors.green;
      case 'I':
        return Colors.orange;
      case 'S':
        return Colors.blue;
      case 'A':
      default:
        return Colors.red;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'H':
        return 'Hadir';
      case 'I':
        return 'Izin';
      case 'S':
        return 'Sakit';
      case 'A':
      default:
        return 'Alpha';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil tanggal 1 bulan terakhir
    final firstDay = today.subtract(Duration(days: 29));
    final lastDay = today;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthService>(context, listen: false).logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.person, size: 60),
                  ),
                  SizedBox(height: 10),
                  Text(
                    userInfo['name']!,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    userInfo['role']!,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Information',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    _buildInfoRow(Icons.email, 'Email', userInfo['email']!),
                    _buildInfoRow(Icons.group, 'Team', userInfo['team']!),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Submit Attendance Hari Ini',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    if (!submittedToday)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Status Kehadiran',
                              border: OutlineInputBorder(),
                            ),
                            value: selectedAttendance,
                            items: [
                              DropdownMenuItem(
                                  value: 'H', child: Text('Hadir')),
                              DropdownMenuItem(value: 'I', child: Text('Izin')),
                              DropdownMenuItem(
                                  value: 'S', child: Text('Sakit')),
                              DropdownMenuItem(
                                  value: 'A', child: Text('Alpha')),
                            ],
                            onChanged: (val) {
                              setState(() {
                                selectedAttendance = val;
                              });
                            },
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: selectedAttendance == null
                                ? null
                                : _submitAttendance,
                            child: Text('Submit'),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Text(
                            'Sudah submit hari ini: ',
                            style: TextStyle(fontSize: 16),
                          ),
                          Chip(
                            label: Text(_statusLabel(selectedAttendance)),
                            backgroundColor: _statusColor(selectedAttendance),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance History (1 Bulan Terakhir)',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    TableCalendar(
                      firstDay: firstDay,
                      lastDay: lastDay,
                      focusedDay: today,
                      calendarFormat: CalendarFormat.month,
                      headerStyle: HeaderStyle(
                          formatButtonVisible: false, titleCentered: true),
                      daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: TextStyle(fontWeight: FontWeight.bold)),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          final status = attendanceMap[_dateOnly(day)];
                          if (status != null) {
                            return Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _statusColor(status).withOpacity(0.2),
                                ),
                                width: 35,
                                height: 35,
                                child: Center(
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: _statusColor(status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _legend('Hadir', Colors.green, 'H'),
                        _legend('Izin', Colors.orange, 'I'),
                        _legend('Sakit', Colors.blue, 'S'),
                        _legend('Alpha', Colors.red, 'A'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(String label, Color color, String code) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
              color: color.withOpacity(0.2), shape: BoxShape.circle),
          child: Center(
            child: Text(code,
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ),
        ),
        SizedBox(width: 5),
        Text(label),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 20),
          SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 16, color: Colors.grey[800]),
          ),
        ],
      ),
    );
  }
}
