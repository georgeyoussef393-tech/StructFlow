import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:structflow/features/calendar/models/calendar_event_model.dart';

class CalendarRepository extends ChangeNotifier {
  static const String _storageKey =
      'structflow_calendar_events';

  CalendarRepository._internal();

  static final CalendarRepository instance =
      CalendarRepository._internal();

  final List<CalendarEventModel> _events = [
    CalendarEventModel(
      id: 'CAL-001',
      title: 'Review Structural Drawings',
      description:
          'Review the latest structural drawings before consultant submission.',
      date: DateTime(2026, 8, 15),
      type: 'Task',
      projectCode: 'PRJ-001',
      projectName: 'New Capital Tower',
      taskId: 'TSK-001',
      color: Colors.orange,
    ),

    CalendarEventModel(
      id: 'CAL-002',
      title: 'BOQ Review',
      description:
          'Review and approve the updated bill of quantities.',
      date: DateTime(2026, 8, 18),
      type: 'Task',
      projectCode: 'PRJ-002',
      projectName: 'Cairo Business Park',
      taskId: 'TSK-002',
      color: Colors.blue,
    ),

    CalendarEventModel(
      id: 'CAL-003',
      title: 'Electrical Coordination',
      description:
          'Coordinate electrical drawings with other disciplines.',
      date: DateTime(2026, 8, 22),
      type: 'Task',
      projectCode: 'PRJ-004',
      projectName: 'Alex Mall',
      taskId: 'TSK-003',
      color: Colors.orange,
    ),

    CalendarEventModel(
      id: 'CAL-004',
      title: 'Site Inspection',
      description:
          'Complete the scheduled site inspection.',
      date: DateTime(2026, 8, 8),
      type: 'Task',
      projectCode: 'PRJ-006',
      projectName: 'Tuban Villas',
      taskId: 'TSK-004',
      color: Colors.green,
    ),

    CalendarEventModel(
      id: 'CAL-005',
      title: 'RFI Response',
      description:
          'Prepare the consultant response for the outstanding RFI.',
      date: DateTime(2026, 8, 13),
      type: 'Task',
      projectCode: 'PRJ-003',
      projectName: 'Smart Village',
      taskId: 'TSK-005',
      color: Colors.red,
    ),

    CalendarEventModel(
      id: 'CAL-006',
      title: 'New Capital Tower Start',
      description:
          'Planned project start date.',
      date: DateTime(2026, 8, 20),
      type: 'Project',
      projectCode: 'PRJ-001',
      projectName: 'New Capital Tower',
      color: Colors.green,
    ),

    CalendarEventModel(
      id: 'CAL-007',
      title: 'Alex Mall Deadline',
      description:
          'Expected project completion milestone.',
      date: DateTime(2026, 8, 30),
      type: 'Milestone',
      projectCode: 'PRJ-004',
      projectName: 'Alex Mall',
      color: Colors.blue,
    ),
  ];

  List<CalendarEventModel> get events {
    return List.unmodifiable(_events);
  }

  Future<void> loadEvents() async {
    final preferences =
        await SharedPreferences.getInstance();

    final savedEvents =
        preferences.getString(_storageKey);

    if (savedEvents == null) {
      return;
    }

    try {
      final decoded =
          jsonDecode(savedEvents) as List<dynamic>;

      final restoredEvents = decoded
          .map(
            (event) =>
                CalendarEventModel.fromJson(
              Map<String, dynamic>.from(
                event as Map,
              ),
            ),
          )
          .toList();

      _events
        ..clear()
        ..addAll(restoredEvents);

      notifyListeners();
    } catch (_) {
      // Keep bundled calendar events.
    }
  }

  Future<void> _saveEvents() async {
    final preferences =
        await SharedPreferences.getInstance();

    final encodedEvents = jsonEncode(
      _events
          .map(
            (event) => event.toJson(),
          )
          .toList(),
    );

    await preferences.setString(
      _storageKey,
      encodedEvents,
    );
  }

  String get nextEventId {
    var highestNumber = 0;

    for (final event in _events) {
      final match = RegExp(
        r'^CAL-(\d+)$',
      ).firstMatch(event.id);

      final number = int.tryParse(
        match?.group(1) ?? '',
      );

      if (number != null &&
          number > highestNumber) {
        highestNumber = number;
      }
    }

    return 'CAL-${(highestNumber + 1).toString().padLeft(3, '0')}';
  }

  List<CalendarEventModel> getEventsForDate(
    DateTime date,
  ) {
    return _events.where((event) {
      return event.date.year == date.year &&
          event.date.month == date.month &&
          event.date.day == date.day;
    }).toList();
  }

  List<CalendarEventModel> getEventsForMonth(
    DateTime date,
  ) {
    return _events.where((event) {
      return event.date.year == date.year &&
          event.date.month == date.month;
    }).toList();
  }

  void addEvent(
    CalendarEventModel event,
  ) {
    _events.add(event);

    _saveEvents();
    notifyListeners();
  }

  void updateEvent(
    CalendarEventModel updatedEvent,
  ) {
    final index = _events.indexWhere(
      (event) => event.id == updatedEvent.id,
    );

    if (index == -1) {
      return;
    }

    _events[index] = updatedEvent;

    _saveEvents();
    notifyListeners();
  }

  void deleteEvent(
    String id,
  ) {
    _events.removeWhere(
      (event) => event.id == id,
    );

    _saveEvents();
    notifyListeners();
  }

  CalendarEventModel? getEventById(
    String id,
  ) {
    try {
      return _events.firstWhere(
        (event) => event.id == id,
      );
    } catch (_) {
      return null;
    }
  }
}