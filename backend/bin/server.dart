import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:structflow_api/src/api.dart';
import 'package:structflow_api/src/config.dart';
import 'package:structflow_api/src/database.dart';
import 'package:structflow_api/src/security.dart';

Future<void> main() async {
  final config = AppConfig.fromEnvironment(Platform.environment);
  await PasswordSecurity.initialize();
  final database = AppDatabase(config.databaseUrl);
  await database.verifyConnection();

  final server = await shelf_io.serve(
    StructFlowApi(config: config, database: database).handler,
    config.host,
    config.port,
    poweredByHeader: null,
  );
  stdout.writeln(
    'StructFlow API listening on ${server.address.address}:${server.port}',
  );

  final shutdown = Completer<void>();
  final signalSubscriptions = <StreamSubscription<ProcessSignal>>[
    ProcessSignal.sigint.watch().listen((_) {
      if (!shutdown.isCompleted) shutdown.complete();
    }),
    if (!Platform.isWindows)
      ProcessSignal.sigterm.watch().listen((_) {
        if (!shutdown.isCompleted) shutdown.complete();
      }),
  ];
  await shutdown.future;
  for (final subscription in signalSubscriptions) {
    await subscription.cancel();
  }
  await server.close();
  await database.pool.close();
}
