import 'dart:convert';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../models/bim_workspace_models.dart';

class BcfExchangeService {
  static const maxArchiveBytes = 25 * 1024 * 1024;
  static const maxExpandedBytes = 40 * 1024 * 1024;
  static const maxArchiveEntries = 5000;
  static const _guidPattern =
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$';

  List<int> exportProject({
    required String projectCode,
    required String projectName,
    required List<BimIssue> issues,
  }) {
    final archive = Archive()
      ..add(
        ArchiveFile.string(
          'bcf.version',
          _xml(
            XmlElement(
              XmlName.parts('Version'),
              [XmlAttribute(XmlName.parts('VersionId'), '2.1')],
              [
                XmlElement(XmlName.parts('DetailedVersion'), [], [
                  XmlText('2.1'),
                ]),
              ],
            ),
          ),
        ),
      )
      ..add(
        ArchiveFile.string(
          'project.bcfp',
          _xml(
            XmlElement(XmlName.parts('ProjectExtension'), [], [
              XmlElement(
                XmlName.parts('Project'),
                [XmlAttribute(XmlName.parts('ProjectId'), _newGuid())],
                [
                  XmlElement(XmlName.parts('Name'), [], [
                    XmlText('$projectName ($projectCode)'),
                  ]),
                ],
              ),
              XmlElement(XmlName.parts('ExtensionSchema'), [], [
                XmlText('https://github.com/buildingSMART/BCF-XML'),
              ]),
            ]),
          ),
        ),
      );

    for (var index = 0; index < issues.length; index++) {
      final issue = issues[index];
      final guid = _guidForIssue(issue.id);
      final now = DateTime.now().toUtc();
      final topic = XmlElement(
        XmlName.parts('Topic'),
        [
          XmlAttribute(XmlName.parts('Guid'), guid),
          XmlAttribute(XmlName.parts('TopicType'), 'Issue'),
          XmlAttribute(XmlName.parts('TopicStatus'), _bcfStatus(issue.status)),
        ],
        [
          _textElement('Title', issue.title),
          _textElement('Priority', issue.severity),
          _textElement('Index', '${index + 1}'),
          _textElement('Labels', issue.discipline),
          _textElement('Labels', issue.location),
          _textElement('CreationDate', now.toIso8601String()),
          _textElement('CreationAuthor', 'StructFlow'),
          _textElement('ModifiedDate', now.toIso8601String()),
          _textElement('ModifiedAuthor', 'StructFlow'),
          _textElement(
            'DueDate',
            DateTime.utc(
              issue.dueDate.year,
              issue.dueDate.month,
              issue.dueDate.day,
            ).toIso8601String(),
          ),
          if (issue.assignedTo.trim().isNotEmpty &&
              issue.assignedTo != 'Unassigned')
            _textElement('AssignedTo', issue.assignedTo),
          _textElement('Description', issue.description),
        ],
      );
      archive.add(
        ArchiveFile.string(
          'topics/$guid/markup.bcf',
          _xml(XmlElement(XmlName.parts('Markup'), [], [topic])),
        ),
      );
    }

    return ZipEncoder().encode(archive);
  }

