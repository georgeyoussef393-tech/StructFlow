class AttendanceRecordModel {
  final String id;
  final String organizationId;
  final String projectId;
  final String userId;
  final DateTime checkInAt;
  final double checkInLatitude;
  final double checkInLongitude;
  final double checkInDistanceMeters;
  final DateTime? checkOutAt;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final double? checkOutDistanceMeters;

  const AttendanceRecordModel({
    required this.id,
    required this.organizationId,
    required this.projectId,
    required this.userId,
    required this.checkInAt,
    required this.checkInLatitude,
    required this.checkInLongitude,
    required this.checkInDistanceMeters,
    this.checkOutAt,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.checkOutDistanceMeters,
  });

  bool get isOpen => checkOutAt == null;
  Duration get workedDuration => (checkOutAt ?? DateTime.now()).difference(checkInAt);

  AttendanceRecordModel copyWith({
    DateTime? checkOutAt,
    double? checkOutLatitude,
    double? checkOutLongitude,
    double? checkOutDistanceMeters,
  }) =>
      AttendanceRecordModel(
        id: id,
        organizationId: organizationId,
        projectId: projectId,
        userId: userId,
        checkInAt: checkInAt,
        checkInLatitude: checkInLatitude,
        checkInLongitude: checkInLongitude,
        checkInDistanceMeters: checkInDistanceMeters,
        checkOutAt: checkOutAt ?? this.checkOutAt,
        checkOutLatitude: checkOutLatitude ?? this.checkOutLatitude,
        checkOutLongitude: checkOutLongitude ?? this.checkOutLongitude,
        checkOutDistanceMeters: checkOutDistanceMeters ?? this.checkOutDistanceMeters,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'organizationId': organizationId,
        'projectId': projectId,
        'userId': userId,
        'checkInAt': checkInAt.toIso8601String(),
        'checkInLatitude': checkInLatitude,
        'checkInLongitude': checkInLongitude,
        'checkInDistanceMeters': checkInDistanceMeters,
        'checkOutAt': checkOutAt?.toIso8601String(),
        'checkOutLatitude': checkOutLatitude,
        'checkOutLongitude': checkOutLongitude,
        'checkOutDistanceMeters': checkOutDistanceMeters,
      };

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) =>
      AttendanceRecordModel(
        id: json['id'] as String? ?? '',
        organizationId: json['organizationId'] as String? ?? '',
        projectId: json['projectId'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        checkInAt: DateTime.tryParse(json['checkInAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        checkInLatitude: (json['checkInLatitude'] as num?)?.toDouble() ?? 0,
        checkInLongitude: (json['checkInLongitude'] as num?)?.toDouble() ?? 0,
        checkInDistanceMeters:
            (json['checkInDistanceMeters'] as num?)?.toDouble() ?? 0,
        checkOutAt: DateTime.tryParse(json['checkOutAt'] as String? ?? ''),
        checkOutLatitude: (json['checkOutLatitude'] as num?)?.toDouble(),
        checkOutLongitude: (json['checkOutLongitude'] as num?)?.toDouble(),
        checkOutDistanceMeters:
            (json['checkOutDistanceMeters'] as num?)?.toDouble(),
      );
}
