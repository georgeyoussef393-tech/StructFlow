import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:structflow/features/team/models/team_model.dart';

class TeamRepository extends ChangeNotifier {
  static const String _storageKey = 'structflow_team';

  TeamRepository._internal();

  static final TeamRepository instance =
      TeamRepository._internal();

  final List<TeamModel> _members = [
    const TeamModel(
      id: 'TEAM-001',
      name: 'Ahmed Hassan',
      role: 'Senior Civil Engineer',
      specialization: 'Civil',
      email: 'ahmed@structflow.com',
      phone: '+20 100 123 4567',
      projectCode: 'PRJ-001',
      projectName: 'New Capital Tower',
      status: 'Active',
      color: Colors.blue,
      icon: Icons.engineering_rounded,
    ),
    const TeamModel(
      id: 'TEAM-002',
      name: 'Michael George',
      role: 'Project Manager',
      specialization: 'Management',
      email: 'michael@structflow.com',
      phone: '+20 101 234 5678',
      projectCode: 'PRJ-002',
      projectName: 'Cairo Business Park',
      status: 'Active',
      color: Colors.purple,
      icon: Icons.manage_accounts_rounded,
    ),
    const TeamModel(
      id: 'TEAM-003',
      name: 'Daniel Sameh',
      role: 'Electrical Engineer',
      specialization: 'Electrical',
      email: 'daniel@structflow.com',
      phone: '+20 102 345 6789',
      projectCode: 'PRJ-004',
      projectName: 'Alex Mall',
      status: 'Active',
      color: Colors.orange,
      icon: Icons.electrical_services_rounded,
    ),
    const TeamModel(
      id: 'TEAM-004',
      name: 'George Youssef',
      role: 'Site Engineer',
      specialization: 'Construction',
      email: 'george@structflow.com',
      phone: '+20 103 456 7890',
      projectCode: 'PRJ-006',
      projectName: 'Tuban Villas',
      status: 'Active',
      color: Colors.green,
      icon: Icons.construction_rounded,
    ),
    const TeamModel(
      id: 'TEAM-005',
      name: 'John Mark',
      role: 'Architect',
      specialization: 'Architecture',
      email: 'john@structflow.com',
      phone: '+20 104 567 8901',
      projectCode: 'PRJ-003',
      projectName: 'Smart Village',
      status: 'On Leave',
      color: Colors.red,
      icon: Icons.architecture_rounded,
    ),
  ];

  // ================================================================
  // ALL MEMBERS
  // ================================================================

  List<TeamModel> get members {
    return List.unmodifiable(_members);
  }

  // ================================================================
  // COUNTS
  // ================================================================

  int get memberCount {
    return _members.length;
  }

  int get activeMemberCount {
    return _members
        .where(
          (member) => member.status == 'Active',
        )
        .length;
  }

  int get inactiveMemberCount {
    return _members
        .where(
          (member) => member.status != 'Active',
        )
        .length;
  }

  // ================================================================
  // LOAD
  // ================================================================

  Future<void> loadMembers() async {
    final preferences =
        await SharedPreferences.getInstance();

    final savedMembers =
        preferences.getString(_storageKey);

    if (savedMembers == null) {
      return;
    }

    try {
      final decoded =
          jsonDecode(savedMembers) as List<dynamic>;

      final restoredMembers = decoded
          .map(
            (member) => TeamModel.fromJson(
              Map<String, dynamic>.from(
                member as Map,
              ),
            ),
          )
          .toList();

      _members
        ..clear()
        ..addAll(restoredMembers);

      notifyListeners();
    } catch (_) {
      // Keep bundled sample members
      // if stored data is invalid.
    }
  }

  // ================================================================
  // SAVE
  // ================================================================

  Future<void> _saveMembers() async {
    final preferences =
        await SharedPreferences.getInstance();

    final encodedMembers = jsonEncode(
      _members
          .map(
            (member) => member.toJson(),
          )
          .toList(),
    );

    await preferences.setString(
      _storageKey,
      encodedMembers,
    );
  }

  // ================================================================
  // NEXT MEMBER ID
  // ================================================================

  String get nextMemberId {
    var highestNumber = 0;

    for (final member in _members) {
      final match = RegExp(
        r'^TEAM-(\d+)$',
      ).firstMatch(member.id);

      final number = int.tryParse(
        match?.group(1) ?? '',
      );

      if (number != null && number > highestNumber) {
        highestNumber = number;
      }
    }

    return 'TEAM-${(highestNumber + 1).toString().padLeft(3, '0')}';
  }

  // ================================================================
  // GET MEMBER
  // ================================================================

  TeamModel? getMemberById(String id) {
    try {
      return _members.firstWhere(
        (member) => member.id == id,
      );
    } catch (_) {
      return null;
    }
  }

  // ================================================================
  // ADD
  // ================================================================

  Future<void> addMember(TeamModel member) async {
    _members.add(member);

    await _saveMembers();

    notifyListeners();
  }

  // ================================================================
  // UPDATE
  // ================================================================

  Future<void> updateMember(
    TeamModel updatedMember,
  ) async {
    final index = _members.indexWhere(
      (member) => member.id == updatedMember.id,
    );

    if (index == -1) {
      return;
    }

    _members[index] = updatedMember;

    await _saveMembers();

    notifyListeners();
  }

  // ================================================================
  // DELETE
  // ================================================================

  Future<void> deleteMember(String id) async {
    final originalLength = _members.length;

    _members.removeWhere(
      (member) => member.id == id,
    );

    if (_members.length != originalLength) {
      await _saveMembers();
      notifyListeners();
    }
  }

  // ================================================================
  // BY PROJECT
  // ================================================================

  List<TeamModel> getMembersByProject(
    String projectCode,
  ) {
    return _members
        .where(
          (member) =>
              member.projectCode == projectCode,
        )
        .toList();
  }

  // ================================================================
  // BY STATUS
  // ================================================================

  List<TeamModel> getMembersByStatus(
    String status,
  ) {
    return _members
        .where(
          (member) => member.status == status,
        )
        .toList();
  }

  // ================================================================
  // BY SPECIALIZATION
  // ================================================================

  List<TeamModel> getMembersBySpecialization(
    String specialization,
  ) {
    return _members
        .where(
          (member) =>
              member.specialization == specialization,
        )
        .toList();
  }
}