import 'package:flutter/material.dart';

class SkipTracing {
  final String id;
  final String userName;
  final String userId;
  final String source;
  final String mobile;
  final String? mobileStatus;
  final DateTime createdTime;

  SkipTracing({
    required this.id,
    required this.userName,
    required this.userId,
    required this.source,
    required this.mobile,
    this.mobileStatus,
    required this.createdTime,
  });

  factory SkipTracing.fromJson(Map<String, dynamic> json) {
    return SkipTracing(
      id: json['id'] ?? '',
      userName: json['User_ID']?['name'] ?? 'N/A',
      userId: json['User_ID']?['id'] ?? '',
      source: json['Source'] ?? 'N/A',
      mobile: json['Mobile'] ?? 'N/A',
      mobileStatus: json['Mobile_Status'],
      createdTime: json['Created_Time'] != null
          ? DateTime.parse(json['Created_Time'])
          : DateTime.now(),
    );
  }

  String get formattedMobile {
    // Format phone number: +62895628235082 -> 0895628235082
    String formatted = mobile.replaceAll(RegExp(r'[^\d]'), '');
    if (formatted.startsWith('62')) {
      formatted = '0${formatted.substring(2)}';
    } else if (!formatted.startsWith('0')) {
      formatted = '0$formatted';
    }
    return formatted;
  }

  String get mobileStatusDisplay {
    return mobileStatus ?? 'Unknown';
  }

  Color get mobileStatusColor {
    switch (mobileStatus?.toLowerCase()) {
      case 'live':
        return const Color(0xFF4CAF50); // Green
      case 'dormant':
        return const Color(0xFFFF9800); // Orange
      case 'dead':
        return const Color(0xFFF44336); // Red
      case 'roaming':
        return const Color(0xFF2196F3); // Blue
      case 'data usage only':
        return const Color(0xFF9C27B0); // Purple
      case 'not valid':
        return const Color(0xFF757575); // Grey
      default:
        return const Color(0xFF9E9E9E); // Default Grey
    }
  }
}
