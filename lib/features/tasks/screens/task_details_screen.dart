import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:structflow/core/theme/app_colors.dart';
import 'package:structflow/features/tasks/models/task_model.dart';
import 'package:structflow/features/tasks/repositories/task_repository.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailsScreen({
    super.key,
    required this.taskId,
  });

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final TaskRepository _repository = TaskRepository.instance;

  @override
  void initState() {
    super.initState();
    _repository.addListener(_onTaskChanged);
  }

  @override
  void dispose() {
    _repository.removeListener(_onTaskChanged);
    super.dispose();
  }

  void _onTaskChanged() {
    if (!mounted) return;

    setState(() {});
  }

  // ================================================================
  // BACK NAVIGATION
  // ================================================================

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/tasks');
    }
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final task = _repository.getTaskById(widget.taskId);

    if (task == null) {
      return _buildNotFound();
    }

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < 750;

            return SingleChildScrollView(
              padding: EdgeInsets.all(
                isMobile ? 16 : 28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1200,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _buildHeader(
                        task,
                        isMobile,
                      ),

                      const SizedBox(height: 24),

                      _buildOverview(
                        task,
                        isMobile,
                      ),

                      const SizedBox(height: 20),

                      _buildMainContent(
                        task,
                        width,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ================================================================
  // NOT FOUND
  // ================================================================

  Widget _buildNotFound() {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 60,
                color: Colors.grey.shade400,
              ),

              const SizedBox(height: 16),

              const Text(
                'Task Not Found',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'The requested task could not be found.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 22),

              ElevatedButton.icon(
                onPressed: () {
                  context.go('/tasks');
                },
                icon: const Icon(
                  Icons.arrow_back_rounded,
                ),
                label: const Text(
                  'Back to Tasks',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // HEADER
  // ================================================================

  Widget _buildHeader(
    TaskModel task,
    bool isMobile,
  ) {
    if (isMobile) {
      return Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: _goBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
            ),
            label: const Text(
              'Back',
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              _taskIcon(
                task,
                58,
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
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
                      task.id,
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

          Row(
            children: [
              _statusBadge(
                task.status,
              ),

              const SizedBox(width: 8),

              _priorityBadge(
                task.priority,
              ),
            ],
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                context.push(
                  '/tasks/${task.id}/edit',
                );
              },
              icon: const Icon(
                Icons.edit_rounded,
                size: 18,
              ),
              label: const Text(
                'Edit Task',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    AppColors.primary,
                side: const BorderSide(
                  color: AppColors.primary,
                ),
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 13,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        IconButton(
          onPressed: _goBack,
          tooltip: 'Back',
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),

        const SizedBox(width: 8),

        _taskIcon(
          task,
          58,
        ),

        const SizedBox(width: 14),

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
                '${task.id} • ${task.projectName}',
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
          task.status,
        ),

        const SizedBox(width: 10),

        _priorityBadge(
          task.priority,
        ),

        const SizedBox(width: 12),

        OutlinedButton.icon(
          onPressed: () {
            context.push(
              '/tasks/${task.id}/edit',
            );
          },
          icon: const Icon(
            Icons.edit_rounded,
            size: 18,
          ),
          label: const Text(
            'Edit',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor:
                AppColors.primary,
            side: const BorderSide(
              color: AppColors.primary,
            ),
            padding:
                const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 13,
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
  // TASK ICON
  // ================================================================

  Widget _taskIcon(
    TaskModel task,
    double size,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: task.color.withValues(
          alpha: .10,
        ),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.task_alt_rounded,
        color: task.color,
        size: size * .48,
      ),
    );
  }

  // ================================================================
  // OVERVIEW
  // ================================================================

  Widget _buildOverview(
    TaskModel task,
    bool isMobile,
  ) {
    return _sectionCard(
      title: 'Task Overview',
      icon: Icons.info_outline_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns =
              constraints.maxWidth >= 900
                  ? 4
                  : constraints.maxWidth >= 600
                      ? 2
                      : 1;

          return GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.8,
            children: [
              _infoCard(
                Icons.folder_outlined,
                'Project',
                task.projectName,
                Colors.blue,
              ),

              _infoCard(
                Icons.person_outline_rounded,
                'Assignee',
                task.assignee,
                Colors.purple,
              ),

              _infoCard(
                Icons.calendar_today_outlined,
                'Due Date',
                _formatDate(
                  task.dueDate,
                ),
                Colors.orange,
              ),

              _infoCard(
                Icons.flag_outlined,
                'Priority',
                task.priority,
                _priorityColor(
                  task.priority,
                ),
              ),
            ],
          );
        },
      ),
    );
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
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(
              color:
                  color.withValues(
                alpha: .10,
              ),
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
                        AppColors
                            .textLight,
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
                        AppColors
                            .textDark,
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
    TaskModel task,
    double width,
  ) {
    if (width < 900) {
      return Column(
        children: [
          _buildProgressCard(
            task,
          ),

          const SizedBox(height: 20),

          _buildDescriptionCard(
            task,
          ),

          const SizedBox(height: 20),

          _buildActionsCard(
            task,
          ),
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
              _buildProgressCard(
                task,
              ),

              const SizedBox(height: 20),

              _buildDescriptionCard(
                task,
              ),
            ],
          ),
        ),

        const SizedBox(width: 20),

        Expanded(
          child:
              _buildActionsCard(
            task,
          ),
        ),
      ],
    );
  }

  // ================================================================
  // PROGRESS
  // ================================================================

  Widget _buildProgressCard(
    TaskModel task,
  ) {
    final percentage =
        (task.progress * 100).round();

    return _sectionCard(
      title: 'Task Progress',
      icon: Icons.trending_up_rounded,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight:
                      FontWeight.bold,
                  color: task.color,
                ),
              ),

              const Spacer(),

              _statusBadge(
                task.status,
              ),
            ],
          ),

          const SizedBox(height: 16),

          ClipRRect(
            borderRadius:
                BorderRadius.circular(20),
            child:
                LinearProgressIndicator(
              value:
                  task.progress,
              minHeight: 12,
              backgroundColor:
                  task.color.withValues(
                alpha: .10,
              ),
              valueColor:
                  AlwaysStoppedAnimation<
                      Color>(
                task.color,
              ),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              const Text(
                'Current Status',
                style: TextStyle(
                  fontSize: 13,
                  color:
                      AppColors
                          .textLight,
                ),
              ),

              const Spacer(),

              Text(
                task.status,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      _statusColor(
                    task.status,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================================================================
  // DESCRIPTION
  // ================================================================

  Widget _buildDescriptionCard(
    TaskModel task,
  ) {
    return _sectionCard(
      title: 'Description',
      icon: Icons.description_outlined,
      child: Text(
        task.description.isEmpty
            ? 'No description has been added for this task.'
            : task.description,
        style: const TextStyle(
          fontSize: 14,
          height: 1.6,
          color:
              AppColors.textLight,
        ),
      ),
    );
  }

  // ================================================================
  // ACTIONS
  // ================================================================

  Widget _buildActionsCard(
    TaskModel task,
  ) {
    return _sectionCard(
      title: 'Task Actions',
      icon: Icons.bolt_rounded,
      child: Column(
        children: [
          _actionButton(
            icon: Icons.edit_rounded,
            title: 'Edit Task',
            subtitle:
                'Update task information',
            color:
                AppColors.primary,
            onTap: () {
              context.push(
                '/tasks/${task.id}/edit',
              );
            },
          ),

          const SizedBox(height: 12),

          _actionButton(
            icon:
                Icons.check_circle_outline_rounded,
            title: 'Mark as Done',
            subtitle:
                'Complete this task',
            color: Colors.green,
            onTap:
                task.status == 'Done'
                    ? null
                    : () {
                        _markAsDone(
                          task,
                        );
                      },
          ),

          const SizedBox(height: 12),

          _actionButton(
            icon:
                Icons.delete_outline_rounded,
            title: 'Delete Task',
            subtitle:
                'Remove this task',
            color: Colors.red,
            onTap: () {
              _confirmDelete(
                task,
              );
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
    required Color color,
    required VoidCallback? onTap,
  }) {
    final disabled =
        onTap == null;

    return InkWell(
      onTap:
          disabled ? null : onTap,
      borderRadius:
          BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(14),
        decoration:
            BoxDecoration(
          color: disabled
              ? Colors.grey.shade100
              : color.withValues(
                  alpha: .06,
                ),
          borderRadius:
              BorderRadius.circular(14),
          border: Border.all(
            color: disabled
                ? Colors.grey.shade200
                : color.withValues(
                    alpha: .15,
                  ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration:
                  BoxDecoration(
                color: disabled
                    ? Colors.grey.shade200
                    : color.withValues(
                        alpha: .10,
                      ),
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child: Icon(
                icon,
                color: disabled
                    ? Colors.grey
                    : color,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w600,
                      color: disabled
                          ? Colors.grey
                          : AppColors
                              .textDark,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: disabled
                          ? Colors.grey
                          : AppColors
                              .textLight,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: disabled
                  ? Colors.grey
                  : color,
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // MARK DONE
  // ================================================================

  void _markAsDone(
    TaskModel task,
  ) {
    final updatedTask =
        task.copyWith(
      status: 'Done',
      progress: 1.0,
    );

    _repository.updateTask(
      updatedTask,
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content: Text(
          'Task marked as completed.',
        ),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // ================================================================
  // DELETE
  // ================================================================

  void _confirmDelete(
    TaskModel task,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text(
            'Delete Task?',
          ),
          content: Text(
            'Are you sure you want to delete "${task.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                _repository.deleteTask(
                  task.id,
                );

                Navigator.pop(
                  dialogContext,
                );

                context.go(
                  '/tasks',
                );

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Task deleted successfully.',
                    ),
                    behavior:
                        SnackBarBehavior.floating,
                  ),
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text('Delete'),
            ),
          ],
        );
      },
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
                      AppColors
                          .textDark,
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
  // STATUS
  // ================================================================

  Widget _statusBadge(
    String status,
  ) {
    final color =
        _statusColor(status);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withValues(
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

  // ================================================================
  // PRIORITY
  // ================================================================

  Widget _priorityBadge(
    String priority,
  ) {
    final color =
        _priorityColor(priority);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha: .10,
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  // ================================================================
  // STATUS COLOR
  // ================================================================

  Color _statusColor(
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
  // PRIORITY COLOR
  // ================================================================

  Color _priorityColor(
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
        date.day.toString().padLeft(
              2,
              '0',
            );

    final month =
        date.month.toString().padLeft(
              2,
              '0',
            );

    return '$day/$month/${date.year}';
  }
}