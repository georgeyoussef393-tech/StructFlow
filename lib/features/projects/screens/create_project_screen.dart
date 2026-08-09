import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:structflow/core/theme/app_colors.dart';
import 'package:structflow/features/projects/models/project_model.dart';
import 'package:structflow/features/projects/repositories/project_repository.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() =>
      _CreateProjectScreenState();
}

class _CreateProjectScreenState
    extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _clientController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();
  final _managerController = TextEditingController();

  final ProjectRepository _repository =
      ProjectRepository.instance;

  String _projectType = 'Commercial';

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _clientController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    _managerController.dispose();

    super.dispose();
  }

  // ================================================================
  // SELECT DATE
  // ================================================================

  Future<void> _selectDate({
    required bool isStartDate,
  }) async {
    final now = DateTime.now();

    final initialDate = isStartDate
        ? (_startDate ?? now)
        : (_endDate ?? _startDate ?? now);

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      if (isStartDate) {
        _startDate = selected;

        if (_endDate != null &&
            _endDate!.isBefore(selected)) {
          _endDate = null;
        }
      } else {
        _endDate = selected;
      }
    });
  }

  // ================================================================
  // CREATE PROJECT
  // ================================================================

  void _createProject() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null) {
      _showMessage(
        'Please select the project start date.',
      );
      return;
    }

    if (_endDate == null) {
      _showMessage(
        'Please select the expected end date.',
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      _showMessage(
        'End date cannot be before start date.',
      );
      return;
    }

    final name = _nameController.text.trim();

    final code =
        _codeController.text.trim().toUpperCase();

    final client =
        _clientController.text.trim();

    final location =
        _locationController.text.trim();

    final budget =
        _budgetController.text.trim();

    final manager =
        _managerController.text.trim();

    // ============================================================
    // CHECK DUPLICATE PROJECT CODE
    // ============================================================

    if (_repository.codeExists(code)) {
      _showMessage(
        'Project code $code already exists.',
      );
      return;
    }

    // ============================================================
    // CREATE PROJECT MODEL
    // ============================================================

    final newProject = ProjectModel(
      name: name,
      code: code,
      client: client,
      location: location,
      status: 'Planning',
      progress: 0.0,
      budget: _formatBudget(budget),
      team: 1,
      color: _getProjectColor(_projectType),
      icon: _getProjectIcon(_projectType),
    );

    // ============================================================
    // ADD TO REPOSITORY
    // ============================================================

    _repository.addProject(newProject);

    // ============================================================
    // SUCCESS DIALOG
    // ============================================================

    _showSuccessDialog(
      newProject,
      manager,
    );
  }

  // ================================================================
  // BUDGET FORMAT
  // ================================================================

  String _formatBudget(String value) {
    final cleanValue =
        value.replaceAll(',', '').trim();

    if (cleanValue.isEmpty) {
      return '\$0';
    }

    return '\$$cleanValue';
  }

  // ================================================================
  // PROJECT COLOR
  // ================================================================

  Color _getProjectColor(String type) {
    switch (type) {
      case 'Residential':
        return Colors.teal;

      case 'Industrial':
        return Colors.orange;

      case 'Infrastructure':
        return Colors.blue;

      case 'Hospitality':
        return Colors.purple;

      case 'Healthcare':
        return Colors.red;

      case 'Commercial':
      default:
        return Colors.green;
    }
  }

  // ================================================================
  // PROJECT ICON
  // ================================================================

  IconData _getProjectIcon(String type) {
    switch (type) {
      case 'Residential':
        return Icons.villa_rounded;

      case 'Industrial':
        return Icons.factory_rounded;

      case 'Infrastructure':
        return Icons.construction_rounded;

      case 'Hospitality':
        return Icons.hotel_rounded;

      case 'Healthcare':
        return Icons.local_hospital_rounded;

      case 'Commercial':
      default:
        return Icons.business_rounded;
    }
  }

  // ================================================================
  // SUCCESS DIALOG
  // ================================================================

  void _showSuccessDialog(
    ProjectModel project,
    String manager,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,

                decoration: BoxDecoration(
                  color:
                      Colors.green.withOpacity(.10),
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.green,
                  size: 40,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Project Created',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                '${project.name}\n${project.code}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Manager: $manager',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,

                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);

                    context.go('/projects');
                  },

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primary,
                    foregroundColor:
                        Colors.white,
                    elevation: 0,

                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 14,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),

                  child: const Text(
                    'Go to Projects',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================================================================
  // MESSAGE
  // ================================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF5F7FB),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile =
                constraints.maxWidth < 700;

            return SingleChildScrollView(
              padding: EdgeInsets.all(
                isMobile ? 16 : 30,
              ),

              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(
                    maxWidth: 1100,
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      _buildHeader(),

                      const SizedBox(height: 24),

                      _buildFormCard(isMobile),
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

  // ================================================================
  // HEADER
  // ================================================================

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        TextButton.icon(
          onPressed: () {
            context.go('/projects');
          },

          icon: const Icon(
            Icons.arrow_back_rounded,
          ),

          label: const Text(
            'Back to Projects',
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          'Create New Project',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Add the basic information for your construction project.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }

  // ================================================================
  // FORM CARD
  // ================================================================

  Widget _buildFormCard(
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,

      padding: EdgeInsets.all(
        isMobile ? 18 : 28,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),

        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),

      child: Form(
        key: _formKey,

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            _sectionTitle(
              Icons.info_outline_rounded,
              'Project Information',
            ),

            const SizedBox(height: 20),

            _buildBasicFields(isMobile),

            const SizedBox(height: 30),

            _sectionTitle(
              Icons.calendar_month_rounded,
              'Project Schedule',
            ),

            const SizedBox(height: 20),

            _buildDateFields(isMobile),

            const SizedBox(height: 30),

            _sectionTitle(
              Icons.account_balance_wallet_outlined,
              'Financial & Management',
            ),

            const SizedBox(height: 20),

            _buildFinancialFields(isMobile),

            const SizedBox(height: 35),

            const Divider(),

            const SizedBox(height: 24),

            _buildActions(isMobile),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // BASIC FIELDS
  // ================================================================

  Widget _buildBasicFields(
    bool isMobile,
  ) {
    final fields = [
      _textField(
        controller: _nameController,
        label: 'Project Name',
        hint: 'e.g. New Capital Tower',
        icon: Icons.apartment_rounded,
      ),

      _textField(
        controller: _codeController,
        label: 'Project Code',
        hint: 'e.g. PRJ-007',
        icon: Icons.tag_rounded,
      ),

      _textField(
        controller: _clientController,
        label: 'Client',
        hint: 'Client / Company name',
        icon: Icons.person_outline_rounded,
      ),

      _textField(
        controller: _locationController,
        label: 'Location',
        hint: 'Project location',
        icon: Icons.location_on_outlined,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          fields[0],
          const SizedBox(height: 16),
          fields[1],
          const SizedBox(height: 16),
          fields[2],
          const SizedBox(height: 16),
          fields[3],
          const SizedBox(height: 16),
          _projectTypeDropdown(),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: fields[0]),
            const SizedBox(width: 18),
            Expanded(child: fields[1]),
          ],
        ),

        const SizedBox(height: 18),

        Row(
          children: [
            Expanded(child: fields[2]),
            const SizedBox(width: 18),
            Expanded(child: fields[3]),
          ],
        ),

        const SizedBox(height: 18),

        _projectTypeDropdown(),
      ],
    );
  }

  // ================================================================
  // PROJECT TYPE
  // ================================================================

  Widget _projectTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _projectType,

      decoration: _inputDecoration(
        label: 'Project Type',
        icon: Icons.category_outlined,
      ),

      items: const [
        DropdownMenuItem(
          value: 'Commercial',
          child: Text('Commercial'),
        ),
        DropdownMenuItem(
          value: 'Residential',
          child: Text('Residential'),
        ),
        DropdownMenuItem(
          value: 'Industrial',
          child: Text('Industrial'),
        ),
        DropdownMenuItem(
          value: 'Infrastructure',
          child: Text('Infrastructure'),
        ),
        DropdownMenuItem(
          value: 'Hospitality',
          child: Text('Hospitality'),
        ),
        DropdownMenuItem(
          value: 'Healthcare',
          child: Text('Healthcare'),
        ),
      ],

      onChanged: (value) {
        if (value == null) {
          return;
        }

        setState(() {
          _projectType = value;
        });
      },
    );
  }

  // ================================================================
  // DATE FIELDS
  // ================================================================

  Widget _buildDateFields(
    bool isMobile,
  ) {
    final startField = _dateField(
      label: 'Start Date',
      date: _startDate,
      icon: Icons.play_arrow_rounded,
      onTap: () {
        _selectDate(
          isStartDate: true,
        );
      },
    );

    final endField = _dateField(
      label: 'Expected End Date',
      date: _endDate,
      icon: Icons.flag_rounded,
      onTap: () {
        _selectDate(
          isStartDate: false,
        );
      },
    );

    if (isMobile) {
      return Column(
        children: [
          startField,
          const SizedBox(height: 16),
          endField,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: startField),
        const SizedBox(width: 18),
        Expanded(child: endField),
      ],
    );
  }

  // ================================================================
  // DATE FIELD
  // ================================================================

  Widget _dateField({
    required String label,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,

      borderRadius:
          BorderRadius.circular(12),

      child: InputDecorator(
        decoration: _inputDecoration(
          label: label,
          icon: icon,
        ),

        child: Text(
          date == null
              ? 'Select date'
              : _formatDate(date),

          style: TextStyle(
            color: date == null
                ? AppColors.textLight
                : AppColors.textDark,

            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ================================================================
  // FINANCIAL FIELDS
  // ================================================================

  Widget _buildFinancialFields(
    bool isMobile,
  ) {
    final budgetField = _textField(
      controller: _budgetController,
      label: 'Budget',
      hint: 'e.g. 850000',
      icon:
          Icons.account_balance_wallet_outlined,
      keyboardType: TextInputType.number,
    );

    final managerField = _textField(
      controller: _managerController,
      label: 'Project Manager',
      hint: 'Manager name',
      icon: Icons.manage_accounts_outlined,
    );

    if (isMobile) {
      return Column(
        children: [
          budgetField,
          const SizedBox(height: 16),
          managerField,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: budgetField),
        const SizedBox(width: 18),
        Expanded(child: managerField),
      ],
    );
  }

  // ================================================================
  // TEXT FIELD
  // ================================================================

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,

      decoration: _inputDecoration(
        label: label,
        hint: hint,
        icon: icon,
      ),

      validator: (value) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'Required';
        }

        return null;
      },
    );
  }

  // ================================================================
  // INPUT DECORATION
  // ================================================================

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,

      prefixIcon: Icon(icon),

      filled: true,

      fillColor:
          const Color(0xffF8FAFC),

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),

        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),

        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),

        borderSide:
            const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),

      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),

        borderSide:
            const BorderSide(
          color: Colors.red,
        ),
      ),

      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),

        borderSide:
            const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
    );
  }

  // ================================================================
  // SECTION TITLE
  // ================================================================

  Widget _sectionTitle(
    IconData icon,
    String title,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,

          decoration: BoxDecoration(
            color:
                AppColors.primary.withOpacity(.10),
            borderRadius:
                BorderRadius.circular(12),
          ),

          child: Icon(
            icon,
            color: AppColors.primary,
            size: 21,
          ),
        ),

        const SizedBox(width: 12),

        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  // ================================================================
  // ACTIONS
  // ================================================================

  Widget _buildActions(
    bool isMobile,
  ) {
    final cancelButton =
        OutlinedButton(
      onPressed: () {
        context.go('/projects');
      },

      style: _secondaryButtonStyle(),

      child: const Text(
        'Cancel',
      ),
    );

    final createButton =
        ElevatedButton.icon(
      onPressed: _createProject,

      icon: const Icon(
        Icons.add_rounded,
      ),

      label: const Text(
        'Create Project',
      ),

      style: _primaryButtonStyle(),
    );

    if (isMobile) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: createButton,
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: cancelButton,
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment:
          MainAxisAlignment.end,

      children: [
        cancelButton,

        const SizedBox(width: 12),

        createButton,
      ],
    );
  }

  // ================================================================
  // BUTTON STYLES
  // ================================================================

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor:
          AppColors.primary,

      foregroundColor: Colors.white,

      elevation: 0,

      padding:
          const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 15,
      ),

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(12),
      ),
    );
  }

  ButtonStyle _secondaryButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor:
          AppColors.textDark,

      padding:
          const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 15,
      ),

      side: BorderSide(
        color: Colors.grey.shade300,
      ),

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(12),
      ),
    );
  }

  // ================================================================
  // DATE FORMAT
  // ================================================================

  String _formatDate(
    DateTime date,
  ) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}