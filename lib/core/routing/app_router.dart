import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:structflow/features/dashboard/screens/dashboard_screen.dart';
import 'package:structflow/features/auth/repositories/auth_repository.dart';
import 'package:structflow/features/auth/screens/login_screen.dart';
import 'package:structflow/features/auth/screens/register_screen.dart';
import 'package:structflow/features/admin/screens/user_management_screen.dart';
import 'package:structflow/features/auth/screens/owner_setup_screen.dart';

import 'package:structflow/features/projects/screens/projects_screen.dart';
import 'package:structflow/features/projects/screens/project_details_screen.dart';
import 'package:structflow/features/projects/screens/create_project_screen.dart';

import 'package:structflow/features/tasks/screens/tasks_screen.dart';
import 'package:structflow/features/tasks/screens/create_task_screen.dart';
import 'package:structflow/features/tasks/screens/task_details_screen.dart';

import 'package:structflow/features/team/screens/team_screen.dart';

import 'package:structflow/features/calendar/screens/calendar_screen.dart';

import 'package:structflow/features/documents/screens/documents_screen.dart';
import 'package:structflow/features/documents/screens/create_document_screen.dart';

import 'package:structflow/features/attendance/screens/attendance_screen.dart';
import 'package:structflow/features/attendance/screens/attendance_management_screen.dart';

