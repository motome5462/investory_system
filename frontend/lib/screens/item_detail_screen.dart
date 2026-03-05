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
  final snCtrl = TextEditingController();
  final noteCtrl = TextEditingController(); // 1. เพิ่ม Controller สำหรับหมายเหตุ
  List<Map<String, dynamic>> itemsList = [];

  void addItem() {
    if (itemCtrl.text.isEmpty) return;
    setState(() {
      itemsList.add({
        "item_name": itemCtrl.text,
        "quantity": qtyCtrl.text,
        "sn_number": snCtrl.text,
        "note": noteCtrl.text, // 2. เก็บค่าหมายเหตุ
      });
    });
    // ล้างข้อมูลหลังกดเพิ่ม
    itemCtrl.clear(); 
    qtyCtrl.clear(); 
    snCtrl.clear();
    noteCtrl.clear(); 
  }

  Future<void> saveAll() async {
    if (itemsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณาเพิ่มรายการสินค้าอย่างน้อย 1 รายการ")),
      );
      return;
    }

    try {
      for (var item in itemsList) {
        await http.post(
          Uri.parse('http://10.0.2.2:3000/api/items'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"project_id": widget.projectId, ...item}),
        );
      }
      if (!mounted) return;
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      debugPrint("Error saving items: $e");
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
                TextField(controller: itemCtrl, decoration: const InputDecoration(labelText: "ชื่อสินค้า", prefixIcon: Icon(Icons.inventory))),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: "จำนวน"), keyboardType: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: snCtrl, decoration: const InputDecoration(labelText: "SN / รหัสสินค้า"))),
                  ],
                ),
                const SizedBox(height: 10),
                // 3. เพิ่มช่องกรอกหมายเหตุ
                TextField(
                  controller: noteCtrl, 
                  decoration: const InputDecoration(labelText: "หมายเหตุ (ถ้ามี)", prefixIcon: Icon(Icons.edit_note)),
                  maxLines: 2,
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: addItem, 
                  icon: const Icon(Icons.add),
                  label: const Text("เพิ่มลงรายการชั่วคราว"),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
                ),
                const Divider(height: 30),
                const Text("รายการที่เตรียมบันทึก:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...itemsList.map((item) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(item['item_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      "SN: ${item['sn_number']} | จำนวน: ${item['quantity']}\nหมายเหตุ: ${item['note'].isEmpty ? '-' : item['note']}"
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red), 
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
                child: const Text("บันทึกทั้งหมดลงฐานข้อมูล", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
              ),
            ),
          )
        ],
      ),
    );
  }
}