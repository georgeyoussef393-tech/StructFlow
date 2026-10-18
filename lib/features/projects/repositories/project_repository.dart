import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_auth_client.dart';
import '../../auth/repositories/auth_repository.dart';
import 'package:structflow/features/projects/models/project_model.dart';

class ProjectRepository extends ChangeNotifier {
  static const _storageKey = 'structflow_projects';
  ProjectRepository._internal();

  static final ProjectRepository instance = ProjectRepository._internal();

  final List<ProjectModel> _projects = [
    const ProjectModel(
      name: 'New Capital Tower',
      code: 'PRJ-001',
      client: 'Capital Development Group',
      location: 'New Capital',
      status: 'Active',
      progress: 0.82,
      budget: '\$850K',
      team: 24,
      color: Colors.green,
      icon: Icons.apartment_rounded,
    ),

    const ProjectModel(
      name: 'Cairo Business Park',
      code: 'PRJ-002',
      client: 'Cairo Business Group',
      location: 'New Cairo',
      status: 'Active',
      progress: 0.64,
      budget: '\$620K',
      team: 18,
      color: Colors.orange,
      icon: Icons.business_rounded,
    ),

    const ProjectModel(
      name: 'Smart Village',
      code: 'PRJ-003',
      client: 'Smart Village Company',
      location: '6th October',
      status: 'On Hold',
      progress: 0.39,
      budget: '\$480K',
      team: 15,
      color: Colors.red,
      icon: Icons.location_city_rounded,
    ),

    const ProjectModel(
      name: 'Alex Mall',
      code: 'PRJ-004',
      client: 'Alexandria Retail',
      location: 'Alexandria',
      status: 'Active',
      progress: 0.95,
      budget: '\$920K',
      team: 31,
      color: Colors.blue,
      icon: Icons.storefront_rounded,
    ),

    const ProjectModel(
      name: 'Sokhna Resort',
      code: 'PRJ-005',
      client: 'Sokhna Developments',
      location: 'Ain Sokhna',
      status: 'Planning',
      progress: 0.18,
      budget: '\$350K',
      team: 9,
      color: Colors.purple,
      icon: Icons.hotel_rounded,
    ),

    const ProjectModel(
      name: 'Tuban Villas',
      code: 'PRJ-006',
      client: 'Tuban Properties',
      location: 'Cairo',
      status: 'Active',
      progress: 0.71,
      budget: '\$560K',
      team: 21,
      color: Colors.teal,
      icon: Icons.villa_rounded,
    ),
  ];

  // ================================================================
  // GET ALL PROJECTS
  // ================================================================

  List<ProjectModel> get projects {
    return List.unmodifiable(_projects);
  }

