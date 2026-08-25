class ProjectGeofenceModel {
  final String id;
  final String organizationId;
  final String projectId;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final bool attendanceEnabled;
  final String updatedByUserId;
  final DateTime updatedAt;

  const ProjectGeofenceModel({
    required this.id,
    required this.organizationId,
    required this.projectId,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.attendanceEnabled,
    required this.updatedByUserId,
    required this.updatedAt,
  }) : assert(radiusMeters > 0);

  bool get hasValidCoordinates =>
      latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;

  bool get isValid => hasValidCoordinates && radiusMeters > 0;

  ProjectGeofenceModel copyWith({
    double? latitude,
    double? longitude,
    double? radiusMeters,
    bool? attendanceEnabled,
    String? updatedByUserId,
    DateTime? updatedAt,
  }) =>
      ProjectGeofenceModel(
        id: id,
        organizationId: organizationId,
        projectId: projectId,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        radiusMeters: radiusMeters ?? this.radiusMeters,
        attendanceEnabled: attendanceEnabled ?? this.attendanceEnabled,
        updatedByUserId: updatedByUserId ?? this.updatedByUserId,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'organizationId': organizationId,
        'projectId': projectId,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
        'attendanceEnabled': attendanceEnabled,
        'updatedByUserId': updatedByUserId,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ProjectGeofenceModel.fromJson(Map<String, dynamic> json) =>
      ProjectGeofenceModel(
        id: json['id'] as String? ?? '',
        organizationId: json['organizationId'] as String? ?? '',
        projectId: json['projectId'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 100,
        attendanceEnabled: json['attendanceEnabled'] as bool? ?? false,
        updatedByUserId: json['updatedByUserId'] as String? ?? '',
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
