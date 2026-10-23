import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:structflow/core/network/api_auth_client.dart';
import 'package:structflow/features/bim/models/bim_workspace_models.dart';
import 'package:structflow/features/projects/models/project_model.dart';
import 'package:structflow/features/tasks/models/task_model.dart';

void main() {
  const token = 'secure-access-token';
  const organizationId = '10000000-0000-4000-8000-000000000001';

  test(
    'stores token only after server verifies the signed-in profile',
    () async {
      final tokenStore = _MemoryTokenStore();
      final seenRequests = <http.Request>[];
      final client = ApiAuthClient(
        baseUri: Uri.parse('https://api.example.test'),
        tokenStore: tokenStore,
        httpClient: MockClient((request) async {
          seenRequests.add(request);
          if (request.url.path == '/v1/auth/login') {
            expect(request.method, 'POST');
            expect(jsonDecode(request.body), {
              'email': 'user@example.test',
              'password': 'long-secret-password',
            });
            return http.Response(
              jsonEncode({'accessToken': token}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          expect(request.url.path, '/v1/me');
          expect(request.headers['authorization'], 'Bearer $token');
          return _profileResponse();
        }),
      );

      final user = await client.signIn(
        email: 'user@example.test',
        password: 'long-secret-password',
      );

      expect(seenRequests, hasLength(2));
      expect(tokenStore.value, token);
      expect(user.id, '20000000-0000-4000-8000-000000000001');
      expect(user.organizationId, organizationId);
      expect(user.organization, 'Example Construction');
      expect(user.role, 'Project Manager');
      expect(user.isApproved, isTrue);
    },
  );

  test('does not persist a token when profile verification fails', () async {
    final tokenStore = _MemoryTokenStore();
    final client = ApiAuthClient(
      baseUri: Uri.parse('https://api.example.test'),
      tokenStore: tokenStore,
      httpClient: MockClient((request) async {
        if (request.url.path == '/v1/auth/login') {
          return http.Response(jsonEncode({'accessToken': token}), 200);
        }
        return http.Response(jsonEncode({'error': 'Invalid session.'}), 401);
      }),
    );

    await expectLater(
      client.signIn(email: 'user@example.test', password: 'valid-password'),
      throwsA(isA<AuthApiException>()),
    );
    expect(tokenStore.value, isNull);
  });

  test('clears an expired secure token after a 401 response', () async {
    final tokenStore = _MemoryTokenStore()..value = token;
    final client = ApiAuthClient(
      baseUri: Uri.parse('https://api.example.test'),
      tokenStore: tokenStore,
      httpClient: MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer $token');
        return http.Response(
          jsonEncode({'error': 'Authentication required.'}),
          401,
        );
      }),
    );

    expect(await client.restoreSession(), isNull);
    expect(tokenStore.value, isNull);
  });

  test('restores a valid secure session from the server profile', () async {
    final tokenStore = _MemoryTokenStore()..value = token;
    final client = ApiAuthClient(
      baseUri: Uri.parse('https://api.example.test'),
      tokenStore: tokenStore,
      httpClient: MockClient((request) async {
        expect(request.url.path, '/v1/me');
        expect(request.headers['authorization'], 'Bearer $token');
        return _profileResponse();
      }),
    );

    final user = await client.restoreSession();

    expect(user?.email, 'user@example.test');
    expect(tokenStore.value, token);
  });

  test('loads projects with the session and active company scope', () async {
    final tokenStore = _MemoryTokenStore()..value = token;
    final client = ApiAuthClient(
      baseUri: Uri.parse('https://api.example.test'),
      tokenStore: tokenStore,
      httpClient: MockClient((request) async {
        expect(request.url.path, '/v1/projects');
        expect(request.headers['authorization'], 'Bearer $token');
        expect(request.headers['x-organization-id'], organizationId);
        return http.Response(
          jsonEncode({
            'projects': [
              {
                'id': '30000000-0000-4000-8000-000000000001',
                'code': 'CIVIL-001',
                'name': 'Regional Infrastructure',
                'status': 'on_hold',
                'location': 'Cairo',
                'clientName': 'Ministry of Transport',
                'projectType': 'Infrastructure',
                'budgetAmount': 1200000,
                'budgetCurrency': 'EGP',
                'plannedStartDate': '2026-01-02',
                'plannedEndDate': '2027-01-02',
                'version': 4,
              },
            ],
          }),
          200,
        );
      }),
    );

    final projects = await client.listProjects(organizationId: organizationId);

    expect(projects, hasLength(1));
    expect(projects.single.id, '30000000-0000-4000-8000-000000000001');
    expect(projects.single.code, 'CIVIL-001');
    expect(projects.single.status, 'On Hold');
    expect(projects.single.location, 'Cairo');
    expect(projects.single.client, 'Ministry of Transport');
    expect(projects.single.projectType, 'Infrastructure');
    expect(projects.single.budget, 'EGP 1200000');
    expect(projects.single.plannedStartDate, DateTime(2026, 1, 2));
    expect(projects.single.plannedEndDate, DateTime(2027, 1, 2));
    expect(projects.single.version, 4);
  });

  test('does not return partial or malformed project data', () async {
    final client = ApiAuthClient(
      baseUri: Uri.parse('https://api.example.test'),
      tokenStore: _MemoryTokenStore()..value = token,
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'projects': [
              {'id': 'project-without-required-fields'},
            ],
          }),
          200,
        ),
      ),
    );

    await expectLater(
      client.listProjects(organizationId: organizationId),
      throwsA(isA<AuthApiException>()),
    );
  });

  test('loads one authorized project by its server identifier', () async {
    final client = ApiAuthClient(
      baseUri: Uri.parse('https://api.example.test'),
      tokenStore: _MemoryTokenStore()..value = token,
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.path,
          '/v1/projects/30000000-0000-4000-8000-000000000001',
        );
        expect(request.headers['authorization'], '******');
        expect(request.headers['x-organization-id'], organizationId);
        return http.Response(
          jsonEncode({
            'project': {
              'id': '30000000-0000-4000-8000-000000000001',
              'code': 'CIVIL-001',
              'name': 'Regional Infrastructure',
              'status': 'active',
              'location': 'Cairo',
              'clientName': 'Ministry of Transport',
              'projectType': 'Infrastructure',
              'budgetAmount': '1250000.50',
              'budgetCurrency': 'EGP',
              'plannedStartDate': '2026-01-02',
              'plannedEndDate': '2027-01-02',
              'version': 3,
            },
          }),
          200,
        );
      }),
    );

    final project = await client.getProject(
      organizationId: organizationId,
      projectIdentifier: '30000000-0000-4000-8000-000000000001',
    );

    expect(project.code, 'CIVIL-001');
    expect(project.client, 'Ministry of Transport');
    expect(project.budget, 'EGP 1250000.50');
    expect(project.version, 3);
  });

  test('surfaces forbidden and not-found project responses', () async {
    for (final statusCode in [403, 404]) {
      final client = ApiAuthClient(
        baseUri: Uri.parse('https://api.example.test'),
        tokenStore: _MemoryTokenStore()..value = token,
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({'error': 'Project not found.'}),
            statusCode,
          ),
        ),
      );

      await expectLater(
        client.getProject(
          organizationId: organizationId,
          projectIdentifier: 'inaccessible-project',
        ),
        throwsA(
          isA<AuthApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            statusCode,
          ),
        ),
      );
    }
  });

  test('loads company-scoped tasks and filters by project code', () async {
    final client = ApiAuthClient(
      baseUri: Uri.parse('https://api.example.test'),
      tokenStore: _MemoryTokenStore()..value = token,
      httpClient: MockClient((request) async {
        expect(request.url.path, '/v1/tasks');
        expect(request.url.queryParameters, {'projectCode': 'CIVIL 001'});
        expect(request.headers['x-organization-id'], organizationId);
        return http.Response(
          jsonEncode({
            'tasks': [
              {
                'id': '40000000-0000-4000-8000-000000000001',
                'title': 'Approve method statement',
                'description': 'Review construction methodology.',
                'projectCode': 'CIVIL 001',
                'projectName': 'Regional Infrastructure',
                'assignee': 'Unassigned',
                'status': 'in_progress',
                'priority': 'high',
                'dueDate': '2026-11-20',
                'progress': '0.5',
                'version': 2,
              },
            ],
          }),
          200,
        );
      }),
    );

    final tasks = await client.listTasks(
      organizationId: organizationId,
      projectCode: 'CIVIL 001',
    );

    expect(tasks, hasLength(1));
    expect(tasks.single, isA<TaskModel>());
    expect(tasks.single.status, 'In Progress');
    expect(tasks.single.priority, 'High');
    expect(tasks.single.dueDate, DateTime(2026, 11, 20));
    expect(tasks.single.version, 2);
  });

  test('rejects incomplete or unsupported API task responses', () async {
    final client = ApiAuthClient(
      baseUri: Uri.parse('https://api.example.test'),
      tokenStore: _MemoryTokenStore()..value = token,
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'tasks': [
              {
                'id': 'task-1',
                'title': 'Unknown status',
                'description': '',
                'projectCode': 'PRJ',
                'projectName': 'Project',
                'assignee': 'Unassigned',
                'status': 'blocked',
                'priority': 'normal',
                'dueDate': '2026-11-20',
                'progress': '0',
                'version': 1,
              },
            ],
          }),
          200,
        ),
      ),
    );

    await expectLater(
      client.listTasks(organizationId: organizationId),
      throwsA(isA<AuthApiException>()),
    );
  });

  test('creates a task using the active company and project scope', () async {
    const assigneeId = '20000000-0000-4000-8000-000000000003';
    final client = ApiAuthClient(
      baseUri: Uri.parse('https://api.example.test'),
      tokenStore: _MemoryTokenStore()..value = token,
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/v1/tasks');
        expect(request.headers['x-organization-id'], organizationId);
        expect(jsonDecode(request.body), {
          'projectCode': 'CIVIL-001',
          'title': 'Inspect concrete pour',
          'description': 'Verify the quality checklist.',
          'priority': 'urgent',
          'dueDate': '2026-11-20',
          'assignedUserId': assigneeId,
        });
        return http.Response(
          jsonEncode({
            'task': {
              'id': '40000000-0000-4000-8000-000000000002',
              'title': 'Inspect concrete pour',
              'description': 'Verify the quality checklist.',
              'projectCode': 'CIVIL-001',
              'projectName': 'Regional Infrastructure',
              'assignee': 'Project Contributor',
              'assignedUserId': assigneeId,
              'status': 'todo',
              'priority': 'urgent',
              'dueDate': '2026-11-20',
              'progress': '0',
              'version': 1,
            },
          }),
          201,
        );
      }),
    );

    final task = await client.createTask(
      organizationId: organizationId,
      projectCode: 'CIVIL-001',
      title: 'Inspect concrete pour',
      description: 'Verify the quality checklist.',
      priority: 'Urgent',
      dueDate: DateTime(2026, 11, 20),
      assignedUserId: assigneeId,
    );

    expect(task.id, '40000000-0000-4000-8000-000000000002');
    expect(task.status, 'To Do');
    expect(task.priority, 'Urgent');
    expect(task.assignedUserId, assigneeId);
  });

  test('loads active assignable members for an authorized project', () async {
    final client = ApiAuthClient(
      baseUri: Uri.parse('https://api.example.test'),
      tokenStore: _MemoryTokenStore()..value = token,
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/v1/projects/CIVIL%20001/members');
        expect(request.headers['x-organization-id'], organizationId);
        return http.Response(
          jsonEncode({
            'projectCode': 'CIVIL 001',
            'members': [
              {
                'id': '20000000-0000-4000-8000-000000000003',
                'name': 'Project Contributor',
                'role': 'contributor',
              },
              {
                'id': '20000000-0000-4000-8000-000000000004',
                'name': 'Project Manager',
                'role': 'project_manager',
              },
            ],
          }),
          200,
        );
      }),
    );

    final members = await client.listProjectMembers(
      organizationId: organizationId,
      projectIdentifier: 'CIVIL 001',
    );

    expect(members, hasLength(2));
    expect(members.first.name, 'Project Contributor');
    expect(members.first.role, 'contributor');
  });

  test('loads a task detail in the active company scope', () async {
    final client = ApiAuthClient(
      baseUri: Uri.parse('https://api.example.test'),
      tokenStore: _MemoryTokenStore()..value = token,
      httpClient: MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.path,
          '/v1/tasks/40000000-0000-4000-8000-000000000003',
        );
        expect(request.headers['x-organization-id'], organizationId);
        return http.Response(
          jsonEncode({
            'task': {
              'id': '40000000-0000-4000-8000-000000000003',
              'title': 'Review shop drawings',
              'description': 'Review latest revisions.',
              'projectCode': 'CIVIL-001',
              'projectName': 'Regional Infrastructure',
              'assignee': 'Unassigned',
              'status': 'review',
              'priority': 'medium',
              'dueDate': '2026-11-22',
              'progress': '0.8',
              'version': 3,
            },
          }),
          200,
        );
      }),
    );

    final task = await client.getTask(
      organizationId: organizationId,
      taskId: '40000000-0000-4000-8000-000000000003',
    );

    expect(task.title, 'Review shop drawings');
    expect(task.status, 'Review');
    expect(task.version, 3);
  });

  test('updates a task with optimistic version and server response', () async {
    final client = ApiAuthClient(
      baseUri: Uri.parse('https://api.example.test'),
      tokenStore: _MemoryTokenStore()..value = token,
      httpClient: MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(
          request.url.path,
          '/v1/tasks/40000000-0000-4000-8000-000000000003',
        );
        expect(request.headers['x-organization-id'], organizationId);
        expect(jsonDecode(request.body), {
          'expectedVersion': 3,
          'title': 'Approved shop drawings',
          'description': 'Approved for consultant review.',
          'status': 'done',
          'priority': 'high',
          'dueDate': '2026-11-24',
          'progress': 1,
          'assignedUserId': null,
        });
        return http.Response(
          jsonEncode({
            'task': {
              'id': '40000000-0000-4000-8000-000000000003',
              'title': 'Approved shop drawings',
              'description': 'Approved for consultant review.',
              'projectCode': 'CIVIL-001',
              'projectName': 'Regional Infrastructure',
              'assignee': 'Unassigned',
              'status': 'done',
              'priority': 'high',
              'dueDate': '2026-11-24',
              'progress': '1',
              'version': 4,
            },
          }),
          200,
        );
      }),
    );

    final updated = await client.updateTask(
      organizationId: organizationId,
      task: TaskModel(
        id: '40000000-0000-4000-8000-000000000003',
        title: 'Approved shop drawings',
        description: 'Approved for consultant review.',
        projectCode: 'CIVIL-001',
        projectName: 'Regional Infrastructure',
        assignee: 'Unassigned',
        status: 'Done',
        priority: 'High',
        dueDate: DateTime(2026, 11, 24),
        progress: 1,
        version: 3,
        color: Colors.blue,
      ),
    );

    expect(updated.version, 4);
    expect(updated.status, 'Done');
    expect(updated.title, 'Approved shop drawings');
  });

  test('surfaces task version conflicts without retrying the update', () async {
    var requestCount = 0;
    final client = ApiAuthClient(
      baseUri: Uri.parse('https://api.example.test'),
      tokenStore: _MemoryTokenStore()..value = token,
      httpClient: MockClient((_) async {
        requestCount++;
        return http.Response(
          jsonEncode({
            'error': 'Task was changed by another user.',
            'currentVersion': 4,
          }),
          409,
        );
      }),
    );

    await expectLater(
      client.updateTask(
        organizationId: organizationId,
        task: TaskModel(
          id: '40000000-0000-4000-8000-000000000003',
          title: 'Approved shop drawings',
          description: '',
          projectCode: 'CIVIL-001',
          projectName: 'Regional Infrastructure',
          assignee: 'Unassigned',
          status: 'Done',
          priority: 'High',
          dueDate: DateTime(2026, 11, 24),
          progress: 1,
          version: 3,
          color: Colors.blue,
        ),
      ),
      throwsA(
        isA<AuthApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          409,
        ),
      ),
    );
    expect(requestCount, 1);
  });

  test(
    'updates a project with optimistic version and preserves response data',
    () async {
      final client = ApiAuthClient(
        baseUri: Uri.parse('https://api.example.test'),
        tokenStore: _MemoryTokenStore()..value = token,
        httpClient: MockClient((request) async {
          expect(request.method, 'PATCH');
          expect(
            request.url.path,
            '/v1/projects/30000000-0000-4000-8000-000000000001',
          );
          expect(request.headers['x-organization-id'], organizationId);
          expect(jsonDecode(request.body), {
            'expectedVersion': 7,
            'name': 'Updated infrastructure',
            'status': 'active',
            'location': 'Alexandria',
            'clientName': 'Transport Authority',
            'projectType': 'Infrastructure',
            'budgetAmount': '1250000.50',
            'budgetCurrency': 'EGP',
            'plannedStartDate': '2026-03-01',
            'plannedEndDate': '2027-03-01',
          });
          return http.Response(
            jsonEncode({
              'project': {
                'id': '30000000-0000-4000-8000-000000000001',
                'code': 'CIVIL-001',
                'name': 'Updated infrastructure',
                'status': 'active',
                'location': 'Alexandria',
                'clientName': 'Transport Authority',
                'projectType': 'Infrastructure',
                'budgetAmount': '1250000.50',
                'budgetCurrency': 'EGP',
                'plannedStartDate': '2026-03-01',
                'plannedEndDate': '2027-03-01',
                'version': 8,
              },
            }),
            200,
          );
        }),
      );

      final updated = await client.updateProject(
        organizationId: organizationId,
        project: ProjectModel(
          id: '30000000-0000-4000-8000-000000000001',
          code: 'CIVIL-001',
          name: 'Updated infrastructure',
          organizationId: organizationId,
          client: 'Transport Authority',
          location: 'Alexandria',
          projectType: 'Infrastructure',
          status: 'Active',
          progress: 0,
          budget: 'EGP 1250000.50',
          team: 0,
          plannedStartDate: DateTime(2026, 3, 1),
          plannedEndDate: DateTime(2027, 3, 1),
          version: 7,
          color: Colors.blue,
          icon: Icons.apartment_rounded,
        ),
      );

      expect(updated.name, 'Updated infrastructure');
      expect(updated.version, 8);
      expect(updated.plannedEndDate, DateTime(2027, 3, 1));
    },
  );

  test(
    'surfaces stale-version conflicts without retrying the update',
    () async {
      var requestCount = 0;
      final client = ApiAuthClient(
        baseUri: Uri.parse('https://api.example.test'),
        tokenStore: _MemoryTokenStore()..value = token,
        httpClient: MockClient((_) async {
          requestCount++;
          return http.Response(
            jsonEncode({
              'error': 'Project was changed by another user.',
              'currentVersion': 8,
            }),
            409,
          );
        }),
      );

      await expectLater(
        client.updateProject(
          organizationId: organizationId,
          project: const ProjectModel(
            id: '30000000-0000-4000-8000-000000000001',
            code: 'CIVIL-001',
            name: 'Updated infrastructure',
            client: '',
            location: 'Cairo',
            projectType: 'Infrastructure',
            status: 'Active',
            progress: 0,
            budget: '',
            team: 0,
            version: 7,
            color: Colors.blue,
            icon: Icons.apartment_rounded,
          ),
        ),
        throwsA(
          isA<AuthApiException>()
              .having((error) => error.statusCode, 'statusCode', 409)
              .having(
                (error) => error.message,
                'message',
                contains('changed by another user'),
              ),
        ),
      );
      expect(requestCount, 1);
    },
  );

  test(
    'creates projects using server-authoritative fields and company scope',
    () async {
      final tokenStore = _MemoryTokenStore()..value = token;
      final client = ApiAuthClient(
        baseUri: Uri.parse('https://api.example.test'),
        tokenStore: tokenStore,
        httpClient: MockClient((request) async {
          expect(request.url.path, '/v1/projects');
          expect(request.method, 'POST');
          expect(request.headers['authorization'], 'Bearer $token');
          expect(request.headers['x-organization-id'], organizationId);
          expect(request.headers['content-type'], 'application/json');
          expect(jsonDecode(request.body), {
            'code': 'NEW-001',
            'name': 'New hospital',
            'clientName': 'Not yet persisted',
            'projectType': 'Commercial',
            'location': 'Cairo',
            'status': 'planning',
            'budgetAmount': '1000000',
            'budgetCurrency': 'EGP',
            'plannedStartDate': null,
            'plannedEndDate': null,
          });
          return http.Response(
            jsonEncode({
              'project': {
                'id': '30000000-0000-4000-8000-000000000003',
                'code': 'NEW-001',
                'name': 'New hospital',
                'status': 'planning',
                'location': 'Cairo',
                'clientName': 'Not yet persisted',
                'projectType': 'Commercial',
                'budgetAmount': 1000000,
                'budgetCurrency': 'EGP',
                'plannedStartDate': '2026-01-02',
                'plannedEndDate': '2026-02-02',
                'version': 1,
              },
            }),
            201,
          );
        }),
      );

      final project = await client.createProject(
        organizationId: organizationId,
        project: const ProjectModel(
          id: '',
          code: 'NEW-001',
          name: 'New hospital',
          client: 'Not yet persisted',
          location: 'Cairo',
          projectType: 'Commercial',
          status: 'Planning',
          progress: 0,
          budget: 'EGP 1000000',
          team: 1,
          color: Colors.blue,
          icon: Icons.apartment_rounded,
        ),
      );

      expect(project.id, '30000000-0000-4000-8000-000000000003');
      expect(project.organizationId, organizationId);
      expect(project.status, 'Planning');
      expect(project.client, 'Not yet persisted');
      expect(project.budget, 'EGP 1000000');
      expect(project.plannedStartDate, DateTime(2026, 1, 2));
      expect(project.plannedEndDate, DateTime(2026, 2, 2));
      expect(project.version, 1);
    },
  );

  test(
    'rejects malformed project budgets before sending an API request',
    () async {
      var requestSent = false;
      final client = ApiAuthClient(
        baseUri: Uri.parse('https://api.example.test'),
        tokenStore: _MemoryTokenStore()..value = token,
        httpClient: MockClient((_) async {
          requestSent = true;
          return http.Response('{}', 500);
        }),
      );

      await expectLater(
        client.createProject(
          organizationId: organizationId,
          project: const ProjectModel(
            code: 'NEW-001',
            name: 'New hospital',
            client: '',
            location: 'Cairo',
            projectType: 'Commercial',
            status: 'Planning',
            progress: 0,
            budget: 'USD -10',
            team: 0,
            color: Colors.blue,
            icon: Icons.apartment_rounded,
          ),
        ),
        throwsA(isA<AuthApiException>()),
      );
      expect(requestSent, isFalse);
    },
  );

  test(
    'surfaces create permission and duplicate-code errors from the API',
    () async {
      final client = ApiAuthClient(
        baseUri: Uri.parse('https://api.example.test'),
        tokenStore: _MemoryTokenStore()..value = token,
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({'error': 'Insufficient permissions.'}),
            403,
          ),
        ),
      );

      await expectLater(
        client.createProject(
          organizationId: organizationId,
          project: const ProjectModel(
            code: 'NEW-001',
            name: 'New hospital',
            client: '',
            location: 'Cairo',
            status: 'Planning',
            progress: 0,
            budget: '',
            team: 0,
            color: Colors.blue,
            icon: Icons.apartment_rounded,
          ),
        ),
        throwsA(
          isA<AuthApiException>()
              .having((error) => error.statusCode, 'statusCode', 403)
              .having(
                (error) => error.message,
                'message',
                'Insufficient permissions.',
              ),
        ),
      );
    },
  );

  test(
    'refuses ambiguous multi-company sessions and revokes the token',
    () async {
      final tokenStore = _MemoryTokenStore();
      var logoutRequested = false;
      final client = ApiAuthClient(
        baseUri: Uri.parse('https://api.example.test'),
        tokenStore: tokenStore,
        httpClient: MockClient((request) async {
          if (request.url.path == '/v1/auth/login') {
            return http.Response(jsonEncode({'accessToken': token}), 200);
          }
          if (request.url.path == '/v1/auth/logout') {
            logoutRequested = true;
            return http.Response('', 204);
          }
          return http.Response(
            jsonEncode({
              'user': {
                'id': '20000000-0000-4000-8000-000000000001',
                'name': 'Example User',
                'email': 'user@example.test',
              },
              'organizations': [
                {'id': organizationId, 'name': 'Company One', 'role': 'member'},
                {
                  'id': '10000000-0000-4000-8000-000000000002',
                  'name': 'Company Two',
                  'role': 'member',
                },
              ],
            }),
            200,
          );
        }),
      );

      await expectLater(
        client.signIn(email: 'user@example.test', password: 'valid-password'),
        throwsA(
          isA<AuthApiException>().having(
            (error) => error.message,
            'message',
            contains('multiple companies'),
          ),
        ),
      );

      expect(logoutRequested, isTrue);
      expect(tokenStore.value, isNull);
    },
  );

  test(
    'updates BIM issue status with BCF identity and expected version',
    () async {
      final issue = BimIssue(
        id: '50000000-0000-4000-8000-000000000001',
        projectCode: 'CIVIL-001',
        title: 'Coordinate duct routing',
        description: 'Resolve the level 2 clash.',
        discipline: 'Mechanical',
        location: 'Level 2',
        severity: 'High',
        status: 'In progress',
        assignedTo: 'Mechanical team',
        dueDate: DateTime(2027, 2, 1),
        bcfGuid: '60000000-0000-4000-8000-000000000001',
        version: 3,
      );
      final client = ApiAuthClient(
        baseUri: Uri.parse('https://api.example.test'),
        tokenStore: _MemoryTokenStore()..value = token,
        httpClient: MockClient((request) async {
          expect(request.method, 'PATCH');
          expect(request.url.path, '/v1/bim/issues/${issue.id}');
          expect(request.headers['x-organization-id'], organizationId);
          expect(jsonDecode(request.body), {
            'status': 'in_progress',
            'expectedVersion': 3,
          });
          return http.Response(
            jsonEncode({
              'issue': {
                'id': issue.id,
                'bcfGuid': issue.bcfGuid,
                'title': issue.title,
                'description': issue.description,
                'discipline': issue.discipline,
                'location': issue.location,
                'severity': 'high',
                'status': 'in_progress',
                'assignedTo': issue.assignedTo,
                'dueDate': '2027-02-01',
                'version': 4,
              },
            }),
            200,
          );
        }),
      );

      final updated = await client.updateBimIssueStatus(
        organizationId: organizationId,
        issue: issue,
      );

      expect(updated.bcfGuid, issue.bcfGuid);
      expect(updated.status, 'In progress');
      expect(updated.version, 4);
    },
  );

  test('loads and registers project-scoped BIM model metadata', () async {
    final model = BimModelRecord(
      id: 'BIM-MOD-local',
      projectCode: 'CIVIL-001',
      name: 'Tower Structure',
      discipline: 'Structure',
      version: 'v2',
      status: 'In review',
      updatedAt: DateTime.utc(2026, 10, 23),
    );
    var requestCount = 0;
    final client = ApiAuthClient(
      baseUri: Uri.parse('https://api.example.test'),
      tokenStore: _MemoryTokenStore()..value = token,
      httpClient: MockClient((request) async {
        expect(request.headers['authorization'], startsWith('Bearer '));
        expect(request.headers['x-organization-id'], organizationId);
        if (request.method == 'GET') {
          expect(request.url.path, '/v1/projects/CIVIL-001/bim/models');
          requestCount++;
          return http.Response(
            jsonEncode({
              'projectCode': 'CIVIL-001',
              'models': [
                {
                  'id': '50000000-0000-4000-8000-000000000001',
                  'name': model.name,
                  'discipline': model.discipline,
                  'version': model.version,
                  'status': 'in_review',
                  'recordVersion': 2,
                  'updatedAt': '2026-10-23T00:00:00.000Z',
                },
              ],
            }),
            200,
          );
        }
        expect(request.method, 'POST');
        expect(request.url.path, '/v1/projects/CIVIL-001/bim/models');
        expect(jsonDecode(request.body), {
          'name': model.name,
          'discipline': model.discipline,
          'version': model.version,
        });
        requestCount++;
        return http.Response(
          jsonEncode({
            'model': {
              'id': '50000000-0000-4000-8000-000000000002',
              'name': model.name,
              'discipline': model.discipline,
              'version': model.version,
              'status': 'in_review',
              'recordVersion': 1,
              'updatedAt': '2026-10-23T00:00:00.000Z',
            },
          }),
          201,
        );
      }),
    );

    final loaded = await client.listBimModels(
      organizationId: organizationId,
      projectIdentifier: 'CIVIL-001',
    );
    final created = await client.createBimModel(
      organizationId: organizationId,
      projectIdentifier: 'CIVIL-001',
      model: model,
    );

    expect(requestCount, 2);
    expect(loaded.single.projectCode, 'CIVIL-001');
    expect(loaded.single.status, 'In review');
    expect(created.id, '50000000-0000-4000-8000-000000000002');
    expect(created.updatedAt, DateTime.utc(2026, 10, 23));
  });

  test('updates BIM model status with optimistic version control', () async {
    final model = BimModelRecord(
      id: '50000000-0000-4000-8000-000000000001',
      projectCode: 'CIVIL-001',
      name: 'Tower Structure',
      discipline: 'Structure',
      version: 'v2',
      status: 'In review',
      updatedAt: DateTime.utc(2026, 10, 23),
      recordVersion: 4,
    );
    final client = ApiAuthClient(
      baseUri: Uri.parse('https://api.example.test'),
      tokenStore: _MemoryTokenStore()..value = token,
      httpClient: MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/v1/bim/models/${model.id}');
        expect(request.headers['authorization'], 'Bearer $token');
        expect(request.headers['x-organization-id'], organizationId);
        expect(jsonDecode(request.body), {
          'status': 'published',
          'expectedVersion': 4,
        });
        return http.Response(
          jsonEncode({
            'model': {
              'id': model.id,
              'name': model.name,
              'discipline': model.discipline,
              'version': model.version,
              'status': 'published',
              'recordVersion': 5,
              'updatedAt': '2026-10-23T01:00:00.000Z',
            },
          }),
          200,
        );
      }),
    );

    final updated = await client.updateBimModelStatus(
      organizationId: organizationId,
      model: model.copyWith(status: 'Published'),
    );

    expect(updated.status, 'Published');
    expect(updated.recordVersion, 5);
  });

  test('surfaces BIM model version conflicts without retrying', () async {
    final model = BimModelRecord(
      id: '50000000-0000-4000-8000-000000000001',
      projectCode: 'CIVIL-001',
      name: 'Tower Structure',
      discipline: 'Structure',
      version: 'v2',
      status: 'In review',
      updatedAt: DateTime.utc(2026, 10, 23),
      recordVersion: 3,
    );
    var requestCount = 0;
    final client = ApiAuthClient(
      baseUri: Uri.parse('https://api.example.test'),
      tokenStore: _MemoryTokenStore()..value = token,
      httpClient: MockClient((_) async {
        requestCount++;
        return http.Response(
          jsonEncode({
            'error': 'BIM model has changed since it was loaded.',
            'currentVersion': 4,
          }),
          409,
        );
      }),
    );

    await expectLater(
      client.updateBimModelStatus(
        organizationId: organizationId,
        model: model.copyWith(status: 'Published'),
      ),
      throwsA(
        isA<AuthApiException>()
            .having((error) => error.statusCode, 'statusCode', 409)
            .having(
              (error) => error.message,
              'message',
              'BIM model has changed since it was loaded.',
            ),
      ),
    );
    expect(requestCount, 1);
  });

  test('loads and adds comments to a BIM coordination issue', () async {
    final issueId = '50000000-0000-4000-8000-000000000001';
    var requestCount = 0;
    final client = ApiAuthClient(
      baseUri: Uri.parse('https://api.example.test'),
      tokenStore: _MemoryTokenStore()..value = token,
      httpClient: MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer $token');
        expect(request.headers['x-organization-id'], organizationId);
        requestCount++;
        if (request.method == 'GET') {
          expect(request.url.path, '/v1/bim/issues/$issueId/comments');
          return http.Response(
            jsonEncode({
              'comments': [
                {
                  'id': '60000000-0000-4000-8000-000000000001',
                  'body': 'Check the clearance at grid C-2.',
                  'authorName': 'BIM Coordinator',
                  'createdAt': '2026-10-23T12:00:00.000Z',
                },
              ],
            }),
            200,
          );
        }
        expect(request.method, 'POST');
        expect(request.url.path, '/v1/bim/issues/$issueId/comments');
        expect(jsonDecode(request.body), {
          'body': 'Please confirm after the model update.',
        });
        return http.Response(
          jsonEncode({
            'comment': {
              'id': '60000000-0000-4000-8000-000000000002',
              'body': 'Please confirm after the model update.',
              'authorName': 'Project Manager',
              'createdAt': '2026-10-23T12:30:00.000Z',
            },
          }),
          201,
        );
      }),
    );

    final comments = await client.listBimIssueComments(
      organizationId: organizationId,
      issueId: issueId,
    );
    final created = await client.createBimIssueComment(
      organizationId: organizationId,
      issueId: issueId,
      body: ' Please confirm after the model update. ',
    );

    expect(requestCount, 2);
    expect(comments.single.issueId, issueId);
    expect(comments.single.authorName, 'BIM Coordinator');
    expect(created.body, 'Please confirm after the model update.');
    expect(created.createdAt, DateTime.utc(2026, 10, 23, 12, 30));
  });

  test('loads and imports BCF comments for a project', () async {
    const projectCode = 'CIVIL-001';
    const topicGuid = '60000000-0000-4000-8000-000000000001';
    const commentGuid = '60000000-0000-4000-8000-000000000002';
    final requests = <http.Request>[];
    final client = ApiAuthClient(
      baseUri: Uri.parse('https://api.example.test'),
      tokenStore: _MemoryTokenStore()..value = token,
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'comments': [
                {
                  'id': commentGuid,
                  'issueId': '50000000-0000-4000-8000-000000000001',
                  'bcfGuid': commentGuid,
                  'body': 'Confirm the clearance.',
                  'authorName': 'BCF: External Coordinator',
                  'createdAt': '2026-10-23T12:00:00.000Z',
                },
              ],
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'imported': 1}), 200);
      }),
    );
    final comment = BimIssueComment(
      id: commentGuid,
      issueId: '50000000-0000-4000-8000-000000000001',
      body: 'Confirm the clearance.',
      authorName: 'External Coordinator',
      createdAt: DateTime.utc(2026, 10, 23, 12),
      bcfGuid: commentGuid,
    );

    final comments = await client.listProjectBimComments(
      organizationId: organizationId,
      projectIdentifier: projectCode,
    );
    final imported = await client.importProjectBimComments(
      organizationId: organizationId,
      projectIdentifier: projectCode,
      commentsByTopicGuid: {
        topicGuid: [comment],
      },
    );

    expect(requests, hasLength(2));
    expect(requests.first.headers['authorization'], isNotEmpty);
    expect(requests.first.method, 'GET');
    expect(requests.first.url.path, '/v1/projects/$projectCode/bim/comments');
    expect(requests.first.headers['x-organization-id'], organizationId);
    expect(requests.last.headers['authorization'], isNotEmpty);
    expect(requests.last.method, 'POST');
    expect(
      requests.last.url.path,
      '/v1/projects/$projectCode/bim/comments/import',
    );
    expect(requests.last.headers['x-organization-id'], organizationId);
    final payload = jsonDecode(requests.last.body) as Map<String, dynamic>;
    expect(payload['comments'], [
      {
        'topicGuid': topicGuid,
        'bcfGuid': commentGuid,
        'body': 'Confirm the clearance.',
        'authorName': 'External Coordinator',
        'createdAt': '2026-10-23T12:00:00.000Z',
      },
    ]);
    expect(comments.single.bcfGuid, commentGuid);
    expect(comments.single.authorName, 'BCF: External Coordinator');
    expect(imported, 1);
  });
  test(
    'revokes the server session and deletes the secure token on sign out',
    () async {
      final tokenStore = _MemoryTokenStore()..value = token;
      final client = ApiAuthClient(
        baseUri: Uri.parse('https://api.example.test'),
        tokenStore: tokenStore,
        httpClient: MockClient((request) async {
          expect(request.url.path, '/v1/auth/logout');
          expect(request.method, 'POST');
          expect(request.headers['authorization'], 'Bearer $token');
          return http.Response('', 204);
        }),
      );

      await client.signOut();

      expect(tokenStore.value, isNull);
    },
  );

  test('requires HTTPS except for loopback development endpoints', () {
    expect(
      () => ApiAuthClient(
        baseUri: Uri.parse('http://api.example.test'),
        tokenStore: _MemoryTokenStore(),
        httpClient: MockClient((_) async => http.Response('', 200)),
      ),
      throwsStateError,
    );
  });
}

http.Response _profileResponse() => http.Response(
  jsonEncode({
    'user': {
      'id': '20000000-0000-4000-8000-000000000001',
      'name': 'Example User',
      'email': 'user@example.test',
    },
    'organizations': [
      {
        'id': '10000000-0000-4000-8000-000000000001',
        'name': 'Example Construction',
        'role': 'project_manager',
      },
    ],
  }),
  200,
  headers: {'content-type': 'application/json'},
);

class _MemoryTokenStore implements SessionTokenStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String token) async => value = token;

  @override
  Future<void> delete() async => value = null;
}
