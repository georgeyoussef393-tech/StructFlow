class AttendanceContextModel {
  final String organizationId;
  final String projectId;
  final String userId;
  final double? latitude;
  final double? longitude;

  const AttendanceContextModel({
    this.organizationId = '',
    this.projectId = '',
    this.userId = '',
    this.latitude,
    this.longitude,
  });

  bool get hasIdentity =>
      organizationId.isNotEmpty && projectId.isNotEmpty && userId.isNotEmpty;

  bool get hasLocation => latitude != null && longitude != null;

  bool get hasValidLocation =>
      hasLocation && latitude! >= -90 && latitude! <= 90 && longitude! >= -180 && longitude! <= 180;

  Map<String, dynamic> toJson() => {
        'organizationId': organizationId,
        'projectId': projectId,
        'userId': userId,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory AttendanceContextModel.fromJson(Map<String, dynamic> json) => AttendanceContextModel(
        organizationId: json['organizationId'] as String? ?? '',
        projectId: json['projectId'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );
}
