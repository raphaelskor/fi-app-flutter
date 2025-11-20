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
  alamatDitemukanRumahKosong,
  dilarangMasukPerumahan,
  dilarangMasukKantor,
  menghindar,
  titipSurat,
  alamatTidakDitemukan,
  alamatSalah,
  konsumenTidakDikenal,
  pindahTidakDitemukan,
  pindahAlamatBaru,
  meninggalDunia,
  mengundurkanDiri,
  berhentiBekerja,
  sedangRenovasi,
  bencanaAlam,
  kondisiMedis,
  sengketaHukum,
  kunjunganUlang,
  ptp,
  negotiation,
  hotProspect,
  alreadyPaid,
  refuseToPay,
  dispute,
  notRecognized,
  partialPayment,
  failedToPay,
  waOneTick,
  waTwoTick,
  waBlueTick,
  waNotRegistered,
  sp1,
  sp2,
  sp3,
  leaveAMessage,
  hangUp,
  rejected,
  noAnswer,
  busy,
  mailbox,
  invalidNumber,
  unreachable,
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

enum PersonContacted {
  debtor,
  spouse,
  son,
  daughter,
  father,
  mother,
  brother,
  sister,
  houseAssistant,
  houseSecurity,
  areaSecurity,
  officeSecurity,
  receptionist,
  guest,
  neighbor,
  emergencyContact,
}

enum ActionLocation {
  alamatKorespondensi,
  alamatKantor,
  alamatRumah,
  alamatKtp,
  alamatLain,
  customerMobile,
  emergencyContact1,
  emergencyContact2,
  office,
  skipTracingNumber,
  phoneContact,
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
      case ContactResult.alamatDitemukanRumahKosong:
        return 'Alamat Ditemukan, Rumah Kosong';
      case ContactResult.dilarangMasukPerumahan:
        return 'Dilarang Masuk Perumahan';
      case ContactResult.dilarangMasukKantor:
        return 'Dilarang Masuk Kantor';
      case ContactResult.menghindar:
        return 'Menghindar';
      case ContactResult.titipSurat:
        return 'Titip Surat';
      case ContactResult.alamatTidakDitemukan:
        return 'Alamat Tidak Ditemukan';
      case ContactResult.alamatSalah:
        return 'Alamat Salah';
      case ContactResult.konsumenTidakDikenal:
        return 'Konsumen Tidak Dikenal';
      case ContactResult.pindahTidakDitemukan:
        return 'Pindah, Tidak Ditemukan';
      case ContactResult.pindahAlamatBaru:
        return 'Pindah, Alamat Baru';
      case ContactResult.meninggalDunia:
        return 'Meninggal Dunia';
      case ContactResult.mengundurkanDiri:
        return 'Mengundurkan Diri';
      case ContactResult.berhentiBekerja:
        return 'Berhenti Bekerja';
      case ContactResult.sedangRenovasi:
        return 'Sedang Renovasi';
      case ContactResult.bencanaAlam:
        return 'Bencana Alam';
      case ContactResult.kondisiMedis:
        return 'Kondisi Medis';
      case ContactResult.sengketaHukum:
        return 'Sengketa Hukum';
      case ContactResult.kunjunganUlang:
        return 'Kunjungan Ulang';
      case ContactResult.ptp:
        return 'Promise to Pay (PTP)';
      case ContactResult.negotiation:
        return 'Negotiation';
      case ContactResult.hotProspect:
        return 'Hot Prospect';
      case ContactResult.alreadyPaid:
        return 'Already Paid';
      case ContactResult.refuseToPay:
        return 'Refuse to Pay';
      case ContactResult.dispute:
        return 'Dispute';
      case ContactResult.notRecognized:
        return 'Not Recognized';
      case ContactResult.partialPayment:
        return 'Partial Payment';
      case ContactResult.failedToPay:
        return 'Failed to Pay';
      case ContactResult.waOneTick:
        return 'WA One Tick';
      case ContactResult.waTwoTick:
        return 'WA Two Tick';
      case ContactResult.waBlueTick:
        return 'WA Blue Tick';
      case ContactResult.waNotRegistered:
        return 'WA Not Registered';
      case ContactResult.sp1:
        return 'SP 1';
      case ContactResult.sp2:
        return 'SP 2';
      case ContactResult.sp3:
        return 'SP 3';
      case ContactResult.leaveAMessage:
        return 'Leave a Message';
      case ContactResult.hangUp:
        return 'Hang Up';
      case ContactResult.rejected:
        return 'Rejected';
      case ContactResult.noAnswer:
        return 'No Answer';
      case ContactResult.busy:
        return 'Busy';
      case ContactResult.mailbox:
        return 'Mailbox';
      case ContactResult.invalidNumber:
        return 'Invalid Number';
      case ContactResult.unreachable:
        return 'Unreachable';
    }
  }

  String get apiValue => displayName;

  static ContactResult fromString(String value) {
    for (final result in ContactResult.values) {
      if (result.displayName == value) {
        return result;
      }
    }
    return ContactResult.kunjunganUlang;
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

extension PersonContactedExtension on PersonContacted {
  String get displayName {
    switch (this) {
      case PersonContacted.debtor:
        return 'Debtor';
      case PersonContacted.spouse:
        return 'Spouse';
      case PersonContacted.son:
        return 'Son';
      case PersonContacted.daughter:
        return 'Daughter';
      case PersonContacted.father:
        return 'Father';
      case PersonContacted.mother:
        return 'Mother';
      case PersonContacted.brother:
        return 'Brother';
      case PersonContacted.sister:
        return 'Sister';
      case PersonContacted.houseAssistant:
        return 'House Assistant';
      case PersonContacted.houseSecurity:
        return 'House Security';
      case PersonContacted.areaSecurity:
        return 'Area Security';
      case PersonContacted.officeSecurity:
        return 'Office Security';
      case PersonContacted.receptionist:
        return 'Receptionist';
      case PersonContacted.guest:
        return 'Guest';
      case PersonContacted.neighbor:
        return 'Neighbor';
      case PersonContacted.emergencyContact:
        return 'Emergency Contact';
    }
  }

  String get apiValue => displayName;

  static PersonContacted fromString(String value) {
    for (final person in PersonContacted.values) {
      if (person.displayName == value) {
        return person;
      }
    }
    return PersonContacted.debtor;
  }
}

extension ActionLocationExtension on ActionLocation {
  String get displayName {
    switch (this) {
      case ActionLocation.alamatKorespondensi:
        return 'Alamat Korespondensi';
      case ActionLocation.alamatKantor:
        return 'Alamat Kantor';
      case ActionLocation.alamatRumah:
        return 'Alamat Rumah';
      case ActionLocation.alamatKtp:
        return 'Alamat KTP';
      case ActionLocation.alamatLain:
        return 'Alamat Lain';
      case ActionLocation.customerMobile:
        return 'Customer Mobile';
      case ActionLocation.emergencyContact1:
        return 'Econ 1';
      case ActionLocation.emergencyContact2:
        return 'Econ 2';
      case ActionLocation.office:
        return 'Office';
      case ActionLocation.skipTracingNumber:
        return 'Skip Tracing Number';
      case ActionLocation.phoneContact:
        return 'Phone Contact';
    }
  }

  String get apiValue => displayName;

  static ActionLocation fromString(String value) {
    for (final location in ActionLocation.values) {
      if (location.displayName == value) {
        return location;
      }
    }
    return ActionLocation.alamatKorespondensi;
  }
}
