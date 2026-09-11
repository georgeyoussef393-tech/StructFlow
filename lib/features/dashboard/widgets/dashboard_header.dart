import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:structflow/core/localization/app_localizations.dart';
import 'package:structflow/core/settings/app_settings.dart';
import 'package:structflow/core/theme/app_colors.dart';

class DashboardHeader extends StatefulWidget {
  const DashboardHeader({super.key});

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  final TextEditingController _searchController =
      TextEditingController();

  bool _showNotifications = false;
  final LayerLink _notificationLink = LayerLink();
  OverlayEntry? _notificationEntry;

  @override
  void dispose() {
    _removeNotificationOverlay();
    _searchController.dispose();
    super.dispose();
  }

  void _changeLanguage(AppLanguage language) {
    AppSettings.instance.setLanguage(language);

    if (_showNotifications) {
      _removeNotificationOverlay();
    }
  }

  void _toggleNotifications() {
    if (_showNotifications) {
      _removeNotificationOverlay();
      return;
    }

    setState(() => _showNotifications = true);
    _notificationEntry = OverlayEntry(
      builder: (context) => CompositedTransformFollower(
        link: _notificationLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomRight,
        followerAnchor: Alignment.topRight,
        offset: const Offset(0, 10),
        child: _buildNotificationPanel(AppLocalizations.of(context)),
      ),
    );
    Overlay.of(context).insert(_notificationEntry!);
  }

  void _removeNotificationOverlay() {
    _notificationEntry?.remove();
    _notificationEntry = null;
    if (mounted && _showNotifications) {
      setState(() => _showNotifications = false);
    } else {
      _showNotifications = false;
    }
  }

  void _closeNotifications() {
    if (!_showNotifications) {
      return;
    }

    _removeNotificationOverlay();
  }

