import 'package:flutter/material.dart';

import 'package:structflow/core/theme/app_colors.dart';
import 'package:structflow/features/attendance/models/attendance_record_model.dart';
import 'package:structflow/features/attendance/repositories/attendance_repository.dart';
import 'package:structflow/features/attendance/repositories/attendance_permission_repository.dart';

class EmployeeAttendanceScreen extends StatefulWidget {
  final String organizationId;
  final String projectId;
  final String userId;

  const EmployeeAttendanceScreen({
    super.key,
    required this.organizationId,
    required this.projectId,
    required this.userId,
  });

  @override
  State<EmployeeAttendanceScreen> createState() =>
      _EmployeeAttendanceScreenState();
}

class _EmployeeAttendanceScreenState
    extends State<EmployeeAttendanceScreen> {
  final AttendanceRepository _attendanceRepository =
      AttendanceRepository.instance;

  bool _loading = false;

  AttendanceRecordModel? get _activeRecord =>
      _attendanceRepository.activeRecordFor(
        userId: widget.userId,
        projectId: widget.projectId,
      );

  bool get _attendanceEnabled {
    final permission =
        AttendancePermissionRepository.instance.getForUser(
      organizationId: widget.organizationId,
      userId: widget.userId,
    );

    return permission?.locationAttendanceEnabled ?? false;
  }

  @override
  void initState() {
    super.initState();
    _attendanceRepository.addListener(_refresh);
  }

  @override
  void dispose() {
    _attendanceRepository.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _checkIn() async {
    if (!_attendanceEnabled) {
      _showMessage(
        'Location attendance is not enabled for this employee.',
        isError: true,
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    /*
     * Temporary coordinates for the UI/demo layer.
     *
     * Real GPS will replace these values when the location service
     * is connected.
     */
    const latitude = 30.0444;
    const longitude = 31.2357;

    final result = await _attendanceRepository.checkIn(
      organizationId: widget.organizationId,
      projectId: widget.projectId,
      userId: widget.userId,
      latitude: latitude,
      longitude: longitude,
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
    });

    if (result == null) {
      _showMessage(
        'Check-in failed. Make sure you are inside the project location.',
        isError: true,
      );
      return;
    }

    _showMessage('Check-in recorded successfully.');
  }

  Future<void> _checkOut() async {
    if (!_attendanceEnabled) {
      _showMessage(
        'Location attendance is not enabled.',
        isError: true,
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    const latitude = 30.0444;
    const longitude = 31.2357;

    final result = await _attendanceRepository.checkOut(
      organizationId: widget.organizationId,
      projectId: widget.projectId,
      userId: widget.userId,
      latitude: latitude,
      longitude: longitude,
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
    });

    if (result == null) {
      _showMessage(
        'Check-out failed. Make sure you are inside the project location.',
        isError: true,
      );
      return;
    }

    _showMessage('Check-out recorded successfully.');
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red : Colors.green,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final activeRecord = _activeRecord;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text('My Attendance'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 520,
              ),
              child: Column(
                children: [
                  _buildStatusCard(activeRecord),

                  const SizedBox(height: 20),

                  _buildAttendanceButton(activeRecord),

                  const SizedBox(height: 20),

                  _buildInfoCard(activeRecord),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    AttendanceRecordModel? record,
  ) {
    final checkedIn = record != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: (checkedIn
                      ? Colors.green
                      : AppColors.primary)
                  .withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              checkedIn
                  ? Icons.location_on_rounded
                  : Icons.location_searching_rounded,
              size: 40,
              color: checkedIn
                  ? Colors.green
                  : AppColors.primary,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            checkedIn
                ? 'You are currently on site'
                : 'Ready to check in',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            checkedIn
                ? 'Your attendance is being recorded.'
                : 'Your location must be inside the project area.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceButton(
    AttendanceRecordModel? record,
  ) {
    final checkedIn = record != null;

    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: _loading
            ? null
            : checkedIn
                ? _checkOut
                : _checkIn,
        icon: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                checkedIn
                    ? Icons.logout_rounded
                    : Icons.login_rounded,
              ),
        label: Text(
          _loading
              ? 'Processing...'
              : checkedIn
                  ? 'CHECK OUT'
                  : 'CHECK IN',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              checkedIn ? Colors.red : AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    AttendanceRecordModel? record,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Information',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),

          const SizedBox(height: 16),

          _infoRow(
            Icons.verified_user_outlined,
            'Location Permission',
            _attendanceEnabled
                ? 'Enabled'
                : 'Disabled',
            valueColor: _attendanceEnabled
                ? Colors.green
                : Colors.red,
          ),

          if (record != null) ...[
            _infoRow(
              Icons.login_rounded,
              'Check-in',
              _formatDateTime(record.checkInAt),
            ),

            _infoRow(
              Icons.location_on_outlined,
              'Check-in Distance',
              '${record.checkInDistanceMeters.round()} m',
            ),

            if (record.checkOutAt != null)
              _infoRow(
                Icons.logout_rounded,
                'Check-out',
                _formatDateTime(record.checkOutAt!),
              ),

            _infoRow(
              Icons.timer_outlined,
              'Worked Time',
              _formatDuration(record.workedDuration),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
              ),
            ),
          ),

          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color:
                  valueColor ?? AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();

    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '${local.day}/${local.month}/${local.year} '
        '$hour:$minute';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return '${hours}h ${minutes}m';
  }
}