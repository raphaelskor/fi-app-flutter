import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/services/auth_service.dart';
import '../../core/services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Real attendance data from API
  Map<DateTime, String> attendanceMap = {};
  bool isLoadingAttendance = true;
  String? selectedAttendance;
  bool submittedToday = false;
  bool isSubmittingAttendance = false;
  final ApiService _apiService = ApiService();

  DateTime today = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAttendanceHistory();
    });
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Future<void> _fetchAttendanceHistory({bool forceRefresh = false}) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userData = authService.userData;

      if (userData == null || userData['id'] == null) {
        setState(() {
          isLoadingAttendance = false;
        });
        return;
      }

      // Use ApiService with caching
      final responseList = await _apiService.getAttendanceHistory(
        userId: userData['id'].toString(),
        forceRefresh: forceRefresh,
      );

      setState(() {
        attendanceMap.clear();

        if (responseList.isNotEmpty) {
          for (var item in responseList) {
            if (item['date'] != null && item['attendance'] != null) {
              DateTime date = DateTime.parse(item['date']);
              String attendance = item['attendance'].toString();

              // Convert attendance status to single letter
              String status = _convertAttendanceToStatus(attendance);
              attendanceMap[_dateOnly(date)] = status;
            }
          }
        }
        // If data is empty, attendanceMap will remain empty
        // This is normal behavior, not an error

        // Check if user has submitted today
        final todayKey = _dateOnly(today);
        submittedToday = attendanceMap.containsKey(todayKey);
        selectedAttendance = attendanceMap[todayKey];
        isLoadingAttendance = false;

        // Debug log to check if today's attendance is found
        print(
            'Today: $todayKey, Submitted: $submittedToday, Attendance: $selectedAttendance');
        print('All attendance data: $attendanceMap');
        print('Data received from API: ${responseList.length} records');
      });
    } catch (e) {
      print('❌ Exception in _fetchAttendanceHistory: $e');
      setState(() {
        isLoadingAttendance = false;
      });

      // Only show error to user if it's a network error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading attendance: $e')),
        );
      }
    }
  }

  /// Manual refresh method for pull-to-refresh
  Future<void> _refreshAttendance() async {
    await _fetchAttendanceHistory(forceRefresh: true);
  }

  String _convertAttendanceToStatus(String attendance) {
    switch (attendance.toLowerCase()) {
      case 'hadir':
        return 'H';
      case 'izin':
        return 'I';
      case 'sakit':
        return 'S';
      case 'alpha':
        return 'A';
      default:
        return 'A';
    }
  }

  String _convertStatusToAttendance(String status) {
    switch (status) {
      case 'H':
        return 'Hadir';
      case 'I':
        return 'Izin';
      case 'S':
        return 'Sakit';
      case 'A':
        return 'Alpha';
      default:
        return 'Alpha';
    }
  }

  Future<void> _submitAttendance() async {
    if (selectedAttendance == null) return;

    // Check if already submitted today to prevent multiple submissions
    if (submittedToday) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance already submitted for today'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      isSubmittingAttendance = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userData = authService.userData;

      if (userData == null || userData['id'] == null) {
        throw Exception('User data not available');
      }

      final attendanceText = _convertStatusToAttendance(selectedAttendance!);

      print(
          '🔄 Submitting attendance: $attendanceText for user: ${userData['id']}');
      print('📅 Date: ${_dateOnly(today)}');

      final response = await http.post(
        Uri.parse(
            'https://n8n.skorcard.app/webhook/491ba156-a378-4d24-aaf8-bcd2d4ddd235'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': userData['id'],
          'attendance': attendanceText,
        }),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Update local state immediately
        setState(() {
          attendanceMap[_dateOnly(today)] = selectedAttendance!;
          submittedToday = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Attendance submitted successfully: $attendanceText'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Refresh attendance history to get the updated data from server
        // Wait a bit to ensure the server has processed the submission
        await Future.delayed(Duration(milliseconds: 500));
        await _fetchAttendanceHistory();
      } else {
        throw Exception(
            'Failed to submit attendance. Server responded with status: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isSubmittingAttendance = false;
      });
    }
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

    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final userData = authService.userData;

        return Scaffold(
          appBar: AppBar(
            title: Text('Profile'),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: () async {
                  await Provider.of<AuthService>(context, listen: false)
                      .logout();
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refreshAttendance,
            child: SingleChildScrollView(
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
                          userData?['name'] ?? 'Unknown User',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          userData?['role'] ?? 'Unknown Role',
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[600]),
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
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          _buildInfoRow(Icons.email, 'Email',
                              userData?['email'] ?? 'N/A'),
                          _buildInfoRow(Icons.phone, 'Mobile',
                              userData?['mobile'] ?? 'N/A'),
                          _buildInfoRow(
                              Icons.group, 'Team', userData?['team'] ?? 'N/A'),
                          _buildInfoRow(
                              Icons.badge, 'Role', userData?['role'] ?? 'N/A'),
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
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          if (isLoadingAttendance)
                            Center(
                              child: Column(
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 10),
                                  Text('Loading attendance data...'),
                                ],
                              ),
                            )
                          else if (!submittedToday)
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
                                    DropdownMenuItem(
                                        value: 'I', child: Text('Izin')),
                                    DropdownMenuItem(
                                        value: 'S', child: Text('Sakit')),
                                    DropdownMenuItem(
                                        value: 'A', child: Text('Alpha')),
                                  ],
                                  onChanged: isSubmittingAttendance
                                      ? null
                                      : (val) {
                                          setState(() {
                                            selectedAttendance = val;
                                          });
                                        },
                                ),
                                SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: (selectedAttendance == null ||
                                          isSubmittingAttendance)
                                      ? null
                                      : _submitAttendance,
                                  child: isSubmittingAttendance
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2),
                                            ),
                                            SizedBox(width: 8),
                                            Text('Submitting...'),
                                          ],
                                        )
                                      : Text('Submit'),
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
                                  backgroundColor:
                                      _statusColor(selectedAttendance),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Attendance History (1 Bulan Terakhir)',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              if (isLoadingAttendance)
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              else
                                IconButton(
                                  icon: Icon(Icons.refresh),
                                  onPressed: _fetchAttendanceHistory,
                                  tooltip: 'Refresh attendance history',
                                ),
                            ],
                          ),
                          SizedBox(height: 10),
                          if (isLoadingAttendance)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 10),
                                    Text('Loading attendance history...'),
                                  ],
                                ),
                              ),
                            )
                          else if (attendanceMap.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Belum ada data attendance',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Submit attendance hari ini untuk mulai tracking',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            TableCalendar(
                              firstDay: firstDay,
                              lastDay: lastDay,
                              focusedDay: today,
                              calendarFormat: CalendarFormat.month,
                              headerStyle: HeaderStyle(
                                  formatButtonVisible: false,
                                  titleCentered: true),
                              daysOfWeekStyle: DaysOfWeekStyle(
                                  weekdayStyle:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              calendarBuilders: CalendarBuilders(
                                defaultBuilder: (context, day, focusedDay) {
                                  final status = attendanceMap[_dateOnly(day)];
                                  if (status != null) {
                                    return Center(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _statusColor(status)
                                              .withOpacity(0.2),
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
                          if (!isLoadingAttendance &&
                              attendanceMap.isNotEmpty) ...[
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
