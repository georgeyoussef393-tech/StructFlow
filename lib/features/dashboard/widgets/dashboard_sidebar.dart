import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:structflow/core/theme/app_colors.dart';

class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentPath =
        GoRouterState.of(context).uri.path;

    return Material(
      color: AppColors.primary,

      child: SizedBox(
        width: 260,
        height: double.infinity,

        child: SafeArea(
          child: Column(
            children: [
              // ========================================================
              // LOGO
              // ========================================================

              const SizedBox(height: 28),

              const Text(
                'StructFlow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: .3,
                ),
              ),

              const SizedBox(height: 28),

              // ========================================================
              // MENU
              // ========================================================

              Expanded(
                child: SingleChildScrollView(
                  physics:
                      const BouncingScrollPhysics(),

                  padding:
                      const EdgeInsets.fromLTRB(
                    12,
                    0,
                    12,
                    24,
                  ),

                  child: Column(
                    children: [
                      _item(
                        context,
                        Icons.dashboard_rounded,
                        'Dashboard',
                        '/',
                        currentPath,
                      ),

                      _item(
                        context,
                        Icons.folder_rounded,
                        'Projects',
                        '/projects',
                        currentPath,
                      ),

                      _item(
                        context,
                        Icons.task_alt_rounded,
                        'Tasks',
                        '/tasks',
                        currentPath,
                      ),

                      _item(
                        context,
                        Icons.people_alt_rounded,
                        'Team',
                        '/team',
                        currentPath,
                      ),

                      _item(
                        context,
                        Icons.calendar_month_rounded,
                        'Calendar',
                        '/calendar',
                        currentPath,
                      ),

                      _item(
                        context,
                        Icons.description_rounded,
                        'Documents',
                        '/documents',
                        currentPath,
                      ),

                      _item(
                        context,
                        Icons.bar_chart_rounded,
                        'Reports',
                        '/reports',
                        currentPath,
                      ),

                      _item(
                        context,
                        Icons.smart_toy_rounded,
                        'AI Assistant',
                        '/ai-assistant',
                        currentPath,
                      ),

                      const SizedBox(height: 12),

                      Divider(
                        color:
                            Colors.white.withOpacity(.15),
                        height: 1,
                      ),

                      const SizedBox(height: 12),

                      _item(
                        context,
                        Icons.settings_rounded,
                        'Settings',
                        '/settings',
                        currentPath,
                      ),
                    ],
                  ),
                ),
              ),

              // ========================================================
              // VERSION
              // ========================================================

              Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 16,
                ),

                child: Text(
                  'StructFlow • v1.0',
                  style: TextStyle(
                    color:
                        Colors.white.withOpacity(.45),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // SIDEBAR ITEM
  // ================================================================

  Widget _item(
    BuildContext context,
    IconData icon,
    String title,
    String route,
    String currentPath,
  ) {
    // ================================================================
    // PROJECTS SHOULD STAY SELECTED INSIDE PROJECT DETAILS
    // ================================================================

    final isProjectsRoute =
        route == '/projects' &&
        currentPath.startsWith('/projects/');

    final selected =
        currentPath == route ||
        isProjectsRoute;

    return Container(
      width: double.infinity,

      margin:
          const EdgeInsets.only(bottom: 6),

      decoration: BoxDecoration(
        color: selected
            ? Colors.white.withOpacity(.15)
            : Colors.transparent,

        borderRadius:
            BorderRadius.circular(12),
      ),

      child: ListTile(
        dense: true,

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 2,
        ),

        leading: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),

        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,

            fontWeight: selected
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),

        onTap: () {
          // ==========================================================
          // NAVIGATION
          // ==========================================================

          context.go(route);

          // ==========================================================
          // CLOSE DRAWER ON MOBILE / TABLET
          // ==========================================================

          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
      ),
    );
  }
}