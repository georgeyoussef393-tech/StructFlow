class OrganizationModel {
  final String id;
  final String name;
  final String code;
  final String type;
  final String description;
  final bool isActive;

  const OrganizationModel({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    this.description = '',
    this.isActive = true,
  });

  OrganizationModel copyWith({
    String? id,
    String? name,
    String? code,
    String? type,
    String? description,
    bool? isActive,
  }) {
    return OrganizationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      type: type ?? this.type,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'type': type,
      'description': description,
      'isActive': isActive,
    };
  }

  factory OrganizationModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return OrganizationModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      type: json['type'] as String? ?? 'General',
      description: json['description'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}