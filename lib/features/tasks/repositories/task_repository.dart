import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:structflow/core/network/api_auth_client.dart';
import 'package:structflow/features/auth/repositories/auth_repository.dart';
import 'package:structflow/features/projects/models/project_member_model.dart';
import 'package:structflow/features/tasks/models/task_model.dart';

class TaskRepository extends ChangeNotifier {
  static const _storageKey = 'structflow_tasks';
  TaskRepository._();

  static final TaskRepository instance = TaskRepository._();

  final List<TaskModel> _tasks = [
    TaskModel(
      id: 'TSK-001',
      title: 'Review Structural Drawings',
      description:
          'Review the latest structural drawings before consultant submission.',
      projectCode: 'PRJ-001',
      projectName: 'New Capital Tower',
      assignee: 'Ahmed Hassan',
      status: 'In Progress',
      priority: 'High',
      dueDate: DateTime(2026, 8, 15),
      progress: 0.65,
      color: Colors.orange,
    ),

    TaskModel(
      id: 'TSK-002',
      title: 'Approve BOQ',
      description: 'Review and approve the updated bill of quantities.',
      projectCode: 'PRJ-002',
      projectName: 'Cairo Business Park',
      assignee: 'Michael George',
      status: 'Review',
      priority: 'Medium',
      dueDate: DateTime(2026, 8, 18),
      progress: 0.80,
      color: Colors.blue,
    ),

    TaskModel(
      id: 'TSK-003',
      title: 'Electrical Coordination',
      description:
          'Coordinate electrical drawings with architectural and mechanical disciplines.',
      projectCode: 'PRJ-004',
      projectName: 'Alex Mall',
      assignee: 'Daniel Sameh',
      status: 'To Do',
      priority: 'High',
      dueDate: DateTime(2026, 8, 22),
      progress: 0.0,
      color: Colors.orange,
    ),

    TaskModel(
      id: 'TSK-004',
      title: 'Site Inspection',
      description:
          'Complete the scheduled site inspection and upload the inspection report.',
      projectCode: 'PRJ-006',
      projectName: 'Tuban Villas',
      assignee: 'George',
      status: 'Done',
      priority: 'Medium',
      dueDate: DateTime(2026, 8, 8),
      progress: 1.0,
      color: Colors.green,
    ),

    TaskModel(
      id: 'TSK-005',
      title: 'Prepare RFI Response',
      description: 'Prepare the consultant response for the outstanding RFI.',
      projectCode: 'PRJ-003',
      projectName: 'Smart Village',
      assignee: 'John Mark',
      status: 'In Progress',
      priority: 'Urgent',
      dueDate: DateTime(2026, 8, 13),
      progress: 0.40,
      color: Colors.red,
    ),
  ];

  // ================================================================
  // ALL TASKS
  // ================================================================

  List<TaskModel> get tasks {
    return List.unmodifiable(_tasks);
  }

  // ================================================================
  // COUNTS
  // ================================================================

  int get taskCount {
    return _tasks.length;
  }

  Future<void> loadTasks({String? projectCode}) async {
    if (AuthRepository.instance.usesApiAuth) {
      _tasks.clear();
      notifyListeners();
      final user = AuthRepository.instance.currentUser;
      if (user == null || user.organizationId.isEmpty) {
        throw const AuthApiException(
          'An authenticated company is required.',
          statusCode: 401,
        );
      }
      try {
        final loadedTasks = await ApiAuthClient.configured.listTasks(
          organizationId: user.organizationId,
          projectCode: projectCode,
        );
        _tasks
          ..clear()
          ..addAll(loadedTasks);
        notifyListeners();
        return;
      } on AuthApiException catch (error) {
        if (error.statusCode == 401) {
          await AuthRepository.instance.signOut();
        }
        rethrow;
      }
    }

    final preferences = await SharedPreferences.getInstance();
    final savedTasks = preferences.getString(_storageKey);

    if (savedTasks == null) {
      return;
    }

    try {
      final decoded = jsonDecode(savedTasks) as List<dynamic>;
      final restoredTasks = decoded
          .map(
            (task) =>
                TaskModel.fromJson(Map<String, dynamic>.from(task as Map)),
          )
          .toList();

      _tasks
        ..clear()
        ..addAll(restoredTasks);

      notifyListeners();
    } catch (_) {
      // Keep the bundled sample tasks if saved data cannot be restored.
    }
  }

  Future<void> createTask(TaskModel task) async {
    if (AuthRepository.instance.usesApiAuth) {
      final user = AuthRepository.instance.currentUser;
      if (user == null || user.organizationId.isEmpty) {
        throw const AuthApiException(
          'An authenticated company is required.',
          statusCode: 401,
        );
      }
      late final TaskModel created;
      try {
        created = await ApiAuthClient.configured.createTask(
          organizationId: user.organizationId,
          projectCode: task.projectCode,
          title: task.title,
          description: task.description,
          priority: task.priority,
          dueDate: task.dueDate,
          assignedUserId: task.assignedUserId,
        );
      } on AuthApiException catch (error) {
        if (error.statusCode == 401) {
          await AuthRepository.instance.signOut();
        }
        rethrow;
      }
      _tasks.removeWhere((existing) => existing.id == created.id);
      _tasks.add(created);
      notifyListeners();
      return;
    }
    addTask(task);
  }