  void _performSearch(String value) {
    final query = value.trim().toLowerCase();

    if (query.isEmpty) {
      return;
    }

    if (query.contains('project') ||
        query.contains('project') ||
        query.contains('مشروع') ||
        query.contains('projet') ||
        query.contains('项目')) {
      context.go('/projects');
      return;
    }

    if (query.contains('task') ||
        query.contains('مهمة') ||
        query.contains('tâche') ||
        query.contains('任务')) {
      context.go('/tasks');
      return;
    }

    if (query.contains('team') ||
        query.contains('فريق') ||
        query.contains('équipe') ||
        query.contains('团队')) {
      context.go('/team');
      return;
    }

    if (query.contains('document') ||
        query.contains('مستند') ||
        query.contains('وثيقة') ||
        query.contains('document') ||
        query.contains('文档')) {
      context.go('/documents');
      return;
    }

    if (query.contains('report') ||
        query.contains('تقرير') ||
        query.contains('rapport') ||
        query.contains('报告')) {
      context.go('/reports');
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Material(
      color: Colors.white,
      elevation: 2,
      child: SizedBox(
        height: 76,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildSearchField(l),
              ),

              const SizedBox(width: 18),

              _buildCompanyButton(),

              const SizedBox(width: 8),

              _buildLanguageButton(l),

              const SizedBox(width: 8),

              _buildNotificationButton(l),

              const SizedBox(width: 8),

              _buildProfileButton(l),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(AppLocalizations l) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 560,
      ),
      child: TextField(
        controller: _searchController,
        onSubmitted: _performSearch,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: l.searchHint,
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 22,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  tooltip: 'Clear',
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                  ),
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.2,
            ),
          ),
        ),
        onChanged: (_) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildCompanyButton() {
    return Material(
      color: const Color(0xFFF5F7FA),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 9,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'S',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'StructFlow',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Main Organization',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 19,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageButton(AppLocalizations l) {
    final currentLanguage =
        AppSettings.instance.language;

    return PopupMenuButton<AppLanguage>(
      tooltip: l.language,
      onSelected: _changeLanguage,

      // أهم جزء:
      // القائمة مرتبطة بالزرار نفسه
      // ولا تعتمد على إحداثيات ثابتة في الشاشة.
      position: PopupMenuPosition.under,

      offset: const Offset(
        0,
        8,
      ),

      elevation: 8,

      color: Colors.white,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),

      constraints: const BoxConstraints(
        minWidth: 190,
        maxWidth: 220,
      ),

      itemBuilder: (context) {
        return [
          _languageMenuItem(
            language: AppLanguage.english,
            title: 'English',
            subtitle: 'English',
            icon: Icons.language_rounded,
            selected:
                currentLanguage == AppLanguage.english,
          ),
          _languageMenuItem(
            language: AppLanguage.arabic,
            title: 'العربية',
            subtitle: 'Arabic',
            icon: Icons.translate_rounded,
            selected:
                currentLanguage == AppLanguage.arabic,
          ),
          _languageMenuItem(
            language: AppLanguage.french,
            title: 'Français',
            subtitle: 'French',
            icon: Icons.language_rounded,
            selected:
                currentLanguage == AppLanguage.french,
          ),
          _languageMenuItem(
            language: AppLanguage.chinese,
            title: '中文',
            subtitle: 'Chinese',
            icon: Icons.language_rounded,
            selected:
                currentLanguage == AppLanguage.chinese,
          ),
        ];
      },

      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.language_rounded,
          color: AppColors.primary,
          size: 22,
        ),
      ),
    );
  }

  PopupMenuItem<AppLanguage> _languageMenuItem({
    required AppLanguage language,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
  }) {
    return PopupMenuItem<AppLanguage>(
      value: language,
      height: 64,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(
                  alpha: 0.08,
                )
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                size: 18,
                color: selected
                    ? Colors.white
                    : AppColors.textLight,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Directionality(
                textDirection:
                    language == AppLanguage.arabic
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 19,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationButton(
    AppLocalizations l,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CompositedTransformTarget(
          link: _notificationLink,
          child: Material(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _toggleNotifications,
              child: SizedBox(
                width: 46,
                height: 46,
                child: Icon(
                  _showNotifications
                      ? Icons.notifications_rounded
                      : Icons.notifications_none_rounded,
                  color: AppColors.primary,
                  size: 23,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: -2,
          right: -2,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.danger,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            alignment: Alignment.center,
            child: const Text(
              '4',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationPanel(
    AppLocalizations l,
  ) {
    return Material(
      elevation: 12,
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 360,
        constraints: const BoxConstraints(
          maxHeight: 470,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border,
          ),
          boxShadow: const [
            BoxShadow(
              blurRadius: 24,
              offset: Offset(0, 10),
              color: Color(0x22000000),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                16,
                12,
                12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.notifications,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l.close,
                    onPressed: _closeNotifications,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(
              height: 1,
            ),

            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                ),
                children: [
                  _notificationItem(
                    icon: Icons.check_circle_rounded,
                    iconColor: AppColors.success,
                    title: l.boqApproved,
                    subtitle:
                        'Capital Site • BOQ has been approved.',
                    time: '5 min ago',
                  ),
                  _notificationItem(
                    icon: Icons.architecture_rounded,
                    iconColor: AppColors.primary,
                    title: l.newDrawingUploaded,
                    subtitle:
                        'Tuban Villas • New drawing uploaded.',
                    time: '18 min ago',
                  ),
                  _notificationItem(
                    icon: Icons.description_rounded,
                    iconColor: AppColors.warning,
                    title: l.rfiNeedsResponse,
                    subtitle:
                        'Capital Site • RFI requires a response.',
                    time: '40 min ago',
                  ),
                  _notificationItem(
                    icon: Icons.person_add_alt_1_rounded,
                    iconColor: AppColors.info,
                    title: l.newEngineerAdded,
                    subtitle:
                        'A new engineer joined the team.',
                    time: '1 hour ago',
                  ),
                ],
              ),
            ),

            const Divider(
              height: 1,
            ),

            InkWell(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              onTap: () {
                setState(() {
                  _showNotifications = false;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Center(
                  child: Text(
                    l.close,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 11,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(
                  alpha: 0.10,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 19,
              ),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    time,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileButton(
    AppLocalizations l,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 5,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'GY',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(width: 9),

              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'George Youssef',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.administrator,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 5),

              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textLight,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}