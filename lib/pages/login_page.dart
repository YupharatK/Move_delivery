import 'package:cloud_firestore/cloud_firestore.dart'; // [เพิ่ม] import Firestore
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:move_delivery/pages/Rider/rider_new_order_screen.dart';
import 'package:move_delivery/pages/User/delivery_main_screen.dart';
import 'package:move_delivery/pages/select_role_page.dart';
// import 'package:move_delivery/services/api_service.dart'; // [ลบ] ไม่ใช้แล้ว

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // [เปลี่ยน] ใช้ Email Controller เพื่อความชัดเจน
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // final _apiService = ApiService(); // [ลบ] ไม่ใช้แล้ว
  bool _isLoading = false;

  // [เปลี่ยน] ปรับปรุงฟังก์ชัน Login ทั้งหมด
  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorSnackBar('กรุณากรอกอีเมลและรหัสผ่าน');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. ใช้ Firebase SDK ในการ Login (เหมือนเดิม)
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user;
      if (user == null) {
        _showErrorSnackBar('เกิดข้อผิดพลาดในการยืนยันตัวตน');
        return;
      }

      // 2. [หัวใจของการเปลี่ยนแปลง] ค้นหา Role ของผู้ใช้จาก Firestore
      // เราจะลองค้นหาใน collection 'users' ก่อน
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        // ถ้าเจอใน 'users' -> นำทางไปหน้า User
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const DeliveryMainScreen()),
          (route) => false,
        );
      } else {
        // ถ้าไม่เจอใน 'users' -> ลองค้นหาใน collection 'riders'
        final riderDoc = await FirebaseFirestore.instance
            .collection('riders')
            .doc(user.uid)
            .get();
        if (riderDoc.exists) {
          // ถ้าเจอใน 'riders' -> นำทางไปหน้า Rider
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const RiderNewOrderScreen(),
            ),
            (route) => false,
          );
        } else {
          // ถ้าไม่เจอทั้ง 2 ที่ -> แสดงข้อผิดพลาด
          _showErrorSnackBar('ไม่พบข้อมูลโปรไฟล์ผู้ใช้ในระบบ');
        }
      }
    } on FirebaseAuthException catch (e) {
      // จัดการ Error จาก Firebase Auth (เหมือนเดิม)
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        _showErrorSnackBar('อีเมลหรือรหัสผ่านไม่ถูกต้อง');
      } else {
        _showErrorSnackBar('เกิดข้อผิดพลาด: ${e.message}');
      }
    } catch (e) {
      // จัดการ Error ทั่วไป
      _showErrorSnackBar('เกิดข้อผิดพลาดที่ไม่คาดคิด กรุณาลองใหม่อีกครั้ง');
      print(e);
    } finally {
      // ตรวจสอบ mounted ก่อนเรียก setState เสมอใน async operation
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, // ทำให้ AppBar โปร่งใส
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ยินดีต้อนรับ !!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'ลงชื่อเข้าใช้ด้วยบัญชีของคุณ',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              // [เปลี่ยน] ใช้ controller ที่เปลี่ยนชื่อ
              const Text(
                'อีเมล',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController, // เปลี่ยน
                keyboardType: TextInputType.emailAddress, // เปลี่ยน
                decoration: _inputDecoration().copyWith(
                  hintText: 'กรอกอีเมลของคุณ',
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'รหัสผ่าน',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: _inputDecoration().copyWith(
                  hintText: 'กรอกรหัสผ่าน',
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('เข้าสู่ระบบ'),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('คุณยังไม่มีบัญชีใช่หรือไม่? '),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SelectRoleScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'สมัครที่นี่',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey[200],
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
    );
  }
}
