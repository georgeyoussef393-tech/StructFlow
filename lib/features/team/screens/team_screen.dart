import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:structflow/core/theme/app_colors.dart';
import 'package:structflow/features/team/models/team_model.dart';
import 'package:structflow/features/team/repositories/team_repository.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final TeamRepository _repository =
      TeamRepository.instance;

  final TextEditingController _searchController =
      TextEditingController();

  String _selectedStatus = 'All';
  String _selectedSpecialization = 'All';

  @override
  void initState() {
    super.initState();

    _repository.addListener(_onTeamChanged);
  }

  @override
  void dispose() {
    _repository.removeListener(_onTeamChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onTeamChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // ================================================================
  // FILTERED MEMBERS
  // ================================================================

  List<TeamModel> get _filteredMembers {
    final query =
        _searchController.text.trim().toLowerCase();

    return _repository.members.where((member) {
      final matchesSearch =
          query.isEmpty ||
          member.name.toLowerCase().contains(query) ||
          member.role.toLowerCase().contains(query) ||
          member.specialization
              .toLowerCase()
              .contains(query) ||
          member.projectName
              .toLowerCase()
              .contains(query) ||
          member.projectCode
              .toLowerCase()
              .contains(query) ||
          member.email.toLowerCase().contains(query);

      final matchesStatus =
          _selectedStatus == 'All' ||
          member.status == _selectedStatus;

      final matchesSpecialization =
          _selectedSpecialization == 'All' ||
          member.specialization ==
              _selectedSpecialization;

      return matchesSearch &&
          matchesStatus &&
          matchesSpecialization;
    }).toList();
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF5F7FB),
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
                  _buildHeader(width),

                  const SizedBox(height: 24),

                  _buildSummaryCards(width),

                  const SizedBox(height: 24),

                  _buildToolbar(width),

                  const SizedBox(height: 20),

                  _buildTeamSection(width),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ================================================================
  // HEADER
  // ================================================================

  Widget _buildHeader(double width) {
    final isMobile = width < 650;

    if (isMobile) {
      return Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () {
              context.go('/');
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
            'Team',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Manage your project team and engineering staff.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: _buildAddMemberButton(),
          ),
        ],
      );
    }

    return Row(
      children: [
        IconButton(
          onPressed: () {
            context.go('/');
          },
          tooltip: 'Back to Dashboard',
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),

        const SizedBox(width: 8),

        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Team',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),

              SizedBox(height: 6),

              Text(
                'Manage your project team and engineering staff.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),

        _buildAddMemberButton(),
      ],
    );
  }

  // ================================================================
  // ADD MEMBER BUTTON
  // ================================================================

  Widget _buildAddMemberButton() {
    return ElevatedButton.icon(
      onPressed: _showAddMemberDialog,
      icon: const Icon(
        Icons.person_add_alt_1_rounded,
        size: 20,
      ),
      label: const Text(
        'Add Member',
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            AppColors.primary,
        foregroundColor:
            Colors.white,
        elevation: 0,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ================================================================
  // SUMMARY CARDS
  // ================================================================

  Widget _buildSummaryCards(
    double width,
  ) {
    final columns = width >= 1000
        ? 3
        : width >= 650
            ? 2
            : 1;

    final cards = [
      _SummaryData(
        title: 'Total Members',
        value:
            '${_repository.memberCount}',
        subtitle: 'All team members',
        icon:
            Icons.people_alt_rounded,
        color: Colors.blue,
      ),
      _SummaryData(
        title: 'Active',
        value:
            '${_repository.activeMemberCount}',
        subtitle: 'Currently active',
        icon:
            Icons.check_circle_rounded,
        color: Colors.green,
      ),
      _SummaryData(
        title: 'Inactive',
        value:
            '${_repository.inactiveMemberCount}',
        subtitle: 'Unavailable members',
        icon:
            Icons.pause_circle_filled_rounded,
        color: Colors.orange,
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
        mainAxisExtent: 140,
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
      padding:
          const EdgeInsets.all(20),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
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
            decoration:
                BoxDecoration(
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
                  style:
                      const TextStyle(
                    fontSize: 13,
                    color:
                        AppColors.textLight,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  data.value,
                  style:
                      const TextStyle(
                    fontSize: 25,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        AppColors.textDark,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  data.subtitle,
                  style:
                      const TextStyle(
                    fontSize: 11,
                    color:
                        AppColors.textLight,
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

  Widget _buildToolbar(
    double width,
  ) {
    final isMobile = width < 800;

    if (isMobile) {
      return Column(
        children: [
          _buildSearch(),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child:
                    _buildStatusFilter(),
              ),

              const SizedBox(width: 10),

              Expanded(
                child:
                    _buildSpecializationFilter(),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildSearch(),
        ),

        const SizedBox(width: 14),

        _buildStatusFilter(),

        const SizedBox(width: 10),

        _buildSpecializationFilter(),
      ],
    );
  }

  // ================================================================
  // SEARCH
  // ================================================================

  Widget _buildSearch() {
    return TextField(
      controller:
          _searchController,
      onChanged: (_) {
        setState(() {});
      },
      decoration:
          InputDecoration(
        hintText:
            'Search members, roles, projects...',
        prefixIcon:
            const Icon(
          Icons.search_rounded,
        ),
        suffixIcon:
            _searchController
                    .text
                    .isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController
                          .clear();
                      setState(() {});
                    },
                    icon:
                        const Icon(
                      Icons.close_rounded,
                    ),
                  )
                : null,
        filled: true,
        fillColor: Colors.white,
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              BorderSide.none,
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              BorderSide.none,
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              const BorderSide(
            color:
                AppColors.primary,
          ),
        ),
      ),
    );
  }

  // ================================================================
  // STATUS FILTER
  // ================================================================

  Widget _buildStatusFilter() {
    return _filterDropdown(
      value: _selectedStatus,
      items: const [
        'All',
        'Active',
        'On Leave',
        'Inactive',
      ],
      icon:
          Icons.person_outline_rounded,
      onChanged: (value) {
        setState(() {
          _selectedStatus = value;
        });
      },
    );
  }

  // ================================================================
  // SPECIALIZATION FILTER
  // ================================================================

  Widget _buildSpecializationFilter() {
    return _filterDropdown(
      value:
          _selectedSpecialization,
      items: const [
        'All',
        'Civil',
        'Architecture',
        'Electrical',
        'Mechanical',
        'Construction',
        'Management',
      ],
      icon:
          Icons.engineering_rounded,
      onChanged: (value) {
        setState(() {
          _selectedSpecialization =
              value;
        });
      },
    );
  }

  Widget _filterDropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String>
        onChanged,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
      ),
      child:
          DropdownButtonHideUnderline(
        child:
            DropdownButton<String>(
          value: value,
          icon:
              const Icon(
            Icons
                .keyboard_arrow_down_rounded,
          ),
          borderRadius:
              BorderRadius.circular(14),
          items: items.map((item) {
            return DropdownMenuItem<
                String>(
              value: item,
              child: Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 17,
                    color: Colors
                        .grey.shade600,
                  ),

                  const SizedBox(
                    width: 7,
                  ),

                  Text(item),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }

  // ================================================================
  // TEAM SECTION
  // ================================================================

  Widget _buildTeamSection(
    double width,
  ) {
    final members =
        _filteredMembers;

    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.all(
        width < 600 ? 16 : 22,
      ),
      decoration:
          BoxDecoration(
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
                  'Team Members',
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
                '${members.length} members',
                style:
                    const TextStyle(
                  fontSize: 13,
                  color:
                      AppColors.textLight,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (members.isEmpty)
            _buildEmptyState()
          else
            _buildMemberGrid(
              members,
              width,
            ),
        ],
      ),
    );
  }

  // ================================================================
  // MEMBER GRID
  // ================================================================

  Widget _buildMemberGrid(
    List<TeamModel> members,
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
      itemCount: members.length,
      gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        mainAxisExtent: 285,
      ),
      itemBuilder: (context, index) {
        return _buildMemberCard(
          members[index],
        );
      },
    );
  }

  // ================================================================
  // MEMBER CARD
  // ================================================================

  Widget _buildMemberCard(
    TeamModel member,
  ) {
    return InkWell(
      onTap: () {
        _showMemberDetails(
          member,
        );
      },
      borderRadius:
          BorderRadius.circular(18),
      child: Container(
        padding:
            const EdgeInsets.all(18),
        decoration:
            BoxDecoration(
          color:
              const Color(0xffFBFCFE),
          borderRadius:
              BorderRadius.circular(18),
          border:
              Border.all(
            color:
                Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration:
                      BoxDecoration(
                    color:
                        member.color
                            .withValues(
                      alpha: .10,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                            15),
                  ),
                  child: Icon(
                    member.icon,
                    color:
                        member.color,
                    size: 27,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        member.name,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              AppColors
                                  .textDark,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        member.id,
                        style:
                            const TextStyle(
                          fontSize: 11,
                          color:
                              AppColors
                                  .textLight,
                        ),
                      ),
                    ],
                  ),
                ),

                _buildStatusBadge(
                  member.status,
                ),
              ],
            ),

            const SizedBox(height: 18),

            Text(
              member.role,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    FontWeight.w600,
                color: member.color,
              ),
            ),

            const SizedBox(height: 6),

            _infoRow(
              Icons.engineering_rounded,
              member.specialization,
            ),

            const SizedBox(height: 8),

            _infoRow(
              Icons.folder_outlined,
              member.projectName,
            ),

            const SizedBox(height: 8),

            _infoRow(
              Icons.email_outlined,
              member.email,
            ),

            const SizedBox(height: 8),

            _infoRow(
              Icons.phone_outlined,
              member.phone,
            ),

            const Spacer(),

            Row(
              children: [
                Text(
                  'View Profile',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        member.color,
                  ),
                ),

                const Spacer(),

                Icon(
                  Icons
                      .arrow_forward_ios_rounded,
                  size: 13,
                  color:
                      member.color,
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
    final color =
        _statusColor(status);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
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
          fontSize: 10,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  Color _statusColor(
    String status,
  ) {
    switch (status) {
      case 'Active':
        return Colors.green;

      case 'On Leave':
        return Colors.orange;

      case 'Inactive':
        return Colors.red;

      default:
        return Colors.grey;
    }
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
          size: 15,
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
              fontSize: 11,
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
              Icons
                  .people_outline_rounded,
              size: 52,
              color:
                  Colors.grey.shade400,
            ),

            const SizedBox(height: 14),

            const Text(
              'No team members found',
              style:
                  TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
                color:
                    AppColors.textDark,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Try changing your search or filters.',
              style:
                  TextStyle(
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
  // MEMBER DETAILS
  // ================================================================

  void _showMemberDetails(
    TeamModel member,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),

          title: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration:
                    BoxDecoration(
                  color:
                      member.color
                          .withValues(
                    alpha: .10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                          13),
                ),
                child: Icon(
                  member.icon,
                  color:
                      member.color,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  member.name,
                  overflow:
                      TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _detailRow(
                'Role',
                member.role,
              ),
              _detailRow(
                'Specialization',
                member.specialization,
              ),
              _detailRow(
                'Project',
                '${member.projectCode} • ${member.projectName}',
              ),
              _detailRow(
                'Email',
                member.email,
              ),
              _detailRow(
                'Phone',
                member.phone,
              ),
              _detailRow(
                'Status',
                member.status,
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text('Close'),
            ),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                _showEditMemberDialog(
                  member,
                );
              },
              icon: const Icon(
                Icons.edit_rounded,
                size: 17,
              ),
              label:
                  const Text('Edit'),
            ),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                _confirmDelete(
                  member,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              icon: const Icon(
                Icons
                    .delete_outline_rounded,
                size: 17,
              ),
              label:
                  const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
                const TextStyle(
              fontSize: 11,
              color:
                  AppColors.textLight,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            value,
            style:
                const TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w600,
              color:
                  AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // EDIT MEMBER
  // ================================================================

  void _showEditMemberDialog(
    TeamModel member,
  ) {
    final nameController =
        TextEditingController(
      text: member.name,
    );

    final roleController =
        TextEditingController(
      text: member.role,
    );

    final specializationController =
        TextEditingController(
      text: member.specialization,
    );

    final emailController =
        TextEditingController(
      text: member.email,
    );

    final phoneController =
        TextEditingController(
      text: member.phone,
    );

    String status = member.status;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder:
              (context, setDialogState) {
            return AlertDialog(
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                        20),
              ),

              title: const Text(
                'Edit Team Member',
              ),

              content:
                  SingleChildScrollView(
                child: SizedBox(
                  width: 450,
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      _dialogField(
                        controller:
                            nameController,
                        label: 'Name',
                        icon: Icons
                            .person_outline_rounded,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      _dialogField(
                        controller:
                            roleController,
                        label: 'Role',
                        icon: Icons
                            .work_outline_rounded,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      _dialogField(
                        controller:
                            specializationController,
                        label:
                            'Specialization',
                        icon: Icons
                            .engineering_rounded,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      _dialogField(
                        controller:
                            emailController,
                        label: 'Email',
                        icon: Icons
                            .email_outlined,
                        keyboardType:
                            TextInputType
                                .emailAddress,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      _dialogField(
                        controller:
                            phoneController,
                        label: 'Phone',
                        icon: Icons
                            .phone_outlined,
                        keyboardType:
                            TextInputType.phone,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      DropdownButtonFormField<
                          String>(
                        initialValue: status,
                        decoration:
                            InputDecoration(
                          labelText:
                              'Status',
                          prefixIcon:
                              const Icon(
                            Icons
                                .flag_outlined,
                          ),
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                                        12),
                          ),
                        ),
                        items:
                            const [
                          DropdownMenuItem(
                            value:
                                'Active',
                            child:
                                Text(
                              'Active',
                            ),
                          ),
                          DropdownMenuItem(
                            value:
                                'On Leave',
                            child:
                                Text(
                              'On Leave',
                            ),
                          ),
                          DropdownMenuItem(
                            value:
                                'Inactive',
                            child:
                                Text(
                              'Inactive',
                            ),
                          ),
                        ],
                        onChanged:
                            (value) {
                          if (value ==
                              null) {
                            return;
                          }

                          setDialogState(
                            () {
                              status =
                                  value;
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child:
                      const Text('Cancel'),
                ),

                ElevatedButton.icon(
                  onPressed: () {
                    if (nameController
                            .text
                            .trim()
                            .isEmpty ||
                        roleController
                            .text
                            .trim()
                            .isEmpty ||
                        specializationController
                            .text
                            .trim()
                            .isEmpty) {
                      _showMessage(
                        'Name, role and specialization are required.',
                      );
                      return;
                    }

                    final specialization =
                        specializationController
                            .text
                            .trim();

                    final updatedMember =
                        member.copyWith(
                      name:
                          nameController
                              .text
                              .trim(),
                      role:
                          roleController
                              .text
                              .trim(),
                      specialization:
                          specialization,
                      email:
                          emailController
                              .text
                              .trim(),
                      phone:
                          phoneController
                              .text
                              .trim(),
                      status: status,
                      color:
                          _memberColor(
                        specialization,
                      ),
                      icon:
                          _memberIcon(
                        specialization,
                      ),
                    );

                    _repository
                        .updateMember(
                      updatedMember,
                    );

                    Navigator.pop(
                      dialogContext,
                    );

                    _showMessage(
                      'Team member updated successfully.',
                    );
                  },
                  icon: const Icon(
                    Icons.save_rounded,
                  ),
                  label:
                      const Text(
                    'Save Changes',
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      nameController.dispose();
      roleController.dispose();
      specializationController.dispose();
      emailController.dispose();
      phoneController.dispose();
    });
  }

  // ================================================================
  // ADD MEMBER
  // ================================================================

  void _showAddMemberDialog() {
    final nameController =
        TextEditingController();

    final roleController =
        TextEditingController();

    final specializationController =
        TextEditingController();

    final emailController =
        TextEditingController();

    final phoneController =
        TextEditingController();

    String status = 'Active';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder:
              (context, setDialogState) {
            return AlertDialog(
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                        20),
              ),

              title: const Text(
                'Add Team Member',
              ),

              content:
                  SingleChildScrollView(
                child: SizedBox(
                  width: 450,
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      _dialogField(
                        controller:
                            nameController,
                        label: 'Name',
                        icon: Icons
                            .person_outline_rounded,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      _dialogField(
                        controller:
                            roleController,
                        label: 'Role',
                        icon: Icons
                            .work_outline_rounded,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      _dialogField(
                        controller:
                            specializationController,
                        label:
                            'Specialization',
                        icon: Icons
                            .engineering_rounded,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      _dialogField(
                        controller:
                            emailController,
                        label: 'Email',
                        icon: Icons
                            .email_outlined,
                        keyboardType:
                            TextInputType
                                .emailAddress,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      _dialogField(
                        controller:
                            phoneController,
                        label: 'Phone',
                        icon: Icons
                            .phone_outlined,
                        keyboardType:
                            TextInputType.phone,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      DropdownButtonFormField<
                          String>(
                        initialValue:
                            status,
                        decoration:
                            InputDecoration(
                          labelText:
                              'Status',
                          prefixIcon:
                              const Icon(
                            Icons
                                .flag_outlined,
                          ),
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                                        12),
                          ),
                        ),
                        items:
                            const [
                          DropdownMenuItem(
                            value:
                                'Active',
                            child:
                                Text(
                              'Active',
                            ),
                          ),
                          DropdownMenuItem(
                            value:
                                'On Leave',
                            child:
                                Text(
                              'On Leave',
                            ),
                          ),
                          DropdownMenuItem(
                            value:
                                'Inactive',
                            child:
                                Text(
                              'Inactive',
                            ),
                          ),
                        ],
                        onChanged:
                            (value) {
                          if (value ==
                              null) {
                            return;
                          }

                          setDialogState(
                            () {
                              status =
                                  value;
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child:
                      const Text('Cancel'),
                ),

                ElevatedButton.icon(
                  onPressed: () {
                    if (nameController
                            .text
                            .trim()
                            .isEmpty ||
                        roleController
                            .text
                            .trim()
                            .isEmpty ||
                        specializationController
                            .text
                            .trim()
                            .isEmpty) {
                      _showMessage(
                        'Name, role and specialization are required.',
                      );
                      return;
                    }

                    final specialization =
                        specializationController
                            .text
                            .trim();

                    final member =
                        TeamModel(
                      id: _repository
                          .nextMemberId,
                      name:
                          nameController
                              .text
                              .trim(),
                      role:
                          roleController
                              .text
                              .trim(),
                      specialization:
                          specialization,
                      email:
                          emailController
                              .text
                              .trim(),
                      phone:
                          phoneController
                              .text
                              .trim(),
                      projectCode:
                          'PRJ-001',
                      projectName:
                          'New Capital Tower',
                      status: status,
                      color:
                          _memberColor(
                        specialization,
                      ),
                      icon:
                          _memberIcon(
                        specialization,
                      ),
                    );

                    _repository
                        .addMember(member);

                    Navigator.pop(
                      dialogContext,
                    );

                    _showMessage(
                      'Team member added successfully.',
                    );
                  },
                  icon: const Icon(
                    Icons
                        .person_add_alt_1_rounded,
                  ),
                  label:
                      const Text(
                    'Add Member',
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      nameController.dispose();
      roleController.dispose();
      specializationController.dispose();
      emailController.dispose();
      phoneController.dispose();
    });
  }

  // ================================================================
  // DIALOG FIELD
  // ================================================================

  Widget _dialogField({
    required TextEditingController
        controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration:
          InputDecoration(
        labelText: label,
        prefixIcon:
            Icon(icon),
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ================================================================
  // DELETE
  // ================================================================

  void _confirmDelete(
    TeamModel member,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Team Member?',
          ),
          content: Text(
            'Are you sure you want to delete "${member.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                _repository
                    .deleteMember(
                  member.id,
                );

                Navigator.pop(
                  dialogContext,
                );

                _showMessage(
                  'Team member deleted successfully.',
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // ================================================================
  // COLORS
  // ================================================================

  Color _memberColor(
    String specialization,
  ) {
    switch (
        specialization.toLowerCase()) {
      case 'civil':
        return Colors.blue;

      case 'architecture':
        return Colors.purple;

      case 'electrical':
        return Colors.orange;

      case 'mechanical':
        return Colors.teal;

      case 'construction':
        return Colors.green;

      case 'management':
        return Colors.indigo;

      default:
        return AppColors.primary;
    }
  }

  // ================================================================
  // ICONS
  // ================================================================

  IconData _memberIcon(
    String specialization,
  ) {
    switch (
        specialization.toLowerCase()) {
      case 'civil':
        return Icons.engineering_rounded;

      case 'architecture':
        return Icons.architecture_rounded;

      case 'electrical':
        return Icons
            .electrical_services_rounded;

      case 'mechanical':
        return Icons
            .precision_manufacturing_rounded;

      case 'construction':
        return Icons
            .construction_rounded;

      case 'management':
        return Icons
            .manage_accounts_rounded;

      default:
        return Icons.person_rounded;
    }
  }

  // ================================================================
  // MESSAGE
  // ================================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }
}

// ============================================================================
// SUMMARY DATA
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