import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:structflow/core/theme/app_colors.dart';
import 'package:structflow/features/tasks/models/task_model.dart';
import 'package:structflow/features/tasks/repositories/task_repository.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TaskRepository _repository =
      TaskRepository.instance;

  final TextEditingController _searchController =
      TextEditingController();

  String _selectedStatus = 'All';
  String _selectedPriority = 'All';

  @override
  void initState() {
    super.initState();
    _repository.addListener(_onTasksChanged);
  }

  @override
  void dispose() {
    _repository.removeListener(_onTasksChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onTasksChanged() {
    if (!mounted) return;

    setState(() {});
  }

  // ================================================================
  // FILTERED TASKS
  // ================================================================

  List<TaskModel> get _filteredTasks {
    final query =
        _searchController.text.trim().toLowerCase();

    return _repository.tasks.where((task) {
      final matchesSearch =
          query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          task.id.toLowerCase().contains(query) ||
          task.projectName.toLowerCase().contains(query) ||
          task.projectCode.toLowerCase().contains(query) ||
          task.assignee.toLowerCase().contains(query);

      final matchesStatus =
          _selectedStatus == 'All' ||
          task.status == _selectedStatus;

      final matchesPriority =
          _selectedPriority == 'All' ||
          task.priority == _selectedPriority;

      return matchesSearch &&
          matchesStatus &&
          matchesPriority;
    }).toList();
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF5F7FB),

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
                  _buildHeader(width),

                  const SizedBox(height: 24),

                  _buildSummaryCards(width),

                  const SizedBox(height: 24),

                  _buildToolbar(width),

                  const SizedBox(height: 20),

                  _buildTasksSection(width),
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

  Widget _buildHeader(double width) {
    final mobile = width < 650;

    if (mobile) {
      return Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  context.go('/');
                },
                tooltip: 'Back to Dashboard',
                icon: const Icon(
                  Icons.arrow_back_rounded,
                ),
              ),

              const SizedBox(width: 4),

              const Expanded(
                child: Text(
                  'Tasks',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          const Text(
            'Manage and track your project tasks.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: _buildNewTaskButton(),
          ),
        ],
      );
    }

    return Row(
      children: [
        IconButton(
          onPressed: () {
            context.go('/');
          },
          tooltip: 'Back to Dashboard',
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),

        const SizedBox(width: 8),

        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                'Tasks',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),

              SizedBox(height: 6),

              Text(
                'Manage and track your project tasks.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),

        _buildNewTaskButton(),
      ],
    );
  }

  // ================================================================
  // NEW TASK
  // ================================================================

  Widget _buildNewTaskButton() {
    return ElevatedButton.icon(
      onPressed: () {
        context.push('/create-task');
      },

      icon: const Icon(
        Icons.add_rounded,
        size: 20,
      ),

      label: const Text(
        'New Task',
      ),

      style: ElevatedButton.styleFrom(
        backgroundColor:
            AppColors.primary,

        foregroundColor:
            Colors.white,

        elevation: 0,

        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ================================================================
  // SUMMARY
  // ================================================================

  Widget _buildSummaryCards(double width) {
    final columns = width >= 1100
        ? 4
        : width >= 700
            ? 2
            : 1;

    final cards = [
      _SummaryData(
        title: 'Total Tasks',
        value:
            '${_repository.taskCount}',
        subtitle: 'All tasks',
        icon:
            Icons.task_alt_rounded,
        color: Colors.blue,
      ),

      _SummaryData(
        title: 'In Progress',
        value:
            '${_repository.inProgressCount}',
        subtitle: 'Currently working',
        icon:
            Icons.play_circle_fill_rounded,
        color: Colors.orange,
      ),

      _SummaryData(
        title: 'Review',
        value:
            '${_repository.reviewCount}',
        subtitle: 'Waiting for review',
        icon:
            Icons.rate_review_rounded,
        color: Colors.purple,
      ),

      _SummaryData(
        title: 'Completed',
        value:
            '${_repository.completedCount}',
        subtitle: 'Finished tasks',
        icon:
            Icons.check_circle_rounded,
        color: Colors.green,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,

      physics:
          const NeverScrollableScrollPhysics(),

      itemCount:
          cards.length,

      gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            columns,

        crossAxisSpacing: 16,

        mainAxisSpacing: 16,

        mainAxisExtent: 140,
      ),

      itemBuilder:
          (context, index) {
        return _buildSummaryCard(
          cards[index],
        );
      },
    );
  }

  Widget _buildSummaryCard(
    _SummaryData data,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(20),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(18),

        boxShadow: const [
          BoxShadow(
            color:
                Colors.black12,
            blurRadius:
                14,
            offset:
                Offset(0, 5),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,

            decoration:
                BoxDecoration(
              color:
                  data.color.withOpacity(.10),

              borderRadius:
                  BorderRadius.circular(14),
            ),

            child: Icon(
              data.icon,
              color:
                  data.color,
              size: 25,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  data.title,
                  style:
                      const TextStyle(
                    fontSize: 13,
                    color:
                        AppColors
                            .textLight,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  data.value,
                  style:
                      const TextStyle(
                    fontSize: 25,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        AppColors
                            .textDark,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  data.subtitle,
                  style:
                      const TextStyle(
                    fontSize: 11,
                    color:
                        AppColors
                            .textLight,
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
  // TOOLBAR
  // ================================================================

  Widget _buildToolbar(double width) {
    final mobile = width < 750;

    if (mobile) {
      return Column(
        children: [
          _buildSearch(),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child:
                    _buildStatusFilter(),
              ),

              const SizedBox(width: 10),

              Expanded(
                child:
                    _buildPriorityFilter(),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child:
              _buildSearch(),
        ),

        const SizedBox(width: 14),

        _buildStatusFilter(),

        const SizedBox(width: 10),

        _buildPriorityFilter(),
      ],
    );
  }

  // ================================================================
  // SEARCH
  // ================================================================

  Widget _buildSearch() {
    return TextField(
      controller:
          _searchController,

      onChanged: (_) {
        setState(() {});
      },

      decoration:
          InputDecoration(
        hintText:
            'Search tasks, projects, assignees...',

        prefixIcon:
            const Icon(
          Icons.search_rounded,
        ),

        suffixIcon:
            _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();

                      setState(() {});
                    },

                    icon:
                        const Icon(
                      Icons.close_rounded,
                    ),
                  )
                : null,

        filled:
            true,

        fillColor:
            Colors.white,

        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),

          borderSide:
              BorderSide.none,
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),

          borderSide:
              BorderSide.none,
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),

          borderSide:
              const BorderSide(
            color:
                AppColors.primary,
          ),
        ),
      ),
    );
  }

  // ================================================================
  // STATUS FILTER
  // ================================================================

  Widget _buildStatusFilter() {
    return _filterDropdown(
      value:
          _selectedStatus,

      items: const [
        'All',
        'To Do',
        'In Progress',
        'Review',
        'Done',
      ],

      label:
          'Status',

      icon:
          Icons.filter_alt_outlined,

      onChanged:
          (value) {
        setState(() {
          _selectedStatus =
              value;
        });
      },
    );
  }

  // ================================================================
  // PRIORITY FILTER
  // ================================================================

  Widget _buildPriorityFilter() {
    return _filterDropdown(
      value:
          _selectedPriority,

      items: const [
        'All',
        'Low',
        'Medium',
        'High',
        'Urgent',
      ],

      label:
          'Priority',

      icon:
          Icons.flag_outlined,

      onChanged:
          (value) {
        setState(() {
          _selectedPriority =
              value;
        });
      },
    );
  }

  Widget _filterDropdown({
    required String value,
    required List<String> items,
    required String label,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(14),
      ),

      child:
          DropdownButtonHideUnderline(
        child:
            DropdownButton<String>(
          value:
              value,

          icon:
              const Icon(
            Icons.keyboard_arrow_down_rounded,
          ),

          borderRadius:
              BorderRadius.circular(14),

          hint:
              Text(label),

          items:
              items.map(
            (item) {
              return DropdownMenuItem<String>(
                value:
                    item,

                child:
                    Row(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [
                    Icon(
                      icon,
                      size: 17,
                      color:
                          Colors.grey.shade600,
                    ),

                    const SizedBox(
                      width: 7,
                    ),

                    Text(item),
                  ],
                ),
              );
            },
          ).toList(),

          onChanged:
              (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }

  // ================================================================
  // TASKS SECTION
  // ================================================================

  Widget _buildTasksSection(
    double width,
  ) {
    final tasks =
        _filteredTasks;

    return Container(
      width:
          double.infinity,

      padding:
          EdgeInsets.all(
        width < 600
            ? 16
            : 22,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        boxShadow: const [
          BoxShadow(
            color:
                Colors.black12,
            blurRadius:
                14,
            offset:
                Offset(0, 5),
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
                  'All Tasks',
                  style:
                      TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        AppColors
                            .textDark,
                  ),
                ),
              ),

              Text(
                '${tasks.length} tasks',
                style:
                    const TextStyle(
                  fontSize: 13,
                  color:
                      AppColors
                          .textLight,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          if (tasks.isEmpty)
            _buildEmptyState()
          else
            _buildTaskGrid(
              tasks,
              width,
            ),
        ],
      ),
    );
  }

  // ================================================================
  // TASK GRID
  // ================================================================

  Widget _buildTaskGrid(
    List<TaskModel> tasks,
    double width,
  ) {
    final columns = width >= 1250
        ? 3
        : width >= 750
            ? 2
            : 1;

    return GridView.builder(
      shrinkWrap:
          true,

      physics:
          const NeverScrollableScrollPhysics(),

      itemCount:
          tasks.length,

      gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            columns,

        crossAxisSpacing:
            18,

        mainAxisSpacing:
            18,

        mainAxisExtent:
            310,
      ),

      itemBuilder:
          (context, index) {
        return _buildTaskCard(
          tasks[index],
        );
      },
    );
  }

  // ================================================================
  // TASK CARD
  // ================================================================

  Widget _buildTaskCard(
    TaskModel task,
  ) {
    return InkWell(
      onTap: () {
        // ==========================================================
        // OPEN TASK DETAILS
        // ==========================================================

        context.push(
          '/tasks/${task.id}',
        );
      },

      borderRadius:
          BorderRadius.circular(18),

      child: Container(
        padding:
            const EdgeInsets.all(18),

        decoration:
            BoxDecoration(
          color:
              const Color(0xffFBFCFE),

          borderRadius:
              BorderRadius.circular(18),

          border:
              Border.all(
            color:
                Colors.grey.shade200,
          ),
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,

                  decoration:
                      BoxDecoration(
                    color:
                        task.color.withOpacity(.10),

                    borderRadius:
                        BorderRadius.circular(13),
                  ),

                  child: Icon(
                    Icons.task_alt_rounded,
                    color:
                        task.color,
                    size: 23,
                  ),
                ),

                const Spacer(),

                _buildPriorityBadge(
                  task.priority,
                ),
              ],
            ),

            const SizedBox(
              height: 14,
            ),

            Text(
              task.title,

              maxLines: 2,

              overflow:
                  TextOverflow.ellipsis,

              style:
                  const TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
                color:
                    AppColors
                        .textDark,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              task.id,

              style:
                  const TextStyle(
                fontSize: 12,
                color:
                    AppColors
                        .textLight,
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            _infoRow(
              Icons.folder_outlined,
              task.projectName,
            ),

            const SizedBox(
              height: 8,
            ),

            _infoRow(
              Icons.person_outline_rounded,
              task.assignee,
            ),

            const SizedBox(
              height: 8,
            ),

            _infoRow(
              Icons.calendar_today_outlined,
              _formatDate(
                task.dueDate,
              ),
            ),

            const Spacer(),

            Row(
              children: [
                _buildStatusBadge(
                  task.status,
                ),

                const Spacer(),

                Text(
                  '${(task.progress * 100).round()}%',
                  style:
                      TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        task.color,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 7,
            ),

            ClipRRect(
              borderRadius:
                  BorderRadius.circular(20),

              child:
                  LinearProgressIndicator(
                value:
                    task.progress,

                minHeight:
                    7,

                backgroundColor:
                    task.color
                        .withOpacity(.10),

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
    );
  }

  // ================================================================
  // STATUS BADGE
  // ================================================================

  Widget _buildStatusBadge(
    String status,
  ) {
    final color =
        _statusColor(status);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),

      decoration:
          BoxDecoration(
        color:
            color.withOpacity(.10),

        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Text(
        status,

        style:
            TextStyle(
          color:
              color,

          fontSize:
              11,

          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  // ================================================================
  // PRIORITY BADGE
  // ================================================================

  Widget _buildPriorityBadge(
    String priority,
  ) {
    final color =
        _priorityColor(priority);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),

      decoration:
          BoxDecoration(
        color:
            color.withOpacity(.10),

        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Text(
        priority,

        style:
            TextStyle(
          color:
              color,

          fontSize:
              11,

          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  // ================================================================
  // INFO ROW
  // ================================================================

  Widget _infoRow(
    IconData icon,
    String text,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color:
              Colors.grey.shade500,
        ),

        const SizedBox(
          width: 7,
        ),

        Expanded(
          child: Text(
            text,

            maxLines:
                1,

            overflow:
                TextOverflow.ellipsis,

            style:
                const TextStyle(
              fontSize: 12,
              color:
                  AppColors
                      .textLight,
            ),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // EMPTY
  // ================================================================

  Widget _buildEmptyState() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 60,
      ),

      child: Center(
        child: Column(
          children: [
            Icon(
              Icons
                  .search_off_rounded,
              size: 52,
              color:
                  Colors.grey.shade400,
            ),

            const SizedBox(
              height: 14,
            ),

            const Text(
              'No tasks found',
              style:
                  TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
                color:
                    AppColors
                        .textDark,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            const Text(
              'Try changing your search or filters.',
              style:
                  TextStyle(
                color:
                    AppColors
                        .textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // COLORS
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
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}

// ============================================================================
// SUMMARY DATA
// ============================================================================

class _SummaryData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SummaryData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}