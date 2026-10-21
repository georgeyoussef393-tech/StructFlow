import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:structflow/features/bim/models/bim_workspace_models.dart';
import 'package:structflow/features/bim/repositories/bim_workspace_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'BCF topic imports are persisted and duplicate imports are skipped',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = BimWorkspaceRepository.instance;
      await repository.load();
      final importedIssue = BimIssue(
        id: 'BCF-2c7a496e-0048-4eeb-90b2-8b37e36a32d9',
        projectCode: 'PRJ-001',
        title: 'Imported clash',
        description: 'Check the clearance.',
        discipline: 'MEP / Structure',
        location: 'Level 2 · Grid B-3',
        severity: 'High',
        status: 'Open',
        assignedTo: 'BIM Coordinator',
        dueDate: DateTime.utc(2026, 11, 15),
      );

      expect(await repository.importIssues([importedIssue]), 1);
      expect(await repository.importIssues([importedIssue]), 0);

      final preferences = await SharedPreferences.getInstance();
      final issues = preferences.getString('structflow_bim_issues_v1')!;
      expect(issues, contains(importedIssue.id));
      expect(
        repository.issues.where((issue) => issue.id == importedIssue.id),
        hasLength(1),
      );
    },
  );
}
