import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_auth_client.dart';
import '../../auth/repositories/auth_repository.dart';
import '../models/bim_workspace_models.dart';

class BimWorkspaceRepository extends ChangeNotifier {
  BimWorkspaceRepository._();

  static final instance = BimWorkspaceRepository._();
  static const _modelsKey = 'structflow_bim_models_v1';
  static const _issuesKey = 'structflow_bim_issues_v1';
  static const _commentsKey = 'structflow_bim_issue_comments_v1';

  List<BimModelRecord> _models = [];
  List<BimIssue> _issues = [];
  List<BimIssueComment> _comments = [];
  bool _loaded = false;

  List<BimModelRecord> get models => List.unmodifiable(_models);
  List<BimIssue> get issues => List.unmodifiable(_issues);
  bool get _apiMode => AuthRepository.instance.usesApiAuth;

  Future<void> load() async {
    if (_loaded) return;
    if (_apiMode) {
      _models = [];
      _issues = [];
      _comments = [];
      _loaded = true;
      notifyListeners();
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    final storedModels = preferences.getString(_modelsKey);
    final storedIssues = preferences.getString(_issuesKey);

    _models = storedModels == null
        ? _sampleModels()
        : _decodeList(storedModels, BimModelRecord.fromJson);
    _issues = storedIssues == null
        ? _sampleIssues()
        : _decodeList(storedIssues, BimIssue.fromJson);
    _comments = _decodeList(
      preferences.getString(_commentsKey) ?? '[]',
      BimIssueComment.fromJson,
    );
    _loaded = true;

    if (storedModels == null ||
        storedIssues == null ||
        preferences.getString(_commentsKey) == null) {
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

  Future<void> loadIssuesForProject(String projectCode) async {
    await _ensureLoaded();
    if (!_apiMode) return;
    final scope = _apiScope();
    final loaded = await ApiAuthClient.configured.listBimIssues(
      organizationId: scope.$1,
      projectIdentifier: projectCode,
    );
    _issues = [
      ..._issues.where((issue) => issue.projectCode != projectCode),
      ...loaded,
    ];
    notifyListeners();
  }

  Future<void> loadModelsForProject(String projectCode) async {
    await _ensureLoaded();
    if (!_apiMode) return;
    final scope = _apiScope();
    final loaded = await ApiAuthClient.configured.listBimModels(
      organizationId: scope.$1,
      projectIdentifier: projectCode,
    );
    _models = [
      ..._models.where((model) => model.projectCode != projectCode),
      ...loaded,
    ];
    notifyListeners();
  }

  Future<void> addModel(BimModelRecord model) async {
    await _ensureLoaded();
    if (_apiMode) {
      final scope = _apiScope();
      final created = await ApiAuthClient.configured.createBimModel(
        organizationId: scope.$1,
        projectIdentifier: model.projectCode,
        model: model,
      );
      _models = [..._models, created];
      notifyListeners();
      return;
    }
    _models = [..._models, model];
    await _persist(await SharedPreferences.getInstance());
    notifyListeners();
  }

  Future<void> updateModelStatus(String modelId, String status) async {
    await _ensureLoaded();
    final index = _models.indexWhere((model) => model.id == modelId);
    if (index < 0) {
      throw StateError('BIM model "$modelId" is not loaded.');
    }
    final candidate = _models[index].copyWith(status: status);
    if (_apiMode) {
      final scope = _apiScope();
      final updated = await ApiAuthClient.configured.updateBimModelStatus(
        organizationId: scope.$1,
        model: candidate,
      );
      _models = [
        for (final model in _models)
          if (model.id == modelId) updated else model,
      ];
      notifyListeners();
      return;
    }
    final previousModels = _models;
    _models = [
      for (final model in _models)
        if (model.id == modelId) candidate else model,
    ];
    try {
      await _persist(await SharedPreferences.getInstance());
    } catch (_) {
      _models = previousModels;
      rethrow;
    }
    notifyListeners();
  }

  Future<void> addIssue(BimIssue issue) async {
    await _ensureLoaded();
    if (_apiMode) {
      final scope = _apiScope();
      final created = await ApiAuthClient.configured.createBimIssue(
        organizationId: scope.$1,
        projectIdentifier: issue.projectCode,
        issue: issue,
      );
      _issues = [..._issues, created];
      notifyListeners();
      return;
    }
    _issues = [..._issues, issue];
    await _persist(await SharedPreferences.getInstance());
    notifyListeners();
  }

  Future<int> importIssues(List<BimIssue> incoming) async {
    await _ensureLoaded();
    if (_apiMode) {
      if (incoming.isEmpty) return 0;
      final projectCode = incoming.first.projectCode;
      if (incoming.any((issue) => issue.projectCode != projectCode)) {
        throw const FormatException(
          'A BCF import must contain issues for one project.',
        );
      }
      final scope = _apiScope();
      final created = await ApiAuthClient.configured.importBimIssues(
        organizationId: scope.$1,
        projectIdentifier: projectCode,
        issues: incoming,
      );
      await loadIssuesForProject(projectCode);
      return created.length;
    }
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
    if (_apiMode) {
      final index = _issues.indexWhere((issue) => issue.id == issueId);
      if (index < 0) {
        throw StateError('BIM issue "$issueId" is not loaded.');
      }
      final scope = _apiScope();
      final updated = await ApiAuthClient.configured.updateBimIssueStatus(
        organizationId: scope.$1,
        issue: _issues[index].copyWith(status: status),
      );
      _issues = [
        for (final issue in _issues)
          if (issue.id == issueId) updated else issue,
      ];
      notifyListeners();
      return;
    }
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

  Future<List<BimIssueComment>> loadIssueComments(String issueId) async {
    await _ensureLoaded();
    if (!_apiMode) {
      return _comments
          .where((comment) => comment.issueId == issueId)
          .toList(growable: false);
    }
    final scope = _apiScope();
    return ApiAuthClient.configured.listBimIssueComments(
      organizationId: scope.$1,
      issueId: issueId,
    );
  }

  Future<Map<String, List<BimIssueComment>>> loadProjectIssueComments(
    String projectCode,
  ) async {
    await _ensureLoaded();
    final projectIssues = issuesFor(projectCode);
    if (!_apiMode) {
      final issueIds = projectIssues.map((issue) => issue.id).toSet();
      return _groupComments(
        _comments.where((comment) => issueIds.contains(comment.issueId)),
      );
    }
    final scope = _apiScope();
    final comments = await ApiAuthClient.configured.listProjectBimComments(
      organizationId: scope.$1,
      projectIdentifier: projectCode,
    );
    return _groupComments(comments);
  }

  Future<BimIssueComment> addIssueComment(String issueId, String body) async {
    await _ensureLoaded();
    final text = body.trim();
    if (text.isEmpty || text.length > 5000) {
      throw const FormatException(
        'Comment text must contain between 1 and 5000 characters.',
      );
    }
    if (_apiMode) {
      final scope = _apiScope();
      return ApiAuthClient.configured.createBimIssueComment(
        organizationId: scope.$1,
        issueId: issueId,
        body: text,
      );
    }
    final comment = BimIssueComment(
      id: 'BIM-CMT-${DateTime.now().microsecondsSinceEpoch}',
      issueId: issueId,
      body: text,
      authorName: AuthRepository.instance.currentUser?.name ?? 'Local user',
      createdAt: DateTime.now(),
      bcfGuid: _newGuid(),
    );
    final previousComments = _comments;
    _comments = [..._comments, comment];
    try {
      await _persist(await SharedPreferences.getInstance());
    } catch (_) {
      _comments = previousComments;
      rethrow;
    }
    notifyListeners();
    return comment;
  }

  Future<int> importBcfComments({
    required String projectCode,
    required Map<String, List<BimIssueComment>> commentsByTopicGuid,
  }) async {
    await _ensureLoaded();
    if (commentsByTopicGuid.isEmpty) return 0;
    final projectIssues = issuesFor(projectCode);
    final issuesByGuid = {
      for (final issue in projectIssues)
        if (issue.bcfGuid != null) issue.bcfGuid!.toLowerCase(): issue,
    };
    final resolved = <String, List<BimIssueComment>>{};
    for (final entry in commentsByTopicGuid.entries) {
      final issue = issuesByGuid[entry.key.toLowerCase()];
      if (issue == null) {
        throw FormatException(
          'BCF comments reference an issue that is not in project $projectCode.',
        );
      }
      resolved[entry.key.toLowerCase()] = entry.value
          .map(
            (comment) => BimIssueComment(
              id: comment.id,
              issueId: issue.id,
              body: comment.body,
              authorName: comment.authorName,
              createdAt: comment.createdAt,
              bcfGuid: comment.bcfGuid,
            ),
          )
          .toList(growable: false);
    }
    if (_apiMode) {
      final scope = _apiScope();
      return ApiAuthClient.configured.importProjectBimComments(
        organizationId: scope.$1,
        projectIdentifier: projectCode,
        commentsByTopicGuid: resolved,
      );
    }

    final existing = {
      for (final comment in _comments)
        if (comment.bcfGuid != null) '${comment.issueId}:${comment.bcfGuid}',
    };
    final additions = <BimIssueComment>[];
    for (final comments in resolved.values) {
      for (final comment in comments) {
        final key = '${comment.issueId}:${comment.bcfGuid}';
        if (existing.add(key)) additions.add(comment);
      }
    }
    if (additions.isEmpty) return 0;
    final previousComments = _comments;
    _comments = [..._comments, ...additions];
    try {
      await _persist(await SharedPreferences.getInstance());
    } catch (_) {
      _comments = previousComments;
      rethrow;
    }
    notifyListeners();
    return additions.length;
  }

  Map<String, List<BimIssueComment>> _groupComments(
    Iterable<BimIssueComment> comments,
  ) {
    final grouped = <String, List<BimIssueComment>>{};
    for (final comment in comments) {
      grouped.putIfAbsent(comment.issueId, () => []).add(comment);
    }
    return {
      for (final entry in grouped.entries)
        entry.key: List.unmodifiable(entry.value),
    };
  }

  String _newGuid() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  Future<void> _ensureLoaded() async {
    if (!_loaded) await load();
  }

  (String, String) _apiScope() {
    final user = AuthRepository.instance.currentUser;
    if (user == null || user.organizationId.isEmpty) {
      throw StateError('An authenticated company is required for BIM issues.');
    }
    return (user.organizationId, user.id);
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
    final savedComments = await preferences.setString(
      _commentsKey,
      jsonEncode(_comments.map((comment) => comment.toJson()).toList()),
    );
    if (!savedModels || !savedIssues || !savedComments) {
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
