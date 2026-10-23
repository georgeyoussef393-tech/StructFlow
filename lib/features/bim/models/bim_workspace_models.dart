class BimModelRecord {
  const BimModelRecord({
    required this.id,
    required this.projectCode,
    required this.name,
    required this.discipline,
    required this.version,
    required this.status,
    required this.updatedAt,
    this.recordVersion = 1,
  });

  final String id;
  final String projectCode;
  final String name;
  final String discipline;
  final String version;
  final String status;
  final DateTime updatedAt;
  final int recordVersion;

  BimModelRecord copyWith({String? status, int? recordVersion}) =>
      BimModelRecord(
        id: id,
        projectCode: projectCode,
        name: name,
        discipline: discipline,
        version: version,
        status: status ?? this.status,
        updatedAt: updatedAt,
        recordVersion: recordVersion ?? this.recordVersion,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'projectCode': projectCode,
    'name': name,
    'discipline': discipline,
    'version': version,
    'status': status,
    'updatedAt': updatedAt.toIso8601String(),
    'recordVersion': recordVersion,
  };

  factory BimModelRecord.fromJson(Map<String, dynamic> json) => BimModelRecord(
    id: json['id'] as String,
    projectCode: json['projectCode'] as String,
    name: json['name'] as String,
    discipline: json['discipline'] as String,
    version: json['version'] as String,
    status: json['status'] as String,
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    recordVersion: json['recordVersion'] as int? ?? 1,
  );
}

class BimIssue {
  const BimIssue({
    required this.id,
    required this.projectCode,
    required this.title,
    required this.description,
    required this.discipline,
    required this.location,
    required this.severity,
    required this.status,
    required this.assignedTo,
    required this.dueDate,
    this.bcfGuid,
    this.version = 1,
  });

  final String id;
  final String projectCode;
  final String title;
  final String description;
  final String discipline;
  final String location;
  final String severity;
  final String status;
  final String assignedTo;
  final DateTime dueDate;
  final String? bcfGuid;
  final int version;

  BimIssue copyWith({String? status, int? version}) => BimIssue(
    id: id,
    projectCode: projectCode,
    title: title,
    description: description,
    discipline: discipline,
    location: location,
    severity: severity,
    status: status ?? this.status,
    assignedTo: assignedTo,
    dueDate: dueDate,
    bcfGuid: bcfGuid,
    version: version ?? this.version,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'projectCode': projectCode,
    'title': title,
    'description': description,
    'discipline': discipline,
    'location': location,
    'severity': severity,
    'status': status,
    'assignedTo': assignedTo,
    'dueDate': dueDate.toIso8601String(),
    'bcfGuid': bcfGuid,
    'version': version,
  };

  factory BimIssue.fromJson(Map<String, dynamic> json) => BimIssue(
    id: json['id'] as String,
    projectCode: json['projectCode'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    discipline: json['discipline'] as String,
    location: json['location'] as String,
    severity: json['severity'] as String,
    status: json['status'] as String,
    assignedTo: json['assignedTo'] as String,
    dueDate: DateTime.parse(json['dueDate'] as String),
    bcfGuid: json['bcfGuid'] as String?,
    version: json['version'] as int? ?? 1,
  );
}

class BimIssueComment {
  const BimIssueComment({
    required this.id,
    required this.issueId,
    required this.body,
    required this.authorName,
    required this.createdAt,
    this.bcfGuid,
  });

  final String id;
  final String issueId;
  final String body;
  final String authorName;
  final DateTime createdAt;
  final String? bcfGuid;

  Map<String, dynamic> toJson() => {
    'id': id,
    'issueId': issueId,
    'body': body,
    'authorName': authorName,
    'createdAt': createdAt.toIso8601String(),
    'bcfGuid': bcfGuid,
  };

  factory BimIssueComment.fromJson(Map<String, dynamic> json) =>
      BimIssueComment(
        id: json['id'] as String,
        issueId: json['issueId'] as String,
        body: json['body'] as String,
        authorName: json['authorName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        bcfGuid: json['bcfGuid'] as String?,
      );
}
