import 'package:flutter/material.dart';

class CalendarEventModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String type;
  final String projectCode;
  final String projectName;
  final String? taskId;
  final Color color;

  const CalendarEventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    required this.projectCode,
    required this.projectName,
    this.taskId,
    required this.color,
  });

  CalendarEventModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? type,
    String? projectCode,
    String? projectName,
    String? taskId,
    Color? color,
  }) {
    return CalendarEventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      type: type ?? this.type,
      projectCode: projectCode ?? this.projectCode,
      projectName: projectName ?? this.projectName,
      taskId: taskId ?? this.taskId,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'type': type,
      'projectCode': projectCode,
      'projectName': projectName,
      'taskId': taskId,
      'color': color.toARGB32(),
    };
  }

  factory CalendarEventModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return CalendarEventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      date: DateTime.parse(
        json['date'] as String,
      ),
      type: json['type'] as String,
      projectCode: json['projectCode'] as String,
      projectName: json['projectName'] as String,
      taskId: json['taskId'] as String?,
      color: Color(
        (json['color'] as num).toInt(),
      ),
    );
  }
}