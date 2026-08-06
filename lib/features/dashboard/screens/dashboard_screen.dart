import 'package:flutter/material.dart';
import 'package:structflow/core/theme/app_colors.dart';
import 'package:structflow/features/dashboard/widgets/dashboard_body.dart';
import 'package:structflow/features/dashboard/widgets/dashboard_header.dart';
import 'package:structflow/features/dashboard/widgets/dashboard_sidebar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const DashboardSidebar(),

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
  }
}