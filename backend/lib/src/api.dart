import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'config.dart';
import 'database.dart';
import 'security.dart';

class StructFlowApi {
  StructFlowApi({
    required this.config,
    required this.database,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       _rateLimiter = LoginRateLimiter(clock: clock);

  static const _sessionLifetime = Duration(hours: 8);

  final AppConfig config;
  final AppDatabase database;
  final DateTime Function() _clock;
  final LoginRateLimiter _rateLimiter;
  final Random _random = Random.secure();

  Handler get handler {
    final router = Router()
      ..get('/healthz', _health)
      ..post('/v1/auth/organizations', _registerOrganization)
      ..post('/v1/auth/login', _login)
      ..post('/v1/auth/logout', _logout)
      ..get('/v1/me', _me)
      ..get('/v1/projects', _listProjects)
      ..get('/v1/projects/<projectIdentifier>', _getProject)
      ..get('/v1/projects/<projectIdentifier>/members', _listProjectMembers)
      ..get('/v1/projects/<projectIdentifier>/bim/models', _listBimModels)
      ..post('/v1/projects/<projectIdentifier>/bim/models', _createBimModel)
      ..patch('/v1/bim/models/<modelId>', _updateBimModelStatus)
      ..get('/v1/projects/<projectIdentifier>/bim/issues', _listBimIssues)
      ..post('/v1/projects/<projectIdentifier>/bim/issues', _createBimIssue)
      ..post(
        '/v1/projects/<projectIdentifier>/bim/issues/import',
        _importBimIssues,
      )
      ..patch('/v1/bim/issues/<issueId>', _updateBimIssueStatus)
      ..get('/v1/bim/issues/<issueId>/comments', _listBimIssueComments)
      ..post('/v1/bim/issues/<issueId>/comments', _createBimIssueComment)
      ..post(
        '/v1/bim/issues/<issueId>/comments/import',
        _importBimIssueComments,
      )
      ..get(
        '/v1/projects/<projectIdentifier>/bim/comments',
        _listProjectBimComments,
      )
      ..post(
        '/v1/projects/<projectIdentifier>/bim/comments/import',
        _importProjectBimComments,
      )
      ..patch('/v1/projects/<projectIdentifier>', _updateProject)
      ..post('/v1/projects', _createProject)
      ..get('/v1/tasks', _listTasks)
      ..post('/v1/tasks', _createTask)
      ..get('/v1/tasks/<taskId>', _getTask)
      ..patch('/v1/tasks/<taskId>', _updateTask);

    return Pipeline()
        .addMiddleware(_securityHeaders())
        .addMiddleware(_cors(config.allowedOrigins))
        .addMiddleware(_errorHandler())
        .addHandler(router.call);
  }

  Future<Response> _health(Request request) async {
    await database.verifyConnection();
    return _json(200, {'status': 'ok'});
  }

  Future<Response> _registerOrganization(Request request) async {
    if (!config.registrationEnabled) {
      return _json(403, {'error': 'Organization signup is disabled.'});
    }

    final rateLimited = _checkRateLimit(request);
    if (rateLimited != null) return rateLimited;

    final body = await _readJson(request);
    final name = _boundedString(body, 'name', minimum: 2, maximum: 160);
    final organization = _boundedString(
      body,
      'organizationName',
      minimum: 2,
      maximum: 160,
    );
    final email = _normalizedEmail(body['email']);
    final password = _passwordString(body);
    if (password == null) {
      return _json(400, {'error': 'A password is required.'});
    }
    if (email == null) {
      return _json(400, {'error': 'A valid email address is required.'});
    }
    final passwordError = PasswordSecurity.validationError(password);
    if (passwordError != null) {
      return _json(400, {'error': passwordError});
    }

    final passwordHash = await PasswordSecurity.hashPasswordAsync(password);
    final sessionToken = SessionTokens.create();
    final expiresAt = _clock().toUtc().add(_sessionLifetime);
    final result = await database.pool.runTx((transaction) async {
      final user = await transaction.execute(
        Sql.named('''
          INSERT INTO users (full_name, email, password_hash)
          VALUES (@name, @email, @passwordHash)
          RETURNING id
        '''),
        parameters: {
          'name': name,
          'email': email,
          'passwordHash': passwordHash,
        },
      );
      final userId = user.first.toColumnMap()['id'];
      final organizationResult = await transaction.execute(
        Sql.named('''
          INSERT INTO organizations (name, slug)
          VALUES (@name, @slug)
          RETURNING id
        '''),
        parameters: {
          'name': organization,
          'slug':
              '${_slug(organization)}-${_random.nextInt(1 << 32).toRadixString(16)}',
        },
      );
      final organizationId = organizationResult.first.toColumnMap()['id'];
      await transaction.execute(
        Sql.named('''
          INSERT INTO memberships (organization_id, user_id, role)
          VALUES (@organizationId, @userId, 'owner')
        '''),
        parameters: {'organizationId': organizationId, 'userId': userId},
      );
      await _setTenantContext(
        transaction,
        organizationId: organizationId as Object,
        userId: userId as Object,
      );
      await _insertSession(transaction, userId, sessionToken, expiresAt);
      await _insertAuditEvent(
        transaction,
        organizationId: organizationId,
        actorUserId: userId,
        action: 'organization.created',
        entityType: 'organization',
        entityId: '$organizationId',
      );
      return {
        'userId': '$userId',
        'organizationId': '$organizationId',
        'organizationName': organization,
      };
    });

    return _json(201, {
      ...result,
      'accessToken': sessionToken,
      'tokenType': 'Bearer',
      'expiresAt': expiresAt.toIso8601String(),
    });
  }

  Future<Response> _login(Request request) async {
    final rateLimited = _checkRateLimit(request);
    if (rateLimited != null) return rateLimited;

    final body = await _readJson(request);
    final email = _normalizedEmail(body['email']);
    final password = _passwordString(body);
    if (email == null || password == null) {
      return _json(400, {'error': 'A valid email and password are required.'});
    }
    if (utf8.encode(password).length > 72) {
      return _json(400, {'error': 'Password must not exceed 72 UTF-8 bytes.'});
    }

    final users = await database.pool.execute(
      Sql.named('''
        SELECT id, full_name, email, password_hash, status
        FROM users
        WHERE lower(email) = @email
        LIMIT 1
      '''),
      parameters: {'email': email},
    );
    final user = users.isEmpty ? null : users.first.toColumnMap();
    final matches = user == null
        ? await PasswordSecurity.verifyUnknownUserPassword(password)
        : await PasswordSecurity.verifyPasswordAsync(
            password,
            '${user['password_hash']}',
          );
    if (user == null || user['status'] != 'active' || !matches) {
      return _json(401, {'error': 'Invalid email or password.'});
    }

    final memberships = await database.pool.execute(
      Sql.named('''
        SELECT o.id AS organization_id, o.name AS organization_name, m.role
        FROM memberships m
        JOIN organizations o ON o.id = m.organization_id
        WHERE m.user_id = @userId
          AND m.status = 'active'
          AND o.status = 'active'
        ORDER BY o.name
      '''),
      parameters: {'userId': user['id']},
    );
    if (memberships.isEmpty) {
      return _json(403, {'error': 'No active organization membership.'});
    }

    final sessionToken = SessionTokens.create();
    final expiresAt = _clock().toUtc().add(_sessionLifetime);
    await database.pool.execute(
      Sql.named('''
        INSERT INTO sessions (token_hash, user_id, expires_at)
        VALUES (@tokenHash, @userId, @expiresAt)
      '''),
      parameters: {
        'tokenHash': SessionTokens.digest(sessionToken),
        'userId': user['id'],
        'expiresAt': expiresAt,
      },
    );

    return _json(200, {
      'accessToken': sessionToken,
      'tokenType': 'Bearer',
      'expiresAt': expiresAt.toIso8601String(),
      'user': {
        'id': '${user['id']}',
        'name': '${user['full_name']}',
        'email': '${user['email']}',
      },
      'organizations': memberships
          .map((membership) => membership.toColumnMap())
          .map(
            (membership) => {
              'id': '${membership['organization_id']}',
              'name': '${membership['organization_name']}',
              'role': '${membership['role']}',
            },
          )
          .toList(),
    });
  }

  Future<Response> _logout(Request request) async {
    final session = await _authenticatedSession(request);
    if (session == null) {
      return _unauthorized();
    }
    await database.pool.execute(
      Sql.named('''
        UPDATE sessions
        SET revoked_at = @now
        WHERE token_hash = @tokenHash
          AND revoked_at IS NULL
      '''),
      parameters: {'now': _clock().toUtc(), 'tokenHash': session.tokenHash},
    );
    return Response(204);
  }

  Future<Response> _me(Request request) async {
    final session = await _authenticatedSession(request);
    if (session == null) return _unauthorized();

    final result = await database.pool.execute(
      Sql.named('''
        SELECT u.id, u.full_name, u.email,
               o.id AS organization_id, o.name AS organization_name, m.role
        FROM users u
        JOIN memberships m ON m.user_id = u.id AND m.status = 'active'
        JOIN organizations o ON o.id = m.organization_id AND o.status = 'active'
        WHERE u.id = @userId AND u.status = 'active'
        ORDER BY o.name
      '''),
      parameters: {'userId': session.userId},
    );
    if (result.isEmpty) {
      return _json(403, {'error': 'No active organization membership.'});
    }
    final user = result.first.toColumnMap();
    return _json(200, {
      'user': {
        'id': '${user['id']}',
        'name': '${user['full_name']}',
        'email': '${user['email']}',
      },
      'organizations': result
          .map((row) => row.toColumnMap())
          .map(
            (row) => {
              'id': '${row['organization_id']}',
              'name': '${row['organization_name']}',
              'role': '${row['role']}',
            },
          )
          .toList(),
    });
  }

  Future<Response> _listProjects(Request request) async {
    final access = await _organizationAccess(request);
    if (access.response != null) return access.response!;

    final projects = await database.pool.runTx((transaction) async {
      await _setTenantContext(
        transaction,
        organizationId: access.organizationId!,
        userId: access.userId!,
      );
      return transaction.execute(
        Sql.named('''
          SELECT p.id, p.code, p.name, p.status, p.location, p.created_at,
                 p.updated_at, p.client_name, p.project_type, p.budget_amount,
                 p.budget_currency, p.planned_start_date, p.planned_end_date,
                 p.version
          FROM projects p
          WHERE p.organization_id = @organizationId
            AND (
              @organizationWide OR EXISTS (
                SELECT 1
                FROM project_memberships pm
                WHERE pm.organization_id = p.organization_id
                  AND pm.project_id = p.id
                  AND pm.user_id = @userId
                  AND pm.status = 'active'
              )
            )
          ORDER BY p.created_at DESC
          LIMIT 500
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'userId': access.userId,
          'organizationWide': ProjectAccessPolicy.canListAllProjects(
            access.role!,
          ),
        },
      );
    });
    return _json(200, {
      'projects': projects
          .map((row) => _projectJson(row.toColumnMap()))
          .toList(),
    });
  }

  Future<Response> _listTasks(Request request) async {
    final access = await _organizationAccess(request);
    if (access.response != null) return access.response!;
    final projectCode = request.url.queryParameters['projectCode'];
    if (projectCode != null &&
        (projectCode.isEmpty || projectCode.length > 40)) {
      return _json(400, {'error': 'Project code filter is invalid.'});
    }

    final rows = await database.pool.runTx((transaction) async {
      await _setTenantContext(
        transaction,
        organizationId: access.organizationId!,
        userId: access.userId!,
      );
      return transaction.execute(
        Sql.named('''
          SELECT t.id, t.title, t.description, t.status, t.priority,
                 t.assigned_user_id,
                 t.due_date, t.progress, t.version, p.code AS project_code,
                 p.name AS project_name,
                 COALESCE(u.full_name, 'Unassigned') AS assignee
          FROM tasks t
          JOIN projects p
            ON p.organization_id = t.organization_id
           AND p.id = t.project_id
          LEFT JOIN users u ON u.id = t.assigned_user_id
          WHERE t.organization_id = @organizationId
            AND (CAST(@projectCode AS text) IS NULL OR p.code = @projectCode)
          ORDER BY t.due_date NULLS LAST, t.created_at DESC
          LIMIT 500
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'projectCode': projectCode,
        },
      );
    });

    return _json(200, {
      'tasks': rows.map((row) => _taskJson(row.toColumnMap())).toList(),
    });
  }

  Future<Response> _getTask(Request request, String taskId) async {
    final access = await _organizationAccess(request);
    if (access.response != null) return access.response!;
    if (!_isUuid(taskId)) {
      return _json(400, {'error': 'Task identifier is invalid.'});
    }

    final rows = await database.pool.runTx((transaction) async {
      await _setTenantContext(
        transaction,
        organizationId: access.organizationId!,
        userId: access.userId!,
      );
      return transaction.execute(
        Sql.named('''
          SELECT t.id, t.title, t.description, t.status, t.priority,
                 t.assigned_user_id,
                 t.due_date, t.progress, t.version, p.code AS project_code,
                 p.name AS project_name,
                 COALESCE(u.full_name, 'Unassigned') AS assignee
          FROM tasks t
          JOIN projects p
            ON p.organization_id = t.organization_id
           AND p.id = t.project_id
          LEFT JOIN users u ON u.id = t.assigned_user_id
          WHERE t.organization_id = @organizationId
            AND t.id = @taskId
          LIMIT 1
        '''),
        parameters: {'organizationId': access.organizationId, 'taskId': taskId},
      );
    });
    if (rows.isEmpty) return _json(404, {'error': 'Task not found.'});
    return _json(200, {'task': _taskJson(rows.first.toColumnMap())});
  }

  Future<Response> _updateTask(Request request, String taskId) async {
    final access = await _organizationAccess(request);
    if (access.response != null) return access.response!;
    if (!_isUuid(taskId)) {
      return _json(400, {'error': 'Task identifier is invalid.'});
    }

    final body = await _readJson(request);
    final expectedVersion = body['expectedVersion'];
    final assigneeInput = body['assignedUserId'];
    final title = _boundedString(body, 'title', minimum: 2, maximum: 200);
    final description = _boundedString(
      body,
      'description',
      minimum: 0,
      maximum: 10000,
    );
    const statuses = {'todo', 'in_progress', 'review', 'done'};
    const priorities = {'low', 'medium', 'high', 'urgent'};
    final status = body['status'];
    final priority = body['priority'];
    final dueDate = _parseDateOnly(body['dueDate']);
    final progressValue = body['progress'];
    final progress = progressValue is num
        ? progressValue.toDouble()
        : double.tryParse('$progressValue');
    if (expectedVersion is! int ||
        expectedVersion < 1 ||
        (body.containsKey('assignedUserId') &&
            assigneeInput != null &&
            (assigneeInput is! String || !_isUuid(assigneeInput))) ||
        status is! String ||
        !statuses.contains(status) ||
        priority is! String ||
        !priorities.contains(priority) ||
        dueDate == null ||
        progress == null ||
        !progress.isFinite ||
        progress < 0 ||
        progress > 1) {
      return _json(400, {'error': 'Task fields are invalid.'});
    }

    final outcome = await database.pool.runTx((transaction) async {
      await _setTenantContext(
        transaction,
        organizationId: access.organizationId!,
        userId: access.userId!,
      );
      final rows = await transaction.execute(
        Sql.named('''
          SELECT t.id, t.project_id, t.version, t.assigned_user_id,
                 (
                   @organizationWide OR EXISTS (
                     SELECT 1
                     FROM project_memberships pm
                     WHERE pm.organization_id = t.organization_id
                       AND pm.project_id = t.project_id
                       AND pm.user_id = @userId
                       AND pm.role = 'project_manager'
                       AND pm.status = 'active'
                   )
                 ) AS can_update
          FROM tasks t
          WHERE t.organization_id = @organizationId
            AND t.id = @taskId
          FOR UPDATE
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'taskId': taskId,
          'userId': access.userId,
          'organizationWide':
              ProjectAccessPolicy.canCreateTaskAcrossOrganization(access.role!),
        },
      );
      if (rows.isEmpty) return {'kind': 'not_found'};
      final current = rows.first.toColumnMap();
      if (current['can_update'] != true) return {'kind': 'forbidden'};
      final version = current['version'] as int;
      if (version != expectedVersion) {
        return {'kind': 'conflict', 'currentVersion': version};
      }
      final assignedUserId = body.containsKey('assignedUserId')
          ? assigneeInput as String?
          : current['assigned_user_id']?.toString();
      if (assignedUserId != null &&
          assignedUserId != current['assigned_user_id']?.toString()) {
        final assignees = await transaction.execute(
          Sql.named('''
            SELECT pm.user_id
            FROM project_memberships pm
            JOIN memberships m
              ON m.organization_id = pm.organization_id
             AND m.user_id = pm.user_id
            JOIN users u ON u.id = pm.user_id
            WHERE pm.organization_id = @organizationId
              AND pm.project_id = @projectId
              AND pm.user_id = @assignedUserId
              AND pm.role IN ('project_manager', 'contributor')
              AND pm.status = 'active'
              AND m.status = 'active'
              AND u.status = 'active'
            LIMIT 1
          '''),
          parameters: {
            'organizationId': access.organizationId,
            'projectId': current['project_id'],
            'assignedUserId': assignedUserId,
          },
        );
        if (assignees.isEmpty) return {'kind': 'invalid_assignee'};
      }

      final updatedRows = await transaction.execute(
        Sql.named('''
          UPDATE tasks
          SET title = @title,
              description = @description,
              status = @status,
              priority = @priority,
              due_date = CAST(@dueDate AS date),
              progress = @progress,
              assigned_user_id = CAST(@assignedUserId AS uuid),
              version = version + 1,
              updated_at = now()
          WHERE organization_id = @organizationId
            AND id = @taskId
            AND version = @expectedVersion
          RETURNING id
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'taskId': taskId,
          'expectedVersion': expectedVersion,
          'title': title.trim(),
          'description': description.trim(),
          'status': status,
          'priority': priority,
          'dueDate': _dateOnly(dueDate),
          'progress': progress,
          'assignedUserId': assignedUserId,
        },
      );
      if (updatedRows.isEmpty) {
        return {'kind': 'conflict', 'currentVersion': version};
      }
      await _insertAuditEvent(
        transaction,
        organizationId: access.organizationId!,
        actorUserId: access.userId!,
        action: 'task.updated',
        entityType: 'task',
        entityId: taskId,
        metadata: {
          'previousVersion': version,
          'version': version + 1,
          if (assignedUserId != current['assigned_user_id']?.toString())
            'assignedUserId': assignedUserId,
        },
      );
      final taskRows = await transaction.execute(
        Sql.named('''
          SELECT t.id, t.title, t.description, t.status, t.priority,
                 t.assigned_user_id, t.due_date, t.progress, t.version,
                 p.code AS project_code,
                 p.name AS project_name,
                 COALESCE(u.full_name, 'Unassigned') AS assignee
          FROM tasks t
          JOIN projects p
            ON p.organization_id = t.organization_id
           AND p.id = t.project_id
          LEFT JOIN users u ON u.id = t.assigned_user_id
          WHERE t.organization_id = @organizationId
            AND t.id = @taskId
          LIMIT 1
        '''),
        parameters: {'organizationId': access.organizationId, 'taskId': taskId},
      );
      if (taskRows.isEmpty) {
        throw StateError('Updated task was not visible to its editor.');
      }
      return {'kind': 'updated', 'task': taskRows.first.toColumnMap()};
    });

    return switch (outcome['kind']) {
      'not_found' => _json(404, {'error': 'Task not found.'}),
      'forbidden' => _json(403, {'error': 'Insufficient permissions.'}),
      'invalid_assignee' => _json(400, {
        'error':
            'Assignee must be an active non-viewer member of this project.',
      }),
      'conflict' => _json(409, {
        'error': 'Task was changed by another user. Reload before saving.',
        'currentVersion': outcome['currentVersion'],
      }),
      'updated' => _json(200, {
        'task': _taskJson(outcome['task'] as Map<String, dynamic>),
      }),
      _ => throw StateError('Unexpected task update result.'),
    };
  }

  Map<String, Object?> _taskJson(Map<String, dynamic> row) => {
    'id': '${row['id']}',
    'title': '${row['title']}',
    'description': '${row['description']}',
    'projectCode': '${row['project_code']}',
    'projectName': '${row['project_name']}',
    'assignee': '${row['assignee']}',
    'assignedUserId': row['assigned_user_id']?.toString(),
    'status': '${row['status']}',
    'priority': '${row['priority']}',
    'dueDate': _dateOnly(row['due_date']),
    'progress': row['progress']?.toString(),
    'version': row['version'],
  };

  static bool _isUuid(String value) => RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);

  Future<Response> _createTask(Request request) async {
    final access = await _organizationAccess(request);
    if (access.response != null) return access.response!;

    final body = await _readJson(request);
    final projectCode = _boundedString(
      body,
      'projectCode',
      minimum: 1,
      maximum: 40,
    );
    final title = _boundedString(body, 'title', minimum: 2, maximum: 200);
    final description = _boundedString(
      body,
      'description',
      minimum: 0,
      maximum: 10000,
    );
    final priority = body['priority'] ?? 'medium';
    final dueDate = _parseDateOnly(body['dueDate']);
    final assigneeInput = body['assignedUserId'];
    if (priority is! String ||
        !{'low', 'medium', 'high', 'urgent'}.contains(priority) ||
        dueDate == null ||
        (body.containsKey('assignedUserId') &&
            assigneeInput != null &&
            (assigneeInput is! String || !_isUuid(assigneeInput)))) {
      return _json(400, {'error': 'Task fields are invalid.'});
    }

    final outcome = await database.pool.runTx((transaction) async {
      await _setTenantContext(
        transaction,
        organizationId: access.organizationId!,
        userId: access.userId!,
      );
      final projects = await transaction.execute(
        Sql.named('''
          SELECT p.id
          FROM projects p
          WHERE p.organization_id = @organizationId
            AND p.code = @projectCode
            AND (
              @organizationWide OR EXISTS (
                SELECT 1
                FROM project_memberships pm
                WHERE pm.organization_id = p.organization_id
                  AND pm.project_id = p.id
                  AND pm.user_id = @userId
                  AND pm.role = 'project_manager'
                  AND pm.status = 'active'
              )
            )
          LIMIT 1
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'projectCode': projectCode,
          'userId': access.userId,
          'organizationWide':
              ProjectAccessPolicy.canCreateTaskAcrossOrganization(access.role!),
        },
      );
      if (projects.isEmpty) return {'kind': 'not_found'};

      final projectId = projects.first.toColumnMap()['id'];
      if (assigneeInput != null) {
        final assignees = await transaction.execute(
          Sql.named('''
            SELECT pm.user_id
            FROM project_memberships pm
            JOIN memberships m
              ON m.organization_id = pm.organization_id
             AND m.user_id = pm.user_id
            JOIN users u ON u.id = pm.user_id
            WHERE pm.organization_id = @organizationId
              AND pm.project_id = @projectId
              AND pm.user_id = @assignedUserId
              AND pm.role IN ('project_manager', 'contributor')
              AND pm.status = 'active'
              AND m.status = 'active'
              AND u.status = 'active'
            LIMIT 1
          '''),
          parameters: {
            'organizationId': access.organizationId,
            'projectId': projectId,
            'assignedUserId': assigneeInput,
          },
        );
        if (assignees.isEmpty) return {'kind': 'invalid_assignee'};
      }
      final created = await transaction.execute(
        Sql.named('''
          INSERT INTO tasks (
            organization_id, project_id, title, description, status, priority,
            assigned_user_id, due_date, progress, created_by
          )
          VALUES (
            @organizationId, @projectId, @title, @description, 'todo',
            @priority, @assignedUserId, CAST(@dueDate AS date), 0, @userId
          )
          RETURNING id, title, description, status, priority, due_date, progress,
                    version
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'projectId': projectId,
          'title': title.trim(),
          'description': description.trim(),
          'priority': priority,
          'assignedUserId': assigneeInput,
          'dueDate': _dateOnly(dueDate),
          'userId': access.userId,
        },
      );
      final task = created.first.toColumnMap();
      await _insertAuditEvent(
        transaction,
        organizationId: access.organizationId!,
        actorUserId: access.userId!,
        action: 'task.created',
        entityType: 'task',
        entityId: '${task['id']}',
        metadata: {
          'projectCode': projectCode,
          'priority': priority,
          'assignedUserId': assigneeInput,
        },
      );
      final taskRows = await transaction.execute(
        Sql.named('''
          SELECT t.id, t.title, t.description, t.status, t.priority,
                 t.assigned_user_id, t.due_date, t.progress, t.version,
                 p.code AS project_code, p.name AS project_name,
                 COALESCE(u.full_name, 'Unassigned') AS assignee
          FROM tasks t
          JOIN projects p
            ON p.organization_id = t.organization_id
           AND p.id = t.project_id
          LEFT JOIN users u ON u.id = t.assigned_user_id
          WHERE t.organization_id = @organizationId
            AND t.id = @taskId
          LIMIT 1
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'taskId': task['id'],
        },
      );
      if (taskRows.isEmpty) {
        throw StateError('Created task was not visible to its creator.');
      }
      return {'kind': 'created', 'task': taskRows.first.toColumnMap()};
    });
    if (outcome['kind'] == 'invalid_assignee') {
      return _json(400, {
        'error':
            'Assignee must be an active non-viewer member of this project.',
      });
    }
    if (outcome['kind'] == 'not_found') {
      return _json(404, {'error': 'Project not found or access denied.'});
    }
    if (outcome['kind'] != 'created') {
      throw StateError('Unexpected task creation result.');
    }

    final row = outcome['task'] as Map<String, dynamic>;
    return _json(201, {'task': _taskJson(row)});
  }

  Future<Response> _listProjectMembers(
    Request request,
    String projectIdentifier,
  ) async {
    final access = await _organizationAccess(request);
    if (access.response != null) return access.response!;
    if (projectIdentifier.isEmpty || projectIdentifier.length > 200) {
      return _json(400, {'error': 'Project identifier is invalid.'});
    }

    final result = await database.pool.runTx((transaction) async {
      await _setTenantContext(
        transaction,
        organizationId: access.organizationId!,
        userId: access.userId!,
      );
      final projects = await transaction.execute(
        Sql.named('''
          SELECT p.id, p.code
          FROM projects p
          WHERE p.organization_id = @organizationId
            AND (p.id::text = @identifier OR p.code = @identifier)
            AND (
              @organizationWide OR EXISTS (
                SELECT 1
                FROM project_memberships current_pm
                WHERE current_pm.organization_id = p.organization_id
                  AND current_pm.project_id = p.id
                  AND current_pm.user_id = @userId
                  AND current_pm.status = 'active'
              )
            )
          LIMIT 1
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'identifier': projectIdentifier,
          'userId': access.userId,
          'organizationWide': ProjectAccessPolicy.canListAllProjects(
            access.role!,
          ),
        },
      );
      if (projects.isEmpty) return null;
      final project = projects.first.toColumnMap();
      final members = await transaction.execute(
        Sql.named('''
          SELECT pm.user_id, u.full_name, pm.role
          FROM project_memberships pm
          JOIN memberships m
            ON m.organization_id = pm.organization_id
           AND m.user_id = pm.user_id
          JOIN users u ON u.id = pm.user_id
          WHERE pm.organization_id = @organizationId
            AND pm.project_id = @projectId
            AND pm.role IN ('project_manager', 'contributor')
            AND pm.status = 'active'
            AND m.status = 'active'
            AND u.status = 'active'
          ORDER BY u.full_name, pm.user_id
          LIMIT 500
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'projectId': project['id'],
        },
      );
      return {
        'projectCode': '${project['code']}',
        'members': members.map((member) {
          final row = member.toColumnMap();
          return {
            'id': '${row['user_id']}',
            'name': '${row['full_name']}',
            'role': '${row['role']}',
          };
        }).toList(),
      };
    });
    if (result == null) return _json(404, {'error': 'Project not found.'});
    return _json(200, {
      'projectCode': result['projectCode'],
      'members': result['members'],
    });
  }

  Future<Response> _listBimIssues(
    Request request,
    String projectIdentifier,
  ) async {
    final access = await _organizationAccess(request);
    if (access.response != null) return access.response!;
    if (projectIdentifier.isEmpty || projectIdentifier.length > 200) {
      return _json(400, {'error': 'Project identifier is invalid.'});
    }

    final result = await database.pool.runTx((transaction) async {
      await _setTenantContext(
        transaction,
        organizationId: access.organizationId!,
        userId: access.userId!,
      );
      final projects = await transaction.execute(
        Sql.named('''
          SELECT p.id, p.code
          FROM projects p
          WHERE p.organization_id = @organizationId
            AND (p.id::text = @identifier OR p.code = @identifier)
            AND (
              @organizationWide OR EXISTS (
                SELECT 1
                FROM project_memberships pm
                WHERE pm.organization_id = p.organization_id
                  AND pm.project_id = p.id
                  AND pm.user_id = @userId
                  AND pm.status = 'active'
              )
            )
          LIMIT 1
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'identifier': projectIdentifier,
          'userId': access.userId,
          'organizationWide': ProjectAccessPolicy.canListAllProjects(
            access.role!,
          ),
        },
      );
      if (projects.isEmpty) return null;
      final project = projects.first.toColumnMap();
      final issues = await transaction.execute(
        Sql.named('''
          SELECT id, bcf_guid, title, description, discipline, location,
                 severity, status, assigned_to, due_date, version,
                 created_at, updated_at
          FROM bim_issues
          WHERE organization_id = @organizationId
            AND project_id = @projectId
          ORDER BY
            CASE status WHEN 'open' THEN 0
                        WHEN 'in_progress' THEN 1 ELSE 2 END,
            due_date,
            created_at DESC
          LIMIT 500
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'projectId': project['id'],
        },
      );
      return {
        'projectCode': '${project['code']}',
        'issues': issues
            .map((row) => _bimIssueJson(row.toColumnMap()))
            .toList(),
      };
    });
    if (result == null) return _json(404, {'error': 'Project not found.'});
    return _json(200, result);
  }

  Future<Response> _listBimModels(
    Request request,
    String projectIdentifier,
  ) async {
    final access = await _organizationAccess(request);
    if (access.response != null) return access.response!;
    if (projectIdentifier.isEmpty || projectIdentifier.length > 200) {
      return _json(400, {'error': 'Project identifier is invalid.'});
    }

    final result = await database.pool.runTx((transaction) async {
      await _setTenantContext(
        transaction,
        organizationId: access.organizationId!,
        userId: access.userId!,
      );
      final projects = await transaction.execute(
        Sql.named('''
          SELECT p.id, p.code
          FROM projects p
          WHERE p.organization_id = @organizationId
            AND (p.id::text = @identifier OR p.code = @identifier)
            AND (
              @organizationWide OR EXISTS (
                SELECT 1
                FROM project_memberships pm
                WHERE pm.organization_id = p.organization_id
                  AND pm.project_id = p.id
                  AND pm.user_id = @userId
                  AND pm.status = 'active'
              )
            )
          LIMIT 1
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'identifier': projectIdentifier,
          'userId': access.userId,
          'organizationWide': ProjectAccessPolicy.canListAllProjects(
            access.role!,
          ),
        },
      );
      if (projects.isEmpty) return null;
      final project = projects.first.toColumnMap();
      final models = await transaction.execute(
        Sql.named('''
          SELECT id, name, discipline, revision, status, version, updated_at
          FROM bim_models
          WHERE organization_id = @organizationId
            AND project_id = @projectId
          ORDER BY updated_at DESC, created_at DESC
          LIMIT 500
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'projectId': project['id'],
        },
      );
      return {
        'projectCode': '${project['code']}',
        'models': models
            .map((row) => _bimModelJson(row.toColumnMap()))
            .toList(),
      };
    });
    if (result == null) return _json(404, {'error': 'Project not found.'});
    return _json(200, result);
  }

  Future<Response> _createBimModel(
    Request request,
    String projectIdentifier,
  ) async {
    final access = await _organizationAccess(request);
    if (access.response != null) return access.response!;
    if (projectIdentifier.isEmpty || projectIdentifier.length > 200) {
      return _json(400, {'error': 'Project identifier is invalid.'});
    }

    late final String name;
    late final String discipline;
    late final String revision;
    try {
      final body = await _readJson(request);
      final nameValue = body['name'];
      final disciplineValue = body['discipline'];
      final revisionValue = body['version'];
      if (nameValue is! String ||
          disciplineValue is! String ||
          revisionValue is! String) {
        throw const FormatException('BIM model fields are invalid.');
      }
      name = nameValue.trim();
      discipline = disciplineValue.trim();
      revision = revisionValue.trim();
      if (name.length < 2 ||
          name.length > 200 ||
          discipline.isEmpty ||
          discipline.length > 120 ||
          revision.isEmpty ||
          revision.length > 80) {
        throw const FormatException('BIM model fields are invalid.');
      }
    } on FormatException catch (error) {
      return _json(400, {'error': error.message});
    }

    final result = await database.pool.runTx((transaction) async {
      await _setTenantContext(
        transaction,
        organizationId: access.organizationId!,
        userId: access.userId!,
      );
      final projects = await transaction.execute(
        Sql.named('''
          SELECT p.id, p.code
          FROM projects p
          WHERE p.organization_id = @organizationId
            AND (p.id::text = @identifier OR p.code = @identifier)
            AND (
              @organizationWide OR EXISTS (
                SELECT 1
                FROM project_memberships pm
                WHERE pm.organization_id = p.organization_id
                  AND pm.project_id = p.id
                  AND pm.user_id = @userId
                  AND pm.role IN ('project_manager', 'contributor')
                  AND pm.status = 'active'
              )
            )
          LIMIT 1
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'identifier': projectIdentifier,
          'userId': access.userId,
          'organizationWide': ProjectAccessPolicy.canListAllProjects(
            access.role!,
          ),
        },
      );
      if (projects.isEmpty) return null;
      final project = projects.first.toColumnMap();
      final created = await transaction.execute(
        Sql.named('''
          INSERT INTO bim_models (
            organization_id, project_id, name, discipline, revision, created_by
          )
          VALUES (
            @organizationId, @projectId, @name, @discipline, @revision, @userId
          )
          RETURNING id, name, discipline, revision, status, version, updated_at
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'projectId': project['id'],
          'name': name,
          'discipline': discipline,
          'revision': revision,
          'userId': access.userId,
        },
      );
      final row = created.first.toColumnMap();
      await _insertAuditEvent(
        transaction,
        organizationId: access.organizationId!,
        actorUserId: access.userId!,
        action: 'bim_model.registered',
        entityType: 'bim_model',
        entityId: '${row['id']}',
        metadata: {
          'projectCode': project['code'],
          'discipline': discipline,
          'revision': revision,
        },
      );
      return _bimModelJson(row);
    });
    if (result == null) {
      return _json(404, {'error': 'Project not found or access denied.'});
    }
    return _json(201, {'model': result});
  }

  Future<Response> _updateBimModelStatus(
    Request request,
    String modelId,
  ) async {
    final access = await _organizationAccess(request);
    if (access.response != null) return access.response!;
    if (!_isUuid(modelId)) {
      return _json(400, {'error': 'BIM model identifier is invalid.'});
    }

    final body = await _readJson(request);
    final status = body['status'];
    final expectedVersion = body['expectedVersion'];
    const statuses = {'in_review', 'published', 'archived'};
    if (status is! String ||
        !statuses.contains(status) ||
        expectedVersion is! int ||
        expectedVersion < 1) {
      return _json(400, {'error': 'BIM model update fields are invalid.'});
    }

    final outcome = await database.pool.runTx((transaction) async {
      await _setTenantContext(
        transaction,
        organizationId: access.organizationId!,
        userId: access.userId!,
      );
      final rows = await transaction.execute(
        Sql.named('''
          SELECT m.project_id, m.version,
                 EXISTS (
                   SELECT 1
                   FROM project_memberships pm
                   WHERE pm.organization_id = m.organization_id
                     AND pm.project_id = m.project_id
                     AND pm.user_id = @userId
                     AND pm.role = 'project_manager'
                     AND pm.status = 'active'
                 ) AS is_project_manager
          FROM bim_models m
          WHERE m.organization_id = @organizationId
            AND m.id = @modelId
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'modelId': modelId,
          'userId': access.userId,
        },
      );
      if (rows.isEmpty) return {'kind': 'not_found'};
      final current = rows.first.toColumnMap();
      if (!ProjectAccessPolicy.canUpdateProject(access.role!) &&
          current['is_project_manager'] != true) {
        return {'kind': 'forbidden'};
      }
      final version = current['version'] as int;
      if (version != expectedVersion) {
        return {'kind': 'conflict', 'currentVersion': version};
      }
      final updated = await transaction.execute(
        Sql.named('''
          UPDATE bim_models
          SET status = @status, version = version + 1, updated_at = now()
          WHERE organization_id = @organizationId
            AND id = @modelId
            AND version = @expectedVersion
          RETURNING id, name, discipline, revision, status, version, updated_at
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'modelId': modelId,
          'expectedVersion': expectedVersion,
          'status': status,
        },
      );
      if (updated.isEmpty) {
        return {'kind': 'conflict', 'currentVersion': version};
      }
      final row = updated.first.toColumnMap();
      await _insertAuditEvent(
        transaction,
        organizationId: access.organizationId!,
        actorUserId: access.userId!,
        action: 'bim_model.status_updated',
        entityType: 'bim_model',
        entityId: modelId,
        metadata: {
          'previousVersion': version,
          'version': version + 1,
          'status': status,
        },
      );
      return {'kind': 'updated', 'model': _bimModelJson(row)};
    });
    return switch (outcome['kind']) {
      'not_found' => _json(404, {'error': 'BIM model not found.'}),
      'forbidden' => _json(403, {'error': 'Insufficient permissions.'}),
      'conflict' => _json(409, {
        'error': 'BIM model has changed since it was loaded.',
        'currentVersion': outcome['currentVersion'],
      }),
      'updated' => _json(200, {'model': outcome['model']}),
      _ => throw StateError('Unexpected BIM model update result.'),
    };
  }

  Future<Response> _createBimIssue(
    Request request,
    String projectIdentifier,
  ) async {
    final access = await _organizationAccess(request);
    if (access.response != null) return access.response!;
    if (projectIdentifier.isEmpty || projectIdentifier.length > 200) {
      return _json(400, {'error': 'Project identifier is invalid.'});
    }

    late final Map<String, Object?> issue;
    try {
      issue = _parseBimIssuePayload(await _readJson(request));
    } on FormatException catch (error) {
      return _json(400, {'error': error.message});
    }

    final result = await database.pool.runTx((transaction) async {
      await _setTenantContext(
        transaction,
        organizationId: access.organizationId!,
        userId: access.userId!,
      );
      final projects = await transaction.execute(
        Sql.named('''
          SELECT p.id, p.code
          FROM projects p
          WHERE p.organization_id = @organizationId
            AND (p.id::text = @identifier OR p.code = @identifier)
            AND (
              @organizationWide OR EXISTS (
                SELECT 1
                FROM project_memberships pm
                WHERE pm.organization_id = p.organization_id
                  AND pm.project_id = p.id
                  AND pm.user_id = @userId
                  AND pm.role IN ('project_manager', 'contributor')
                  AND pm.status = 'active'
              )
            )
          LIMIT 1
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'identifier': projectIdentifier,
          'userId': access.userId,
          'organizationWide': ProjectAccessPolicy.canListAllProjects(
            access.role!,
          ),
        },
      );
      if (projects.isEmpty) return null;
      final project = projects.first.toColumnMap();
      final created = await transaction.execute(
        Sql.named('''
          INSERT INTO bim_issues (
            organization_id, project_id, bcf_guid, title, description,
            discipline, location, severity, assigned_to, due_date, created_by
          )
          VALUES (
            @organizationId, @projectId, CAST(@bcfGuid AS uuid), @title,
            @description, @discipline, @location, @severity, @assignedTo,
            CAST(@dueDate AS date), @userId
          )
          RETURNING id, bcf_guid, title, description, discipline, location,
                    severity, status, assigned_to, due_date, version,
                    created_at, updated_at
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'projectId': project['id'],
          'bcfGuid': issue['bcfGuid'],
          'title': issue['title'],
          'description': issue['description'],
          'discipline': issue['discipline'],
          'location': issue['location'],
          'severity': issue['severity'],
          'assignedTo': issue['assignedTo'],
          'dueDate': issue['dueDate'],
          'userId': access.userId,
        },
      );
      final row = created.first.toColumnMap();
      await _insertAuditEvent(
        transaction,
        organizationId: access.organizationId!,
        actorUserId: access.userId!,
        action: 'bim_issue.created',
        entityType: 'bim_issue',
        entityId: '${row['id']}',
        metadata: {
          'projectCode': project['code'],
          'severity': issue['severity'],
          'bcfGuid': issue['bcfGuid'],
        },
      );
      return _bimIssueJson(row);
    });
    if (result == null) {
      return _json(404, {'error': 'Project not found or access denied.'});
    }
    return _json(201, {'issue': result});
  }

  Future<Response> _importBimIssues(
    Request request,
    String projectIdentifier,
  ) async {
    final access = await _organizationAccess(request);
    if (access.response != null) return access.response!;
    if (projectIdentifier.isEmpty || projectIdentifier.length > 200) {
      return _json(400, {'error': 'Project identifier is invalid.'});
    }

    late final List<Map<String, Object?>> issues;
    try {
      final body = await _readJson(request);
      final input = body['issues'];
      if (input is! List || input.isEmpty || input.length > 500) {
        throw const FormatException(
          'A batch of 1 to 500 BIM issues is required.',
        );
      }
      issues = input
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Each BIM issue must be an object.');
            }
            return _parseBimIssuePayload(item, preserveStatus: true);
          })
          .toList(growable: false);
      final bcfGuids = issues
          .map((issue) => issue['bcfGuid'])
          .whereType<String>()
          .toList();
      if (bcfGuids.length != bcfGuids.toSet().length) {
        throw const FormatException(
          'The BCF batch contains duplicate topic identifiers.',
        );
      }
    } on FormatException catch (error) {
      return _json(400, {'error': error.message});
    }

    final result = await database.pool.runTx((transaction) async {
      await _setTenantContext(
        transaction,
        organizationId: access.organizationId!,
        userId: access.userId!,
      );
      final projects = await transaction.execute(
        Sql.named('''
          SELECT p.id, p.code
          FROM projects p
          WHERE p.organization_id = @organizationId
            AND (p.id::text = @identifier OR p.code = @identifier)
            AND (
              @organizationWide OR EXISTS (
                SELECT 1
                FROM project_memberships pm
                WHERE pm.organization_id = p.organization_id
                  AND pm.project_id = p.id
                  AND pm.user_id = @userId
                  AND pm.role IN ('project_manager', 'contributor')
                  AND pm.status = 'active'
              )
            )
          LIMIT 1
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'identifier': projectIdentifier,
          'userId': access.userId,
          'organizationWide': ProjectAccessPolicy.canListAllProjects(
            access.role!,
          ),
        },
      );
      if (projects.isEmpty) return null;
      final project = projects.first.toColumnMap();
      final imported = <Map<String, Object?>>[];
      for (final issue in issues) {
        final inserted = await transaction.execute(
          Sql.named('''
            INSERT INTO bim_issues (
              organization_id, project_id, bcf_guid, title, description,
              discipline, location, severity, status, assigned_to, due_date,
              created_by
            )
            VALUES (
              @organizationId, @projectId, CAST(@bcfGuid AS uuid), @title,
              @description, @discipline, @location, @severity, @status,
              @assignedTo, CAST(@dueDate AS date), @userId
            )
            ON CONFLICT (organization_id, project_id, bcf_guid)
              WHERE bcf_guid IS NOT NULL
            DO NOTHING
            RETURNING id, bcf_guid, title, description, discipline, location,
                      severity, status, assigned_to, due_date, version,
                      created_at, updated_at
          '''),
          parameters: {
            'organizationId': access.organizationId,
            'projectId': project['id'],
            'bcfGuid': issue['bcfGuid'],
            'title': issue['title'],
            'description': issue['description'],
            'discipline': issue['discipline'],
            'location': issue['location'],
            'severity': issue['severity'],
            'status': issue['status'],
            'assignedTo': issue['assignedTo'],
            'dueDate': issue['dueDate'],
            'userId': access.userId,
          },
        );
        if (inserted.isEmpty) continue;
        final row = inserted.first.toColumnMap();
        await _insertAuditEvent(
          transaction,
          organizationId: access.organizationId!,
          actorUserId: access.userId!,
          action: 'bim_issue.imported',
          entityType: 'bim_issue',
          entityId: '${row['id']}',
          metadata: {
            'projectCode': project['code'],
            'bcfGuid': issue['bcfGuid'],
          },
        );
        imported.add(_bimIssueJson(row));
      }
      return {'projectCode': '${project['code']}', 'issues': imported};
    });
    if (result == null) {
      return _json(404, {'error': 'Project not found or access denied.'});
    }
    return _json(200, result);
  }

  Future<Response> _updateBimIssueStatus(
    Request request,
    String issueId,
  ) async {
    final access = await _organizationAccess(request);
    if (access.response != null) return access.response!;
    if (!_isUuid(issueId)) {
      return _json(400, {'error': 'BIM issue identifier is invalid.'});
    }
    final body = await _readJson(request);
    final status = body['status'];
    final expectedVersion = body['expectedVersion'];
    const statuses = {'open', 'in_progress', 'resolved'};
    if (status is! String ||
        !statuses.contains(status) ||
        expectedVersion is! int ||
        expectedVersion < 1) {
      return _json(400, {'error': 'BIM issue update fields are invalid.'});
    }

    final outcome = await database.pool.runTx((transaction) async {
      await _setTenantContext(
        transaction,
        organizationId: access.organizationId!,
        userId: access.userId!,
      );
      final rows = await transaction.execute(
        Sql.named('''
          SELECT i.project_id, i.version,
                 EXISTS (
                   SELECT 1
                   FROM project_memberships pm
                   WHERE pm.organization_id = i.organization_id
                     AND pm.project_id = i.project_id
                     AND pm.user_id = @userId
                     AND pm.role = 'project_manager'
                     AND pm.status = 'active'
                 ) AS is_project_manager
          FROM bim_issues i
          WHERE i.organization_id = @organizationId
            AND i.id = @issueId
          FOR UPDATE
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'issueId': issueId,
          'userId': access.userId,
        },
      );
      if (rows.isEmpty) return {'kind': 'not_found'};
      final current = rows.first.toColumnMap();
      final organizationWide = ProjectAccessPolicy.canUpdateProject(
        access.role!,
      );
      if (!organizationWide && current['is_project_manager'] != true) {
        return {'kind': 'forbidden'};
      }
      final version = current['version'] as int;
      if (version != expectedVersion) {
        return {'kind': 'conflict', 'currentVersion': version};
      }
      final updated = await transaction.execute(
        Sql.named('''
          UPDATE bim_issues
          SET status = @status,
              version = version + 1,
              updated_at = now()
          WHERE organization_id = @organizationId
            AND id = @issueId
            AND version = @expectedVersion
          RETURNING id, bcf_guid, title, description, discipline, location,
                    severity, status, assigned_to, due_date, version,
                    created_at, updated_at
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'issueId': issueId,
          'expectedVersion': expectedVersion,
          'status': status,
        },
      );
      if (updated.isEmpty) {
        return {'kind': 'conflict', 'currentVersion': version};
      }
      final row = updated.first.toColumnMap();
      await _insertAuditEvent(
        transaction,
        organizationId: access.organizationId!,
        actorUserId: access.userId!,
        action: 'bim_issue.status_updated',
        entityType: 'bim_issue',
        entityId: issueId,
        metadata: {
          'previousVersion': version,
          'version': version + 1,
          'status': status,
        },
      );
      return {'kind': 'updated', 'issue': _bimIssueJson(row)};
    });
    return switch (outcome['kind']) {
      'not_found' => _json(404, {'error': 'BIM issue not found.'}),
      'forbidden' => _json(403, {'error': 'Insufficient permissions.'}),
      'conflict' => _json(409, {
        'error': 'BIM issue has changed since it was loaded.',
        'currentVersion': outcome['currentVersion'],
      }),
      'updated' => _json(200, {'issue': outcome['issue']}),
      _ => throw StateError('Unexpected BIM issue update result.'),
    };
  }

  Future<Response> _listBimIssueComments(
    Request request,
    String issueId,
  ) async {
    final access = await _organizationAccess(request);
    if (access.response != null) return access.response!;
    if (!_isUuid(issueId)) {
      return _json(400, {'error': 'BIM issue identifier is invalid.'});
    }
    final result = await database.pool.runTx((transaction) async {
      await _setTenantContext(
        transaction,
        organizationId: access.organizationId!,
        userId: access.userId!,
      );
      final issue = await transaction.execute(
        Sql.named('''
          SELECT id FROM bim_issues
          WHERE organization_id = @organizationId AND id = @issueId
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'issueId': issueId,
        },
      );
      if (issue.isEmpty) return null;
      final comments = await transaction.execute(
        Sql.named('''
          SELECT recent.id, recent.body, recent.created_at,
                 recent.source_guid,
                 CASE WHEN recent.source_author IS NOT NULL
                      THEN 'BCF: ' || recent.source_author
                      ELSE u.full_name END AS author_name
          FROM (
            SELECT id, body, created_at, created_by, source_guid,
                   source_author
            FROM bim_issue_comments
            WHERE organization_id = @organizationId AND issue_id = @issueId
            ORDER BY created_at DESC, id DESC
            LIMIT 500
          ) recent
          JOIN users u ON u.id = recent.created_by
          ORDER BY recent.created_at, recent.id
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'issueId': issueId,
        },
      );
      return comments
          .map((row) => _bimIssueCommentJson(row.toColumnMap()))
          .toList(growable: false);
    });
    if (result == null) return _json(404, {'error': 'BIM issue not found.'});
    return _json(200, {'comments': result});
  }

  Future<Response> _createBimIssueComment(
    Request request,
    String issueId,
  ) async {
    final access = await _organizationAccess(request);
    if (access.response != null) return access.response!;
    if (!_isUuid(issueId)) {
      return _json(400, {'error': 'BIM issue identifier is invalid.'});
    }
    late final String text;
    try {
      final body = await _readJson(request);
      final value = body['body'];
      if (value is! String ||
          value.trim().isEmpty ||
          value.trim().length > 5000) {
        throw const FormatException(
          'Comment text must contain between 1 and 5000 characters.',
        );
      }
      text = value.trim();
    } on FormatException catch (error) {
      return _json(400, {'error': error.message});
    }

    final result = await database.pool.runTx((transaction) async {
      await _setTenantContext(
        transaction,
        organizationId: access.organizationId!,
        userId: access.userId!,
      );
      final issues = await transaction.execute(
        Sql.named('''
          SELECT project_id,
                 EXISTS (
                   SELECT 1
                   FROM memberships m
                   WHERE m.organization_id = bim_issues.organization_id
                     AND m.user_id = @userId
                     AND m.role IN ('owner', 'admin')
                     AND m.status = 'active'
                 ) OR EXISTS (
                   SELECT 1
                   FROM project_memberships pm
                   WHERE pm.organization_id = bim_issues.organization_id
                     AND pm.project_id = bim_issues.project_id
                     AND pm.user_id = @userId
                     AND pm.role IN ('project_manager', 'contributor')
                     AND pm.status = 'active'
                 ) AS can_comment
          FROM bim_issues
          WHERE organization_id = @organizationId AND id = @issueId
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'issueId': issueId,
          'userId': access.userId,
        },
      );
      if (issues.isEmpty) return null;
      final issue = issues.first.toColumnMap();
      if (!ProjectAccessPolicy.canListAllProjects(access.role!) &&
          issue['can_comment'] != true) {
        return {'kind': 'forbidden'};
      }
      final projectId = issue['project_id'];
      final inserted = await transaction.execute(
        Sql.named('''
          INSERT INTO bim_issue_comments (
            organization_id, project_id, issue_id, body, created_by
          )
          VALUES (
            @organizationId, @projectId, @issueId, @body, @userId
          )
          RETURNING id, body, created_at, created_by, source_guid
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'projectId': projectId,
          'issueId': issueId,
          'body': text,
          'userId': access.userId,
        },
      );
      final comment = inserted.first.toColumnMap();
      final users = await transaction.execute(
        Sql.named('SELECT full_name FROM users WHERE id = @userId'),
        parameters: {'userId': access.userId},
      );
      final json = _bimIssueCommentJson({
        ...comment,
        'author_name': users.first.toColumnMap()['full_name'],
      });
      await _insertAuditEvent(
        transaction,
        organizationId: access.organizationId!,
        actorUserId: access.userId!,
        action: 'bim_issue.comment_added',
        entityType: 'bim_issue',
        entityId: issueId,
        metadata: {'commentId': comment['id']},
      );
      return {'kind': 'created', 'comment': json};
    });
    if (result == null) return _json(404, {'error': 'BIM issue not found.'});
    if (result['kind'] == 'forbidden') {
      return _json(403, {'error': 'Insufficient permissions.'});
    }
    return _json(201, {'comment': result['comment']});
  }

  Future<Response> _importBimIssueComments(
    Request request,
    String issueId,
  ) async {
    final access = await _organizationAccess(request);
    if (access.response != null) return access.response!;
    if (!_isUuid(issueId)) {
      return _json(400, {'error': 'BIM issue identifier is invalid.'});
    }

    late final List<Map<String, Object?>> comments;
    try {
      final input = (await _readJson(request))['comments'];
      if (input is! List || input.length > 500) {
        throw const FormatException(
          'At most 500 BCF comments can be imported for one issue.',
        );
      }
      comments = input
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException(
                'Each BCF comment must be an object.',
              );
            }
            final guid = item['bcfGuid'];
            final body = item['body'];
            final author = item['authorName'];
            final createdAt = item['createdAt'];
            final parsedDate = createdAt is String
                ? DateTime.tryParse(createdAt)
                : null;
            if (guid is! String ||
                !_isUuid(guid) ||
                body is! String ||
                body.trim().isEmpty ||
                body.trim().length > 5000 ||
                author is! String ||
                author.trim().isEmpty ||
                author.trim().length > 200 ||
                parsedDate == null) {
              throw const FormatException('A BCF comment is invalid.');
            }
            return <String, Object?>{
              'bcfGuid': guid,
              'body': body.trim(),
              'authorName': author.trim(),
              'createdAt': parsedDate.toUtc(),
            };
          })
          .toList(growable: false);
      final guids = comments
          .map((comment) => comment['bcfGuid'] as String)
          .toSet();
      if (guids.length != comments.length) {
        throw const FormatException(
          'BCF comments contain duplicate identifiers.',
        );
      }
    } on FormatException catch (error) {
      return _json(400, {'error': error.message});
    }

    final outcome = await database.pool.runTx((transaction) async {
      await _setTenantContext(
        transaction,
        organizationId: access.organizationId!,
        userId: access.userId!,
      );
      final issues = await transaction.execute(
        Sql.named('''
          SELECT i.project_id,
                 EXISTS (
                   SELECT 1 FROM memberships m
                   WHERE m.organization_id = i.organization_id
                     AND m.user_id = @userId
                     AND m.role IN ('owner', 'admin')
                     AND m.status = 'active'
                 ) OR EXISTS (
                   SELECT 1 FROM project_memberships pm
                   WHERE pm.organization_id = i.organization_id
                     AND pm.project_id = i.project_id
                     AND pm.user_id = @userId
                     AND pm.role IN ('project_manager', 'contributor')
                     AND pm.status = 'active'
                 ) AS can_comment
          FROM bim_issues i
          WHERE i.organization_id = @organizationId AND i.id = @issueId
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'issueId': issueId,
          'userId': access.userId,
        },
      );
      if (issues.isEmpty) return {'kind': 'not_found'};
      final issue = issues.first.toColumnMap();
      if (!ProjectAccessPolicy.canListAllProjects(access.role!) &&
          issue['can_comment'] != true) {
        return {'kind': 'forbidden'};
      }

      var imported = 0;
      for (final comment in comments) {
        final inserted = await transaction.execute(
          Sql.named('''
            INSERT INTO bim_issue_comments (
              organization_id, project_id, issue_id, body, created_by,
              created_at, source_guid, source_author
            )
            VALUES (
              @organizationId, @projectId, @issueId, @body, @userId,
              @createdAt, CAST(@sourceGuid AS uuid), @sourceAuthor
            )
            ON CONFLICT (organization_id, issue_id, source_guid)
              WHERE source_guid IS NOT NULL
            DO NOTHING
            RETURNING id
          '''),
          parameters: {
            'organizationId': access.organizationId,
            'projectId': issue['project_id'],
            'issueId': issueId,
            'body': comment['body'],
            'userId': access.userId,
            'createdAt': comment['createdAt'],
            'sourceGuid': comment['bcfGuid'],
            'sourceAuthor': comment['authorName'],
          },
        );
        if (inserted.isNotEmpty) imported++;
      }
      if (imported > 0) {
        await _insertAuditEvent(
          transaction,
          organizationId: access.organizationId!,
          actorUserId: access.userId!,
          action: 'bim_issue.comments_imported',
          entityType: 'bim_issue',
          entityId: issueId,
          metadata: {'importedCount': imported},
        );
      }
      return {'kind': 'imported', 'count': imported};
    });
    if (outcome['kind'] == 'not_found') {
      return _json(404, {'error': 'BIM issue not found.'});
    }
    if (outcome['kind'] == 'forbidden') {
      return _json(403, {'error': 'Insufficient permissions.'});
    }
    return _json(200, {'imported': outcome['count']});
  }

  Future<Response> _listProjectBimComments(
    Request request,
    String projectIdentifier,
  ) async {
    final access = await _organizationAccess(request);
    if (access.response != null) return access.response!;
    if (projectIdentifier.isEmpty || projectIdentifier.length > 200) {
      return _json(400, {'error': 'Project identifier is invalid.'});
    }

    final result = await database.pool.runTx((transaction) async {
      await _setTenantContext(
        transaction,
        organizationId: access.organizationId!,
        userId: access.userId!,
      );
      final projects = await transaction.execute(
        Sql.named('''
          SELECT p.id, p.code
          FROM projects p
          WHERE p.organization_id = @organizationId
            AND (p.id::text = @identifier OR p.code = @identifier)
            AND (
              @organizationWide OR EXISTS (
                SELECT 1 FROM project_memberships pm
                WHERE pm.organization_id = p.organization_id
                  AND pm.project_id = p.id
                  AND pm.user_id = @userId
                  AND pm.status = 'active'
              )
            )
          LIMIT 1
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'identifier': projectIdentifier,
          'userId': access.userId,
          'organizationWide': ProjectAccessPolicy.canListAllProjects(
            access.role!,
          ),
        },
      );
      if (projects.isEmpty) return null;
      final project = projects.first.toColumnMap();
      final comments = await transaction.execute(
        Sql.named('''
          SELECT c.id, c.issue_id, c.body, c.created_at, c.source_guid,
                 CASE WHEN c.source_author IS NOT NULL
                      THEN 'BCF: ' || c.source_author
                      ELSE u.full_name END AS author_name
          FROM bim_issue_comments c
          JOIN users u ON u.id = c.created_by
          WHERE c.organization_id = @organizationId
            AND c.project_id = @projectId
          ORDER BY c.created_at, c.id
          LIMIT 5001
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'projectId': project['id'],
        },
      );
      return {
        'projectCode': '${project['code']}',
        'comments': comments.map((row) {
          final comment = row.toColumnMap();
          return {
            ..._bimIssueCommentJson(comment),
            'issueId': '${comment['issue_id']}',
          };
        }).toList(),
      };
    });
    if (result == null) return _json(404, {'error': 'Project not found.'});
    return _json(200, result);
  }

  Future<Response> _importProjectBimComments(
    Request request,
    String projectIdentifier,
  ) async {
    final access = await _organizationAccess(request);
    if (access.response != null) return access.response!;
    if (projectIdentifier.isEmpty || projectIdentifier.length > 200) {
      return _json(400, {'error': 'Project identifier is invalid.'});
    }

    late final List<Map<String, Object?>> comments;
    try {
      final input = (await _readJson(
        request,
        maxBytes: 32 * 1024 * 1024,
      ))['comments'];
      if (input is! List || input.length > 5000) {
        throw const FormatException(
          'At most 5000 BCF comments can be imported at once.',
        );
      }
      comments = input
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException(
                'Each BCF comment must be an object.',
              );
            }
            final topicGuid = item['topicGuid'];
            final guid = item['bcfGuid'];
            final body = item['body'];
            final author = item['authorName'];
            final createdAt = item['createdAt'];
            final parsedDate = createdAt is String
                ? DateTime.tryParse(createdAt)
                : null;
            if (topicGuid is! String ||
                !_isUuid(topicGuid) ||
                guid is! String ||
                !_isUuid(guid) ||
                body is! String ||
                body.trim().isEmpty ||
                body.trim().length > 5000 ||
                author is! String ||
                author.trim().isEmpty ||
                author.trim().length > 200 ||
                parsedDate == null) {
              throw const FormatException('A BCF comment is invalid.');
            }
            return <String, Object?>{
              'topicGuid': topicGuid.toLowerCase(),
              'bcfGuid': guid.toLowerCase(),
              'body': body.trim(),
              'authorName': author.trim(),
              'createdAt': parsedDate.toUtc(),
            };
          })
          .toList(growable: false);
      final identities = comments
          .map((comment) => '${comment['topicGuid']}:${comment['bcfGuid']}')
          .toSet();
      if (identities.length != comments.length) {
        throw const FormatException(
          'BCF comments contain duplicate identifiers.',
        );
      }
    } on FormatException catch (error) {
      return _json(400, {'error': error.message});
    }

    final outcome = await database.pool.runTx((transaction) async {
      await _setTenantContext(
        transaction,
        organizationId: access.organizationId!,
        userId: access.userId!,
      );
      final projects = await transaction.execute(
        Sql.named('''
          SELECT p.id, p.code,
                 @organizationWide OR EXISTS (
                   SELECT 1 FROM project_memberships pm
                   WHERE pm.organization_id = p.organization_id
                     AND pm.project_id = p.id
                     AND pm.user_id = @userId
                     AND pm.role IN ('project_manager', 'contributor')
                     AND pm.status = 'active'
                 ) AS can_comment
          FROM projects p
          WHERE p.organization_id = @organizationId
            AND (p.id::text = @identifier OR p.code = @identifier)
          LIMIT 1
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'identifier': projectIdentifier,
          'userId': access.userId,
          'organizationWide': ProjectAccessPolicy.canListAllProjects(
            access.role!,
          ),
        },
      );
      if (projects.isEmpty) return {'kind': 'not_found'};
      final project = projects.first.toColumnMap();
      if (project['can_comment'] != true) return {'kind': 'forbidden'};
      if (comments.isEmpty) return {'kind': 'imported', 'count': 0};

      final topicGuids = comments
          .map((comment) => comment['topicGuid'] as String)
          .toSet();
      final topicGuidList = topicGuids.toList(growable: false);
      final topicGuidParameters = <String, Object?>{
        for (var index = 0; index < topicGuidList.length; index++)
          'topicGuid$index': topicGuidList[index],
      };
      final topicGuidPlaceholders = List.generate(
        topicGuidList.length,
        (index) => '@topicGuid$index',
      ).join(', ');
      final issueRows = await transaction.execute(
        Sql.named('''
          SELECT id, bcf_guid
          FROM bim_issues
          WHERE organization_id = @organizationId
            AND project_id = @projectId
            AND bcf_guid IN ($topicGuidPlaceholders)
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'projectId': project['id'],
          ...topicGuidParameters,
        },
      );
      final issueIds = <String, Object?>{};
      for (final row in issueRows) {
        final issue = row.toColumnMap();
        issueIds['${issue['bcf_guid']}'.toLowerCase()] = issue['id'];
      }
      if (!issueIds.keys.toSet().containsAll(topicGuids)) {
        return {'kind': 'missing_topic'};
      }

      var imported = 0;
      for (var offset = 0; offset < comments.length; offset += 250) {
        final chunk = comments.skip(offset).take(250).toList(growable: false);
        final rows = <String>[];
        final parameters = <String, Object?>{
          'organizationId': access.organizationId,
          'projectId': project['id'],
          'userId': access.userId,
        };
        for (var index = 0; index < chunk.length; index++) {
          final comment = chunk[index];
          rows.add('''
            (
              @organizationId, @projectId, @issueId$index, @body$index,
              @userId, @createdAt$index, CAST(@sourceGuid$index AS uuid),
              @sourceAuthor$index
            )
          ''');
          parameters
            ..['issueId$index'] = issueIds[comment['topicGuid']]
            ..['body$index'] = comment['body']
            ..['createdAt$index'] = comment['createdAt']
            ..['sourceGuid$index'] = comment['bcfGuid']
            ..['sourceAuthor$index'] = comment['authorName'];
        }
        final inserted = await transaction.execute(
          Sql.named('''
            INSERT INTO bim_issue_comments (
              organization_id, project_id, issue_id, body, created_by,
              created_at, source_guid, source_author
            )
            VALUES ${rows.join(', ')}
            ON CONFLICT (organization_id, issue_id, source_guid)
              WHERE source_guid IS NOT NULL
            DO NOTHING
            RETURNING id
          '''),
          parameters: parameters,
        );
        imported += inserted.length;
      }
      if (imported > 0) {
        await _insertAuditEvent(
          transaction,
          organizationId: access.organizationId!,
          actorUserId: access.userId!,
          action: 'bim_issue.comments_imported',
          entityType: 'project',
          entityId: '${project['id']}',
          metadata: {'importedCount': imported},
        );
      }
      return {'kind': 'imported', 'count': imported};
    });
    if (outcome['kind'] == 'not_found') {
      return _json(404, {'error': 'Project not found.'});
    }
    if (outcome['kind'] == 'forbidden') {
      return _json(403, {'error': 'Insufficient permissions.'});
    }
    if (outcome['kind'] == 'missing_topic') {
      return _json(400, {
        'error': 'Every BCF comment must match an issue in this project.',
      });
    }
    return _json(200, {'imported': outcome['count']});
  }

  Map<String, Object?> _parseBimIssuePayload(
    Map<String, dynamic> body, {
    bool preserveStatus = false,
  }) {
    final title = _boundedString(body, 'title', minimum: 2, maximum: 200);
    final description = _boundedString(
      body,
      'description',
      minimum: 0,
      maximum: 10000,
    );
    final discipline = _boundedString(
      body,
      'discipline',
      minimum: 1,
      maximum: 200,
    );
    final location = _boundedString(body, 'location', minimum: 1, maximum: 300);
    final assignedToValue = body['assignedTo'] ?? '';
    if (assignedToValue is! String || assignedToValue.trim().length > 160) {
      throw const FormatException('assignedTo must be at most 160 characters.');
    }
    final severityValue = body['severity'];
    const severities = {'low', 'medium', 'high', 'critical'};
    if (severityValue is! String ||
        !severities.contains(severityValue.toLowerCase())) {
      throw const FormatException('BIM issue severity is invalid.');
    }
    final dueDate = _parseDateOnly(body['dueDate']);
    if (dueDate == null) {
      throw const FormatException('BIM issue dueDate must be a valid date.');
    }
    final bcfGuidValue = body['bcfGuid'];
    if (bcfGuidValue != null &&
        (bcfGuidValue is! String || !_isUuid(bcfGuidValue))) {
      throw const FormatException('BIM issue BCF topic identifier is invalid.');
    }
    var status = 'open';
    if (preserveStatus) {
      final statusValue = body['status'];
      const allowedStatuses = {'open', 'in_progress', 'resolved'};
      if (statusValue is! String ||
          !allowedStatuses.contains(statusValue.toLowerCase())) {
        throw const FormatException('BIM issue status is invalid.');
      }
      status = statusValue.toLowerCase();
    }
    return {
      'title': title,
      'description': description,
      'discipline': discipline,
      'location': location,
      'severity': severityValue.toLowerCase(),
      'status': status,
      'assignedTo': assignedToValue.trim(),
      'dueDate': _dateOnly(dueDate),
      'bcfGuid': bcfGuidValue,
    };
  }

  Map<String, Object?> _bimModelJson(Map<String, dynamic> row) => {
    'id': '${row['id']}',
    'name': '${row['name']}',
    'discipline': '${row['discipline']}',
    'version': '${row['revision']}',
    'status': '${row['status']}',
    'recordVersion': row['version'],
    'updatedAt': (row['updated_at'] as DateTime).toUtc().toIso8601String(),
  };

  Map<String, Object?> _bimIssueCommentJson(Map<String, dynamic> row) => {
    'id': '${row['id']}',
    'body': '${row['body']}',
    'authorName': '${row['author_name']}',
    'createdAt': (row['created_at'] as DateTime).toUtc().toIso8601String(),
    'bcfGuid': row['source_guid']?.toString(),
  };

  Map<String, Object?> _bimIssueJson(Map<String, dynamic> row) => {
    'id': '${row['id']}',
    'bcfGuid': row['bcf_guid']?.toString(),
    'title': '${row['title']}',
    'description': '${row['description']}',
    'discipline': '${row['discipline']}',
    'location': '${row['location']}',
    'severity': '${row['severity']}',
    'status': '${row['status']}',
    'assignedTo': '${row['assigned_to']}',
    'dueDate': _dateOnly(row['due_date']),
    'version': row['version'],
    'createdAt': (row['created_at'] as DateTime).toUtc().toIso8601String(),
    'updatedAt': (row['updated_at'] as DateTime).toUtc().toIso8601String(),
  };

  Future<Response> _getProject(
    Request request,
    String projectIdentifier,
  ) async {
    final access = await _organizationAccess(request);
    if (access.response != null) return access.response!;
    if (projectIdentifier.isEmpty || projectIdentifier.length > 200) {
      return _json(400, {'error': 'Project identifier is invalid.'});
    }

    final rows = await database.pool.runTx((transaction) async {
      await _setTenantContext(
        transaction,
        organizationId: access.organizationId!,
        userId: access.userId!,
      );
      return transaction.execute(
        Sql.named('''
          SELECT p.id, p.code, p.name, p.status, p.location, p.created_at,
                 p.updated_at, p.client_name, p.project_type, p.budget_amount,
                 p.budget_currency, p.planned_start_date, p.planned_end_date,
                 p.version
          FROM projects p
          WHERE p.organization_id = @organizationId
            AND (p.id::text = @identifier OR p.code = @identifier)
            AND (
              @organizationWide OR EXISTS (
                SELECT 1
                FROM project_memberships pm
                WHERE pm.organization_id = p.organization_id
                  AND pm.project_id = p.id
                  AND pm.user_id = @userId
                  AND pm.status = 'active'
              )
            )
          LIMIT 1
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'identifier': projectIdentifier,
          'userId': access.userId,
          'organizationWide': ProjectAccessPolicy.canListAllProjects(
            access.role!,
          ),
        },
      );
    });
    if (rows.isEmpty) return _json(404, {'error': 'Project not found.'});

    final row = rows.first.toColumnMap();
    return _json(200, {'project': _projectJson(row)});
  }

  Map<String, Object?> _projectJson(Map<String, dynamic> row) => {
    'id': '${row['id']}',
    'code': '${row['code']}',
    'name': '${row['name']}',
    'status': '${row['status']}',
    'location': '${row['location']}',
    'clientName': '${row['client_name']}',
    'projectType': '${row['project_type']}',
    'budgetAmount': row['budget_amount']?.toString(),
    'budgetCurrency': '${row['budget_currency']}'.trim(),
    'plannedStartDate': _dateOnly(row['planned_start_date']),
    'plannedEndDate': _dateOnly(row['planned_end_date']),
    'version': row['version'],
    'createdAt': (row['created_at'] as DateTime).toUtc().toIso8601String(),
    'updatedAt': (row['updated_at'] as DateTime).toUtc().toIso8601String(),
  };

  Future<Response> _updateProject(
    Request request,
    String projectIdentifier,
  ) async {
    final access = await _organizationAccess(request);
    if (access.response != null) return access.response!;
    if (!ProjectAccessPolicy.canUpdateProject(access.role!)) {
      return _json(403, {'error': 'Insufficient permissions.'});
    }

    final body = await _readJson(request);
    final expectedVersion = body['expectedVersion'];
    if (expectedVersion is! int || expectedVersion < 1) {
      return _json(400, {'error': 'A valid expectedVersion is required.'});
    }

    final outcome = await database.pool.runTx((transaction) async {
      await _setTenantContext(
        transaction,
        organizationId: access.organizationId!,
        userId: access.userId!,
      );
      final rows = await transaction.execute(
        Sql.named('''
          SELECT p.id, p.code, p.name, p.status, p.location, p.created_at,
                 p.updated_at, p.client_name, p.project_type, p.budget_amount,
                 p.budget_currency, p.planned_start_date, p.planned_end_date,
                 p.version
          FROM projects p
          WHERE p.organization_id = @organizationId
            AND (p.id::text = @identifier OR p.code = @identifier)
            AND (
              @organizationWide OR EXISTS (
                SELECT 1
                FROM project_memberships pm
                WHERE pm.organization_id = p.organization_id
                  AND pm.project_id = p.id
                  AND pm.user_id = @userId
                  AND pm.status = 'active'
              )
            )
          FOR UPDATE
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'identifier': projectIdentifier,
          'userId': access.userId,
          'organizationWide': ProjectAccessPolicy.canListAllProjects(
            access.role!,
          ),
        },
      );
      if (rows.isEmpty) return {'kind': 'not_found'};

      final current = rows.first.toColumnMap();
      final currentVersion = current['version'] as int;
      if (currentVersion != expectedVersion) {
        return {'kind': 'conflict', 'currentVersion': currentVersion};
      }

      final name = body['name'] ?? current['name'];
      final status = body['status'] ?? current['status'];
      final location = body['location'] ?? current['location'];
      final clientName = body['clientName'] ?? current['client_name'];
      final projectType = body['projectType'] ?? current['project_type'];
      final budgetCurrency =
          body['budgetCurrency'] ?? '${current['budget_currency']}'.trim();
      final budgetInput = body.containsKey('budgetAmount')
          ? body['budgetAmount']
          : current['budget_amount']?.toString();
      final startInput = body.containsKey('plannedStartDate')
          ? body['plannedStartDate']
          : _dateOnly(current['planned_start_date']);
      final endInput = body.containsKey('plannedEndDate')
          ? body['plannedEndDate']
          : _dateOnly(current['planned_end_date']);

      if (name is! String ||
          name.trim().length < 2 ||
          name.trim().length > 200 ||
          status is! String ||
          !{
            'planning',
            'active',
            'on_hold',
            'completed',
            'cancelled',
          }.contains(status) ||
          location is! String ||
          location.length > 240 ||
          clientName is! String ||
          clientName.length > 160 ||
          projectType is! String ||
          !{
            'Commercial',
            'Residential',
            'Industrial',
            'Infrastructure',
            'Hospitality',
            'Healthcare',
          }.contains(projectType) ||
          budgetCurrency is! String ||
          !RegExp(r'^[A-Z]{3}$').hasMatch(budgetCurrency)) {
        return {'kind': 'invalid'};
      }
      final budgetAmount = _parseBudgetAmount(budgetInput);
      if (budgetInput != null && budgetInput != '' && budgetAmount == null) {
        return {'kind': 'invalid'};
      }
      final startDate = _parseDateOnly(startInput);
      final endDate = _parseDateOnly(endInput);
      if ((startInput != null && startDate == null) ||
          (endInput != null && endDate == null) ||
          (startDate != null &&
              endDate != null &&
              endDate.isBefore(startDate))) {
        return {'kind': 'invalid'};
      }

      final updatedRows = await transaction.execute(
        Sql.named('''
          UPDATE projects
          SET name = @name,
              status = @status,
              location = @location,
              client_name = @clientName,
              project_type = @projectType,
              budget_amount = CAST(@budgetAmount AS numeric),
              budget_currency = @budgetCurrency,
              planned_start_date = CAST(@startDate AS date),
              planned_end_date = CAST(@endDate AS date),
              version = version + 1,
              updated_at = now()
          WHERE organization_id = @organizationId
            AND id = @projectId
            AND version = @expectedVersion
          RETURNING id, code, name, status, location, created_at, updated_at,
                    client_name, project_type, budget_amount, budget_currency,
                    planned_start_date, planned_end_date, version
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'projectId': current['id'],
          'expectedVersion': expectedVersion,
          'name': name.trim(),
          'status': status,
          'location': location.trim(),
          'clientName': clientName.trim(),
          'projectType': projectType,
          'budgetAmount': budgetAmount,
          'budgetCurrency': budgetCurrency,
          'startDate': startDate == null ? null : _dateOnly(startDate),
          'endDate': endDate == null ? null : _dateOnly(endDate),
        },
      );
      if (updatedRows.isEmpty) {
        return {'kind': 'conflict', 'currentVersion': currentVersion};
      }
      final updated = updatedRows.first.toColumnMap();
      await _insertAuditEvent(
        transaction,
        organizationId: access.organizationId!,
        actorUserId: access.userId!,
        action: 'project.updated',
        entityType: 'project',
        entityId: '${updated['id']}',
        metadata: {
          'code': '${updated['code']}',
          'previousVersion': currentVersion,
          'version': updated['version'],
        },
      );
      return {'kind': 'updated', 'project': updated};
    });

    return switch (outcome['kind']) {
      'not_found' => _json(404, {'error': 'Project not found.'}),
      'conflict' => _json(409, {
        'error': 'Project was changed by another user. Reload before saving.',
        'currentVersion': outcome['currentVersion'],
      }),
      'invalid' => _json(400, {'error': 'Project fields are invalid.'}),
      'updated' => _json(200, {
        'project': _projectJson(outcome['project'] as Map<String, dynamic>),
      }),
      _ => throw StateError('Unexpected project update result.'),
    };
  }

  Future<Response> _createProject(Request request) async {
    final access = await _organizationAccess(request);
    if (access.response != null) return access.response!;
    if (!ProjectAccessPolicy.canCreateProject(access.role!)) {
      return _json(403, {'error': 'Insufficient permissions.'});
    }

    final body = await _readJson(request);
    final code = _boundedString(
      body,
      'code',
      minimum: 1,
      maximum: 40,
    ).toUpperCase();
    final name = _boundedString(body, 'name', minimum: 2, maximum: 200);
    final location = _boundedString(body, 'location', minimum: 0, maximum: 240);
    final status = body['status'] ?? 'planning';
    if (status is! String ||
        !{
          'planning',
          'active',
          'on_hold',
          'completed',
          'cancelled',
        }.contains(status)) {
      return _json(400, {'error': 'Project status is invalid.'});
    }
    final clientName = body['clientName'] ?? '';
    final projectType = body['projectType'] ?? 'Commercial';
    final budgetInput = body['budgetAmount'];
    final budgetCurrency = body['budgetCurrency'] ?? 'USD';
    final startInput = body['plannedStartDate'];
    final endInput = body['plannedEndDate'];
    if (clientName is! String ||
        clientName.length > 160 ||
        projectType is! String ||
        !{
          'Commercial',
          'Residential',
          'Industrial',
          'Infrastructure',
          'Hospitality',
          'Healthcare',
        }.contains(projectType) ||
        budgetCurrency is! String ||
        !RegExp(r'^[A-Z]{3}$').hasMatch(budgetCurrency)) {
      return _json(400, {'error': 'Project metadata is invalid.'});
    }
    final budgetAmount = _parseBudgetAmount(budgetInput);
    if (budgetInput != null && budgetInput != '' && budgetAmount == null) {
      return _json(400, {
        'error':
            'Budget must be a non-negative amount with up to two decimals.',
      });
    }
    final startDate = _parseDateOnly(startInput);
    final endDate = _parseDateOnly(endInput);
    if ((startInput != null && startDate == null) ||
        (endInput != null && endDate == null) ||
        (startDate != null && endDate != null && endDate.isBefore(startDate))) {
      return _json(400, {'error': 'Project schedule dates are invalid.'});
    }

    final result = await database.pool.runTx((transaction) async {
      await _setTenantContext(
        transaction,
        organizationId: access.organizationId!,
        userId: access.userId!,
      );
      final project = await transaction.execute(
        Sql.named('''
          INSERT INTO projects (
            organization_id, code, name, status, location, created_by,
            client_name, project_type, budget_amount, budget_currency,
            planned_start_date, planned_end_date
          )
          VALUES (
            @organizationId, @code, @name, @status, @location, @userId,
            @clientName, @projectType, CAST(@budgetAmount AS numeric),
            @budgetCurrency, CAST(@startDate AS date), CAST(@endDate AS date)
          )
          RETURNING id, created_at, updated_at, version
        '''),
        parameters: {
          'organizationId': access.organizationId,
          'code': code,
          'name': name,
          'status': status,
          'location': location,
          'userId': access.userId,
          'clientName': clientName.trim(),
          'projectType': projectType,
          'budgetAmount': budgetAmount,
          'budgetCurrency': budgetCurrency,
          'startDate': startDate == null ? null : _dateOnly(startDate),
          'endDate': endDate == null ? null : _dateOnly(endDate),
        },
      );
      final projectId = project.first.toColumnMap()['id'];
      await _insertAuditEvent(
        transaction,
        organizationId: access.organizationId!,
        actorUserId: access.userId!,
        action: 'project.created',
        entityType: 'project',
        entityId: '$projectId',
        metadata: {'code': code},
      );
      return project.first.toColumnMap();
    });

    final projectId = result['id'];
    return _json(201, {
      'project': {
        'id': '$projectId',
        'code': code,
        'name': name,
        'status': status,
        'location': location,
        'clientName': clientName.trim(),
        'projectType': projectType,
        'budgetAmount': budgetAmount,
        'budgetCurrency': budgetCurrency,
        'plannedStartDate': _dateOnly(startDate),
        'plannedEndDate': _dateOnly(endDate),
        'version': result['version'],
        'createdAt': (result['created_at'] as DateTime)
            .toUtc()
            .toIso8601String(),
        'updatedAt': (result['updated_at'] as DateTime)
            .toUtc()
            .toIso8601String(),
      },
    });
  }

  static String? _parseBudgetAmount(Object? value) {
    if (value == null || value == '') return null;
    if (value is! String && value is! num) return null;
    final text = '$value';
    if (!RegExp(r'^\d{1,18}(\.\d{1,2})?$').hasMatch(text)) return null;
    return text;
  }

  static DateTime? _parseDateOnly(Object? value) {
    if (value == null) return null;
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return null;
    }
    final date = DateTime.tryParse(value);
    if (date == null || _dateOnly(date) != value) return null;
    return date;
  }

  static String? _dateOnly(Object? value) {
    if (value == null) return null;
    if (value is DateTime) {
      final year = value.year.toString().padLeft(4, '0');
      final month = value.month.toString().padLeft(2, '0');
      final day = value.day.toString().padLeft(2, '0');
      return '$year-$month-$day';
    }
    return null;
  }

  Future<_Session?> _authenticatedSession(Request request) async {
    final authorization = request.headers['authorization'];
    if (authorization == null || !authorization.startsWith('Bearer ')) {
      return null;
    }
    final token = authorization.substring(7).trim();
    if (token.length < 40 || token.length > 64) return null;

    final result = await database.pool.execute(
      Sql.named('''
        SELECT s.token_hash, s.user_id
        FROM sessions s
        JOIN users u ON u.id = s.user_id AND u.status = 'active'
        WHERE s.token_hash = @tokenHash
          AND s.revoked_at IS NULL
          AND s.expires_at > @now
        LIMIT 1
      '''),
      parameters: {
        'tokenHash': SessionTokens.digest(token),
        'now': _clock().toUtc(),
      },
    );
    if (result.isEmpty) return null;
    final row = result.first.toColumnMap();
    return _Session('${row['token_hash']}', '${row['user_id']}');
  }

  Future<_OrganizationAccess> _organizationAccess(Request request) async {
    final session = await _authenticatedSession(request);
    if (session == null) {
      return _OrganizationAccess(response: _unauthorized());
    }

    final organizationId = request.headers['x-organization-id'];
    if (organizationId == null ||
        !RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
        ).hasMatch(organizationId)) {
      return _OrganizationAccess(
        response: _json(400, {
          'error': 'A valid X-Organization-ID is required.',
        }),
      );
    }

    final membership = await database.pool.execute(
      Sql.named('''
        SELECT m.role
        FROM memberships m
        JOIN organizations o ON o.id = m.organization_id
        WHERE m.organization_id = @organizationId
          AND m.user_id = @userId
          AND m.status = 'active'
          AND o.status = 'active'
        LIMIT 1
      '''),
      parameters: {'organizationId': organizationId, 'userId': session.userId},
    );
    if (membership.isEmpty) {
      return _OrganizationAccess(
        response: _json(404, {'error': 'Organization not found.'}),
      );
    }
    return _OrganizationAccess(
      organizationId: organizationId,
      userId: session.userId,
      role: '${membership.first.toColumnMap()['role']}',
    );
  }

  Future<void> _insertSession(
    TxSession transaction,
    Object? userId,
    String token,
    DateTime expiresAt,
  ) async {
    await transaction.execute(
      Sql.named('''
        INSERT INTO sessions (token_hash, user_id, expires_at)
        VALUES (@tokenHash, @userId, @expiresAt)
      '''),
      parameters: {
        'tokenHash': SessionTokens.digest(token),
        'userId': userId,
        'expiresAt': expiresAt,
      },
    );
  }

  Future<void> _setTenantContext(
    TxSession transaction, {
    required Object organizationId,
    required Object userId,
  }) async {
    await transaction.execute(
      Sql.named('''
        SELECT set_config('app.organization_id', @organizationId, true),
               set_config('app.user_id', @userId, true)
      '''),
      parameters: {'organizationId': organizationId, 'userId': userId},
    );
  }

  Future<void> _insertAuditEvent(
    TxSession transaction, {
    required Object organizationId,
    required Object actorUserId,
    required String action,
    required String entityType,
    required String entityId,
    Map<String, Object?> metadata = const {},
  }) async {
    await transaction.execute(
      Sql.named('''
        INSERT INTO audit_events (
          organization_id, actor_user_id, action, entity_type, entity_id, metadata
        )
        VALUES (@organizationId, @actorUserId, @action, @entityType, @entityId, @metadata)
      '''),
      parameters: {
        'organizationId': organizationId,
        'actorUserId': actorUserId,
        'action': action,
        'entityType': entityType,
        'entityId': entityId,
        'metadata': jsonEncode(metadata),
      },
    );
  }

  Response? _checkRateLimit(Request request) {
    final connectionInfo =
        request.context['shelf.io.connection_info'] as HttpConnectionInfo?;
    final remoteAddress = connectionInfo?.remoteAddress.address ?? 'unknown';
    final key = '${request.url.path}:$remoteAddress';
    final retry = _rateLimiter.retryAfter(key);
    if (retry == null) return null;
    return Response(
      429,
      body: jsonEncode({'error': 'Too many requests. Try again later.'}),
      headers: {..._jsonHeaders, 'retry-after': '${max(1, retry.inSeconds)}'},
    );
  }

  Middleware _securityHeaders() =>
      (innerHandler) => (request) async {
        final response = await innerHandler(request);
        return response.change(
          headers: {
            'x-content-type-options': 'nosniff',
            'cache-control': 'no-store',
            'referrer-policy': 'no-referrer',
          },
        );
      };

  Middleware _cors(Set<String> allowedOrigins) =>
      (innerHandler) => (request) async {
        final origin = request.headers['origin'];
        if (origin == null) return innerHandler(request);
        if (!allowedOrigins.contains(origin)) {
          return _json(403, {'error': 'Origin is not allowed.'});
        }
        if (request.method == 'OPTIONS') {
          return Response(
            204,
            headers: {
              'access-control-allow-origin': origin,
              'access-control-allow-methods': 'GET, POST, PATCH, OPTIONS',
              'access-control-allow-headers':
                  'authorization, content-type, x-organization-id',
              'access-control-max-age': '600',
              'vary': 'origin',
            },
          );
        }
        final response = await innerHandler(request);
        return response.change(
          headers: {'access-control-allow-origin': origin, 'vary': 'origin'},
        );
      };

  Middleware _errorHandler() =>
      (innerHandler) => (request) async {
        try {
          return await innerHandler(request);
        } on FormatException catch (error) {
          return _json(400, {'error': error.message});
        } on UniqueViolationException {
          return _json(409, {
            'error':
                'A unique account or project identifier is already in use.',
          });
        } on Object catch (error, stackTrace) {
          // Keep request and credential data out of logs and responses.
          developer.log(
            'Request failed (${error.runtimeType}).',
            name: 'structflow.api',
            stackTrace: stackTrace,
          );
          return _json(500, {'error': 'An unexpected server error occurred.'});
        }
      };

  Future<Map<String, dynamic>> _readJson(
    Request request, {
    int maxBytes = 16 * 1024,
  }) async {
    final contentType = request.headers['content-type']
        ?.split(';')
        .first
        .trim()
        .toLowerCase();
    if (contentType != 'application/json') {
      throw const FormatException('Content-Type must be application/json.');
    }
    final bytes = <int>[];
    await for (final chunk in request.read()) {
      if (bytes.length + chunk.length > maxBytes) {
        throw const FormatException('Request body is too large.');
      }
      bytes.addAll(chunk);
    }
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('A JSON object is required.');
    }
    return decoded;
  }

  static String _boundedString(
    Map<String, dynamic> body,
    String key, {
    required int minimum,
    required int maximum,
  }) {
    final value = body[key];
    if (value is! String) {
      throw FormatException('$key must be a string.');
    }
    final trimmed = value.trim();
    if (trimmed.length < minimum || trimmed.length > maximum) {
      throw FormatException(
        '$key length must be between $minimum and $maximum.',
      );
    }
    return trimmed;
  }

  static String? _passwordString(Map<String, dynamic> body) {
    final value = body['password'];
    if (value is! String || value.isEmpty || value.length > 72) {
      return null;
    }
    return value;
  }

  static String? _normalizedEmail(Object? value) {
    if (value is! String) return null;
    final email = value.trim().toLowerCase();
    if (email.length > 254 ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return null;
    }
    return email;
  }

  static String _slug(String value) {
    final slug = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'organization' : slug;
  }

  static const _jsonHeaders = {
    'content-type': 'application/json; charset=utf-8',
    'cache-control': 'no-store',
  };

  static Response _json(int statusCode, Object body) =>
      Response(statusCode, body: jsonEncode(body), headers: _jsonHeaders);

  static Response _unauthorized() =>
      _json(401, {'error': 'Authentication required.'});
}

class _Session {
  const _Session(this.tokenHash, this.userId);
  final String tokenHash;
  final String userId;
}

class _OrganizationAccess {
  const _OrganizationAccess({
    this.organizationId,
    this.userId,
    this.role,
    this.response,
  });
  final String? organizationId;
  final String? userId;
  final String? role;
  final Response? response;
}
