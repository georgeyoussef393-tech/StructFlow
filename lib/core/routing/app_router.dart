import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:structflow/features/dashboard/screens/dashboard_screen.dart';

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

final GoRouter appRouter = GoRouter(
  initialLocation: '/',

  routes: [
    // ============================================================
    // DASHBOARD
    // ============================================================

    GoRoute(
      path: '/',
      builder: (context, state) {
        return const DashboardScreen();
      },
    ),

    // ============================================================
    // PROJECTS
    // ============================================================

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

    // ============================================================
    // CREATE PROJECT
    // ============================================================

    GoRoute(
      path: '/create-project',
      builder: (context, state) {
        return const CreateProjectScreen();
      },
    ),

    // ============================================================
    // TASKS
    // ============================================================

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

    // ============================================================
    // CREATE TASK
    // ============================================================

    GoRoute(
      path: '/create-task',
      builder: (context, state) {
        return CreateTaskScreen(
          initialProjectCode:
              state.uri.queryParameters['projectCode'],
        );
      },
    ),

    // ============================================================
    // TEAM
    // ============================================================

    GoRoute(
      path: '/team',
      builder: (context, state) {
        return const TeamScreen();
      },
    ),

    // ============================================================
    // CALENDAR
    // ============================================================

    GoRoute(
      path: '/calendar',
      builder: (context, state) {
        return const CalendarScreen();
      },
    ),

    // ============================================================
    // DOCUMENTS
    // ============================================================

    GoRoute(
      path: '/documents',
      builder: (context, state) {
        return const DocumentsScreen();
      },
    ),

    // ============================================================
    // CREATE / EDIT DOCUMENT
    // ============================================================

    GoRoute(
      path: '/create-document',
      builder: (context, state) {
        return CreateDocumentScreen(
          documentId:
              state.uri.queryParameters['documentId'],
        );
      },
    ),

    // ============================================================
    // ATTENDANCE
    // ============================================================

    GoRoute(
      path: '/attendance',
      builder: (context, state) => const AttendanceScreen(),
    ),

    GoRoute(
      path: '/attendance-management',
      builder: (context, state) => const AttendanceManagementScreen(),
    ),

    // ============================================================
    // REPORTS
    // ============================================================

    GoRoute(
      path: '/reports',
      builder: (context, state) {
        return const _ComingSoonScreen(
          title: 'Reports',
          icon: Icons.bar_chart_rounded,
        );
      },
    ),

    // ============================================================
    // AI ASSISTANT
    // ============================================================

    GoRoute(
      path: '/ai-assistant',
      builder: (context, state) {
        return const _ComingSoonScreen(
          title: 'AI Assistant',
          icon: Icons.smart_toy_rounded,
        );
      },
    ),

    // ============================================================
    // SETTINGS
    // ============================================================

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
// COMING SOON
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
        backgroundColor: Colors.white,
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

              const SizedBox(height: 20),

              Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'This module is under development.',
                style:
                    TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 25),

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
