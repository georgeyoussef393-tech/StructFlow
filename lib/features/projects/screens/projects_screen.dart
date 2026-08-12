import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:structflow/core/theme/app_colors.dart';
import 'package:structflow/features/projects/models/project_model.dart';
import 'package:structflow/features/projects/repositories/project_repository.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  final ProjectRepository _repository =
      ProjectRepository.instance;

  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();

    _repository.addListener(_onProjectsChanged);
  }

  @override
  void dispose() {
    _repository.removeListener(_onProjectsChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onProjectsChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // ================================================================
  // FILTERED PROJECTS
  // ================================================================

  List<ProjectModel> get _filteredProjects {
    final query =
        _searchController.text.trim().toLowerCase();

    return _repository.projects.where((project) {
      final matchesSearch =
          query.isEmpty ||
          project.name.toLowerCase().contains(query) ||
          project.code.toLowerCase().contains(query) ||
          project.client.toLowerCase().contains(query) ||
          project.location.toLowerCase().contains(query);

      final matchesFilter =
          _selectedFilter == 'All' ||
          project.status == _selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            return SingleChildScrollView(
              padding: EdgeInsets.all(
                width < 600 ? 16 : 28,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildPageHeader(width),

                  const SizedBox(height: 24),

                  _buildSummaryCards(width),

                  const SizedBox(height: 24),

                  _buildToolbar(width),

                  const SizedBox(height: 20),

                  _buildProjectsSection(width),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ================================================================
  // PAGE HEADER
  // ================================================================

  Widget _buildPageHeader(double width) {
    final isMobile = width < 650;

    if (isMobile) {
      return Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ==========================================================
          // BACK TO DASHBOARD
          // ==========================================================

          TextButton.icon(
            onPressed: () {
              context.pop();
            },
            icon: const Icon(
              Icons.arrow_back_rounded,
            ),
            label: const Text(
              'Back to Dashboard',
            ),
            style: TextButton.styleFrom(
              foregroundColor:
                  AppColors.primary,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 4,
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Projects',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Manage and monitor your construction projects.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: _buildCreateButton(),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        // ==========================================================
        // BACK BUTTON
        // ==========================================================

        Padding(
          padding: const EdgeInsets.only(
            top: 2,
            right: 10,
          ),
          child: IconButton(
            onPressed: () {
              context.pop();
            },
            tooltip: 'Back to Dashboard',
            icon: const Icon(
              Icons.arrow_back_rounded,
            ),
            color: AppColors.textDark,
          ),
        ),

        // ==========================================================
        // TITLE
        // ==========================================================

        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Projects',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),

              SizedBox(height: 6),

              Text(
                'Manage and monitor your construction projects.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),

        // ==========================================================
        // CREATE PROJECT
        // ==========================================================

        _buildCreateButton(),
      ],
    );
  }

  // ================================================================
  // CREATE PROJECT BUTTON
  // ================================================================

  Widget _buildCreateButton() {
    return ElevatedButton.icon(
      onPressed: () {
        context.push('/create-project');
      },

      icon: const Icon(
        Icons.add_rounded,
        size: 20,
      ),

      label: const Text(
        'New Project',
      ),

      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,

        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ================================================================
  // SUMMARY CARDS
  // ================================================================

  Widget _buildSummaryCards(double width) {
    final columns = width >= 1100
        ? 4
        : width >= 700
            ? 2
            : 1;

    final cards = [
      _SummaryData(
        title: 'Total Projects',
        value: '${_repository.projectCount}',
        subtitle: 'All projects',
        icon: Icons.folder_copy_rounded,
        color: Colors.blue,
      ),

      _SummaryData(
        title: 'Active',
        value: '${_repository.activeProjectCount}',
        subtitle: 'Currently running',
        icon: Icons.play_circle_fill_rounded,
        color: Colors.green,
      ),

      _SummaryData(
        title: 'Planning',
        value: '${_repository.planningProjectCount}',
        subtitle: 'Under preparation',
        icon: Icons.pending_actions_rounded,
        color: Colors.orange,
      ),

      _SummaryData(
        title: 'On Hold',
        value: '${_repository.onHoldProjectCount}',
        subtitle: 'Needs attention',
        icon: Icons.pause_circle_filled_rounded,
        color: Colors.red,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,

      physics:
          const NeverScrollableScrollPhysics(),

      itemCount: cards.length,

      gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 145,
      ),

      itemBuilder: (context, index) {
        return _buildSummaryCard(
          cards[index],
        );
      },
    );
  }

  Widget _buildSummaryCard(
    _SummaryData data,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,

            decoration: BoxDecoration(
              color: data.color.withValues(
                alpha: .10,
              ),
              borderRadius:
                  BorderRadius.circular(14),
            ),

            child: Icon(
              data.icon,
              color: data.color,
              size: 25,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  data.value,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  data.subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // TOOLBAR
  // ================================================================

  Widget _buildToolbar(double width) {
    final isMobile = width < 700;

    if (isMobile) {
      return Column(
        children: [
          _buildSearchBox(),

          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerLeft,
            child: _buildFilterRow(),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildSearchBox(),
        ),

        const SizedBox(width: 16),

        _buildFilterRow(),
      ],
    );
  }

  // ================================================================
  // SEARCH
  // ================================================================

  Widget _buildSearchBox() {
    return TextField(
      controller: _searchController,

      onChanged: (_) {
        setState(() {});
      },

      decoration: InputDecoration(
        hintText:
            'Search projects, clients, locations...',

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

        fillColor: Colors.white,

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
      ),
    );
  }

  // ================================================================
  // FILTER
  // ================================================================

  Widget _buildFilterRow() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
      ),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,

          borderRadius:
              BorderRadius.circular(14),

          items: const [
            DropdownMenuItem(
              value: 'All',
              child: Text('All Status'),
            ),

            DropdownMenuItem(
              value: 'Active',
              child: Text('Active'),
            ),

            DropdownMenuItem(
              value: 'Planning',
              child: Text('Planning'),
            ),

            DropdownMenuItem(
              value: 'On Hold',
              child: Text('On Hold'),
            ),
          ],

          onChanged: (value) {
            if (value == null) {
              return;
            }

            setState(() {
              _selectedFilter = value;
            });
          },
        ),
      ),
    );
  }

  // ================================================================
  // PROJECTS SECTION
  // ================================================================

  Widget _buildProjectsSection(double width) {
    final projects = _filteredProjects;

    return Container(
      width: double.infinity,

      padding: EdgeInsets.all(
        width < 600 ? 16 : 22,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),

        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'All Projects',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        AppColors.textDark,
                  ),
                ),
              ),

              Text(
                '${projects.length} projects',
                style: const TextStyle(
                  fontSize: 13,
                  color:
                      AppColors.textLight,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (projects.isEmpty)
            _buildEmptyState()
          else
            _buildProjectGrid(
              projects,
              width,
            ),
        ],
      ),
    );
  }

  // ================================================================
  // PROJECT GRID
  // ================================================================

  Widget _buildProjectGrid(
    List<ProjectModel> projects,
    double width,
  ) {
    final columns = width >= 1250
        ? 3
        : width >= 750
            ? 2
            : 1;

    return GridView.builder(
      shrinkWrap: true,

      physics:
          const NeverScrollableScrollPhysics(),

      itemCount: projects.length,

      gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        mainAxisExtent: 320,
      ),

      itemBuilder: (context, index) {
        return _buildProjectCard(
          projects[index],
        );
      },
    );
  }

  // ================================================================
  // PROJECT CARD
  // ================================================================

  Widget _buildProjectCard(
    ProjectModel project,
  ) {
    return InkWell(
      onTap: () {
        _openProject(project);
      },

      borderRadius:
          BorderRadius.circular(18),

      child: Container(
        padding:
            const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color:
              const Color(0xffFBFCFE),

          borderRadius:
              BorderRadius.circular(18),

          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,

                  decoration:
                      BoxDecoration(
                    color:
                        project.color.withValues(
                      alpha: .10,
                    ),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),

                  child: Icon(
                    project.icon,
                    color: project.color,
                    size: 24,
                  ),
                ),

                const Spacer(),

                _buildStatusBadge(
                  project.status,
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              project.name,

              maxLines: 1,

              overflow:
                  TextOverflow.ellipsis,

              style: const TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
                color:
                    AppColors.textDark,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              project.code,
              style: const TextStyle(
                fontSize: 12,
                color:
                    AppColors.textLight,
              ),
            ),

            const SizedBox(height: 14),

            _infoRow(
              Icons.person_outline_rounded,
              project.client,
            ),

            const SizedBox(height: 8),

            _infoRow(
              Icons.location_on_outlined,
              project.location,
            ),

            const Spacer(),

            Row(
              children: [
                const Text(
                  'Progress',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        AppColors.textLight,
                  ),
                ),

                const Spacer(),

                Text(
                  '${(project.progress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        project.color,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 7),

            ClipRRect(
              borderRadius:
                  BorderRadius.circular(20),

              child:
                  LinearProgressIndicator(
                value:
                    project.progress,
                minHeight: 7,

                backgroundColor:
                    project.color.withValues(
                  alpha: .10,
                ),

                valueColor:
                    AlwaysStoppedAnimation<
                        Color>(
                  project.color,
                ),
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Icon(
                  Icons
                      .account_balance_wallet_outlined,
                  size: 16,
                  color:
                      Colors.grey.shade600,
                ),

                const SizedBox(width: 5),

                Text(
                  project.budget,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        AppColors.textDark,
                  ),
                ),

                const Spacer(),

                Icon(
                  Icons
                      .people_outline_rounded,
                  size: 17,
                  color:
                      Colors.grey.shade600,
                ),

                const SizedBox(width: 5),

                Text(
                  '${project.team}',
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        AppColors.textDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // STATUS BADGE
  // ================================================================

  Widget _buildStatusBadge(
    String status,
  ) {
    Color color;

    switch (status) {
      case 'Active':
        color = Colors.green;
        break;

      case 'Planning':
        color = Colors.orange;
        break;

      case 'On Hold':
        color = Colors.red;
        break;

      default:
        color = Colors.grey;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),

      decoration: BoxDecoration(
        color: color.withValues(
          alpha: .10,
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  // ================================================================
  // INFO ROW
  // ================================================================

  Widget _infoRow(
    IconData icon,
    String text,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color:
              Colors.grey.shade500,
        ),

        const SizedBox(width: 7),

        Expanded(
          child: Text(
            text,

            maxLines: 1,

            overflow:
                TextOverflow.ellipsis,

            style:
                const TextStyle(
              fontSize: 12,
              color:
                  AppColors.textLight,
            ),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // EMPTY STATE
  // ================================================================

  Widget _buildEmptyState() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 60,
      ),

      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 52,
              color:
                  Colors.grey.shade400,
            ),

            const SizedBox(height: 14),

            const Text(
              'No projects found',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
                color:
                    AppColors.textDark,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Try changing your search or filter.',
              style: TextStyle(
                color:
                    AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // OPEN PROJECT
  // ================================================================

  void _openProject(
    ProjectModel project,
  ) {
    context.push(
      '/projects/${project.code}',
    );
  }
}

// ============================================================================
// SUMMARY MODEL
// ============================================================================

class _SummaryData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SummaryData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}