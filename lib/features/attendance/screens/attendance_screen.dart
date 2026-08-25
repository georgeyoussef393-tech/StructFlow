import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:structflow/core/theme/app_colors.dart';
import 'package:structflow/features/attendance/models/attendance_record_model.dart';
import 'package:structflow/features/attendance/repositories/attendance_repository.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final AttendanceRepository _repository = AttendanceRepository.instance;
  final _organizationController = TextEditingController();
  final _projectController = TextEditingController();
  final _userController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _repository.addListener(_onChanged);
  }

  @override
  void dispose() {
    _repository.removeListener(_onChanged);
    _organizationController.dispose();
    _projectController.dispose();
    _userController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _submit({required bool checkIn}) async {
    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());
    if (_organizationController.text.trim().isEmpty ||
        _projectController.text.trim().isEmpty ||
        _userController.text.trim().isEmpty ||
        latitude == null ||
        longitude == null) {
      _showMessage('Complete the organization, project, employee, and location fields.');
      return;
    }

    setState(() => _isSaving = true);
    final record = checkIn
        ? await _repository.checkIn(
            organizationId: _organizationController.text.trim(),
            projectId: _projectController.text.trim(),
            userId: _userController.text.trim(),
            latitude: latitude,
            longitude: longitude,
          )
        : await _repository.checkOut(
            organizationId: _organizationController.text.trim(),
            projectId: _projectController.text.trim(),
            userId: _userController.text.trim(),
            latitude: latitude,
            longitude: longitude,
          );
    if (!mounted) return;
    setState(() => _isSaving = false);
    _showMessage(
      record == null
          ? 'Attendance was not recorded. Confirm location attendance is enabled and you are inside the project geofence.'
          : checkIn
              ? 'Check-in recorded successfully.'
              : 'Check-out recorded successfully.',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final records = _repository.records.reversed.toList();
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Attendance management',
            icon: const Icon(Icons.admin_panel_settings_rounded),
            onPressed: () => context.go('/attendance-management'),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.all(constraints.maxWidth < 600 ? 16 : 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Check in to your project',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your location must be inside the enabled project geofence.',
                      style: TextStyle(color: AppColors.textLight),
                    ),
                    const SizedBox(height: 20),
                    _buildForm(),
                    const SizedBox(height: 28),
                    const Text(
                      'Attendance records',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 12),
                    if (records.isEmpty)
                      _buildEmptyState()
                    else
                      ...records.map(_buildRecordCard),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: Column(
          children: [
            _field(_organizationController, 'Organization ID', Icons.business_rounded),
            const SizedBox(height: 12),
            _field(_projectController, 'Project ID', Icons.folder_rounded),
            const SizedBox(height: 12),
            _field(_userController, 'Employee ID', Icons.person_rounded),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field(_latitudeController, 'Latitude', Icons.my_location_rounded, number: true)),
                const SizedBox(width: 12),
                Expanded(child: _field(_longitudeController, 'Longitude', Icons.my_location_rounded, number: true)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : () => _submit(checkIn: false),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Check out'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : () => _submit(checkIn: true),
                    icon: const Icon(Icons.login_rounded),
                    label: Text(_isSaving ? 'Saving...' : 'Check in'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _field(TextEditingController controller, String label, IconData icon, {bool number = false}) => TextField(
        controller: controller,
        keyboardType: number ? const TextInputType.numberWithOptions(decimal: true, signed: true) : TextInputType.text,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder()),
      );

  Widget _buildEmptyState() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: const Column(
          children: [
            Icon(Icons.event_available_outlined, size: 40, color: AppColors.textLight),
            SizedBox(height: 10),
            Text('No attendance records yet.', style: TextStyle(color: AppColors.textLight)),
          ],
        ),
      );

  Widget _buildRecordCard(AttendanceRecordModel record) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: record.isOpen ? Colors.green.withValues(alpha: .12) : Colors.blue.withValues(alpha: .12),
            child: Icon(record.isOpen ? Icons.login_rounded : Icons.task_alt_rounded, color: record.isOpen ? Colors.green : Colors.blue),
          ),
          title: Text('${record.userId} · ${record.projectId}'),
          subtitle: Text('In: ${_formatDate(record.checkInAt)}${record.isOpen ? '' : '  •  Out: ${_formatDate(record.checkOutAt!)}'}'),
          trailing: Text(record.isOpen ? 'Checked in' : 'Completed', style: TextStyle(color: record.isOpen ? Colors.green : Colors.blue, fontWeight: FontWeight.w600)),
        ),
      );

  String _formatDate(DateTime value) => '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
