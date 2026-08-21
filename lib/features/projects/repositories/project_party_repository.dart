import 'package:flutter/foundation.dart';

import 'package:structflow/features/models/project_party_model.dart';

class ProjectPartyRepository extends ChangeNotifier {
  ProjectPartyRepository._();

  static final ProjectPartyRepository instance =
      ProjectPartyRepository._();

  final List<ProjectPartyModel> _parties = [
    ProjectPartyModel(
      id: 'PARTY-001',
      projectId: 'PRJ-001',
      organizationId: 'ORG-002',
      partyType: 'Owner',
      role: 'Project Owner',
    ),
    ProjectPartyModel(
      id: 'PARTY-002',
      projectId: 'PRJ-001',
      organizationId: 'ORG-003',
      partyType: 'Consultant',
      role: 'Lead Consultant',
    ),
    ProjectPartyModel(
      id: 'PARTY-003',
      projectId: 'PRJ-001',
      organizationId: 'ORG-004',
      partyType: 'Contractor',
      role: 'Main Contractor',
    ),
    ProjectPartyModel(
      id: 'PARTY-004',
      projectId: 'PRJ-002',
      organizationId: 'ORG-002',
      partyType: 'Owner',
      role: 'Project Owner',
    ),
    ProjectPartyModel(
      id: 'PARTY-005',
      projectId: 'PRJ-002',
      organizationId: 'ORG-003',
      partyType: 'Consultant',
      role: 'Lead Consultant',
    ),
  ];

  // ==============================================================
  // GETTERS
  // ==============================================================

  List<ProjectPartyModel> get parties =>
      List.unmodifiable(_parties);

  int get partyCount => _parties.length;

  // ==============================================================
  // GET BY ID
  // ==============================================================

  ProjectPartyModel? getById(String id) {
    for (final party in _parties) {
      if (party.id == id) {
        return party;
      }
    }

    return null;
  }

  // ==============================================================
  // GET BY PROJECT
  // ==============================================================

  List<ProjectPartyModel> getByProject(
    String projectId,
  ) {
    return _parties
        .where(
          (party) => party.projectId == projectId,
        )
        .toList();
  }

  // ==============================================================
  // GET BY ORGANIZATION
  // ==============================================================

  List<ProjectPartyModel> getByOrganization(
    String organizationId,
  ) {
    return _parties
        .where(
          (party) =>
              party.organizationId == organizationId,
        )
        .toList();
  }

  // ==============================================================
  // GET BY PARTY TYPE
  // ==============================================================

  List<ProjectPartyModel> getByPartyType(
    String partyType,
  ) {
    return _parties
        .where(
          (party) => party.partyType == partyType,
        )
        .toList();
  }

  // ==============================================================
  // GET PROJECT PARTY
  // ==============================================================

  ProjectPartyModel? getProjectParty(
    String projectId,
    String partyType,
  ) {
    for (final party in _parties) {
      if (party.projectId == projectId &&
          party.partyType == partyType) {
        return party;
      }
    }

    return null;
  }

  // ==============================================================
  // CHECK PARTY TYPE
  // ==============================================================

  bool hasPartyType(
    String projectId,
    String partyType,
  ) {
    return _parties.any(
      (party) =>
          party.projectId == projectId &&
          party.partyType == partyType,
    );
  }

  // ==============================================================
  // ADD
  // ==============================================================

  void addParty(
    ProjectPartyModel party,
  ) {
    final existingIndex = _parties.indexWhere(
      (item) => item.id == party.id,
    );

    if (existingIndex >= 0) {
      _parties[existingIndex] = party;
    } else {
      _parties.add(party);
    }

    notifyListeners();
  }

  // ==============================================================
  // UPDATE
  // ==============================================================

  bool updateParty(
    ProjectPartyModel party,
  ) {
    final index = _parties.indexWhere(
      (item) => item.id == party.id,
    );

    if (index == -1) {
      return false;
    }

    _parties[index] = party;

    notifyListeners();

    return true;
  }

  // ==============================================================
  // DELETE
  // ==============================================================

  bool deleteParty(String id) {
    final index = _parties.indexWhere(
      (party) => party.id == id,
    );

    if (index == -1) {
      return false;
    }

    _parties.removeAt(index);

    notifyListeners();

    return true;
  }

  // ==============================================================
  // EXISTS
  // ==============================================================

  bool exists(String id) {
    return _parties.any(
      (party) => party.id == id,
    );
  }

  // ==============================================================
  // ORGANIZATION ASSIGNED TO PROJECT
  // ==============================================================

  bool organizationIsAssignedToProject(
    String projectId,
    String organizationId,
  ) {
    return _parties.any(
      (party) =>
          party.projectId == projectId &&
          party.organizationId == organizationId,
    );
  }

  // ==============================================================
  // REMOVE PROJECT PARTIES
  // ==============================================================

  void removeProjectParties(
    String projectId,
  ) {
    _parties.removeWhere(
      (party) => party.projectId == projectId,
    );

    notifyListeners();
  }

  // ==============================================================
  // REMOVE ORGANIZATION FROM PROJECTS
  // ==============================================================

  void removeOrganizationFromProjects(
    String organizationId,
  ) {
    _parties.removeWhere(
      (party) =>
          party.organizationId == organizationId,
    );

    notifyListeners();
  }

  // ==============================================================
  // CLEAR
  // ==============================================================

  void clear() {
    _parties.clear();

    notifyListeners();
  }
}