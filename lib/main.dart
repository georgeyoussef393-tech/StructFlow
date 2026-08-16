import 'package:flutter/material.dart';

import 'app.dart';
import 'package:structflow/features/documents/repositories/document_repository.dart';
import 'package:structflow/features/projects/repositories/project_repository.dart';
import 'package:structflow/features/tasks/repositories/task_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    ProjectRepository.instance.loadProjects(),
    TaskRepository.instance.loadTasks(),
    DocumentRepository.instance.loadDocuments(),
  ]);

  runApp(const StructFlowApp());
}