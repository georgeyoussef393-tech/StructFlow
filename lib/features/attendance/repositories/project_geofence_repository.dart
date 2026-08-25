import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:structflow/features/attendance/models/project_geofence_model.dart';
import 'package:structflow/features/attendance/repositories/attendance_permission_repository.dart';

class ProjectGeofenceRepository extends ChangeNotifier {
  ProjectGeofenceRepository._();

  static const _storageKey = 'structflow_project_geofences';
  static final instance = ProjectGeofenceRepository._();
  final List<ProjectGeofenceModel> _geofences = [];

  List<ProjectGeofenceModel> get geofences => List.unmodifiable(_geofences);

  ProjectGeofenceModel? getForProject(String projectId) {
    for (final geofence in _geofences) {
      if (geofence.projectId == projectId) return geofence;
    }
    return null;
  }

  Future<bool> save({required String actorUserId, required ProjectGeofenceModel geofence}) async {
    if (!geofence.isValid) return false;
    final permission = AttendancePermissionRepository.instance.getForUser(
      organizationId: geofence.organizationId,
      userId: actorUserId,
    );
    final mayManage = permission != null &&
        (permission.isSuperAdmin ||
            (permission.isProjectManager && permission.canManageProjectGeofences && permission.managesProject(geofence.projectId)));
    if (!mayManage) return false;
    final index = _geofences.indexWhere((item) => item.projectId == geofence.projectId);
    if (index == -1) {
      _geofences.add(geofence);
    } else {
      _geofences[index] = geofence;
    }
    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> load() async {
    final value = (await SharedPreferences.getInstance()).getString(_storageKey);
    if (value == null) return;
    try {
      final decoded = jsonDecode(value) as List<dynamic>;
      _geofences
        ..clear()
        ..addAll(decoded.map((item) => ProjectGeofenceModel.fromJson(Map<String, dynamic>.from(item as Map))));
      notifyListeners();
    } catch (_) {
      // Preserve in-memory values when persisted data is invalid.
    }
  }

  Future<void> _persist() async {
    await (await SharedPreferences.getInstance()).setString(
      _storageKey,
      jsonEncode(_geofences.map((item) => item.toJson()).toList()),
    );
  }
}
