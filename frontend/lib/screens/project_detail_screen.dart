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

  // --- 🎨 สไตล์การตกแต่ง Shared Decoration ---
  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
      ),
    );
  }

  // --- ⚙️ ฟังก์ชันดึงข้อมูลและจัดกลุ่ม ---
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
    setState(() {
      groupedItems = tempGroup.values.toList();
    });
  }

  Future<void> fetchData() async {
    try {
      final response = await http
          .get(Uri.parse('http://192.168.201.93:3000/api/projects/${widget.projectId}'))
          .timeout(const Duration(seconds: 10));

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

  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                'http://192.168.201.93:3000$imageUrl',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported, size: 100, color: Colors.white),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemDialog() {
    final itemCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    List<TextEditingController> snControllers = [TextEditingController()];
    File? tempImage;
    final picker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void onQtyChanged(String value) {
            int count = int.tryParse(value) ?? 1;
            if (count < 1) count = 1;
            if (count > 50) count = 50;

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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            title: const Row(
              children: [
                Icon(Icons.add_box_rounded, color: Colors.blueAccent),
                SizedBox(width: 10),
                Text("เพิ่มสินค้าใหม่"),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final pickedFile = await picker.pickImage(
                            source: ImageSource.gallery, imageQuality: 50);
                        if (pickedFile != null) {
                          setDialogState(() => tempImage = File(pickedFile.path));
                        }
                      },
                      child: Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: tempImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.file(tempImage!, fit: BoxFit.cover))
                            : const Icon(Icons.add_a_photo_rounded, size: 40, color: Colors.blueAccent),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: itemCtrl,
                      decoration: _inputStyle("ชื่อสินค้า", Icons.shopping_bag),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: onQtyChanged,
                      decoration: _inputStyle("จำนวนที่ต้องการเบิก", Icons.format_list_numbered),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const Text("ระบุ Serial Number (SN)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    const SizedBox(height: 10),
                    ...List.generate(snControllers.length, (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextField(
                        controller: snControllers[index],
                        decoration: InputDecoration(
                          hintText: "SN ชิ้นที่ ${index + 1}",
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    )),
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteCtrl,
                      decoration: _inputStyle("หมายเหตุเพิ่มเติม", Icons.note_alt),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("ยกเลิก", style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  if (itemCtrl.text.isEmpty || qtyCtrl.text.isEmpty) return;
                  List<String> sns = snControllers.map((c) => c.text.isEmpty ? "-" : c.text).toList();
                  var request = http.MultipartRequest('POST', Uri.parse('http://192.168.201.93:3000/api/items'));
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
                child: const Text("ยืนยันการเพิ่ม", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Off-white Background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text("รายละเอียดโครงการ", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(isEditing ? Icons.check_circle : Icons.edit_note_rounded,
                  color: isEditing ? Colors.green : Colors.blueAccent, size: 28),
              onPressed: () => isEditing ? _updateProject() : setState(() => isEditing = true),
            ),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- ส่วนหัวข้อมูลโครงการ ---
                  _buildHeaderCard(),
                  const SizedBox(height: 30),

                  // --- ส่วนรายการสินค้า ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("รายการสินค้า", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1E293B))),
                          Text("Items in this project", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddItemDialog,
                        icon: const Icon(Icons.add, size: 18, color: Colors.white),
                        label: const Text("เพิ่มสินค้า", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  groupedItems.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: groupedItems.length,
                          itemBuilder: (context, index) {
                            final item = groupedItems[index];
                            return _buildItemCard(item);
                          },
                        ),
                ],
              ),
            ),
    );
  }

  // --- 📦 Widget: Header Card (Project Info) ---
  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: nameCtrl,
            enabled: isEditing,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            decoration: _inputStyle("ชื่อโครงการ", Icons.topic_rounded),
          ),
          const SizedBox(height: 15),
          InkWell(
            onTap: isEditing ? () async {
              DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100));
              if (picked != null) setState(() => selectedDate = picked);
            } : null,
            child: IgnorePointer(
              child: TextField(
                decoration: _inputStyle(DateFormat('dd MMMM yyyy').format(selectedDate), Icons.calendar_month_rounded),
                readOnly: true,
              ),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: detailCtrl,
            enabled: isEditing,
            maxLines: 2,
            decoration: _inputStyle("รายละเอียดโครงการ", Icons.description_rounded),
          ),
        ],
      ),
    );
  }

  // --- 📦 Widget: Item Card ---
  Widget _buildItemCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: GestureDetector(
          onTap: () {
            if (item['image_url'] != null) _showImagePreview(item['image_url']);
          },
          child: Hero(
            tag: item['item_name'],
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.blue.shade50,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: item['image_url'] != null
                    ? Image.network('http://192.168.201.93:3000${item['image_url']}', fit: BoxFit.cover)
                    : const Icon(Icons.inventory_2_rounded, color: Colors.blueAccent),
              ),
            ),
          ),
        ),
        title: Text(item['item_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("จำนวน: ${item['quantity']} ชิ้น", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text("SN: ${item['sn_list'].join(', ')}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12), overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
          ),
          onPressed: () => _deleteGroupItems(item['ids']),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          const Text("ยังไม่มีสินค้าในโครงการนี้", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Future<void> _updateProject() async {
    try {
      final response = await http.put(
        Uri.parse('http://192.168.201.93:3000/api/projects/${widget.projectId}'),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("อัปเดตสำเร็จ", textAlign: TextAlign.center)));
      }
    } catch (e) {
      debugPrint("Update error: $e");
    }
  }

Future<void> _deleteGroupItems(List<dynamic> ids) async {
  // 1. แสดงหน้าต่างยืนยันก่อน
  bool confirmDelete = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text("ยืนยันการลบ"),
          ],
        ),
        content: const Text("คุณแน่ใจหรือไม่ว่าต้องการลบรายการสินค้านี้? ข้อมูลที่ลบแล้วไม่สามารถกู้คืนได้"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // ส่งค่า false กลับไป
            child: const Text("ยกเลิก", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true), // ส่งค่า true กลับไป
            child: const Text("ลบเลย", style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  ) ?? false; // ถ้ากดนอกกรอบให้ถือว่าเป็น false

  // 2. ถ้าผู้ใช้กดตกลง (true) ถึงจะเริ่มทำงานลบ
  if (confirmDelete) {
    try {
      for (var id in ids) {
        await http.delete(Uri.parse('http://192.168.201.93:3000/api/items/$id'));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ลบรายการสินค้าเรียบร้อยแล้ว"), backgroundColor: Colors.green),
        );
        fetchData(); // รีเฟรชข้อมูลใหม่
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาด: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}
}