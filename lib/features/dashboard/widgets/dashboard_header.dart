import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  @override
  void dispose() {
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
  // NOTIFICATIONS
  // ============================================================

  void _toggleNotifications() {
    setState(() {
      _showNotifications = !_showNotifications;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
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
          // ==========================================================
          // TITLE
          // ==========================================================

          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
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
                decoration: InputDecoration(
                  hintText:
                      'Search projects, drawings, BOQ...',

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

          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.language,
            ),
            tooltip: 'Language',
          ),

          // ==========================================================
          // THEME
          // ==========================================================

          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.dark_mode_outlined,
            ),
            tooltip: 'Theme',
          ),

          // ==========================================================
          // NOTIFICATIONS
          // ==========================================================

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
                tooltip: 'Notifications',
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

              // ======================================================
              // NOTIFICATION PANEL
              // ======================================================

              if (_showNotifications)
                Positioned(
                  top: 55,
                  right: 0,
                  child: _buildNotificationPanel(),
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

          const Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'George',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),

              SizedBox(height: 2),

              Text(
                'Administrator',
                style: TextStyle(
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

  // ============================================================
  // NOTIFICATION PANEL
  // ============================================================

  Widget _buildNotificationPanel() {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: Container(
        width: 330,
        constraints: const BoxConstraints(
          maxHeight: 420,
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
                const Expanded(
                  child: Text(
                    'Notifications',
                    style: TextStyle(
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
                    setState(() {
                      _showNotifications =
                          false;
                    });
                  },
                  child: const Text(
                    'Close',
                  ),
                ),
              ],
            ),

            const Divider(),

            _notificationItem(
              Icons.assignment_turned_in_rounded,
              'BOQ Approved',
              'New Capital Tower',
              '5 min ago',
              Colors.green,
            ),

            _notificationItem(
              Icons.upload_file_rounded,
              'New Drawing Uploaded',
              'Cairo Business Park',
              '18 min ago',
              Colors.blue,
            ),

            _notificationItem(
              Icons.warning_amber_rounded,
              'RFI Needs Response',
              'Smart Village',
              '40 min ago',
              Colors.orange,
            ),

            _notificationItem(
              Icons.person_add_alt_1_rounded,
              'New Engineer Added',
              'Tuban Villas',
              '1 hour ago',
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NOTIFICATION ITEM
  // ============================================================

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