import 'package:flutter/material.dart';
import 'package:move_delivery/pages/select_role_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar แบบง่ายๆ ที่มีแค่ปุ่มย้อนกลับ
      appBar: AppBar(
        backgroundColor: Colors.white,
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
              // ส่วนหัวข้อ
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

              // รูปภาพประกอบ
              Center(
                child: Image.asset(
                  'assets/images/pack.png', // TODO: อย่าลืมใส่รูปภาพของคุณใน assets
                  height: 250,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),

              // ช่องกรอกเบอร์โทรศัพท์
              const Text(
                'หมายเลขโทรศัพท์',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 20),

              // ช่องกรอกรหัสผ่าน
              const Text(
                'รหัสผ่าน',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 40),

              // ปุ่มเข้าสู่ระบบ
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: ใส่ Logic การ Login
                  },
                  child: const Text('เข้าสู่ระบบ'),
                ),
              ),
              const SizedBox(height: 24),

              // ลิงก์สำหรับสมัครสมาชิก
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

  // ฟังก์ชันสำหรับตกแต่ง TextFormField เพื่อลดการเขียนโค้ดซ้ำ
  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey[200],
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none, // ทำให้ไม่มีเส้นขอบ
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).primaryColor, // มีเส้นขอบสีเขียวเมื่อ focus
          width: 2,
        ),
      ),
    );
  }
}
