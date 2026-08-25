import 'package:flutter_test/flutter_test.dart';
import 'package:structflow/features/attendance/models/attendance_record_model.dart';
import 'package:structflow/features/attendance/models/project_geofence_model.dart';

void main() {
  test('geofence accepts valid coordinates and a positive radius', () {
    final geofence = ProjectGeofenceModel(
      id: 'GEOFENCE-1',
      organizationId: 'ORG-001',
      projectId: 'PRJ-001',
      latitude: 30.0,
      longitude: 31.0,
      radiusMeters: 100,
      attendanceEnabled: true,
      updatedByUserId: 'ADMIN-1',
      updatedAt: DateTime(2026),
    );

    expect(geofence.isValid, isTrue);
  });

  test('open attendance record calculates ongoing work duration', () {
    final record = AttendanceRecordModel(
      id: 'ATT-1',
      organizationId: 'ORG-001',
      projectId: 'PRJ-001',
      userId: 'USER-001',
      checkInAt: DateTime.now().subtract(const Duration(minutes: 5)),
      checkInLatitude: 30.0,
      checkInLongitude: 31.0,
      checkInDistanceMeters: 10,
    );

    expect(record.isOpen, isTrue);
    expect(record.workedDuration.inMinutes, greaterThanOrEqualTo(5));
  });
}
