/// Attendance permissions granted to one user inside one organization.
///
/// Roles stay as strings to remain compatible with the existing membership
/// model (`Super Admin`, `Project Manager`, `HR Manager`, and `Employee`).
class AttendancePermissionModel {
  final String id;
  final String organizationId;
  final String userId;
  final String role;
  final bool locationAttendanceEnabled;
  final bool canManageProjectGeofences;
  final bool canViewProjectAttendance;
  final bool canViewOrganizationAttendance;
  final List<String> managedProjectIds;
  final DateTime updatedAt;

  const AttendancePermissionModel({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.role,
    this.locationAttendanceEnabled = false,
    this.canManageProjectGeofences = false,
    this.canViewProjectAttendance = false,
    this.canViewOrganizationAttendance = false,
    this.managedProjectIds = const [],
    required this.updatedAt,
  });

  bool get isSuperAdmin => role == 'Super Admin';
  bool get isProjectManager => role == 'Project Manager';
  bool get isHrManager => role == 'HR Manager';
  bool managesProject(String projectId) =>
      isSuperAdmin || managedProjectIds.contains(projectId);

  factory AttendancePermissionModel.superAdmin({
    required String id,
    required String organizationId,
    required String userId,
    DateTime? updatedAt,
  }) =>
      AttendancePermissionModel(
        id: id,
        organizationId: organizationId,
        userId: userId,
        role: 'Super Admin',
        locationAttendanceEnabled: true,
        canManageProjectGeofences: true,
        canViewProjectAttendance: true,
        canViewOrganizationAttendance: true,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  AttendancePermissionModel copyWith({
    String? role,
    bool? locationAttendanceEnabled,
    bool? canManageProjectGeofences,
    bool? canViewProjectAttendance,
    bool? canViewOrganizationAttendance,
    List<String>? managedProjectIds,
    DateTime? updatedAt,
  }) =>
      AttendancePermissionModel(
        id: id,
        organizationId: organizationId,
        userId: userId,
        role: role ?? this.role,
        locationAttendanceEnabled:
            locationAttendanceEnabled ?? this.locationAttendanceEnabled,
        canManageProjectGeofences:
            canManageProjectGeofences ?? this.canManageProjectGeofences,
        canViewProjectAttendance:
            canViewProjectAttendance ?? this.canViewProjectAttendance,
        canViewOrganizationAttendance:
            canViewOrganizationAttendance ?? this.canViewOrganizationAttendance,
        managedProjectIds: managedProjectIds ?? this.managedProjectIds,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'organizationId': organizationId,
        'userId': userId,
        'role': role,
        'locationAttendanceEnabled': locationAttendanceEnabled,
        'canManageProjectGeofences': canManageProjectGeofences,
        'canViewProjectAttendance': canViewProjectAttendance,
        'canViewOrganizationAttendance': canViewOrganizationAttendance,
        'managedProjectIds': managedProjectIds,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AttendancePermissionModel.fromJson(Map<String, dynamic> json) =>
      AttendancePermissionModel(
        id: json['id'] as String? ?? '',
        organizationId: json['organizationId'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        role: json['role'] as String? ?? 'Employee',
        locationAttendanceEnabled:
            json['locationAttendanceEnabled'] as bool? ?? false,
        canManageProjectGeofences:
            json['canManageProjectGeofences'] as bool? ?? false,
        canViewProjectAttendance:
            json['canViewProjectAttendance'] as bool? ?? false,
        canViewOrganizationAttendance:
            json['canViewOrganizationAttendance'] as bool? ?? false,
        managedProjectIds: (json['managedProjectIds'] as List<dynamic>? ?? [])
            .whereType<String>()
            .toList(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
