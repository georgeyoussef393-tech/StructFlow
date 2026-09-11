import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:structflow/features/attendance/models/project_geofence_model.dart';
import 'package:structflow/features/attendance/repositories/attendance_permission_repository.dart';

class ProjectGeofenceRepository
    extends ChangeNotifier {
  ProjectGeofenceRepository._();

  static const String _storageKey =
      'structflow_project_geofences';

  static final ProjectGeofenceRepository
      instance =
      ProjectGeofenceRepository._();

  final List<ProjectGeofenceModel>
      _geofences = [];

  List<ProjectGeofenceModel>
      get geofences =>
          List.unmodifiable(
            _geofences,
          );

  // ============================================================
  // GET PROJECT GEOFENCE
  // ============================================================

  ProjectGeofenceModel? getForProject(
    String projectId,
  ) {
    for (final geofence
        in _geofences) {
      if (geofence.projectId ==
          projectId) {
        return geofence;
      }
    }

    return null;
  }

  // ============================================================
  // GET ORGANIZATION GEOFENCES
  // ============================================================

  List<ProjectGeofenceModel>
      forOrganization(
    String organizationId,
  ) {
    return _geofences
        .where(
          (item) =>
              item.organizationId ==
              organizationId,
        )
        .toList();
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<bool> save({
    required String actorUserId,
    required ProjectGeofenceModel
        geofence,
  }) async {
    if (!geofence.isValid) {
      return false;
    }

    final permission =
        AttendancePermissionRepository
            .instance
            .getForUser(
      organizationId:
          geofence.organizationId,
      userId: actorUserId,
    );

    if (permission == null) {
      return false;
    }

    bool mayManage = false;

    // ----------------------------------------------------------
    // OWNER
    // ----------------------------------------------------------

    if (permission.isOwner) {
      mayManage = true;
    }

    // ----------------------------------------------------------
    // MANAGERS
    // ----------------------------------------------------------

    if (!mayManage &&
        permission.canManageProjectGeofences &&
        permission.isManager) {
      mayManage =
          permission.managesProject(
        geofence.projectId,
      );
    }

    if (!mayManage) {
      return false;
    }

    final index =
        _geofences.indexWhere(
      (item) =>
          item.organizationId ==
              geofence.organizationId &&
          item.projectId ==
              geofence.projectId,
    );

    if (index == -1) {
      _geofences.add(
        geofence,
      );
    } else {
      _geofences[index] =
          geofence;
    }

    await _persist();

    notifyListeners();

    return true;
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<bool> delete({
    required String actorUserId,
    required String organizationId,
    required String projectId,
  }) async {
    final permission =
        AttendancePermissionRepository
            .instance
            .getForUser(
      organizationId:
          organizationId,
      userId: actorUserId,
    );

    if (permission == null) {
      return false;
    }

    if (!permission.isOwner &&
        !(
          permission.canManageProjectGeofences &&
          permission.managesProject(
            projectId,
          )
        )) {
      return false;
    }

    _geofences.removeWhere(
      (item) =>
          item.organizationId ==
              organizationId &&
          item.projectId ==
              projectId,
    );

    await _persist();

    notifyListeners();

    return true;
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> load() async {
    final preferences =
        await SharedPreferences
            .getInstance();

    final value =
        preferences.getString(
      _storageKey,
    );

    if (value == null ||
        value.isEmpty) {
      return;
    }

    try {
      final decoded =
          jsonDecode(value)
              as List<dynamic>;

      _geofences
        ..clear()
        ..addAll(
          decoded.map(
            (item) =>
                ProjectGeofenceModel
                    .fromJson(
              Map<String, dynamic>.from(
                item as Map,
              ),
            ),
          ),
        );

      notifyListeners();
    } catch (_) {
      // Keep existing state.
    }
  }

  // ============================================================
  // PERSIST
  // ============================================================

  Future<void> _persist() async {
    final preferences =
        await SharedPreferences
            .getInstance();

    await preferences.setString(
      _storageKey,
      jsonEncode(
        _geofences
            .map(
              (item) =>
                  item.toJson(),
            )
            .toList(),
      ),
    );
  }
}