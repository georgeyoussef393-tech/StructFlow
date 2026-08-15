import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:structflow/core/theme/app_colors.dart';
import 'package:structflow/features/projects/models/project_model.dart';
import 'package:structflow/features/projects/repositories/project_repository.dart';
import 'package:structflow/features/tasks/models/task_model.dart';
import 'package:structflow/features/tasks/repositories/task_repository.dart';

class CreateTaskScreen extends StatefulWidget {
  final String? taskId;
  final String? initialProjectCode;

  const CreateTaskScreen({
    super.key,
    this.taskId,
    this.initialProjectCode,
  });

  @override
  State<CreateTaskScreen> createState() =>
      _CreateTaskScreenState();
}

class _CreateTaskScreenState
    extends State<CreateTaskScreen> {
  final _formKey =
      GlobalKey<FormState>();

  final _titleController =
      TextEditingController();

  final _descriptionController =
      TextEditingController();

  final _assigneeController =
      TextEditingController();

  final TaskRepository _taskRepository =
      TaskRepository.instance;

  final ProjectRepository _projectRepository =
      ProjectRepository.instance;

  ProjectModel? _selectedProject;

  String _status = 'To Do';

  String _priority = 'Medium';

  double _progress = 0.0;

  DateTime _dueDate =
      DateTime.now().add(
    const Duration(days: 7),
  );

  bool get _isEditing =>
      widget.taskId != null;

  // ================================================================
  // INIT
  // ================================================================

  @override
  void initState() {
    super.initState();

    final taskId = widget.taskId;

    if (taskId == null) {
      _selectedProject =
          _projectRepository.getProjectByCode(
        widget.initialProjectCode ?? '',
      );

      return;
    }

    final task =
        _taskRepository.getTaskById(
      taskId,
    );

    if (task == null) {
      return;
    }

    _titleController.text =
        task.title;

    _descriptionController.text =
        task.description;

    _assigneeController.text =
        task.assignee == 'Unassigned'
            ? ''
            : task.assignee;

    _selectedProject =
        _projectRepository.getProjectByCode(
      task.projectCode,
    );

    _status =
        task.status;

    _priority =
        task.priority;

    _progress =
        task.progress;

    _dueDate =
        task.dueDate;
  }

  // ================================================================
  // DISPOSE
  // ================================================================

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assigneeController.dispose();

    super.dispose();
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF5F7FB),

      body: SafeArea(
        child: LayoutBuilder(
          builder:
              (context, constraints) {
            final width =
                constraints.maxWidth;

            final isMobile =
                width < 700;

            return SingleChildScrollView(
              padding:
                  EdgeInsets.all(
                isMobile
                    ? 16
                    : 30,
              ),

              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(
                    maxWidth: 1000,
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      _buildHeader(),

                      const SizedBox(
                        height: 24,
                      ),

                      _buildFormCard(
                        isMobile,
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
  // HEADER
  // ================================================================

  Widget _buildHeader() {
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

        const SizedBox(
          width: 8,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,

            children: [
              Text(
                _isEditing
                    ? 'Edit Task'
                    : 'Create New Task',

                style:
                    const TextStyle(
                  fontSize: 30,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      AppColors.textDark,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              Text(
                _isEditing
                    ? 'Update the task information and save your changes.'
                    : 'Create and assign a new task to your project team.',

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
      ],
    );
  }

  // ================================================================
  // FORM CARD
  // ================================================================

  Widget _buildFormCard(
    bool isMobile,
  ) {
    return Container(
      width:
          double.infinity,

      padding:
          EdgeInsets.all(
        isMobile
            ? 18
            : 28,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          20,
        ),

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

      child: Form(
        key:
            _formKey,

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,

          children: [
            const Text(
              'Task Information',
              style:
                  TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
                color:
                    AppColors.textDark,
              ),
            ),

            const SizedBox(
              height: 22,
            ),

            _buildTextField(
              controller:
                  _titleController,
              label:
                  'Task Title',
              hint:
                  'Enter task title',
              icon:
                  Icons.task_alt_rounded,
              requiredField:
                  true,
            ),

            const SizedBox(
              height: 18,
            ),

            _buildTextField(
              controller:
                  _descriptionController,
              label:
                  'Description',
              hint:
                  'Describe the task...',
              icon:
                  Icons.description_outlined,
              maxLines:
                  4,
            ),

            const SizedBox(
              height: 18,
            ),

            _buildProjectDropdown(),

            const SizedBox(
              height: 18,
            ),

            if (isMobile)
              Column(
                children: [
                  _buildAssigneeField(),

                  const SizedBox(
                    height: 18,
                  ),

                  _buildStatusDropdown(),

                  const SizedBox(
                    height: 18,
                  ),

                  _buildPriorityDropdown(),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child:
                        _buildAssigneeField(),
                  ),

                  const SizedBox(
                    width: 14,
                  ),

                  Expanded(
                    child:
                        _buildStatusDropdown(),
                  ),

                  const SizedBox(
                    width: 14,
                  ),

                  Expanded(
                    child:
                        _buildPriorityDropdown(),
                  ),
                ],
              ),

            const SizedBox(
              height: 18,
            ),

            _buildDueDateField(),

            if (_isEditing) ...[
              const SizedBox(
                height: 18,
              ),

              _buildProgressField(),
            ],

            const SizedBox(
              height: 30,
            ),

            const Divider(),

            const SizedBox(
              height: 22,
            ),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.end,

              children: [
                OutlinedButton(
                  onPressed: () {
                    context.pop();
                  },

                  style:
                      OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 24,
                      vertical: 15,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                    ),
                  ),

                  child:
                      const Text(
                    'Cancel',
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                ElevatedButton.icon(
                  onPressed:
                      _isEditing
                          ? _updateTask
                          : _createTask,

                  icon:
                      Icon(
                    _isEditing
                        ? Icons.save_rounded
                        : Icons.add_task_rounded,
                  ),

                  label:
                      Text(
                    _isEditing
                        ? 'Save Changes'
                        : 'Create Task',
                  ),

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primary,

                    foregroundColor:
                        Colors.white,

                    elevation:
                        0,

                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 24,
                      vertical: 15,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // TEXT FIELD
  // ================================================================

  Widget _buildTextField({
    required TextEditingController
        controller,
    required String label,
    required String hint,
    required IconData icon,
    bool requiredField =
        false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller:
          controller,

      maxLines:
          maxLines,

      validator:
          requiredField
              ? (value) {
                  if (value ==
                          null ||
                      value
                          .trim()
                          .isEmpty) {
                    return '$label is required';
                  }

                  return null;
                }
              : null,

      decoration:
          InputDecoration(
        labelText:
            label,

        hintText:
            hint,

        prefixIcon:
            Icon(icon),

        filled:
            true,

        fillColor:
            const Color(
          0xffFAFBFD,
        ),

        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),

          borderSide:
              BorderSide(
            color:
                Colors.grey.shade200,
          ),
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),

          borderSide:
              BorderSide(
            color:
                Colors.grey.shade200,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),

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
  // ASSIGNEE
  // ================================================================

  Widget _buildAssigneeField() {
    return _buildTextField(
      controller:
          _assigneeController,
      label:
          'Assignee',
      hint:
          'Engineer / team member',
      icon:
          Icons.person_outline_rounded,
    );
  }

  // ================================================================
  // PROJECT
  // ================================================================

  Widget _buildProjectDropdown() {
    final projects =
        _projectRepository.projects;

    return DropdownButtonFormField<
        ProjectModel>(
      initialValue:
          _selectedProject,

      decoration:
          InputDecoration(
        labelText:
            'Project',

        prefixIcon:
            const Icon(
          Icons.folder_outlined,
        ),

        filled:
            true,

        fillColor:
            const Color(
          0xffFAFBFD,
        ),

        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),

          borderSide:
              BorderSide(
            color:
                Colors.grey.shade200,
          ),
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),

          borderSide:
              BorderSide(
            color:
                Colors.grey.shade200,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),

          borderSide:
              const BorderSide(
            color:
                AppColors.primary,
          ),
        ),
      ),

      items:
          projects.map(
        (project) {
          return DropdownMenuItem<
              ProjectModel>(
            value:
                project,

            child:
                Text(
              '${project.code} • ${project.name}',
              overflow:
                  TextOverflow.ellipsis,
            ),
          );
        },
      ).toList(),

      onChanged:
          (value) {
        setState(() {
          _selectedProject =
              value;
        });
      },

      validator:
          (value) {
        if (value ==
            null) {
          return 'Please select a project';
        }

        return null;
      },
    );
  }

  // ================================================================
  // STATUS
  // ================================================================

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<
        String>(
      initialValue:
          _status,

      decoration:
          _dropdownDecoration(
        'Status',
        Icons.flag_outlined,
      ),

      items: const [
        DropdownMenuItem(
          value:
              'To Do',
          child:
              Text('To Do'),
        ),

        DropdownMenuItem(
          value:
              'In Progress',
          child:
              Text('In Progress'),
        ),

        DropdownMenuItem(
          value:
              'Review',
          child:
              Text('Review'),
        ),

        DropdownMenuItem(
          value:
              'Done',
          child:
              Text('Done'),
        ),
      ],

      onChanged:
          (value) {
        if (value ==
            null) {
          return;
        }

        setState(() {
          _status =
              value;

          if (value ==
              'Done') {
            _progress =
                1.0;
          }
        });
      },
    );
  }

  // ================================================================
  // PRIORITY
  // ================================================================

  Widget _buildPriorityDropdown() {
    return DropdownButtonFormField<
        String>(
      initialValue:
          _priority,

      decoration:
          _dropdownDecoration(
        'Priority',
        Icons.priority_high_rounded,
      ),

      items: const [
        DropdownMenuItem(
          value:
              'Low',
          child:
              Text('Low'),
        ),

        DropdownMenuItem(
          value:
              'Medium',
          child:
              Text('Medium'),
        ),

        DropdownMenuItem(
          value:
              'High',
          child:
              Text('High'),
        ),

        DropdownMenuItem(
          value:
              'Urgent',
          child:
              Text('Urgent'),
        ),
      ],

      onChanged:
          (value) {
        if (value ==
            null) {
          return;
        }

        setState(() {
          _priority =
              value;
        });
      },
    );
  }

  // ================================================================
  // DROPDOWN DECORATION
  // ================================================================

  InputDecoration _dropdownDecoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText:
          label,

      prefixIcon:
          Icon(icon),

      filled:
          true,

      fillColor:
          const Color(
        0xffFAFBFD,
      ),

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),

        borderSide:
            BorderSide(
          color:
              Colors.grey.shade200,
        ),
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),

        borderSide:
            BorderSide(
          color:
              Colors.grey.shade200,
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),

        borderSide:
            const BorderSide(
          color:
              AppColors.primary,
        ),
      ),
    );
  }

  // ================================================================
  // DUE DATE
  // ================================================================

  Widget _buildDueDateField() {
    return InkWell(
      onTap:
          _selectDueDate,

      borderRadius:
          BorderRadius.circular(
        14,
      ),

      child:
          InputDecorator(
        decoration:
            _dropdownDecoration(
          'Due Date',
          Icons.calendar_today_outlined,
        ),

        child:
            Text(
          _formatDate(
            _dueDate,
          ),

          style:
              const TextStyle(
            fontSize: 14,
            color:
                AppColors.textDark,
          ),
        ),
      ),
    );
  }

  // ================================================================
  // PROGRESS
  // ================================================================

  Widget _buildProgressField() {
    final percentage =
        (_progress * 100)
            .round();

    final isCompleted =
        _status == 'Done';

    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        10,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(
          0xffFAFBFD,
        ),

        borderRadius:
            BorderRadius.circular(
          14,
        ),

        border:
            Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,

        children: [
          Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                color:
                    AppColors.primary,
              ),

              const SizedBox(
                width: 10,
              ),

              const Expanded(
                child:
                    Text(
                  'Progress',
                  style:
                      TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        AppColors.textDark,
                  ),
                ),
              ),

              Text(
                '$percentage%',
                style:
                    const TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      AppColors.primary,
                ),
              ),
            ],
          ),

          Slider(
            value:
                _progress
                    .clamp(
                      0.0,
                      1.0,
                    )
                    .toDouble(),

            min:
                0,

            max:
                1,

            divisions:
                100,

            label:
                '$percentage%',

            onChanged:
                isCompleted
                    ? null
                    : (value) {
                        setState(() {
                          _progress =
                              value;

                          if (value ==
                              1.0) {
                            _status =
                                'Done';
                          }
                        });
                      },
          ),

          Text(
            isCompleted
                ? 'Completed tasks are automatically set to 100%.'
                : 'Drag the slider to update completion progress.',

            style:
                TextStyle(
              fontSize: 12,
              color:
                  Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // DATE PICKER
  // ================================================================

  Future<void>
      _selectDueDate() async {
    final today =
        DateTime.now();

    final firstDate =
        DateTime(
      today.year,
      today.month,
      today.day,
    );

    final selected =
        await showDatePicker(
      context:
          context,

      initialDate:
          _dueDate.isBefore(
        firstDate,
      )
              ? firstDate
              : _dueDate,

      firstDate:
          firstDate,

      lastDate:
          DateTime(2100),
    );

    if (selected ==
        null) {
      return;
    }

    setState(() {
      _dueDate =
          selected;
    });
  }

  // ================================================================
  // CREATE TASK
  // ================================================================

  void _createTask() {
    if (!_formKey
        .currentState!
        .validate()) {
      return;
    }

    if (_selectedProject ==
        null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a project before creating the task.',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );

      return;
    }

    final id =
        _taskRepository.nextTaskId;

    final newTask =
        TaskModel(
      id:
          id,

      title:
          _titleController
              .text
              .trim(),

      description:
          _descriptionController
              .text
              .trim(),

      projectCode:
          _selectedProject!
              .code,

      projectName:
          _selectedProject!
              .name,

      assignee:
          _assigneeController
                  .text
                  .trim()
                  .isEmpty
              ? 'Unassigned'
              : _assigneeController
                  .text
                  .trim(),

      status:
          _status,

      priority:
          _priority,

      dueDate:
          _dueDate,

      progress:
          _status == 'Done'
              ? 1.0
              : 0.0,

      color:
          _priorityColor(
        _priority,
      ),
    );

    _taskRepository
        .addTask(
      newTask,
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content:
            Text(
          'Task created successfully.',
        ),
        behavior:
            SnackBarBehavior.floating,
      ),
    );

    context.pop();
  }

  // ================================================================
  // UPDATE TASK
  // ================================================================

  void _updateTask() {
    if (!_formKey
        .currentState!
        .validate()) {
      return;
    }

    if (_selectedProject ==
            null ||
        widget.taskId ==
            null) {
      return;
    }

    final existingTask =
        _taskRepository
            .getTaskById(
      widget.taskId!,
    );

    if (existingTask ==
        null) {
      context.go(
        '/tasks',
      );

      return;
    }

    final updatedTask =
        existingTask.copyWith(
      title:
          _titleController
              .text
              .trim(),

      description:
          _descriptionController
              .text
              .trim(),

      projectCode:
          _selectedProject!
              .code,

      projectName:
          _selectedProject!
              .name,

      assignee:
          _assigneeController
                  .text
                  .trim()
                  .isEmpty
              ? 'Unassigned'
              : _assigneeController
                  .text
                  .trim(),

      status:
          _status,

      priority:
          _priority,

      dueDate:
          _dueDate,

      progress:
          _status == 'Done'
              ? 1.0
              : _progress,

      color:
          _priorityColor(
        _priority,
      ),
    );

    _taskRepository
        .updateTask(
      updatedTask,
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content:
            Text(
          'Task updated successfully.',
        ),
        behavior:
            SnackBarBehavior.floating,
      ),
    );

    context.go(
      '/tasks/${updatedTask.id}',
    );
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
        return Colors.blue;
    }
  }

  // ================================================================
  // DATE FORMAT
  // ================================================================

  String _formatDate(
    DateTime date,
  ) {
    final day =
        date.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    final month =
        date.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$day/$month/${date.year}';
  }
}