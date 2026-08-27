import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:structflow/features/attendance/models/attendance_permission_model.dart';
import 'package:structflow/features/attendance/models/attendance_record_model.dart';
import 'package:structflow/features/attendance/models/project_geofence_model.dart';
import 'package:structflow/features/attendance/repositories/attendance_permission_repository.dart';
import 'package:structflow/features/attendance/repositories/attendance_repository.dart';
import 'package:structflow/features/attendance/repositories/project_geofence_repository.dart';

class AttendanceCenterPage extends StatefulWidget {
  final String organizationId;
  final String userId;

  const AttendanceCenterPage({
    super.key,
    required this.organizationId,
    required this.userId,
  });

  @override
  State<AttendanceCenterPage> createState() =>
      _AttendanceCenterPageState();
}

class _AttendanceCenterPageState extends State<AttendanceCenterPage> {
  final AttendanceRepository _attendanceRepository =
      AttendanceRepository.instance;

  final AttendancePermissionRepository _permissionRepository =
      AttendancePermissionRepository.instance;

  final ProjectGeofenceRepository _geofenceRepository =
      ProjectGeofenceRepository.instance;

  bool _loading = false;

  AttendancePermissionModel? get _permission =>
      _permissionRepository.getForUser(
        organizationId: widget.organizationId,
        userId: widget.userId,
      );

  bool get _isSuperAdmin => _permission?.isSuperAdmin ?? false;

  bool get _isProjectManager =>
      _permission?.isProjectManager ?? false;

  bool get _isHrManager => _permission?.isHrManager ?? false;

  bool get _canManageGeofences =>
      _permission?.canManageProjectGeofences ?? false;

  bool get _canViewOrganizationAttendance =>
      _permission?.canViewOrganizationAttendance ?? false;

  bool get _canViewProjectAttendance =>
      _permission?.canViewProjectAttendance ?? false;

  @override
  void initState() {
    super.initState();

    _permissionRepository.addListener(_refresh);
    _attendanceRepository.addListener(_refresh);
    _geofenceRepository.addListener(_refresh);

    _loadData();
  }

  @override
  void dispose() {
    _permissionRepository.removeListener(_refresh);
    _attendanceRepository.removeListener(_refresh);
    _geofenceRepository.removeListener(_refresh);

    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadData() async {
    await Future.wait([
      _permissionRepository.load(),
      _attendanceRepository.load(),
      _geofenceRepository.load(),
    ]);

    if (mounted) {
      setState(() {});
    }
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      await _showMessage(
        'Location Service',
        'لازم تشغل خدمة تحديد الموقع على الهاتف أولاً.',
      );
      return false;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      await _showMessage(
        'Location Permission',
        'تم رفض صلاحية الموقع.',
      );
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      await _showMessage(
        'Location Permission',
        'صلاحية الموقع مرفوضة نهائيًا. افتح إعدادات التطبيق واسمح بالموقع.',
      );
      return false;
    }

    return true;
  }

