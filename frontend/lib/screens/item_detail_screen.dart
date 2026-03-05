import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  
  // รายการของ Controllers สำหรับช่อง SN ที่จะเพิ่มลดตามจำนวนสินค้า
  List<TextEditingController> snControllers = [];
  List<Map<String, dynamic>> itemsList = [];

  @override
  void initState() {
    super.initState();
    // เริ่มต้นช่อง SN อย่างน้อย 1 ช่อง
    snControllers.add(TextEditingController());
    
    // ตรวจสอบการพิมพ์ในช่องจำนวน เพื่อสร้างช่อง SN ตามจริง
    qtyCtrl.addListener(_onQtyChanged);
  }

  void _onQtyChanged() {
    final text = qtyCtrl.text;
    if (text.isEmpty) return;
    
    int count = int.tryParse(text) ?? 1;
    if (count < 1) count = 1;
    if (count > 50) count = 50; // จำกัดเพื่อความปลอดภัย

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

  // แก้ไขฟังก์ชันการเพิ่มรายการชั่วคราว
  void addItem() {
    // ตรวจสอบความถูกต้องเบื้องต้น
    if (itemCtrl.text.isEmpty || qtyCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณากรอกชื่อสินค้าและจำนวน"))
      );
      return;
    }

    // ดึงค่า SN จากทุกช่องที่ถูกสร้างขึ้น
    List<String> sns = snControllers.map((c) => c.text).toList();

    setState(() {
      itemsList.add({
        "item_name": itemCtrl.text,
        "quantity": qtyCtrl.text,
        "sn_list": sns, // เก็บเป็น List ของ SN ทั้งหมด
        "note": noteCtrl.text,
      });
    });

    // ล้างข้อมูลหลังจากเพิ่มสำเร็จ
    itemCtrl.clear();
    qtyCtrl.clear();
    noteCtrl.clear();
    for (var controller in snControllers) {
      controller.clear();
    }
    // รีเซ็ตช่อง SN กลับไปเป็น 1 ช่อง (ตามพฤติกรรมปกติหลังล้าง qtyCtrl)
    setState(() {
       snControllers.clear();
       snControllers.add(TextEditingController());
    });
  }

  Future<void> saveAll() async {
    if (itemsList.isEmpty) return;

    try {
      for (var item in itemsList) {
        // วนลูปบันทึกทีละ SN ลงฐานข้อมูล (หรือปรับตามที่ Backend รับ)
        for (var sn in item['sn_list']) {
          await http.post(
            Uri.parse('http://10.0.2.2:3000/api/items'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "project_id": widget.projectId,
              "item_name": item['item_name'],
              "quantity": 1, // บันทึกทีละชิ้น
              "sn_number": sn,
              "note": item['note'],
            }),
          );
        }
      }
      if (!mounted) return;
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      debugPrint("Error saving: $e");
    }
  }

  @override
  void dispose() {
    itemCtrl.dispose();
    qtyCtrl.dispose();
    noteCtrl.dispose();
    for (var c in snControllers) {
      c.dispose();
    }
    super.dispose();
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
                TextField(
                  controller: itemCtrl, 
                  decoration: const InputDecoration(labelText: "ชื่อสินค้า", prefixIcon: Icon(Icons.inventory))
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: qtyCtrl, 
                  decoration: const InputDecoration(
                    labelText: "จำนวน", 
                    helperText: "ระบุจำนวนเพื่อสร้างช่องกรอก SN"
                  ), 
                  keyboardType: TextInputType.number
                ),
                const SizedBox(height: 20),
                
                if (qtyCtrl.text.isNotEmpty) ...[
                  const Text("ระบุ Serial Number (SN):", 
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(snControllers.length, (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TextField(
                      controller: snControllers[index],
                      decoration: InputDecoration(
                        labelText: "SN ชิ้นที่ ${index + 1}",
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  )),
                ],

                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl, 
                  decoration: const InputDecoration(labelText: "หมายเหตุ (ถ้ามี)", prefixIcon: Icon(Icons.edit_note)),
                  maxLines: 2,
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: addItem, 
                  icon: const Icon(Icons.add_task),
                  label: const Text("เพิ่มลงรายการชั่วคราว"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.blue.shade50
                  ),
                ),
                const Divider(height: 40),
                
                const Text("รายการที่เตรียมบันทึก:", style: TextStyle(fontWeight: FontWeight.bold)),
                ...itemsList.map((item) => Card(
                  child: ListTile(
                    title: Text("${item['item_name']} (จำนวน ${item['quantity']})"),
                    subtitle: Text("SN: ${item['sn_list'].join(', ')}\nหมายเหตุ: ${item['note']}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red), 
                      onPressed: () => setState(() => itemsList.remove(item))
                    ),
                  ),
                )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity, 
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), 
                onPressed: saveAll, 
                child: const Text("บันทึกทั้งหมดลงฐานข้อมูล", 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                )
              ),
            ),
          )
        ],
      ),
    );
  }
}