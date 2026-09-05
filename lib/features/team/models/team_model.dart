import 'package:flutter/material.dart';

class TeamModel {
  final String id;
  final String name;
  final String email;
  final String phone;

  /// Job title / role of the team member.
  ///
  /// This is intentionally a String rather than an enum because
  /// StructFlow supports arbitrary engineering and management roles,
  /// for example:
  /// - Senior Civil Engineer
  /// - Project Manager
  /// - Electrical Engineer
  /// - Architect
  /// - Site Engineer
  /// - Quantity Surveyor
  /// - Safety Engineer
  /// - QA/QC Engineer
  final String role;

  final String specialization;
  final String projectName;
  final String projectCode;
  final String status;
  final String avatarUrl;

  /// Icon code point used for local persistence.
  final int iconCodePoint;

  /// Visual color of the member.
  ///
  /// Kept non-null so UI code can safely use withValues(),
  /// Icon color, etc.
  final Color color;

  /// Optional custom icon.
  final IconData icon;

  const TeamModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.specialization = '',
    this.projectName = '',
    this.projectCode = '',
    this.status = 'Active',
    this.avatarUrl = '',
    this.iconCodePoint = 0xe491,
    this.color = Colors.blue,
    this.icon = Icons.person_rounded,
  });

  factory TeamModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawRole = json['role'];

    final role = rawRole == null
        ? ''
        : rawRole.toString().trim();

    final rawColor = json['color'];

    Color parsedColor = Colors.blue;

    if (rawColor is int) {
      parsedColor = Color(rawColor);
    }

    final rawIconCodePoint =
        json['iconCodePoint'];

    final parsedIconCodePoint =
        rawIconCodePoint is int
            ? rawIconCodePoint
            : int.tryParse(
                  rawIconCodePoint?.toString() ?? '',
                ) ??
                0xe491;

    return TeamModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: role,
      specialization:
          json['specialization']?.toString() ?? '',
      projectName:
          json['projectName']?.toString() ?? '',
      projectCode:
          json['projectCode']?.toString() ?? '',
      status:
          json['status']?.toString() ?? 'Active',
      avatarUrl:
          json['avatarUrl']?.toString() ?? '',
      iconCodePoint: parsedIconCodePoint,
      color: parsedColor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'specialization': specialization,
      'projectName': projectName,
      'projectCode': projectCode,
      'status': status,
      'avatarUrl': avatarUrl,
      'iconCodePoint': iconCodePoint,
      'color': color.toARGB32(),
    };
  }

  TeamModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? specialization,
    String? projectName,
    String? projectCode,
    String? status,
    String? avatarUrl,
    int? iconCodePoint,
    Color? color,
    IconData? icon,
  }) {
    return TeamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      specialization:
          specialization ?? this.specialization,
      projectName:
          projectName ?? this.projectName,
      projectCode:
          projectCode ?? this.projectCode,
      status: status ?? this.status,
      avatarUrl:
          avatarUrl ?? this.avatarUrl,
      iconCodePoint:
          iconCodePoint ?? this.iconCodePoint,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }

  IconData get roleIcon {
    // ignore: non_const_argument_for_const_parameter
    return IconData(
      iconCodePoint,
      fontFamily: 'MaterialIcons',
    );
  }

  String getRoleLabel() {
    return role.trim().isEmpty
        ? 'Team Member'
        : role.trim();
  }

  Widget getRoleBadge() {
    final badgeColor = color;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(
          alpha: 0.1,
        ),
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor,
        ),
      ),
      child: Text(
        getRoleLabel(),
        style: TextStyle(
          color: badgeColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}