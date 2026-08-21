class OrganizationMembershipModel {
  final String id;
  final String organizationId;
  final String userId;
  final String role;
  final String department;
  final bool isActive;

  const OrganizationMembershipModel({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.role,
    this.department = '',
    this.isActive = true,
  });

  OrganizationMembershipModel copyWith({
    String? id,
    String? organizationId,
    String? userId,
    String? role,
    String? department,
    bool? isActive,
  }) {
    return OrganizationMembershipModel(
      id: id ?? this.id,
      organizationId:
          organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      department:
          department ?? this.department,
      isActive:
          isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizationId': organizationId,
      'userId': userId,
      'role': role,
      'department': department,
      'isActive': isActive,
    };
  }

  factory OrganizationMembershipModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return OrganizationMembershipModel(
      id: json['id'] as String? ?? '',
      organizationId:
          json['organizationId'] as String? ?? '',
      userId:
          json['userId'] as String? ?? '',
      role:
          json['role'] as String? ?? '',
      department:
          json['department'] as String? ?? '',
      isActive:
          json['isActive'] as bool? ?? true,
    );
  }
}