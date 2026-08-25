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

  static const _storageKey = 'structflow_attendance_records';
  static final instance = AttendanceRepository._();
  final List<AttendanceRecordModel> _records = [];

  List<AttendanceRecordModel> get records => List.unmodifiable(_records);

  /// The employee may check in only for themself, with a Super-Admin-granted
  /// location permission and inside an enabled project geofence.
  Future<AttendanceRecordModel?> checkIn({
    required String organizationId,
    required String projectId,
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    if (!_hasValidCoordinates(latitude, longitude)) return null;
    final geofence = _enabledGeofence(organizationId, projectId, userId);
    if (geofence == null) return null;
    final distance = distanceToGeofence(geofence, latitude, longitude);
    if (distance > geofence.radiusMeters) return null;
    final existing = activeRecordFor(userId: userId, projectId: projectId);
    if (existing != null) return existing;

    final record = AttendanceRecordModel(
      id: 'ATT-${DateTime.now().microsecondsSinceEpoch}',
      organizationId: organizationId,
      projectId: projectId,
      userId: userId,
      checkInAt: DateTime.now(),
      checkInLatitude: latitude,
      checkInLongitude: longitude,
      checkInDistanceMeters: distance,
    );
    _records.add(record);
    await _persist();
    notifyListeners();
    return record;
  }

  Future<AttendanceRecordModel?> checkOut({
    required String organizationId,
    required String projectId,
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    if (!_hasValidCoordinates(latitude, longitude)) return null;
    final geofence = _enabledGeofence(organizationId, projectId, userId);
    if (geofence == null) return null;
    final distance = distanceToGeofence(geofence, latitude, longitude);
    if (distance > geofence.radiusMeters) return null;
    final index = _records.indexWhere(
      (record) => record.organizationId == organizationId && record.projectId == projectId && record.userId == userId && record.isOpen,
    );
    if (index == -1) return null;

    final updated = _records[index].copyWith(
      checkOutAt: DateTime.now(),
      checkOutLatitude: latitude,
      checkOutLongitude: longitude,
      checkOutDistanceMeters: distance,
    );
    _records[index] = updated;
    await _persist();
    notifyListeners();
    return updated;
  }

  AttendanceRecordModel? activeRecordFor({required String userId, required String projectId}) {
    for (final record in _records) {
      if (record.userId == userId && record.projectId == projectId && record.isOpen) return record;
    }
    return null;
  }

  List<AttendanceRecordModel> recordsForUser({
    required String organizationId,
    required String userId,
  }) =>
      _records
          .where((record) => record.organizationId == organizationId && record.userId == userId)
          .toList(growable: false);

  List<AttendanceRecordModel> recordsForProject({
    required String organizationId,
    required String projectId,
  }) =>
      _records
          .where((record) => record.organizationId == organizationId && record.projectId == projectId)
          .toList(growable: false);

  /// HR reads organization records; Project Managers read only their scoped projects.
  List<AttendanceRecordModel> recordsVisibleTo({
    required String actorUserId,
    required String organizationId,
    String? projectId,
  }) {
    final permission = AttendancePermissionRepository.instance.getForUser(
      organizationId: organizationId,
      userId: actorUserId,
    );
    if (permission == null) return const [];
    final mayReadOrganization = permission.isSuperAdmin ||
        (permission.isHrManager && permission.canViewOrganizationAttendance);
    final mayReadProject = permission.isSuperAdmin ||
        (permission.isProjectManager && permission.canViewProjectAttendance);
    if (!mayReadOrganization && !mayReadProject) return const [];

    return _records.where((record) {
      if (record.organizationId != organizationId) return false;
      if (projectId != null && record.projectId != projectId) return false;
      return mayReadOrganization || permission.managesProject(record.projectId);
    }).toList(growable: false);
  }

  double distanceToGeofence(ProjectGeofenceModel geofence, double latitude, double longitude) {
    const earthRadiusMeters = 6371000.0;
    final latitudeDelta = _radians(geofence.latitude - latitude);
    final longitudeDelta = _radians(geofence.longitude - longitude);
    final a = pow(sin(latitudeDelta / 2), 2) +
        cos(_radians(latitude)) * cos(_radians(geofence.latitude)) * pow(sin(longitudeDelta / 2), 2);
    return earthRadiusMeters * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  ProjectGeofenceModel? _enabledGeofence(String organizationId, String projectId, String userId) {
    final permission = AttendancePermissionRepository.instance.getForUser(
      organizationId: organizationId,
      userId: userId,
    );
    final geofence = ProjectGeofenceRepository.instance.getForProject(projectId);
    if (permission == null ||
        !permission.locationAttendanceEnabled ||
        geofence == null ||
        geofence.organizationId != organizationId ||
        !geofence.attendanceEnabled) {
      return null;
    }
    return geofence;
  }

  Future<void> load() async {
    final value = (await SharedPreferences.getInstance()).getString(_storageKey);
    if (value == null) return;
    try {
      final decoded = jsonDecode(value) as List<dynamic>;
      _records
        ..clear()
        ..addAll(decoded.map((item) => AttendanceRecordModel.fromJson(Map<String, dynamic>.from(item as Map))));
      notifyListeners();
    } catch (_) {
      // Preserve in-memory values when persisted data is invalid.
    }
  }

  Future<void> _persist() async {
    await (await SharedPreferences.getInstance()).setString(
      _storageKey,
      jsonEncode(_records.map((item) => item.toJson()).toList()),
    );
  }

  double _radians(double degrees) => degrees * pi / 180;

  bool _hasValidCoordinates(double latitude, double longitude) =>
      latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;
}
