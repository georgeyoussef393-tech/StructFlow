class AuthUserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String organization;
  final String status;
  final bool systemOwner;

  const AuthUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.organization,
    this.status = 'Approved',
    this.systemOwner = false,
  });

  bool get isApproved => status == 'Approved';
  bool get isPending => status == 'Pending';
  bool get isRejected => status == 'Rejected';
  bool get isOwner => role == 'Owner' || role == 'Super Admin';
  bool get isSystemOwner => systemOwner;

  AuthUserModel copyWith({
    String? name,
    String? email,
    String? role,
    String? organization,
    String? status,
    bool? systemOwner,
  }) {
    return AuthUserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      organization: organization ?? this.organization,
      status: status ?? this.status,
      systemOwner: systemOwner ?? this.systemOwner,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'organization': organization,
        'status': status,
        'systemOwner': systemOwner,
      };

  factory AuthUserModel.fromJson(Map<String, dynamic> json) => AuthUserModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        email: (json['email'] as String? ?? '').toLowerCase(),
        role: json['role'] as String? ?? 'Employee',
        organization: json['organization'] as String? ?? '',
        status: json['status'] as String? ?? 'Approved',
        systemOwner: json['systemOwner'] as bool? ?? false,
      );
}
