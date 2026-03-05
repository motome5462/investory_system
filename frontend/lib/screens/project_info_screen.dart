import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'item_detail_screen.dart';

class ProjectInfoScreen extends StatefulWidget {
  const ProjectInfoScreen({super.key});
  @override
  State<ProjectInfoScreen> createState() => _ProjectInfoScreenState();
}

class _ProjectInfoScreenState extends State<ProjectInfoScreen> {
  final nameCtrl = TextEditingController();
  final dateCtrl = TextEditingController(text: "2026-03-04");
  final timeCtrl = TextEditingController(text: "17:00");
  final detailCtrl = TextEditingController();

  Future<void> nextStep() async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/api/projects'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "project_name": nameCtrl.text,
        "project_date": dateCtrl.text,
        "project_time": timeCtrl.text,
        "project_detail": detailCtrl.text
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => ItemDetailScreen(projectId: data['project_id'], projectName: nameCtrl.text)
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("1. ข้อมูลโครงการ")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "ชื่อโครงการ")),
          TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: "วันที่")),
          TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: "เวลา")),
          TextField(controller: detailCtrl, decoration: const InputDecoration(labelText: "รายละเอียด")),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: nextStep, child: const Text("ถัดไป: กรอกรายการสินค้า"))
        ],
      ),
    );
  }
}