import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:structflow_api/src/api.dart';
import 'package:structflow_api/src/config.dart';
import 'package:structflow_api/src/database.dart';
import 'package:test/test.dart';

void main() {
  late StructFlowApi api;

  setUp(() {
    final config = AppConfig.fromEnvironment({
      'APP_ENV': 'production',
      'DATABASE_URL':
          'postgresql://runtime:password@db.example.test/structflow?sslmode=verify-full',
      'CORS_ORIGINS': 'https://app.example.test',
    });
    api = StructFlowApi(
      config: config,
      database: AppDatabase(config.databaseUrl),
    );
  });

  test(
    'organization signup is closed in production without touching database',
    () async {
      final response = await api.handler(
        Request(
          'POST',
          Uri.parse('https://api.example.test/v1/auth/organizations'),
          headers: {'content-type': 'application/json'},
          body: '{}',
        ),
      );

      expect(response.statusCode, 403);
      expect(await response.readAsString(), contains('signup is disabled'));
      expect(response.headers['cache-control'], 'no-store');
      expect(response.headers['x-content-type-options'], 'nosniff');
    },
  );

  test('rejects requests from unconfigured browser origins', () async {
    final response = await api.handler(
      Request(
        'OPTIONS',
        Uri.parse('https://api.example.test/v1/auth/login'),
        headers: {'origin': 'https://untrusted.example.test'},
      ),
    );

    expect(response.statusCode, 403);
    expect(response.headers['access-control-allow-origin'], isNull);
  });

  test('allows preflight only for configured origins and headers', () async {
    final response = await api.handler(
      Request(
        'OPTIONS',
        Uri.parse('https://api.example.test/v1/projects'),
        headers: {'origin': 'https://app.example.test'},
      ),
    );

    expect(response.statusCode, 204);
    expect(
      response.headers['access-control-allow-origin'],
      'https://app.example.test',
    );
    expect(
      response.headers['access-control-allow-headers'],
      contains('x-organization-id'),
    );
    expect(response.headers['access-control-allow-methods'], contains('PATCH'));
  });

  test(
    'rejects non-JSON authentication requests before database access',
    () async {
      final response = await api.handler(
        Request(
          'POST',
          Uri.parse('https://api.example.test/v1/auth/login'),
          headers: {'content-type': 'text/plain'},
          body: '{}',
        ),
      );

      expect(response.statusCode, 400);
      expect(await response.readAsString(), contains('application/json'));
      expect(response.headers['cache-control'], 'no-store');
    },
  );

  test('project details endpoint requires an authenticated session', () async {
    final response = await api.handler(
      Request(
        'GET',
        Uri.parse(
          'https://api.example.test/v1/projects/30000000-0000-4000-8000-000000000001',
        ),
      ),
    );

    expect(response.statusCode, 401);
    expect(await response.readAsString(), contains('Authentication required'));
  });

  test('project update endpoint requires an authenticated session', () async {
    final response = await api.handler(
      Request(
        'PATCH',
        Uri.parse(
          'https://api.example.test/v1/projects/30000000-0000-4000-8000-000000000001',
        ),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'expectedVersion': 1}),
      ),
    );

    expect(response.statusCode, 401);
    expect(await response.readAsString(), contains('Authentication required'));
  });

  test('task list endpoint requires an authenticated session', () async {
    final response = await api.handler(
      Request('GET', Uri.parse('https://api.example.test/v1/tasks')),
    );

    expect(response.statusCode, 401);
    expect(await response.readAsString(), contains('Authentication required'));
  });

  test('BIM issue endpoints require an authenticated session', () async {
    final requests = [
      Request(
        'GET',
        Uri.parse('https://api.example.test/v1/projects/CIVIL-001/bim/issues'),
      ),
      Request(
        'POST',
        Uri.parse('https://api.example.test/v1/projects/CIVIL-001/bim/issues'),
        headers: {'content-type': 'application/json'},
        body: '{}',
      ),
      Request(
        'POST',
        Uri.parse(
          'https://api.example.test/v1/projects/CIVIL-001/bim/issues/import',
        ),
        headers: {'content-type': 'application/json'},
        body: '{"issues":[]}',
      ),
      Request(
        'PATCH',
        Uri.parse(
          'https://api.example.test/v1/bim/issues/50000000-0000-4000-8000-000000000001',
        ),
        headers: {'content-type': 'application/json'},
        body: '{"status":"resolved","expectedVersion":1}',
      ),
    ];

    for (final request in requests) {
      final response = await api.handler(request);
      expect(response.statusCode, 401);
      expect(
        await response.readAsString(),
        contains('Authentication required'),
      );
    }
  });

  test('BIM model endpoints require an authenticated session', () async {
    final requests = [
      Request(
        'GET',
        Uri.parse('https://api.example.test/v1/projects/CIVIL-001/bim/models'),
      ),
      Request(
        'POST',
        Uri.parse('https://api.example.test/v1/projects/CIVIL-001/bim/models'),
        headers: {'content-type': 'application/json'},
        body:
            '{"name":"Tower Structure","discipline":"Structure","version":"v2"}',
      ),
      Request(
        'PATCH',
        Uri.parse(
          'https://api.example.test/v1/bim/models/50000000-0000-4000-8000-000000000001',
        ),
        headers: {'content-type': 'application/json'},
        body: '{"status":"published","expectedVersion":1}',
      ),
    ];

    for (final request in requests) {
      final response = await api.handler(request);
      expect(response.statusCode, 401);
      expect(
        await response.readAsString(),
        contains('Authentication required'),
      );
    }
  });

  test('BIM issue comment endpoints require an authenticated session', () async {
    final requests = [
      Request(
        'GET',
        Uri.parse(
          'https://api.example.test/v1/bim/issues/50000000-0000-4000-8000-000000000001/comments',
        ),
      ),
      Request(
        'POST',
        Uri.parse(
          'https://api.example.test/v1/bim/issues/50000000-0000-4000-8000-000000000001/comments',
        ),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'body': 'Reviewed the coordination clearance.'}),
      ),
    ];

    for (final request in requests) {
      final response = await api.handler(request);
      expect(response.statusCode, 401);
      expect(
        await response.readAsString(),
        contains('Authentication required'),
      );
    }
  });

  test(
    'BCF project comment endpoints require an authenticated session',
    () async {
      final requests = [
        Request(
          'GET',
          Uri.parse(
            'https://api.example.test/v1/projects/CIVIL-001/bim/comments',
          ),
        ),
        Request(
          'POST',
          Uri.parse(
            'https://api.example.test/v1/projects/CIVIL-001/bim/comments/import',
          ),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'comments': []}),
        ),
      ];

      for (final request in requests) {
        final response = await api.handler(request);
        expect(response.statusCode, 401);
        expect(
          await response.readAsString(),
          contains('Authentication required'),
        );
      }
    },
  );

  test('task detail endpoint requires an authenticated session', () async {
    final response = await api.handler(
      Request(
        'GET',
        Uri.parse(
          'https://api.example.test/v1/tasks/40000000-0000-4000-8000-000000000001',
        ),
      ),
    );

    expect(response.statusCode, 401);
    expect(await response.readAsString(), contains('Authentication required'));
  });

  test('task update endpoint requires an authenticated session', () async {
    final response = await api.handler(
      Request(
        'PATCH',
        Uri.parse(
          'https://api.example.test/v1/tasks/40000000-0000-4000-8000-000000000001',
        ),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'expectedVersion': 1}),
      ),
    );

    expect(response.statusCode, 401);
    expect(await response.readAsString(), contains('Authentication required'));
  });

  test('task creation endpoint requires an authenticated session', () async {
    final response = await api.handler(
      Request(
        'POST',
        Uri.parse('https://api.example.test/v1/tasks'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'projectCode': 'ONE',
          'title': 'Create a task',
          'description': '',
          'dueDate': '2027-02-01',
        }),
      ),
    );

    expect(response.statusCode, 401);
    expect(await response.readAsString(), contains('Authentication required'));
  });

  test('project member endpoint requires an authenticated session', () async {
    final response = await api.handler(
      Request(
        'GET',
        Uri.parse('https://api.example.test/v1/projects/CIVIL-001/members'),
      ),
    );

    expect(response.statusCode, 401);
    expect(await response.readAsString(), contains('Authentication required'));
  });

  test(
    'rejects oversized authentication request bodies before parsing',
    () async {
      final response = await api.handler(
        Request(
          'POST',
          Uri.parse('https://api.example.test/v1/auth/login'),
          headers: {'content-type': 'application/json'},
          body: ' ' * (16 * 1024 + 1),
        ),
      );

      expect(response.statusCode, 400);
      expect(await response.readAsString(), contains('too large'));
    },
  );

  test(
    'returns a client error for malformed JSON without leaking server errors',
    () async {
      final response = await api.handler(
        Request(
          'POST',
          Uri.parse('https://api.example.test/v1/auth/login'),
          headers: {'content-type': 'application/json'},
          body: '{',
        ),
      );

      expect(response.statusCode, 400);
      expect(
        await response.readAsString(),
        isNot(contains('unexpected server')),
      );
    },
  );
}
