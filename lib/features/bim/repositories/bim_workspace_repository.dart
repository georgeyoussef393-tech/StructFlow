import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bim_workspace_models.dart';

class BimWorkspaceRepository extends ChangeNotifier {
  BimWorkspaceRepository._();

  static final instance = BimWorkspaceRepository._();
  static const _modelsKey = 'structflow_bim_models_v1';
  static const _issuesKey = 'structflow_bim_issues_v1';

  List<BimModelRecord> _models = [];
  List<BimIssue> _issues = [];
  bool _loaded = false;

  List<BimModelRecord> get models => List.unmodifiable(_models);
  List<BimIssue> get issues => List.unmodifiable(_issues);

  Future<void> load() async {
    if (_loaded) return;
    final preferences = await SharedPreferences.getInstance();
    final storedModels = preferences.getString(_modelsKey);
    final storedIssues = preferences.getString(_issuesKey);

    _models = storedModels == null
        ? _sampleModels()
        : _decodeList(storedModels, BimModelRecord.fromJson);
    _issues = storedIssues == null
        ? _sampleIssues()
        : _decodeList(storedIssues, BimIssue.fromJson);
    _loaded = true;

    if (storedModels == null || storedIssues == null) {
      await _persist(preferences);
    }
    notifyListeners();
  }

  List<BimModelRecord> modelsFor(String projectCode) => _models
      .where((model) => model.projectCode == projectCode)
      .toList(growable: false);

  List<BimIssue> issuesFor(String projectCode) => _issues
      .where((issue) => issue.projectCode == projectCode)
      .toList(growable: false);

  Future<void> addModel(BimModelRecord model) async {
    await _ensureLoaded();
    _models = [..._models, model];
    await _persist(await SharedPreferences.getInstance());
    notifyListeners();
  }

  Future<void> addIssue(BimIssue issue) async {
    await _ensureLoaded();
    _issues = [..._issues, issue];
    await _persist(await SharedPreferences.getInstance());
    notifyListeners();
  }

  Future<int> importIssues(List<BimIssue> incoming) async {
    await _ensureLoaded();
    final existingIds = _issues.map((issue) => issue.id).toSet();
    final additions = incoming
        .where((issue) => !existingIds.contains(issue.id))
        .toList(growable: false);
    if (additions.isEmpty) return 0;
    final previousIssues = _issues;
    _issues = [...previousIssues, ...additions];
    try {
      await _persist(await SharedPreferences.getInstance());
    } catch (_) {
      _issues = previousIssues;
      rethrow;
    }
    notifyListeners();
    return additions.length;
  }

  Future<void> updateIssueStatus(String issueId, String status) async {
    await _ensureLoaded();
    var found = false;
    _issues = _issues
        .map((issue) {
          if (issue.id != issueId) return issue;
          found = true;
          return issue.copyWith(status: status);
        })
        .toList(growable: false);
    if (!found) throw StateError('BIM issue "$issueId" no longer exists.');
    await _persist(await SharedPreferences.getInstance());
    notifyListeners();
  }

  Future<void> _ensureLoaded() async {
    if (!_loaded) await load();
  }

  Future<void> _persist(SharedPreferences preferences) async {
    final savedModels = await preferences.setString(
      _modelsKey,
      jsonEncode(_models.map((model) => model.toJson()).toList()),
    );
    final savedIssues = await preferences.setString(
      _issuesKey,
      jsonEncode(_issues.map((issue) => issue.toJson()).toList()),
    );
    if (!savedModels || !savedIssues) {
      throw StateError('BIM workspace changes could not be saved locally.');
    }
  }

  List<T> _decodeList<T>(
    String raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      final value = jsonDecode(raw);
      if (value is! List) throw const FormatException('Expected a list.');
      return value
          .map((item) => fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } on Object catch (error) {
      throw FormatException('Saved BIM workspace data is invalid: $error');
    }
  }

  List<BimModelRecord> _sampleModels() {
    final updatedAt = DateTime(2026, 10, 15);
    return [
      BimModelRecord(
        id: 'BIM-MOD-001',
        projectCode: 'PRJ-001',
        name: 'Tower - Architecture',
        discipline: 'Architecture',
        version: 'v12',
        status: 'Published',
        updatedAt: updatedAt,
      ),
      BimModelRecord(
        id: 'BIM-MOD-002',
        projectCode: 'PRJ-001',
        name: 'Tower - Structure',
        discipline: 'Structure',
        version: 'v9',
        status: 'Published',
        updatedAt: updatedAt,
      ),
      BimModelRecord(
        id: 'BIM-MOD-003',
        projectCode: 'PRJ-001',
        name: 'Tower - MEP',
        discipline: 'MEP',
        version: 'v7',
        status: 'In review',
        updatedAt: updatedAt,
      ),
      BimModelRecord(
        id: 'BIM-MOD-004',
        projectCode: 'PRJ-002',
        name: 'Business Park - Core',
        discipline: 'Structure',
        version: 'v3',
        status: 'Published',
        updatedAt: updatedAt,
      ),
    ];
  }

  List<BimIssue> _sampleIssues() {
    final dueDate = DateTime(2026, 10, 30);
    return [
      BimIssue(
        id: 'BIM-ISS-001',
        projectCode: 'PRJ-001',
        title: 'Duct conflicts with transfer beam',
        description: 'Review the main supply duct route at the beam crossing.',
        discipline: 'MEP / Structure',
        location: 'Tower A · Level 04 · Grid C-5',
        severity: 'Critical',
        status: 'Open',
        assignedTo: 'MEP Coordinator',
        dueDate: dueDate,
      ),
      BimIssue(
        id: 'BIM-ISS-002',
        projectCode: 'PRJ-001',
        title: 'Facade bracket clearance',
        description: 'Confirm installation clearance around the slab edge.',
        discipline: 'Facade / Structure',
        location: 'Tower A · Level 08 · Grid F-2',
        severity: 'High',
        status: 'In progress',
        assignedTo: 'Facade Lead',
        dueDate: dueDate,
      ),
      BimIssue(
        id: 'BIM-ISS-003',
        projectCode: 'PRJ-001',
        title: 'Ceiling access panel alignment',
        description: 'Align access panel with the reflected ceiling plan.',
        discipline: 'Architecture / MEP',
        location: 'Tower A · Level 03 · Room 3.12',
        severity: 'Medium',
        status: 'Open',
        assignedTo: 'BIM Coordinator',
        dueDate: DateTime(2026, 11, 3),
      ),
      BimIssue(
        id: 'BIM-ISS-004',
        projectCode: 'PRJ-001',
        title: 'Plant-room sleeve coordination',
        description: 'Sleeve opening confirmed with structural team.',
        discipline: 'MEP / Structure',
        location: 'Tower A · Basement · Plant room',
        severity: 'Low',
        status: 'Resolved',
        assignedTo: 'Structural Lead',
        dueDate: DateTime(2026, 10, 10),
      ),
    ];
  }
}
