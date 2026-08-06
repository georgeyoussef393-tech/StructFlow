import 'package:flutter/material.dart';
import 'package:structflow/core/theme/app_colors.dart';

class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: AppColors.primary,
      child: Column(
        children: [
          const SizedBox(height: 30),

          const Text(
            "StructFlow",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 40),

          _item(Icons.dashboard, "Dashboard", true),
          _item(Icons.folder, "Projects"),
          _item(Icons.task, "Tasks"),
          _item(Icons.people, "Team"),
          _item(Icons.calendar_month, "Calendar"),
          _item(Icons.description, "Documents"),
          _item(Icons.bar_chart, "Reports"),
          _item(Icons.smart_toy, "AI Assistant"),
          _item(Icons.settings, "Settings"),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String title, [bool selected = false]) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: selected
            ? Colors.white.withOpacity(.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}