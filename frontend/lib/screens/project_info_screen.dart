import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'item_detail_screen.dart';

class ProjectInfoScreen extends StatefulWidget {
  final String userName;
  const ProjectInfoScreen({super.key, required this.userName});

  @override
  State<ProjectInfoScreen> createState() => _ProjectInfoScreenState();
}

class _ProjectInfoScreenState extends State<ProjectInfoScreen> {
  final nameCtrl = TextEditingController();
  final detailCtrl = TextEditingController();
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  Future<void> nextStep() async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/api/projects'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "project_name": nameCtrl.text,
        "project_date": DateFormat('yyyy-MM-dd').format(selectedDate),
        "project_time": "${selectedTime.hour}:${selectedTime.minute}:00",
        "project_detail": detailCtrl.text
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => ItemDetailScreen(projectId: data['project_id'], projectName: nameCtrl.text)
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ข้อมูลโครงการ")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text("ผู้บันทึก: ${widget.userName}", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "ชื่อโครงการ", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          ListTile(
            title: Text("วันที่: ${DateFormat('dd/MM/yyyy').format(selectedDate)}"),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              DateTime? picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
              if (picked != null) setState(() => selectedDate = picked);
            },
          ),
          ListTile(
            title: Text("เวลา: ${selectedTime.format(context)}"),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              TimeOfDay? picked = await showTimePicker(context: context, initialTime: selectedTime);
              if (picked != null) setState(() => selectedTime = picked);
            },
          ),
          TextField(controller: detailCtrl, decoration: const InputDecoration(labelText: "รายละเอียด"), maxLines: 3),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: nextStep, child: const Text("ถัดไป: เพิ่มรายการสินค้า")),
        ],
      ),
    );
  }
}