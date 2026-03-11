import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool _isLoading = false; // สำหรับแสดงสถานะการโหลด

  Future<void> login() async {
    // ตรวจสอบว่ากรอกข้อมูลครบถ้วนหรือไม่
    if (userCtrl.text.isEmpty || passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณากรอก Username และ Password")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/login'), // สำหรับ Emulator Android
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": userCtrl.text, 
          "password": passCtrl.text
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // ตรวจสอบข้อมูลที่ได้รับจาก API
        String nameFromApi = data['full_name'] ?? userCtrl.text;
        int idFromApi = data['user_id'] ?? 0; // รับ userId จาก Backend

        if (!mounted) return;

        // นำข้อมูลไปใช้ในหน้า HomeScreen
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              userName: nameFromApi,
              userId: idFromApi, // ส่ง userId ไปยังหน้า Home
            ),
          ),
        );
      } else {
        // กรณี Login ไม่สำเร็จ
        final errorData = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['message'] ?? "Login Failed!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาดในการเชื่อมต่อ: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // โลโก้แอป
              const Icon(Icons.inventory, size: 100, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                "ระบบเบิกสินค้า", 
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text("กรุณาเข้าสู่ระบบเพื่อใช้งาน", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),

              // ช่องกรอก Username
              TextField(
                controller: userCtrl, 
                decoration: const InputDecoration(
                  labelText: "Username", 
                  prefixIcon: Icon(Icons.person), 
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFFF5F5F5),
                ),
              ),
              const SizedBox(height: 20),

              // ช่องกรอก Password
              TextField(
                controller: passCtrl, 
                decoration: const InputDecoration(
                  labelText: "Password", 
                  prefixIcon: Icon(Icons.lock), 
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFFF5F5F5),
                ), 
                obscureText: true,
              ),
              const SizedBox(height: 30),

              // ปุ่มเข้าสู่ระบบ
              SizedBox(
                width: double.infinity, 
                height: 55, 
                child: ElevatedButton(
                  onPressed: _isLoading ? null : login, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("เข้าสู่ระบบ", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}