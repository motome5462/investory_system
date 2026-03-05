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
  List<Map<String, dynamic>> itemsList = [];

  void addItem() {
    if (itemCtrl.text.isEmpty) return;
    setState(() {
      itemsList.add({"item_name": itemCtrl.text, "quantity": qtyCtrl.text, "sn_number": snCtrl.text});
    });
    itemCtrl.clear(); qtyCtrl.clear(); snCtrl.clear();
  }

  Future<void> saveAll() async {
    for (var item in itemsList) {
      await http.post(Uri.parse('http://10.0.2.2:3000/api/items'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"project_id": widget.projectId, ...item}));
    }
    Navigator.popUntil(context, (route) => route.isFirst);
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
                TextField(controller: itemCtrl, decoration: const InputDecoration(labelText: "ชื่อสินค้า")),
                TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: "จำนวน"), keyboardType: TextInputType.number),
                TextField(controller: snCtrl, decoration: const InputDecoration(labelText: "SN")),
                const SizedBox(height: 10),
                ElevatedButton(onPressed: addItem, child: const Text("เพิ่มลงรายการชั่วคราว")),
                const Divider(),
                ...itemsList.map((item) => ListTile(
                      title: Text(item['item_name']),
                      subtitle: Text("SN: ${item['sn_number']} | จำนวน: ${item['quantity']}"),
                      trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => itemsList.remove(item))),
                    )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), onPressed: saveAll, child: const Text("บันทึกทั้งหมดลงฐานข้อมูล"))),
          )
        ],
      ),
    );
  }
}