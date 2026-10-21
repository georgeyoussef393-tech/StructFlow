class BimModelRecord {
  const BimModelRecord({
    required this.id,
    required this.projectCode,
    required this.name,
    required this.discipline,
    required this.version,
    required this.status,
    required this.updatedAt,
  });

  final String id;
  final String projectCode;
  final String name;
  final String discipline;
  final String version;
  final String status;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'projectCode': projectCode,
    'name': name,
    'discipline': discipline,
    'version': version,
    'status': status,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory BimModelRecord.fromJson(Map<String, dynamic> json) => BimModelRecord(
    id: json['id'] as String,
    projectCode: json['projectCode'] as String,
    name: json['name'] as String,
    discipline: json['discipline'] as String,
    version: json['version'] as String,
    status: json['status'] as String,
    updatedAt: DateTime.parse(json['updatedAt'] as String),
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

  BimIssue copyWith({String? status}) => BimIssue(
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
  );
}
