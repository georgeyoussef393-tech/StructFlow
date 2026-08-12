import 'package:flutter/material.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;

  final String projectCode;
  final String projectName;

  final String assignee;

  final String status;
  final String priority;

  final DateTime dueDate;

  final double progress;

  final Color color;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.projectCode,
    required this.projectName,
    required this.assignee,
    required this.status,
    required this.priority,
    required this.dueDate,
    required this.progress,
    required this.color,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? projectCode,
    String? projectName,
    String? assignee,
    String? status,
    String? priority,
    DateTime? dueDate,
    double? progress,
    Color? color,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      projectCode: projectCode ?? this.projectCode,
      projectName: projectName ?? this.projectName,
      assignee: assignee ?? this.assignee,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      progress: progress ?? this.progress,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'projectCode': projectCode,
      'projectName': projectName,
      'assignee': assignee,
      'status': status,
      'priority': priority,
      'dueDate': dueDate.toIso8601String(),
      'progress': progress,
      'color': color.value,
    };
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      projectCode: json['projectCode'] as String,
      projectName: json['projectName'] as String,
      assignee: json['assignee'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      progress: (json['progress'] as num).toDouble(),
      color: Color((json['color'] as num).toInt()),
    );
  }
}
