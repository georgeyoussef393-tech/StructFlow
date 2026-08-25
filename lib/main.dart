import 'package:flutter/material.dart';

import 'app.dart';
import 'package:structflow/features/documents/repositories/document_repository.dart';
import 'package:structflow/features/attendance/repositories/attendance_permission_repository.dart';
import 'package:structflow/features/attendance/repositories/attendance_repository.dart';
import 'package:structflow/features/attendance/repositories/project_geofence_repository.dart';
import 'package:structflow/features/projects/repositories/project_repository.dart';
import 'package:structflow/features/tasks/repositories/task_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    ProjectRepository.instance.loadProjects(),
    TaskRepository.instance.loadTasks(),
    DocumentRepository.instance.loadDocuments(),
    AttendancePermissionRepository.instance.load(),
    ProjectGeofenceRepository.instance.load(),
    AttendanceRepository.instance.load(),
  ]);

  runApp(const StructFlowApp());
}
