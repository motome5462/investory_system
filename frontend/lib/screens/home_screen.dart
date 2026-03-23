import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'login_screen.dart';
import 'project_info_screen.dart';
import 'project_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final int userId;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<dynamic>> fetchProjects() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.201.93:3000/api/projects'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load projects');
      }
    } catch (e) {
      throw Exception('การเชื่อมต่อล้มเหลว: $e');
    }
  }

  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      DateTime dateTime = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }

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
      backgroundColor: const Color(0xFFF8FAFC), // พื้นหลังเทาอ่อนสะอาดตา
      appBar: AppBar(
        title: const Text(
          "Project Dashboard",
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          )
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade800, Colors.blue.shade500],
                ),
              ),
              accountName: Text(
                widget.userName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              accountEmail: const Text("Staff Member"),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 45, color: Colors.blue),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_rounded),
              title: const Text("Dashboard"),
              onTap: () => Navigator.pop(context),
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text("Sign Out", style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchProjects(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var project = snapshot.data![index];
                return _buildProjectCard(project);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
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
        label: const Text("New Project", style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
      ),
    );
  }

  Widget _buildProjectCard(dynamic project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProjectDetailScreen(
                  projectId: project['id'],
                  userName: widget.userName,
                ),
              ),
            ).then((_) => setState(() {}));
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon ตกแต่งด้านซ้าย
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(Icons.folder_rounded, color: Colors.blue.shade600, size: 28),
                ),
                const SizedBox(width: 16),
                // ข้อมูลโครงการ
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project['project_name'] ?? 'Untitled Project',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            formatDate(project['project_date']),
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.person_rounded, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              project['full_name'] ?? widget.userName,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Color(0xFFCBD5E1)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            'https://cdn-icons-png.flaticon.com/512/4076/4076432.png', // ภาพประกอบ Empty State
            width: 180,
            opacity: const AlwaysStoppedAnimation(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            "Hello, ${widget.userName}!",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "No projects found. Tap '+' to create one.",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 80, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text("Connection Error", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text("Try Again"),
            )
          ],
        ),
      ),
    );
  }
}