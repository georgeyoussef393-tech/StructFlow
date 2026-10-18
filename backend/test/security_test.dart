import 'package:structflow_api/src/config.dart';
import 'package:structflow_api/src/security.dart';
import 'package:test/test.dart';

void main() {
  group('PasswordSecurity', () {
    test('enforces a twelve-character minimum', () {
      expect(PasswordSecurity.validationError('short-pass'), isNotNull);
      expect(PasswordSecurity.validationError('long-enough-password'), isNull);
    });

    test('rejects passwords over the bcrypt byte limit', () {
      expect(PasswordSecurity.validationError('a' * 73), isNotNull);
      expect(PasswordSecurity.validationError('é' * 37), isNotNull);
    });

    test('hashes and verifies passwords without storing plaintext', () {
      const password = 'a-correct-horse-battery';
      final hash = PasswordSecurity.hashPassword(password);

      expect(hash, startsWith(r'$2'));
      expect(hash, isNot(contains(password)));
      expect(PasswordSecurity.verifyPassword(password, hash), isTrue);
      expect(PasswordSecurity.verifyPassword('wrong-password', hash), isFalse);
    });
  });

  test('session tokens are random and stored as irreversible digests', () {
    final first = SessionTokens.create();
    final second = SessionTokens.create();

    expect(first, isNot(second));
    expect(SessionTokens.digest(first), hasLength(64));
    expect(SessionTokens.digest(first), isNot(first));
  });

  test('login rate limiter blocks after threshold and resets after window', () {
    var now = DateTime.utc(2026, 10, 18);
    final limiter = LoginRateLimiter(
      limit: 2,
      window: const Duration(minutes: 1),
      clock: () => now,
    );

    expect(limiter.retryAfter('client'), isNull);
    expect(limiter.retryAfter('client'), isNull);
    expect(limiter.retryAfter('client'), const Duration(minutes: 1));
    now = now.add(const Duration(minutes: 1));
    expect(limiter.retryAfter('client'), isNull);
  });

  test('only owners and organization admins can create projects', () {
    expect(ProjectAccessPolicy.canCreateProject('owner'), isTrue);
    expect(ProjectAccessPolicy.canCreateProject('admin'), isTrue);
    expect(ProjectAccessPolicy.canCreateProject('project_manager'), isFalse);
    expect(ProjectAccessPolicy.canCreateProject('member'), isFalse);
  });

  test('only owners and admins can create tasks across an organization', () {
    expect(
      ProjectAccessPolicy.canCreateTaskAcrossOrganization('owner'),
      isTrue,
    );
    expect(
      ProjectAccessPolicy.canCreateTaskAcrossOrganization('admin'),
      isTrue,
    );
    expect(
      ProjectAccessPolicy.canCreateTaskAcrossOrganization('project_manager'),
      isFalse,
    );
    expect(
      ProjectAccessPolicy.canCreateTaskAcrossOrganization('member'),
      isFalse,
    );
  });

  test('only owners and organization admins can update projects', () {
    expect(ProjectAccessPolicy.canUpdateProject('owner'), isTrue);
    expect(ProjectAccessPolicy.canUpdateProject('admin'), isTrue);
    expect(ProjectAccessPolicy.canUpdateProject('project_manager'), isFalse);
    expect(ProjectAccessPolicy.canUpdateProject('member'), isFalse);
  });

  test('project managers cannot list projects outside their assignments', () {
    expect(ProjectAccessPolicy.canListAllProjects('owner'), isTrue);
    expect(ProjectAccessPolicy.canListAllProjects('admin'), isTrue);
    expect(ProjectAccessPolicy.canListAllProjects('project_manager'), isFalse);
    expect(ProjectAccessPolicy.canListAllProjects('viewer'), isFalse);
  });

  group('AppConfig', () {
    test('requires an explicit PostgreSQL connection string', () {
      expect(() => AppConfig.fromEnvironment(const {}), throwsStateError);
    });

    test('rejects production database connections without verified TLS', () {
      expect(
        () => AppConfig.fromEnvironment({
          'APP_ENV': 'production',
          'DATABASE_URL':
              'postgresql://runtime:password@db.example.test/structflow?sslmode=require',
        }),
        throwsStateError,
      );
    });

    test('disables self-service organization signup in production', () {
      final config = AppConfig.fromEnvironment({
        'APP_ENV': 'production',
        'DATABASE_URL':
            'postgresql://runtime:password@db.example.test/structflow?sslmode=verify-full',
        'ENABLE_ORGANIZATION_SIGNUP': 'true',
      });

      expect(config.registrationEnabled, isFalse);
    });

    test('rejects wildcard CORS in production', () {
      expect(
        () => AppConfig.fromEnvironment({
          'APP_ENV': 'production',
          'DATABASE_URL':
              'postgresql://runtime:password@db.example.test/structflow?sslmode=verify-full',
          'CORS_ORIGINS': '*',
        }),
        throwsStateError,
      );
    });

    test('requires exact CORS origins without trailing paths', () {
      expect(
        () => AppConfig.fromEnvironment({
          'APP_ENV': 'production',
          'DATABASE_URL':
              'postgresql://runtime:password@db.example.test/structflow?sslmode=verify-full',
          'CORS_ORIGINS': 'https://app.example.test/',
        }),
        throwsStateError,
      );
    });
  });
}
