import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:structflow/features/attendance/models/attendance_record_model.dart';
import 'package:structflow/features/attendance/models/project_geofence_model.dart';
import 'package:structflow/features/attendance/repositories/attendance_permission_repository.dart';
import 'package:structflow/features/attendance/repositories/project_geofence_repository.dart';

class AttendanceRepository extends ChangeNotifier {
  AttendanceRepository._();

  static const _storageKey =
      'structflow_attendance_records';

  static final instance =
      AttendanceRepository._();

  final List<AttendanceRecordModel> _records = [];

  List<AttendanceRecordModel> get records =>
      List.unmodifiable(_records);

  // ============================================================
  // CHECK IN
  // ============================================================

  /// Employee can check in only when:
  ///
  /// 1. Coordinates are valid.
  /// 2. User has an active permission record.
  /// 3. Location attendance is enabled.
  /// 4. User is allowed to access the selected project.
  /// 5. The project has an enabled geofence.
  /// 6. The employee is physically inside the configured radius.
  Future<AttendanceRecordModel?> checkIn({
    required String organizationId,
    required String projectId,
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    if (!_hasValidCoordinates(
      latitude,
      longitude,
    )) {
      return null;
    }

    final geofence = _enabledGeofence(
      organizationId,
      projectId,
      userId,
    );

    if (geofence == null) {
      return null;
    }

    final distance = distanceToGeofence(
      geofence,
      latitude,
      longitude,
    );

    // Employee must physically be inside
    // the project's configured radius.
    if (distance > geofence.radiusMeters) {
      return null;
    }

    final existing = activeRecordFor(
      userId: userId,
      projectId: projectId,
    );

    if (existing != null) {
      return existing;
    }

    final record = AttendanceRecordModel(
      id:
          'ATT-${DateTime.now().microsecondsSinceEpoch}',
      organizationId:
          organizationId,
      projectId:
          projectId,
      userId:
          userId,
      checkInAt:
          DateTime.now(),
      checkInLatitude:
          latitude,
      checkInLongitude:
          longitude,
      checkInDistanceMeters:
          distance,
    );

    _records.add(record);

    await _persist();

    notifyListeners();

    return record;
  }

  // ============================================================
  // CHECK OUT
  // ============================================================

  Future<AttendanceRecordModel?> checkOut({
    required String organizationId,
    required String projectId,
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    if (!_hasValidCoordinates(
      latitude,
      longitude,
    )) {
      return null;
    }

    final geofence = _enabledGeofence(
      organizationId,
      projectId,
      userId,
    );

    if (geofence == null) {
      return null;
    }

    final distance = distanceToGeofence(
      geofence,
      latitude,
      longitude,
    );

    // Employee must also be inside the
    // project radius when checking out.
    if (distance > geofence.radiusMeters) {
      return null;
    }

    final index = _records.indexWhere(
      (record) =>
          record.organizationId ==
              organizationId &&
          record.projectId ==
              projectId &&
          record.userId ==
              userId &&
          record.isOpen,
    );

    if (index == -1) {
      return null;
    }

    final updated =
        _records[index].copyWith(
      checkOutAt:
          DateTime.now(),
      checkOutLatitude:
          latitude,
      checkOutLongitude:
          longitude,
      checkOutDistanceMeters:
          distance,
    );

    _records[index] = updated;

    await _persist();

    notifyListeners();

    return updated;
  }

  // ============================================================
  // ACTIVE RECORD
  // ============================================================

  AttendanceRecordModel? activeRecordFor({
    required String userId,
    required String projectId,
  }) {
    for (final record in _records) {
      if (record.userId == userId &&
          record.projectId == projectId &&
          record.isOpen) {
        return record;
      }
    }

    return null;
  }

  // ============================================================
  // USER RECORDS
  // ============================================================

  List<AttendanceRecordModel> recordsForUser({
    required String organizationId,
    required String userId,
  }) {
    return _records
        .where(
          (record) =>
              record.organizationId ==
                  organizationId &&
              record.userId ==
                  userId,
        )
        .toList(
          growable: false,
        );
  }

  // ============================================================
  // PROJECT RECORDS
  // ============================================================

  List<AttendanceRecordModel> recordsForProject({
    required String organizationId,
    required String projectId,
  }) {
    return _records
        .where(
          (record) =>
              record.organizationId ==
                  organizationId &&
              record.projectId ==
                  projectId,
        )
        .toList(
          growable: false,
        );
  }

  // ============================================================
  // RECORDS VISIBLE TO MANAGERS
  // ============================================================

  /// Determines which attendance records a manager can see.
  ///
  /// Owner:
  ///   - Can see organization attendance.
  ///
  /// Owner HR Manager:
  ///   - Can see organization attendance when enabled.
  ///
  /// Consultant HR Manager:
  ///   - Can see organization attendance when enabled.
  ///
  /// Consultant Manager:
  ///   - Can see attendance for projects they manage.
  ///
  /// Employees:
  ///   - Cannot read other employees' attendance through
  ///     this manager-level method.
  List<AttendanceRecordModel> recordsVisibleTo({
    required String actorUserId,
    required String organizationId,
    String? projectId,
  }) {
    final permission =
        AttendancePermissionRepository.instance
            .getForUser(
      organizationId:
          organizationId,
      userId:
          actorUserId,
    );

    if (permission == null) {
      return const [];
    }

    final mayReadOrganization =
        permission.isOwner &&
        permission.canViewOrganizationAttendance;

    final mayReadManagedProjects =
        permission.canViewProjectAttendance &&
        (
          permission.isConsultantManager ||
          permission.isOwnerHrManager ||
          permission.isConsultantHrManager ||
          permission.isProjectManager
        );

    if (!mayReadOrganization &&
        !mayReadManagedProjects) {
      return const [];
    }

    return _records.where(
      (record) {
        if (record.organizationId !=
            organizationId) {
          return false;
        }

        if (projectId != null &&
            record.projectId != projectId) {
          return false;
        }

        // Owner / organization-level viewer.
        if (mayReadOrganization) {
          return true;
        }

        // Manager can only see projects
        // assigned to their management scope.
        return permission.managesProject(
          record.projectId,
        );
      },
    ).toList(
      growable: false,
    );
  }

  // ============================================================
  // DISTANCE
  // ============================================================

  double distanceToGeofence(
    ProjectGeofenceModel geofence,
    double latitude,
    double longitude,
  ) {
    const earthRadiusMeters =
        6371000.0;

    final latitudeDelta = _radians(
      geofence.latitude - latitude,
    );

    final longitudeDelta = _radians(
      geofence.longitude - longitude,
    );

    final a =
        pow(
              sin(latitudeDelta / 2),
              2,
            ) +
            cos(
              _radians(latitude),
            ) *
                cos(
                  _radians(
                    geofence.latitude,
                  ),
                ) *
                pow(
                  sin(
                    longitudeDelta / 2,
                  ),
                  2,
                );

    return earthRadiusMeters *
        2 *
        atan2(
          sqrt(a),
          sqrt(1 - a),
        );
  }

  // ============================================================
  // ENABLED GEOFENCE
  // ============================================================

  ProjectGeofenceModel? _enabledGeofence(
    String organizationId,
    String projectId,
    String userId,
  ) {
    final permission =
        AttendancePermissionRepository.instance
            .getForUser(
      organizationId:
          organizationId,
      userId:
          userId,
    );

    final geofence =
        ProjectGeofenceRepository.instance
            .getForProject(
      projectId,
    );

    // No permission record.
    if (permission == null) {
      return null;
    }

    // Location attendance must be enabled.
    if (!permission.locationAttendanceEnabled) {
      return null;
    }

    // ==========================================================
    // PROJECT ACCESS CONTROL
    // ==========================================================

    // Owner can access all projects.
    //
    // Other users must explicitly have the project
    // in allowedProjectIds or managedProjectIds.
    if (!permission.canAccessProject(
      projectId,
    )) {
      return null;
    }

    // ==========================================================
    // GEOFENCE VALIDATION
    // ==========================================================

    if (geofence == null) {
      return null;
    }

    if (geofence.organizationId !=
        organizationId) {
      return null;
    }

    if (!geofence.attendanceEnabled) {
      return null;
    }

    return geofence;
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> load() async {
    final preferences =
        await SharedPreferences.getInstance();

    final value =
        preferences.getString(
      _storageKey,
    );

    if (value == null) {
      return;
    }

    try {
      final decoded =
          jsonDecode(value)
              as List<dynamic>;

      _records
        ..clear()
        ..addAll(
          decoded.map(
            (item) =>
                AttendanceRecordModel
                    .fromJson(
              Map<String, dynamic>.from(
                item as Map,
              ),
            ),
          ),
        );

      notifyListeners();
    } catch (_) {
      // Preserve current in-memory values
      // if persisted data is invalid.
    }
  }

  // ============================================================
  // PERSIST
  // ============================================================

  Future<void> _persist() async {
    final preferences =
        await SharedPreferences.getInstance();

    await preferences.setString(
      _storageKey,
      jsonEncode(
        _records
            .map(
              (item) => item.toJson(),
            )
            .toList(),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  double _radians(
    double degrees,
  ) {
    return degrees * pi / 180;
  }

  bool _hasValidCoordinates(
    double latitude,
    double longitude,
  ) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }
}