import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:structflow/features/attendance/models/attendance_permission_model.dart';
import 'package:structflow/features/attendance/repositories/attendance_permission_repository.dart';
import 'package:structflow/features/auth/repositories/auth_repository.dart';
import 'package:structflow/features/projects/repositories/project_repository.dart';
import 'package:structflow/features/tasks/repositories/task_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('project repository restores saved projects', () async {
    SharedPreferences.setMockInitialValues({
      'structflow_projects': jsonEncode([
        {
          'id': 'PERSISTED-1',
          'name': 'Saved project',
          'code': 'SAVED-001',
          'organizationId': 'ORG-1',
          'projectType': 'Commercial',
          'client': 'Client',
          'location': 'Cairo',
          'status': 'Active',
          'progress': 0.5,
          'budget': '100K',
          'team': 4,
          'color': 0xFF0000FF,
          'iconCodePoint': 0xe3af,
        },
      ]),
    });

    await ProjectRepository.instance.loadProjects();

    expect(ProjectRepository.instance.projects, hasLength(1));
    expect(
      ProjectRepository.instance.getProjectByCode('SAVED-001')?.name,
      'Saved project',
    );
  });

  test('task repository restores saved tasks', () async {
    SharedPreferences.setMockInitialValues({
      'structflow_tasks': jsonEncode([
        {
          'id': 'SAVED-TASK-1',
          'title': 'Saved task',
          'description': 'Persisted task',
          'projectCode': 'SAVED-001',
          'projectName': 'Saved project',
          'assignee': 'Engineer',
          'status': 'To Do',
          'priority': 'High',
          'dueDate': DateTime(2026, 12, 1).toIso8601String(),
          'progress': 0.0,
          'color': 0xFF0000FF,
        },
      ]),
    });

    await TaskRepository.instance.loadTasks();

    expect(TaskRepository.instance.tasks, hasLength(1));
    expect(
      TaskRepository.instance.getTaskById('SAVED-TASK-1')?.title,
      'Saved task',
    );
  });

  test(
    'bootstrapping a missing permission does not require an actor record',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = AttendancePermissionRepository.instance;
      const organizationId = 'ORG-BOOTSTRAP-TEST';
      const userId = 'USER-BOOTSTRAP-TEST';

      await repository.ensureUserPermission(
        permission: AttendancePermissionModel(
          id: 'PERM-$userId',
          organizationId: organizationId,
          userId: userId,
          role: 'Employee',
          locationAttendanceEnabled: true,
          updatedAt: DateTime(2026),
        ),
      );

      expect(
        repository.getForUser(organizationId: organizationId, userId: userId),
        isNotNull,
      );
    },
  );

  test(
    'users cannot escalate another user role or delete colleagues',
    () async {
      SharedPreferences.setMockInitialValues({});
      final auth = AuthRepository.instance;
      await auth.load();
      await auth.setupOwner(
        name: 'Company Owner',
        email: 'owner@example.com',
        password: 'owner-password',
        organization: 'Test Company',
      );
      final ownerId = auth.currentUser!.id;

      await auth.register(
        name: 'Employee One',
        email: 'employee-one@example.com',
        password: 'employee-password',
        role: 'Employee',
        organization: 'Test Company',
      );
      await auth.register(
        name: 'Employee Two',
        email: 'employee-two@example.com',
        password: 'employee-password',
        role: 'Employee',
        organization: 'Test Company',
      );
      final firstEmployeeId = auth.users
          .singleWhere((user) => user.email == 'employee-one@example.com')
          .id;
      final secondEmployeeId = auth.users
          .singleWhere((user) => user.email == 'employee-two@example.com')
          .id;

      expect(
        await auth.approveUser(
          actorUserId: ownerId,
          userId: firstEmployeeId,
          role: 'Employee',
        ),
        isTrue,
      );
      expect(
        await auth.approveUser(
          actorUserId: ownerId,
          userId: secondEmployeeId,
          role: 'Employee',
        ),
        isTrue,
      );

      expect(
        await auth.updateUser(
          actorUserId: firstEmployeeId,
          userId: secondEmployeeId,
          role: 'Consultant Manager',
          status: 'Approved',
        ),
        isFalse,
      );
      expect(
        await auth.rejectUser(
          actorUserId: firstEmployeeId,
          userId: secondEmployeeId,
        ),
        isFalse,
      );
      expect(
        await auth.deleteUser(
          actorUserId: firstEmployeeId,
          userId: secondEmployeeId,
        ),
        isFalse,
      );

      expect(
        await auth.updateUser(
          actorUserId: ownerId,
          userId: firstEmployeeId,
          role: 'Consultant Manager',
        ),
        isTrue,
      );
      expect(
        await auth.updateUser(
          actorUserId: firstEmployeeId,
          userId: secondEmployeeId,
          role: 'Consultant Manager',
        ),
        isFalse,
      );
    },
  );
}
