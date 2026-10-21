import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structflow/features/bim/models/bim_workspace_models.dart';
import 'package:structflow/features/bim/services/bcf_exchange_service.dart';

void main() {
  final service = BcfExchangeService();

  test('exports and imports issues as an open BCF 2.1 archive', () {
    final issue = BimIssue(
      id: 'BIM-ISS-501',
      projectCode: 'PRJ-501',
      title: 'Duct & beam coordination',
      description: 'Check <clearance> & access.',
      discipline: 'MEP / Structure',
      location: 'Level 04 · Grid C-5',
      severity: 'Critical',
      status: 'In progress',
      assignedTo: 'BIM Coordinator',
      dueDate: DateTime.utc(2026, 11, 4),
    );

    final bytes = service.exportProject(
      projectCode: 'PRJ-501',
      projectName: 'Tower One',
      issues: [issue],
    );
    final archive = ZipDecoder().decodeBytes(bytes);

    expect(archive.find('bcf.version'), isNotNull);
    expect(archive.find('project.bcfp'), isNotNull);
    final markupFiles = archive.files
        .where((file) => file.name.endsWith('/markup.bcf'))
        .toList();
    expect(markupFiles, hasLength(1));

    final imported = service.importProject(
      bytes: bytes,
      projectCode: 'PRJ-501',
    );

    expect(imported, hasLength(1));
    expect(imported.single.title, issue.title);
    expect(imported.single.description, issue.description);
    expect(imported.single.discipline, issue.discipline);
    expect(imported.single.location, issue.location);
    expect(imported.single.severity, issue.severity);
    expect(imported.single.status, issue.status);
    expect(imported.single.assignedTo, issue.assignedTo);
    expect(imported.single.dueDate, issue.dueDate);
    expect(imported.single.projectCode, 'PRJ-501');
    expect(imported.single.id, startsWith('BCF-'));

    final reExport = service.exportProject(
      projectCode: 'PRJ-501',
      projectName: 'Tower One',
      issues: imported,
    );
    final reExportedTopicPath = ZipDecoder()
        .decodeBytes(reExport)
        .files
        .singleWhere((file) => file.name.endsWith('/markup.bcf'))
        .name;
    expect(reExportedTopicPath, markupFiles.single.name);
  });

  test('rejects unsupported BCF versions', () {
    final archive = Archive()
      ..add(
        ArchiveFile.string(
          'bcf.version',
          '<?xml version="1.0"?><Version VersionId="3.0"/>',
        ),
      );
    final bytes = ZipEncoder().encode(archive);

    expect(
      () => service.importProject(bytes: bytes, projectCode: 'PRJ-1'),
      throwsFormatException,
    );
  });

  test('rejects archive paths that could escape the BCF root', () {
    final archive = Archive()
      ..add(
        ArchiveFile.string(
          'bcf.version',
          '<?xml version="1.0"?><Version VersionId="2.1"/>',
        ),
      )
      ..add(ArchiveFile.string('../outside.txt', 'unexpected'));
    final bytes = ZipEncoder().encode(archive);

    expect(
      () => service.importProject(bytes: bytes, projectCode: 'PRJ-1'),
      throwsFormatException,
    );
  });

  test('rejects non-ZIP and oversized imports', () {
    expect(
      () => service.importProject(bytes: [1, 2, 3], projectCode: 'PRJ-1'),
      throwsFormatException,
    );
    expect(
      () => service.importProject(
        bytes: List<int>.filled(BcfExchangeService.maxArchiveBytes + 1, 0),
        projectCode: 'PRJ-1',
      ),
      throwsFormatException,
    );
  });
}
