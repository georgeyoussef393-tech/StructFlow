import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  final AppSettings _settings = AppSettings.instance;

  bool _showNotifications = false;

  OverlayEntry? _notificationOverlay;

  @override
  void initState() {
    super.initState();

    _settings.addListener(_settingsChanged);
  }

  void _settingsChanged() {
    if (!mounted) {
      return;
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

  // ============================================================
  // SEARCH
  // ============================================================

  void _performSearch(String value) {
    final query = value.trim().toLowerCase();

    if (query.isEmpty) {
      return;
    }

    if (query.contains('project') ||
        query.contains('projects') ||
        query.contains('مشروع') ||
        query.contains('مشاريع')) {
      context.go('/projects');
      return;
    }

    if (query.contains('task') ||
        query.contains('tasks') ||
        query.contains('مهمة') ||
        query.contains('مهام')) {
      context.go('/tasks');
      return;
    }

    if (query.contains('team') ||
        query.contains('engineer') ||
        query.contains('engineers') ||
        query.contains('فريق') ||
        query.contains('مهندس')) {
      context.go('/team');
      return;
    }

    if (query.contains('document') ||
        query.contains('documents') ||
        query.contains('drawing') ||
        query.contains('drawings') ||
        query.contains('boq') ||
        query.contains('مستند') ||
        query.contains('رسومات')) {
      context.go('/documents');
      return;
    }

    if (query.contains('report') ||
        query.contains('reports') ||
        query.contains('تقرير') ||
        query.contains('تقارير')) {
      context.go('/reports');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'No result found for "$value"',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // LANGUAGE
  // ============================================================

  void _selectLanguage(AppLanguage language) {
    _settings.setLanguage(language);
  }

  // ============================================================
  // THEME
  // ============================================================

  void _toggleTheme() {
    _settings.toggleTheme();
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  void _toggleNotifications() {
    if (_showNotifications) {
      _hideNotificationOverlay();

      setState(() {
        _showNotifications = false;
      });
    } else {
      setState(() {
        _showNotifications = true;
      });

      _showNotificationOverlay();
    }
  }

  void _showNotificationOverlay() {
    if (_notificationOverlay != null) {
      return;
    }

    final overlay = Overlay.of(context);

    _notificationOverlay = OverlayEntry(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Positioned(
          top: 92,
          right: 24,
          child: Material(
            color: Colors.transparent,
            child: _buildNotificationPanel(
              isDark: isDark,
            ),
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

  void _closeNotifications() {
    _hideNotificationOverlay();

    if (!mounted) {
      return;
    }

    setState(() {
      _showNotifications = false;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(
        horizontal: 30,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade300,
          ),
        ),
      ),
      child: Row(
        children: [
          // ==========================================================
          // TITLE
          // ==========================================================

          Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? Colors.white
                  : AppColors.textDark,
            ),
          ),

          const SizedBox(width: 30),

          // ==========================================================
          // SEARCH
          // ==========================================================

          Expanded(
            child: SizedBox(
              height: 48,
              child: TextField(
                controller: _searchController,
                onSubmitted: _performSearch,
                style: TextStyle(
                  color: isDark
                      ? Colors.white
                      : AppColors.textDark,
                ),
                decoration: InputDecoration(
                  hintText:
                      'Search projects, drawings, BOQ...',

                  hintStyle: TextStyle(
                    color: isDark
                        ? Colors.white54
                        : AppColors.textLight,
                  ),

                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDark
                        ? Colors.white70
                        : AppColors.textLight,
                  ),

                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();

                                setState(() {});
                              },
                              icon: Icon(
                                Icons.close_rounded,
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.textLight,
                              ),
                            )
                          : null,

                  filled: true,

                  fillColor: isDark
                      ? const Color(0xFF1E293B)
                      : Colors.grey.shade100,

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide: const BorderSide(
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

          // ==========================================================
          // COMPANY
          // ==========================================================

          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(
              Icons.business,
            ),
            label: const Text(
              'GE&JO Construction',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(
                color: AppColors.primary,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(width: 15),

          // ==========================================================
          // LANGUAGE
          // ==========================================================

          PopupMenuButton<AppLanguage>(
            tooltip: 'Language',

            onSelected: _selectLanguage,

            position: PopupMenuPosition.under,

            itemBuilder: (BuildContext context) {
              return const [
                PopupMenuItem<AppLanguage>(
                  value: AppLanguage.english,
                  child: Row(
                    children: [
                      Text('🇬🇧'),
                      SizedBox(width: 10),
                      Text('English'),
                    ],
                  ),
                ),

                PopupMenuItem<AppLanguage>(
                  value: AppLanguage.arabic,
                  child: Row(
                    children: [
                      Text('🇪🇬'),
                      SizedBox(width: 10),
                      Text('العربية'),
                    ],
                  ),
                ),

                PopupMenuItem<AppLanguage>(
                  value: AppLanguage.french,
                  child: Row(
                    children: [
                      Text('🇫🇷'),
                      SizedBox(width: 10),
                      Text('Français'),
                    ],
                  ),
                ),

                PopupMenuItem<AppLanguage>(
                  value: AppLanguage.chinese,
                  child: Row(
                    children: [
                      Text('🇨🇳'),
                      SizedBox(width: 10),
                      Text('中文'),
                    ],
                  ),
                ),
              ];
            },

            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
              ),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(12),
                color: isDark
                    ? const Color(0xFF1E293B)
                    : Colors.transparent,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.language_rounded,
                    color: isDark
                        ? Colors.white
                        : AppColors.textDark,
                  ),

                  const SizedBox(width: 6),

                  Text(
                    _settings.languageName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white
                          : AppColors.textDark,
                    ),
                  ),

                  const SizedBox(width: 2),

                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: isDark
                        ? Colors.white70
                        : AppColors.textLight,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 5),

          // ==========================================================
          // THEME
          // ==========================================================

          IconButton(
            onPressed: _toggleTheme,

            tooltip: _settings.isDarkMode
                ? 'Light mode'
                : 'Dark mode',

            icon: AnimatedSwitcher(
              duration: const Duration(
                milliseconds: 250,
              ),
              transitionBuilder:
                  (child, animation) {
                return RotationTransition(
                  turns: animation,
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: Icon(
                _settings.isDarkMode
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_outlined,
                key: ValueKey<bool>(
                  _settings.isDarkMode,
                ),
              ),
            ),
          ),

          const SizedBox(width: 5),

          // ==========================================================
          // NOTIFICATIONS
          // ==========================================================

          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: _toggleNotifications,

                tooltip: 'Notifications',

                icon: Icon(
                  _showNotifications
                      ? Icons.notifications_rounded
                      : Icons.notifications_none_rounded,
                ),
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

          // ==========================================================
          // PROFILE
          // ==========================================================

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
              Text(
                'George',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? Colors.white
                      : AppColors.textDark,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                'Administrator',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? Colors.white60
                      : AppColors.textLight,
                ),
              ),
            ],
          ),

          const SizedBox(width: 10),
        ],
      ),
    );
  }

  // ============================================================
  // NOTIFICATION PANEL
  // ============================================================

  Widget _buildNotificationPanel({
    required bool isDark,
  }) {
    final backgroundColor = isDark
        ? const Color(0xFF1E293B)
        : Colors.white;

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;

    final primaryTextColor = isDark
        ? Colors.white
        : AppColors.textDark;

    final secondaryTextColor = isDark
        ? Colors.white60
        : AppColors.textLight;

    return Material(
      elevation: 16,
      shadowColor: Colors.black.withValues(
        alpha: isDark ? 0.40 : 0.20,
      ),
      borderRadius: BorderRadius.circular(16),
      color: backgroundColor,
      child: Container(
        width: 350,
        constraints: const BoxConstraints(
          maxHeight: 440,
        ),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ======================================================
            // HEADER
            // ======================================================

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                ),

                TextButton(
                  onPressed: _closeNotifications,
                  child: const Text(
                    'Close',
                  ),
                ),
              ],
            ),

            Divider(
              color: borderColor,
            ),

            // ======================================================
            // NOTIFICATION 1
            // ======================================================

            _notificationItem(
              icon:
                  Icons.assignment_turned_in_rounded,
              title: 'BOQ Approved',
              subtitle: 'New Capital Tower',
              time: '5 min ago',
              color: Colors.green,
              textColor: primaryTextColor,
              secondaryTextColor:
                  secondaryTextColor,
            ),

            // ======================================================
            // NOTIFICATION 2
            // ======================================================

            _notificationItem(
              icon: Icons.upload_file_rounded,
              title: 'New Drawing Uploaded',
              subtitle: 'Cairo Business Park',
              time: '18 min ago',
              color: Colors.blue,
              textColor: primaryTextColor,
              secondaryTextColor:
                  secondaryTextColor,
            ),

            // ======================================================
            // NOTIFICATION 3
            // ======================================================

            _notificationItem(
              icon: Icons.warning_amber_rounded,
              title: 'RFI Needs Response',
              subtitle: 'Smart Village',
              time: '40 min ago',
              color: Colors.orange,
              textColor: primaryTextColor,
              secondaryTextColor:
                  secondaryTextColor,
            ),

            // ======================================================
            // NOTIFICATION 4
            // ======================================================

            _notificationItem(
              icon:
                  Icons.person_add_alt_1_rounded,
              title: 'New Engineer Added',
              subtitle: 'Tuban Villas',
              time: '1 hour ago',
              color: Colors.purple,
              textColor: primaryTextColor,
              secondaryTextColor:
                  secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NOTIFICATION ITEM
  // ============================================================

  Widget _notificationItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
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
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: .10,
              ),
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
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w600,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        secondaryTextColor,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        secondaryTextColor,
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