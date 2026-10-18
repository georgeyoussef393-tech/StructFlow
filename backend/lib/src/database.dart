import 'package:postgres/postgres.dart';

class AppDatabase {
  AppDatabase(String connectionString)
    : pool = Pool.withUrl(_configuredUrl(connectionString));

  final Pool pool;

  static String _configuredUrl(String connectionString) {
    final uri = Uri.parse(connectionString);
    return uri
        .replace(
          queryParameters: {
            ...uri.queryParameters,
            'application_name': 'structflow-api',
            'max_connection_count': '20',
            'connect_timeout': '10',
            'query_timeout': '30',
          },
        )
        .toString();
  }

  Future<void> verifyConnection() async {
    await pool.execute('SELECT 1');
  }
}
