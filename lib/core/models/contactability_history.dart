class ContactabilityHistory {
  final String id;
  final String skorUserId;
  final String name;
  final String channel;
  final String? status;
  final String? result;
  final String? notes;
  final String? visitLocation;
  final String? visitAgent;
  final String? visitLatLong;
  final DateTime createdTime;
  final DateTime? modifiedTime;
  final DateTime? visitDate;
  final String? dpdbucket;
  final String? contactResult;
  final String? messageSentFor;
  final String? deliveredTimeIfAny;
  final String? readTimeIfAny;
  final Map<String, dynamic> rawData;

  ContactabilityHistory({
    required this.id,
    required this.skorUserId,
    required this.name,
    required this.channel,
    this.status,
    this.result,
    this.notes,
    this.visitLocation,
    this.visitAgent,
    this.visitLatLong,
    required this.createdTime,
    this.modifiedTime,
    this.visitDate,
    this.dpdbucket,
    this.contactResult,
    this.messageSentFor,
    this.deliveredTimeIfAny,
    this.readTimeIfAny,
    required this.rawData,
  });

  factory ContactabilityHistory.fromSkorcardApi(Map<String, dynamic> json) {
    DateTime createdTime = DateTime.now();
    DateTime? modifiedTime;
    DateTime? visitDate;

    try {
      if (json['Created_Time'] != null) {
        createdTime = DateTime.parse(json['Created_Time']);
      }
      if (json['Modified_Time'] != null) {
        modifiedTime = DateTime.parse(json['Modified_Time']);
      }
      if (json['Visit_Date'] != null) {
        visitDate = DateTime.parse(json['Visit_Date']);
      }
    } catch (e) {
      print('Error parsing dates in ContactabilityHistory: $e');
    }

    // Determine the actual result/status based on the channel and available data
    String result = _determineResult(json);
    String notes = _extractNotes(json);

    return ContactabilityHistory(
      id: json['id']?.toString() ?? '',
      skorUserId: json['Skor_User_ID']?.toString() ?? '',
      name: json['Name']?.toString() ?? '',
      channel: json['Channel']?.toString() ?? '',
      status: json['Visit_Status']?.toString(),
      result: result,
      notes: notes,
      visitLocation: json['Visit_Location']?.toString(),
      visitAgent: json['Visit_Agent']?.toString(),
      visitLatLong: json['Visit_Lat_Long']?.toString(),
      createdTime: createdTime,
      modifiedTime: modifiedTime,
      visitDate: visitDate,
      dpdbucket: json['DPD_Bucket']?.toString(),
      contactResult: json['Contact_Result']?.toString(),
      messageSentFor: json['Message_Sent_For']?.toString(),
      deliveredTimeIfAny: json['Delivered_Time_If_Any']?.toString(),
      readTimeIfAny: json['Read_Time_If_Any']?.toString(),
      rawData: json,
    );
  }

  static String _determineResult(Map<String, dynamic> json) {
    final String name = json['Name']?.toString() ?? '';
    final String channel = json['Channel']?.toString() ?? '';
    final String? visitStatus = json['Visit_Status']?.toString();
    final String? contactResult = json['Contact_Result']?.toString();

    // For WhatsApp/Message channels
    if (channel.toLowerCase().contains('whatsapp') ||
        channel.toLowerCase().contains('message')) {
      if (name.toLowerCase() == 'delivered') return 'Delivered';
      if (name.toLowerCase() == 'read') return 'Read';
      if (name.toLowerCase() == 'sent') return 'Sent';
      if (json['Delivered_Time_If_Any'] != null) return 'Delivered';
      if (json['Read_Time_If_Any'] != null) return 'Read';
    }

    // For Field Visit
    if (channel.toLowerCase().contains('field') ||
        channel.toLowerCase().contains('visit')) {
      if (visitStatus != null && visitStatus.isNotEmpty) return visitStatus;
      if (json['Vist_Action'] != null) return json['Vist_Action'].toString();
    }

    // For Call
    if (channel.toLowerCase().contains('call')) {
      if (contactResult != null && contactResult.isNotEmpty)
        return contactResult;
      if (json['If_Connected'] != null) return json['If_Connected'].toString();
      if (json['If_not_Connected'] != null)
        return json['If_not_Connected'].toString();
    }

    // Fallback
    if (contactResult != null && contactResult.isNotEmpty) return contactResult;
    if (name.isNotEmpty && name.toLowerCase() != 'null') return name;

    return 'Contact Attempted';
  }

  static String _extractNotes(Map<String, dynamic> json) {
    List<String> notesParts = [];

    if (json['Visit_Notes'] != null &&
        json['Visit_Notes'].toString().isNotEmpty) {
      notesParts.add('${json['Visit_Notes']}');
    }
    if (json['Call_Notes'] != null &&
        json['Call_Notes'].toString().isNotEmpty) {
      notesParts.add('${json['Call_Notes']}');
    }
    if (json['Agent_WA_Notes'] != null &&
        json['Agent_WA_Notes'].toString().isNotEmpty) {
      notesParts.add('${json['Agent_WA_Notes']}');
    }
    if (json['Educational_Call_Notes'] != null &&
        json['Educational_Call_Notes'].toString().isNotEmpty) {
      notesParts.add('${json['Educational_Call_Notes']}');
    }
    if (json['Message_Sent_For'] != null &&
        json['Message_Sent_For'].toString().isNotEmpty) {
      notesParts.add('${json['Message_Sent_For']}');
    }

    if (notesParts.isEmpty) {
      // Try to create a meaningful note from available data
      if (json['Visit_Location'] != null &&
          json['Visit_Location'].toString().isNotEmpty) {
        notesParts.add('Location: ${json['Visit_Location']}');
      }
      if (json['Visit_Agent'] != null &&
          json['Visit_Agent'].toString().isNotEmpty) {
        notesParts.add('Agent: ${json['Visit_Agent']}');
      }
    }

    return notesParts.isNotEmpty
        ? notesParts.join(' | ')
        : 'No additional notes';
  }

  // Helper getters for UI display
  String get channelDisplayName {
    switch (channel.toLowerCase()) {
      case 'field visit':
        return 'Field Visit';
      case 'whatsapp':
        return 'WhatsApp';
      case 'call':
        return 'Phone Call';
      case 'sms':
        return 'SMS';
      case 'email':
        return 'Email';
      default:
        return channel;
    }
  }

  String get resultDisplayName {
    return result ?? 'Unknown';
  }

  DateTime get contactedAt {
    return visitDate ?? modifiedTime ?? createdTime;
  }

  @override
  String toString() {
    return 'ContactabilityHistory(id: $id, channel: $channel, result: $result, date: $createdTime)';
  }
}