  Future<void> loadProjects() async {
    if (AuthRepository.instance.usesApiAuth) {
      _projects.clear();
      notifyListeners();
      final user = AuthRepository.instance.currentUser;
      if (user == null || user.organizationId.isEmpty) {
        throw StateError('An authenticated company is required.');
      }
      late final List<ProjectModel> loadedProjects;
      try {
        loadedProjects = await ApiAuthClient.configured.listProjects(
          organizationId: user.organizationId,
        );
      } on AuthApiException catch (error) {
        if (error.statusCode == 401) {
          await AuthRepository.instance.signOut();
        }
        rethrow;
      }
      _projects
        ..clear()
        ..addAll(loadedProjects);
      notifyListeners();
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    final savedProjects = preferences.getString(_storageKey);

    if (savedProjects == null) {
      return;
    }

    try {
      final decoded = jsonDecode(savedProjects) as List<dynamic>;
      final restoredProjects = decoded
          .map(
            (project) => ProjectModel.fromJson(
              Map<String, dynamic>.from(project as Map),
            ),
          )
          .toList();

      _projects
        ..clear()
        ..addAll(restoredProjects);

      notifyListeners();
    } catch (_) {
      // Keep the bundled sample projects if saved data cannot be restored.
    }
  }

  Future<ProjectModel> createProject(ProjectModel project) async {
    if (AuthRepository.instance.usesApiAuth) {
      final user = AuthRepository.instance.currentUser;
      if (user == null || user.organizationId.isEmpty) {
        throw StateError('An authenticated company is required.');
      }
      late final ProjectModel createdProject;
      try {
        createdProject = await ApiAuthClient.configured.createProject(
          organizationId: user.organizationId,
          project: project,
        );
      } on AuthApiException catch (error) {
        if (error.statusCode == 401) {
          await AuthRepository.instance.signOut();
        }
        rethrow;
      }
      _projects.insert(0, createdProject);
      notifyListeners();
      return createdProject;
    }

    addProject(project);
    return project;
  }

  Future<ProjectModel> loadProject(String projectIdentifier) async {
    if (!AuthRepository.instance.usesApiAuth) {
      ProjectModel? project;
      for (final candidate in _projects) {
        if (candidate.code == projectIdentifier ||
            candidate.id == projectIdentifier) {
          project = candidate;
          break;
        }
      }
      if (project == null) {
        throw StateError('Project not found.');
      }
      return project;
    }

    final user = AuthRepository.instance.currentUser;
    if (user == null || user.organizationId.isEmpty) {
      throw StateError('An authenticated company is required.');
    }
    try {
      return await ApiAuthClient.configured.getProject(
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

  Future<void> _saveProjects() async {
    final preferences = await SharedPreferences.getInstance();
    final encodedProjects = jsonEncode(
      _projects.map((project) => project.toJson()).toList(),
    );

    await preferences.setString(_storageKey, encodedProjects);
  }

  // ================================================================
  // GET PROJECT BY CODE
  // ================================================================

  ProjectModel? getProjectByCode(String code) {
    try {
      return _projects.firstWhere((project) => project.code == code);
    } catch (_) {
      return null;
    }
  }

  // ================================================================
  // ADD PROJECT
  // ================================================================

  void addProject(ProjectModel project) {
    _projects.add(project);

    _saveProjects();
    notifyListeners();
  }

  // ================================================================
  // UPDATE PROJECT
  // ================================================================

  Future<ProjectModel?> updateProject(ProjectModel updatedProject) async {
    if (AuthRepository.instance.usesApiAuth) {
      final user = AuthRepository.instance.currentUser;
      if (user == null || user.organizationId.isEmpty) {
        throw StateError('An authenticated company is required.');
      }
      try {
        final savedProject = await ApiAuthClient.configured.updateProject(
          organizationId: user.organizationId,
          project: updatedProject,
        );
        final index = _projects.indexWhere(
          (project) => project.id == savedProject.id,
        );
        if (index != -1) {
          _projects[index] = savedProject;
          notifyListeners();
        }
        return savedProject;
      } on AuthApiException catch (error) {
        if (error.statusCode == 401) {
          await AuthRepository.instance.signOut();
        }
        rethrow;
      }
    }

    final index = _projects.indexWhere(
      (project) => project.code == updatedProject.code,
    );

    if (index == -1) {
      return null;
    }

    _projects[index] = updatedProject;

    _saveProjects();
    notifyListeners();
    return updatedProject;
  }

  // ================================================================
  // DELETE PROJECT
  // ================================================================

  void deleteProject(String code) {
    _projects.removeWhere((project) => project.code == code);

    _saveProjects();
    notifyListeners();
  }

  // ================================================================
  // CHECK PROJECT CODE
  // ================================================================

  bool codeExists(String code) {
    return _projects.any((project) => project.code == code);
  }

  // ================================================================
  // PROJECT COUNT
  // ================================================================

  int get projectCount {
    return _projects.length;
  }

  // ================================================================
  // ACTIVE PROJECT COUNT
  // ================================================================

  int get activeProjectCount {
    return _projects.where((project) => project.status == 'Active').length;
  }

  // ================================================================
  // PLANNING PROJECT COUNT
  // ================================================================

  int get planningProjectCount {
    return _projects.where((project) => project.status == 'Planning').length;
  }

  // ================================================================
  // ON HOLD PROJECT COUNT
  // ================================================================

  int get onHoldProjectCount {
    return _projects.where((project) => project.status == 'On Hold').length;
  }
}
