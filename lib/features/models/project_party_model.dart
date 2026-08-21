class ProjectPartyModel {
  final String id;
  final String projectId;
  final String organizationId;
  final String partyType;
  final String role;
  final bool isActive;

  const ProjectPartyModel({
    required this.id,
    required this.projectId,
    required this.organizationId,
    required this.partyType,
    required this.role,
    this.isActive = true,
  });

  ProjectPartyModel copyWith({
    String? id,
    String? projectId,
    String? organizationId,
    String? partyType,
    String? role,
    bool? isActive,
  }) {
    return ProjectPartyModel(
      id: id ?? this.id,
      projectId:
          projectId ?? this.projectId,
      organizationId:
          organizationId ?? this.organizationId,
      partyType:
          partyType ?? this.partyType,
      role:
          role ?? this.role,
      isActive:
          isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'organizationId': organizationId,
      'partyType': partyType,
      'role': role,
      'isActive': isActive,
    };
  }

  factory ProjectPartyModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProjectPartyModel(
      id: json['id'] as String? ?? '',
      projectId:
          json['projectId'] as String? ?? '',
      organizationId:
          json['organizationId'] as String? ?? '',
      partyType:
          json['partyType'] as String? ?? 'Other',
      role:
          json['role'] as String? ?? '',
      isActive:
          json['isActive'] as bool? ?? true,
    );
  }
}