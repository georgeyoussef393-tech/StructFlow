import 'package:flutter/foundation.dart';

import 'package:structflow/features/models/organization_model.dart';

class OrganizationRepository extends ChangeNotifier {
  OrganizationRepository._();

  static final OrganizationRepository instance =
      OrganizationRepository._();

  final List<OrganizationModel> _organizations = [
    OrganizationModel(
      id: 'ORG-001',
      name: 'StructFlow Development',
      code: 'SF-DEV',
      type: 'Software Company',
    ),
    OrganizationModel(
      id: 'ORG-002',
      name: 'Abu Soma Development',
      code: 'ASD',
      type: 'Owner',
    ),
    OrganizationModel(
      id: 'ORG-003',
      name: 'StructFlow Engineering',
      code: 'SF-ENG',
      type: 'Consultant',
    ),
    OrganizationModel(
      id: 'ORG-004',
      name: 'StructFlow Contracting',
      code: 'SF-CON',
      type: 'Contractor',
    ),
  ];

  List<OrganizationModel> get organizations =>
      List.unmodifiable(_organizations);

  int get organizationCount => _organizations.length;

  OrganizationModel? getById(String id) {
    for (final organization in _organizations) {
      if (organization.id == id) {
        return organization;
      }
    }

    return null;
  }

  OrganizationModel? getByCode(String code) {
    for (final organization in _organizations) {
      if (organization.code == code) {
        return organization;
      }
    }

    return null;
  }

  List<OrganizationModel> search(String query) {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return organizations;
    }

    return _organizations.where((organization) {
      return organization.id
              .toLowerCase()
              .contains(normalizedQuery) ||
          organization.name
              .toLowerCase()
              .contains(normalizedQuery) ||
          organization.code
              .toLowerCase()
              .contains(normalizedQuery) ||
          organization.type
              .toLowerCase()
              .contains(normalizedQuery);
    }).toList();
  }

  void addOrganization(
    OrganizationModel organization,
  ) {
    final existingIndex = _organizations.indexWhere(
      (item) => item.id == organization.id,
    );

    if (existingIndex >= 0) {
      _organizations[existingIndex] = organization;
    } else {
      _organizations.add(organization);
    }

    notifyListeners();
  }

  bool updateOrganization(
    OrganizationModel organization,
  ) {
    final index = _organizations.indexWhere(
      (item) => item.id == organization.id,
    );

    if (index == -1) {
      return false;
    }

    _organizations[index] = organization;
    notifyListeners();

    return true;
  }

  bool deleteOrganization(String id) {
    final index = _organizations.indexWhere(
      (organization) => organization.id == id,
    );

    if (index == -1) {
      return false;
    }

    _organizations.removeAt(index);
    notifyListeners();

    return true;
  }

  bool exists(String id) {
    return _organizations.any(
      (organization) => organization.id == id,
    );
  }

  bool codeExists(
    String code, {
    String? excludingId,
  }) {
    return _organizations.any(
      (organization) =>
          organization.code.toLowerCase() ==
              code.toLowerCase() &&
          organization.id != excludingId,
    );
  }

  void clear() {
    _organizations.clear();
    notifyListeners();
  }
}