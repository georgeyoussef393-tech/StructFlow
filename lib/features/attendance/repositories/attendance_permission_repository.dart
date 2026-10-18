import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:structflow/features/attendance/models/attendance_permission_model.dart';

class AttendancePermissionRepository extends ChangeNotifier {
  AttendancePermissionRepository._();

  static const String _storageKey = 'structflow_attendance_permissions';

  static final AttendancePermissionRepository instance =
      AttendancePermissionRepository._();

  final List<AttendancePermissionModel> _permissions = [];

  List<AttendancePermissionModel> get permissions =>
      List.unmodifiable(_permissions);

  // ============================================================
  // FIND USER
  // ============================================================

  AttendancePermissionModel? getForUser({
    required String organizationId,
    required String userId,
  }) {
    for (final permission in _permissions) {
      if (permission.organizationId == organizationId &&
          permission.userId == userId) {
        return permission;
      }
    }

    return null;
  }

  // ============================================================
  // SAVE PERMISSION
  // ============================================================

  Future<bool> save({
    required String actorUserId,
    required AttendancePermissionModel permission,
  }) async {
    final actor = getForUser(
      organizationId: permission.organizationId,
      userId: actorUserId,
    );

    if (actor == null) {
      return false;
    }

    if (!actor.canManageUsers) {
      return false;
    }

    /*
     * Managers are allowed to manage employees.
     *
     * Owner can manage everyone.
     */

    if (!actor.isOwner && !permission.isEmployee) {
      return false;
    }

    /*
     * Prevent a manager from creating an
     * Owner account.
     */

    if (!actor.isOwner && permission.isOwner) {
      return false;
    }

    final index = _permissions.indexWhere(
      (item) =>
          item.organizationId == permission.organizationId &&
          item.userId == permission.userId,
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

  // ============================================================
  // CREATE / INITIALIZE OWNER
  // ============================================================

  Future<void> seedSuperAdmin(AttendancePermissionModel permission) async {
    final index = _permissions.indexWhere(
      (item) =>
          item.organizationId == permission.organizationId &&
          item.userId == permission.userId,
    );

    if (index == -1) {
      _permissions.add(permission);
    } else {
      _permissions[index] = permission;
    }

    await _persist();

    notifyListeners();
  }

  Future<void> ensureUserPermission({
    required AttendancePermissionModel permission,
  }) async {
    if (getForUser(
          organizationId: permission.organizationId,
          userId: permission.userId,
        ) !=
        null) {
      return;
    }

    _permissions.add(permission);
    await _persist();
    notifyListeners();
  }

  // ============================================================
  // REMOVE USER PERMISSION
  // ============================================================

  Future<bool> revoke({
    required String actorUserId,
    required String organizationId,
    required String userId,
  }) async {
    final actor = getForUser(
      organizationId: organizationId,
      userId: actorUserId,
    );

    if (actor == null) {
      return false;
    }

    if (!actor.canManageUsers) {
      return false;
    }

    /*
     * A user cannot remove his own permission
     * record.
     */

    if (actor.userId == userId) {
      return false;
    }

    /*
     * Only Owner can remove another manager.
     */

    final target = getForUser(organizationId: organizationId, userId: userId);

    if (target == null) {
      return false;
    }

    if (!actor.isOwner && !target.isEmployee) {
      return false;
    }

    _permissions.removeWhere(
      (item) => item.organizationId == organizationId && item.userId == userId,
    );

    await _persist();

    notifyListeners();

    return true;
  }

  // ============================================================
  // CHECK PERMISSION
  // ============================================================

  bool hasPermission({
    required String organizationId,
    required String userId,
    required String permission,
  }) {
    final user = getForUser(organizationId: organizationId, userId: userId);

    if (user == null) {
      return false;
    }

    return user.hasPermission(permission);
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();

    final value = preferences.getString(_storageKey);

    if (value == null || value.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(value) as List<dynamic>;

      _permissions
        ..clear()
        ..addAll(
          decoded.map(
            (item) => AttendancePermissionModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          ),
        );

      notifyListeners();
    } catch (_) {
      /*
       * Keep the current in-memory state
       * if stored data is invalid.
       */
    }
  }

  // ============================================================
  // PERSIST
  // ============================================================

  Future<void> _persist() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _storageKey,
      jsonEncode(_permissions.map((item) => item.toJson()).toList()),
    );
  }
}