  Future<TaskModel> loadTask(String id) async {
    if (!AuthRepository.instance.usesApiAuth) {
      final task = getTaskById(id);
      if (task == null) {
        throw const AuthApiException('Task not found.', statusCode: 404);
      }
      return task;
    }
    final user = AuthRepository.instance.currentUser;
    if (user == null || user.organizationId.isEmpty) {
      throw const AuthApiException(
        'An authenticated company is required.',
        statusCode: 401,
      );
    }
    try {
      final task = await ApiAuthClient.configured.getTask(
        organizationId: user.organizationId,
        taskId: id,
      );
      _replaceTask(task);
      return task;
    } on AuthApiException catch (error) {
      if (error.statusCode == 401) {
        await AuthRepository.instance.signOut();
      }
      rethrow;
    }
  }

  Future<List<ProjectMemberModel>> listProjectMembers(
    String projectIdentifier,
  ) async {
    final user = AuthRepository.instance.currentUser;
    if (!AuthRepository.instance.usesApiAuth ||
        user == null ||
        user.organizationId.isEmpty) {
      throw const AuthApiException(
        'An authenticated company is required.',
        statusCode: 401,
      );
    }
    try {
      return await ApiAuthClient.configured.listProjectMembers(
        organizationId: user.organizationId,
        projectIdentifier: projectIdentifier,
      );
    } on AuthApiException catch (error) {
      if (error.statusCode == 401) {
        await AuthRepository.instance.signOut();
      }
      rethrow;
    }
  }

  Future<TaskModel> saveTask(TaskModel task) async {
    if (!AuthRepository.instance.usesApiAuth) {
      updateTask(task);
      return task;
    }
    final user = AuthRepository.instance.currentUser;
    if (user == null || user.organizationId.isEmpty) {
      throw const AuthApiException(
        'An authenticated company is required.',
        statusCode: 401,
      );
    }
    try {
      final updated = await ApiAuthClient.configured.updateTask(
        organizationId: user.organizationId,
        task: task,
      );
      _replaceTask(updated);
      return updated;
    } on AuthApiException catch (error) {
      if (error.statusCode == 401) {
        await AuthRepository.instance.signOut();
      }
      rethrow;
    }
  }

  void _replaceTask(TaskModel task) {
    final index = _tasks.indexWhere((existing) => existing.id == task.id);
    if (index == -1) {
      _tasks.add(task);
    } else {
      _tasks[index] = task;
    }
    notifyListeners();
  }

  Future<void> _saveTasks() async {
    final preferences = await SharedPreferences.getInstance();
    final encodedTasks = jsonEncode(
      _tasks.map((task) => task.toJson()).toList(),
    );

    await preferences.setString(_storageKey, encodedTasks);
  }

  String get nextTaskId {
    var highestNumber = 0;

    for (final task in _tasks) {
      final match = RegExp(r'^TSK-(\d+)$').firstMatch(task.id);
      final number = int.tryParse(match?.group(1) ?? '');

      if (number != null && number > highestNumber) {
        highestNumber = number;
      }
    }

    return 'TSK-${(highestNumber + 1).toString().padLeft(3, '0')}';
  }

  int get toDoCount {
    return _tasks.where((task) => task.status == 'To Do').length;
  }

  int get inProgressCount {
    return _tasks.where((task) => task.status == 'In Progress').length;
  }

  int get reviewCount {
    return _tasks.where((task) => task.status == 'Review').length;
  }

  int get completedCount {
    return _tasks.where((task) => task.status == 'Done').length;
  }

  int get urgentCount {
    return _tasks.where((task) => task.priority == 'Urgent').length;
  }

  // ================================================================
  // GET TASK
  // ================================================================

  TaskModel? getTaskById(String id) {
    for (final task in _tasks) {
      if (task.id == id) {
        return task;
      }
    }

    return null;
  }

  // ================================================================
  // ADD TASK
  // ================================================================

  void addTask(TaskModel task) {
    _tasks.add(task);

    _saveTasks();
    notifyListeners();
  }

  // ================================================================
  // UPDATE TASK
  // ================================================================

  void updateTask(TaskModel updatedTask) {
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);

    if (index == -1) {
      return;
    }

    _tasks[index] = updatedTask;

    _saveTasks();
    notifyListeners();
  }

  // ================================================================
  // DELETE TASK
  // ================================================================

  void deleteTask(String id) {
    _tasks.removeWhere((task) => task.id == id);

    _saveTasks();
    notifyListeners();
  }

  // ================================================================
  // TASKS BY PROJECT
  // ================================================================

  List<TaskModel> getTasksByProject(String projectCode) {
    return _tasks.where((task) => task.projectCode == projectCode).toList();
  }

  // ================================================================
  // TASKS BY STATUS
  // ================================================================

  List<TaskModel> getTasksByStatus(String status) {
    return _tasks.where((task) => task.status == status).toList();
  }

  // ================================================================
  // TASKS BY PRIORITY
  // ================================================================

  List<TaskModel> getTasksByPriority(String priority) {
    return _tasks.where((task) => task.priority == priority).toList();
  }
}
