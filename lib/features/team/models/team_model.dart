import 'package:flutter/material.dart';

class TeamModel {
  final String id;
  final String name;
  final String role;
  final String specialization;
  final String email;
  final String phone;
  final String projectCode;
  final String projectName;
  final String status;
  final Color color;
  final IconData icon;

  const TeamModel({
    required this.id,
    required this.name,
    required this.role,
    required this.specialization,
    required this.email,
    required this.phone,
    required this.projectCode,
    required this.projectName,
    required this.status,
    required this.color,
    required this.icon,
  });

  TeamModel copyWith({
    String? id,
    String? name,
    String? role,
    String? specialization,
    String? email,
    String? phone,
    String? projectCode,
    String? projectName,
    String? status,
    Color? color,
    IconData? icon,
  }) {
    return TeamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      specialization: specialization ?? this.specialization,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      projectCode: projectCode ?? this.projectCode,
      projectName: projectName ?? this.projectName,
      status: status ?? this.status,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'specialization': specialization,
      'email': email,
      'phone': phone,
      'projectCode': projectCode,
      'projectName': projectName,
      'status': status,
      'color': color.toARGB32(),
      'iconCodePoint': icon.codePoint,
    };
  }

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    final int iconCodePoint =
        (json['iconCodePoint'] as num?)?.toInt() ??
        Icons.person.codePoint;

    final int colorValue =
        (json['color'] as num?)?.toInt() ??
        Colors.blue.toARGB32();

    return TeamModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      specialization: json['specialization'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      projectCode: json['projectCode'] as String? ?? '',
      projectName: json['projectName'] as String? ?? '',
      status: json['status'] as String? ?? 'Active',
      color: Color(colorValue),
      icon: _iconFromCodePoint(iconCodePoint),
    );
  }

  static IconData _iconFromCodePoint(int codePoint) {
    return IconData(
      codePoint,
      fontFamily: 'MaterialIcons',
      matchTextDirection: false,
    );
  }
}