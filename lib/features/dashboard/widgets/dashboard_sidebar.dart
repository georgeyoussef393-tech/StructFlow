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
              const SizedBox(height: 28),

              const Text(
                'StructFlow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 28),

              Expanded(
                child: SingleChildScrollView(
                  physics:
                      const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
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
            ],
          ),
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
    final selected = currentPath == route;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: selected
            ? Colors.white.withOpacity(.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
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
          context.go(route);
        },

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}