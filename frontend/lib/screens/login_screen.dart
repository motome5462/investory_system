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

  Future<void> login() async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": userCtrl.text, "password": passCtrl.text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String nameFromApi = data['full_name'] ?? userCtrl.text;
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (context) => HomeScreen(userName: nameFromApi),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Login Failed!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text("ระบบเบิกสินค้า", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            TextField(controller: userCtrl, decoration: const InputDecoration(labelText: "Username", prefixIcon: Icon(Icons.person), border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: "Password", prefixIcon: Icon(Icons.lock), border: OutlineInputBorder()), obscureText: true),
            const SizedBox(height: 25),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: login, child: const Text("เข้าสู่ระบบ"))),
          ],
        ),
      ),
    );
  }
}