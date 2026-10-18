import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_auth_client.dart';
import '../models/auth_user_model.dart';

class AuthRepository extends ChangeNotifier {
  AuthRepository._();

  static final instance = AuthRepository._();

  static const _usersKey = 'structflow_auth_users_v2';
  static const _passwordsKey = 'structflow_auth_passwords_v2';
  static const _currentUserIdKey = 'structflow_auth_current_user_id_v2';

  // Legacy keys from the first local-auth demo.
  static const _legacyUserKey = 'structflow_auth_user';
  static const _legacyPasswordKey = 'structflow_auth_password';
  static int _userIdSequence = 0;

  final List<AuthUserModel> _users = [];
  final Map<String, String> _passwords = {};
  AuthUserModel? _currentUser;

  List<AuthUserModel> get users => List.unmodifiable(_users);
  AuthUserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null && _currentUser!.isApproved;
  bool get usesApiAuth => ApiAuthClient.isConfigured;
  bool get hasOwner => _users.any((u) => u.isSystemOwner && u.isApproved);
  int get pendingCount => _users.where((u) => u.isPending).length;

  String _newUserId() {
    String id;
    do {
      _userIdSequence++;
      id = 'USR-${DateTime.now().microsecondsSinceEpoch}-$_userIdSequence';
    } while (_findById(id) != null);
    return id;
  }

  Future<void> load() async {
    if (usesApiAuth) {
      _users.clear();
      _passwords.clear();
      _currentUser = await ApiAuthClient.configured.restoreSession();
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    _users.clear();
    _passwords.clear();
    _currentUser = null;

    final rawUsers = prefs.getString(_usersKey);
    if (rawUsers != null && rawUsers.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawUsers) as List<dynamic>;
        _users.addAll(
          decoded.map(
            (item) =>
                AuthUserModel.fromJson(Map<String, dynamic>.from(item as Map)),
          ),
        );
      } catch (_) {}
    }

    final rawPasswords = prefs.getString(_passwordsKey);
    if (rawPasswords != null && rawPasswords.isNotEmpty) {
      try {
        final decoded = Map<String, dynamic>.from(
          jsonDecode(rawPasswords) as Map,
        );
        decoded.forEach((key, value) {
          if (value is String) _passwords[key] = value;
        });
      } catch (_) {}
    }

    // Migrate the original single-user demo account.
    if (_users.isEmpty) {
      final legacyUser = prefs.getString(_legacyUserKey);
      if (legacyUser != null && legacyUser.isNotEmpty) {
        try {
          final oldUser = AuthUserModel.fromJson(
            Map<String, dynamic>.from(jsonDecode(legacyUser) as Map),
          );
          final owner = oldUser.copyWith(
            role: 'Owner',
            status: 'Approved',
            systemOwner: true,
          );
          _users.add(owner);
          final oldPassword = prefs.getString(_legacyPasswordKey);
          if (oldPassword != null) _passwords[owner.id] = oldPassword;
          await _persist();
        } catch (_) {}
      }
    }

    final currentId = prefs.getString(_currentUserIdKey);
    if (currentId != null) {
      _currentUser = _findById(currentId);
    }

