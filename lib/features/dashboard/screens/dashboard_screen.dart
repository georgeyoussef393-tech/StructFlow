import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),

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
            padding: EdgeInsets.only(right: 20),
            child: Icon(
              Icons.notifications_none,
              color: Colors.white,
            ),
          )
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
              leading: Icon(Icons.folder_open),
              title: Text("Projects"),
            ),

            ListTile(
              leading: Icon(Icons.task_alt),
              title: Text("Tasks"),
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

      body: const Center(
        child: Text(
          "Dashboard",
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}