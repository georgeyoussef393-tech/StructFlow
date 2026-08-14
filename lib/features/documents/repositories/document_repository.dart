import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:structflow/features/documents/models/document_model.dart';

class DocumentRepository extends ChangeNotifier {
  static const _storageKey = 'structflow_documents';

  DocumentRepository._internal();

  static final DocumentRepository instance =
      DocumentRepository._internal();

  final List<DocumentModel> _documents = [
    DocumentModel(
      id: 'DOC-001',
      documentNumber: 'IR-CIV-001',
      title: 'Structural Drawings',
      description:
          'Latest structural drawings submitted for consultant review.',
      projectCode: 'PRJ-001',
      projectName: 'New Capital Tower',
      category: 'Technical',
      subCategory: 'Drawings',
      documentType: 'Drawing',
      discipline: 'Civil',
      revision: 'Rev. 03',
      status: 'Under Review',
      from: 'Ahmed Hassan',
      to: 'Consultant',
      submittedBy: 'Ahmed Hassan',
      recipient: 'Consultant',
      date: DateTime(2026, 8, 14),
      createdBy: 'Ahmed Hassan',
      createdDate: DateTime(2026, 8, 13),
      priority: 'High',
      confidentiality: 'Internal',
      color: Colors.blue,
      icon: Icons.architecture_rounded,
    ),

    DocumentModel(
      id: 'DOC-002',
      documentNumber: 'SUB-COM-002',
      title: 'Updated BOQ',
      description:
          'Updated bill of quantities submitted for approval.',
      projectCode: 'PRJ-002',
      projectName: 'Cairo Business Park',
      category: 'Commercial',
      subCategory: 'Cost Control',
      documentType: 'BOQ',
      discipline: 'Commercial',
      revision: 'Rev. 02',
      status: 'Approved',
      from: 'Michael George',
      to: 'Client',
      submittedBy: 'Michael George',
      recipient: 'Client',
      date: DateTime(2026, 8, 12),
      createdBy: 'Michael George',
      createdDate: DateTime(2026, 8, 11),
      priority: 'Normal',
      confidentiality: 'Internal',
      color: Colors.green,
      icon: Icons.request_quote_rounded,
    ),

    DocumentModel(
      id: 'DOC-003',
      documentNumber: 'SD-ELE-003',
      title: 'Electrical Coordination',
      description:
          'Electrical coordination drawings for review.',
      projectCode: 'PRJ-004',
      projectName: 'Alex Mall',
      category: 'Technical',
      subCategory: 'Coordination',
      documentType: 'Drawing',
      discipline: 'Electrical',
      revision: 'Rev. 01',
      status: 'Submitted',
      from: 'Daniel Sameh',
      to: 'Consultant',
      submittedBy: 'Daniel Sameh',
      recipient: 'Consultant',
      date: DateTime(2026, 8, 10),
      createdBy: 'Daniel Sameh',
      createdDate: DateTime(2026, 8, 9),
      priority: 'Normal',
      confidentiality: 'Internal',
      color: Colors.orange,
      icon: Icons.electrical_services_rounded,
    ),

    DocumentModel(
      id: 'DOC-004',
      documentNumber: 'RPT-CON-004',
      title: 'Site Inspection Report',
      description:
          'Site inspection report including observations and photographs.',
      projectCode: 'PRJ-006',
      projectName: 'Tuban Villas',
      category: 'Reports',
      subCategory: 'Site Inspection',
      documentType: 'Report',
      discipline: 'Construction',
      revision: 'Rev. 00',
      status: 'Approved',
      from: 'George Youssef',
      to: 'Project Manager',
      submittedBy: 'George Youssef',
      recipient: 'Project Manager',
      date: DateTime(2026, 8, 8),
      createdBy: 'George Youssef',
      createdDate: DateTime(2026, 8, 7),
      priority: 'Normal',
      confidentiality: 'Internal',
      color: Colors.purple,
      icon: Icons.assignment_rounded,
    ),

    DocumentModel(
      id: 'DOC-005',
      documentNumber: 'RFI-TEC-005',
      title: 'RFI Response',
      description:
          'Consultant response to the outstanding request for information.',
      projectCode: 'PRJ-003',
      projectName: 'Smart Village',
      category: 'Technical',
      subCategory: 'RFI',
      documentType: 'RFI',
      discipline: 'Technical',
      revision: 'Rev. 01',
      status: 'Pending',
      from: 'John Mark',
      to: 'Consultant',
      submittedBy: 'John Mark',
      recipient: 'Consultant',
      date: DateTime(2026, 8, 13),
      createdBy: 'John Mark',
      createdDate: DateTime(2026, 8, 12),
      priority: 'High',
      confidentiality: 'Internal',
      color: Colors.red,
      icon: Icons.question_answer_rounded,
    ),
  ];

