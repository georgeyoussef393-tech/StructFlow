import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:structflow/core/localization/app_localizations.dart';
import 'package:structflow/core/theme/app_colors.dart';
import 'package:structflow/features/attendance/repositories/attendance_context_repository.dart';
import 'package:structflow/features/attendance/repositories/attendance_permission_repository.dart';
import 'package:structflow/features/auth/repositories/auth_repository.dart';

class DashboardSidebar extends StatefulWidget {
  const DashboardSidebar({super.key});

  @override
  State<DashboardSidebar> createState() => _DashboardSidebarState();
}

class _DashboardSidebarState extends State<DashboardSidebar> {
  final _permissions = AttendancePermissionRepository.instance;

  final _context = AttendanceContextRepository.instance;

  @override
  void initState() {
    super.initState();

    _permissions.addListener(_changed);
    _context.addListener(_changed);
    AuthRepository.instance.addListener(_changed);
  }

  @override
  void dispose() {
    _permissions.removeListener(_changed);
    _context.removeListener(_changed);
    AuthRepository.instance.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    final currentPath = GoRouterState.of(context).uri.path;

    final session = _context.context;
    final currentUser = AuthRepository.instance.currentUser;

    final organizationId = session.organizationId.isNotEmpty
        ? session.organizationId
        : currentUser == null
        ? ''
        : 'ORG-${currentUser.organization.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}';
    final userId = session.userId.isNotEmpty
        ? session.userId
        : currentUser?.id ?? '';

    final permission = _permissions.getForUser(
      organizationId: organizationId,
      userId: userId,
    );

    /*
     * IMPORTANT:
     *
     * When no user has been selected yet, the
     * dashboard remains usable so the existing
     * application can initialize its session.
     *
     * Once a user/organization exists, permissions
     * control the modules.
     */
    final unrestricted = currentUser == null;

    bool can(String key) {
      if (unrestricted) {
        return true;
      }

      return permission?.hasPermission(key) == true;
    }

    final canManageAttendance = unrestricted || permission?.isManager == true;

    return Container(
      width: 250,

      decoration: const BoxDecoration(color: AppColors.primary),

      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),

              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,

                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(12),
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
                padding: const EdgeInsets.symmetric(horizontal: 12),

                child: Column(
                  children: [
                    // ==================================================
                    // DASHBOARD
                    // ==================================================
                    _item(
                      context,
                      Icons.dashboard_rounded,
                      l.dashboard,
                      '/',
                      currentPath,
                    ),

                    // ==================================================
                    // PROJECTS
                    // ==================================================
                    if (can('projects'))
                      _item(
                        context,
                        Icons.apartment_rounded,
                        l.projects,
                        '/projects',
                        currentPath,
                      ),

                    if (can('bim'))
                      _item(
                        context,
                        Icons.view_in_ar_rounded,
                        'BIM Coordination',
                        '/bim',
                        currentPath,
                      ),

                    // ==================================================
                    // TASKS
                    // ==================================================
                    if (can('tasks'))
                      _item(
                        context,
                        Icons.task_alt_rounded,
                        l.tasks,
                        '/tasks',
                        currentPath,
                      ),

                    // ==================================================
                    // TEAM
                    // ==================================================
                    if (can('team'))
                      _item(
                        context,
                        Icons.groups_rounded,
                        l.team,
                        '/team',
                        currentPath,
                      ),

                    // ==================================================
                    // CALENDAR
                    // ==================================================
                    if (can('calendar'))
                      _item(
                        context,
                        Icons.calendar_month_rounded,
                        l.calendar,
                        '/calendar',
                        currentPath,
                      ),

                    // ==================================================
                    // DOCUMENTS
                    // ==================================================
                    if (can('documents'))
                      _item(
                        context,
                        Icons.description_rounded,
                        l.documents,
                        '/documents',
                        currentPath,
                      ),

                    // ==================================================
                    // ATTENDANCE
                    //
                    // Always visible.
                    // ==================================================
                    _item(
                      context,
                      Icons.location_on_rounded,
                      l.attendance,
                      '/attendance',
                      currentPath,
                    ),

                    // ==================================================
                    // ATTENDANCE MANAGEMENT
                    // Managers only.
                    // ==================================================
                    if (canManageAttendance)
                      _item(
                        context,
                        Icons.manage_accounts_rounded,
                        l.attendanceManagement,
                        '/attendance-management',
                        currentPath,
                      ),

                    if (currentUser != null &&
                        (currentUser.isOwner ||
                            currentUser.role == 'Consultant Manager' ||
                            currentUser.role == 'Owner HR Manager' ||
                            currentUser.role == 'Consultant HR Manager'))
                      _item(
                        context,
                        Icons.manage_accounts_rounded,
                        'User Management',
                        '/user-management',
                        currentPath,
                      ),

                    const SizedBox(height: 15),

                    Divider(color: Colors.white.withValues(alpha: .15)),

                    const SizedBox(height: 15),

                    // ==================================================
                    // REPORTS
                    // ==================================================
                    if (can('reports'))
                      _item(
                        context,
                        Icons.bar_chart_rounded,
                        l.reports,
                        '/reports',
                        currentPath,
                      ),

                    // ==================================================
                    // AI
                    // ==================================================
                    _item(
                      context,
                      Icons.auto_awesome_rounded,
                      l.aiAssistant,
                      '/ai-assistant',
                      currentPath,
                    ),

                    // ==================================================
                    // SETTINGS
                    // ==================================================
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
              padding: const EdgeInsets.only(bottom: 16),

              child: Text(
                'StructFlow • v1.0',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .45),
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
    final selected =
        currentPath == route ||
        (route == '/projects' && currentPath.startsWith('/projects/')) ||
        (route == '/bim' && currentPath.startsWith('/bim')) ||
        (route == '/tasks' && currentPath.startsWith('/tasks/')) ||
        (route == '/documents' && currentPath.startsWith('/documents/')) ||
        (route == '/attendance' && currentPath.startsWith('/attendance'));

    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 6),

      decoration: BoxDecoration(
        color: selected
            ? Colors.white.withValues(alpha: .15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),

      child: Material(
        color: Colors.transparent,

        borderRadius: BorderRadius.circular(12),

        clipBehavior: Clip.antiAlias,

        child: ListTile(
          dense: true,

          leading: Icon(icon, color: Colors.white, size: 21),

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
