import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:structflow/core/theme/app_colors.dart';
import 'package:structflow/features/documents/models/document_model.dart';
import 'package:structflow/features/documents/repositories/document_repository.dart';

class DocumentDetailsScreen extends StatelessWidget {
  final String documentId;

  const DocumentDetailsScreen({
    super.key,
    required this.documentId,
  });

  DocumentModel? _getDocument() {
    return DocumentRepository.instance.getDocumentById(documentId);
  }

  @override
  Widget build(BuildContext context) {
    final document = _getDocument();

    if (document == null) {
      return _buildNotFound(context);
    }

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;

            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 30),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(
                        context,
                        document,
                        isMobile,
                      ),
                      const SizedBox(height: 24),
                      _buildHeroCard(
                        document,
                        isMobile,
                      ),
                      const SizedBox(height: 20),
                      _buildInformationCard(
                        document,
                        isMobile,
                      ),
                      const SizedBox(height: 20),
                      _buildCommunicationCard(
                        document,
                        isMobile,
                      ),
                      const SizedBox(height: 20),
                      _buildDatesCard(
                        document,
                        isMobile,
                      ),
                      const SizedBox(height: 20),
                      _buildDescriptionCard(document),
                      const SizedBox(height: 20),
                      _buildAttachmentsCard(document),
                      const SizedBox(height: 30),
                      _buildBottomActions(
                        context,
                        document,
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
  // NOT FOUND
  // ==============================================================

  Widget _buildNotFound(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(35),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 16,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.description_outlined,
                size: 65,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 20),
              const Text(
                'Document Not Found',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'The requested document could not be found.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  context.go('/documents');
                },
                icon: const Icon(
                  Icons.arrow_back_rounded,
                ),
                label: const Text(
                  'Back to Documents',
                ),
                style: _primaryButtonStyle(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // HEADER
  // ==============================================================

  Widget _buildHeader(
    BuildContext context,
    DocumentModel document,
    bool isMobile,
  ) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () {
              context.go('/documents');
            },
            icon: const Icon(
              Icons.arrow_back_rounded,
            ),
            label: const Text(
              'Back to Documents',
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 4,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            document.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            document.documentNumber,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        IconButton(
          onPressed: () {
            context.go('/documents');
          },
          tooltip: 'Back to Documents',
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                document.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                document.documentNumber,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: () {
            _editDocument(
              context,
              document,
            );
          },
          icon: const Icon(
            Icons.edit_rounded,
            size: 18,
          ),
          label: const Text('Edit'),
          style: _secondaryButtonStyle(),
        ),
      ],
    );
  }

  // ==============================================================
  // HERO
  // ==============================================================

