import 'package:flutter/material.dart';
import 'package:structflow/core/responsive/responsive.dart';
import 'package:structflow/features/dashboard/widgets/statistics_card.dart';
import 'package:structflow/features/projects/models/project_model.dart';
import 'package:structflow/features/projects/repositories/project_repository.dart';
import 'package:structflow/features/tasks/models/task_model.dart';
import 'package:structflow/features/tasks/repositories/task_repository.dart';

class DashboardBody extends StatelessWidget {
  const DashboardBody({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        ProjectRepository.instance,
        TaskRepository.instance,
      ]),
      builder: (context, child) {
        final projects = ProjectRepository.instance.projects;
        final tasks = TaskRepository.instance.tasks;
        final completedTasks = tasks.where((task) => task.status == 'Done').length;
        final averageProgress = tasks.isEmpty
            ? 0
            : (tasks.map((task) => task.progress).reduce((total, progress) => total + progress) * 100).round();
        final columns = Responsive.gridColumns(context);
        final horizontalPadding = Responsive.horizontalPadding(context);
        final spacing = Responsive.spacing(context);
        final cards = [
          StatisticsCard(
            title: 'Projects',
            value: '${projects.length}',
            icon: Icons.apartment_rounded,
            color: Colors.blue,
            change: 0,
            isPositive: true,
          ),
          StatisticsCard(
            title: 'Tasks',
            value: '${tasks.length}',
            icon: Icons.task_alt_rounded,
            color: Colors.orange,
            change: 0,
            isPositive: true,
          ),
          StatisticsCard(
            title: 'Completed',
            value: '$completedTasks',
            icon: Icons.check_circle_rounded,
            color: Colors.green,
            change: 0,
            isPositive: true,
          ),
          StatisticsCard(
            title: 'Task Progress',
            value: '$averageProgress%',
            icon: Icons.trending_up_rounded,
            color: Colors.purple,
            change: 0,
            isPositive: true,
          ),
        ];

        return SingleChildScrollView(
          padding: EdgeInsets.all(horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cards.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  mainAxisExtent: 225,
                ),
                itemBuilder: (context, index) => cards[index],
              ),
              SizedBox(height: spacing + 10),
              _buildMainSections(context, projects, tasks),
              SizedBox(height: spacing),
            ],
          ),
        );
      },
    );
  }

Widget _buildMainSections(
  BuildContext context,
  List<ProjectModel> projects,
  List<TaskModel> tasks,
) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final availableWidth = constraints.maxWidth;

      // عندما تكون المساحة الفعلية صغيرة
      // نضع الكروت تحت بعضها.
      if (availableWidth < 950) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _activeProjectsCard(projects),

            const SizedBox(height: 20),

            _recentActivityCard(tasks),
          ],
        );
      }

      // Desktop
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _activeProjectsCard(projects),
          ),

          const SizedBox(width: 20),

          Expanded(
            flex: 1,
            child: _recentActivityCard(tasks),
          ),
        ],
      );
    },
  );
}

  Widget _activeProjectsCard(List<ProjectModel> projects) {
    return _sectionCard(
      title: "Active Projects",
      icon: Icons.apartment_rounded,
      child: Column(
        children: [
          ...projects.take(4).map(
            (project) => _projectTile(
              project.name,
              project.progress,
              project.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentActivityCard(List<TaskModel> tasks) {
    final upcomingTasks = [...tasks]
      ..sort((first, second) => first.dueDate.compareTo(second.dueDate));

    return _sectionCard(
      title: 'Upcoming Tasks',
      icon: Icons.schedule_rounded,
      child: Column(
        children: [
          if (upcomingTasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No upcoming tasks.',
                style: TextStyle(color: Color(0xff6B7280)),
              ),
            )
          else
            ...upcomingTasks.take(4).map(
              (task) => _activityTile(
                Icons.task_alt_rounded,
                task.title,
                'Due ${_formatDate(task.dueDate)} • ${task.status}',
                task.color,
              ),
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

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}
