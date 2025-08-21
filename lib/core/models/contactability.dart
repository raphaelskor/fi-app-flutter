enum ContactabilityChannel {
  call,
  message,
  visit,
}

enum ContactabilityResult {
  contacted,
  notContacted,
  visited,
  notAvailable,
}

// New enums for the enhanced contactability form
enum VisitAction {
  opc,
  rpc,
  tpc,
}

enum VisitStatus {
  bencanaAlam,
  sedangRenovasi,
  kunjunganUlang,
  meninggalDunia,
  gagalBayar,
  mengundurkanDiri,
  alamatSalah,
  menolakBayar,
  pembayaranSebagian,
  alamatTidakDitemukan,
  pindahAlamatBaru,
  sudahBayar,
  menghindar,
  negosiasi,
  berhentiBekerja,
  alamatDitemukanRumahKosong,
  janjiBayar,
  konsumenTidakDikenal,
  tinggalkanSurat,
  pindahTidakDitemukan,
  kunjunganUlang2,
  tinggalkanPesan,
}

enum ContactResult {
  refuseToPay,
  dispute,
  notRecognized,
  alreadyPaid,
  noPromise,
  notRecognised,
  negotiation,
  hangUp,
  leaveAMessage,
  noRespond,
  ptp,
  keepPromise,
  brokenPromise,
}

enum VisitLocation {
  tempatKerja,
  sesuaiAlamat,
  tempatLain,
}

enum VisitBySkorTeam {
  yes,
  no,
}

