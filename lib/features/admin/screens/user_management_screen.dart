import 'package:flutter/material.dart';

import 'package:structflow/core/theme/app_colors.dart';
import 'package:structflow/features/attendance/models/attendance_permission_model.dart';
import 'package:structflow/features/attendance/repositories/attendance_permission_repository.dart';
import 'package:structflow/features/auth/models/auth_user_model.dart';
import 'package:structflow/features/auth/repositories/auth_repository.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _auth = AuthRepository.instance;
  final _permissions = AttendancePermissionRepository.instance;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_refresh);
    _permissions.addListener(_refresh);
  }

  @override
  void dispose() {
    _auth.removeListener(_refresh);
    _permissions.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  bool get _canManage =>
      _auth.currentUser?.isSystemOwner == true ||
      _auth.currentUser?.isOwner == true ||
      const {
        'Consultant Manager',
        'Owner HR Manager',
        'Consultant HR Manager',
      }.contains(_auth.currentUser?.role);

  @override
  Widget build(BuildContext context) {
    final current = _auth.currentUser;
    if (current == null || !_canManage) {
      return const Scaffold(body: Center(child: Text('Access denied.')));
    }

    final currentOrg = current.organization;
    final visibleUsers = current.isSystemOwner
        ? _auth.users
        : _auth.users.where((u) => u.organization == currentOrg).toList();
    final pending = visibleUsers.where((u) => u.isPending).toList();
    final approved = visibleUsers.where((u) => u.isApproved).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 950;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _hero(current),
                const SizedBox(height: 22),
                _sectionHeader(
                  'Pending approval',
                  '${pending.length} request${pending.length == 1 ? '' : 's'}',
                ),
                const SizedBox(height: 10),
                if (pending.isEmpty)
                  _emptyCard('No pending registration requests.')
                else
                  ...pending.map((user) => _pendingCard(user)),
                const SizedBox(height: 28),
                _sectionHeader('Users', '${approved.length} approved'),
                const SizedBox(height: 10),
                if (wide)
                  _usersTable(approved)
                else
                  ...approved.map((user) => _userCard(user)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _hero(AuthUserModel current) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Roles & Permissions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${current.name} • ${current.role} • ${current.organization}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: .86)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            count,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyCard(String text) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(Icons.inbox_outlined, color: AppColors.textLight),
            const SizedBox(width: 12),
            Text(text, style: const TextStyle(color: AppColors.textLight)),
          ],
        ),
      ),
    );
  }

  Widget _pendingCard(AuthUserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _avatar(user),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user.email,
                    style: const TextStyle(color: AppColors.textLight),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${user.organization} • Requested: ${user.role}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => _approve(user),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Review & Approve'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _usersTable(List<AuthUserModel> users) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('User')),
          DataColumn(label: Text('Role')),
          DataColumn(label: Text('Permissions')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: users.map((user) {
          final p = _permissionFor(user);
          return DataRow(
            cells: [
              DataCell(
                Row(
                  children: [
                    _avatar(user, small: true),
                    const SizedBox(width: 9),
                    SizedBox(
                      width: 190,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            user.email,
                            overflow: TextOverflow.ellipsis,
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
              ),
              DataCell(Text(user.role)),
              DataCell(
                Text(
                  user.isOwner
                      ? 'Full access'
                      : '${p?.permissions.length ?? 0} modules',
                ),
              ),
              DataCell(_statusChip(user.status)),
              DataCell(_actions(user)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _userCard(AuthUserModel user) {
    final p = _permissionFor(user);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: _avatar(user),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${user.email}\n${user.role} • ${user.isOwner ? 'Full access' : '${p?.permissions.length ?? 0} modules'}',
        ),
        isThreeLine: true,
        trailing: _actions(user),
      ),
    );
  }

  Widget _actions(AuthUserModel user) {
    final current = _auth.currentUser!;
    final canEdit =
        current.isSystemOwner || current.isOwner || user.role == 'Employee';
    if (user.id == current.id) {
      return const Chip(label: Text('You'));
    }
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') _editUser(user);
        if (value == 'delete') _deleteUser(user);
      },
      itemBuilder: (context) => [
        if (canEdit)
          const PopupMenuItem(
            value: 'edit',
            child: Text('Edit role & permissions'),
          ),
        const PopupMenuItem(value: 'delete', child: Text('Remove user')),
      ],
    );
  }

  AttendancePermissionModel? _permissionFor(AuthUserModel user) {
    return _permissions.permissions
        .cast<AttendancePermissionModel?>()
        .firstWhere(
          (p) =>
              p!.userId == user.id && p.organizationId == _organizationId(user),
          orElse: () => null,
        );
  }

  String _organizationId(AuthUserModel user) =>
      'ORG-${user.organization.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}';

  Widget _avatar(AuthUserModel user, {bool small = false}) {
    final size = small ? 32.0 : 44.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(small ? 9 : 12),
      ),
      child: Text(
        user.name.trim().isEmpty ? '?' : user.name.trim()[0].toUpperCase(),
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: small ? 13 : 17,
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    return Chip(
      label: Text(status, style: const TextStyle(fontSize: 11)),
      avatar: Icon(
        status == 'Approved' ? Icons.check_circle : Icons.schedule,
        size: 15,
        color: status == 'Approved' ? AppColors.success : AppColors.warning,
      ),
    );
  }

  Future<void> _approve(AuthUserModel user) async {
    final result = await _permissionDialog(user, initialRole: 'Employee');
    if (result == null) return;

    final actor = _auth.currentUser!;
    final ok = await _auth.approveUser(
      actorUserId: actor.id,
      userId: user.id,
      role: result.role,
    );
    if (!ok) {
      _message('This user cannot be approved by the current manager.');
      return;
    }

    final permission = _buildPermission(
      user: user,
      role: result.role,
      modules: result.modules,
    );

    final saved = await _permissions.save(
      actorUserId: actor.id,
      permission: permission,
    );
    if (!saved && !mounted) return;
    if (!saved) {
      _message('User approved, but permissions could not be saved.');
      return;
    }
    _message('${user.name} approved successfully.');
  }

  Future<void> _editUser(AuthUserModel user) async {
    final existing = _permissionFor(user);
    final result = await _permissionDialog(
      user,
      initialRole: user.role,
      initialModules: existing?.permissions ?? const [],
    );
    if (result == null) return;

    final actor = _auth.currentUser!;
    final roleChanged = await _auth.updateUser(
      actorUserId: actor.id,
      userId: user.id,
      role: result.role,
      status: 'Approved',
    );
    if (!roleChanged) {
      _message('This role cannot be assigned by the current manager.');
      return;
    }

    final updated = _buildPermission(
      user: user,
      role: result.role,
      modules: result.modules,
    );
    final saved = await _permissions.save(
      actorUserId: actor.id,
      permission: updated,
    );
    _message(saved ? 'Permissions updated.' : 'Could not save permissions.');
  }

  AttendancePermissionModel _buildPermission({
    required AuthUserModel user,
    required String role,
    required List<String> modules,
  }) {
    final organizationId = _organizationId(user);
    final isOwner = role == 'Owner' || role == 'Super Admin';
    final effective = isOwner
        ? AttendancePermissionModel.modulePermissions.toList()
        : modules.toSet().toList();

    return AttendancePermissionModel(
      id: 'PERM-${user.id}',
      organizationId: organizationId,
      userId: user.id,
      role: role,
      locationAttendanceEnabled: true,
      canManageProjectGeofences:
          isOwner ||
          role == 'Consultant Manager' ||
          role == 'Owner HR Manager' ||
          role == 'Consultant HR Manager',
      canViewProjectAttendance: isOwner || role.contains('Manager'),
      canViewOrganizationAttendance: isOwner || role == 'Owner HR Manager',
      permissions: effective,
      updatedAt: DateTime.now(),
    );
  }

  Future<_PermissionResult?> _permissionDialog(
    AuthUserModel user, {
    required String initialRole,
    List<String> initialModules = const [],
  }) async {
    var role = initialRole;
    final selected = initialModules.toSet();
    final actor = _auth.currentUser!;
    final roles = actor.isSystemOwner
        ? AttendancePermissionModel.roles
        : actor.isOwner
        ? const [
            'Employee',
            'Consultant Manager',
            'Owner HR Manager',
            'Consultant HR Manager',
          ]
        : const ['Employee'];

    return showDialog<_PermissionResult>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) {
          final full = role == 'Owner';
          return AlertDialog(
            title: Text('Permissions • ${user.name}'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: roles.contains(role) ? role : roles.first,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      items: roles
                          .map(
                            (r) => DropdownMenuItem(value: r, child: Text(r)),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setLocal(() {
                          role = value;
                          if (value == 'Owner') {
                            selected.addAll(
                              AttendancePermissionModel.modulePermissions,
                            );
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Module access',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    ...AttendancePermissionModel.modulePermissions.map(
                      (module) => CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(_moduleName(module)),
                        value: full || selected.contains(module),
                        onChanged: full
                            ? null
                            : (value) {
                                setLocal(() {
                                  if (value == true) {
                                    selected.add(module);
                                  } else {
                                    selected.remove(module);
                                  }
                                });
                              },
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Attendance is always available. Attendance Management is controlled by the manager role.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(
                  dialogContext,
                  _PermissionResult(role, selected.toList()),
                ),
                child: const Text('Save & Approve'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _moduleName(String value) {
    if (value == 'bim') return 'BIM Coordination';
    return value[0].toUpperCase() + value.substring(1);
  }

  Future<void> _deleteUser(AuthUserModel user) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove user?'),
        content: Text('Remove ${user.name} from this organization?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (yes != true) return;

    final ok = await _auth.deleteUser(
      actorUserId: _auth.currentUser!.id,
      userId: user.id,
    );
    if (!ok) {
      _message('This user cannot be removed by the current manager.');
      return;
    }
    await _permissions.revoke(
      actorUserId: _auth.currentUser!.id,
      organizationId: _organizationId(user),
      userId: user.id,
    );
    _message('User removed.');
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}

class _PermissionResult {
  final String role;
  final List<String> modules;

  const _PermissionResult(this.role, this.modules);
}
