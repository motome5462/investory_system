import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // สำหรับ File
import 'package:image_picker/image_picker.dart'; // สำหรับเลือกรูป

class ItemDetailScreen extends StatefulWidget {
  final int projectId;
  final String projectName;
  const ItemDetailScreen({super.key, required this.projectId, required this.projectName});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final itemCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  
  File? _image; // เก็บไฟล์รูปภาพที่เลือก
  final picker = ImagePicker();

  List<TextEditingController> snControllers = [];
  List<Map<String, dynamic>> itemsList = [];

  @override
  void initState() {
    super.initState();
    snControllers.add(TextEditingController());
    qtyCtrl.addListener(_onQtyChanged);
  }

  // ฟังก์ชันเลือกรูปภาพ
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _onQtyChanged() {
    final text = qtyCtrl.text;
    int count = int.tryParse(text) ?? 1;
    if (count < 1) count = 1;

    setState(() {
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

  void addItem() {
    if (itemCtrl.text.isEmpty || qtyCtrl.text.isEmpty) return;

    List<String> sns = snControllers.map((c) => c.text).toList();

    setState(() {
      itemsList.add({
        "item_name": itemCtrl.text,
        "quantity": qtyCtrl.text,
        "sn_list": sns,
        "note": noteCtrl.text,
        "image_file": _image, // เก็บไฟล์ไว้ในรายการชั่วคราว
      });
    });

    // ล้างข้อมูล
    itemCtrl.clear();
    qtyCtrl.clear();
    noteCtrl.clear();
    _image = null;
    snControllers.clear();
    snControllers.add(TextEditingController());
  }

  Future<void> saveAll() async {
    if (itemsList.isEmpty) return;

    try {
      for (var item in itemsList) {
        // ใช้ MultipartRequest เพื่อส่งไฟล์
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://10.0.2.2:3000/api/items'),
        );

        request.fields['project_id'] = widget.projectId.toString();
        request.fields['item_name'] = item['item_name'];
        request.fields['quantity'] = item['quantity'];
        request.fields['sn_numbers'] = jsonEncode(item['sn_list']);
        request.fields['note'] = item['note'];

        if (item['image_file'] != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'image', // ชื่อ Field ที่ Backend รอรับ
            item['image_file'].path,
          ));
        }

        await request.send();
      }
      if (!mounted) return;
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      debugPrint("Error saving: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("เพิ่มรายการ: ${widget.projectName}")),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ส่วนแสดงตัวอย่างรูปภาพ
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _image != null ? FileImage(_image!) : null,
                        child: _image == null ? const Icon(Icons.image, size: 50, color: Colors.grey) : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: Colors.blue,
                          radius: 18,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                            onPressed: () {
                              _showImagePickerOptions();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(controller: itemCtrl, decoration: const InputDecoration(labelText: "ชื่อสินค้า", prefixIcon: Icon(Icons.inventory))),
                const SizedBox(height: 10),
                TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: "จำนวน"), keyboardType: TextInputType.number),
                const SizedBox(height: 20),
                const Text("ระบุ Serial Number (SN):", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                ...List.generate(snControllers.length, (index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: TextField(controller: snControllers[index], decoration: InputDecoration(labelText: "SN ชิ้นที่ ${index + 1}", border: const OutlineInputBorder())),
                )),
                const SizedBox(height: 10),
                TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: "หมายเหตุ (ถ้ามี)", prefixIcon: Icon(Icons.edit_note)), maxLines: 2),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: addItem,
                  icon: const Icon(Icons.add),
                  label: const Text("เพิ่มลงรายการชั่วคราว"),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                ),
                const Divider(height: 40),
                // รายการที่เตรียมบันทึก (แสดงรูปย่อด้วย)
                ...itemsList.map((item) => Card(
                  child: ListTile(
                    leading: item['image_file'] != null 
                      ? Image.file(item['image_file'], width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.image_not_supported),
                    title: Text("${item['item_name']} (จำนวน ${item['quantity']})"),
                    trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => itemsList.remove(item))),
                  ),
                )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), onPressed: saveAll, child: const Text("บันทึกทั้งหมดลงฐานข้อมูล"))),
          )
        ],
      ),
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('เลือกจากคลังภาพ'), onTap: () { _pickImage(ImageSource.gallery); Navigator.pop(context); }),
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('ถ่ายรูป'), onTap: () { _pickImage(ImageSource.camera); Navigator.pop(context); }),
          ],
        ),
      ),
    );
  }
}