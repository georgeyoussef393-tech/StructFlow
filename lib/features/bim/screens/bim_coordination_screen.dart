import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_selector/file_selector.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../projects/models/project_model.dart';
import '../../projects/repositories/project_repository.dart';
import '../models/bim_workspace_models.dart';
import '../repositories/bim_workspace_repository.dart';
import '../services/bcf_exchange_service.dart';

class BimCoordinationScreen extends StatefulWidget {
  const BimCoordinationScreen({super.key});

  @override
  State<BimCoordinationScreen> createState() => _BimCoordinationScreenState();
}

class _BimCoordinationScreenState extends State<BimCoordinationScreen> {
  final _repository = BimWorkspaceRepository.instance;
  final _bcfExchange = BcfExchangeService();
  final _searchController = TextEditingController();
  String _selectedProjectCode = '';
  String _selectedTab = 'Issues';
  String _issueFilter = 'All';
  bool _loading = true;
  bool _loadingIssues = false;
  String? _loadError;

  List<ProjectModel> get _projects => ProjectRepository.instance.projects;

  @override
  void initState() {
    super.initState();
    _repository.addListener(_refresh);
    _loadWorkspace();
  }

  @override
  void dispose() {
    _repository.removeListener(_refresh);
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _loadWorkspace() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      if (AuthRepository.instance.usesApiAuth) {
        await ProjectRepository.instance.loadProjects();
      }
      await _repository.load();
      if (_selectedProjectCode.isEmpty && _projects.isNotEmpty) {
        _selectedProjectCode = _projects.first.code;
      }
      if (AuthRepository.instance.usesApiAuth &&
          _selectedProjectCode.isNotEmpty) {
        await _loadBimDataForProject(_selectedProjectCode);
      }
    } on Exception catch (error) {
      if (mounted) setState(() => _loadError = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadBimDataForProject(String projectCode) async {
    setState(() {
      _loadingIssues = true;
      _loadError = null;
    });
    try {
      await Future.wait([
        _repository.loadIssuesForProject(projectCode),
        _repository.loadModelsForProject(projectCode),
      ]);
    } on Exception catch (error) {
      if (mounted) _message('Could not load BIM project data: $error');
    } finally {
      if (mounted) setState(() => _loadingIssues = false);
    }
  }

  List<BimIssue> get _filteredIssues {
    final query = _searchController.text.trim().toLowerCase();
    return _repository.issuesFor(_selectedProjectCode).where((issue) {
      final matchesQuery =
          query.isEmpty ||
          issue.title.toLowerCase().contains(query) ||
          issue.location.toLowerCase().contains(query) ||
          issue.discipline.toLowerCase().contains(query) ||
          issue.assignedTo.toLowerCase().contains(query);
      final matchesFilter =
          _issueFilter == 'All' || issue.status == _issueFilter;
      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return SingleChildScrollView(
              padding: EdgeInsets.all(width < 600 ? 16 : 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(width),
                      const SizedBox(height: 20),
                      _buildDemoNotice(),
                      const SizedBox(height: 20),
                      if (_loadError case final error?)
                        _buildError(error)
                      else if (_loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(64),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_projects.isEmpty)
                        _buildNoProjects()
                      else ...[
                        _buildProjectSelector(width),
                        const SizedBox(height: 18),
                        _buildSummaryCards(width),
                        const SizedBox(height: 22),
                        _buildWorkspace(width),
                      ],
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

  Widget _buildHeader(double width) {
    final compact = width < 650;
    final title = const Text(
      'BIM Coordination',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.textDark,
      ),
    );
    final actions = Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: _importBcf,
          icon: const Icon(Icons.upload_file_outlined),
          label: const Text('Import BCF'),
        ),
        OutlinedButton.icon(
          onPressed: _exportBcf,
          icon: const Icon(Icons.download_outlined),
          label: const Text('Export BCF'),
        ),
        OutlinedButton.icon(
          onPressed: _showRegisterModelDialog,
          icon: const Icon(Icons.view_in_ar_outlined),
          label: const Text('Register model'),
        ),
        FilledButton.icon(
          onPressed: _showCreateIssueDialog,
          icon: const Icon(Icons.add),
          label: const Text('New coordination issue'),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Back to dashboard'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 8),
        if (compact) ...[
          title,
          const SizedBox(height: 14),
          actions,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 5),
                    const Text(
                      'Model register, multidisciplinary coordination, and issue tracking',
                      style: TextStyle(color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
              actions,
            ],
          ),
      ],
    );
  }

  Widget _buildDemoNotice() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xffFFF7E6),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xffF3D18A)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, color: Color(0xff8A5A00)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            AuthRepository.instance.usesApiAuth
                ? 'Model register metadata and coordination issues are stored in the StructFlow server and are subject to project membership. Model files are not uploaded or viewed here. BCF 2.1 exchange transfers core issue fields only; viewpoints and clash detection are not connected yet.'
                : 'Coordination workspace preview. Import/export BCF 2.1 issue packages and core issue fields; records are stored in this browser. Model registration stores metadata only. IFC/Revit upload, 3D viewing, viewpoints, and clash detection are not connected yet. Do not enter confidential project information.',
            style: const TextStyle(color: Color(0xff684500), height: 1.4),
          ),
        ),
      ],
    ),
  );

  Widget _buildError(String error) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BIM workspace could not load: $error'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loadWorkspace,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );

  Widget _buildNoProjects() => const Card(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Text('Create a project before setting up its BIM coordination.'),
    ),
  );

  Widget _buildProjectSelector(double width) {
    final selected =
        _projects.any((project) => project.code == _selectedProjectCode)
        ? _selectedProjectCode
        : _projects.first.code;
    _selectedProjectCode = selected;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.apartment_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            const Text(
              'Project',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selected,
                  isExpanded: true,
                  items: _projects
                      .map(
                        (project) => DropdownMenuItem(
                          value: project.code,
                          child: Text(
                            '${project.name} · ${project.code}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedProjectCode = value);
                      if (AuthRepository.instance.usesApiAuth) {
                        _loadBimDataForProject(value);
                      }
                    }
                  },
                ),
              ),
            ),
            if (width >= 700) ...[
              const SizedBox(width: 16),
              const Icon(Icons.sync, size: 18, color: AppColors.textLight),
              const SizedBox(width: 6),
              Text(
                AuthRepository.instance.usesApiAuth
                    ? 'Server data'
                    : 'Local preview',
                style: const TextStyle(color: AppColors.textLight),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(double width) {
    final models = _repository.modelsFor(_selectedProjectCode);
    final issues = _repository.issuesFor(_selectedProjectCode);
    final open = issues.where((issue) => issue.status != 'Resolved').length;
    final critical = issues
        .where(
          (issue) => issue.severity == 'Critical' && issue.status != 'Resolved',
        )
        .length;
    final cards = [
      _MetricData(
        'Models',
        '${models.length}',
        Icons.view_in_ar_outlined,
        const Color(0xff2155A3),
      ),
      _MetricData(
        'Open issues',
        '$open',
        Icons.rule_folder_outlined,
        const Color(0xffC47A0A),
      ),
      _MetricData(
        'Critical',
        '$critical',
        Icons.warning_amber_rounded,
        const Color(0xffC43D3D),
      ),
      _MetricData(
        'Resolved',
        '${issues.where((issue) => issue.status == 'Resolved').length}',
        Icons.task_alt_rounded,
        const Color(0xff25815A),
      ),
    ];
    final columns = width < 560 ? 2 : 4;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisExtent: 100,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) => _metricCard(cards[index]),
    );
  }

  Widget _metricCard(_MetricData metric) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: metric.color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(metric.icon, color: metric.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildWorkspace(double width) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
          child: Row(
            children: [
              _tabButton('Issues'),
              const SizedBox(width: 8),
              _tabButton('Model register'),
              const Spacer(),
              if (width >= 760)
                const Text(
                  'Coordination workspace',
                  style: TextStyle(color: AppColors.textLight, fontSize: 12),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (_selectedTab == 'Issues')
          _buildIssuesPanel(width)
        else
          _buildModelsPanel(width),
      ],
    ),
  );

  Widget _tabButton(String title) {
    final selected = _selectedTab == title;
    return TextButton(
      onPressed: () => setState(() => _selectedTab = title),
      style: TextButton.styleFrom(
        foregroundColor: selected ? AppColors.primary : AppColors.textLight,
        shape: const RoundedRectangleBorder(),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 3,
            width: 70,
            color: selected ? AppColors.primary : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildIssuesPanel(double width) {
    final issues = _filteredIssues;
    return Column(
      children: [
        if (_loadingIssues) const LinearProgressIndicator(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              SizedBox(
                width: width < 600 ? width - 66 : 330,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search issue, location, discipline...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                width: 170,
                child: DropdownButtonFormField<String>(
                  initialValue: _issueFilter,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    isDense: true,
                  ),
                  items: const ['All', 'Open', 'In progress', 'Resolved']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _issueFilter = value);
                  },
                ),
              ),
            ],
          ),
        ),
        if (issues.isEmpty)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Text('No coordination issues match this view.'),
          )
        else if (width < 820)
          ...issues.map(_issueCard)
        else
          _buildIssueTable(issues),
      ],
    );
  }

  Widget _buildIssueTable(List<BimIssue> issues) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      headingRowColor: WidgetStateProperty.all(const Color(0xffF7F9FC)),
      columns: const [
        DataColumn(label: Text('Issue')),
        DataColumn(label: Text('Discipline')),
        DataColumn(label: Text('Location')),
        DataColumn(label: Text('Severity')),
        DataColumn(label: Text('Assigned to')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Due date')),
      ],
      rows: issues
          .map(
            (issue) => DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 220,
                    child: Text(
                      issue.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  onTap: () => _showIssueDetails(issue),
                ),
                DataCell(Text(issue.discipline)),
                DataCell(Text(issue.location)),
                DataCell(_severityBadge(issue.severity)),
                DataCell(Text(issue.assignedTo)),
                DataCell(_statusDropdown(issue)),
                DataCell(Text(_dateLabel(issue.dueDate))),
              ],
            ),
          )
          .toList(),
    ),
  );

  Widget _issueCard(BimIssue issue) => Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xffE5EAF1)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _showIssueDetails(issue),
                child: Text(
                  issue.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            _severityBadge(issue.severity),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          issue.discipline,
          style: const TextStyle(color: AppColors.textLight),
        ),
        const SizedBox(height: 5),
        Text(issue.location, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                '${issue.assignedTo} · Due ${_dateLabel(issue.dueDate)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
            ),
            _statusDropdown(issue),
          ],
        ),
      ],
    ),
  );

  Widget _buildModelsPanel(double width) {
    final models = _repository.modelsFor(_selectedProjectCode);
    if (models.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Text('No model metadata registered for this project yet.'),
      );
    }
    final columns = width < 650
        ? 1
        : width < 1050
        ? 2
        : 3;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: models.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisExtent: 154,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) => _modelCard(models[index]),
      ),
    );
  }

  Widget _modelCard(BimModelRecord model) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xffE5EAF1)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.view_in_ar_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                model.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            _modelStatusDropdown(model),
          ],
        ),
        const Spacer(),
        Text(
          '${model.discipline} · ${model.version}',
          style: const TextStyle(color: AppColors.textLight),
        ),
        const SizedBox(height: 6),
        Text(
          'Updated ${_dateLabel(model.updatedAt)} · Metadata only',
          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
        ),
      ],
    ),
  );

  Widget _severityBadge(String severity) {
    final color = switch (severity) {
      'Critical' => const Color(0xffC43D3D),
      'High' => const Color(0xffC47A0A),
      'Medium' => const Color(0xff2155A3),
      _ => const Color(0xff5E6B7A),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        severity,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _modelStatusDropdown(BimModelRecord model) => DropdownButton<String>(
    value: model.status,
    underline: const SizedBox.shrink(),
    isDense: true,
    items: const ['In review', 'Published', 'Archived']
        .map(
          (status) => DropdownMenuItem(
            value: status,
            child: Text(status, style: const TextStyle(fontSize: 11)),
          ),
        )
        .toList(),
    onChanged: (status) {
      if (status == null || status == model.status) return;
      _updateModelStatus(model, status);
    },
  );

  Future<void> _updateModelStatus(BimModelRecord model, String status) async {
    try {
      await _repository.updateModelStatus(model.id, status);
      _message('Model status updated.');
    } on Exception catch (error) {
      _message('Model status could not be updated: $error');
    } finally {
      if (mounted) setState(() {});
    }
  }

  Widget _statusDropdown(BimIssue issue) => DropdownButton<String>(
    value: issue.status,
    underline: const SizedBox.shrink(),
    isDense: true,
    items: const ['Open', 'In progress', 'Resolved']
        .map((status) => DropdownMenuItem(value: status, child: Text(status)))
        .toList(),
    onChanged: (status) {
      if (status != null && status != issue.status) {
        _updateIssueStatus(issue.id, status);
      }
    },
  );

  Future<void> _importBcf() async {
    int? importedIssueCount;
    try {
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(label: 'BCF 2.1 coordination file', extensions: ['bcf']),
        ],
      );
      if (file == null) return;
      if (await file.length() > BcfExchangeService.maxArchiveBytes) {
        throw const FormatException('BCF files must be 25 MB or smaller.');
      }
      final importedBcf = _bcfExchange.importProjectBundle(
        bytes: await file.readAsBytes(),
        projectCode: _selectedProjectCode,
      );
      final imported = await _repository.importIssues(importedBcf.issues);
      importedIssueCount = imported;
      final importedComments = await _repository.importBcfComments(
        projectCode: _selectedProjectCode,
        commentsByTopicGuid: importedBcf.commentsByTopicGuid,
      );
      setState(() {
        _selectedTab = 'Issues';
        _issueFilter = 'All';
        _searchController.clear();
      });
      _message(
        'Imported $imported issue${imported == 1 ? '' : 's'} and '
        '$importedComments comment${importedComments == 1 ? '' : 's'}; '
        'repeated BCF identifiers were skipped.',
      );
    } on Exception catch (error) {
      final partialImport = importedIssueCount == null
          ? ''
          : ' $importedIssueCount issue(s) were imported before the failure.';
      _message('BCF import failed:$partialImport $error');
    }
  }

  Future<void> _exportBcf() async {
    try {
      final project = _projects
          .where((candidate) => candidate.code == _selectedProjectCode)
          .firstOrNull;
      if (project == null) {
        throw StateError('Select a project before exporting BCF.');
      }
      final issues = _repository.issuesFor(project.code);
      if (issues.isEmpty) {
        _message('There are no coordination issues to export.');
        return;
      }
      final commentsByIssueId = await _repository.loadProjectIssueComments(
        project.code,
      );
      final filename =
          'StructFlow-${project.code.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}.bcf';
      final destination = await getSaveLocation(
        suggestedName: filename,
        acceptedTypeGroups: const [
          XTypeGroup(label: 'BCF 2.1 coordination file', extensions: ['bcf']),
        ],
      );
      if (destination == null) return;
      final bytes = _bcfExchange.exportProject(
        projectCode: project.code,
        projectName: project.name,
        issues: issues,
        commentsByIssueId: commentsByIssueId,
      );
      await XFile.fromData(
        Uint8List.fromList(bytes),
        mimeType: 'application/octet-stream',
        name: filename,
      ).saveTo(destination.path);
      final commentCount = commentsByIssueId.values.fold<int>(
        0,
        (count, comments) => count + comments.length,
      );
      _message(
        'Exported ${issues.length} issues and $commentCount comments as BCF 2.1.',
      );
    } on Exception catch (error) {
      _message('BCF export failed: $error');
    }
  }

  Future<void> _updateIssueStatus(String id, String status) async {
    try {
      await _repository.updateIssueStatus(id, status);
    } on Exception catch (error) {
      _message('Issue status could not be saved: $error');
    }
  }

  Future<void> _showIssueDetails(BimIssue issue) async {
    final commentController = TextEditingController();
    List<BimIssueComment> comments = [];
    String? commentLoadError;
    try {
      comments = await _repository.loadIssueComments(issue.id);
    } on Exception catch (error) {
      commentLoadError = error.toString();
    }
    if (!mounted) {
      commentController.dispose();
      return;
    }
    var submitting = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(issue.title),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(issue.description),
                    const SizedBox(height: 18),
                    Text('Discipline: ${issue.discipline}'),
                    Text('Location: ${issue.location}'),
                    Text('Assigned to: ${issue.assignedTo}'),
                    Text('Due: ${_dateLabel(issue.dueDate)}'),
                    const Divider(height: 28),
                    Text(
                      'Discussion (${comments.length})',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    if (commentLoadError != null)
                      Text('Comments could not be loaded: $commentLoadError')
                    else if (comments.isEmpty)
                      const Text(
                        'No comments yet.',
                        style: TextStyle(color: AppColors.textLight),
                      )
                    else
                      ...comments.map(
                        (comment) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(comment.body),
                          subtitle: Text(
                            '${comment.authorName} · ${_dateTimeLabel(comment.createdAt)}',
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: commentController,
                      minLines: 2,
                      maxLines: 4,
                      maxLength: 5000,
                      decoration: const InputDecoration(
                        labelText: 'Add coordination note',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: submitting || commentLoadError != null
                            ? null
                            : () async {
                                final body = commentController.text.trim();
                                if (body.isEmpty) return;
                                setDialogState(() => submitting = true);
                                try {
                                  final comment = await _repository
                                      .addIssueComment(issue.id, body);
                                  if (!dialogContext.mounted) return;
                                  setDialogState(() {
                                    comments = [...comments, comment];
                                    commentController.clear();
                                  });
                                } on Exception catch (error) {
                                  _message(
                                    'Comment could not be saved: $error',
                                  );
                                } finally {
                                  if (dialogContext.mounted) {
                                    setDialogState(() => submitting = false);
                                  }
                                }
                              },
                        icon: submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_outlined),
                        label: const Text('Add comment'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
    commentController.dispose();
  }

  Future<void> _showCreateIssueDialog() async {
    final title = TextEditingController();
    final description = TextEditingController();
    final discipline = TextEditingController();
    final location = TextEditingController();
    final assignedTo = TextEditingController();
    var severity = 'Medium';
    var dueDate = DateTime.now().add(const Duration(days: 7));

    final issue = await showDialog<BimIssue>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New coordination issue'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogField(title, 'Issue title'),
                  _dialogField(description, 'Description', maxLines: 3),
                  _dialogField(discipline, 'Discipline / trade pair'),
                  _dialogField(location, 'Model location / grid'),
                  _dialogField(assignedTo, 'Responsible coordinator'),
                  DropdownButtonFormField<String>(
                    initialValue: severity,
                    decoration: const InputDecoration(labelText: 'Severity'),
                    items: const ['Critical', 'High', 'Medium', 'Low']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => severity = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Due date'),
                    subtitle: Text(_dateLabel(dueDate)),
                    trailing: const Icon(Icons.calendar_month_outlined),
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: dialogContext,
                        initialDate: dueDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2040),
                      );
                      if (selected != null) {
                        setDialogState(() => dueDate = selected);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if ([
                  title,
                  description,
                  discipline,
                  location,
                  assignedTo,
                ].any((field) => field.text.trim().isEmpty)) {
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  BimIssue(
                    id: _newId('ISS'),
                    projectCode: _selectedProjectCode,
                    title: title.text.trim(),
                    description: description.text.trim(),
                    discipline: discipline.text.trim(),
                    location: location.text.trim(),
                    severity: severity,
                    status: 'Open',
                    assignedTo: assignedTo.text.trim(),
                    dueDate: dueDate,
                  ),
                );
              },
              child: const Text('Create issue'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    description.dispose();
    discipline.dispose();
    location.dispose();
    assignedTo.dispose();
    if (issue == null) return;
    try {
      await _repository.addIssue(issue);
      _message('Coordination issue created.');
    } on Exception catch (error) {
      _message('Issue could not be saved: $error');
    }
  }

  Widget _dialogField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
    ),
  );

  Future<void> _showRegisterModelDialog() async {
    final name = TextEditingController();
    final discipline = TextEditingController();
    final version = TextEditingController(text: 'v1');
    final model = await showDialog<BimModelRecord>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Register model metadata'),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(name, 'Model name'),
              _dialogField(discipline, 'Discipline'),
              _dialogField(version, 'Revision label'),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'This records metadata only. It does not upload or link a model file.',
                  style: TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if ([
                name,
                discipline,
                version,
              ].any((field) => field.text.trim().isEmpty)) {
                return;
              }
              Navigator.pop(
                dialogContext,
                BimModelRecord(
                  id: _newId('MOD'),
                  projectCode: _selectedProjectCode,
                  name: name.text.trim(),
                  discipline: discipline.text.trim(),
                  version: version.text.trim(),
                  status: 'In review',
                  updatedAt: DateTime.now(),
                ),
              );
            },
            child: const Text('Register'),
          ),
        ],
      ),
    );
    name.dispose();
    discipline.dispose();
    version.dispose();
    if (model == null) return;
    try {
      await _repository.addModel(model);
      setState(() => _selectedTab = 'Model register');
      _message('Model metadata registered.');
    } on Exception catch (error) {
      _message('Model metadata could not be saved: $error');
    }
  }

  String _newId(String type) =>
      'BIM-$type-${DateTime.now().microsecondsSinceEpoch}';

  String _dateLabel(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _dateTimeLabel(DateTime date) {
    final local = date.toLocal();
    return '${_dateLabel(local)} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}