  List<BimIssue> importProject({
    required List<int> bytes,
    required String projectCode,
  }) {
    if (bytes.isEmpty || bytes.length > maxArchiveBytes) {
      throw const FormatException(
        'BCF file must be smaller than 25 MB and cannot be empty.',
      );
    }

    late final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes, verify: true);
    } on Object catch (error) {
      throw FormatException('The selected file is not a valid BCF ZIP: $error');
    }
    if (archive.length > maxArchiveEntries) {
      throw const FormatException('BCF archive contains too many entries.');
    }
    final entries = <String, ArchiveFile>{};
    var expandedBytes = 0;
    for (final entry in archive) {
      if (!entry.isFile) continue;
      expandedBytes += entry.size;
      if (expandedBytes > maxExpandedBytes) {
        throw const FormatException(
          'BCF archive expands beyond the 40 MB import limit.',
        );
      }
      if (entry.isSymbolicLink ||
          entry.name.startsWith('/') ||
          entry.name.contains(r'\') ||
          entry.name.split('/').any((segment) => segment == '..')) {
        throw const FormatException('BCF archive contains an unsafe path.');
      }
      if (entries.containsKey(entry.name)) {
        throw FormatException(
          'BCF archive has duplicate path "${entry.name}".',
        );
      }
      entries[entry.name] = entry;
    }

    final versionEntry = entries['bcf.version'];
    if (versionEntry == null) {
      throw const FormatException('BCF version information is missing.');
    }
    final version = _readXml(versionEntry, 'bcf.version');
    final versionId = version.rootElement.getAttribute('VersionId');
    if (version.rootElement.name.local != 'Version' || versionId != '2.1') {
      throw FormatException(
        'Only BCF 2.1 files are currently supported (found ${versionId ?? 'unknown'}).',
      );
    }

    final markupPaths = entries.keys
        .where(
          (path) =>
              RegExp(r'^topics/[0-9a-fA-F-]{36}/markup\.bcf$').hasMatch(path),
        )
        .toList(growable: false);
    if (markupPaths.isEmpty) {
      throw const FormatException('BCF file contains no coordination topics.');
    }

    final topics = <BimIssue>[];
    final topicIds = <String>{};
    for (final path in markupPaths) {
      final folderGuid = path.split('/')[1];
      if (!RegExp(_guidPattern).hasMatch(folderGuid)) {
        throw FormatException('Invalid BCF topic identifier in "$path".');
      }
      final document = _readXml(entries[path]!, path);
      final topic = _child(document.rootElement, 'Topic');
      if (document.rootElement.name.local != 'Markup' || topic == null) {
        throw FormatException('BCF topic "$path" has invalid markup.');
      }
      final guid = topic.getAttribute('Guid') ?? folderGuid;
      if (!RegExp(_guidPattern).hasMatch(guid)) {
        throw FormatException('BCF topic "$path" has an invalid GUID.');
      }
      if (guid.toLowerCase() != folderGuid.toLowerCase()) {
        throw FormatException(
          'BCF topic "$path" does not match its topic folder GUID.',
        );
      }
      if (!topicIds.add(guid.toLowerCase())) {
        throw FormatException('BCF file repeats topic GUID "$guid".');
      }

      final title = _childText(topic, 'Title');
      if (title.isEmpty) {
        throw FormatException('BCF topic "$path" is missing its title.');
      }
      final dueDate = DateTime.tryParse(_childText(topic, 'DueDate'));
      final labels = topic
          .findElements('Labels')
          .map((e) => e.innerText)
          .toList();
      final description = _childText(topic, 'Description');
      topics.add(
        BimIssue(
          id: 'BCF-${guid.toLowerCase()}',
          projectCode: projectCode,
          title: title,
          description: description,
          discipline: labels.isEmpty ? 'General' : labels.first,
          location: labels.length < 2 ? 'Not specified' : labels[1],
          severity: _normalizeSeverity(_childText(topic, 'Priority')),
          status: _normalizeStatus(topic.getAttribute('TopicStatus') ?? 'Open'),
          assignedTo: _childText(topic, 'AssignedTo').isEmpty
              ? 'Unassigned'
              : _childText(topic, 'AssignedTo'),
          dueDate: dueDate ?? DateTime.now(),
        ),
      );
    }
    return topics;
  }

  String _guidForIssue(String issueId) {
    final candidate = issueId.startsWith('BCF-')
        ? issueId.substring('BCF-'.length)
        : issueId;
    if (RegExp(_guidPattern).hasMatch(candidate)) {
      return candidate.toLowerCase();
    }
    return _newGuid();
  }

  String _newGuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  String _bcfStatus(String value) {
    if (value.toLowerCase() == 'in progress') return 'In Progress';
    if (value.toLowerCase() == 'resolved') return 'Resolved';
    return 'Open';
  }

  String _normalizeStatus(String value) {
    switch (value.trim().toLowerCase()) {
      case 'in progress':
      case 'in-progress':
        return 'In progress';
      case 'resolved':
      case 'closed':
      case 'done':
        return 'Resolved';
      default:
        return 'Open';
    }
  }

  String _normalizeSeverity(String value) {
    switch (value.trim().toLowerCase()) {
      case 'critical':
        return 'Critical';
      case 'high':
        return 'High';
      case 'low':
        return 'Low';
      default:
        return 'Medium';
    }
  }

  String _xml(XmlElement element) =>
      '<?xml version="1.0" encoding="UTF-8"?>'
      '${XmlDocument([element]).toXmlString()}';

  XmlElement _textElement(String name, String value) =>
      XmlElement(XmlName.parts(name), [], [XmlText(value)]);

  XmlDocument _readXml(ArchiveFile entry, String path) {
    final data = entry.readBytes();
    if (data == null) throw FormatException('BCF entry "$path" is empty.');
    try {
      return XmlDocument.parse(utf8.decode(data, allowMalformed: false));
    } on Object catch (error) {
      throw FormatException('BCF entry "$path" has invalid XML: $error');
    }
  }

  XmlElement? _child(XmlElement element, String name) => element.childElements
      .where((child) => child.name.local == name)
      .firstOrNull;

  String _childText(XmlElement element, String name) =>
      _child(element, name)?.innerText.trim() ?? '';
}
