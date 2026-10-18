import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:bcrypt/bcrypt.dart';
import 'package:crypto/crypto.dart';

class PasswordSecurity {
  static const minimumLength = 12;
  static const bcryptRounds = 12;
  static String? _dummyHash;

  static Future<void> initialize() async {
    final random = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    _dummyHash ??= await hashPasswordAsync(base64Url.encode(random));
  }

  static String? validationError(String password) {
    if (password.length < minimumLength) {
      return 'Password must contain at least 12 characters.';
    }
    if (password.length > 72) {
      return 'Password must not exceed 72 UTF-8 bytes.';
    }
    if (utf8.encode(password).length > 72) {
      return 'Password must not exceed 72 UTF-8 bytes.';
    }
    return null;
  }

  static String hashPassword(String password) =>
      BCrypt.hashpw(password, BCrypt.gensalt(logRounds: bcryptRounds));

  static Future<String> hashPasswordAsync(String password) =>
      Isolate.run(() => hashPassword(password));

  static bool verifyPassword(String password, String hash) {
    if (!RegExp(r'^\$2[aby]\$\d\d\$[./A-Za-z0-9]{53}$').hasMatch(hash)) {
      return false;
    }
    try {
      return BCrypt.checkpw(password, hash);
    } on ArgumentError {
      return false;
    } on FormatException {
      return false;
    }
  }

  static Future<bool> verifyPasswordAsync(String password, String hash) =>
      Isolate.run(() => verifyPassword(password, hash));

  static Future<bool> verifyUnknownUserPassword(String password) {
    final dummyHash = _dummyHash;
    if (dummyHash == null) {
      throw StateError('PasswordSecurity.initialize() must be called first.');
    }
    return verifyPasswordAsync(password, dummyHash);
  }
}

class SessionTokens {
  static final Random _secureRandom = Random.secure();

  static String create() {
    final bytes = List<int>.generate(32, (_) => _secureRandom.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static String digest(String token) =>
      sha256.convert(utf8.encode(token)).toString();
}

class LoginRateLimiter {
  LoginRateLimiter({
    this.limit = 10,
    this.window = const Duration(minutes: 1),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final int limit;
  final Duration window;
  final DateTime Function() _clock;
  final Map<String, List<DateTime>> _attempts = {};

  Duration? retryAfter(String key) {
    final now = _clock();
    final cutoff = now.subtract(window);
    if (!_attempts.containsKey(key) && _attempts.length >= 10000) {
      _attempts.removeWhere(
        (_, attempts) => attempts.every((attempt) => !attempt.isAfter(cutoff)),
      );
      if (_attempts.length >= 10000) return window;
    }
    final attempts = _attempts.putIfAbsent(key, () => <DateTime>[])
      ..removeWhere((attempt) => !attempt.isAfter(cutoff));

    if (attempts.length >= limit) {
      return attempts.first.add(window).difference(now);
    }

    attempts.add(now);
    return null;
  }
}

class ProjectAccessPolicy {
  static const organizationWideRoles = {'owner', 'admin'};

  static bool canCreateProject(String role) =>
      organizationWideRoles.contains(role);

  static bool canCreateTaskAcrossOrganization(String role) =>
      organizationWideRoles.contains(role);

  static bool canUpdateProject(String role) =>
      organizationWideRoles.contains(role);

  static bool canListAllProjects(String role) =>
      organizationWideRoles.contains(role);
}
