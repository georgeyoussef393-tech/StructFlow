import 'package:flutter/material.dart';

import 'package:structflow/features/dashboard/widgets/statistics_card.dart';

class DashboardBody extends StatelessWidget {
  const DashboardBody({
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(

      padding: const EdgeInsets.all(30),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          GridView.count(

            crossAxisCount: 4,

            crossAxisSpacing: 20,

            mainAxisSpacing: 20,

            childAspectRatio: 1.55,

            shrinkWrap: true,

            physics: const NeverScrollableScrollPhysics(),

            children: const [

              const StatisticsCard(

                title: "Projects",

                value: "48",

                icon: Icons.apartment_rounded,

                color: Colors.blue,

                change: 12.4,

                isPositive: true,

              ),

              const StatisticsCard(

                title: "Engineers",

                value: "132",

                icon: Icons.engineering_rounded,

                color: Colors.green,
                
                change: 4.8,

                isPositive: true,

              ),

              const StatisticsCard(

                title: "Budget",

                value: "\$2.8M",

                icon: Icons.account_balance_wallet_rounded,

                color: Colors.orange,
                 
                change: 2.1,

                isPositive: true,

              ),

              const StatisticsCard(

                title: "Progress",

                value: "78%",

                icon: Icons.trending_up_rounded,

                color: Colors.purple,
                 
                change: 8.7,

                isPositive: true,

              ),

            ],

          ),

          const SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Expanded(
                flex: 2,
                child: Container(
                  height: 350,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 18,
                        color: Colors.black12,
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text(
                        "Active Projects",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      _projectTile(
                        "New Capital Tower",
                        "82%",
                        Colors.green,
                      ),

                      _projectTile(
                        "Cairo Business Park",
                        "64%",
                        Colors.orange,
                      ),

                      _projectTile(
                        "Smart Village",
                        "39%",
                        Colors.red,
                      ),

                      _projectTile(
                        "Alex Mall",
                        "95%",
                        Colors.blue,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: Container(
                  height: 350,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 18,
                        color: Colors.black12,
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      const Text(
                        "Recent Activity",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),
                      _activityTile(
                        Icons.check_circle,
                        "BOQ Approved",
                        "5 min ago",
                        Colors.green,
                      ),

                      _activityTile(
                        Icons.upload_file,
                        "Shop Drawings Uploaded",
                        "18 min ago",
                        Colors.blue,
                      ),

                      _activityTile(
                        Icons.warning_amber,
                        "RFI Waiting Response",
                        "40 min ago",
                        Colors.orange,
                      ),

                      _activityTile(
                        Icons.person_add,
                        "New Engineer Added",
                        "1 hour ago",
                        Colors.purple,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),
          const SizedBox(height: 25),
        ],
      ),
    );
  }

  Widget _projectTile(
    String title,
    String progress,
    Color color,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(.15),
        child: Icon(
          Icons.apartment_rounded,
          color: color,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          progress,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _activityTile(
    IconData icon,
    String title,
    String time,
    Color color,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(.15),
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(time),
    );
  }
}