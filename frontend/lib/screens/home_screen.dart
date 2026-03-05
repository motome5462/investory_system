import 'package:flutter/material.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'project_info_screen.dart';
import 'project_detail_screen.dart'; // อย่าลืมสร้างและ import ไฟล์นี้
import 'package:intl/intl.dart';

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

  // ฟังก์ชันจัดรูปแบบวันที่จาก DB ให้เป็น dd/MM/yyyy
  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      DateTime dateTime = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }

  // ฟังก์ชันจัดรูปแบบเวลา (ตัดวินาทีออก)
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
              padding: const EdgeInsets.all(10),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var project = snapshot.data![index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.business, color: Colors.white),
                    ),
                    title: Text(
                      project['project_name'] ?? 'ไม่มีชื่อโครงการ',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: Colors.blueGrey),
                            const SizedBox(width: 6),
                            Text("วันที่: ${formatDate(project['project_date'])}"),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Colors.blueGrey),
                            const SizedBox(width: 6),
                            Text("เวลา: ${formatTime(project['project_time'])} น."),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 14, color: Colors.blueGrey),
                            const SizedBox(width: 6),
                            Text("ผู้บันทึก: ${project['full_name'] ?? widget.userName}"),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.blue),
                    onTap: () async {
                      // นำทางไปหน้าละเอียดโครงการ และส่ง projectId ไป
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProjectDetailScreen(
                            projectId: project['id'], 
                            userName: widget.userName
                          ),
                        ),
                      );
                      setState(() {}); // รีเฟรชข้อมูลเมื่อกลับมาจากหน้าแก้ไข
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
          await Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => ProjectInfoScreen(userName: widget.userName))
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