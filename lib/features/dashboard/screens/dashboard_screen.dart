import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:structflow/features/dashboard/widgets/dashboard_body.dart';
import 'package:structflow/features/dashboard/widgets/dashboard_header.dart';
import 'package:structflow/features/dashboard/widgets/dashboard_sidebar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // ============================================================
        // MOBILE / TABLET / HIGH ZOOM
        // ============================================================

        if (width < 1050) {
          return const _MobileDashboard();
        }

        // ============================================================
        // DESKTOP / LAPTOP
        // ============================================================

        return Scaffold(
          backgroundColor: const Color(0xffF5F7FB),
          body: Row(
            children: [
              const DashboardSidebar(),

              Expanded(
                child: Column(
                  children: [
                    const DashboardHeader(),

                    const Expanded(
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

// ============================================================================
// MOBILE / TABLET DASHBOARD
// ============================================================================

class _MobileDashboard extends StatefulWidget {
  const _MobileDashboard();

  @override
  State<_MobileDashboard> createState() =>
      _MobileDashboardState();
}

class _MobileDashboardState
    extends State<_MobileDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  bool _showSearch = false;
  bool _showNotifications = false;

  final TextEditingController _searchController =
      TextEditingController();

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
  // OPEN DRAWER
  // ============================================================

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  // ============================================================
  // SEARCH BUTTON
  // ============================================================

  void _openSearch() {
    setState(() {
      _showSearch = true;
      _showNotifications = false;
    });
  }

  // ============================================================
  // CLOSE SEARCH
  // ============================================================

  void _closeSearch() {
    setState(() {
      _showSearch = false;
      _searchController.clear();
    });
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  void _toggleNotifications() {
    setState(() {
      _showNotifications = !_showNotifications;
      _showSearch = false;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,

      backgroundColor: const Color(0xffF5F7FB),

      drawer: const Drawer(
        width: 260,
        child: DashboardSidebar(),
      ),

      body: Column(
        children: [
          SizedBox(
            height: _showSearch ? 125 : 70,
            child: _buildMobileHeader(),
          ),

          Expanded(
            child: Stack(
              children: [
                const DashboardBody(),

                if (_showNotifications)
                  Positioned(
                    top: 10,
                    right: 12,
                    child: _buildNotificationPanel(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE HEADER
  // ============================================================

  Widget _buildMobileHeader() {
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
          Expanded(
            child: Row(
              children: [
                // MENU
                IconButton(
                  onPressed: _openDrawer,
                  tooltip: 'Menu',
                  icon: const Icon(
                    Icons.menu_rounded,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 6),

                const Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff1F2937),
                  ),
                ),

                const Spacer(),

                // SEARCH
                IconButton(
                  onPressed: _openSearch,
                  tooltip: 'Search',
                  icon: Icon(
                    _showSearch
                        ? Icons.search_rounded
                        : Icons.search_rounded,
                  ),
                ),

                // NOTIFICATIONS
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
                      right: 7,
                      top: 7,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration:
                            const BoxDecoration(
                          color: Color(0xffFF6B35),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 4),

                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xff0B3D91),
                  child: Text(
                    'G',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ==========================================================
          // SEARCH BAR
          // ==========================================================

          if (_showSearch)
            Padding(
              padding: const EdgeInsets.only(
                bottom: 10,
                left: 4,
                right: 4,
              ),
              child: SizedBox(
                height: 42,
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onSubmitted: _performSearch,
                  decoration: InputDecoration(
                    hintText:
                        'Search projects, drawings, BOQ...',

                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                    ),

                    suffixIcon: IconButton(
                      onPressed: _closeSearch,
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                      ),
                    ),

                    filled: true,
                    fillColor: Colors.grey.shade100,

                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),

                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(
                        color: Color(0xff0B3D91),
                      ),
                    ),
                  ),
                ),
              ),
            ),
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
        width: 320,
        constraints: const BoxConstraints(
          maxHeight: 430,
        ),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
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
                        fontWeight: FontWeight.bold,
                        color: Color(0xff1F2937),
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showNotifications = false;
                      });
                    },
                    icon: const Icon(
                      Icons.close_rounded,
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
      padding: const EdgeInsets.symmetric(
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
              color: color.withOpacity(.10),
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
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1F2937),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xff6B7280),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xff9CA3AF),
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