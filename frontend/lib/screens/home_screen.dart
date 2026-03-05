import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'project_info_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  const HomeScreen({super.key, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ฟังก์ชันดึงข้อมูลโครงการจาก API
  Future<List<dynamic>> fetchProjects() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:3000/api/projects'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load projects');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("รายการโครงการ")),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(widget.userName),
              accountEmail: const Text("เจ้าหน้าที่บันทึกข้อมูล"),
              currentAccountPicture: const CircleAvatar(child: Icon(Icons.person)),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("ออกจากระบบ"),
              onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
            ),
          ],
        ),
      ),
      // ใช้ FutureBuilder เพื่อรอข้อมูลจาก API
      body: FutureBuilder<List<dynamic>>(
        future: fetchProjects(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("เกิดข้อผิดพลาด: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // แสดงหน้าเดิมหากไม่มีข้อมูล
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment, size: 100, color: Colors.grey),
                  Text("สวัสดีคุณ ${widget.userName}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text("ยังไม่มีโครงการ กดปุ่มด้านล่างเพื่อเพิ่ม"),
                ],
              ),
            );
          }

          // แสดงรายการโครงการที่ดึงมาจาก MySQL
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var project = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.business)),
                  title: Text(project['project_name']),
                  subtitle: Text("วันที่: ${project['project_date']} | ${project['project_detail'] ?? ''}"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // กดเพื่อดูรายการสินค้าในโครงการนี้ (ถ้าทำหน้าสรุปไว้)
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // นำทางไปหน้าเพิ่มโครงการ และรอให้กลับมาเพื่อ Refresh หน้าจอ
          await Navigator.push(context, MaterialPageRoute(builder: (context) => ProjectInfoScreen(userName: widget.userName)));
          setState(() {}); // สั่งให้ดึงข้อมูลใหม่หลังจากกลับมาหน้า Home
        },
        label: const Text("เพิ่มโครงการใหม่"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}