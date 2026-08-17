import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:structflow/core/theme/app_colors.dart';
import 'package:structflow/features/documents/models/document_model.dart';
import 'package:structflow/features/documents/repositories/document_repository.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() =>
      _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final DocumentRepository _repository =
      DocumentRepository.instance;

  final TextEditingController _searchController =
      TextEditingController();

  String _selectedStatus = 'All';
  String _selectedType = 'All';

  @override
  void initState() {
    super.initState();

    _repository.addListener(_onDocumentsChanged);
  }

  @override
  void dispose() {
    _repository.removeListener(_onDocumentsChanged);
    _searchController.dispose();

    super.dispose();
  }

  // ==============================================================
  // REPOSITORY LISTENER
  // ==============================================================

  void _onDocumentsChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // ==============================================================
  // FILTERED DOCUMENTS
  // ==============================================================

  List<DocumentModel> get _filteredDocuments {
    final query =
        _searchController.text.trim().toLowerCase();

    return _repository.documents.where((document) {
      final matchesSearch =
          query.isEmpty ||
          document.id.toLowerCase().contains(query) ||
          document.documentNumber.toLowerCase().contains(query) ||
          document.title.toLowerCase().contains(query) ||
          document.projectName.toLowerCase().contains(query) ||
          document.projectCode.toLowerCase().contains(query) ||
          document.category.toLowerCase().contains(query) ||
          document.subCategory.toLowerCase().contains(query) ||
          document.documentType.toLowerCase().contains(query) ||
          document.discipline.toLowerCase().contains(query) ||
          document.submittedBy.toLowerCase().contains(query) ||
          document.recipient.toLowerCase().contains(query);

      final matchesStatus =
          _selectedStatus == 'All' ||
          document.status == _selectedStatus;

      final matchesType =
          _selectedType == 'All' ||
          document.documentType == _selectedType;

      return matchesSearch &&
          matchesStatus &&
          matchesType;
    }).toList();
  }

  // ==============================================================
  // BUILD
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            return SingleChildScrollView(
              padding: EdgeInsets.all(
                width < 600 ? 16 : 28,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildHeader(width),

                  const SizedBox(height: 24),

                  _buildSummaryCards(width),

                  const SizedBox(height: 24),

                  _buildToolbar(width),

                  const SizedBox(height: 20),

                  _buildDocumentsSection(width),
                ],
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

  Widget _buildHeader(double width) {
    final isMobile = width < 650;

    if (isMobile) {
      return Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () {
              context.go('/');
            },
            icon: const Icon(
              Icons.arrow_back_rounded,
            ),
            label: const Text(
              'Back to Dashboard',
            ),
            style: TextButton.styleFrom(
              foregroundColor:
                  AppColors.primary,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 4,
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Documents',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Manage project documents, submissions and approvals.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: _buildAddDocumentButton(),
          ),
        ],
      );
    }

    return Row(
      children: [
        IconButton(
          onPressed: () {
            context.go('/');
          },
          tooltip: 'Back to Dashboard',
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),

        const SizedBox(width: 8),

        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Documents',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Manage project documents, submissions and approvals.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),

        _buildAddDocumentButton(),
      ],
    );
  }

  // ==============================================================
  // NEW DOCUMENT
  // ==============================================================

  Widget _buildAddDocumentButton() {
    return ElevatedButton.icon(
      onPressed: () {
        context.go('/create-document');
      },
      icon: const Icon(
        Icons.upload_file_rounded,
        size: 20,
      ),
      label: const Text(
        'New Document',
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            AppColors.primary,
        foregroundColor:
            Colors.white,
        elevation: 0,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ==============================================================
  // SUMMARY CARDS
  // ==============================================================

  Widget _buildSummaryCards(double width) {
    final columns =
        width >= 1000
            ? 4
            : width >= 650
                ? 2
                : 1;

    final cards = [
      _SummaryData(
        title: 'Total Documents',
        value:
            '${_repository.documentCount}',
        subtitle: 'All project documents',
        icon: Icons.folder_copy_rounded,
        color: Colors.blue,
      ),
      _SummaryData(
        title: 'Pending',
        value:
            '${_repository.pendingCount}',
        subtitle: 'Awaiting action',
        icon: Icons.pending_actions_rounded,
        color: Colors.orange,
      ),
      _SummaryData(
        title: 'Under Review',
        value:
            '${_repository.reviewCount}',
        subtitle: 'Currently being reviewed',
        icon: Icons.rate_review_rounded,
        color: Colors.purple,
      ),
      _SummaryData(
        title: 'Approved',
        value:
            '${_repository.approvedCount}',
        subtitle: 'Approved documents',
        icon: Icons.check_circle_rounded,
        color: Colors.green,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 140,
      ),
      itemBuilder: (context, index) {
        return _buildSummaryCard(
          cards[index],
        );
      },
    );
  }

  Widget _buildSummaryCard(
    _SummaryData data,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: data.color.withValues(
                alpha: .10,
              ),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Icon(
              data.icon,
              color: data.color,
              size: 25,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style:
                      const TextStyle(
                    fontSize: 13,
                    color:
                        AppColors.textLight,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  data.value,
                  style:
                      const TextStyle(
                    fontSize: 25,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        AppColors.textDark,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  data.subtitle,
                  style:
                      const TextStyle(
                    fontSize: 11,
                    color:
                        AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // TOOLBAR
  // ==============================================================

  Widget _buildToolbar(double width) {
    final isMobile = width < 800;

    if (isMobile) {
      return Column(
        children: [
          _buildSearch(),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child:
                    _buildStatusFilter(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child:
                    _buildTypeFilter(),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildSearch(),
        ),

        const SizedBox(width: 14),

        _buildStatusFilter(),

        const SizedBox(width: 10),

        _buildTypeFilter(),
      ],
    );
  }

  // ==============================================================
  // SEARCH
  // ==============================================================

  Widget _buildSearch() {
    return TextField(
      controller:
          _searchController,
      onChanged: (_) {
        setState(() {});
      },
      decoration:
          InputDecoration(
        hintText:
            'Search documents, projects, IDs...',
        prefixIcon:
            const Icon(
          Icons.search_rounded,
        ),
        suffixIcon:
            _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon:
                        const Icon(
                      Icons.close_rounded,
                    ),
                  )
                : null,
        filled: true,
        fillColor: Colors.white,
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              BorderSide.none,
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              BorderSide.none,
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              const BorderSide(
            color:
                AppColors.primary,
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // STATUS FILTER
  // ==============================================================

  Widget _buildStatusFilter() {
    return _filterDropdown(
      value: _selectedStatus,
      items: const [
        'All',
        'Draft',
        'Pending',
        'Submitted',
        'Under Review',
        'Approved',
        'Rejected',
        'Closed',
      ],
      icon:
          Icons.filter_alt_outlined,
      onChanged: (value) {
        setState(() {
          _selectedStatus = value;
        });
      },
    );
  }

  // ==============================================================
  // TYPE FILTER
  // ==============================================================

  Widget _buildTypeFilter() {
    return _filterDropdown(
      value: _selectedType,
      items: const [
        'All',
        'Drawing',
        'BOQ',
        'Report',
        'RFI',
        'Submittal',
        'Letter',
        'Contract',
        'Minutes',
        'Other',
      ],
      icon:
          Icons.description_outlined,
      onChanged: (value) {
        setState(() {
          _selectedType = value;
        });
      },
    );
  }

  Widget _filterDropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String>
        onChanged,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(14),
      ),
      child:
          DropdownButtonHideUnderline(
        child:
            DropdownButton<String>(
          value: value,
          icon:
              const Icon(
            Icons.keyboard_arrow_down_rounded,
          ),
          borderRadius:
              BorderRadius.circular(14),
          items: items.map(
            (item) {
              return DropdownMenuItem<String>(
                value: item,
                child:
                    Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 17,
                      color:
                          Colors.grey.shade600,
                    ),
                    const SizedBox(width: 7),
                    Text(item),
                  ],
                ),
              );
            },
          ).toList(),
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }

  // ==============================================================
  // DOCUMENTS SECTION
  // ==============================================================

  Widget _buildDocumentsSection(
    double width,
  ) {
    final documents =
        _filteredDocuments;

    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.all(
        width < 600 ? 16 : 22,
      ),
      decoration:
          BoxDecoration(
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
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Project Documents',
                  style:
                      TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        AppColors.textDark,
                  ),
                ),
              ),

              Text(
                '${documents.length} documents',
                style:
                    const TextStyle(
                  fontSize: 13,
                  color:
                      AppColors.textLight,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (documents.isEmpty)
            _buildEmptyState()
          else
            _buildDocumentGrid(
              documents,
              width,
            ),
        ],
      ),
    );
  }

  // ==============================================================
  // DOCUMENT GRID
  // ==============================================================

  Widget _buildDocumentGrid(
    List<DocumentModel> documents,
    double width,
  ) {
    final columns =
        width >= 1250
            ? 3
            : width >= 750
                ? 2
                : 1;

    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      itemCount:
          documents.length,
      gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            columns,
        crossAxisSpacing:
            18,
        mainAxisSpacing:
            18,
        mainAxisExtent:
            300,
      ),
      itemBuilder:
          (context, index) {
        return _buildDocumentCard(
          documents[index],
        );
      },
    );
  }

  // ==============================================================
  // DOCUMENT CARD
  // ==============================================================

  Widget _buildDocumentCard(
    DocumentModel document,
  ) {
    return InkWell(
      onTap: () {
        context.go(
          '/documents/${Uri.encodeComponent(document.id)}',
        );
      },
      borderRadius:
          BorderRadius.circular(18),
      child: Container(
        padding:
            const EdgeInsets.all(18),
        decoration:
            BoxDecoration(
          color:
              const Color(0xffFBFCFE),
          borderRadius:
              BorderRadius.circular(18),
          border:
              Border.all(
            color:
                Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration:
                      BoxDecoration(
                    color:
                        document.color.withValues(
                      alpha: .10,
                    ),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: Icon(
                    document.icon,
                    color:
                        document.color,
                    size: 26,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.documentNumber,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          fontSize: 11,
                          color:
                              AppColors.textLight,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        document.revision,
                        style:
                            const TextStyle(
                          fontSize: 12,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                _statusBadge(
                  document.status,
                ),
              ],
            ),

            const SizedBox(height: 15),

            Text(
              document.title,
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
                color:
                    AppColors.textDark,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              document.documentType,
              style:
                  TextStyle(
                fontSize: 12,
                fontWeight:
                    FontWeight.w600,
                color:
                    document.color,
              ),
            ),

            const SizedBox(height: 12),

            _infoRow(
              Icons.folder_outlined,
              document.projectName,
            ),

            const SizedBox(height: 8),

            _infoRow(
              Icons.engineering_outlined,
              document.discipline,
            ),

            const SizedBox(height: 8),

            _infoRow(
              Icons.person_outline_rounded,
              document.submittedBy,
            ),

            const SizedBox(height: 8),

            _infoRow(
              Icons.calendar_today_outlined,
              _formatDate(
                document.date,
              ),
            ),

            const Spacer(),

            Row(
              children: [
                Text(
                  'View Document',
                  style:
                      TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        document.color,
                  ),
                ),

                const Spacer(),

                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color:
                      document.color,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // STATUS BADGE
  // ==============================================================

  Widget _statusBadge(
    String status,
  ) {
    final color =
        _statusColor(status);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha: .10,
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child:
          Text(
        status,
        maxLines: 1,
        overflow:
            TextOverflow.ellipsis,
        style:
            TextStyle(
          color: color,
          fontSize: 10,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  Color _statusColor(
    String status,
  ) {
    switch (status) {
      case 'Pending':
        return Colors.orange;

      case 'Submitted':
        return Colors.blue;

      case 'Under Review':
        return Colors.purple;

      case 'Approved':
        return Colors.green;

      case 'Draft':
        return Colors.grey;

      case 'Rejected':
        return Colors.red;

      case 'Closed':
        return Colors.black54;

      default:
        return Colors.grey;
    }
  }

  // ==============================================================
  // INFO ROW
  // ==============================================================

  Widget _infoRow(
    IconData icon,
    String text,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color:
              Colors.grey.shade500,
        ),

        const SizedBox(width: 7),

        Expanded(
          child:
              Text(
            text.isEmpty
                ? '-'
                : text,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              fontSize: 11,
              color:
                  AppColors.textLight,
            ),
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // EMPTY STATE
  // ==============================================================

  Widget _buildEmptyState() {
    final hasFilters =
        _searchController.text
                .trim()
                .isNotEmpty ||
        _selectedStatus != 'All' ||
        _selectedType != 'All';

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 60,
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              hasFilters
                  ? Icons.search_off_rounded
                  : Icons.folder_off_rounded,
              size: 52,
              color:
                  Colors.grey.shade400,
            ),

            const SizedBox(height: 14),

            Text(
              hasFilters
                  ? 'No matching documents'
                  : 'No documents found',
              style:
                  const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
                color:
                    AppColors.textDark,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              hasFilters
                  ? 'Try changing your search or filters.'
                  : 'Create your first project document.',
              style:
                  const TextStyle(
                color:
                    AppColors.textLight,
              ),
            ),

            if (hasFilters) ...[
              const SizedBox(height: 18),

              OutlinedButton.icon(
                onPressed:
                    _clearFilters,
                icon:
                    const Icon(
                  Icons.clear_all_rounded,
                ),
                label:
                    const Text(
                  'Clear Filters',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // CLEAR FILTERS
  // ==============================================================

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = 'All';
      _selectedType = 'All';
    });
  }

  // ==============================================================
  // DATE
  // ==============================================================

  String _formatDate(
    DateTime date,
  ) {
    final day =
        date.day
            .toString()
            .padLeft(2, '0');

    final month =
        date.month
            .toString()
            .padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}

// ============================================================================
// SUMMARY DATA
// ============================================================================

class _SummaryData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SummaryData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}