class Contactability {
  final String id;
  final String clientId;
  final String userId;
  final ContactabilityChannel channel;
  final ContactabilityResult result;
  final String notes;
  final DateTime contactedAt;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  Contactability({
    required this.id,
    required this.clientId,
    required this.userId,
    required this.channel,
    required this.result,
    required this.notes,
    required this.contactedAt,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Contactability.fromJson(Map<String, dynamic> json) {
    return Contactability(
      id: json['id']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      channel: _parseChannel(json['channel']?.toString()),
      result: _parseResult(json['result']?.toString()),
      notes: json['notes']?.toString() ?? '',
      contactedAt: DateTime.parse(
          json['contacted_at'] ?? DateTime.now().toIso8601String()),
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'user_id': userId,
      'channel': _channelToString(channel),
      'result': _resultToString(result),
      'notes': notes,
      'contacted_at': contactedAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static ContactabilityChannel _parseChannel(String? channel) {
    switch (channel?.toLowerCase()) {
      case 'call':
        return ContactabilityChannel.call;
      case 'message':
        return ContactabilityChannel.message;
      case 'visit':
        return ContactabilityChannel.visit;
      default:
        return ContactabilityChannel.call;
    }
  }

  static ContactabilityResult _parseResult(String? result) {
    switch (result?.toLowerCase()) {
      case 'contacted':
        return ContactabilityResult.contacted;
      case 'not_contacted':
        return ContactabilityResult.notContacted;
      case 'visited':
        return ContactabilityResult.visited;
      case 'not_available':
        return ContactabilityResult.notAvailable;
      default:
        return ContactabilityResult.notContacted;
    }
  }

  static String _channelToString(ContactabilityChannel channel) {
    switch (channel) {
      case ContactabilityChannel.call:
        return 'call';
      case ContactabilityChannel.message:
        return 'message';
      case ContactabilityChannel.visit:
        return 'visit';
    }
  }

  static String _resultToString(ContactabilityResult result) {
    switch (result) {
      case ContactabilityResult.contacted:
        return 'contacted';
      case ContactabilityResult.notContacted:
        return 'not_contacted';
      case ContactabilityResult.visited:
        return 'visited';
      case ContactabilityResult.notAvailable:
        return 'not_available';
    }
  }

  String get channelDisplayName {
    switch (channel) {
      case ContactabilityChannel.call:
        return 'Call';
      case ContactabilityChannel.message:
        return 'Message';
      case ContactabilityChannel.visit:
        return 'Visit';
    }
  }

  String get resultDisplayName {
    switch (result) {
      case ContactabilityResult.contacted:
        return 'Contacted';
      case ContactabilityResult.notContacted:
        return 'Not Contacted';
      case ContactabilityResult.visited:
        return 'Visited';
      case ContactabilityResult.notAvailable:
        return 'Not Available';
    }
  }

  Contactability copyWith({
    String? id,
    String? clientId,
    String? userId,
    ContactabilityChannel? channel,
    ContactabilityResult? result,
    String? notes,
    DateTime? contactedAt,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contactability(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      userId: userId ?? this.userId,
      channel: channel ?? this.channel,
      result: result ?? this.result,
      notes: notes ?? this.notes,
      contactedAt: contactedAt ?? this.contactedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Contactability(id: $id, clientId: $clientId, channel: $channel, result: $result)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Contactability && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Helper methods for new enums
extension VisitActionExtension on VisitAction {
  String get displayName {
    switch (this) {
      case VisitAction.opc:
        return 'OPC';
      case VisitAction.rpc:
        return 'RPC';
      case VisitAction.tpc:
        return 'TPC';
    }
  }

  String get apiValue {
    switch (this) {
      case VisitAction.opc:
        return 'OPC';
      case VisitAction.rpc:
        return 'RPC';
      case VisitAction.tpc:
        return 'TPC';
    }
  }

  static VisitAction fromString(String value) {
    switch (value.toUpperCase()) {
      case 'OPC':
        return VisitAction.opc;
      case 'RPC':
        return VisitAction.rpc;
      case 'TPC':
        return VisitAction.tpc;
      default:
        return VisitAction.opc;
    }
  }
}

extension VisitStatusExtension on VisitStatus {
  String get displayName {
    switch (this) {
      case VisitStatus.bencanaAlam:
        return 'Bencana Alam';
      case VisitStatus.sedangRenovasi:
        return 'Sedang Renovasi';
      case VisitStatus.kunjunganUlang:
        return 'Kunjungan Ulang';
      case VisitStatus.meninggalDunia:
        return 'Meninggal Dunia';
      case VisitStatus.gagalBayar:
        return 'Gagal Bayar';
      case VisitStatus.mengundurkanDiri:
        return 'Mengundurkan Diri';
      case VisitStatus.alamatSalah:
        return 'Alamat Salah';
      case VisitStatus.menolakBayar:
        return 'Menolak Bayar';
      case VisitStatus.pembayaranSebagian:
        return 'Pembayaran Sebagian';
      case VisitStatus.alamatTidakDitemukan:
        return 'Alamat Tidak Ditemukan';
      case VisitStatus.pindahAlamatBaru:
        return 'Pindah Alamat Baru';
      case VisitStatus.sudahBayar:
        return 'Sudah Bayar';
      case VisitStatus.menghindar:
        return 'Menghindar';
      case VisitStatus.negosiasi:
        return 'Negosiasi';
      case VisitStatus.berhentiBekerja:
        return 'Berhenti Bekerja';
      case VisitStatus.alamatDitemukanRumahKosong:
        return 'Alamat Ditemukan Rumah Kosong';
      case VisitStatus.janjiBayar:
        return 'Janji Bayar';
      case VisitStatus.konsumenTidakDikenal:
        return 'Konsumen Tidak Dikenal';
      case VisitStatus.tinggalkanSurat:
        return 'Tinggalkan Surat';
      case VisitStatus.pindahTidakDitemukan:
        return 'Pindah Tidak Ditemukan';
      case VisitStatus.kunjunganUlang2:
        return 'Kunjungan Ulang';
      case VisitStatus.tinggalkanPesan:
        return 'Tinggalkan Pesan';
    }
  }

  String get apiValue => displayName;

  static VisitStatus fromString(String value) {
    for (final status in VisitStatus.values) {
      if (status.displayName == value) {
        return status;
      }
    }
    return VisitStatus.kunjunganUlang;
  }
}

extension ContactResultExtension on ContactResult {
  String get displayName {
    switch (this) {
      case ContactResult.refuseToPay:
        return 'Refuse to Pay';
      case ContactResult.dispute:
        return 'Dispute';
      case ContactResult.notRecognized:
        return 'Not Recognized';
      case ContactResult.alreadyPaid:
        return 'Already Paid';
      case ContactResult.noPromise:
        return 'No Promise';
      case ContactResult.notRecognised:
        return 'Not Recognised';
      case ContactResult.negotiation:
        return 'Negotiation';
      case ContactResult.hangUp:
        return 'Hang Up';
      case ContactResult.leaveAMessage:
        return 'Leave a Message';
      case ContactResult.noRespond:
        return 'No respond';
      case ContactResult.ptp:
        return 'Promise to Pay (PTP)';
      case ContactResult.keepPromise:
        return 'Keep Promise (KP)';
      case ContactResult.brokenPromise:
        return 'Broken Promise (BP)';
    }
  }

  String get apiValue => displayName;

  static ContactResult fromString(String value) {
    for (final result in ContactResult.values) {
      if (result.displayName == value) {
        return result;
      }
    }
    return ContactResult.noRespond;
  }
}

extension VisitLocationExtension on VisitLocation {
  String get displayName {
    switch (this) {
      case VisitLocation.tempatKerja:
        return 'Tempat Kerja';
      case VisitLocation.sesuaiAlamat:
        return 'Sesuai Alamat';
      case VisitLocation.tempatLain:
        return 'Tempat Lain';
    }
  }

  String get apiValue => displayName;

  static VisitLocation fromString(String value) {
    for (final location in VisitLocation.values) {
      if (location.displayName == value) {
        return location;
      }
    }
    return VisitLocation.sesuaiAlamat;
  }
}

extension VisitBySkorTeamExtension on VisitBySkorTeam {
  String get displayName {
    switch (this) {
      case VisitBySkorTeam.yes:
        return 'Yes';
      case VisitBySkorTeam.no:
        return 'No';
    }
  }

  String get apiValue => displayName;

  static VisitBySkorTeam fromString(String value) {
    switch (value.toLowerCase()) {
      case 'yes':
        return VisitBySkorTeam.yes;
      case 'no':
        return VisitBySkorTeam.no;
      default:
        return VisitBySkorTeam.yes;
    }
  }
}
