import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:structflow/core/network/api_auth_client.dart';
import 'package:structflow/features/projects/models/project_model.dart';
import 'package:structflow/features/projects/repositories/project_repository.dart';

class EditProjectScreen extends StatefulWidget {
  const EditProjectScreen({
    super.key,
    required this.projectId,
    this.initialProject,
  });

  final String projectId;
  final ProjectModel? initialProject;

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _client = TextEditingController();
  final _location = TextEditingController();
  final _budget = TextEditingController();
  ProjectModel? _project;
  String _status = 'Planning';
  String _type = 'Commercial';
  String _currency = 'USD';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initialProject = widget.initialProject;
    if (initialProject != null) {
      _setProject(initialProject);
    } else {
      _loadProject();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _client.dispose();
    _location.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _loadProject() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final project = await ProjectRepository.instance.loadProject(
        widget.projectId,
      );
      if (mounted) _setProject(project);
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is AuthApiException
            ? error.message
            : 'Could not load project. Please try again.';
        _loading = false;
      });
    }
  }

  void _setProject(ProjectModel project) {
    _project = project;
    _name.text = project.name;
    _client.text = project.client;
    _location.text = project.location;
    final budgetParts = project.budget.trim().split(RegExp(r'\s+'));
    if (budgetParts.length > 1 &&
        RegExp(r'^[A-Z]{3}$').hasMatch(budgetParts.first)) {
      _currency = budgetParts.first;
      _budget.text = budgetParts.skip(1).join(' ');
    } else {
      _budget.text = project.budget;
    }
    _status = project.status;
    _type = project.projectType;
    _startDate = project.plannedStartDate;
    _endDate = project.plannedEndDate;
    setState(() {
      _error = null;
      _loading = false;
    });
  }

  Future<void> _selectDate({required bool start}) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: start
          ? (_startDate ?? now)
          : (_endDate ?? _startDate ?? now),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected == null) return;
    setState(() {
      if (start) {
        _startDate = selected;
        if (_endDate != null && _endDate!.isBefore(selected)) {
          _endDate = null;
        }
      } else {
        _endDate = selected;
      }
    });
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final current = _project;
    if (current == null) return;
    if (_startDate != null &&
        _endDate != null &&
        _endDate!.isBefore(_startDate!)) {
      setState(() => _error = 'End date cannot be before start date.');
      return;
    }

    final amount = _budget.text.trim().replaceAll(',', '');
    if (amount.isNotEmpty &&
        !RegExp(r'^\d{1,18}(\.\d{1,2})?$').hasMatch(amount)) {
      setState(
        () => _error = 'Enter a non-negative amount with up to 2 decimals.',
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final updated = ProjectModel(
      id: current.id,
      name: _name.text.trim(),
      code: current.code,
      organizationId: current.organizationId,
      client: _client.text.trim(),
      location: _location.text.trim(),
      projectType: _type,
      status: _status,
      progress: current.progress,
      budget: amount.isEmpty ? '' : '$_currency $amount',
      team: current.team,
      plannedStartDate: _startDate,
      plannedEndDate: _endDate,
      version: current.version,
      color: current.color,
      icon: current.icon,
    );
    try {
      final saved = await ProjectRepository.instance.updateProject(updated);
      if (saved == null) {
        throw StateError('The project could not be found.');
      }
      if (mounted) context.pop(saved);
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        if (error is AuthApiException && error.statusCode == 409) {
          _error =
              'This project changed since you opened it. Reload the latest '
              'version before making your changes.';
        } else {
          _error = error is AuthApiException
              ? error.message
              : 'Could not save project changes.';
        }
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Project'),
        leading: IconButton(
          onPressed: _saving ? null : () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _project == null
          ? _loadFailure()
          : _projectForm(),
    );
  }

  Widget _loadFailure() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children: [
              OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Back'),
              ),
              ElevatedButton(
                onPressed: _loadProject,
                child: const Text('Retry'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _projectForm() => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (_error != null) ...[
              MaterialBanner(
                content: Text(_error!),
                actions: [
                  if (_error!.contains('changed since'))
                    TextButton(
                      onPressed: _loadProject,
                      child: const Text('Reload latest'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Project name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                return text.length < 2 || text.length > 200
                    ? 'Enter a name between 2 and 200 characters.'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _project?.code,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Project code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _client,
              maxLength: 160,
              decoration: const InputDecoration(
                labelText: 'Client',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Project type',
                border: OutlineInputBorder(),
              ),
              items:
                  const [
                        'Commercial',
                        'Residential',
                        'Industrial',
                        'Infrastructure',
                        'Hospitality',
                        'Healthcare',
                      ]
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value != null) setState(() => _type = value);
                    },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _location,
              maxLength: 240,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items:
                  const [
                        ('Planning', 'Planning'),
                        ('Active', 'Active'),
                        ('On Hold', 'On Hold'),
                        ('Completed', 'Completed'),
                        ('Cancelled', 'Cancelled'),
                      ]
                      .map(
                        (status) => DropdownMenuItem(
                          value: status.$1,
                          child: Text(status.$2),
                        ),
                      )
                      .toList(),
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => _status = value);
                    },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _budget,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Budget (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _currency,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(),
                    ),
                    items: {'USD', 'EUR', 'GBP', 'EGP', 'SAR', 'AED', _currency}
                        .map(
                          (currency) => DropdownMenuItem(
                            value: currency,
                            child: Text(currency),
                          ),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _currency = value);
                            }
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _dateButton('Planned start', _startDate, () {
              _selectDate(start: true);
            }, () => setState(() => _startDate = null)),
            const SizedBox(height: 8),
            _dateButton('Planned end', _endDate, () {
              _selectDate(start: false);
            }, () => setState(() => _endDate = null)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving...' : 'Save changes'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _dateButton(
    String label,
    DateTime? date,
    VoidCallback onPressed,
    VoidCallback onClear,
  ) => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: _saving ? null : onPressed,
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text(
            '$label: ${date == null ? 'Not set' : date.toIso8601String().split('T').first}',
          ),
        ),
      ),
      if (date != null)
        IconButton(
          tooltip: 'Clear $label',
          onPressed: _saving ? null : onClear,
          icon: const Icon(Icons.clear_rounded),
        ),
    ],
  );
}
