import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // สำหรับจัดการไฟล์รูปภาพ
import 'package:image_picker/image_picker.dart'; // สำหรับเลือกรูป/ถ่ายรูป

class ItemDetailScreen extends StatefulWidget {
  final int projectId;
  final String projectName;

  const ItemDetailScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final itemCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  File? _image; // ตัวแปรเก็บรูปภาพปัจจุบันที่เลือก
  final picker = ImagePicker();

  List<TextEditingController> snControllers = [];
  List<Map<String, dynamic>> itemsList = []; // รายการสินค้าชั่วคราวก่อนกดบันทึกจริง

  @override
  void initState() {
    super.initState();
    snControllers.add(TextEditingController());
    qtyCtrl.addListener(_onQtyChanged);
  }

  // ฟังก์ชันเลือกรูปภาพ (ถ่ายรูป หรือ เลือกจากคลัง)
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 50, // ลดขนาดรูปเพื่อไม่ให้หนัก Server
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // ฟังก์ชันสร้างช่องกรอก SN ตามจำนวนที่ระบุ
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

  // เพิ่มข้อมูลลงในรายการชั่วคราว (ยังไม่ส่งไป Database)
  void addItem() {
    if (itemCtrl.text.isEmpty || qtyCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณากรอกชื่อสินค้าและจำนวน")),
      );
      return;
    }

    setState(() {
      itemsList.add({
        "item_name": itemCtrl.text,
        "quantity": qtyCtrl.text,
        "sn_list": snControllers.map((c) => c.text).toList(),
        "note": noteCtrl.text,
        "image_file": _image, // เก็บไฟล์รูปภาพไว้ใน Map
      });
    });

    // ล้างข้อมูลหน้าจอเพื่อกรอกรายการถัดไป
    itemCtrl.clear();
    qtyCtrl.clear();
    noteCtrl.clear();
    _image = null;
    snControllers.clear();
    snControllers.add(TextEditingController());
  }

  // ส่งข้อมูลทั้งหมดไปยัง Backend (MultipartRequest)
  Future<void> saveAll() async {
    if (itemsList.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      for (var item in itemsList) {
        // ใช้ MultipartRequest เพื่อส่งไฟล์และฟิลด์ข้อความพร้อมกัน
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://10.0.2.2:3000/api/items'), // ใช้ 10.0.2.2 สำหรับ Emulator Android
        );

        // ใส่ข้อมูลลงใน Fields (ทุกอย่างต้องเป็น String)
        request.fields['project_id'] = widget.projectId.toString();
        request.fields['item_name'] = item['item_name'].toString();
        request.fields['quantity'] = item['quantity'].toString();
        request.fields['note'] = item['note'] ?? "";
        
        // แปลง List ของ SN ให้เป็น JSON String เพื่อให้ Backend ใช้ JSON.parse ได้
        request.fields['sn_numbers'] = jsonEncode(item['sn_list']);

        // ถ้ามีรูปภาพ ให้แนบไฟล์ไปด้วย
        if (item['image_file'] != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'image', // ชื่อต้องตรงกับ upload.single('image') ใน server.js
            item['image_file'].path,
          ));
        }

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode != 200 && response.statusCode != 201) {
          debugPrint("บันทึกไม่สำเร็จ: ${response.body}");
        }
      }

      if (!mounted) return;
      Navigator.pop(context); // ปิด Loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("บันทึกข้อมูลเรียบร้อยแล้ว"), backgroundColor: Colors.green),
      );
      
      // กลับไปหน้าก่อนหน้า
      Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context); // ปิด Loading
      debugPrint("Error saving items: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
      );
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
                // --- ส่วนแสดงตัวอย่างรูปภาพและการเลือกรูป ---
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _image != null ? FileImage(_image!) : null,
                        child: _image == null
                            ? const Icon(Icons.image, size: 60, color: Colors.grey)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: Colors.blue,
                          radius: 20,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                            onPressed: _showImagePickerOptions,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: itemCtrl,
                  decoration: const InputDecoration(
                    labelText: "ชื่อสินค้า",
                    prefixIcon: Icon(Icons.inventory),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: qtyCtrl,
                  decoration: const InputDecoration(
                    labelText: "จำนวนสินค้า",
                    prefixIcon: Icon(Icons.format_list_numbered),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                const Text(
                  "ระบุ Serial Number (SN):",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16),
                ),
                const SizedBox(height: 10),
                ...List.generate(snControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      controller: snControllers[index],
                      decoration: InputDecoration(
                        labelText: "SN ชิ้นที่ ${index + 1}",
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: "หมายเหตุ (ถ้ามี)",
                    prefixIcon: Icon(Icons.edit_note),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: addItem,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text("เพิ่มลงรายการชั่วคราว"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const Divider(height: 40, thickness: 2),
                
                // --- รายการที่เตรียมบันทึก ---
                const Text("รายการที่รอการบันทึก:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...itemsList.map((item) => Card(
                      color: Colors.blue[50],
                      child: ListTile(
                        leading: item['image_file'] != null
                            ? Image.file(item['image_file'], width: 50, height: 50, fit: BoxFit.cover)
                            : const Icon(Icons.image_not_supported),
                        title: Text("${item['item_name']} (${item['quantity']} ชิ้น)"),
                        subtitle: Text("SN: ${item['sn_list'].join(', ')}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => setState(() => itemsList.remove(item)),
                        ),
                      ),
                    )),
              ],
            ),
          ),
          // --- ปุ่มบันทึกทั้งหมด ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 5,
                ),
                onPressed: itemsList.isEmpty ? null : saveAll,
                child: const Text("บันทึกข้อมูลทั้งหมดลงฐานข้อมูล", style: TextStyle(fontSize: 18)),
              ),
            ),
          )
        ],
      ),
    );
  }

  // แสดงตัวเลือกสำหรับการจัดการรูปภาพ
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('เลือกจากคลังภาพ'),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('ถ่ายรูปด้วยกล้อง'),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}