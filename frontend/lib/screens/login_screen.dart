import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'project_info_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  Future<void> login() async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/api/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": userCtrl.text, "password": passCtrl.text}),
    );
    if (response.statusCode == 200) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProjectInfoScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Login Failed!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Login", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            TextField(controller: userCtrl, decoration: const InputDecoration(labelText: "Username")),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: login, child: const Text("เข้าสู่ระบบ"))
          ],
        ),
      ),
    );
  }
}