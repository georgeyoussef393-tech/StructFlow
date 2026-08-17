import 'package:flutter/material.dart';

class ProjectModel {
  final String name;
  final String code;
  final String client;
  final String location;
  final String status;
  final double progress;
  final String budget;
  final int team;
  final Color color;
  final IconData icon;

  const ProjectModel({
    required this.name,
    required this.code,
    required this.client,
    required this.location,
    required this.status,
    required this.progress,
    required this.budget,
    required this.team,
    required this.color,
    required this.icon,
  });

  ProjectModel copyWith({
    String? name,
    String? code,
    String? client,
    String? location,
    String? status,
    double? progress,
    String? budget,
    int? team,
    Color? color,
    IconData? icon,
  }) {
    return ProjectModel(
      name: name ?? this.name,
      code: code ?? this.code,
      client: client ?? this.client,
      location: location ?? this.location,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      budget: budget ?? this.budget,
      team: team ?? this.team,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }

  // ==============================================================
  // TO JSON
  // ==============================================================

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'client': client,
      'location': location,
      'status': status,
      'progress': progress,
      'budget': budget,
      'team': team,
      'color': color.toARGB32(),
      'iconCodePoint': icon.codePoint,
    };
  }

  // ==============================================================
  // FROM JSON
  // ==============================================================

  factory ProjectModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final int iconCodePoint =
        (json['iconCodePoint'] as num?)?.toInt() ??
        Icons.apartment.codePoint;

    final int colorValue =
        (json['color'] as num?)?.toInt() ??
        Colors.blue.toARGB32();

    return ProjectModel(
      name:
          json['name'] as String? ?? '',
      code:
          json['code'] as String? ?? '',
      client:
          json['client'] as String? ?? '',
      location:
          json['location'] as String? ?? '',
      status:
          json['status'] as String? ?? 'Planning',
      progress:
          (json['progress'] as num?)?.toDouble() ??
          0.0,
      budget:
          json['budget'] as String? ?? '',
      team:
          (json['team'] as num?)?.toInt() ?? 0,
      color:
          Color(colorValue),
      icon:
          _iconFromCodePoint(
        iconCodePoint,
      ),
    );
  }

  // ==============================================================
  // ICON PARSER
  // ==============================================================

  static IconData _iconFromCodePoint(
    int codePoint,
  ) {
    return IconData(
      // Icon code point is loaded dynamically from JSON.
      // ignore: non_const_argument_for_const_parameter
      codePoint,
      fontFamily: 'MaterialIcons',
    );
  }
}