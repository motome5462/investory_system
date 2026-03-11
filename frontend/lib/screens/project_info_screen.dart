import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'item_detail_screen.dart';

class ProjectInfoScreen extends StatefulWidget {
  final String userName;
  final int userId; 

  const ProjectInfoScreen({super.key, required this.userName, required this.userId});

  @override
  State<ProjectInfoScreen> createState() => _ProjectInfoScreenState();
}

class _ProjectInfoScreenState extends State<ProjectInfoScreen> {
  final nameCtrl = TextEditingController();
  final detailCtrl = TextEditingController();
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  Future<void> nextStep() async {
    if (nameCtrl.text.isEmpty) return;
    
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/api/projects'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "project_name": nameCtrl.text,
        "project_date": DateFormat('yyyy-MM-dd').format(selectedDate),
        "project_time": "${selectedTime.hour}:${selectedTime.minute}:00",
        "project_detail": detailCtrl.text,
        "user_id": widget.userId
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
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
            child: Text("ผู้บันทึก: ${widget.userName}", style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "ชื่อโครงการ", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          ListTile(
            tileColor: Colors.grey.shade100,
            title: Text("วันที่: ${DateFormat('dd/MM/yyyy').format(selectedDate)}"),
            trailing: const Icon(Icons.calendar_today, color: Colors.blue),
            onTap: () async {
              DateTime? picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
              if (picked != null) setState(() => selectedDate = picked);
            },
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: Colors.grey.shade100,
            title: Text("เวลา: ${selectedTime.format(context)}"),
            trailing: const Icon(Icons.access_time, color: Colors.blue),
            onTap: () async {
              TimeOfDay? picked = await showTimePicker(context: context, initialTime: selectedTime);
              if (picked != null) setState(() => selectedTime = picked);
            },
          ),
          const SizedBox(height: 15),
          TextField(controller: detailCtrl, decoration: const InputDecoration(labelText: "รายละเอียด", border: OutlineInputBorder()), maxLines: 3),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.blue, foregroundColor: Colors.white),
            onPressed: nextStep, 
            child: const Text("ถัดไป: เพิ่มรายการสินค้า")
          ),
        ],
      ),
    );
  }
}