import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:structflow/features/attendance/models/attendance_context_model.dart';

class AttendanceContextRepository extends ChangeNotifier {
  AttendanceContextRepository._();

  static const _storageKey = 'structflow_attendance_context';
  static final instance = AttendanceContextRepository._();
  AttendanceContextModel _context = const AttendanceContextModel();

  AttendanceContextModel get context => _context;

  Future<void> save(AttendanceContextModel context) async {
    _context = context;
    await (await SharedPreferences.getInstance()).setString(
      _storageKey,
      jsonEncode(context.toJson()),
    );
    notifyListeners();
  }

  Future<void> load() async {
    final value = (await SharedPreferences.getInstance()).getString(_storageKey);
    if (value == null) return;
    try {
      _context = AttendanceContextModel.fromJson(Map<String, dynamic>.from(jsonDecode(value) as Map));
      notifyListeners();
    } catch (_) {
      // Keep an empty context if saved content is invalid.
    }
  }
}
