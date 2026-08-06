import 'package:flutter/material.dart';
import 'package:structflow/core/theme/app_colors.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

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

          const Text(
            "Dashboard",
            style: TextStyle(
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
                decoration: InputDecoration(

                  hintText: "Search projects, drawings, BOQ...",

                  prefixIcon: const Icon(
                    Icons.search,
                  ),

                  filled: true,

                  fillColor: Colors.grey.shade100,

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
                    ),
                  ),

                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 20,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 25),

          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.business),
            label: const Text("GE&JO Construction"),
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
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(width: 20),

          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.language),
            tooltip: "Language",
          ),

          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.dark_mode_outlined),
            tooltip: "Theme",
          ),

          Stack(
            children: [

              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_none_rounded,
                ),
              ),

              Positioned(
                right: 8,
                top: 8,

                child: Container(
                  width: 10,
                  height: 10,

                  decoration: const BoxDecoration(
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
              "G",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 12),

          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                "George",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),

              SizedBox(height: 2),

              Text(
                "Administrator",
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
}