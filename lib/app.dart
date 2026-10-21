import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:structflow/config/app_theme.dart';
import 'package:structflow/core/localization/app_localizations.dart';
import 'package:structflow/core/routing/app_router.dart';
import 'package:structflow/core/settings/app_settings.dart';
import 'package:structflow/features/calendar/repositories/calendar_repository.dart';
import 'package:structflow/features/bim/repositories/bim_workspace_repository.dart';
import 'package:structflow/features/documents/repositories/document_repository.dart';
import 'package:structflow/features/auth/repositories/auth_repository.dart';
import 'package:structflow/features/attendance/models/attendance_permission_model.dart';
import 'package:structflow/features/attendance/repositories/attendance_context_repository.dart';
import 'package:structflow/features/attendance/repositories/attendance_permission_repository.dart';
import 'package:structflow/features/attendance/repositories/project_geofence_repository.dart';
import 'package:structflow/features/attendance/repositories/attendance_repository.dart';
import 'package:structflow/features/projects/repositories/project_repository.dart';
import 'package:structflow/features/tasks/repositories/task_repository.dart';
import 'package:structflow/features/team/repositories/team_repository.dart';

class StructFlowApp extends StatefulWidget {
  const StructFlowApp({super.key});

  @override
  State<StructFlowApp> createState() => _StructFlowAppState();
}

class _StructFlowAppState extends State<StructFlowApp> {
  final AppSettings _settings = AppSettings.instance;
  late final Future<void> _bootstrapFuture;

  @override
  void initState() {
    super.initState();

    _settings.addListener(_settingsChanged);
    AuthRepository.instance.addListener(_settingsChanged);
    _bootstrapFuture = kReleaseMode ? Future<void>.value() : _loadSettings();
  }

  Future<void> _loadSettings() async {
    await Future.wait([_settings.load(), AuthRepository.instance.load()]);

    if (AuthRepository.instance.usesApiAuth) return;

    await Future.wait([
      AttendanceContextRepository.instance.load(),
      AttendancePermissionRepository.instance.load(),
      ProjectGeofenceRepository.instance.load(),
      AttendanceRepository.instance.load(),
      ProjectRepository.instance.loadProjects(),
      TaskRepository.instance.loadTasks(),
      TeamRepository.instance.loadMembers(),
      DocumentRepository.instance.loadDocuments(),
      CalendarRepository.instance.loadEvents(),
      BimWorkspaceRepository.instance.load(),
    ]);

    final user = AuthRepository.instance.currentUser;
    if (user != null && !AuthRepository.instance.usesApiAuth) {
      final organizationId =
          'ORG-${user.organization.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}';
      final existing = AttendancePermissionRepository.instance.getForUser(
        organizationId: organizationId,
        userId: user.id,
      );
      if (existing == null) {
        if (user.isOwner) {
          await AttendancePermissionRepository.instance.seedSuperAdmin(
            AttendancePermissionModel.owner(
              id: 'PERM-${user.id}',
              organizationId: organizationId,
              userId: user.id,
            ),
          );
        } else {
          await AttendancePermissionRepository.instance.ensureUserPermission(
            permission: AttendancePermissionModel(
              id: 'PERM-${user.id}',
              organizationId: organizationId,
              userId: user.id,
              role: user.role,
              locationAttendanceEnabled: true,
              permissions: const [],
              updatedAt: DateTime.now(),
            ),
          );
        }
      }
    }
  }

  void _settingsChanged() {
    if (!mounted) return;

    setState(() {});
  }

  @override
  void dispose() {
    _settings.removeListener(_settingsChanged);
    AuthRepository.instance.removeListener(_settingsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'نسخة الإنتاج غير مفعّلة قبل ربط التطبيق بخادم آمن.',
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Production builds are blocked until authentication and '
                    'company data are connected to the secure backend.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'StructFlow could not load saved data.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        return _buildApp();
      },
    );
  }

  Widget _buildApp() {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,

      title: 'StructFlow',

      // Theme ثابت مؤقتًا على Light.
      // مفيش Dark Theme ولا ThemeMode دلوقتي.
      theme: AppTheme.lightTheme,

      // اللغة الحالية.
      locale: _settings.locale,

      // اللغات المدعومة.
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
        Locale('fr'),
        Locale('zh'),
      ],

      // Flutter built-in localization.
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],

      routerConfig: appRouter,
    );
  }
}
