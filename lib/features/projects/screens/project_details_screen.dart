import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:structflow/core/theme/app_colors.dart';
import 'package:structflow/features/projects/models/project_model.dart';
import 'package:structflow/features/projects/repositories/project_repository.dart';
import 'package:structflow/features/tasks/models/task_model.dart';
import 'package:structflow/features/tasks/repositories/task_repository.dart';

class ProjectDetailsScreen extends StatelessWidget {
  final String projectId;

  const ProjectDetailsScreen({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context) {
    // ================================================================
    // GET REAL PROJECT FROM REPOSITORY
    // ================================================================

    final projectRepository = ProjectRepository.instance;

    final ProjectModel? project =
        projectRepository.getProjectByCode(projectId);

    // ================================================================
    // PROJECT NOT FOUND
    // ================================================================

    if (project == null) {
      return Scaffold(
        backgroundColor: const Color(0xffF5F7FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          title: const Text('Project'),
        ),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.folder_off_rounded,
                  size: 60,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Project Not Found',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No project was found with code: $projectId',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    context.pop();
                  },
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                  ),
                  label: const Text(
                    'Back to Projects',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
    // REAL PROJECT DETAILS
    // ================================================================

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      body: AnimatedBuilder(
        animation: TaskRepository.instance,
        builder: (context, child) {
          final tasks = TaskRepository.instance.getTasksByProject(
            project.code,
          );

          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final isMobile = width < 700;

                return SingleChildScrollView(
                  padding: EdgeInsets.all(
                    isMobile ? 16 : 28,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _buildHeader(
                        context,
                        project,
                        isMobile,
                      ),
                      const SizedBox(height: 24),
                      _buildOverviewCard(
                        project,
                        isMobile,
                        tasks,
                      ),
                      const SizedBox(height: 20),
                      _buildMainContent(
                        context,
                        project,
                        width,
                        tasks,
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ================================================================
  // HEADER
  // ================================================================

  Widget _buildHeader(
    BuildContext context,
    ProjectModel project,
    bool isMobile,
  ) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () {
              context.pop();
            },
            icon: const Icon(
              Icons.arrow_back_rounded,
            ),
            label: const Text(
              'Back to Projects',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _projectIcon(project),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project.code,
                      style: const TextStyle(
                        fontSize: 13,
                        color:
                            AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _statusBadge(
            project.status,
          ),
        ],
      );
    }

    return Row(
      children: [
        IconButton(
          onPressed: () {
            context.pop();
          },
          tooltip: 'Back',
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),
        const SizedBox(width: 8),
        _projectIcon(project),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                project.name,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${project.code} • ${project.location}',
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color:
                      AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
        _statusBadge(
          project.status,
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () {
            _showComingSoon(
              context,
              'Edit Project',
            );
          },
          icon: const Icon(
            Icons.edit_rounded,
            size: 18,
          ),
          label: const Text(
            'Edit Project',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                AppColors.primary,
            foregroundColor:
                Colors.white,
            elevation: 0,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // PROJECT ICON
  // ================================================================

  Widget _projectIcon(
    ProjectModel project,
  ) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color:
            project.color.withValues(alpha: .10),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Icon(
        project.icon,
        color: project.color,
        size: 28,
      ),
    );
  }

  // ================================================================
  // OVERVIEW
  // ================================================================

  Widget _buildOverviewCard(
    ProjectModel project,
    bool isMobile,
    List<TaskModel> tasks,
  ) {
    final averageProgress =
        _calculateAverageProgress(tasks);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isMobile ? 18 : 24,
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
          const Text(
            'Project Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
              color:
                  AppColors.textDark,
            ),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder:
                (context, constraints) {
              final columns =
                  constraints.maxWidth >= 900
                      ? 4
                      : constraints.maxWidth >= 600
                          ? 2
                          : 1;

              return GridView.count(
                crossAxisCount:
                    columns,
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
                childAspectRatio: 2.8,
                children: [
                  _infoCard(
                    Icons.person_outline_rounded,
                    'Client',
                    project.client,
                    Colors.blue,
                  ),
                  _infoCard(
                    Icons.location_on_outlined,
                    'Location',
                    project.location,
                    Colors.red,
                  ),
                  _infoCard(
                    Icons.account_balance_wallet_outlined,
                    'Budget',
                    project.budget,
                    Colors.orange,
                  ),
                  _infoCard(
                    Icons.people_outline_rounded,
                    'Team',
                    '${project.team} Members',
                    Colors.purple,
                  ),
                  _infoCard(
                    Icons.task_alt_rounded,
                    'Tasks',
                    '${tasks.length} Tasks',
                    Colors.teal,
                  ),
                  _infoCard(
                    Icons.trending_up_rounded,
                    'Task Progress',
                    '$averageProgress%',
                    AppColors.primary,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  int _calculateAverageProgress(
    List<TaskModel> tasks,
  ) {
    if (tasks.isEmpty) {
      return 0;
    }

    final totalProgress = tasks.fold<double>(
      0,
      (total, task) {
        return total + task.progress;
      },
    );

    return ((totalProgress / tasks.length) * 100)
        .round();
  }

  Widget _infoCard(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            const Color(0xffFAFBFD),
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
                  color.withValues(alpha: .10),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 11,
                    color:
                        AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 13,
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
    BuildContext context,
    ProjectModel project,
    double width,
    List<TaskModel> tasks,
  ) {
    if (width < 950) {
      return Column(
        children: [
          _buildProgressCard(project),
          const SizedBox(height: 20),
          _buildTasksCard(
            context,
            project,
            tasks,
          ),
          const SizedBox(height: 20),
          _buildModulesCard(),
          const SizedBox(height: 20),
          _buildActivityCard(),
        ],
      );
    }

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildProgressCard(project),
              const SizedBox(height: 20),
              _buildTasksCard(
                context,
                project,
                tasks,
              ),
              const SizedBox(height: 20),
              _buildModulesCard(),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child:
              _buildActivityCard(),
        ),
      ],
    );
  }

  // ================================================================
  // PROJECT PROGRESS
  // ================================================================

  Widget _buildProgressCard(
    ProjectModel project,
  ) {
    final percentage =
        (project.progress * 100).round();

    return _sectionCard(
      title: 'Project Progress',
      icon:
          Icons.trending_up_rounded,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      project.color,
                ),
              ),
              const Spacer(),
              const Text(
                'Overall Progress',
                style: TextStyle(
                  color:
                      AppColors.textLight,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(20),
            child:
                LinearProgressIndicator(
              value:
                  project.progress,
              minHeight: 12,
              backgroundColor:
                  project.color
                      .withValues(alpha: .10),
              valueColor:
                  AlwaysStoppedAnimation<
                      Color>(
                project.color,
              ),
            ),
          ),
          const SizedBox(height: 22),
          _progressRow(
            'Civil Works',
            .91,
            Colors.blue,
          ),
          _progressRow(
            'Architecture',
            .76,
            Colors.green,
          ),
          _progressRow(
            'Mechanical',
            .62,
            Colors.orange,
          ),
          _progressRow(
            'Electrical',
            .55,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _progressRow(
    String title,
    double value,
    Color color,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 15,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
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
              ),
              Text(
                '${(value * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(20),
            child:
                LinearProgressIndicator(
              value: value,
              minHeight: 7,
              backgroundColor:
                  color.withValues(alpha: .10),
              valueColor:
                  AlwaysStoppedAnimation<
                      Color>(
                color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // PROJECT TASKS
  // ================================================================

  Widget _buildTasksCard(
    BuildContext context,
    ProjectModel project,
    List<TaskModel> tasks,
  ) {
    return _sectionCard(
      title: 'Project Tasks',
      icon:
          Icons.task_alt_rounded,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child:
                OutlinedButton.icon(
              onPressed: () {
                // IMPORTANT:
                // push keeps Project Details in navigation stack.
                // Create Task -> Back returns here.
                context.push(
                  '/create-task?projectCode=${project.code}',
                );
              },
              icon: const Icon(
                Icons.add_task_rounded,
              ),
              label: const Text(
                'Create Task',
              ),
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    AppColors.primary,
                side: const BorderSide(
                  color:
                      AppColors.primary,
                ),
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 13,
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
          ),
          const SizedBox(height: 14),
          if (tasks.isEmpty)
            _buildNoTasksState()
          else
            ...tasks.map(
              (task) => _taskItem(
                context,
                task,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoTasksState() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 24,
      ),
      child: Column(
        children: [
          Icon(
            Icons.task_alt_rounded,
            size: 42,
            color:
                Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          const Text(
            'No tasks yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.w600,
              color:
                  AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Create the first task for this project.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color:
                  AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskItem(
    BuildContext context,
    TaskModel task,
  ) {
    final percentage =
        (task.progress * 100).round();

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: InkWell(
        onTap: () {
          // IMPORTANT:
          // push instead of go.
          // This preserves Project Details,
          // so Task Details -> Back returns here.
          context.push(
            '/tasks/${task.id}',
          );
        },
        borderRadius:
            BorderRadius.circular(16),
        child: Container(
          padding:
              const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:
                task.color.withValues(alpha: .06),
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color:
                  task.color.withValues(alpha: .15),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration:
                        BoxDecoration(
                      color: task.color
                          .withValues(alpha: .10),
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Icon(
                      Icons.task_alt_rounded,
                      color:
                          task.color,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
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
                        const SizedBox(height: 3),
                        Text(
                          task.id,
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
                  _buildTaskPriorityBadge(
                    task.priority,
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color:
                        task.color,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _taskMeta(
                      Icons.person_outline_rounded,
                      task.assignee,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _taskMeta(
                      Icons.calendar_today_outlined,
                      _formatDate(
                        task.dueDate,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildTaskStatusBadge(
                    task.status,
                  ),
                  const Spacer(),
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          task.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
                child:
                    LinearProgressIndicator(
                  value:
                      task.progress,
                  minHeight: 6,
                  backgroundColor:
                      task.color
                          .withValues(alpha: .10),
                  valueColor:
                      AlwaysStoppedAnimation<
                          Color>(
                    task.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _taskMeta(
    IconData icon,
    String text,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color:
              Colors.grey.shade500,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
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
        ),
      ],
    );
  }

  Widget _buildTaskStatusBadge(
    String status,
  ) {
    final color =
        _taskStatusColor(status);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withValues(alpha: .10),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTaskPriorityBadge(
    String priority,
  ) {
    final color =
        _taskPriorityColor(priority);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withValues(alpha: .10),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  // ================================================================
  // MODULES
  // ================================================================

  Widget _buildModulesCard() {
    return _sectionCard(
      title: 'Project Modules',
      icon:
          Icons.dashboard_customize_rounded,
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics:
            const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.7,
        children: [
          _moduleItem(
            Icons.description_rounded,
            'Documents',
            Colors.blue,
          ),
          _moduleItem(
            Icons.architecture_rounded,
            'Drawings',
            Colors.purple,
          ),
          _moduleItem(
            Icons.request_quote_rounded,
            'BOQ',
            Colors.orange,
          ),
          _moduleItem(
            Icons.help_outline_rounded,
            'RFIs',
            Colors.red,
          ),
          _moduleItem(
            Icons.people_alt_rounded,
            'Team',
            Colors.green,
          ),
          _moduleItem(
            Icons.analytics_rounded,
            'Reports',
            Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _moduleItem(
    IconData icon,
    String title,
    Color color,
  ) {
    return InkWell(
      onTap: () {
        // سيتم ربط الموديول لاحقًا.
      },
      borderRadius:
          BorderRadius.circular(14),
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
        ),
        decoration:
            BoxDecoration(
          color:
              color.withValues(alpha: .06),
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color:
                color.withValues(alpha: .15),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 21,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
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
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // ACTIVITY
  // ================================================================

  Widget _buildActivityCard() {
    return _sectionCard(
      title: 'Recent Activity',
      icon:
          Icons.timeline_rounded,
      child: Column(
        children: [
          _activityItem(
            Icons.check_circle_rounded,
            'BOQ Approved',
            'Structural BOQ was approved.',
            '5 min ago',
            Colors.green,
          ),
          _activityItem(
            Icons.upload_file_rounded,
            'Drawing Uploaded',
            'New architectural drawing uploaded.',
            '18 min ago',
            Colors.blue,
          ),
          _activityItem(
            Icons.warning_amber_rounded,
            'RFI Waiting Response',
            'RFI-104 requires consultant response.',
            '40 min ago',
            Colors.orange,
          ),
          _activityItem(
            Icons.person_add_alt_1_rounded,
            'Engineer Added',
            'New engineer joined the project.',
            '1 hour ago',
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _activityItem(
    IconData icon,
    String title,
    String description,
    String time,
    Color color,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 18,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration:
                BoxDecoration(
              color:
                  color.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                    color:
                        AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  time,
                  style:
                      const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
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
  // SECTION CARD
  // ================================================================

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(22),
      decoration:
          BoxDecoration(
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
              Icon(
                icon,
                color:
                    AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 19,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      AppColors.textDark,
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

  // ================================================================
  // PROJECT STATUS
  // ================================================================

  Widget _statusBadge(
    String status,
  ) {
    final color =
        _projectStatusColor(status);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withValues(alpha: .10),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  Color _projectStatusColor(
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
  // TASK STATUS
  // ================================================================

  Color _taskStatusColor(
    String status,
  ) {
    switch (status) {
      case 'To Do':
        return Colors.blue;
      case 'In Progress':
        return Colors.orange;
      case 'Review':
        return Colors.purple;
      case 'Done':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // ================================================================
  // TASK PRIORITY
  // ================================================================

  Color _taskPriorityColor(
    String priority,
  ) {
    switch (priority) {
      case 'Urgent':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.blue;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // ================================================================
  // DATE
  // ================================================================

  String _formatDate(
    DateTime date,
  ) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // ================================================================
  // TEMP ACTION
  // ================================================================

  void _showComingSoon(
    BuildContext context,
    String title,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '$title will be connected next.',
        ),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }
}