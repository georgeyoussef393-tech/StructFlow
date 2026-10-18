class AppConfig {
  const AppConfig({
    required this.databaseUrl,
    required this.port,
    required this.host,
    required this.registrationEnabled,
    required this.allowedOrigins,
    required this.production,
  });

  final String databaseUrl;
  final int port;
  final String host;
  final bool registrationEnabled;
  final Set<String> allowedOrigins;
  final bool production;

  factory AppConfig.fromEnvironment(Map<String, String> environment) {
    final environmentName = environment['APP_ENV'] ?? 'development';
    if (!{'development', 'test', 'production'}.contains(environmentName)) {
      throw StateError('APP_ENV must be development, test, or production.');
    }

    final databaseUrl = environment['DATABASE_URL'];
    if (databaseUrl == null || databaseUrl.isEmpty) {
      throw StateError('DATABASE_URL must be configured.');
    }

    final port = int.tryParse(environment['PORT'] ?? '8080');
    if (port == null || port < 1 || port > 65535) {
      throw StateError('PORT must be a valid TCP port.');
    }

    final production = environmentName == 'production';
    final databaseUri = Uri.tryParse(databaseUrl);
    if (databaseUri == null ||
        !{'postgres', 'postgresql'}.contains(databaseUri.scheme) ||
        databaseUri.host.isEmpty ||
        databaseUri.path.length < 2) {
      throw StateError('DATABASE_URL must be a PostgreSQL connection URL.');
    }
    if (production &&
        !{
          'verify-ca',
          'verify-full',
        }.contains(databaseUri.queryParameters['sslmode'])) {
      throw StateError(
        'Production DATABASE_URL must verify the PostgreSQL TLS certificate.',
      );
    }

    final origins = (environment['CORS_ORIGINS'] ?? '')
        .split(',')
        .map((origin) => origin.trim())
        .where((origin) => origin.isNotEmpty)
        .toSet();
    for (final origin in origins) {
      final uri = Uri.tryParse(origin);
      if (origin == '*' ||
          uri == null ||
          !{'http', 'https'}.contains(uri.scheme) ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty ||
          uri.path.isNotEmpty ||
          uri.hasQuery ||
          uri.hasFragment ||
          (production && uri.scheme != 'https')) {
        throw StateError('CORS_ORIGINS must contain exact valid origins.');
      }
    }

    return AppConfig(
      databaseUrl: databaseUrl,
      port: port,
      host: environment['HOST'] ?? '127.0.0.1',
      registrationEnabled:
          !production && environment['ENABLE_ORGANIZATION_SIGNUP'] == 'true',
      allowedOrigins: origins,
      production: production,
    );
  }
}
