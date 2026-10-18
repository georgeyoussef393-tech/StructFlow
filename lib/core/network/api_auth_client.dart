import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../features/auth/models/auth_user_model.dart';
import '../../features/projects/models/project_model.dart';
import '../../features/tasks/models/task_model.dart';

const _configuredApiUrl = String.fromEnvironment('STRUCTFLOW_API_BASE_URL');

abstract interface class SessionTokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> delete();
}

class SecureSessionTokenStore implements SessionTokenStore {
  static const _tokenKey = 'structflow.api.access_token';
  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read() => _storage.read(key: _tokenKey);

  @override
  Future<void> write(String token) =>
      _storage.write(key: _tokenKey, value: token);

  @override
  Future<void> delete() => _storage.delete(key: _tokenKey);
}

class AuthApiException implements Exception {
  const AuthApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiAuthClient {
  ApiAuthClient({
    required Uri baseUri,
    required http.Client httpClient,
    required SessionTokenStore tokenStore,
  }) : this._(_validateBaseUri(baseUri), httpClient, tokenStore);

  ApiAuthClient._(this._baseUri, this._httpClient, this._tokenStore);

  static final ApiAuthClient configured = ApiAuthClient(
    baseUri: Uri.parse(_configuredApiUrl),
    httpClient: http.Client(),
    tokenStore: SecureSessionTokenStore(),
  );

  static bool get isConfigured => _configuredApiUrl.trim().isNotEmpty;

  final Uri _baseUri;
  final http.Client _httpClient;
  final SessionTokenStore _tokenStore;

  static Uri _validateBaseUri(Uri uri) {
    if (!{'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw StateError(
        'STRUCTFLOW_API_BASE_URL must be an HTTP(S) origin without a path.',
      );
    }
    final isLoopback = {
      'localhost',
      '127.0.0.1',
      '::1',
    }.contains(uri.host.toLowerCase());
    if (uri.scheme != 'https' && (kReleaseMode || !isLoopback)) {
      throw StateError(
        'The StructFlow API must use HTTPS, except localhost during development.',
      );
    }
    return uri;
  }

  Uri _endpoint(String path) => _baseUri.resolve(path);

  Future<AuthUserModel?> restoreSession() async {
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) return null;

    try {
      final user = await _fetchCurrentUser(token);
      return user;
    } on AuthApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _tokenStore.delete();
        return null;
      }
      rethrow;
    }
  }

  Future<List<ProjectModel>> listProjects({
    required String organizationId,
  }) async {
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) {
      throw const AuthApiException(
        'Your session has expired. Sign in again.',
        statusCode: 401,
      );
    }
    final response = await _send(
      () => _httpClient
          .get(
            _endpoint('/v1/projects'),
            headers: {
              'authorization': 'Bearer $token',
              'x-organization-id': organizationId,
            },
          )
          .timeout(const Duration(seconds: 15)),
    );
    final body = _decodeBody(response);
    if (response.statusCode != 200) {
      if (response.statusCode == 401) await _tokenStore.delete();
      throw AuthApiException(
        _errorMessage(body, 'Could not load company projects.'),
        statusCode: response.statusCode,
      );
    }
    final projects = body['projects'];
    if (projects is! List) {
      throw const AuthApiException(
        'The server returned an invalid projects response.',
      );
    }
    return projects
        .map((project) => _parseProject(project, organizationId))
        .toList(growable: false);
  }

  Future<ProjectModel> createProject({
    required String organizationId,
    required ProjectModel project,
  }) async {
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) {
      throw const AuthApiException(
        'Your session has expired. Sign in again.',
        statusCode: 401,
      );
    }
    final response = await _send(
      () => _httpClient
          .post(
            _endpoint('/v1/projects'),
            headers: {
              'authorization': 'Bearer $token',
              'x-organization-id': organizationId,
              'content-type': 'application/json',
            },
            body: jsonEncode({
              'code': project.code,
              'name': project.name,
              'clientName': project.client,
              'projectType': project.projectType,
              'location': project.location,
              'status': _apiProjectStatus(project.status),
              'budgetAmount': _budgetAmount(project.budget),
              'budgetCurrency': _budgetCurrency(project.budget),
              'plannedStartDate': project.plannedStartDate
                  ?.toIso8601String()
                  .split('T')
                  .first,
              'plannedEndDate': project.plannedEndDate
                  ?.toIso8601String()
                  .split('T')
                  .first,
            }),
          )
          .timeout(const Duration(seconds: 15)),
    );
    final body = _decodeBody(response);
    if (response.statusCode != 201) {
      if (response.statusCode == 401) await _tokenStore.delete();
      throw AuthApiException(
        _errorMessage(body, 'Could not create the project.'),
        statusCode: response.statusCode,
      );
    }
    final responseProject = body['project'];
    if (responseProject is! Map<String, dynamic>) {
      throw const AuthApiException(
        'The server returned an invalid created project.',
      );
    }
    return _parseProject(responseProject, organizationId);
  }

  Future<ProjectModel> getProject({
    required String organizationId,
    required String projectIdentifier,
  }) async {
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) {
      throw const AuthApiException(
        'Your session has expired. Sign in again.',
        statusCode: 401,
      );
    }
    final response = await _send(
      () => _httpClient
          .get(
            _endpoint('/v1/projects/${Uri.encodeComponent(projectIdentifier)}'),
            headers: {
              'authorization': '******',
              'x-organization-id': organizationId,
            },
          )
          .timeout(const Duration(seconds: 15)),
    );
    final body = _decodeBody(response);
    if (response.statusCode != 200) {
      if (response.statusCode == 401) await _tokenStore.delete();
      throw AuthApiException(
        _errorMessage(body, 'Could not load the project.'),
        statusCode: response.statusCode,
      );
    }
    final project = body['project'];
    if (project is! Map<String, dynamic>) {
      throw const AuthApiException(
        'The server returned an invalid project response.',
      );
    }
    return _parseProject(project, organizationId);
  }

  Future<ProjectModel> updateProject({
    required String organizationId,
    required ProjectModel project,
  }) async {
    if (project.id.isEmpty || project.version < 1) {
      throw const AuthApiException('Project update data is invalid.');
    }
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) {
      throw const AuthApiException(
        'Your session has expired. Sign in again.',
        statusCode: 401,
      );
    }
    final response = await _send(
      () => _httpClient
          .patch(
            _endpoint('/v1/projects/${Uri.encodeComponent(project.id)}'),
            headers: {
              'authorization': '******',
              'x-organization-id': organizationId,
              'content-type': 'application/json',
            },
            body: jsonEncode({
              'expectedVersion': project.version,
              'name': project.name,
              'status': _apiProjectStatus(project.status),
              'location': project.location,
              'clientName': project.client,
              'projectType': project.projectType,
              'budgetAmount': _budgetAmount(project.budget),
              'budgetCurrency': _budgetCurrency(project.budget),
              'plannedStartDate': project.plannedStartDate
                  ?.toIso8601String()
                  .split('T')
                  .first,
              'plannedEndDate': project.plannedEndDate
                  ?.toIso8601String()
                  .split('T')
                  .first,
            }),
          )
          .timeout(const Duration(seconds: 15)),
    );
    final body = _decodeBody(response);
    if (response.statusCode != 200) {
      if (response.statusCode == 401) await _tokenStore.delete();
      throw AuthApiException(
        _errorMessage(body, 'Could not update the project.'),
        statusCode: response.statusCode,
      );
    }
    final responseProject = body['project'];
    if (responseProject is! Map<String, dynamic>) {
      throw const AuthApiException(
        'The server returned an invalid updated project.',
      );
    }
    return _parseProject(responseProject, organizationId);
  }

  Future<List<TaskModel>> listTasks({
    required String organizationId,
    String? projectCode,
  }) async {
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) {
      throw const AuthApiException(
        'Your session has expired. Sign in again.',
        statusCode: 401,
      );
    }
    final uri = _endpoint('/v1/tasks').replace(
      queryParameters: projectCode == null || projectCode.isEmpty
          ? null
          : {'projectCode': projectCode},
    );
    final response = await _send(
      () => _httpClient
          .get(
            uri,
            headers: {
              'authorization': '******',
              'x-organization-id': organizationId,
            },
          )
          .timeout(const Duration(seconds: 15)),
    );
    final body = _decodeBody(response);
    if (response.statusCode != 200) {
      if (response.statusCode == 401) await _tokenStore.delete();
      throw AuthApiException(
        _errorMessage(body, 'Could not load tasks.'),
        statusCode: response.statusCode,
      );
    }
    final tasks = body['tasks'];
    if (tasks is! List) {
      throw const AuthApiException('The server returned invalid task data.');
    }
    return tasks.map(_parseTask).toList(growable: false);
  }

  Future<TaskModel> createTask({
    required String organizationId,
    required String projectCode,
    required String title,
    required String description,
    required String priority,
    required DateTime dueDate,
  }) async {
    const priorities = {
      'Low': 'low',
      'Medium': 'medium',
      'High': 'high',
      'Urgent': 'urgent',
    };
    final apiPriority = priorities[priority];
    if (projectCode.isEmpty || title.trim().length < 2 || apiPriority == null) {
      throw const AuthApiException('Task fields are invalid.');
    }
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) {
      throw const AuthApiException(
        'Your session has expired. Sign in again.',
        statusCode: 401,
      );
    }
    final response = await _send(
      () => _httpClient
          .post(
            _endpoint('/v1/tasks'),
            headers: {
              'authorization': '******',
              'x-organization-id': organizationId,
              'content-type': 'application/json',
            },
            body: jsonEncode({
              'projectCode': projectCode,
              'title': title.trim(),
              'description': description.trim(),
              'priority': apiPriority,
              'dueDate': dueDate.toIso8601String().split('T').first,
            }),
          )
          .timeout(const Duration(seconds: 15)),
    );
    final body = _decodeBody(response);
    if (response.statusCode != 201) {
      if (response.statusCode == 401) await _tokenStore.delete();
      throw AuthApiException(
        _errorMessage(body, 'Could not create the task.'),
        statusCode: response.statusCode,
      );
    }
    return _parseTask(body['task']);
  }

  Future<TaskModel> getTask({
    required String organizationId,
    required String taskId,
  }) async {
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) {
      throw const AuthApiException(
        'Your session has expired. Sign in again.',
        statusCode: 401,
      );
    }
    final response = await _send(
      () => _httpClient
          .get(
            _endpoint('/v1/tasks/${Uri.encodeComponent(taskId)}'),
            headers: {
              'authorization': '******',
              'x-organization-id': organizationId,
            },
          )
          .timeout(const Duration(seconds: 15)),
    );
    final body = _decodeBody(response);
    if (response.statusCode != 200) {
      if (response.statusCode == 401) await _tokenStore.delete();
      throw AuthApiException(
        _errorMessage(body, 'Could not load the task.'),
        statusCode: response.statusCode,
      );
    }
    return _parseTask(body['task']);
  }

  Future<TaskModel> updateTask({
    required String organizationId,
    required TaskModel task,
  }) async {
    if (task.id.isEmpty || task.version < 1) {
      throw const AuthApiException('Task update data is invalid.');
    }
    const statuses = {
      'To Do': 'todo',
      'In Progress': 'in_progress',
      'Review': 'review',
      'Done': 'done',
    };
    const priorities = {
      'Low': 'low',
      'Medium': 'medium',
      'High': 'high',
      'Urgent': 'urgent',
    };
    final apiStatus = statuses[task.status];
    final apiPriority = priorities[task.priority];
    if (apiStatus == null ||
        apiPriority == null ||
        task.title.trim().length < 2 ||
        !task.progress.isFinite ||
        task.progress < 0 ||
        task.progress > 1) {
      throw const AuthApiException('Task update fields are invalid.');
    }
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) {
      throw const AuthApiException(
        'Your session has expired. Sign in again.',
        statusCode: 401,
      );
    }
    final response = await _send(
      () => _httpClient
          .patch(
            _endpoint('/v1/tasks/${Uri.encodeComponent(task.id)}'),
            headers: {
              'authorization': '******',
              'x-organization-id': organizationId,
              'content-type': 'application/json',
            },
            body: jsonEncode({
              'expectedVersion': task.version,
              'title': task.title.trim(),
              'description': task.description.trim(),
              'status': apiStatus,
              'priority': apiPriority,
              'dueDate': task.dueDate.toIso8601String().split('T').first,
              'progress': task.progress,
            }),
          )
          .timeout(const Duration(seconds: 15)),
    );
    final body = _decodeBody(response);
    if (response.statusCode != 200) {
      if (response.statusCode == 401) await _tokenStore.delete();
      throw AuthApiException(
        _errorMessage(body, 'Could not update the task.'),
        statusCode: response.statusCode,
      );
    }
    return _parseTask(body['task']);
  }

  TaskModel _parseTask(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const AuthApiException('The server returned an invalid task.');
    }
    final id = value['id'];
    final title = value['title'];
    final description = value['description'];
    final projectCode = value['projectCode'];
    final projectName = value['projectName'];
    final assignee = value['assignee'];
    final status = value['status'];
    final priority = value['priority'];
    final dueDate = value['dueDate'];
    final progress = value['progress'];
    final version = value['version'];
    if ([
      id,
      title,
      description,
      projectCode,
      projectName,
      assignee,
      status,
      priority,
      dueDate,
    ].any((field) => field is! String)) {
      throw const AuthApiException('The server returned an incomplete task.');
    }
    const statusMap = {
      'todo': 'To Do',
      'in_progress': 'In Progress',
      'review': 'Review',
      'done': 'Done',
    };
    const priorityMap = {
      'low': 'Low',
      'medium': 'Medium',
      'high': 'High',
      'urgent': 'Urgent',
    };
    final normalizedStatus = statusMap[status];
    final normalizedPriority = priorityMap[priority];
    final parsedDueDate = DateTime.tryParse(dueDate as String);
    final parsedProgress = progress is num
        ? progress.toDouble()
        : double.tryParse('$progress');
    if (normalizedStatus == null ||
        normalizedPriority == null ||
        parsedDueDate == null ||
        parsedProgress == null ||
        !parsedProgress.isFinite ||
        parsedProgress < 0 ||
        parsedProgress > 1 ||
        version is! int ||
        version < 1) {
      throw const AuthApiException('The server returned invalid task fields.');
    }
    return TaskModel(
      id: id as String,
      title: title as String,
      description: description as String,
      projectCode: projectCode as String,
      projectName: projectName as String,
      assignee: assignee as String,
      status: normalizedStatus,
      priority: normalizedPriority,
      dueDate: parsedDueDate,
      progress: parsedProgress,
      version: version,
      color: switch (normalizedPriority) {
        'Urgent' => Colors.red,
        'High' => Colors.orange,
        'Medium' => Colors.blue,
        _ => Colors.green,
      },
    );
  }

  ProjectModel _parseProject(Object? project, String organizationId) {
    if (project is! Map<String, dynamic>) {
      throw const AuthApiException(
        'The server returned an invalid project record.',
      );
    }
    final id = project['id'];
    final code = project['code'];
    final name = project['name'];
    final location = project['location'];
    final status = project['status'];
    final client = project['clientName'] ?? '';
    final projectType = project['projectType'] ?? 'Commercial';
    final budgetAmount = project['budgetAmount'];
    final budgetCurrency = project['budgetCurrency'] ?? 'USD';
    final plannedStartDate = project['plannedStartDate'];
    final plannedEndDate = project['plannedEndDate'];
    final version = project['version'] ?? 1;
    if ([id, code, name, location, status].any((value) => value is! String)) {
      throw const AuthApiException(
        'The server returned an incomplete project record.',
      );
    }
    final normalizedStatus = _projectStatus(status as String);
    if (!{
      'Planning',
      'Active',
      'On Hold',
      'Completed',
      'Cancelled',
    }.contains(normalizedStatus)) {
      throw const AuthApiException(
        'The server returned an unsupported project status.',
      );
    }
    if (client is! String ||
        projectType is! String ||
        budgetCurrency is! String ||
        version is! int ||
        (budgetAmount != null &&
            budgetAmount is! num &&
            budgetAmount is! String) ||
        (plannedStartDate != null && plannedStartDate is! String) ||
        (plannedEndDate != null && plannedEndDate is! String)) {
      throw const AuthApiException(
        'The server returned invalid project metadata.',
      );
    }
    final startDate = _parseApiDate(plannedStartDate);
    final endDate = _parseApiDate(plannedEndDate);
    if ((plannedStartDate != null && startDate == null) ||
        (plannedEndDate != null && endDate == null) ||
        (startDate != null && endDate != null && endDate.isBefore(startDate))) {
      throw const AuthApiException(
        'The server returned invalid project schedule dates.',
      );
    }
    return ProjectModel(
      id: id as String,
      code: code as String,
      name: name as String,
      organizationId: organizationId,
      client: client,
      location: location as String,
      projectType: projectType,
      status: normalizedStatus,
      progress: 0,
      budget: budgetAmount == null
          ? ''
          : _formatBudget(budgetAmount, budgetCurrency),
      team: 0,
      plannedStartDate: startDate,
      plannedEndDate: endDate,
      version: version,
      color: Colors.blue,
      icon: Icons.apartment_rounded,
    );
  }

  Future<AuthUserModel> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _send(
      () => _httpClient
          .post(
            _endpoint('/v1/auth/login'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15)),
    );
    final body = _decodeBody(response);
    if (response.statusCode != 200) {
      throw AuthApiException(
        _errorMessage(body, 'Sign in failed.'),
        statusCode: response.statusCode,
      );
    }
    final token = body['accessToken'];
    if (token is! String || token.isEmpty) {
      throw const AuthApiException('The server returned an invalid session.');
    }

    try {
      final user = await _fetchCurrentUser(token);
      await _tokenStore.write(token);
      return user;
    } on Exception {
      await _revokeUnpersistedSession(token);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      final token = await _tokenStore.read();
      if (token != null && token.isNotEmpty) {
        final response = await _send(
          () => _httpClient
              .post(
                _endpoint('/v1/auth/logout'),
                headers: {'authorization': 'Bearer $token'},
              )
              .timeout(const Duration(seconds: 15)),
        );
        if (response.statusCode != 204 && response.statusCode != 401) {
          final body = _decodeBody(response);
          throw AuthApiException(
            _errorMessage(body, 'Could not revoke the server session.'),
            statusCode: response.statusCode,
          );
        }
      }
    } finally {
      await _tokenStore.delete();
    }
  }

  Future<AuthUserModel> _fetchCurrentUser(String token) async {
    final response = await _send(
      () => _httpClient
          .get(_endpoint('/v1/me'), headers: {'authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 15)),
    );
    final body = _decodeBody(response);
    if (response.statusCode != 200) {
      throw AuthApiException(
        _errorMessage(body, 'Could not verify the server session.'),
        statusCode: response.statusCode,
      );
    }

    final user = body['user'];
    final organizations = body['organizations'];
    if (user is! Map<String, dynamic> ||
        organizations is! List ||
        organizations.isEmpty ||
        organizations.first is! Map<String, dynamic>) {
      throw const AuthApiException(
        'The server returned an incomplete account profile.',
      );
    }
    if (organizations.length != 1) {
      throw const AuthApiException(
        'This account belongs to multiple companies. Company selection is '
        'not available yet; contact your administrator.',
      );
    }
    final organization = organizations.first as Map<String, dynamic>;
    final userId = user['id'];
    final name = user['name'];
    final email = user['email'];
    final organizationId = organization['id'];
    final organizationName = organization['name'];
    final role = organization['role'];
    if ([
      userId,
      name,
      email,
      organizationId,
      organizationName,
      role,
    ].any((value) => value is! String || value.isEmpty)) {
      throw const AuthApiException(
        'The server returned an invalid account profile.',
      );
    }
    final mappedRole = _applicationRole(role as String);
    if (mappedRole == null) {
      throw const AuthApiException(
        'The server returned an unsupported account role.',
      );
    }
    return AuthUserModel(
      id: userId as String,
      name: name as String,
      email: email as String,
      role: mappedRole,
      organization: organizationName as String,
      organizationId: organizationId as String,
      status: 'Approved',
    );
  }

  Future<void> _revokeUnpersistedSession(String token) async {
    final response = await _send(
      () => _httpClient
          .post(
            _endpoint('/v1/auth/logout'),
            headers: {'authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15)),
    );
    if (response.statusCode != 204 && response.statusCode != 401) {
      final body = _decodeBody(response);
      throw AuthApiException(
        _errorMessage(body, 'Could not revoke the incomplete server session.'),
        statusCode: response.statusCode,
      );
    }
  }

  static String? _applicationRole(String role) => switch (role) {
    'owner' => 'Owner',
    'admin' => 'Super Admin',
    'project_manager' => 'Project Manager',
    'hr_manager' => 'HR Manager',
    'viewer' => 'Viewer',
    'member' => 'Employee',
    _ => null,
  };

  static String _projectStatus(String status) => switch (status) {
    'planning' => 'Planning',
    'active' => 'Active',
    'on_hold' => 'On Hold',
    'completed' => 'Completed',
    'cancelled' => 'Cancelled',
    _ => status,
  };

  static String _apiProjectStatus(String status) => switch (status) {
    'Planning' => 'planning',
    'Active' => 'active',
    'On Hold' => 'on_hold',
    'Completed' => 'completed',
    'Cancelled' => 'cancelled',
    _ => throw AuthApiException('Unsupported project status: $status'),
  };

  static DateTime? _parseApiDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static String _budgetAmount(String budget) {
    if (budget.isEmpty) return '';
    final amount = budget
        .trim()
        .replaceAll(',', '')
        .replaceFirst(RegExp(r'^\$'), '')
        .replaceFirst(RegExp(r'^[A-Z]{3}\s+'), '');
    if (!RegExp(r'^\d{1,18}(\.\d{1,2})?$').hasMatch(amount)) {
      throw const AuthApiException(
        'Budget must be a non-negative amount with up to two decimals.',
      );
    }
    return amount;
  }

  static String _budgetCurrency(String budget) {
    final match = RegExp(r'^([A-Z]{3})\s+').firstMatch(budget.trim());
    return match?.group(1) ?? 'USD';
  }

  static String _formatBudget(Object amount, String currency) {
    final normalized = '$amount'.replaceFirst(RegExp(r'\.00$'), '');
    return '$currency $normalized';
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request();
    } on AuthApiException {
      rethrow;
    } on Exception {
      throw const AuthApiException(
        'Could not reach the StructFlow server. Check the connection and try again.',
      );
    }
  }

  static Map<String, dynamic> _decodeBody(http.Response response) {
    if (response.bodyBytes.length > 64 * 1024) {
      throw const AuthApiException('The server response was too large.');
    }
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      throw const AuthApiException('The server returned an invalid response.');
    }
    throw const AuthApiException('The server returned an invalid response.');
  }

  static String _errorMessage(Map<String, dynamic> body, String fallback) {
    final message = body['error'];
    return message is String && message.isNotEmpty ? message : fallback;
  }
}
