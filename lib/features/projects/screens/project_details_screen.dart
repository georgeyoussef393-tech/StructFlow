import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:structflow/core/theme/app_colors.dart';
import 'package:structflow/features/projects/models/project_model.dart';
import 'package:structflow/features/projects/repositories/project_repository.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailsScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<ProjectDetailsScreen> createState() =>
      _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState
    extends State<ProjectDetailsScreen> {
  final ProjectRepository _repository =
      ProjectRepository.instance;

  @override
  void initState() {
    super.initState();
    _repository.addListener(_onProjectChanged);
  }

  @override
  void dispose() {
    _repository.removeListener(_onProjectChanged);
    super.dispose();
  }

  void _onProjectChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // ================================================================
  // PROJECT
  // ================================================================

  ProjectModel? get _project {
    return _repository.getProjectByCode(
      widget.projectId,
    );
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final project = _project;

    if (project == null) {
      return _buildProjectNotFound();
    }

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            return SingleChildScrollView(
              padding: EdgeInsets.all(
                width < 600 ? 16 : 28,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildHeader(
                    project,
                    width,
                  ),

                  const SizedBox(height: 24),

                  _buildOverviewCard(
                    project,
                    width,
                  ),

                  const SizedBox(height: 20),

                  _buildMainContent(
                    project,
                    width,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ================================================================
  // HEADER
  // ================================================================

  Widget _buildHeader(
    ProjectModel project,
    double width,
  ) {
    final isMobile = width < 700;

    if (isMobile) {
      return Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () {
              context.go('/projects');
            },
            icon: const Icon(
              Icons.arrow_back_rounded,
            ),
            label: const Text(
              'Back to Projects',
            ),
            style: TextButton.styleFrom(
              foregroundColor:
                  AppColors.primary,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 4,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildProjectIcon(project),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style:
                          const TextStyle(
                        fontSize: 25,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            AppColors.textDark,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      project.code,
                      style:
                          const TextStyle(
                        fontSize: 13,
                        color:
                            AppColors.textLight,
                      ),
                    ),

                    const SizedBox(height: 10),

                    _buildStatusBadge(
                      project.status,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () {
            context.go('/projects');
          },
          tooltip: 'Back to Projects',
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),

        const SizedBox(width: 8),

        _buildProjectIcon(project),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                project.name,
                style:
                    const TextStyle(
                  fontSize: 30,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      AppColors.textDark,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                project.code,
                style:
                    const TextStyle(
                  fontSize: 14,
                  color:
                      AppColors.textLight,
                ),
              ),
            ],
          ),
        ),

        _buildStatusBadge(
          project.status,
        ),
      ],
    );
  }

  // ================================================================
  // PROJECT ICON
  // ================================================================

  Widget _buildProjectIcon(
    ProjectModel project,
  ) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: project.color.withValues(
          alpha: .10,
        ),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Icon(
        project.icon,
        color: project.color,
        size: 29,
      ),
    );
  }

  // ================================================================
  // OVERVIEW
  // ================================================================

  Widget _buildOverviewCard(
    ProjectModel project,
    double width,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        width < 600 ? 18 : 24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Project Overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        AppColors.textDark,
                  ),
                ),
              ),

              Text(
                '${(project.progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      project.color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child:
                    LinearProgressIndicator(
                  value:
                      project.progress,
                  minHeight: 10,
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                  backgroundColor:
                      project.color.withValues(
                    alpha: .10,
                  ),
                  valueColor:
                      AlwaysStoppedAnimation<
                          Color>(
                    project.color,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            _progressLabel(
              project.progress,
            ),
            style:
                const TextStyle(
              fontSize: 12,
              color:
                  AppColors.textLight,
            ),
          ),

          const SizedBox(height: 24),

          _buildOverviewGrid(
            project,
            width,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewGrid(
    ProjectModel project,
    double width,
  ) {
    final columns = width >= 1100
        ? 4
        : width >= 700
            ? 2
            : 1;

    final items = [
      _OverviewItem(
        title: 'Client',
        value: project.client,
        icon:
            Icons.person_outline_rounded,
      ),
      _OverviewItem(
        title: 'Location',
        value: project.location,
        icon:
            Icons.location_on_outlined,
      ),
      _OverviewItem(
        title: 'Budget',
        value: project.budget,
        icon:
            Icons.account_balance_wallet_outlined,
      ),
      _OverviewItem(
        title: 'Team Members',
        value: '${project.team}',
        icon:
            Icons.people_outline_rounded,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 100,
      ),
      itemBuilder: (context, index) {
        return _buildOverviewItem(
          items[index],
        );
      },
    );
  }

  Widget _buildOverviewItem(
    _OverviewItem item,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            const Color(0xffF8FAFC),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
                  AppColors.primary.withValues(
                alpha: .08,
              ),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              item.icon,
              size: 21,
              color:
                  AppColors.primary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style:
                      const TextStyle(
                    fontSize: 11,
                    color:
                        AppColors.textLight,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  item.value,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // MAIN CONTENT
  // ================================================================

  Widget _buildMainContent(
    ProjectModel project,
    double width,
  ) {
    final isMobile = width < 900;

    if (isMobile) {
      return Column(
        children: [
          _buildProjectInformation(
            project,
          ),

          const SizedBox(height: 20),

          _buildQuickActions(),
        ],
      );
    }

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child:
              _buildProjectInformation(
            project,
          ),
        ),

        const SizedBox(width: 20),

        Expanded(
          child:
              _buildQuickActions(),
        ),
      ],
    );
  }

  // ================================================================
  // PROJECT INFORMATION
  // ================================================================

  Widget _buildProjectInformation(
    ProjectModel project,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Project Information',
            style: TextStyle(
              fontSize: 19,
              fontWeight:
                  FontWeight.bold,
              color:
                  AppColors.textDark,
            ),
          ),

          const SizedBox(height: 20),

          _detailRow(
            'Project Name',
            project.name,
          ),

          _detailRow(
            'Project Code',
            project.code,
          ),

          _detailRow(
            'Client',
            project.client,
          ),

          _detailRow(
            'Location',
            project.location,
          ),

          _detailRow(
            'Status',
            project.status,
          ),

          _detailRow(
            'Budget',
            project.budget,
          ),

          _detailRow(
            'Team Size',
            '${project.team} members',
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    String title,
    String value,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 13,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color:
                Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              title,
              style:
                  const TextStyle(
                fontSize: 12,
                color:
                    AppColors.textLight,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w600,
                color:
                    AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // QUICK ACTIONS
  // ================================================================

  Widget _buildQuickActions() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 19,
              fontWeight:
                  FontWeight.bold,
              color:
                  AppColors.textDark,
            ),
          ),

          const SizedBox(height: 18),

          _actionButton(
            icon:
                Icons.task_alt_rounded,
            title: 'Project Tasks',
            subtitle:
                'View and manage project tasks',
            onPressed: () {
              final project =
                  _project;

              if (project == null) {
                return;
              }

              context.push(
                '/tasks?projectCode=${Uri.encodeComponent(project.code)}',
              );
            },
          ),

          const SizedBox(height: 10),

          _actionButton(
            icon:
                Icons.description_outlined,
            title: 'Project Documents',
            subtitle:
                'View project documents',
            onPressed: () {
              context.go('/documents');
            },
          ),

          const SizedBox(height: 10),

          _actionButton(
            icon:
                Icons.people_outline_rounded,
            title: 'Project Team',
            subtitle:
                'View team members',
            onPressed: () {
              context.go('/team');
            },
          ),

          const SizedBox(height: 10),

          _actionButton(
            icon:
                Icons.calendar_month_outlined,
            title: 'Project Calendar',
            subtitle:
                'View project schedule',
            onPressed: () {
              context.go('/calendar');
            },
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
  }) {
    return Material(
      color:
          const Color(0xffF8FAFC),
      borderRadius:
          BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius:
            BorderRadius.circular(14),
        child: Padding(
          padding:
              const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration:
                    BoxDecoration(
                  color:
                      AppColors.primary
                          .withValues(
                    alpha: .08,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  icon,
                  color:
                      AppColors.primary,
                  size: 21,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            AppColors.textDark,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 11,
                        color:
                            AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons
                    .arrow_forward_ios_rounded,
                size: 13,
                color:
                    AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // STATUS
  // ================================================================

  Widget _buildStatusBadge(
    String status,
  ) {
    final color =
        _statusColor(status);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: .10,
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  Color _statusColor(
    String status,
  ) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Planning':
        return Colors.orange;
      case 'On Hold':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ================================================================
  // PROGRESS LABEL
  // ================================================================

  String _progressLabel(
    double progress,
  ) {
    if (progress >= .90) {
      return 'Project is nearly complete.';
    }

    if (progress >= .70) {
      return 'Project is progressing well.';
    }

    if (progress >= .40) {
      return 'Project is currently in progress.';
    }

    return 'Project is still in the early stage.';
  }

  // ================================================================
  // PROJECT NOT FOUND
  // ================================================================

  Widget _buildProjectNotFound() {
    return Scaffold(
      backgroundColor:
          const Color(0xffF5F7FB),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding:
                const EdgeInsets.all(24),
            child: Container(
              width: 460,
              padding:
                  const EdgeInsets.all(32),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.red.withValues(
                        alpha: .08,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: const Icon(
                      Icons
                          .folder_off_rounded,
                      color: Colors.red,
                      size: 36,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Project Not Found',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          AppColors.textDark,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'No project was found with code "${widget.projectId}".',
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      fontSize: 13,
                      color:
                          AppColors.textLight,
                    ),
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: () {
                      context.go(
                        '/projects',
                      );
                    },
                    icon: const Icon(
                      Icons
                          .arrow_back_rounded,
                    ),
                    label: const Text(
                      'Back to Projects',
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.primary,
                      foregroundColor:
                          Colors.white,
                      elevation: 0,
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// OVERVIEW ITEM MODEL
// ============================================================================

class _OverviewItem {
  final String title;
  final String value;
  final IconData icon;

  const _OverviewItem({
    required this.title,
    required this.value,
    required this.icon,
  });
}