  Future<Position?> _getCurrentPosition() async {
    final allowed = await _ensureLocationPermission();

    if (!allowed) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      await _showMessage(
        'Location Error',
        'تعذر الحصول على موقع الهاتف.',
      );
      return null;
    }
  }

  Future<void> _showMessage(
    String title,
    String message,
  ) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkIn(String projectId) async {
    if (_permission == null) {
      await _showMessage(
        'Attendance',
        'لا توجد صلاحية Attendance لهذا المستخدم.',
      );
      return;
    }

    if (!_permission!.locationAttendanceEnabled) {
      await _showMessage(
        'Attendance',
        'تسجيل الموقع غير مفعل لهذا الموظف.',
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final position = await _getCurrentPosition();

      if (position == null) {
        return;
      }

      final record = await _attendanceRepository.checkIn(
        organizationId: widget.organizationId,
        projectId: projectId,
        userId: widget.userId,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;

      if (record == null) {
        await _showMessage(
          'Attendance',
          'لم يتم تسجيل الحضور.\n\n'
          'تأكد أنك داخل نطاق المشروع المحدد بواسطة الإدارة.',
        );
        return;
      }

      await _showMessage(
        'تم تسجيل الحضور',
        'تم تسجيل وصول الموظف بنجاح.\n\n'
        'وقت الوصول: ${_formatDateTime(record.checkInAt)}\n'
        'المسافة من الموقع: '
        '${record.checkInDistanceMeters.toStringAsFixed(1)} متر',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _checkOut(String projectId) async {
    setState(() {
      _loading = true;
    });

    try {
      final position = await _getCurrentPosition();

      if (position == null) {
        return;
      }

      final record = await _attendanceRepository.checkOut(
        organizationId: widget.organizationId,
        projectId: projectId,
        userId: widget.userId,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;

      if (record == null) {
        await _showMessage(
          'Attendance',
          'لم يتم تسجيل الانصراف.\n\n'
          'تأكد أنك داخل نطاق المشروع وأن هناك حضورًا مفتوحًا.',
        );
        return;
      }

      await _showMessage(
        'تم تسجيل الانصراف',
        'تم تسجيل انصراف الموظف بنجاح.\n\n'
        'وقت الانصراف: '
        '${_formatDateTime(record.checkOutAt!)}\n'
        'إجمالي العمل: '
        '${_formatDuration(record.workedDuration)}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();

    String two(int value) =>
        value.toString().padLeft(2, '0');

    return '${local.year}/'
        '${two(local.month)}/'
        '${two(local.day)} '
        '${two(local.hour)}:'
        '${two(local.minute)}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return '$hours ساعة $minutes دقيقة';
  }

  List<AttendanceRecordModel> get _myRecords =>
      _attendanceRepository.recordsForUser(
        organizationId: widget.organizationId,
        userId: widget.userId,
      );

  List<AttendanceRecordModel> get _visibleRecords =>
      _attendanceRepository.recordsVisibleTo(
        actorUserId: widget.userId,
        organizationId: widget.organizationId,
      );

  @override
  Widget build(BuildContext context) {
    final permission = _permission;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Center'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(permission),
                  const SizedBox(height: 16),

                  if (permission != null)
                    _buildRoleCard(permission),

                  const SizedBox(height: 16),

                  _buildEmployeeAttendance(),

                  if (_isSuperAdmin ||
                      _isProjectManager ||
                      _isHrManager) ...[
                    const SizedBox(height: 20),
                    _buildManagementSection(),
                  ],

                  if (_canManageGeofences) ...[
                    const SizedBox(height: 20),
                    _buildGeofenceSection(),
                  ],

                  if ((_isHrManager &&
                          _canViewOrganizationAttendance) ||
                      (_isProjectManager &&
                          _canViewProjectAttendance) ||
                      _isSuperAdmin) ...[
                    const SizedBox(height: 20),
                    _buildReportsSection(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(
    AttendancePermissionModel? permission,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              child: Icon(
                permission?.locationAttendanceEnabled == true
                    ? Icons.location_on
                    : Icons.location_off,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attendance',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    permission?.locationAttendanceEnabled == true
                        ? 'Location attendance is enabled'
                        : 'Location attendance is disabled',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    AttendancePermissionModel permission,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Access & Permissions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _permissionRow('Role', permission.role),
            _permissionRow(
              'Location Attendance',
              permission.locationAttendanceEnabled
                  ? 'Enabled'
                  : 'Disabled',
            ),
            _permissionRow(
              'Manage Geofences',
              permission.canManageProjectGeofences
                  ? 'Allowed'
                  : 'Not allowed',
            ),
            _permissionRow(
              'Project Attendance',
              permission.canViewProjectAttendance
                  ? 'Allowed'
                  : 'Not allowed',
            ),
            _permissionRow(
              'Organization Attendance',
              permission.canViewOrganizationAttendance
                  ? 'Allowed'
                  : 'Not allowed',
            ),
          ],
        ),
      ),
    );
  }

  Widget _permissionRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeAttendance() {
    final records = _myRecords;

    final openRecords = records
        .where((record) => record.isOpen)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Attendance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (openRecords.isEmpty)
              const Text(
                'لا يوجد حضور مفتوح حاليًا.',
              )
            else
              ...openRecords.map(
                _buildOpenAttendanceCard,
              ),

            const SizedBox(height: 12),

            if (openRecords.isEmpty)
              ..._buildProjectButtons(),

            const Divider(height: 28),

            const Text(
              'Recent Attendance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            if (records.isEmpty)
              const Text(
                'لا توجد سجلات حضور حتى الآن.',
              )
            else
              ...records.reversed
                  .take(10)
                  .map(_buildAttendanceRecord),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildProjectButtons() {
    final projectIds =
        _permission?.managedProjectIds ?? const <String>[];

    if (projectIds.isEmpty) {
      return [
        const Text(
          'لم يتم تعيين أي مشروع لهذا المستخدم.',
        ),
      ];
    }

    return projectIds
        .map(
          (projectId) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading
                    ? null
                    : () => _checkIn(projectId),
                icon: const Icon(Icons.login),
                label: Text(
                  'Check In • $projectId',
                ),
              ),
            ),
          ),
        )
        .toList();
  }

  Widget _buildOpenAttendanceCard(
    AttendanceRecordModel record,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.work,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  record.projectId,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Chip(
                label: Text('OPEN'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Check In: '
            '${_formatDateTime(record.checkInAt)}',
          ),
          Text(
            'Distance: '
            '${record.checkInDistanceMeters.toStringAsFixed(1)} m',
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loading
                  ? null
                  : () => _checkOut(record.projectId),
              icon: const Icon(Icons.logout),
              label: const Text('Check Out'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRecord(
    AttendanceRecordModel record,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        record.isOpen
            ? Icons.login
            : Icons.check_circle,
      ),
      title: Text(record.projectId),
      subtitle: Text(
        '${_formatDateTime(record.checkInAt)}'
        '${record.checkOutAt != null ? ' → ${_formatDateTime(record.checkOutAt!)}' : ''}',
      ),
      trailing: record.checkOutAt == null
          ? const Text('Open')
          : Text(
              _formatDuration(
                record.workedDuration,
              ),
            ),
    );
  }

  Widget _buildManagementSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Management',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (_isSuperAdmin)
              ListTile(
                leading: const Icon(
                  Icons.admin_panel_settings,
                ),
                title: const Text(
                  'Attendance Permissions',
                ),
                subtitle: const Text(
                  'إدارة صلاحيات تسجيل ومتابعة الحضور',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: _showPermissionsInfo,
              ),

            if (_isSuperAdmin || _isProjectManager)
              ListTile(
                leading: const Icon(
                  Icons.location_on,
                ),
                title: const Text(
                  'Project Geofences',
                ),
                subtitle: const Text(
                  'إدارة نطاقات مواقع المشاريع',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: _showGeofenceInfo,
              ),

            if (_isHrManager || _isSuperAdmin)
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('HR Attendance'),
                subtitle: const Text(
                  'بيانات حضور الموظفين',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: _showReportsInfo,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeofenceSection() {
    final geofences = _geofenceRepository.geofences
        .where(
          (item) =>
              item.organizationId ==
              widget.organizationId,
        )
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Project Geofences',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            if (geofences.isEmpty)
              const Text(
                'لا توجد Geofences مضافة حاليًا.',
              )
            else
              ...geofences.map(
                _buildGeofenceTile,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeofenceTile(
    ProjectGeofenceModel geofence,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        geofence.attendanceEnabled
            ? Icons.location_on
            : Icons.location_off,
      ),
      title: Text(geofence.projectId),
      subtitle: Text(
        'Radius: '
        '${geofence.radiusMeters.toStringAsFixed(0)} m\n'
        '${geofence.latitude.toStringAsFixed(6)}, '
        '${geofence.longitude.toStringAsFixed(6)}',
      ),
      trailing: Switch(
        value: geofence.attendanceEnabled,
        onChanged: _canManageGeofences
            ? (_) => _toggleGeofence(geofence)
            : null,
      ),
    );
  }

  Future<void> _toggleGeofence(
    ProjectGeofenceModel geofence,
  ) async {
    final permission = _permission;

    if (permission == null || !_canManageGeofences) {
      return;
    }

    final updated = geofence.copyWith(
      attendanceEnabled:
          !geofence.attendanceEnabled,
      updatedByUserId: widget.userId,
      updatedAt: DateTime.now(),
    );

    await _geofenceRepository.save(
      actorUserId: widget.userId,
      geofence: updated,
    );
  }

  Widget _buildReportsSection() {
    final records = _visibleRecords;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Attendance Reports',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text('${records.length} records'),
              ],
            ),
            const SizedBox(height: 12),

            if (records.isEmpty)
              const Text(
                'لا توجد بيانات متاحة حسب صلاحيات المستخدم.',
              )
            else
              ...records.reversed
                  .take(30)
                  .map(_buildReportTile),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTile(
    AttendanceRecordModel record,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        child: Icon(
          record.isOpen
              ? Icons.login
              : Icons.done,
        ),
      ),
      title: Text(record.userId),
      subtitle: Text(
        '${record.projectId}\n'
        'In: ${_formatDateTime(record.checkInAt)}'
        '${record.checkOutAt != null ? '\nOut: ${_formatDateTime(record.checkOutAt!)}' : ''}',
      ),
      isThreeLine: true,
      trailing: record.isOpen
          ? const Chip(
              label: Text('OPEN'),
            )
          : Text(
              _formatDuration(
                record.workedDuration,
              ),
            ),
    );
  }

  Future<void> _showPermissionsInfo() async {
    await _showMessage(
      'Attendance Permissions',
      'إدارة صلاحيات الحضور يجب أن تتم من Super Admin.\n\n'
      'Super Admin يستطيع منح صلاحية الموقع وتحديد صلاحيات مدير المشروع وHR.',
    );
  }

  Future<void> _showGeofenceInfo() async {
    await _showMessage(
      'Project Geofence',
      'نطاق المشروع هو المكان الجغرافي الذي يسمح للموظف بتسجيل الحضور والانصراف داخله.',
    );
  }

  Future<void> _showReportsInfo() async {
    await _showMessage(
      'HR Attendance',
      'قسم HR يستطيع متابعة سجلات الحضور والانصراف حسب الصلاحيات الممنوحة.',
    );
  }
}