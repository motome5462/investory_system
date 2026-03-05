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
  bool isEditing = false;
  bool isLoading = true;

  // Controllers สำหรับข้อมูลโครงการ
  final nameCtrl = TextEditingController();
  final detailCtrl = TextEditingController();
  DateTime selectedDate = DateTime.now();
  
  // รายการสินค้า (จะดึงมาจากฐานข้อมูล)
  List<dynamic> items = [];

  @override
  void initState() {
    super.initState();
    fetchData(); // ดึงข้อมูลโครงการและสินค้าทันทีที่เปิดหน้า
  }

  // ฟังก์ชันดึงข้อมูลโครงการและรายการสินค้าจาก API
Future<void> fetchData() async {
  try {
    debugPrint("กำลังดึงข้อมูลโครงการ ID: ${widget.projectId}");
    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/api/projects/${widget.projectId}')
    ).timeout(const Duration(seconds: 10)); // เพิ่ม Timeout กันค้าง

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint("ได้รับข้อมูล: $data");

      setState(() {
        // ดึงข้อมูลโครงการ: รองรับทั้งแบบ data['project'] และ data ตรงๆ
        var projectData = data['project'] ?? data; 
        
        nameCtrl.text = projectData['project_name']?.toString() ?? "";
        detailCtrl.text = projectData['project_detail']?.toString() ?? "";
        
        if (projectData['project_date'] != null) {
          selectedDate = DateTime.parse(projectData['project_date'].toString());
        }
        
        // ดึงรายการสินค้า
        items = data['items'] ?? [];
        isLoading = false;
      });
    } else {
      throw "Server ตอบกลับด้วยรหัส: ${response.statusCode}";
    }
  } catch (e) {
    debugPrint("Error Fetching: $e");
    if (mounted) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("โหลดข้อมูลไม่สำเร็จ: $e"), backgroundColor: Colors.red),
      );
    }
  }
}

  // ฟังก์ชันบันทึกการแก้ไขข้อมูลโครงการ (PUT)
  Future<void> updateProject() async {
    try {
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("อัปเดตข้อมูลโครงการสำเร็จ")));
        }
        setState(() => isEditing = false);
        fetchData(); // โหลดข้อมูลใหม่เพื่อยืนยันความถูกต้อง
      }
    } catch (e) {
      debugPrint("Error updating project: $e");
    }
  }

  // ฟังก์ชันลบสินค้า (Delete)
  Future<void> deleteItem(int itemId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:3000/api/items/$itemId'),
      );
      if (response.statusCode == 200) {
        fetchData(); // รีเฟรชรายการหลังลบสำเร็จ
      }
    } catch (e) {
      debugPrint("Error deleting item: $e");
    }
  }

  // ฟังก์ชันแสดง Dialog เพื่อเพิ่มสินค้าใหม่เข้าไปในโครงการนี้
  void showAddItemDialog() {
    final itemNameCtrl = TextEditingController();
    final snCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("เพิ่มสินค้าใหม่", style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: itemNameCtrl, decoration: const InputDecoration(labelText: "ชื่อสินค้า", prefixIcon: Icon(Icons.inventory))),
              TextField(controller: snCtrl, decoration: const InputDecoration(labelText: "S/N Number", prefixIcon: Icon(Icons.qr_code))),
              TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: "จำนวน", prefixIcon: Icon(Icons.numbers)), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ยกเลิก")),
          ElevatedButton(
            onPressed: () async {
              if (itemNameCtrl.text.isNotEmpty && qtyCtrl.text.isNotEmpty) {
                await addItemApi(itemNameCtrl.text, snCtrl.text, qtyCtrl.text);
                if (mounted) Navigator.pop(context);
              }
            }, 
            child: const Text("เพิ่ม")
          ),
        ],
      ),
    );
  }

  // API เพิ่มสินค้าใหม่ผูกกับ projectId นี้
  Future<void> addItemApi(String name, String sn, String qty) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/items'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "project_id": widget.projectId,
          "item_name": name,
          "sn_number": sn,
          "quantity": int.tryParse(qty) ?? 0
        }),
      );
      if (response.statusCode == 201) {
        fetchData(); // โหลดรายการสินค้าใหม่มาแสดงทันที
      }
    } catch (e) {
      debugPrint("Error adding item: $e");
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
            tooltip: isEditing ? 'บันทึก' : 'แก้ไขข้อมูลโครงการ',
            onPressed: () => isEditing ? updateProject() : setState(() => isEditing = true),
          )
        ],
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- ส่วนข้อมูลโครงการ ---
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Text("ข้อมูลทั่วไป", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: nameCtrl, 
                  enabled: isEditing, 
                  decoration: InputDecoration(
                    labelText: "ชื่อโครงการ", 
                    filled: !isEditing,
                    fillColor: isEditing ? Colors.transparent : Colors.grey[100],
                    border: const OutlineInputBorder()
                  )
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                    color: isEditing ? Colors.transparent : Colors.grey[100],
                  ),
                  child: ListTile(
                    title: Text("วันที่: ${DateFormat('dd/MM/yyyy').format(selectedDate)}"),
                    trailing: isEditing ? const Icon(Icons.calendar_today, color: Colors.blue) : null,
                    onTap: isEditing ? () async {
                      DateTime? picked = await showDatePicker(
                        context: context, 
                        initialDate: selectedDate, 
                        firstDate: DateTime(2000), 
                        lastDate: DateTime(2100)
                      );
                      if (picked != null) setState(() => selectedDate = picked);
                    } : null,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: detailCtrl, 
                  enabled: isEditing, 
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: "รายละเอียดงาน", 
                    filled: !isEditing,
                    fillColor: isEditing ? Colors.transparent : Colors.grey[100],
                    border: const OutlineInputBorder()
                  )
                ),
                
                const Divider(height: 40, thickness: 1.2),
                
                // --- ส่วนรายการสินค้าที่เคยบันทึกไว้ ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.list_alt, color: Colors.green),
                        SizedBox(width: 8),
                        Text("รายการสินค้าในโครงการ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: showAddItemDialog,
                      icon: const Icon(Icons.add),
                      label: const Text("เพิ่มสินค้า"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, 
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                
                items.isEmpty 
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(child: Text("ไม่พบรายการสินค้าในโครงการนี้", style: TextStyle(color: Colors.grey))),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.blueAccent, 
                              child: Icon(Icons.inventory_2, color: Colors.white, size: 20)
                            ),
                            title: Text(item['item_name'] ?? "สินค้าไม่มีชื่อ", style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("S/N: ${item['sn_number'] ?? '-'} | จำนวน: ${item['quantity'] ?? 0}"),
                            trailing: isEditing ? IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => deleteItem(item['id']), // ลบสินค้าออกจากฐานข้อมูล
                            ) : null,
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