    notifyListeners();
  }

  Future<String?> setupOwner({
    required String name,
    required String email,
    required String password,
    required String organization,
  }) async {
    if (usesApiAuth) {
      return 'Organization setup is managed by the StructFlow server.';
    }
    if (hasOwner) return 'A StructFlow Owner already exists.';
    if (password.length < 6) return 'Password must be at least 6 characters.';
    if (_users.any((u) => u.email == email.trim().toLowerCase())) {
      return 'This email is already registered.';
    }

    final user = AuthUserModel(
      id: _newUserId(),
      name: name.trim(),
      email: email.trim().toLowerCase(),
      role: 'Owner',
      organization: organization.trim(),
      status: 'Approved',
      systemOwner: true,
    );

    _users.add(user);
    _passwords[user.id] = password;
    _currentUser = user;
    await _persist();
    await _setCurrentUserId(user.id);
    notifyListeners();
    return null;
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    if (usesApiAuth) {
      try {
        _currentUser = await ApiAuthClient.configured.signIn(
          email: email,
          password: password,
        );
      } on AuthApiException catch (error) {
        return error.message;
      }
      notifyListeners();
      return null;
    }

    final normalized = email.trim().toLowerCase();
    AuthUserModel? user;
    for (final candidate in _users) {
      if (candidate.email == normalized) {
        user = candidate;
        break;
      }
    }

    if (user == null) {
      return 'No account found for this email.';
    }
    if (user.status == 'Pending') {
      return 'Your account is waiting for approval.';
    }
    if (user.status == 'Rejected') {
      return 'This account registration was rejected.';
    }
    if ((_passwords[user.id] ?? '') != password) {
      return 'Incorrect password.';
    }

    _currentUser = user;
    await _setCurrentUserId(user.id);
    notifyListeners();
    return null;
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String organization,
  }) async {
    if (usesApiAuth) {
      return 'Ask your company administrator for an invitation.';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    final normalized = email.trim().toLowerCase();
    if (_users.any((u) => u.email == normalized)) {
      return 'This email is already registered.';
    }

    final user = AuthUserModel(
      id: _newUserId(),
      name: name.trim(),
      email: normalized,
      // The registration category describes the organization type.
      // Actual access role is assigned by an Owner/Manager after approval.
      role: 'Employee',
      organization: organization.trim(),
      status: 'Pending',
    );

    _users.add(user);
    _passwords[user.id] = password;
    await _persist();
    notifyListeners();
    return null;
  }

  Future<bool> approveUser({
    required String actorUserId,
    required String userId,
    required String role,
  }) async {
    if (!_canManage(actorUserId, userId, role)) return false;
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1 || !_users[index].isPending) return false;

    _users[index] = _users[index].copyWith(role: role, status: 'Approved');
    await _persist();
    notifyListeners();
    return true;
  }

  Future<bool> updateUser({
    required String actorUserId,
    required String userId,
    String? role,
    String? status,
  }) async {
    final target = _findById(userId);
    final actor = _findById(actorUserId);
    if (target == null || actor == null) {
      return false;
    }
    if (status != null &&
        !{'Approved', 'Pending', 'Rejected'}.contains(status)) {
      return false;
    }
    if (!_canManage(actorUserId, userId, role ?? target.role)) {
      return false;
    }
    if (target.id == actor.id && status == 'Rejected') {
      return false;
    }

    final index = _users.indexWhere((u) => u.id == userId);
    _users[index] = target.copyWith(role: role, status: status);
    if (_currentUser?.id == userId) _currentUser = _users[index];
    await _persist();
    notifyListeners();
    return true;
  }

  Future<bool> rejectUser({
    required String actorUserId,
    required String userId,
  }) async {
    return updateUser(
      actorUserId: actorUserId,
      userId: userId,
      status: 'Rejected',
    );
  }

  Future<bool> deleteUser({
    required String actorUserId,
    required String userId,
  }) async {
    final actor = _findById(actorUserId);
    final target = _findById(userId);
    if (actor == null ||
        target == null ||
        !_canManage(actorUserId, userId, target.role)) {
      return false;
    }

    _users.removeWhere((u) => u.id == userId);
    _passwords.remove(userId);
    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> signOut() async {
    _currentUser = null;
    notifyListeners();
    if (usesApiAuth) {
      await ApiAuthClient.configured.signOut();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserIdKey);
  }

  AuthUserModel? _findById(String id) {
    for (final user in _users) {
      if (user.id == id) {
        return user;
      }
    }
    return null;
  }

  bool _canManage(String actorUserId, String targetUserId, String role) {
    const assignableRoles = {
      'Owner',
      'Super Admin',
      'Consultant Manager',
      'Owner HR Manager',
      'Consultant HR Manager',
      'Project Manager',
      'HR Manager',
      'Employee',
    };
    if (!assignableRoles.contains(role)) {
      return false;
    }

    final actor = _findById(actorUserId);
    final target = _findById(targetUserId);
    if (actor == null || target == null || actor.id == target.id) {
      return false;
    }
    if (actor.isSystemOwner) {
      return true;
    }
    if (target.isSystemOwner || target.organization != actor.organization) {
      return false;
    }
    if (actor.isOwner) {
      return !target.isOwner &&
          {
            'Employee',
            'Consultant Manager',
            'Owner HR Manager',
            'Consultant HR Manager',
          }.contains(role);
    }
    const managers = {
      'Consultant Manager',
      'Owner HR Manager',
      'Consultant HR Manager',
    };
    return managers.contains(actor.role) &&
        target.role == 'Employee' &&
        role == 'Employee';
  }

  Future<void> _setCurrentUserId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserIdKey, id);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _usersKey,
      jsonEncode(_users.map((u) => u.toJson()).toList()),
    );
    await prefs.setString(_passwordsKey, jsonEncode(_passwords));
  }
}
