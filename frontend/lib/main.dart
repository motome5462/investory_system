import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart'; // เพิ่มไฟล์หน้า Dashboard
import 'screens/project_info_screen.dart';

void main() {
  runApp(const InventoryApp());
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inventory System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),
      ),
      // กำหนดหน้าแรกเป็น Login
      home: const LoginScreen(),
      
      // (ทางเลือก) กำหนด Routes เพื่อเรียกใช้ง่ายๆ
      routes: {
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}