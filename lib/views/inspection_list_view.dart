import 'package:flutter/material.dart';

class InspectionModel {
  final String id;
  final String title;
  final String description;
  final String status;
  final DateTime createdAt;

  InspectionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory InspectionModel.fromJson(Map<String, dynamic> json) {
    return InspectionModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class InspectionService {
  Future<List<InspectionModel>> fetchInspections() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      InspectionModel(
        id: '1',
        title: 'فحص الخرسانة المسلحة',
        description: 'مراجعة أبعاد وتسليح السقف قبل الصب',
        status: 'مكتمل',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      InspectionModel(
        id: '2',
        title: 'معاينة أعمال التشطيبات',
        description: 'فحص بند المحارة والدهانات للفيلا',
        status: 'قيد الانتظار',
        createdAt: DateTime.now(),
      ),
      InspectionModel(
        id: '3',
        title: 'استلام بند الكهرباء',
        description: 'اختبار مسارات التمديدات ولوحات التوزيع الرئيسية',
        status: 'جاري العمل',
        createdAt: DateTime.now(),
      ),
    ];
  }
}

class InspectionListView extends StatefulWidget {
  // تم التعديل إلى super.key
  const InspectionListView({super.key});

  @override
  State<InspectionListView> createState() => _InspectionListViewState();
}

class _InspectionListViewState extends State<InspectionListView> {
  final InspectionService _service = InspectionService();
  late Future<List<InspectionModel>> _inspectionsFuture;

  @override
  void initState() {
    super.initState();
    _inspectionsFuture = _service.fetchInspections();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'مكتمل':
        return Colors.green;
      case 'جاري العمل':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة الفحوصات والمهام'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<InspectionModel>>(
        future: _inspectionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد عناصر حالياً'));
          }

          final items = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(12.0),
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      item.id,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // تم تعديل مكان style لنقله داخل الـ Text بدلاً من الـ Padding
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      item.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  trailing: Chip(
                    label: Text(
                      item.status,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: _getStatusColor(item.status),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}