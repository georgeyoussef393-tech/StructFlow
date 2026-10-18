import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:structflow/core/network/api_auth_client.dart';
import 'package:structflow/features/projects/models/project_model.dart';

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
