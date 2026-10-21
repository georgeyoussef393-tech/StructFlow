class AttendancePermissionModel {
  final String id;
  final String organizationId;
  final String userId;
  final String role;

  final bool locationAttendanceEnabled;
  final bool canManageProjectGeofences;
  final bool canViewProjectAttendance;
  final bool canViewOrganizationAttendance;

  final List<String> permissions;
  final List<String> managedProjectIds;
  final List<String> allowedProjectIds;

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
    this.permissions = const [],
    this.managedProjectIds = const [],
    this.allowedProjectIds = const [],
    required this.updatedAt,
  });

  // ============================================================
  // ROLES
  // ============================================================

  static const roles = <String>[
    'Owner',
    'Consultant Manager',
    'Owner HR Manager',
    'Consultant HR Manager',
    'Employee',
  ];

  // Legacy roles kept for compatibility with the existing
  // AttendanceCenterPage.
  static const legacyRoles = <String>[
    'Super Admin',
    'Project Manager',
    'HR Manager',
  ];

  // ============================================================
  // MODULE PERMISSIONS
  // ============================================================

  static const modulePermissions = <String>[
    'projects',
    'bim',
    'documents',
    'drawings',
    'tasks',
    'reports',
    'team',
    'calendar',
  ];

  // ============================================================
  // ROLE CHECKS
  // ============================================================

  bool get isOwner => role == 'Owner' || role == 'Super Admin';

  bool get isSuperAdmin => isOwner;

  bool get isConsultantManager => role == 'Consultant Manager';

  bool get isOwnerHrManager => role == 'Owner HR Manager';

  bool get isConsultantHrManager => role == 'Consultant HR Manager';

  bool get isEmployee => role == 'Employee';

  // Legacy compatibility.
  bool get isProjectManager => role == 'Project Manager';

  // Legacy compatibility.
  bool get isHrManager => role == 'HR Manager';

  bool get isManager =>
      isOwner ||
      isConsultantManager ||
      isOwnerHrManager ||
      isConsultantHrManager ||
      isProjectManager ||
      isHrManager;

  // ============================================================
  // PERMISSIONS
  // ============================================================

  bool hasPermission(String permission) {
    if (isOwner) return true;
    return permissions.contains(permission);
  }

  bool canAccessProject(String projectId) {
    if (isOwner) return true;

    if (allowedProjectIds.contains(projectId)) {
      return true;
    }

    if (managedProjectIds.contains(projectId)) {
      return true;
    }

    return false;
  }

  bool managesProject(String projectId) {
    if (isOwner) return true;

    return managedProjectIds.contains(projectId);
  }

  bool get canAccessAttendance => true;

  bool get canAccessProjects => hasPermission('projects');

  bool get canAccessDocuments => hasPermission('documents');

  bool get canAccessDrawings => hasPermission('drawings');

  bool get canAccessTasks => hasPermission('tasks');

  bool get canAccessReports => hasPermission('reports');

  bool get canAccessTeam => hasPermission('team');

  bool get canAccessCalendar => hasPermission('calendar');

  bool get canManageUsers => isManager;

  // ============================================================
  // OWNER / SUPER ADMIN FACTORY
  // ============================================================

  factory AttendancePermissionModel.owner({
    required String id,
    required String organizationId,
    required String userId,
    DateTime? updatedAt,
  }) {
    return AttendancePermissionModel(
      id: id,
      organizationId: organizationId,
      userId: userId,
      role: 'Owner',
      locationAttendanceEnabled: true,
      canManageProjectGeofences: true,
      canViewProjectAttendance: true,
      canViewOrganizationAttendance: true,
      permissions: modulePermissions,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Kept because the existing code uses this factory.
  factory AttendancePermissionModel.superAdmin({
    required String id,
    required String organizationId,
    required String userId,
    DateTime? updatedAt,
  }) {
    return AttendancePermissionModel.owner(
      id: id,
      organizationId: organizationId,
      userId: userId,
      updatedAt: updatedAt,
    );
  }

  // ============================================================
  // COPY
  // ============================================================

  AttendancePermissionModel copyWith({
    String? role,
    bool? locationAttendanceEnabled,
    bool? canManageProjectGeofences,
    bool? canViewProjectAttendance,
    bool? canViewOrganizationAttendance,
    List<String>? permissions,
    List<String>? managedProjectIds,
    List<String>? allowedProjectIds,
    DateTime? updatedAt,
  }) {
    return AttendancePermissionModel(
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
      permissions: permissions ?? this.permissions,
      managedProjectIds: managedProjectIds ?? this.managedProjectIds,
      allowedProjectIds: allowedProjectIds ?? this.allowedProjectIds,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ============================================================
  // JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizationId': organizationId,
      'userId': userId,
      'role': role,
      'locationAttendanceEnabled': locationAttendanceEnabled,
      'canManageProjectGeofences': canManageProjectGeofences,
      'canViewProjectAttendance': canViewProjectAttendance,
      'canViewOrganizationAttendance': canViewOrganizationAttendance,
      'permissions': permissions,
      'managedProjectIds': managedProjectIds,
      'allowedProjectIds': allowedProjectIds,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AttendancePermissionModel.fromJson(Map<String, dynamic> json) {
    return AttendancePermissionModel(
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
      permissions: (json['permissions'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      managedProjectIds: (json['managedProjectIds'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      allowedProjectIds: (json['allowedProjectIds'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
