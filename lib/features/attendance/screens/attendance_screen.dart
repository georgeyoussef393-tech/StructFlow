import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import 'package:structflow/core/theme/app_colors.dart';
import 'package:structflow/features/attendance/models/attendance_context_model.dart';
import 'package:structflow/features/attendance/models/attendance_record_model.dart';
import 'package:structflow/features/attendance/repositories/attendance_context_repository.dart';
import 'package:structflow/features/attendance/repositories/attendance_permission_repository.dart';
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
  bool _isGettingLocation = false;

  String _recordFilter = 'All';

  @override
  void initState() {
    super.initState();

    _repository.addListener(_onChanged);

    _loadContext();
  }

  void _loadContext() {
    final saved = AttendanceContextRepository.instance.context;

    _organizationController.text = saved.organizationId;
    _projectController.text = saved.projectId;
    _userController.text = saved.userId;
    _latitudeController.text = saved.latitude?.toString() ?? '';
    _longitudeController.text = saved.longitude?.toString() ?? '';
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
    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // CURRENT PERMISSION
  // ============================================================

  bool get _canManageAttendance {
    final permission = AttendancePermissionRepository.instance.getForUser(
      organizationId: _organizationController.text.trim(),
      userId: _userController.text.trim(),
    );

    return permission?.canManageUsers ?? false;
  }

  // ============================================================
  // CURRENT LOCATION
  // ============================================================

  Future<void> _useCurrentLocation() async {
    if (_isGettingLocation) return;

    setState(() {
      _isGettingLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showMessage(
          'Location services are turned off. Please enable GPS and try again.',
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showMessage(
          'Location permission was denied.',
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage(
          'Location permission is permanently denied. Please enable it from device settings.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _latitudeController.text = position.latitude.toStringAsFixed(7);
      _longitudeController.text = position.longitude.toStringAsFixed(7);

      if (mounted) {
        setState(() {});
      }

      _showMessage(
        'Current GPS location loaded successfully.',
      );
    } catch (e) {
      _showMessage(
        'Unable to get your current location. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  String? _validateBasicFields() {
    if (_organizationController.text.trim().isEmpty) {
      return 'Organization ID is required.';
    }

    if (_projectController.text.trim().isEmpty) {
      return 'Project ID is required.';
    }

    if (_userController.text.trim().isEmpty) {
      return 'Employee ID is required.';
    }

    final latitude = double.tryParse(
      _latitudeController.text.trim(),
    );

    final longitude = double.tryParse(
      _longitudeController.text.trim(),
    );

    if (latitude == null || longitude == null) {
      return 'A valid GPS location is required.';
    }

    if (latitude < -90 || latitude > 90) {
      return 'Invalid latitude.';
    }

    if (longitude < -180 || longitude > 180) {
      return 'Invalid longitude.';
    }

    return null;
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _submit({
    required bool checkIn,
  }) async {
    final validationMessage = _validateBasicFields();

    if (validationMessage != null) {
      _showMessage(validationMessage);
      return;
    }

    final organizationId = _organizationController.text.trim();
    final projectId = _projectController.text.trim();
    final userId = _userController.text.trim();

    final latitude = double.parse(
      _latitudeController.text.trim(),
    );

    final longitude = double.parse(
      _longitudeController.text.trim(),
    );

    final permission = AttendancePermissionRepository.instance.getForUser(
      organizationId: organizationId,
      userId: userId,
    );

    if (permission == null) {
      _showMessage(
        'No attendance permission was found for this employee.',
      );
      return;
    }

    if (!permission.locationAttendanceEnabled) {
      _showMessage(
        'Location attendance is not enabled for this employee.',
      );
      return;
    }

    if (!permission.canAccessProject(projectId)) {
      _showMessage(
        'This employee does not have access to the selected project.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await AttendanceContextRepository.instance.save(
        AttendanceContextModel(
          organizationId: organizationId,
          projectId: projectId,
          userId: userId,
          latitude: latitude,
          longitude: longitude,
        ),
      );

      final record = checkIn
          ? await _repository.checkIn(
              organizationId: organizationId,
              projectId: projectId,
              userId: userId,
              latitude: latitude,
              longitude: longitude,
            )
          : await _repository.checkOut(
              organizationId: organizationId,
              projectId: projectId,
              userId: userId,
              latitude: latitude,
              longitude: longitude,
            );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      if (record == null) {
        _showMessage(
          checkIn
              ? 'Check-in failed. You may be outside the project geofence, or no active geofence is configured.'
              : 'Check-out failed. You may be outside the project geofence, or there is no open attendance record.',
        );
        return;
      }

      _showMessage(
        checkIn
            ? 'Check-in recorded successfully.'
            : 'Check-out recorded successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        'Attendance could not be recorded. Please try again.',
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final records = _visibleRecords();

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back to Dashboard',
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
          onPressed: () {
            context.go('/');
          },
        ),
        actions: [
          if (_canManageAttendance)
            IconButton(
              tooltip: 'Attendance management',
              icon: const Icon(
                Icons.admin_panel_settings_rounded,
              ),
              onPressed: () {
                context.go(
                  '/attendance-management',
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(
                constraints.maxWidth < 600 ? 16 : 28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 920,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Check in to your project',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your location must be inside the enabled project geofence.',
                        style: TextStyle(
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildForm(),
                      const SizedBox(height: 28),
                      const Text(
                        'Attendance records',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSummary(records),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'All',
                            label: Text('All'),
                          ),
                          ButtonSegment(
                            value: 'Mine',
                            label: Text('Mine'),
                          ),
                          ButtonSegment(
                            value: 'Open',
                            label: Text('Open'),
                          ),
                        ],
                        selected: {
                          _recordFilter,
                        },
                        onSelectionChanged: (selection) {
                          setState(() {
                            _recordFilter = selection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      if (records.isEmpty)
                        _buildEmptyState()
                      else
                        ...records.map(
                          _buildRecordCard,
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

  // ============================================================
  // FORM
  // ============================================================

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _field(
            _organizationController,
            'Organization ID',
            Icons.business_rounded,
            readOnly: true,
          ),
          const SizedBox(height: 12),
          _field(
            _projectController,
            'Project ID',
            Icons.folder_rounded,
          ),
          const SizedBox(height: 12),
          _field(
            _userController,
            'Employee ID',
            Icons.person_rounded,
            readOnly: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _field(
                  _latitudeController,
                  'Latitude',
                  Icons.my_location_rounded,
                  number: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  _longitudeController,
                  'Longitude',
                  Icons.my_location_rounded,
                  number: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isGettingLocation || _isSaving
                  ? null
                  : _useCurrentLocation,
              icon: _isGettingLocation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.gps_fixed_rounded,
                    ),
              label: Text(
                _isGettingLocation
                    ? 'Getting GPS location...'
                    : 'Use my current location',
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Use GPS to get the employee device location before checking in or out.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _saveContext,
              icon: const Icon(
                Icons.bookmark_add_outlined,
              ),
              label: const Text(
                'Save attendance profile',
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () => _submit(
                            checkIn: false,
                          ),
                  icon: const Icon(
                    Icons.logout_rounded,
                  ),
                  label: const Text(
                    'Check out',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () => _submit(
                            checkIn: true,
                          ),
                  icon: const Icon(
                    Icons.login_rounded,
                  ),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Check in',
                  ),
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
  }

  // ============================================================
  // SAVE CONTEXT
  // ============================================================

  Future<void> _saveContext() async {
    final validationMessage = _validateBasicFields();

    if (validationMessage != null) {
      _showMessage(
        validationMessage,
      );
      return;
    }

    final latitude = double.parse(
      _latitudeController.text.trim(),
    );

    final longitude = double.parse(
      _longitudeController.text.trim(),
    );

    await AttendanceContextRepository.instance.save(
      AttendanceContextModel(
        organizationId: _organizationController.text.trim(),
        projectId: _projectController.text.trim(),
        userId: _userController.text.trim(),
        latitude: latitude,
        longitude: longitude,
      ),
    );

    _showMessage(
      'Attendance profile saved.',
    );
  }

  // ============================================================
  // FIELD
  // ============================================================

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool number = false,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: number
          ? const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            )
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: readOnly,
        fillColor: readOnly
            ? const Color(0xffF3F5F8)
            : null,
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 40,
            color: AppColors.textLight,
          ),
          SizedBox(height: 10),
          Text(
            'No attendance records yet.',
            style: TextStyle(
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECORD CARD
  // ============================================================

  Widget _buildRecordCard(
    AttendanceRecordModel record,
  ) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: record.isOpen
              ? Colors.green.withValues(alpha: .12)
              : Colors.blue.withValues(alpha: .12),
          child: Icon(
            record.isOpen
                ? Icons.login_rounded
                : Icons.task_alt_rounded,
            color: record.isOpen
                ? Colors.green
                : Colors.blue,
          ),
        ),
        title: Text(
          '${record.userId} · ${record.projectId}',
        ),
        subtitle: Text(
          'In: ${_formatDate(record.checkInAt)}'
          '${record.isOpen ? '' : '  •  Out: ${_formatDate(record.checkOutAt!)}'}',
        ),
        trailing: Text(
          record.isOpen
              ? 'Checked in'
              : 'Completed',
          style: TextStyle(
            color: record.isOpen
                ? Colors.green
                : Colors.blue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // VISIBLE RECORDS
  // ============================================================

  List<AttendanceRecordModel> _visibleRecords() {
    final userId = _userController.text.trim();

    return _repository.records.reversed.where((record) {
      if (_recordFilter == 'Mine' &&
          record.userId != userId) {
        return false;
      }

      if (_recordFilter == 'Open' &&
          !record.isOpen) {
        return false;
      }

      return true;
    }).toList();
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary(
    List<AttendanceRecordModel> records,
  ) {
    final open = records.where(
      (record) => record.isOpen,
    ).length;

    final completed = records.length - open;

    return Row(
      children: [
        Expanded(
          child: _metric(
            'Total',
            records.length,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metric(
            'Open',
            open,
            Colors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metric(
            'Completed',
            completed,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // METRIC
  // ============================================================

  Widget _metric(
    String label,
    int value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(DateTime value) {
    return '${value.year}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.day.toString().padLeft(2, '0')} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}