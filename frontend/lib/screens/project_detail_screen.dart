import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;
  final String userName;

  const ProjectDetailScreen({super.key, required this.projectId, required this.userName});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  bool isEditing = false; // สถานะว่ากำลังแก้ไขอยู่หรือไม่
  
  // Controllers สำหรับการแก้ไข
  final nameCtrl = TextEditingController();
  final detailCtrl = TextEditingController();
  DateTime selectedDate = DateTime.now();

  List<dynamic> items = []; // สำหรับเก็บรายการสินค้าในโครงการ

  @override
  void initState() {
    super.initState();
    fetchProjectData();
  }

  // ดึงข้อมูลโครงการและสินค้า
  Future<void> fetchProjectData() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:3000/api/projects/${widget.projectId}'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        nameCtrl.text = data['project']['project_name'];
        detailCtrl.text = data['project']['project_detail'] ?? '';
        selectedDate = DateTime.parse(data['project']['project_date']);
        items = data['items'];
      });
    }
  }

  // บันทึกการแก้ไขโครงการ
  Future<void> updateProject() async {
    final response = await http.put(
      Uri.parse('http://10.0.2.2:3000/api/projects/${widget.projectId}'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "project_name": nameCtrl.text,
        "project_date": DateFormat('yyyy-MM-dd').format(selectedDate),
        "project_detail": detailCtrl.text,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("อัปเดตข้อมูลสำเร็จ!")));
      setState(() => isEditing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("รายละเอียดโครงการ"),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (isEditing) {
                updateProject();
              } else {
                setState(() => isEditing = true);
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ส่วนข้อมูลโครงการ ---
            const Text("ข้อมูลทั่วไป", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            isEditing 
              ? TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "ชื่อโครงการ", border: OutlineInputBorder()))
              : ListTile(leading: const Icon(Icons.business), title: const Text("ชื่อโครงการ"), subtitle: Text(nameCtrl.text)),
            
            const SizedBox(height: 10),
            isEditing
              ? ListTile(
                  title: Text("วันที่: ${DateFormat('dd/MM/yyyy').format(selectedDate)}"),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    DateTime? picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (picked != null) setState(() => selectedDate = picked);
                  },
                )
              : ListTile(leading: const Icon(Icons.calendar_today), title: const Text("วันที่โครงการ"), subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate))),

            const SizedBox(height: 10),
            isEditing
              ? TextField(controller: detailCtrl, decoration: const InputDecoration(labelText: "รายละเอียด", border: OutlineInputBorder()), maxLines: 2)
              : ListTile(leading: const Icon(Icons.description), title: const Text("รายละเอียด"), subtitle: Text(detailCtrl.text)),

            const Divider(height: 40, thickness: 2),

            // --- ส่วนรายการสินค้า ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("รายการสินค้าในโครงการ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                if (isEditing) IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: () { /* เพิ่มฟังก์ชันเพิ่มสินค้าใหม่ที่นี่ */ }),
              ],
            ),
            const SizedBox(height: 10),
            items.isEmpty 
              ? const Center(child: Text("ไม่มีรายการสินค้า"))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    var item = items[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.inventory_2)),
                        title: Text(item['item_name']),
                        subtitle: Text("SN: ${item['sn_number']} | จำนวน: ${item['quantity']}"),
                        trailing: isEditing ? IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {}) : null,
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}