import 'package:structflow/features/attendance/repositories/attendance_context_repository.dart';
import 'package:structflow/features/attendance/repositories/attendance_permission_repository.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',

  refreshListenable: Listenable.merge([
    AuthRepository.instance,
    AttendancePermissionRepository.instance,
    AttendanceContextRepository.instance,
  ]),

  redirect: (context, state) {
    final authenticated = AuthRepository.instance.isAuthenticated;
    final path = state.uri.path;

    if (!authenticated) {
      if (path == '/login' || path == '/register' || path == '/owner-setup') return null;
      return '/login';
    }

    if (path == '/login' || path == '/register') return '/';
    if (path == '/owner-setup') {
      return AuthRepository.instance.hasOwner ? '/login' : null;
    }

    // User Management is governed by the authenticated account role,
    // so it must remain reachable even when an old attendance session
    // has not yet been synchronized.
    if (path == '/user-management') {
      final user = AuthRepository.instance.currentUser;
      final allowed = user?.isSystemOwner == true ||
          user?.isOwner == true ||
          user?.role == 'Consultant Manager' ||
          user?.role == 'Owner HR Manager' ||
          user?.role == 'Consultant HR Manager';
      return allowed ? null : '/';
    }

    final session =
        AttendanceContextRepository.instance.context;

    // ==========================================================
    // NO CURRENT USER
    // ==========================================================

    // Keep the existing demo unrestricted until a user/session
    // has been selected.
    if (session.organizationId.isEmpty ||
        session.userId.isEmpty) {
      return null;
    }

    final permission =
        AttendancePermissionRepository.instance.getForUser(
      organizationId:
          session.organizationId,
      userId:
          session.userId,
    );

    // ==========================================================
    // USER HAS NO PERMISSION RECORD
    // ==========================================================

    if (permission == null) {
      if (state.uri.path == '/' ||
          state.uri.path == '/attendance') {
        return null;
      }

      return '/attendance';
    }

    // ==========================================================
    // DASHBOARD
    // ==========================================================

    if (path == '/') {
      return null;
    }

    // ==========================================================
    // ATTENDANCE
    // ==========================================================

    // Every employee/user can access Attendance.
    if (path == '/attendance') {
      return null;
    }

    // ==========================================================
    // ATTENDANCE MANAGEMENT
    // ==========================================================

    if (path == '/attendance-management') {
      return permission.isManager
          ? null
          : '/attendance';
    }

    // ==========================================================
    // PROJECTS
    // ==========================================================

    if (path == '/projects') {
      return permission.canAccessProjects
          ? null
          : '/attendance';
    }

    if (path.startsWith('/projects/')) {
      if (!permission.canAccessProjects) {
        return '/attendance';
      }

      final parts = path.split('/');

      if (parts.length > 2) {
        final projectId = parts[2];

        if (projectId.isNotEmpty &&
            !permission.canAccessProject(projectId)) {
          return '/projects';
        }
      }

      return null;
    }

    // ==========================================================
    // CREATE PROJECT
    // ==========================================================

    if (path == '/create-project') {
      return permission.canAccessProjects
          ? null
          : '/attendance';
    }

    // ==========================================================
    // TASKS
    // ==========================================================

    if (path == '/tasks' ||
        path.startsWith('/tasks/')) {
      return permission.canAccessTasks
          ? null
          : '/attendance';
    }

    if (path == '/create-task') {
      return permission.canAccessTasks
          ? null
          : '/attendance';
    }

    // ==========================================================
    // TEAM
    // ==========================================================

    if (path == '/team') {
      return permission.canAccessTeam
          ? null
          : '/attendance';
    }

    // ==========================================================
    // CALENDAR
    // ==========================================================

    if (path == '/calendar') {
      return permission.canAccessCalendar
          ? null
          : '/attendance';
    }

    // ==========================================================
    // DOCUMENTS
    // ==========================================================

    if (path == '/documents' ||
        path.startsWith('/documents/')) {
      return permission.canAccessDocuments
          ? null
          : '/attendance';
    }

    if (path == '/create-document') {
      return permission.canAccessDocuments
          ? null
          : '/attendance';
    }

    // ==========================================================
    // REPORTS
    // ==========================================================

    if (path == '/reports') {
      return permission.canAccessReports
          ? null
          : '/attendance';
    }

    // ==========================================================
    // AI ASSISTANT
    // ==========================================================

    if (path == '/ai-assistant') {
      return null;
    }

    // ==========================================================
    // SETTINGS
    // ==========================================================

    if (path == '/settings') {
      return null;
    }

    return null;
  },

  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/owner-setup',
      builder: (context, state) => const OwnerSetupScreen(),
    ),

    // ==========================================================
    // DASHBOARD
    // ==========================================================

    GoRoute(
      path: '/',
      builder: (context, state) {
        return const DashboardScreen();
      },
    ),

    // ==========================================================
    // PROJECTS
    // ==========================================================

    GoRoute(
      path: '/projects',
      builder: (context, state) {
        return const ProjectsScreen();
      },
      routes: [
        GoRoute(
          path: ':projectId',
          builder: (context, state) {
            final projectId =
                state.pathParameters['projectId'] ??
                'PRJ-001';

            return ProjectDetailsScreen(
              projectId: projectId,
            );
          },
        ),
      ],
    ),

    // ==========================================================
    // CREATE PROJECT
    // ==========================================================

    GoRoute(
      path: '/create-project',
      builder: (context, state) {
        return const CreateProjectScreen();
      },
    ),

    // ==========================================================
    // TASKS
    // ==========================================================

    GoRoute(
      path: '/tasks',
      builder: (context, state) {
        return const TasksScreen();
      },
      routes: [
        GoRoute(
          path: ':taskId',
          builder: (context, state) {
            final taskId =
                state.pathParameters['taskId'] ??
                '';

            return TaskDetailsScreen(
              taskId: taskId,
            );
          },
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) {
                final taskId =
                    state.pathParameters['taskId'] ??
                    '';

                return CreateTaskScreen(
                  taskId: taskId,
                );
              },
            ),
          ],
        ),
      ],
    ),

    // ==========================================================
    // CREATE TASK
    // ==========================================================

    GoRoute(
      path: '/create-task',
      builder: (context, state) {
        return CreateTaskScreen(
          initialProjectCode:
              state.uri.queryParameters['projectCode'],
        );
      },
    ),

    // ==========================================================
    // TEAM
    // ==========================================================

    GoRoute(
      path: '/team',
      builder: (context, state) {
        return const TeamScreen();
      },
    ),

    // ==========================================================
    // CALENDAR
    // ==========================================================

    GoRoute(
      path: '/calendar',
      builder: (context, state) {
        return const CalendarScreen();
      },
    ),

    // ==========================================================
    // DOCUMENTS
    // ==========================================================

    GoRoute(
      path: '/documents',
      builder: (context, state) {
        return const DocumentsScreen();
      },
    ),

    // ==========================================================
    // CREATE / EDIT DOCUMENT
    // ==========================================================

    GoRoute(
      path: '/create-document',
      builder: (context, state) {
        return CreateDocumentScreen(
          documentId:
              state.uri.queryParameters['documentId'],
        );
      },
    ),

    // ==========================================================
    // ATTENDANCE
    // ==========================================================

    GoRoute(
      path: '/attendance',
      builder: (context, state) {
        return const AttendanceScreen();
      },
    ),

    // ==========================================================
    // ATTENDANCE MANAGEMENT
    // ==========================================================

    GoRoute(
      path: '/attendance-management',
      builder: (context, state) {
        return const AttendanceManagementScreen();
      },
    ),

    GoRoute(
      path: '/user-management',
      builder: (context, state) => const UserManagementScreen(),
    ),

    // ==========================================================
    // REPORTS
    // ==========================================================

    GoRoute(
      path: '/reports',
      builder: (context, state) {
        return const _ComingSoonScreen(
          title: 'Reports',
          icon: Icons.bar_chart_rounded,
        );
      },
    ),

    // ==========================================================
    // AI ASSISTANT
    // ==========================================================

    GoRoute(
      path: '/ai-assistant',
      builder: (context, state) {
        return const _ComingSoonScreen(
          title: 'AI Assistant',
          icon: Icons.smart_toy_rounded,
        );
      },
    ),

    // ==========================================================
    // SETTINGS
    // ==========================================================

    GoRoute(
      path: '/settings',
      builder: (context, state) {
        return const _ComingSoonScreen(
          title: 'Settings',
          icon: Icons.settings_rounded,
        );
      },
    ),
  ],
);

// ============================================================================
// COMING SOON SCREEN
// ============================================================================

class _ComingSoonScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const _ComingSoonScreen({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF5F7FB),

      appBar: AppBar(
        title: Text(title),
        backgroundColor:
            Colors.white,
        foregroundColor:
            const Color(0xff1F2937),
        elevation: 0,
      ),

      body: Center(
        child: Container(
          padding:
              const EdgeInsets.all(40),

          margin:
              const EdgeInsets.all(24),

          decoration:
              BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(24),
          ),

          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              Icon(
                icon,
                size: 60,
                color:
                    const Color(0xff0B3D91),
              ),

              const SizedBox(
                height: 20,
              ),

              Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              const Text(
                'This module is under development.',
                style:
                    TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              ElevatedButton.icon(
                onPressed: () {
                  context.go('/');
                },

                icon: const Icon(
                  Icons.dashboard_rounded,
                ),

                label: const Text(
                  'Back to Dashboard',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}