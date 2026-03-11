import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
// Import หน้าที่เกี่ยวข้อง
import 'login_screen.dart';
import 'project_info_screen.dart';
import 'project_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final int userId; // เพิ่ม userId เพื่อรองรับ Constructor ใหม่ของ ProjectInfoScreen

  const HomeScreen({
    super.key, 
    required this.userName, 
    required this.userId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
  // ฟังก์ชันดึงข้อมูลโครงการจาก API
  Future<List<dynamic>> fetchProjects() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:3000/api/projects'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load projects');
      }
    } catch (e) {
      throw Exception('การเชื่อมต่อล้มเหลว: $e');
    }
  }

  // ฟังก์ชันจัดรูปแบบวันที่
  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      DateTime dateTime = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }

  // ฟังก์ชันจัดรูปแบบเวลา
  String formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '-';
    if (timeStr.contains(':') && timeStr.length >= 5) {
      return timeStr.substring(0, 5);
    }
    return timeStr;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("รายการโครงการ"),
        centerTitle: true,
        elevation: 2,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(widget.userName),
              accountEmail: const Text("เจ้าหน้าที่บันทึกข้อมูล"),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.blue),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("ออกจากระบบ"),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchProjects(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("เกิดข้อผิดพลาด: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment_late_outlined, size: 100, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text("สวัสดีคุณ ${widget.userName}", 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text("ยังไม่มีโครงการในระบบ กดปุ่มด้านล่างเพื่อเพิ่ม"),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var project = snapshot.data![index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.business_center, color: Colors.blue, size: 30),
                    ),
                    title: Text(
                      project['project_name'] ?? 'ไม่มีชื่อโครงการ',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text("วันที่: ${formatDate(project['project_date'])}"),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text("ผู้บันทึก: ${project['full_name'] ?? widget.userName}"),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.blue),
                    onTap: () {
                      // ส่ง projectId ไปยังหน้าแสดงรายละเอียด
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProjectDetailScreen(
                            projectId: project['id'], 
                            userName: widget.userName,
                          ),
                        ),
                      ).then((_) => setState(() {})); // รีเฟรชหน้า Home เมื่อกลับมา
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // แก้ไขจุดนี้: ส่ง userId ไปด้วยเพื่อให้ ProjectInfoScreen ทำงานได้
          await Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (context) => ProjectInfoScreen(
                userName: widget.userName,
                userId: widget.userId,
              ),
            ),
          );
          setState(() {}); 
        },
        label: const Text("เพิ่มโครงการใหม่"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}