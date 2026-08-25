import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:structflow/features/attendance/models/attendance_permission_model.dart';

class AttendancePermissionRepository extends ChangeNotifier {
  AttendancePermissionRepository._();

  static const _storageKey = 'structflow_attendance_permissions';
  static final instance = AttendancePermissionRepository._();
  final List<AttendancePermissionModel> _permissions = [];

  List<AttendancePermissionModel> get permissions => List.unmodifiable(_permissions);

  AttendancePermissionModel? getForUser({required String organizationId, required String userId}) {
    for (final permission in _permissions) {
      if (permission.organizationId == organizationId && permission.userId == userId) return permission;
    }
    return null;
  }

  /// Only a Super Admin can grant, revoke, or alter location attendance rights.
  Future<bool> save({required String actorUserId, required AttendancePermissionModel permission}) async {
    final actor = getForUser(organizationId: permission.organizationId, userId: actorUserId);
    if (actor == null || !actor.isSuperAdmin) return false;
    final index = _permissions.indexWhere(
      (item) => item.organizationId == permission.organizationId && item.userId == permission.userId,
    );
    if (index == -1) {
      _permissions.add(permission);
    } else {
      _permissions[index] = permission;
    }
    await _persist();
    notifyListeners();
    return true;
  }

  /// Explicit bootstrap for the first Super Admin in an organization.
  Future<void> seedSuperAdmin(AttendancePermissionModel permission) async {
    assert(permission.isSuperAdmin);
    if (_permissions.any(
      (item) => item.organizationId == permission.organizationId,
    )) {
      return;
    }
    final index = _permissions.indexWhere(
      (item) => item.organizationId == permission.organizationId && item.userId == permission.userId,
    );
    if (index == -1) {
      _permissions.add(permission);
    } else {
      _permissions[index] = permission;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> load() async {
    final value = (await SharedPreferences.getInstance()).getString(_storageKey);
    if (value == null) return;
    try {
      final decoded = jsonDecode(value) as List<dynamic>;
      _permissions
        ..clear()
        ..addAll(decoded.map((item) => AttendancePermissionModel.fromJson(Map<String, dynamic>.from(item as Map))));
      notifyListeners();
    } catch (_) {
      // Preserve in-memory values when persisted data is invalid.
    }
  }

  Future<void> _persist() async {
    await (await SharedPreferences.getInstance()).setString(
      _storageKey,
      jsonEncode(_permissions.map((item) => item.toJson()).toList()),
    );
  }
}
