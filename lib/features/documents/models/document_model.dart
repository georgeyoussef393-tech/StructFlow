import 'package:flutter/material.dart';

class DocumentModel {
  // ==============================================================
  // BASIC INFORMATION
  // ==============================================================

  final String id;
  final String documentNumber;
  final String title;

  final String projectCode;
  final String projectName;

  // ==============================================================
  // CLASSIFICATION
  // ==============================================================

  final String category;
  final String subCategory;
  final String documentType;
  final String discipline;

  // ==============================================================
  // REVISION / STATUS
  // ==============================================================

  final String revision;
  final String status;

  // ==============================================================
  // COMMUNICATION
  // ==============================================================

  final String from;
  final String to;
  final String cc;

  // ==============================================================
  // COMPATIBILITY
  // ==============================================================

  final String submittedBy;
  final String recipient;
  final DateTime date;

  // ==============================================================
  // CREATION
  // ==============================================================

  final String createdBy;
  final DateTime createdDate;

  final DateTime? submittedDate;
  final DateTime? dueDate;
  final DateTime? responseDate;

  // ==============================================================
  // PRIORITY / CONFIDENTIALITY
  // ==============================================================

  final String priority;
  final String confidentiality;

  // ==============================================================
  // CONTENT / FILES
  // ==============================================================

  final String description;
  final List<String> attachments;

  // ==============================================================
  // UI
  // ==============================================================

  final Color color;
  final IconData icon;

  // ==============================================================
  // CONSTRUCTOR
  // ==============================================================

  const DocumentModel({
    required this.id,
    this.documentNumber = '',
    required this.title,
    required this.projectCode,
    required this.projectName,

    // Classification
    this.category = 'General',
    this.subCategory = 'General',
    this.documentType = 'General',
    this.discipline = 'General',

    // Revision / status
    this.revision = 'Rev. 00',
    this.status = 'Draft',

    // Communication
    this.from = '',
    this.to = '',
    this.cc = '',

    // Compatibility
    this.submittedBy = '',
    this.recipient = '',
    required this.date,

    // Creation
    this.createdBy = '',
    required this.createdDate,
    this.submittedDate,
    this.dueDate,
    this.responseDate,

    // Priority
    this.priority = 'Normal',
    this.confidentiality = 'Internal',

    // Content
    this.description = '',
    this.attachments = const [],

    // UI
    required this.color,
    required this.icon,
  });

  // ==============================================================
  // COPY WITH
  // ==============================================================

  DocumentModel copyWith({
    String? id,
    String? documentNumber,
    String? title,
    String? projectCode,
    String? projectName,
    String? category,
    String? subCategory,
    String? documentType,
    String? discipline,
    String? revision,
    String? status,
    String? from,
    String? to,
    String? cc,
    String? submittedBy,
    String? recipient,
    DateTime? date,
    String? createdBy,
    DateTime? createdDate,
    DateTime? submittedDate,
    DateTime? dueDate,
    DateTime? responseDate,
    String? priority,
    String? confidentiality,
    String? description,
    List<String>? attachments,
    Color? color,
    IconData? icon,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      documentNumber:
          documentNumber ?? this.documentNumber,
      title: title ?? this.title,
      projectCode:
          projectCode ?? this.projectCode,
      projectName:
          projectName ?? this.projectName,
      category:
          category ?? this.category,
      subCategory:
          subCategory ?? this.subCategory,
      documentType:
          documentType ?? this.documentType,
      discipline:
          discipline ?? this.discipline,
      revision:
          revision ?? this.revision,
      status:
          status ?? this.status,
      from:
          from ?? this.from,
      to:
          to ?? this.to,
      cc:
          cc ?? this.cc,
      submittedBy:
          submittedBy ?? this.submittedBy,
      recipient:
          recipient ?? this.recipient,
      date:
          date ?? this.date,
      createdBy:
          createdBy ?? this.createdBy,
      createdDate:
          createdDate ?? this.createdDate,
      submittedDate:
          submittedDate ?? this.submittedDate,
      dueDate:
          dueDate ?? this.dueDate,
      responseDate:
          responseDate ?? this.responseDate,
      priority:
          priority ?? this.priority,
      confidentiality:
          confidentiality ?? this.confidentiality,
      description:
          description ?? this.description,
      attachments:
          attachments ?? this.attachments,
      color:
          color ?? this.color,
      icon:
          icon ?? this.icon,
    );
  }

  // ==============================================================
  // TO JSON
  // ==============================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentNumber': documentNumber,
      'title': title,
      'projectCode': projectCode,
      'projectName': projectName,

