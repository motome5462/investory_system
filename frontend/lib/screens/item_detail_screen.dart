import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ItemDetailScreen extends StatelessWidget {
  final int projectId;
  final String projectName;
  ItemDetailScreen({super.key, required this.projectId, required this.projectName});

  final itemCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();
  final snCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  Future<void> save(BuildContext context) async {
    await http.post(
      Uri.parse('http://10.0.2.2:3000/api/items'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "project_id": projectId,
        "item_name": itemCtrl.text,
        "quantity": qtyCtrl.text,
        "sn_number": snCtrl.text,
        "note": noteCtrl.text
      }),
    );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("บันทึกข้อมูลเรียบร้อย!")));
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("2. รายการเบิก: $projectName")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text("Project ID: $projectId", style: const TextStyle(color: Colors.grey)),
          TextField(controller: itemCtrl, decoration: const InputDecoration(labelText: "รายการสินค้า")),
          TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: "จำนวน"), keyboardType: TextInputType.number),
          TextField(controller: snCtrl, decoration: const InputDecoration(labelText: "Serial Number (SN)")),
          const SizedBox(height: 20),
          Container(height: 100, color: Colors.grey[200], child: const Icon(Icons.camera_alt)), // ตัวอย่างปุ่มรูป
          TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: "หมายเหตุ")),
          const SizedBox(height: 30),
          ElevatedButton(onPressed: () => save(context), child: const Text("ยืนยันบันทึกข้อมูล"))
        ],
      ),
    );
  }
}