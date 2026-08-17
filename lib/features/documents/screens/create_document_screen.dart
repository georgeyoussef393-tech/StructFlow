import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:structflow/core/theme/app_colors.dart';
import 'package:structflow/features/documents/data/engineering_document_catalog.dart';
import 'package:structflow/features/documents/models/document_model.dart';
import 'package:structflow/features/documents/repositories/document_repository.dart';
import 'package:structflow/features/projects/models/project_model.dart';
import 'package:structflow/features/projects/repositories/project_repository.dart';

class CreateDocumentScreen extends StatefulWidget {
  final String? documentId;

  const CreateDocumentScreen({
    super.key,
    this.documentId,
  });

  @override
  State<CreateDocumentScreen> createState() =>
      _CreateDocumentScreenState();
}

class _CreateDocumentScreenState
    extends State<CreateDocumentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _documentNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _submittedByController = TextEditingController();
  final _recipientController = TextEditingController();
  final _ccController = TextEditingController();

  final DocumentRepository _documentRepository =
      DocumentRepository.instance;

  final ProjectRepository _projectRepository =
      ProjectRepository.instance;

  ProjectModel? _selectedProject;

  // ==============================================================
  // ENGINEERING DOCUMENT TYPE
  // ==============================================================

  EngineeringDocumentType? _selectedDocumentType;

  String _category = 'Drawings';
  String _subCategory = 'General';
  String _documentType = 'General Arrangement';
  String _discipline = 'General';
  String _revision = 'Rev. 00';
  String _status = 'Draft';
  String _priority = 'Normal';
  String _confidentiality = 'Internal';

  DateTime _documentDate = DateTime.now();
  DateTime? _dueDate;

  bool _saving = false;
  bool _documentLoaded = false;

  bool get _isEditing => widget.documentId != null;

  // ==============================================================
  // INIT
  // ==============================================================

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      _loadDocumentForEditing();
    } else {
      if (_projectRepository.projects.isNotEmpty) {
        _selectedProject =
            _projectRepository.projects.first;
      }

      _selectedDocumentType =
          EngineeringDocumentCatalog.all.first;

      _documentType =
          _selectedDocumentType!.name;

      _category =
          _selectedDocumentType!.category;

      _discipline =
          _selectedDocumentType!.discipline;

      _generateDocumentNumber();

      _documentLoaded = true;
    }
  }

  // ==============================================================
  // LOAD DOCUMENT FOR EDIT
  // ==============================================================

  void _loadDocumentForEditing() {
    final document =
        _documentRepository.getDocumentById(
      widget.documentId!,
    );

    if (document == null) {
      _documentLoaded = false;
      return;
    }

    _titleController.text =
        document.title;

    _documentNumberController.text =
        document.documentNumber;

    _descriptionController.text =
        document.description;

    _submittedByController.text =
        document.submittedBy;

    _recipientController.text =
        document.recipient;

    _ccController.text =
        document.cc;

    _category =
        document.category;

    _subCategory =
        document.subCategory;

    _documentType =
        document.documentType;

    _discipline =
        document.discipline;

    _revision =
        document.revision;

    _status =
        document.status;

    _priority =
        document.priority;

    _confidentiality =
        document.confidentiality;

    _documentDate =
        document.date;

    _dueDate =
        document.dueDate;

    _selectedProject =
        _projectRepository.getProjectByCode(
      document.projectCode,
    );

    // ------------------------------------------------------------
    // Try to find the document inside the engineering catalog.
    // ------------------------------------------------------------

    _selectedDocumentType =
        _findDocumentType(
      document.documentType,
    );

    // ------------------------------------------------------------
    // If the document is an old/legacy type that does not exist
    // in the catalog, keep the existing saved values.
    // ------------------------------------------------------------

    if (_selectedDocumentType != null) {
      _documentType =
          _selectedDocumentType!.name;

      _category =
          _selectedDocumentType!.category;

      _discipline =
          _selectedDocumentType!.discipline;
    }

    _documentLoaded = true;
  }

  // ==============================================================
  // FIND DOCUMENT TYPE
  // ==============================================================

  EngineeringDocumentType? _findDocumentType(
    String value,
  ) {
    final query =
        value.trim().toLowerCase();

    if (query.isEmpty) {
      return null;
    }

    for (final document
        in EngineeringDocumentCatalog.all) {
      if (document.name.toLowerCase() ==
          query) {
        return document;
      }

      if (document.abbreviation
              .toLowerCase() ==
          query) {
        return document;
      }

      if (document.aliases.any(
        (alias) =>
            alias.toLowerCase() ==
            query,
      )) {
        return document;
      }
    }

    return null;
  }

  // ==============================================================
  // DISPOSE
  // ==============================================================

  @override
  void dispose() {
    _titleController.dispose();
    _documentNumberController.dispose();
    _descriptionController.dispose();
    _submittedByController.dispose();
    _recipientController.dispose();
    _ccController.dispose();

    super.dispose();
  }

  // ==============================================================
  // DOCUMENT NUMBER
  // ==============================================================

  void _generateDocumentNumber() {
    if (_isEditing) {
      return;
    }

    final projectCode =
        _selectedProject?.code ?? 'PRJ';

    final number =
        _documentRepository.nextDocumentId
            .replaceFirst(
      'DOC-',
      '',
    );

    final disciplineCode =
        _selectedDocumentType
                ?.abbreviation
                .toUpperCase() ??
            _discipline.toUpperCase();

    _documentNumberController.text =
        'DOC-$projectCode-$disciplineCode-$number';
  }

  // ==============================================================
  // SELECT ENGINEERING DOCUMENT TYPE
  // ==============================================================

  void _selectDocumentType(
    EngineeringDocumentType? value,
  ) {
    if (value == null) {
      return;
    }

    setState(() {
      _selectedDocumentType =
          value;

      _documentType =
          value.name;

      _discipline =
          value.discipline;

      _category =
          value.category;

      // Keep the old Sub Category field available.
      // It is intentionally not overwritten by the catalog.
      if (_subCategory.isEmpty) {
        _subCategory =
            'General';
      }

      if (!_isEditing) {
        _generateDocumentNumber();
      }
    });
  }

  // ==============================================================
  // CREATE / UPDATE
  // ==============================================================

  Future<void> _saveDocument() async {
    FocusScope.of(context).unfocus();

    if (!_documentLoaded) {
      _showMessage(
        'Document could not be found.',
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedProject == null) {
      _showMessage(
        'Please select a project.',
      );
      return;
    }

    if (_selectedDocumentType == null) {
      _showMessage(
        'Please select a document type.',
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final now =
          DateTime.now();

      final existingDocument =
          _isEditing
              ? _documentRepository
                  .getDocumentById(
                  widget.documentId!,
                )
              : null;

      if (_isEditing &&
          existingDocument == null) {
        if (!mounted) {
          return;
        }

        setState(() {
          _saving = false;
        });

        _showMessage(
          'The document no longer exists.',
        );

        return;
      }

      final documentId =
          existingDocument?.id ??
              _documentRepository
                  .nextDocumentId;

      final document =
          DocumentModel(
        id: documentId,

        // ----------------------------------------------------------
        // BASIC INFORMATION
        // ----------------------------------------------------------

        documentNumber:
            _documentNumberController
                .text
                .trim(),

        title:
            _titleController
                .text
                .trim(),

        projectCode:
            _selectedProject!.code,

        projectName:
            _selectedProject!.name,

        // ----------------------------------------------------------
        // CLASSIFICATION
        // ----------------------------------------------------------

        category:
            _category,

        subCategory:
            _subCategory,

        documentType:
            _documentType,

        discipline:
            _discipline,

        // ----------------------------------------------------------
        // REVISION / STATUS
        // ----------------------------------------------------------

        revision:
            _revision,

        status:
            _status,

        // ----------------------------------------------------------
        // COMMUNICATION
        // ----------------------------------------------------------

        from:
            _submittedByController
                .text
                .trim(),

        to:
            _recipientController
                .text
                .trim(),

        cc:
            _ccController
                .text
                .trim(),

        submittedBy:
            _submittedByController
                .text
                .trim(),

        recipient:
            _recipientController
                .text
                .trim(),

        // ----------------------------------------------------------
        // DATES
        // ----------------------------------------------------------

        date:
            _documentDate,

        createdBy:
            existingDocument
                    ?.createdBy ??
                _submittedByController
                    .text
                    .trim(),

        createdDate:
            existingDocument
                    ?.createdDate ??
                now,

        submittedDate:
            _status == 'Draft'
                ? null
                : (
                    existingDocument
                            ?.submittedDate ??
                        now
                  ),

        dueDate:
            _dueDate,

        responseDate:
            existingDocument
                ?.responseDate,

        // ----------------------------------------------------------
        // PRIORITY / SECURITY
        // ----------------------------------------------------------

        priority:
            _priority,

        confidentiality:
            _confidentiality,

        // ----------------------------------------------------------
        // DESCRIPTION
        // ----------------------------------------------------------

        description:
            _descriptionController
                .text
                .trim(),

        // ----------------------------------------------------------
        // ATTACHMENTS
        // ----------------------------------------------------------

        attachments:
            existingDocument
                    ?.attachments ??
                const [],

        // ----------------------------------------------------------
        // UI
        // ----------------------------------------------------------

        color:
            _documentColor(
          _selectedDocumentType!,
        ),

        icon:
            _documentIcon(
          _selectedDocumentType!,
        ),
      );

      if (_isEditing) {
        _documentRepository
            .updateDocument(
          document,
        );
      } else {
        _documentRepository
            .addDocument(
          document,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      _showSuccessDialog(
        document,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      _showMessage(
        'Failed to save document.',
      );
    }
  }

  // ==============================================================
  // DATE PICKER
  // ==============================================================

  Future<void> _selectDate({
    required bool dueDate,
  }) async {
    final initialDate =
        dueDate
            ? (_dueDate ??
                _documentDate)
            : _documentDate;

    final selected =
        await showDatePicker(
      context: context,
      initialDate:
          initialDate,
      firstDate:
          DateTime(2020),
      lastDate:
          DateTime(2100),
    );

    if (selected == null ||
        !mounted) {
      return;
    }

    if (dueDate) {
      if (selected.isBefore(
        _documentDate,
      )) {
        _showMessage(
          'Due date cannot be before document date.',
        );

        return;
      }

      setState(() {
        _dueDate =
            selected;
      });
    } else {
      setState(() {
        _documentDate =
            selected;

        if (_dueDate != null &&
            _dueDate!.isBefore(
              selected,
            )) {
          _dueDate =
              null;
        }
      });
    }
  }

  // ==============================================================
  // SUCCESS
  // ==============================================================

  void _showSuccessDialog(
    DocumentModel document,
  ) {
    showDialog(
      context: context,
      barrierDismissible:
          false,
      builder:
          (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),
          content:
              Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration:
                    BoxDecoration(
                  color:
                      Colors.green
                          .withValues(
                    alpha: .10,
                  ),
                  shape:
                      BoxShape.circle,
                ),
                child:
                    const Icon(
                  Icons
                      .check_rounded,
                  color:
                      Colors.green,
                  size: 40,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              Text(
                _isEditing
                    ? 'Document Updated'
                    : 'Document Created',
                style:
                    const TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      AppColors
                          .textDark,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              Text(
                document.title,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      AppColors
                          .textDark,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              Text(
                document
                    .documentNumber,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontSize: 13,
                  color:
                      AppColors
                          .textLight,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              Text(
                '${document.projectCode} • ${document.projectName}',
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontSize: 12,
                  color:
                      AppColors
                          .textLight,
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              SizedBox(
                width:
                    double.infinity,
                child:
                    ElevatedButton(
                  onPressed:
                      () {
                    Navigator.pop(
                      dialogContext,
                    );

                    context.go(
                      '/documents',
                    );
                  },
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        AppColors
                            .primary,
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 14,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                    ),
                  ),
                  child:
                      const Text(
                    'Go to Documents',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==============================================================
  // BUILD
  // ==============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (_isEditing &&
        !_documentLoaded) {
      return Scaffold(
        backgroundColor:
            const Color(
          0xffF5F7FB,
        ),
        body:
            Center(
          child:
              Container(
            padding:
                const EdgeInsets
                    .all(
              32,
            ),
            margin:
                const EdgeInsets
                    .all(
              24,
            ),
            decoration:
                BoxDecoration(
              color:
                  Colors.white,
              borderRadius:
                  BorderRadius
                      .circular(
                20,
              ),
            ),
            child:
                Column(
              mainAxisSize:
                  MainAxisSize
                      .min,
              children: [
                const Icon(
                  Icons
                      .description_outlined,
                  size: 60,
                  color:
                      Colors.grey,
                ),

                const SizedBox(
                  height: 20,
                ),

                const Text(
                  'Document Not Found',
                  style:
                      TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight
                            .bold,
                    color:
                        AppColors
                            .textDark,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                const Text(
                  'The requested document could not be found.',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color:
                        AppColors
                            .textLight,
                  ),
                ),

                const SizedBox(
                  height: 24,
                ),

                ElevatedButton
                    .icon(
                  onPressed:
                      () {
                    context.go(
                      '/documents',
                    );
                  },
                  icon:
                      const Icon(
                    Icons
                        .arrow_back_rounded,
                  ),
                  label:
                      const Text(
                    'Back to Documents',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          const Color(
        0xffF5F7FB,
      ),
      body:
          SafeArea(
        child:
            LayoutBuilder(
          builder:
              (
            context,
            constraints,
          ) {
            final isMobile =
                constraints
                        .maxWidth <
                    700;

            return SingleChildScrollView(
              padding:
                  EdgeInsets.all(
                isMobile
                    ? 16
                    : 30,
              ),
              child:
                  Center(
                child:
                    ConstrainedBox(
                  constraints:
                      const BoxConstraints(
                    maxWidth:
                        1100,
                  ),
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      _buildHeader(),

                      const SizedBox(
                        height: 24,
                      ),

                      _buildFormCard(
                        isMobile,
                      ),
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

  // ==============================================================
  // HEADER
  // ==============================================================

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment
              .start,
      children: [
        TextButton.icon(
          onPressed:
              _saving
                  ? null
                  : () {
                      context.go(
                        '/documents',
                      );
                    },
          icon:
              const Icon(
            Icons
                .arrow_back_rounded,
          ),
          label:
              const Text(
            'Back to Documents',
          ),
          style:
              TextButton.styleFrom(
            foregroundColor:
                AppColors
                    .primary,
          ),
        ),

        const SizedBox(
          height: 10,
        ),

        Text(
          _isEditing
              ? 'Edit Document'
              : 'Create New Document',
          style:
              const TextStyle(
            fontSize: 30,
            fontWeight:
                FontWeight.bold,
            color:
                AppColors
                    .textDark,
          ),
        ),

        const SizedBox(
          height: 6,
        ),

        Text(
          _isEditing
              ? 'Update and save project document information.'
              : 'Create and register a new project document.',
          style:
              const TextStyle(
            fontSize: 14,
            color:
                AppColors
                    .textLight,
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // FORM CARD
  // ==============================================================

  Widget _buildFormCard(
    bool isMobile,
  ) {
    return Container(
      width:
          double.infinity,
      padding:
          EdgeInsets.all(
        isMobile
            ? 18
            : 28,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius
                .circular(
          20,
        ),
        boxShadow:
            const [
          BoxShadow(
            color:
                Colors.black12,
            blurRadius:
                14,
            offset:
                Offset(
              0,
              5,
            ),
          ),
        ],
      ),
      child:
          Form(
        key:
            _formKey,
        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            _sectionTitle(
              Icons.folder_rounded,
              'Project & Document Information',
            ),

            const SizedBox(
              height: 20,
            ),

            _buildProjectFields(
              isMobile,
            ),

            const SizedBox(
              height: 30,
            ),

            _sectionTitle(
              Icons
                  .category_rounded,
              'Classification',
            ),

            const SizedBox(
              height: 20,
            ),

            _buildClassificationFields(
              isMobile,
            ),

            const SizedBox(
              height: 30,
            ),

            _sectionTitle(
              Icons.sync_rounded,
              'Revision & Status',
            ),

            const SizedBox(
              height: 20,
            ),

            _buildRevisionFields(
              isMobile,
            ),

            const SizedBox(
              height: 30,
            ),

            _sectionTitle(
              Icons
                  .people_alt_outlined,
              'Communication',
            ),

            const SizedBox(
              height: 20,
            ),

            _buildCommunicationFields(
              isMobile,
            ),

            const SizedBox(
              height: 30,
            ),

            _sectionTitle(
              Icons
                  .calendar_month_rounded,
              'Dates',
            ),

            const SizedBox(
              height: 20,
            ),

            _buildDateFields(
              isMobile,
            ),

            const SizedBox(
              height: 30,
            ),

            _sectionTitle(
              Icons
                  .shield_outlined,
              'Priority & Confidentiality',
            ),

            const SizedBox(
              height: 20,
            ),

            _buildPriorityFields(
              isMobile,
            ),

            const SizedBox(
              height: 30,
            ),

            _sectionTitle(
              Icons.notes_rounded,
              'Description',
            ),

            const SizedBox(
              height: 20,
            ),

            TextFormField(
              controller:
                  _descriptionController,
              maxLines:
                  5,
              decoration:
                  _inputDecoration(
                label:
                    'Document Description',
                hint:
                    'Enter document description...',
                icon:
                    Icons
                        .notes_rounded,
              ),
            ),

            const SizedBox(
              height: 35,
            ),

            const Divider(),

            const SizedBox(
              height: 24,
            ),

            _buildActions(
              isMobile,
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // PROJECT FIELDS
  // ==============================================================

  Widget _buildProjectFields(
    bool isMobile,
  ) {
    final projectField =
        DropdownButtonFormField<ProjectModel>(
      initialValue:
          _selectedProject,
      isExpanded:
          true,
      decoration:
          _inputDecoration(
        label:
            'Project',
        icon:
            Icons.folder_rounded,
      ),
      items:
          _projectRepository
              .projects
              .map(
        (
          project,
        ) {
          return DropdownMenuItem<
              ProjectModel>(
            value:
                project,
            child:
                Text(
              '${project.code} • ${project.name}',
              overflow:
                  TextOverflow
                      .ellipsis,
            ),
          );
        },
      ).toList(),
      validator:
          (
        value,
      ) {
        if (value ==
            null) {
          return 'Required';
        }

        return null;
      },
      onChanged:
          (
        value,
      ) {
        setState(() {
          _selectedProject =
              value;

          if (!_isEditing) {
            _generateDocumentNumber();
          }
        });
      },
    );

    final numberField =
        TextFormField(
      controller:
          _documentNumberController,
      readOnly:
          true,
      decoration:
          _inputDecoration(
        label:
            'Document Number',
        icon:
            Icons.tag_rounded,
      ),
    );

    if (isMobile) {
      return Column(
        children: [
          projectField,
          const SizedBox(
            height: 16,
          ),
          numberField,
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child:
              projectField,
        ),
        const SizedBox(
          width: 18,
        ),
        Expanded(
          child:
              numberField,
        ),
      ],
    );
  }

  // ==============================================================
  // CLASSIFICATION
  // ==============================================================

  Widget _buildClassificationFields(
    bool isMobile,
  ) {
    final documentTypeField =
        _buildEngineeringDocumentTypeField();

    final categoryField =
        _dropdownField(
      value:
          _category,
      label:
          'Category',
      icon:
          Icons
              .category_outlined,
      items:
          const [
        'Drawings',
        'Details',
        'Schedules',
        'Sections',
        'Profiles',
        'Design',
        'Diagrams',
        'Survey',
        'Correspondence',
        'Submittals',
        'Inspection',
        'Quality',
        'Reports',
        'Methodology',
        'Commercial',
        'Contracts',
        'Meetings',
        'HSE',
        'Issue Status',
        'Isometrics',
        'Other',
        'General',
      ],
      onChanged:
          (
        value,
      ) {
        setState(() {
          _category =
              value;
        });
      },
    );

    final subCategoryField =
        _dropdownField(
      value:
          _subCategory,
      label:
          'Sub Category',
      icon:
          Icons
              .account_tree_outlined,
      items:
          const [
        'General',
        'Drawings',
        'Coordination',
        'Cost Control',
        'Site Inspection',
        'RFI',
        'Submittals',
        'Correspondence',
        'Details',
        'Schedules',
        'Reports',
        'Quality',
        'Commercial',
        'Contracts',
        'HSE',
      ],
      onChanged:
          (
        value,
      ) {
        setState(() {
          _subCategory =
              value;
        });
      },
    );

    final disciplineField =
        _dropdownField(
      value:
          _discipline,
      label:
          'Discipline',
      icon:
          Icons
              .engineering_rounded,
      items:
          _disciplineOptions(),
      onChanged:
          (
        value,
      ) {
        setState(() {
          _discipline =
              value;

          if (!_isEditing) {
            _generateDocumentNumber();
          }
        });
      },
    );

    if (isMobile) {
      return Column(
        children: [
          documentTypeField,
          const SizedBox(
            height: 16,
          ),
          categoryField,
          const SizedBox(
            height: 16,
          ),
          subCategoryField,
          const SizedBox(
            height: 16,
          ),
          disciplineField,
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child:
                  documentTypeField,
            ),
            const SizedBox(
              width: 18,
            ),
            Expanded(
              child:
                  categoryField,
            ),
          ],
        ),

        const SizedBox(
          height: 18,
        ),

        Row(
          children: [
            Expanded(
              child:
                  subCategoryField,
            ),
            const SizedBox(
              width: 18,
            ),
            Expanded(
              child:
                  disciplineField,
            ),
          ],
        ),
      ],
    );
  }

  // ==============================================================
  // ENGINEERING DOCUMENT TYPE FIELD
  // ==============================================================

  Widget _buildEngineeringDocumentTypeField() {
    final catalog =
        EngineeringDocumentCatalog
            .all;

    final currentValue =
        _selectedDocumentType !=
                null &&
            catalog.contains(
              _selectedDocumentType,
            )
            ? _selectedDocumentType
            : null;

    return DropdownButtonFormField<
        EngineeringDocumentType>(
      initialValue:
          currentValue,
      isExpanded:
          true,
      decoration:
          _inputDecoration(
        label:
            'Document Type',
        hint:
            'Select engineering document type',
        icon:
            Icons
                .description_outlined,
      ),
      items:
          catalog.map(
        (
          document,
        ) {
          return DropdownMenuItem<
              EngineeringDocumentType>(
            value:
                document,
            child:
                Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal:
                        8,
                    vertical:
                        5,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        AppColors
                            .primary
                            .withValues(
                      alpha:
                          .08,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      6,
                    ),
                  ),
                  child:
                      Text(
                    document
                        .abbreviation,
                    style:
                        const TextStyle(
                      fontSize:
                          11,
                      fontWeight:
                          FontWeight
                              .bold,
                      color:
                          AppColors
                              .primary,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child:
                      Text(
                    document
                        .name,
                    overflow:
                        TextOverflow
                            .ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ).toList(),
      validator:
          (
        value,
      ) {
        if (value ==
            null) {
          return 'Required';
        }

        return null;
      },
      onChanged:
          _selectDocumentType,
    );
  }

  // ==============================================================
  // DISCIPLINE OPTIONS
  // ==============================================================

  List<String> _disciplineOptions() {
    final values =
        EngineeringDocumentCatalog
            .all
            .map(
              (
                document,
              ) =>
                  document.discipline,
            )
            .toSet()
            .toList();

    values.sort();

    return values;
  }

  // ==============================================================
  // REVISION
  // ==============================================================

  Widget _buildRevisionFields(
    bool isMobile,
  ) {
    final fields = [
      _dropdownField(
        value:
            _revision,
        label:
            'Revision',
        icon:
            Icons
                .history_rounded,
        items:
            const [
          'Rev. 00',
          'Rev. 01',
          'Rev. 02',
          'Rev. 03',
          'Rev. 04',
          'Rev. 05',
        ],
        onChanged:
            (
          value,
        ) {
          setState(() {
            _revision =
                value;
          });
        },
      ),

      _dropdownField(
        value:
            _status,
        label:
            'Status',
        icon:
            Icons
                .flag_outlined,
        items:
            const [
          'Draft',
          'Pending',
          'Submitted',
          'Under Review',
          'Approved',
          'Rejected',
          'Closed',
        ],
        onChanged:
            (
          value,
        ) {
          setState(() {
            _status =
                value;
          });
        },
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          fields[0],
          const SizedBox(
            height: 16,
          ),
          fields[1],
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child:
              fields[0],
        ),
        const SizedBox(
          width: 18,
        ),
        Expanded(
          child:
              fields[1],
        ),
      ],
    );
  }

  // ==============================================================
  // COMMUNICATION
  // ==============================================================

  Widget _buildCommunicationFields(
    bool isMobile,
  ) {
    final fields = [
      _textField(
        controller:
            _submittedByController,
        label:
            'From / Submitted By',
        hint:
            'Person or company',
        icon:
            Icons
                .person_outline_rounded,
      ),

      _textField(
        controller:
            _recipientController,
        label:
            'To / Recipient',
        hint:
            'Recipient',
        icon:
            Icons
                .person_search_rounded,
      ),

      _textField(
        controller:
            _ccController,
        label:
            'CC',
        hint:
            'Optional',
        icon:
            Icons
                .people_outline_rounded,
        requiredField:
            false,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          fields[0],
          const SizedBox(
            height: 16,
          ),
          fields[1],
          const SizedBox(
            height: 16,
          ),
          fields[2],
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child:
              fields[0],
        ),
        const SizedBox(
          width: 18,
        ),
        Expanded(
          child:
              fields[1],
        ),
        const SizedBox(
          width: 18,
        ),
        Expanded(
          child:
              fields[2],
        ),
      ],
    );
  }

  // ==============================================================
  // DATES
  // ==============================================================

  Widget _buildDateFields(
    bool isMobile,
  ) {
    final dateField =
        _dateField(
      label:
          'Document Date',
      date:
          _documentDate,
      icon:
          Icons
              .calendar_today_outlined,
      onTap:
          () {
        _selectDate(
          dueDate:
              false,
        );
      },
    );

    final dueDateField =
        _dateField(
      label:
          'Due Date',
      date:
          _dueDate,
      icon:
          Icons
              .event_available_outlined,
      onTap:
          () {
        _selectDate(
          dueDate:
              true,
        );
      },
    );

    if (isMobile) {
      return Column(
        children: [
          dateField,
          const SizedBox(
            height: 16,
          ),
          dueDateField,
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child:
              dateField,
        ),
        const SizedBox(
          width: 18,
        ),
        Expanded(
          child:
              dueDateField,
        ),
      ],
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap:
          onTap,
      borderRadius:
          BorderRadius.circular(
        12,
      ),
      child:
          InputDecorator(
        decoration:
            _inputDecoration(
          label:
              label,
          icon:
              icon,
        ),
        child:
            Text(
          date == null
              ? 'Select date'
              : _formatDate(
                  date,
                ),
          style:
              TextStyle(
            color:
                date == null
                    ? AppColors
                        .textLight
                    : AppColors
                        .textDark,
            fontSize:
                14,
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // PRIORITY
  // ==============================================================

  Widget _buildPriorityFields(
    bool isMobile,
  ) {
    final priorityField =
        _dropdownField(
      value:
          _priority,
      label:
          'Priority',
      icon:
          Icons
              .priority_high_rounded,
      items:
          const [
        'Low',
        'Normal',
        'High',
        'Urgent',
      ],
      onChanged:
          (
        value,
      ) {
        setState(() {
          _priority =
              value;
        });
      },
    );

    final confidentialityField =
        _dropdownField(
      value:
          _confidentiality,
      label:
          'Confidentiality',
      icon:
          Icons
              .lock_outline_rounded,
      items:
          const [
        'Public',
        'Internal',
        'Confidential',
        'Restricted',
      ],
      onChanged:
          (
        value,
      ) {
        setState(() {
          _confidentiality =
              value;
        });
      },
    );

    if (isMobile) {
      return Column(
        children: [
          priorityField,
          const SizedBox(
            height: 16,
          ),
          confidentialityField,
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child:
              priorityField,
        ),
        const SizedBox(
          width: 18,
        ),
        Expanded(
          child:
              confidentialityField,
        ),
      ],
    );
  }

  // ==============================================================
  // TEXT FIELD
  // ==============================================================

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool requiredField = true,
  }) {
    return TextFormField(
      controller:
          controller,
      decoration:
          _inputDecoration(
        label:
            label,
        hint:
            hint,
        icon:
            icon,
      ),
      validator:
          (
        value,
      ) {
        if (!requiredField) {
          return null;
        }

        if (value ==
                null ||
            value
                .trim()
                .isEmpty) {
          return 'Required';
        }

        return null;
      },
    );
  }

  // ==============================================================
  // DROPDOWN
  // ==============================================================

  Widget _dropdownField({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue:
          items.contains(
            value,
          )
              ? value
              : null,
      isExpanded:
          true,
      decoration:
          _inputDecoration(
        label:
            label,
        icon:
            icon,
      ),
      items:
          items.map(
        (
          item,
        ) {
          return DropdownMenuItem<
              String>(
            value:
                item,
            child:
                Text(
              item,
              overflow:
                  TextOverflow
                      .ellipsis,
            ),
          );
        },
      ).toList(),
      onChanged:
          (
        value,
      ) {
        if (value !=
            null) {
          onChanged(
            value,
          );
        }
      },
    );
  }

  // ==============================================================
  // INPUT DECORATION
  // ==============================================================

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText:
          label,
      hintText:
          hint,
      prefixIcon:
          Icon(
        icon,
      ),
      filled:
          true,
      fillColor:
          const Color(
        0xffF8FAFC,
      ),
      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius
                .circular(
          12,
        ),
        borderSide:
            BorderSide(
          color:
              Colors.grey
                  .shade200,
        ),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius
                .circular(
          12,
        ),
        borderSide:
            BorderSide(
          color:
              Colors.grey
                  .shade200,
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius
                .circular(
          12,
        ),
        borderSide:
            const BorderSide(
          color:
              AppColors
                  .primary,
          width:
              1.5,
        ),
      ),
      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius
                .circular(
          12,
        ),
        borderSide:
            const BorderSide(
          color:
              Colors.red,
        ),
      ),
      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius
                .circular(
          12,
        ),
        borderSide:
            const BorderSide(
          color:
              Colors.red,
          width:
              1.5,
        ),
      ),
    );
  }

  // ==============================================================
  // SECTION TITLE
  // ==============================================================

  Widget _sectionTitle(
    IconData icon,
    String title,
  ) {
    return Row(
      children: [
        Container(
          width:
              40,
          height:
              40,
          decoration:
              BoxDecoration(
            color:
                AppColors
                    .primary
                    .withValues(
              alpha:
                  .10,
            ),
            borderRadius:
                BorderRadius
                    .circular(
              12,
            ),
          ),
          child:
              Icon(
            icon,
            color:
                AppColors
                    .primary,
            size:
                21,
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        Expanded(
          child:
              Text(
            title,
            style:
                const TextStyle(
              fontSize:
                  18,
              fontWeight:
                  FontWeight
                      .bold,
              color:
                  AppColors
                      .textDark,
            ),
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // ACTIONS
  // ==============================================================

  Widget _buildActions(
    bool isMobile,
  ) {
    final cancelButton =
        OutlinedButton(
      onPressed:
          _saving
              ? null
              : () {
                  context.go(
                    '/documents',
                  );
                },
      style:
          _secondaryButtonStyle(),
      child:
          const Text(
        'Cancel',
      ),
    );

    final saveButton =
        ElevatedButton.icon(
      onPressed:
          _saving
              ? null
              : _saveDocument,
      icon:
          _saving
              ? const SizedBox(
                  width:
                      18,
                  height:
                      18,
                  child:
                      CircularProgressIndicator(
                    strokeWidth:
                        2,
                    color:
                        Colors.white,
                  ),
                )
              : Icon(
                  _isEditing
                      ? Icons
                          .save_rounded
                      : Icons
                          .add_rounded,
                ),
      label:
          Text(
        _saving
            ? 'Saving...'
            : (_isEditing
                ? 'Update Document'
                : 'Create Document'),
      ),
      style:
          _primaryButtonStyle(),
    );

    if (isMobile) {
      return Column(
        children: [
          SizedBox(
            width:
                double.infinity,
            child:
                saveButton,
          ),
          const SizedBox(
            height: 10,
          ),
          SizedBox(
            width:
                double.infinity,
            child:
                cancelButton,
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment:
          MainAxisAlignment
              .end,
      children: [
        cancelButton,
        const SizedBox(
          width: 12,
        ),
        saveButton,
      ],
    );
  }

  // ==============================================================
  // BUTTON STYLES
  // ==============================================================

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton
        .styleFrom(
      backgroundColor:
          AppColors
              .primary,
      foregroundColor:
          Colors.white,
      elevation:
          0,
      padding:
          const EdgeInsets
              .symmetric(
        horizontal:
            24,
        vertical:
            15,
      ),
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius
                .circular(
          12,
        ),
      ),
    );
  }

  ButtonStyle _secondaryButtonStyle() {
    return OutlinedButton
        .styleFrom(
      foregroundColor:
          AppColors
              .textDark,
      padding:
          const EdgeInsets
              .symmetric(
        horizontal:
            24,
        vertical:
            15,
      ),
      side:
          BorderSide(
        color:
            Colors.grey
                .shade300,
      ),
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius
                .circular(
          12,
        ),
      ),
    );
  }

  // ==============================================================
  // DOCUMENT COLOR
  // ==============================================================

  Color _documentColor(
    EngineeringDocumentType type,
  ) {
    switch (type.category) {
      case 'Drawings':
        return Colors.blue;

      case 'Details':
        return Colors.indigo;

      case 'Schedules':
        return Colors.teal;

      case 'Sections':
        return Colors.cyan;

      case 'Profiles':
        return Colors.deepPurple;

      case 'Design':
        return Colors.purple;

      case 'Diagrams':
        return Colors.orange;

      case 'Survey':
        return Colors.brown;

      case 'Correspondence':
        return Colors.blueGrey;

      case 'Submittals':
        return Colors.teal;

      case 'Inspection':
        return Colors.amber;

      case 'Quality':
        return Colors.red;

      case 'Reports':
        return Colors.purple;

      case 'Methodology':
        return Colors.deepOrange;

      case 'Commercial':
        return Colors.green;

      case 'Contracts':
        return Colors.red;

      case 'Meetings':
        return Colors.indigo;

      case 'HSE':
        return Colors.orange;

      case 'Issue Status':
        return Colors.blue;

      case 'Isometrics':
        return Colors.deepPurple;

      default:
        return AppColors
            .primary;
    }
  }

  // ==============================================================
  // DOCUMENT ICON
  // ==============================================================

  IconData _documentIcon(
    EngineeringDocumentType type,
  ) {
    final category =
        type.category
            .toLowerCase();

    final discipline =
        type.discipline
            .toLowerCase();

    final abbreviation =
        type.abbreviation
            .toUpperCase();

    if (abbreviation ==
        'RFI') {
      return Icons
          .question_answer_rounded;
    }

    if (abbreviation ==
        'BOQ') {
      return Icons
          .request_quote_rounded;
    }

    if (abbreviation ==
        'MOM') {
      return Icons
          .groups_rounded;
    }

    if (abbreviation ==
        'NCR') {
      return Icons
          .report_problem_rounded;
    }

    if (abbreviation ==
        'ITP') {
      return Icons
          .fact_check_rounded;
    }

    if (abbreviation ==
        'WIR') {
      return Icons
          .engineering_rounded;
    }

    if (abbreviation ==
        'MIR') {
      return Icons
          .inventory_2_rounded;
    }

    if (abbreviation ==
        'P&ID') {
      return Icons
          .schema_rounded;
    }

    if (abbreviation ==
        'PFD') {
      return Icons
          .account_tree_rounded;
    }

    if (abbreviation ==
        'HVAC') {
      return Icons
          .air_rounded;
    }

    if (abbreviation ==
        'CCTV') {
      return Icons
          .videocam_rounded;
    }

    if (abbreviation ==
        'FA') {
      return Icons
          .notifications_active_rounded;
    }

    if (abbreviation ==
        'FF') {
      return Icons
          .local_fire_department_rounded;
    }

    if (abbreviation ==
        'SD') {
      return Icons
          .architecture_rounded;
    }

    if (discipline ==
        'architecture') {
      return Icons
          .architecture_rounded;
    }

    if (discipline ==
        'structural') {
      return Icons
          .account_balance_rounded;
    }

    if (discipline ==
        'electrical') {
      return Icons
          .bolt_rounded;
    }

    if (discipline ==
        'mechanical') {
      return Icons
          .settings_rounded;
    }

    if (discipline ==
        'plumbing') {
      return Icons
          .water_drop_rounded;
    }

    if (discipline ==
        'roads') {
      return Icons
          .alt_route_rounded;
    }

    if (discipline ==
        'bridges') {
      return Icons
          .directions_rounded;
    }

    if (discipline ==
        'drainage') {
      return Icons
          .water_rounded;
    }

    if (discipline ==
        'survey') {
      return Icons
          .straighten_rounded;
    }

    if (discipline ==
        'geotechnical') {
      return Icons
          .terrain_rounded;
    }

    if (discipline ==
        'landscape') {
      return Icons
          .park_rounded;
    }

    if (discipline ==
        'hse') {
      return Icons
          .health_and_safety_rounded;
    }

    if (discipline ==
        'commercial') {
      return Icons
          .request_quote_rounded;
    }

    if (discipline ==
        'contractual') {
      return Icons
          .gavel_rounded;
    }

    if (category ==
        'drawings') {
      return Icons
          .description_rounded;
    }

    if (category ==
        'schedules') {
      return Icons
          .table_chart_rounded;
    }

    if (category ==
        'diagrams') {
      return Icons
          .schema_rounded;
    }

    if (category ==
        'reports') {
      return Icons
          .assignment_rounded;
    }

    if (category ==
        'correspondence') {
      return Icons
          .mail_outline_rounded;
    }

    if (category ==
        'contracts') {
      return Icons
          .gavel_rounded;
    }

    if (category ==
        'hse') {
      return Icons
          .health_and_safety_rounded;
    }

    return Icons
        .description_rounded;
  }

  // ==============================================================
  // DATE FORMAT
  // ==============================================================

  String _formatDate(
    DateTime date,
  ) {
    final day =
        date.day.toString().padLeft(
              2,
              '0',
            );

    final month =
        date.month.toString().padLeft(
              2,
              '0',
            );

    return '$day/$month/${date.year}';
  }

  // ==============================================================
  // MESSAGE
  // ==============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(
          message,
        ),
        behavior:
            SnackBarBehavior
                .floating,
      ),
    );
  }
}