  // ==============================================================
  // GETTERS
  // ==============================================================

  List<DocumentModel> get documents {
    return List.unmodifiable(_documents);
  }

  int get documentCount {
    return _documents.length;
  }

  int get pendingCount {
    return _documents
        .where(
          (document) =>
              document.status == 'Pending',
        )
        .length;
  }

  int get reviewCount {
    return _documents
        .where(
          (document) =>
              document.status == 'Under Review',
        )
        .length;
  }

  int get approvedCount {
    return _documents
        .where(
          (document) =>
              document.status == 'Approved',
        )
        .length;
  }

  // ==============================================================
  // LOAD
  // ==============================================================

  Future<void> loadDocuments() async {
    final preferences =
        await SharedPreferences.getInstance();

    final savedDocuments =
        preferences.getString(_storageKey);

    if (savedDocuments == null) {
      return;
    }

    try {
      final decoded =
          jsonDecode(savedDocuments) as List<dynamic>;

      final restoredDocuments = decoded
          .map(
            (document) => DocumentModel.fromJson(
              Map<String, dynamic>.from(
                document as Map,
              ),
            ),
          )
          .toList();

      _documents
        ..clear()
        ..addAll(restoredDocuments);

      notifyListeners();
    } catch (_) {
      // Keep bundled sample documents.
    }
  }

  // ==============================================================
  // SAVE
  // ==============================================================

  Future<void> _saveDocuments() async {
    final preferences =
        await SharedPreferences.getInstance();

    final encodedDocuments = jsonEncode(
      _documents
          .map(
            (document) => document.toJson(),
          )
          .toList(),
    );

    await preferences.setString(
      _storageKey,
      encodedDocuments,
    );
  }

  // ==============================================================
  // NEXT DOCUMENT ID
  // ==============================================================

  String get nextDocumentId {
    var highestNumber = 0;

    for (final document in _documents) {
      final match = RegExp(
        r'^DOC-(\d+)$',
      ).firstMatch(document.id);

      final number = int.tryParse(
        match?.group(1) ?? '',
      );

      if (number != null &&
          number > highestNumber) {
        highestNumber = number;
      }
    }

    return 'DOC-${(highestNumber + 1).toString().padLeft(3, '0')}';
  }

  // ==============================================================
  // FIND DOCUMENT
  // ==============================================================

  DocumentModel? getDocumentById(
    String id,
  ) {
    try {
      return _documents.firstWhere(
        (document) => document.id == id,
      );
    } catch (_) {
      return null;
    }
  }

  // ==============================================================
  // ADD
  // ==============================================================

  void addDocument(
    DocumentModel document,
  ) {
    _documents.add(document);

    _saveDocuments();
    notifyListeners();
  }

  // ==============================================================
  // UPDATE
  // ==============================================================

  void updateDocument(
    DocumentModel updatedDocument,
  ) {
    final index = _documents.indexWhere(
      (document) =>
          document.id == updatedDocument.id,
    );

    if (index == -1) {
      return;
    }

    _documents[index] = updatedDocument;

    _saveDocuments();
    notifyListeners();
  }

  // ==============================================================
  // DELETE
  // ==============================================================

  void deleteDocument(
    String id,
  ) {
    _documents.removeWhere(
      (document) => document.id == id,
    );

    _saveDocuments();
    notifyListeners();
  }

  // ==============================================================
  // FILTER BY PROJECT
  // ==============================================================

  List<DocumentModel> getDocumentsByProject(
    String projectCode,
  ) {
    return _documents
        .where(
          (document) =>
              document.projectCode == projectCode,
        )
        .toList();
  }

  // ==============================================================
  // FILTER BY STATUS
  // ==============================================================

  List<DocumentModel> getDocumentsByStatus(
    String status,
  ) {
    return _documents
        .where(
          (document) =>
              document.status == status,
        )
        .toList();
  }

  // ==============================================================
  // FILTER BY TYPE
  // ==============================================================

  List<DocumentModel> getDocumentsByType(
    String type,
  ) {
    return _documents
        .where(
          (document) =>
              document.documentType == type,
        )
        .toList();
  }
}