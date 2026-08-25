import 'package:flutter/material.dart';

import 'package:structflow/core/theme/app_colors.dart';
import 'package:structflow/features/attendance/models/attendance_permission_model.dart';
import 'package:structflow/features/attendance/models/project_geofence_model.dart';
import 'package:structflow/features/attendance/repositories/attendance_permission_repository.dart';
import 'package:structflow/features/attendance/repositories/project_geofence_repository.dart';

class AttendanceManagementScreen extends StatefulWidget {
  const AttendanceManagementScreen({super.key});

  @override
  State<AttendanceManagementScreen> createState() => _AttendanceManagementScreenState();
}

class _AttendanceManagementScreenState extends State<AttendanceManagementScreen> {
  final _organization = TextEditingController();
  final _admin = TextEditingController();
  final _user = TextEditingController();
  final _projects = TextEditingController();
  final _project = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _radius = TextEditingController(text: '100');
  String _role = 'Employee';
  bool _locationEnabled = true;
  bool _geofenceEnabled = true;

  @override
  void dispose() {
    for (final controller in [_organization, _admin, _user, _projects, _project, _latitude, _longitude, _radius]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _bootstrapAdmin() async {
    if (!_required([_organization, _admin])) return;
    await AttendancePermissionRepository.instance.seedSuperAdmin(
      AttendancePermissionModel.superAdmin(
        id: 'ATT-PERM-${_admin.text.trim()}',
        organizationId: _organization.text.trim(),
        userId: _admin.text.trim(),
      ),
    );
    _message('Super Admin access is ready.');
  }

  Future<void> _savePermission() async {
    if (!_required([_organization, _admin, _user])) return;
    final projects = _projects.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    final permission = AttendancePermissionModel(
      id: 'ATT-PERM-${_user.text.trim()}',
      organizationId: _organization.text.trim(),
      userId: _user.text.trim(),
      role: _role,
      locationAttendanceEnabled: _locationEnabled,
      canManageProjectGeofences: _role == 'Project Manager',
      canViewProjectAttendance: _role == 'Project Manager',
      canViewOrganizationAttendance: _role == 'HR Manager',
      managedProjectIds: projects,
      updatedAt: DateTime.now(),
    );
    final saved = await AttendancePermissionRepository.instance.save(
      actorUserId: _admin.text.trim(),
      permission: permission,
    );
    _message(saved ? 'Attendance permission saved.' : 'Only the organization Super Admin can change permissions.');
  }

  Future<void> _saveGeofence() async {
    if (!_required([_organization, _admin, _project, _latitude, _longitude, _radius])) return;
    final latitude = double.tryParse(_latitude.text.trim());
    final longitude = double.tryParse(_longitude.text.trim());
    final radius = double.tryParse(_radius.text.trim());
    if (latitude == null || longitude == null || radius == null || radius <= 0) {
      _message('Enter a valid latitude, longitude, and radius.');
      return;
    }
    final saved = await ProjectGeofenceRepository.instance.save(
      actorUserId: _admin.text.trim(),
      geofence: ProjectGeofenceModel(
        id: 'GEOFENCE-${_project.text.trim()}',
        organizationId: _organization.text.trim(),
        projectId: _project.text.trim(),
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radius,
        attendanceEnabled: _geofenceEnabled,
        updatedByUserId: _admin.text.trim(),
        updatedAt: DateTime.now(),
      ),
    );
    _message(saved ? 'Project geofence saved.' : 'This user cannot manage this project geofence.');
  }

  bool _required(List<TextEditingController> controllers) {
    if (controllers.every((controller) => controller.text.trim().isNotEmpty)) return true;
    _message('Complete all required fields.');
    return false;
  }

  void _message(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xffF5F7FB),
        appBar: AppBar(title: const Text('Attendance Management'), backgroundColor: Colors.white, foregroundColor: AppColors.textDark),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Control access and project location rules', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 16),
            _card('Organization access', [
              _field(_organization, 'Organization ID'),
              _field(_admin, 'Super Admin user ID'),
              FilledButton.icon(onPressed: _bootstrapAdmin, icon: const Icon(Icons.admin_panel_settings_rounded), label: const Text('Initialize Super Admin')),
            ]),
            _card('User attendance permission', [
              _field(_user, 'User ID'),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                items: const ['Employee', 'Project Manager', 'HR Manager'].map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                onChanged: (value) => setState(() => _role = value ?? 'Employee'),
              ),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Enable location attendance'), value: _locationEnabled, onChanged: (value) => setState(() => _locationEnabled = value)),
              if (_role == 'Project Manager') _field(_projects, 'Managed project IDs (comma-separated)'),
              FilledButton.icon(onPressed: _savePermission, icon: const Icon(Icons.save_rounded), label: const Text('Save permission')),
            ]),
            _card('Project geofence', [
              _field(_project, 'Project ID'),
              Row(children: [Expanded(child: _field(_latitude, 'Latitude', number: true)), const SizedBox(width: 12), Expanded(child: _field(_longitude, 'Longitude', number: true))]),
              _field(_radius, 'Radius in meters', number: true),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Enable attendance for this project'), value: _geofenceEnabled, onChanged: (value) => setState(() => _geofenceEnabled = value)),
              FilledButton.icon(onPressed: _saveGeofence, icon: const Icon(Icons.location_on_rounded), label: const Text('Save geofence')),
            ]),
          ],
        ),
      );

  Widget _card(String title, List<Widget> children) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 14), ...children.map((child) => Padding(padding: const EdgeInsets.only(bottom: 12), child: child))]),
        ),
      );

  Widget _field(TextEditingController controller, String label, {bool number = false}) => TextField(
        controller: controller,
        keyboardType: number ? const TextInputType.numberWithOptions(decimal: true, signed: true) : TextInputType.text,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      );
}
