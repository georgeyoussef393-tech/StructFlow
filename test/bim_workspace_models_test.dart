import 'package:flutter_test/flutter_test.dart';
import 'package:structflow/features/bim/models/bim_workspace_models.dart';

void main() {
  test('BIM model metadata survives JSON serialization', () {
    final model = BimModelRecord(
      id: 'BIM-MOD-10',
      projectCode: 'PRJ-10',
      name: 'Tower Structure',
      discipline: 'Structure',
      version: 'v2',
      status: 'Published',
      updatedAt: DateTime.utc(2026, 10, 1),
      recordVersion: 3,
    );

    expect(BimModelRecord.fromJson(model.toJson()).toJson(), model.toJson());
    final updated = model.copyWith(status: 'Archived', recordVersion: 4);
    expect(updated.status, 'Archived');
    expect(updated.recordVersion, 4);
    expect(updated.name, model.name);
  });

  test('coordination issue status changes preserve issue details', () {
    final issue = BimIssue(
      id: 'BIM-ISS-10',
      projectCode: 'PRJ-10',
      title: 'Beam and duct coordination',
      description: 'Check clearance.',
      discipline: 'MEP / Structure',
      location: 'Level 4 · Grid C-2',
      severity: 'High',
      status: 'Open',
      assignedTo: 'BIM Coordinator',
      dueDate: DateTime.utc(2026, 10, 10),
      bcfGuid: '60000000-0000-4000-8000-000000000001',
      version: 4,
    );

    final updated = issue.copyWith(status: 'Resolved', version: 5);
    expect(updated.status, 'Resolved');
    expect(updated.version, 5);
    expect(updated.bcfGuid, issue.bcfGuid);
    expect(
      updated.toJson()
        ..remove('status')
        ..remove('version'),
      issue.toJson()
        ..remove('status')
        ..remove('version'),
    );
    expect(BimIssue.fromJson(issue.toJson()).toJson(), issue.toJson());
  });
}
