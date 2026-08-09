import 'package:flutter/material.dart';
import 'package:structflow/core/responsive/responsive.dart';
import 'package:structflow/features/dashboard/widgets/statistics_card.dart';

class DashboardBody extends StatelessWidget {
  const DashboardBody({super.key});

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.gridColumns(context);
    final horizontalPadding = Responsive.horizontalPadding(context);
    final spacing = Responsive.spacing(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              mainAxisExtent: 225,
            ),
            itemBuilder: (context, index) {
              const cards = [
                StatisticsCard(
                  title: "Projects",
                  value: "48",
                  icon: Icons.apartment_rounded,
                  color: Colors.blue,
                  change: 12.4,
                  isPositive: true,
                ),
                StatisticsCard(
                  title: "Engineers",
                  value: "132",
                  icon: Icons.engineering_rounded,
                  color: Colors.green,
                  change: 4.8,
                  isPositive: true,
                ),
                StatisticsCard(
                  title: "Budget",
                  value: "\$2.8M",
                  icon: Icons.account_balance_wallet_rounded,
                  color: Colors.orange,
                  change: 2.1,
                  isPositive: false,
                ),
                StatisticsCard(
                  title: "Progress",
                  value: "78%",
                  icon: Icons.trending_up_rounded,
                  color: Colors.purple,
                  change: 8.7,
                  isPositive: true,
                ),
              ];

              return cards[index];
            },
          ),

          SizedBox(height: spacing + 10),

          _buildMainSections(context),

          SizedBox(height: spacing),
        ],
      ),
    );
  }

Widget _buildMainSections(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final availableWidth = constraints.maxWidth;

      // عندما تكون المساحة الفعلية صغيرة
      // نضع الكروت تحت بعضها.
      if (availableWidth < 950) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _activeProjectsCard(),

            const SizedBox(height: 20),

            _recentActivityCard(),
          ],
        );
      }

      // Desktop
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _activeProjectsCard(),
          ),

          const SizedBox(width: 20),

          Expanded(
            flex: 1,
            child: _recentActivityCard(),
          ),
        ],
      );
    },
  );
}

  Widget _activeProjectsCard() {
    return _sectionCard(
      title: "Active Projects",
      icon: Icons.apartment_rounded,
      child: Column(
        children: [
          _projectTile(
            "New Capital Tower",
            0.82,
            Colors.green,
          ),
          _projectTile(
            "Cairo Business Park",
            0.64,
            Colors.orange,
          ),
          _projectTile(
            "Smart Village",
            0.39,
            Colors.red,
          ),
          _projectTile(
            "Alex Mall",
            0.95,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _recentActivityCard() {
    return _sectionCard(
      title: "Recent Activity",
      icon: Icons.timeline_rounded,
      child: Column(
        children: [
          _activityTile(
            Icons.check_circle_rounded,
            "BOQ Approved",
            "5 min ago",
            Colors.green,
          ),
          _activityTile(
            Icons.upload_file_rounded,
            "Shop Drawings Uploaded",
            "18 min ago",
            Colors.blue,
          ),
          _activityTile(
            Icons.warning_amber_rounded,
            "RFI Waiting Response",
            "40 min ago",
            Colors.orange,
          ),
          _activityTile(
            Icons.person_add_alt_1_rounded,
            "New Engineer Added",
            "1 hour ago",
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
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
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xff0B3D91),
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff1F2937),
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

  Widget _projectTile(
    String title,
    double progress,
    Color color,
  ) {
    final percentage = (progress * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1F2937),
                  ),
                ),
              ),
              Text(
                "$percentage%",
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: color.withOpacity(.10),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityTile(
    IconData icon,
    String title,
    String time,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xff6B7280),
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