  Widget _buildHeroCard(
    DocumentModel document,
    bool isMobile,
  ) {
    final statusColor = _statusColor(document.status);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isMobile ? 18 : 24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _documentIdentity(document),
                const SizedBox(height: 20),
                _statusArea(
                  document,
                  statusColor,
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: _documentIdentity(document),
                ),
                const SizedBox(width: 30),
                _statusArea(
                  document,
                  statusColor,
                ),
              ],
            ),
    );
  }

  Widget _documentIdentity(DocumentModel document) {
    return Row(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: document.color.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            document.icon,
            color: document.color,
            size: 34,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                document.documentType,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: document.color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${document.projectCode} • ${document.projectName}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusArea(
    DocumentModel document,
    Color statusColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withValues(alpha: .15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CURRENT STATUS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            document.status,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 8),
          _statusBadge(document.status),
        ],
      ),
    );
  }

  // ==============================================================
  // INFORMATION
  // ==============================================================

  Widget _buildInformationCard(
    DocumentModel document,
    bool isMobile,
  ) {
    return _card(
      title: 'Project & Classification',
      icon: Icons.folder_rounded,
      child: _responsiveInfoGrid(
        isMobile: isMobile,
        items: [
          _InfoItem('Document ID', document.id),
          _InfoItem(
            'Document Number',
            document.documentNumber,
          ),
          _InfoItem(
            'Project Code',
            document.projectCode,
          ),
          _InfoItem(
            'Project Name',
            document.projectName,
          ),
          _InfoItem(
            'Category',
            document.category,
          ),
          _InfoItem(
            'Sub Category',
            document.subCategory,
          ),
          _InfoItem(
            'Document Type',
            document.documentType,
          ),
          _InfoItem(
            'Discipline',
            document.discipline,
          ),
          _InfoItem(
            'Revision',
            document.revision,
          ),
          _InfoItem(
            'Priority',
            document.priority,
          ),
          _InfoItem(
            'Confidentiality',
            document.confidentiality,
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // COMMUNICATION
  // ==============================================================

  Widget _buildCommunicationCard(
    DocumentModel document,
    bool isMobile,
  ) {
    return _card(
      title: 'Communication',
      icon: Icons.people_alt_outlined,
      child: _responsiveInfoGrid(
        isMobile: isMobile,
        items: [
          _InfoItem('From', document.from),
          _InfoItem('To', document.to),
          _InfoItem('CC', document.cc),
          _InfoItem(
            'Submitted By',
            document.submittedBy,
          ),
          _InfoItem(
            'Recipient',
            document.recipient,
          ),
          _InfoItem(
            'Created By',
            document.createdBy,
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // DATES
  // ==============================================================

  Widget _buildDatesCard(
    DocumentModel document,
    bool isMobile,
  ) {
    return _card(
      title: 'Dates',
      icon: Icons.calendar_month_rounded,
      child: _responsiveInfoGrid(
        isMobile: isMobile,
        items: [
          _InfoItem(
            'Document Date',
            _formatDate(document.date),
          ),
          _InfoItem(
            'Created Date',
            _formatDate(document.createdDate),
          ),
          _InfoItem(
            'Submitted Date',
            document.submittedDate == null
                ? '-'
                : _formatDate(
                    document.submittedDate!,
                  ),
          ),
          _InfoItem(
            'Due Date',
            document.dueDate == null
                ? '-'
                : _formatDate(
                    document.dueDate!,
                  ),
          ),
          _InfoItem(
            'Response Date',
            document.responseDate == null
                ? '-'
                : _formatDate(
                    document.responseDate!,
                  ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // DESCRIPTION
  // ==============================================================

  Widget _buildDescriptionCard(
    DocumentModel document,
  ) {
    return _card(
      title: 'Description',
      icon: Icons.notes_rounded,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xffF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Text(
          document.description.isEmpty
              ? 'No description provided.'
              : document.description,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: document.description.isEmpty
                ? AppColors.textLight
                : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // ATTACHMENTS
  // ==============================================================

  Widget _buildAttachmentsCard(
    DocumentModel document,
  ) {
    return _card(
      title: 'Attachments',
      icon: Icons.attach_file_rounded,
      child: document.attachments.isEmpty
          ? _emptyAttachments()
          : Column(
              children: document.attachments.map(
                (attachment) {
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(
                      bottom: 8,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xffF8FAFC),
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary
                                .withValues(alpha: .08),
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.insert_drive_file_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            attachment,
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ).toList(),
            ),
    );
  }

  Widget _emptyAttachments() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.attach_file_rounded,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'No attachments added.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // BOTTOM ACTIONS
  // ==============================================================

  Widget _buildBottomActions(
    BuildContext context,
    DocumentModel document,
    bool isMobile,
  ) {
    final editButton = ElevatedButton.icon(
      onPressed: () {
        _editDocument(
          context,
          document,
        );
      },
      icon: const Icon(
        Icons.edit_rounded,
      ),
      label: const Text(
        'Edit Document',
      ),
      style: _primaryButtonStyle(),
    );

    final backButton = OutlinedButton.icon(
      onPressed: () {
        context.go('/documents');
      },
      icon: const Icon(
        Icons.arrow_back_rounded,
      ),
      label: const Text(
        'Back to Documents',
      ),
      style: _secondaryButtonStyle(),
    );

    if (isMobile) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: editButton,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: backButton,
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        backButton,
        const SizedBox(width: 12),
        editButton,
      ],
    );
  }

  // ==============================================================
  // CARD
  // ==============================================================

  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withValues(alpha: .10),
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
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  // ==============================================================
  // INFO GRID
  // ==============================================================

  Widget _responsiveInfoGrid({
    required bool isMobile,
    required List<_InfoItem> items,
  }) {
    if (isMobile) {
      return Column(
        children: items.map(
          (item) {
            return Padding(
              padding: const EdgeInsets.only(
                bottom: 16,
              ),
              child: _infoItem(item),
            );
          },
        ).toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >= 750 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 24,
            mainAxisSpacing: 20,
            mainAxisExtent: 62,
          ),
          itemBuilder: (context, index) {
            return _infoItem(
              items[index],
            );
          },
        );
      },
    );
  }

  Widget _infoItem(_InfoItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          item.value.isEmpty ? '-' : item.value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // STATUS
  // ==============================================================

  Widget _statusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
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
  // EDIT
  // ==============================================================

  void _editDocument(
    BuildContext context,
    DocumentModel document,
  ) {
    context.go(
      '/create-document?documentId=${Uri.encodeComponent(document.id)}',
    );
  }

  // ==============================================================
  // DATE
  // ==============================================================

  String _formatDate(DateTime date) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // ==============================================================
  // BUTTON STYLES
  // ==============================================================

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  ButtonStyle _secondaryButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.textDark,
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 14,
      ),
      side: BorderSide(
        color: Colors.grey.shade300,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

// ============================================================================
// INFO ITEM
// ============================================================================

class _InfoItem {
  final String title;
  final String value;

  const _InfoItem(
    this.title,
    this.value,
  );
}