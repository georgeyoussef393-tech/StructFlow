import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:structflow/core/localization/app_localizations.dart';
import 'package:structflow/core/settings/app_settings.dart';
import 'package:structflow/core/theme/app_colors.dart';

class DashboardHeader extends StatefulWidget {
  const DashboardHeader({super.key});

  @override
  State<DashboardHeader> createState() =>
      _DashboardHeaderState();
}

class _DashboardHeaderState
    extends State<DashboardHeader> {
  final TextEditingController _searchController =
      TextEditingController();

  final AppSettings _settings =
      AppSettings.instance;

  OverlayEntry? _notificationOverlay;

  bool _showNotifications = false;

  @override
  void initState() {
    super.initState();

    _settings.addListener(_settingsChanged);
  }

  void _settingsChanged() {
    if (!mounted) return;

    // لو اللغة اتغيرت والـOverlay مفتوح،
    // نقفله عشان مايفضلش عالق بلغة قديمة.
    if (_notificationOverlay != null) {
      _hideNotificationOverlay();
      _showNotifications = false;
    }

    setState(() {});
  }

  @override
  void dispose() {
    _hideNotificationOverlay();

    _settings.removeListener(_settingsChanged);

    _searchController.dispose();

    super.dispose();
  }

  void _performSearch(String value) {
    final query = value.trim().toLowerCase();

    if (query.isEmpty) return;

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

  Future<void> _openLanguageMenu() async {
    final selected =
        await showMenu<AppLanguage>(
      context: context,
      position:
          _languageMenuPosition(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 10,
      items: [
        _languagePopupItem(
          AppLanguage.english,
          'English',
        ),
        _languagePopupItem(
          AppLanguage.arabic,
          'العربية',
        ),
        _languagePopupItem(
          AppLanguage.french,
          'Français',
        ),
        _languagePopupItem(
          AppLanguage.chinese,
          '中文',
        ),
      ],
    );

    if (!mounted || selected == null) {
      return;
    }

    await _settings.setLanguage(selected);
  }

  RelativeRect _languageMenuPosition(
    BuildContext context,
  ) {
    final RenderBox button =
        context.findRenderObject() as RenderBox;

    final RenderBox overlay =
        Overlay.of(context)
            .context
            .findRenderObject() as RenderBox;

    final Offset topLeft = button.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );

    final Size buttonSize = button.size;
    final Size overlaySize = overlay.size;

    final direction =
        Directionality.of(context);

    const double menuWidth = 180;

    if (direction == TextDirection.rtl) {
      final double right =
          overlaySize.width -
          topLeft.dx -
          buttonSize.width;

      return RelativeRect.fromLTRB(
        overlaySize.width -
            right -
            menuWidth,
        topLeft.dy + buttonSize.height + 8,
        right,
        0,
      );
    }

    return RelativeRect.fromLTRB(
      topLeft.dx +
          buttonSize.width -
          menuWidth,
      topLeft.dy + buttonSize.height + 8,
      overlaySize.width -
          topLeft.dx -
          buttonSize.width,
      0,
    );
  }

  PopupMenuItem<AppLanguage>
      _languagePopupItem(
    AppLanguage language,
    String title,
  ) {
    final selected =
        _settings.language == language;

    return PopupMenuItem<AppLanguage>(
      value: language,
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.check_circle_rounded
                : Icons.language_rounded,
            size: 20,
            color: selected
                ? AppColors.primary
                : AppColors.textLight,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: selected
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationOverlay() {
    if (_notificationOverlay != null) {
      return;
    }

    final overlay = Overlay.of(context);

    _notificationOverlay = OverlayEntry(
      builder: (overlayContext) {
        final direction =
            Directionality.of(context);

        return Positioned(
          top: 78,
          width: 350,
          right: direction == TextDirection.ltr
              ? 25
              : null,
          left: direction == TextDirection.rtl
              ? 25
              : null,
          child: Material(
            color: Colors.transparent,
            child: _buildNotificationPanel(),
          ),
        );
      },
    );

    overlay.insert(_notificationOverlay!);
  }

  void _hideNotificationOverlay() {
    _notificationOverlay?.remove();
    _notificationOverlay = null;
  }

  void _toggleNotifications() {
    if (_showNotifications) {
      _hideNotificationOverlay();

      setState(() {
        _showNotifications = false;
      });

      return;
    }

    _showNotificationOverlay();

    setState(() {
      _showNotifications = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(
        horizontal: 30,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            l.dashboard,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),

          const SizedBox(width: 30),

          Expanded(
            child: SizedBox(
              height: 48,
              child: TextField(
                controller: _searchController,
                onSubmitted: _performSearch,
                decoration: InputDecoration(
                  hintText: l.searchHint,
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                  ),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                              ),
                            )
                          : null,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(
                      color: AppColors.primary,
                    ),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 20,
                  ),
                ),
                onChanged: (_) {
                  setState(() {});
                },
              ),
            ),
          ),

          const SizedBox(width: 25),

          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(
              Icons.business,
            ),
            label: const Text(
              'GE&JO Construction',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  AppColors.primary,
              side: const BorderSide(
                color: AppColors.primary,
              ),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // LANGUAGE
          IconButton(
            onPressed: _openLanguageMenu,
            icon: const Icon(
              Icons.language_rounded,
            ),
            tooltip: l.language,
          ),

          // THEME BUTTON REMOVED.
          // Theme is currently fixed to Light.

          // NOTIFICATIONS
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
                right: 8,
                top: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration:
                      const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 15),

          const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary,
            child: Text(
              'G',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'George',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l.administrator,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),

          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildNotificationPanel() {
    final l = AppLocalizations.of(context);

    return Material(
      elevation: 16,
      borderRadius:
          BorderRadius.circular(16),
      color: Colors.white,
      child: Container(
        width: 350,
        constraints: const BoxConstraints(
          maxHeight: 430,
        ),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.notifications,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          AppColors.textDark,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _hideNotificationOverlay();

                    setState(() {
                      _showNotifications =
                          false;
                    });
                  },
                  child: Text(l.close),
                ),
              ],
            ),

            Divider(
              color: Colors.grey.shade300,
            ),

            _notificationItem(
              Icons
                  .assignment_turned_in_rounded,
              l.boqApproved,
              'New Capital Tower',
              l.fiveMinutesAgo,
              AppColors.success,
            ),

            _notificationItem(
              Icons.upload_file_rounded,
              l.newDrawingUploaded,
              'Cairo Business Park',
              l.eighteenMinutesAgo,
              AppColors.info,
            ),

            _notificationItem(
              Icons.warning_amber_rounded,
              l.rfiNeedsResponse,
              'Smart Village',
              l.fortyMinutesAgo,
              AppColors.warning,
            ),

            _notificationItem(
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

  Widget _notificationItem(
    IconData icon,
    String title,
    String subtitle,
    String time,
    Color color,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 9,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration:
                BoxDecoration(
              color:
                  color.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
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
                    fontWeight:
                        FontWeight.w600,
                    color:
                        AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color:
                        AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
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
}