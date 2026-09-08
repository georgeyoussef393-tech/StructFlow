import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:structflow/core/localization/app_localizations.dart';
import 'package:structflow/core/theme/app_colors.dart';

class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    final currentPath =
        GoRouterState.of(context).uri.path;

    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AppColors.primary,
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withValues(alpha: .14),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_tree_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 12),

                  const Expanded(
                    child: Text(
                      'StructFlow',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                child: Column(
                  children: [
                    _item(
                      context,
                      Icons.dashboard_rounded,
                      l.dashboard,
                      '/',
                      currentPath,
                    ),

                    _item(
                      context,
                      Icons.apartment_rounded,
                      l.projects,
                      '/projects',
                      currentPath,
                    ),

                    _item(
                      context,
                      Icons.task_alt_rounded,
                      l.tasks,
                      '/tasks',
                      currentPath,
                    ),

                    _item(
                      context,
                      Icons.groups_rounded,
                      l.team,
                      '/team',
                      currentPath,
                    ),

                    _item(
                      context,
                      Icons.calendar_month_rounded,
                      l.calendar,
                      '/calendar',
                      currentPath,
                    ),

                    _item(
                      context,
                      Icons.description_rounded,
                      l.documents,
                      '/documents',
                      currentPath,
                    ),

                    _item(
                      context,
                      Icons.location_on_rounded,
                      l.attendance,
                      '/attendance',
                      currentPath,
                    ),

                    _item(
                      context,
                      Icons.manage_accounts_rounded,
                      l.attendanceManagement,
                      '/attendance-management',
                      currentPath,
                    ),

                    const SizedBox(height: 15),

                    Divider(
                      color: Colors.white
                          .withValues(alpha: .15),
                    ),

                    const SizedBox(height: 15),

                    _item(
                      context,
                      Icons.bar_chart_rounded,
                      l.reports,
                      '/reports',
                      currentPath,
                    ),

                    _item(
                      context,
                      Icons.auto_awesome_rounded,
                      l.aiAssistant,
                      '/ai-assistant',
                      currentPath,
                    ),

                    _item(
                      context,
                      Icons.settings_rounded,
                      l.settings,
                      '/settings',
                      currentPath,
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 16,
              ),
              child: Text(
                'StructFlow • v1.0',
                style: TextStyle(
                  color: Colors.white
                      .withValues(alpha: .45),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String title,
    String route,
    String currentPath,
  ) {
    final isProjectsRoute =
        route == '/projects' &&
        currentPath.startsWith('/projects/');

    final isTasksRoute =
        route == '/tasks' &&
        currentPath.startsWith('/tasks/');

    final selected =
        currentPath == route ||
        isProjectsRoute ||
        isTasksRoute;

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: selected
            ? Colors.white.withValues(
                alpha: .15,
              )
            : Colors.transparent,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius:
            BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          dense: true,
          leading: Icon(
            icon,
            color: Colors.white,
            size: 21,
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () {
            context.go(route);
          },
        ),
      ),
    );
  }
}