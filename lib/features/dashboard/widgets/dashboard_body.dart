import 'package:flutter/material.dart';
import 'package:structflow/core/localization/app_localizations.dart';
import 'package:structflow/core/theme/app_colors.dart';

class DashboardBody extends StatelessWidget {
  const DashboardBody({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(context, l),
          const SizedBox(height: 24),
          _buildStatsGrid(context, l),
          const SizedBox(height: 24),
          _buildMainGrid(context, l),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(
    BuildContext context,
    AppLocalizations l,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.dashboard,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome to StructFlow',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.dashboard_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    AppLocalizations l,
  ) {
    final stats = [
      _StatItem(
        title: l.activeProjects,
        value: '12',
        icon: Icons.business_center_rounded,
        color: AppColors.primary,
      ),
      _StatItem(
        title: l.upcomingTasks,
        value: '28',
        icon: Icons.task_alt_rounded,
        color: AppColors.warning,
      ),
      _StatItem(
        title: l.team,
        value: '46',
        icon: Icons.groups_rounded,
        color: AppColors.success,
      ),
      _StatItem(
        title: l.documents,
        value: '184',
        icon: Icons.folder_rounded,
        color: AppColors.secondary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int columns;

        if (width >= 1200) {
          columns = 4;
        } else if (width >= 700) {
          columns = 2;
        } else {
          columns = 1;
        }

        const spacing = 16.0;

        final itemWidth =
            (width - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: stats
              .map(
                (stat) => SizedBox(
                  width: itemWidth,
                  child: _buildStatCard(context, stat),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    _StatItem stat,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              stat.icon,
              color: stat.color,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat.value,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainGrid(
    BuildContext context,
    AppLocalizations l,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildProjectsCard(context, l),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: _buildTasksCard(context, l),
              ),
            ],
          );
        }

        return Column(
          children: [
            _buildProjectsCard(context, l),
            const SizedBox(height: 20),
            _buildTasksCard(context, l),
          ],
        );
      },
    );
  }

  Widget _buildProjectsCard(
    BuildContext context,
    AppLocalizations l,
  ) {
    final projects = [
      _ProjectItem(
        name: 'Tuban Villas',
        location: 'New Cairo',
        progress: 0.78,
      ),
      _ProjectItem(
        name: 'Capital Site',
        location: 'New Capital',
        progress: 0.54,
      ),
      _ProjectItem(
        name: 'Sokhna Site',
        location: 'Ain Sokhna',
        progress: 0.32,
      ),
    ];

    return _DashboardCard(
      title: l.projects,
      icon: Icons.business_center_rounded,
      child: Column(
        children: projects
            .map(
              (project) => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: _buildProjectRow(
                  context,
                  project,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildProjectRow(
    BuildContext context,
    _ProjectItem project,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.apartment_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    project.location,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${(project.progress * 100).round()}%',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: project.progress,
            minHeight: 7,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTasksCard(
    BuildContext context,
    AppLocalizations l,
  ) {
    final tasks = [
      _TaskItem(
        title: 'Review structural drawings',
        project: 'Tuban Villas',
        icon: Icons.architecture_rounded,
        color: AppColors.primary,
      ),
      _TaskItem(
        title: 'BOQ approval',
        project: 'Capital Site',
        icon: Icons.receipt_long_rounded,
        color: AppColors.warning,
      ),
      _TaskItem(
        title: 'Site inspection',
        project: 'Sokhna Site',
        icon: Icons.location_on_rounded,
        color: AppColors.success,
      ),
    ];

    return _DashboardCard(
      title: l.upcomingTasks,
      icon: Icons.task_alt_rounded,
      child: Column(
        children: tasks
            .map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildTaskRow(
                  context,
                  task,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTaskRow(
    BuildContext context,
    _TaskItem task,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: task.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              task.icon,
              color: task.color,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.project,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textLight,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _StatItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _ProjectItem {
  final String name;
  final String location;
  final double progress;

  const _ProjectItem({
    required this.name,
    required this.location,
    required this.progress,
  });
}

class _TaskItem {
  final String title;
  final String project;
  final IconData icon;
  final Color color;

  const _TaskItem({
    required this.title,
    required this.project,
    required this.icon,
    required this.color,
  });
}