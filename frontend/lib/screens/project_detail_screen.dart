import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; 
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart'; 

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;
  final String userName;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    required this.userName,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  bool isEditing = false;
  bool isLoading = true;

  final nameCtrl = TextEditingController();
  final detailCtrl = TextEditingController();
  DateTime selectedDate = DateTime.now();

  List<Map<String, dynamic>> groupedItems = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  // --- ฟังก์ชันดึงข้อมูลและจัดกลุ่ม ---
  void _groupProjectItems(List<dynamic> rawItems) {
    Map<String, Map<String, dynamic>> tempGroup = {};
    for (var item in rawItems) {
      String name = item['item_name'] ?? "ไม่มีชื่อ";
      String sn = item['sn_number'] ?? "-";
      String note = item['note'] ?? "";
      String? imageUrl = item['image_url'];

      if (tempGroup.containsKey(name)) {
        tempGroup[name]!['quantity'] += 1;
        tempGroup[name]!['sn_list'].add(sn);
        tempGroup[name]!['ids'].add(item['id']);
      } else {
        tempGroup[name] = {
          'item_name': name,
          'quantity': 1,
          'sn_list': [sn],
          'note': note,
          'image_url': imageUrl,
          'ids': [item['id']],
        };
      }
    }
    setState(() { groupedItems = tempGroup.values.toList(); });
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/projects/${widget.projectId}'),
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
          _groupProjectItems(data['items'] ?? []);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  // --- ฟังก์ชันแสดง Dialog เพิ่มสินค้าพร้อมช่อง S/N ไดนามิก ---
  void _showAddItemDialog() {
    final itemCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    
    // สร้าง List เพื่อเก็บ Controller สำหรับช่อง S/N หลายช่อง
    List<TextEditingController> snControllers = [TextEditingController()];
    
    File? tempImage;
    final picker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          
          // ฟังก์ชันจัดการเพิ่ม/ลดช่องกรอก SN ตามจำนวนที่ระบุ
          void onQtyChanged(String value) {
            int count = int.tryParse(value) ?? 1;
            if (count < 1) count = 1;
            if (count > 50) count = 50; // ป้องกันการใส่จำนวนมากเกินไปจนค้าง

            setDialogState(() {
              if (snControllers.length < count) {
                for (int i = snControllers.length; i < count; i++) {
                  snControllers.add(TextEditingController());
                }
              } else if (snControllers.length > count) {
                for (int i = snControllers.length - 1; i >= count; i--) {
                  snControllers[i].dispose();
                  snControllers.removeAt(i);
                }
              }
            });
          }

          return AlertDialog(
            title: const Text("เพิ่มสินค้าเข้าโครงการ", style: TextStyle(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                        if (pickedFile != null) {
                          setDialogState(() => tempImage = File(pickedFile.path));
                        }
                      },
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: tempImage != null ? FileImage(tempImage!) : null,
                        child: tempImage == null ? const Icon(Icons.camera_alt, size: 30) : null,
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(controller: itemCtrl, decoration: const InputDecoration(labelText: "ชื่อสินค้า", border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    TextField(
                      controller: qtyCtrl, 
                      decoration: const InputDecoration(labelText: "จำนวน", border: OutlineInputBorder(), hintText: "ระบุจำนวนเพื่อสร้างช่อง SN"), 
                      keyboardType: TextInputType.number,
                      onChanged: onQtyChanged, // ตรวจจับการเปลี่ยนค่าจำนวน
                    ),
                    const SizedBox(height: 15),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("ระบุ Serial Number (SN):", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    ),
                    const SizedBox(height: 5),
                    // วนลูปสร้างช่องกรอกตามจำนวน Controller ที่มี
                    ...List.generate(snControllers.length, (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: TextField(
                        controller: snControllers[index], 
                        decoration: InputDecoration(
                          labelText: "SN ชิ้นที่ ${index + 1}", 
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
                        )
                      ),
                    )),
                    const SizedBox(height: 10),
                    TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: "หมายเหตุ", border: OutlineInputBorder())),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("ยกเลิก")),
              ElevatedButton(
                onPressed: () async {
                  if (itemCtrl.text.isEmpty || qtyCtrl.text.isEmpty) return;
                  
                  // รวบรวมค่า SN จากทุกช่อง
                  List<String> sns = snControllers.map((c) => c.text.isEmpty ? "-" : c.text).toList();

                  var request = http.MultipartRequest('POST', Uri.parse('http://10.0.2.2:3000/api/items'));
                  request.fields['project_id'] = widget.projectId.toString();
                  request.fields['item_name'] = itemCtrl.text;
                  request.fields['quantity'] = qtyCtrl.text;
                  request.fields['note'] = noteCtrl.text;
                  request.fields['sn_numbers'] = jsonEncode(sns);

                  if (tempImage != null) {
                    request.files.add(await http.MultipartFile.fromPath('image', tempImage!.path));
                  }

                  var response = await request.send();
                  if (response.statusCode == 201 || response.statusCode == 200) {
                    Navigator.pop(context);
                    fetchData(); 
                  }
                },
                child: const Text("เพิ่มสินค้า"),
              ),
            ],
          );
        }
      ),
    );
  }

  // --- ส่วน UI หลัก ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("รายละเอียดโครงการ"),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.save : Icons.edit),
            onPressed: () => isEditing ? _updateProject() : setState(() => isEditing = true),
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
                    tileColor: const Color(0xFFF5F5F5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                  const SizedBox(height: 12),
                  TextField(controller: detailCtrl, enabled: isEditing, maxLines: 2, decoration: const InputDecoration(labelText: "รายละเอียดงาน", border: OutlineInputBorder())),
                  const Divider(height: 40, thickness: 1.2),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("รายการสินค้า", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ElevatedButton.icon(
                        onPressed: _showAddItemDialog,
                        icon: const Icon(Icons.add),
                        label: const Text("เพิ่มสินค้า"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  groupedItems.isEmpty
                      ? const Center(child: Padding(
                        padding: EdgeInsets.all(20.0),
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
                                color: const Color(0xFFF5F5F5), 
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2)
                                  )
                                ]
                              ),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: item['image_url'] != null
                                      ? Image.network(
                                          'http://10.0.2.2:3000${item['image_url']}', 
                                          width: 50, height: 50, fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.inventory_2),
                                        )
                                      : const Icon(Icons.inventory_2),
                                ),
                                title: Text("${item['item_name']} (จำนวน ${item['quantity']})", style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text("SN: ${item['sn_list'].join(', ')}"),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red), 
                                  onPressed: () => _deleteGroupItems(item['ids'])
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

  // --- ฟังก์ชันอัปเดตโครงการ ---
  Future<void> _updateProject() async {
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
        setState(() => isEditing = false);
        fetchData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("อัปเดตข้อมูลโครงการสำเร็จ")));
      }
    } catch (e) {
       debugPrint("Update error: $e");
    }
  }

  // --- ฟังก์ชันลบรายการสินค้า ---
  Future<void> _deleteGroupItems(List<dynamic> ids) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ยืนยันการลบ"),
        content: const Text("คุณต้องการลบรายการสินค้าเหล่านี้ใช่หรือไม่?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("ยกเลิก")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("ลบ", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      for (var id in ids) { 
        await http.delete(Uri.parse('http://10.0.2.2:3000/api/items/$id')); 
      }
      fetchData();
    }
  }
}