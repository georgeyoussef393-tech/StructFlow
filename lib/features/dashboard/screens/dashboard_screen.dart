import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FA),

      appBar: AppBar(
        backgroundColor: const Color(0xff0B1F36),
        elevation: 0,
        title: const Text(
          "StructFlow",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.notifications_none, color: Colors.white),
          ),
        ],
      ),

      drawer: Drawer(
        child: ListView(
          children: const [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xff0B1F36),
              ),
              child: Center(
                child: Text(
                  "StructFlow",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text("Dashboard"),
            ),

            ListTile(
              leading: Icon(Icons.folder_copy_outlined),
              title: Text("Projects"),
            ),

            ListTile(
              leading: Icon(Icons.people_outline),
              title: Text("Team"),
            ),

            ListTile(
              leading: Icon(Icons.bar_chart),
              title: Text("Reports"),
            ),

            ListTile(
              leading: Icon(Icons.settings),
              title: Text("Settings"),
            ),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(
              "Welcome to StructFlow",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Construction Management System",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 30),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
                children: const [

                  DashboardCard(
                    title: "Projects",
                    icon: Icons.folder_copy,
                    color: Colors.blue,
                  ),

                  DashboardCard(
                    title: "Team",
                    icon: Icons.people,
                    color: Colors.green,
                  ),

                  DashboardCard(
                    title: "Schedule",
                    icon: Icons.calendar_month,
                    color: Colors.orange,
                  ),

                  DashboardCard(
                    title: "Reports",
                    icon: Icons.bar_chart,
                    color: Colors.red,
                  ),

                  DashboardCard(
                    title: "Cost Control",
                    icon: Icons.attach_money,
                    color: Colors.purple,
                  ),

                  DashboardCard(
                    title: "AI Assistant",
                    icon: Icons.smart_toy,
                    color: Colors.teal,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {

  final String title;
  final IconData icon;
  final Color color;

  const DashboardCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {

    return Card(
      elevation: 6,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),

      child: InkWell(
        borderRadius: BorderRadius.circular(20),

        onTap: () {},

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(.12),
              child: Icon(
                icon,
                size: 34,
                color: color,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}