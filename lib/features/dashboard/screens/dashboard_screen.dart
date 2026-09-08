import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:structflow/core/localization/app_localizations.dart';
import 'package:structflow/core/settings/app_settings.dart';
import 'package:structflow/core/theme/app_colors.dart';
import 'package:structflow/features/dashboard/widgets/dashboard_body.dart';
import 'package:structflow/features/dashboard/widgets/dashboard_header.dart';
import 'package:structflow/features/dashboard/widgets/dashboard_sidebar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1050) {
          return const _MobileDashboard();
        }

        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Row(
            children: [
              DashboardSidebar(),
              Expanded(
                child: Column(
                  children: [
                    DashboardHeader(),
                    Expanded(
                      child: DashboardBody(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MobileDashboard extends StatefulWidget {
  const _MobileDashboard();

  @override
  State<_MobileDashboard> createState() => _MobileDashboardState();
}

class _MobileDashboardState extends State<_MobileDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  final TextEditingController _searchController =
      TextEditingController();

  final AppSettings _settings = AppSettings.instance;

  bool _showSearch = false;
  bool _showNotifications = false;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_settingsChanged);
  }

  void _settingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _settings.removeListener(_settingsChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String value) {
    final query = value.trim().toLowerCase();

    if (query.isEmpty) {
      return;
    }

    if (query.contains('project') ||
        query.contains('projects') ||
        query.contains('مشروع') ||
        query.contains('مشروعات') ||
        query.contains('projet') ||
        query.contains('项目')) {
      context.go('/projects');
      return;
    }

    if (query.contains('task') ||
        query.contains('tasks') ||
        query.contains('مهمة') ||
        query.contains('مهام') ||
        query.contains('tâche') ||
        query.contains('任务')) {
      context.go('/tasks');
      return;
    }

    if (query.contains('team') ||
        query.contains('engineer') ||
        query.contains('engineers') ||
        query.contains('فريق') ||
        query.contains('مهندس') ||
        query.contains('équipe') ||
        query.contains('团队')) {
      context.go('/team');
      return;
    }

    if (query.contains('document') ||
        query.contains('documents') ||
        query.contains('drawing') ||
        query.contains('drawings') ||
        query.contains('boq') ||
        query.contains('مستند') ||
        query.contains('رسمة') ||
        query.contains('رسومات') ||
        query.contains('文件')) {
      context.go('/documents');
      return;
    }

    if (query.contains('report') ||
        query.contains('reports') ||
        query.contains('تقرير') ||
        query.contains('تقارير') ||
        query.contains('rapport') ||
        query.contains('报告')) {
      context.go('/reports');
      return;
    }

    final l = AppLocalizations.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l.noResultFound(value),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Future<void> _openLanguageMenu() async {
    final selected = await showModalBottomSheet<AppLanguage>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (sheetContext) {
        final l = AppLocalizations.of(sheetContext);

        return SafeArea(
          child: Directionality(
            textDirection: Directionality.of(sheetContext),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    18,
                    20,
                    14,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.language_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l.language,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                _languageItem(
                  sheetContext,
                  AppLanguage.english,
                  'English',
                ),
                _languageItem(
                  sheetContext,
                  AppLanguage.arabic,
                  'العربية',
                ),
                _languageItem(
                  sheetContext,
                  AppLanguage.french,
                  'Français',
                ),
                _languageItem(
                  sheetContext,
                  AppLanguage.chinese,
                  '中文',
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }

    await _settings.setLanguage(selected);
  }

  Widget _languageItem(
    BuildContext sheetContext,
    AppLanguage language,
    String title,
  ) {
    final selected = _settings.language == language;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      leading: Icon(
        selected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_off_rounded,
        color: selected
            ? AppColors.primary
            : AppColors.textLight,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight:
              selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: selected
          ? const Icon(
              Icons.check_rounded,
              color: AppColors.primary,
            )
          : null,
      onTap: () {
        Navigator.of(sheetContext).pop(language);
      },
    );
  }

  void _toggleNotifications() {
    setState(() {
      _showNotifications = !_showNotifications;
      _showSearch = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: const Drawer(
        width: 280,
        child: DashboardSidebar(),
      ),
      body: Column(
        children: [
          _buildMobileHeader(l),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const DashboardBody(),

                if (_showNotifications)
                  Positioned(
                    top: 10,
                    left: 12,
                    right: 12,
                    child: _buildNotificationPanel(l),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(
    AppLocalizations l,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 70,
            child: Row(
              children: [
                IconButton(
                  onPressed: _openDrawer,
                  icon: const Icon(
                    Icons.menu_rounded,
                  ),
                  tooltip: 'Menu',
                ),

                Expanded(
                  child: Text(
                    l.dashboard,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),

                IconButton(
                  onPressed: () {
                    setState(() {
                      _showSearch = !_showSearch;
                      _showNotifications = false;
                    });
                  },
                  icon: const Icon(
                    Icons.search_rounded,
                  ),
                  tooltip: l.searchHint,
                ),

                IconButton(
                  onPressed: _openLanguageMenu,
                  icon: const Icon(
                    Icons.language_rounded,
                  ),
                  tooltip: l.language,
                ),

                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: _toggleNotifications,
                      icon: Icon(
                        _showNotifications
                            ? Icons.notifications_rounded
                            : Icons.notifications_none_rounded,
                      ),
                      tooltip: l.notifications,
                    ),
                    Positioned(
                      right: 7,
                      top: 7,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_showSearch)
            Padding(
              padding: const EdgeInsets.only(
                bottom: 12,
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onSubmitted: _performSearch,
                decoration: InputDecoration(
                  hintText: l.searchHint,
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationPanel(
    AppLocalizations l,
  ) {
    return Material(
      elevation: 16,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.notifications,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showNotifications = false;
                    });
                  },
                  child: Text(l.close),
                ),
              ],
            ),
            Divider(
              color: Colors.grey.shade300,
            ),
            _mobileNotificationItem(
              Icons.assignment_turned_in_rounded,
              l.boqApproved,
              'New Capital Tower',
              l.fiveMinutesAgo,
              AppColors.success,
            ),
            _mobileNotificationItem(
              Icons.upload_file_rounded,
              l.newDrawingUploaded,
              'Cairo Business Park',
              l.eighteenMinutesAgo,
              AppColors.info,
            ),
            _mobileNotificationItem(
              Icons.warning_amber_rounded,
              l.rfiNeedsResponse,
              'Smart Village',
              l.fortyMinutesAgo,
              AppColors.warning,
            ),
            _mobileNotificationItem(
              Icons.person_add_alt_1_rounded,
              l.newEngineerAdded,
              'Tuban Villas',
              l.oneHourAgo,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileNotificationItem(
    IconData icon,
    String title,
    String subtitle,
    String time,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}