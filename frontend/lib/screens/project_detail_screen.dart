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

  final nameCtrl = TextEditingController();
  final detailCtrl = TextEditingController();
  DateTime selectedDate = DateTime.now();
  
  // เปลี่ยนโครงสร้างการเก็บข้อมูลเพื่อรองรับการ Grouping
  List<Map<String, dynamic>> groupedItems = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  // ฟังก์ชันจัดกลุ่มสินค้าที่มีชื่อเดียวกัน
  void groupProjectItems(List<dynamic> rawItems) {
    Map<String, Map<String, dynamic>> tempGroup = {};

    for (var item in rawItems) {
      String name = item['item_name'] ?? "ไม่มีชื่อ";
      String sn = item['sn_number'] ?? "-";
      String note = item['note'] ?? "";
      
      if (tempGroup.containsKey(name)) {
        // ถ้ามีชื่อนี้อยู่แล้ว ให้เพิ่มจำนวน และต่อท้าย SN
        tempGroup[name]!['quantity'] += 1;
        tempGroup[name]!['sn_list'].add(sn);
        // เก็บ ID ไว้สำหรับอ้างอิงการลบ (ในกรณีนี้จะลบตัวล่าสุดที่เจอ)
        tempGroup[name]!['ids'].add(item['id']);
      } else {
        // ถ้ายังไม่มี ให้สร้าง Entry ใหม่
        tempGroup[name] = {
          'item_name': name,
          'quantity': 1,
          'sn_list': [sn],
          'note': note,
          'ids': [item['id']],
        };
      }
    }
    
    setState(() {
      groupedItems = tempGroup.values.toList();
    });
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/projects/${widget.projectId}')
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          var projectData = data['project'] ?? data; 
          nameCtrl.text = projectData['project_name']?.toString() ?? "";
          detailCtrl.text = projectData['project_detail']?.toString() ?? "";
          if (projectData['project_date'] != null) {
            selectedDate = DateTime.parse(projectData['project_date'].toString());
          }
          
          // นำข้อมูลดิบไปจัดกลุ่มก่อนแสดงผล
          groupProjectItems(data['items'] ?? []);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("โหลดข้อมูลไม่สำเร็จ: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("บันทึกข้อมูลโครงการสำเร็จ"), backgroundColor: Colors.green)
          );
          Navigator.pop(context); 
        }
      }
    } catch (e) {
      debugPrint("Error updating project: $e");
    }
  }

  // แก้ไขฟังก์ชันลบ: ลบสินค้าทั้งหมดภายใต้กลุ่มชื่อเดียวกัน
  Future<void> deleteGroupItems(List<dynamic> ids) async {
    try {
      for (var id in ids) {
        await http.delete(Uri.parse('http://10.0.2.2:3000/api/items/$id'));
      }
      fetchData(); 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ลบรายการสินค้าเรียบร้อยแล้ว"), backgroundColor: Colors.orange)
        );
      }
    } catch (e) {
      debugPrint("Error deleting items: $e");
    }
  }

  void showAddItemDialog() {
    final itemNameCtrl = TextEditingController();
    final snCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

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
              TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: "หมายเหตุ", prefixIcon: Icon(Icons.note_add))), 
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ยกเลิก")),
          ElevatedButton(
            onPressed: () async {
              if (itemNameCtrl.text.isNotEmpty && qtyCtrl.text.isNotEmpty) {
                // สำหรับหน้า Detail เราจะเพิ่มทีละรายการตาม Logic เดิมของ API คุณ
                int qty = int.tryParse(qtyCtrl.text) ?? 1;
                for(int i=0; i < qty; i++){
                   await http.post(
                    Uri.parse('http://10.0.2.2:3000/api/items'),
                    headers: {"Content-Type": "application/json"},
                    body: jsonEncode({
                      "project_id": widget.projectId,
                      "item_name": itemNameCtrl.text,
                      "sn_number": i == 0 ? snCtrl.text : "${snCtrl.text}-$i", // ตัวอย่างการแยก SN
                      "quantity": 1,
                      "note": noteCtrl.text 
                    }),
                  );
                }
                fetchData();
                if (mounted) Navigator.pop(context);
              }
            }, 
            child: const Text("เพิ่ม")
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("รายละเอียดโครงการ"),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.save : Icons.edit),
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
                // ส่วนข้อมูลโครงการ (เหมือนเดิม)
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Text("ข้อมูลทั่วไป", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 15),
                TextField(controller: nameCtrl, enabled: isEditing, decoration: const InputDecoration(labelText: "ชื่อโครงการ", border: OutlineInputBorder())),
                const SizedBox(height: 12),
                ListTile(
                  title: Text("วันที่: ${DateFormat('dd/MM/yyyy').format(selectedDate)}"),
                  trailing: isEditing ? const Icon(Icons.calendar_today, color: Colors.blue) : null,
                  onTap: isEditing ? () async {
                    DateTime? picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (picked != null) setState(() => selectedDate = picked);
                  } : null,
                ),
                const SizedBox(height: 12),
                TextField(controller: detailCtrl, enabled: isEditing, maxLines: 2, decoration: const InputDecoration(labelText: "รายละเอียดงาน", border: OutlineInputBorder())),
                const Divider(height: 40, thickness: 1.2),
                
                // ส่วนรายการสินค้า
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("รายการสินค้าในโครงการ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ElevatedButton.icon(
                      onPressed: showAddItemDialog,
                      icon: const Icon(Icons.add),
                      label: const Text("เพิ่มสินค้า"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                
                // แสดงผลรายการที่ Group แล้วเหมือนหน้า Item Detail
                groupedItems.isEmpty 
                  ? const Center(child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text("ไม่พบรายการสินค้าในโครงการนี้", style: TextStyle(color: Colors.grey)),
                    ))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: groupedItems.length,
                      itemBuilder: (context, index) {
                        final item = groupedItems[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5), // สีพื้นหลังเทาอ่อนเหมือนในรูป
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${item['item_name']} (จำนวน ${item['quantity']})",
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "SN: ${item['sn_list'].join(', ')}",
                                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                                      ),
                                      if (item['note'].toString().isNotEmpty)
                                        Text(
                                          "หมายเหตุ: ${item['note']}",
                                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("ยืนยันการลบ"),
                                        content: const Text("ต้องการลบกลุ่มสินค้านี้ใช่หรือไม่?"),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ยกเลิก")),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              deleteGroupItems(item['ids']);
                                            }, 
                                            child: const Text("ลบ", style: TextStyle(color: Colors.red))
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
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