      // Classification
      'category': category,
      'subCategory': subCategory,
      'documentType': documentType,
      'discipline': discipline,

      // Revision / status
      'revision': revision,
      'status': status,

      // Communication
      'from': from,
      'to': to,
      'cc': cc,

      // Compatibility
      'submittedBy': submittedBy,
      'recipient': recipient,
      'date': date.toIso8601String(),

      // Creation
      'createdBy': createdBy,
      'createdDate':
          createdDate.toIso8601String(),
      'submittedDate':
          submittedDate?.toIso8601String(),
      'dueDate':
          dueDate?.toIso8601String(),
      'responseDate':
          responseDate?.toIso8601String(),

      // Priority
      'priority': priority,
      'confidentiality':
          confidentiality,

      // Content
      'description': description,
      'attachments': attachments,

      // UI
      'color': color.toARGB32(),
      'iconCodePoint': icon.codePoint,
    };
  }

  // ==============================================================
  // FROM JSON
  // ==============================================================

  factory DocumentModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final DateTime parsedDate =
        _parseDate(json['date']) ??
        _parseDate(json['createdDate']) ??
        DateTime.now();

    final DateTime parsedCreatedDate =
        _parseDate(json['createdDate']) ??
        parsedDate;

    final int colorValue =
        (json['color'] as num?)?.toInt() ??
        Colors.blue.toARGB32();

    final int iconCodePoint =
        (json['iconCodePoint'] as num?)?.toInt() ??
        Icons.description.codePoint;

    return DocumentModel(
      // ------------------------------------------------------------
      // Basic
      // ------------------------------------------------------------

      id:
          json['id'] as String? ?? '',

      documentNumber:
          json['documentNumber'] as String? ?? '',

      title:
          json['title'] as String? ?? '',

      projectCode:
          json['projectCode'] as String? ?? '',

      projectName:
          json['projectName'] as String? ?? '',

      // ------------------------------------------------------------
      // Classification
      // ------------------------------------------------------------

      category:
          json['category'] as String? ??
          'General',

      subCategory:
          json['subCategory'] as String? ??
          'General',

      documentType:
          json['documentType'] as String? ??
          'General',

      discipline:
          json['discipline'] as String? ??
          'General',

      // ------------------------------------------------------------
      // Revision / status
      // ------------------------------------------------------------

      revision:
          json['revision'] as String? ??
          'Rev. 00',

      status:
          json['status'] as String? ??
          'Draft',

      // ------------------------------------------------------------
      // Communication
      // ------------------------------------------------------------

      from:
          json['from'] as String? ?? '',

      to:
          json['to'] as String? ?? '',

      cc:
          json['cc'] as String? ?? '',

      // ------------------------------------------------------------
      // Compatibility
      // ------------------------------------------------------------

      submittedBy:
          json['submittedBy'] as String? ??
          json['from'] as String? ??
          '',

      recipient:
          json['recipient'] as String? ??
          json['to'] as String? ??
          '',

      date: parsedDate,

      // ------------------------------------------------------------
      // Creation
      // ------------------------------------------------------------

      createdBy:
          json['createdBy'] as String? ??
          json['submittedBy'] as String? ??
          json['from'] as String? ??
          '',

      createdDate:
          parsedCreatedDate,

      submittedDate:
          _parseDate(
        json['submittedDate'],
      ),

      dueDate:
          _parseDate(
        json['dueDate'],
      ),

      responseDate:
          _parseDate(
        json['responseDate'],
      ),

      // ------------------------------------------------------------
      // Priority
      // ------------------------------------------------------------

      priority:
          json['priority'] as String? ??
          'Normal',

      confidentiality:
          json['confidentiality'] as String? ??
          'Internal',

      // ------------------------------------------------------------
      // Content
      // ------------------------------------------------------------

      description:
          json['description'] as String? ??
          '',

      attachments:
          _parseAttachments(
        json['attachments'],
      ),

      // ------------------------------------------------------------
      // UI
      // ------------------------------------------------------------

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
      codePoint,
      fontFamily: 'MaterialIcons',
    );
  }

  // ==============================================================
  // DATE PARSER
  // ==============================================================

  static DateTime? _parseDate(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(
        value,
      );
    }

    return null;
  }

  // ==============================================================
  // ATTACHMENTS PARSER
  // ==============================================================

  static List<String> _parseAttachments(
    dynamic value,
  ) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<String>()
        .toList();
  }
}