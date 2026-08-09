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
}