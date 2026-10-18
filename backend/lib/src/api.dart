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
          SELECT t.id, t.project_id, t.version,
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

      final updatedRows = await transaction.execute(
        Sql.named('''
          UPDATE tasks
          SET title = @title,
              description = @description,
              status = @status,
              priority = @priority,
              due_date = CAST(@dueDate AS date),
              progress = @progress,
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
        metadata: {'previousVersion': version, 'version': version + 1},
      );
      final taskRows = await transaction.execute(
        Sql.named('''
          SELECT t.id, t.title, t.description, t.status, t.priority,
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
      if (taskRows.isEmpty) {
        throw StateError('Updated task was not visible to its editor.');
      }
      return {'kind': 'updated', 'task': taskRows.first.toColumnMap()};
    });

    return switch (outcome['kind']) {
      'not_found' => _json(404, {'error': 'Task not found.'}),
      'forbidden' => _json(403, {'error': 'Insufficient permissions.'}),
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
    if (priority is! String ||
        !{'low', 'medium', 'high', 'urgent'}.contains(priority) ||
        dueDate == null) {
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
      final created = await transaction.execute(
        Sql.named('''
          INSERT INTO tasks (
            organization_id, project_id, title, description, status, priority,
            due_date, progress, created_by
          )
          VALUES (
            @organizationId, @projectId, @title, @description, 'todo',
            @priority, CAST(@dueDate AS date), 0, @userId
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
        metadata: {'projectCode': projectCode, 'priority': priority},
      );
      final taskRows = await transaction.execute(
        Sql.named('''
          SELECT t.id, t.title, t.description, t.status, t.priority,
                 t.due_date, t.progress, t.version, p.code AS project_code,
                 p.name AS project_name, 'Unassigned' AS assignee
          FROM tasks t
          JOIN projects p
            ON p.organization_id = t.organization_id
           AND p.id = t.project_id
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
    if (outcome['kind'] == 'not_found') {
      return _json(404, {'error': 'Project not found or access denied.'});
    }
    if (outcome['kind'] != 'created') {
      throw StateError('Unexpected task creation result.');
    }

    final row = outcome['task'] as Map<String, dynamic>;
    return _json(201, {
      'task': {
        'id': '${row['id']}',
        'title': '${row['title']}',
        'description': '${row['description']}',
        'projectCode': '${row['project_code']}',
        'projectName': '${row['project_name']}',
        'assignee': '${row['assignee']}',
        'status': '${row['status']}',
        'priority': '${row['priority']}',
        'dueDate': _dateOnly(row['due_date']),
        'progress': row['progress']?.toString(),
        'version': row['version'],
      },
    });
  }

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

  Future<Map<String, dynamic>> _readJson(Request request) async {
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
      if (bytes.length + chunk.length > 16 * 1024) {
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
