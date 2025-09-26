import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:move_delivery/pages/Rider/rider_new_order_screen.dart';
import 'package:move_delivery/pages/User/delivery_main_screen.dart';
import 'package:move_delivery/pages/select_role_page.dart';
import 'package:move_delivery/services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService(); // สร้าง instance ของ ApiService
  bool _isLoading = false;

  // ฟังก์ชันสำหรับจัดการ Logic การ Login
  Future<void> _login() async {
    // ตรวจสอบว่าผู้ใช้กรอกข้อมูลครบหรือไม่
    if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorSnackBar('กรุณากรอกอีเมลและรหัสผ่าน');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. ใช้ Firebase SDK ในการ Login
      // ⚠️ ข้อควรระวัง: Firebase ไม่มี signInWithPhoneNumberAndPassword โดยตรง
      // เราจึงต้องใช้ signInWithEmailAndPassword แทน
      // ซึ่งหมายความว่าตอนสมัครสมาชิก คุณต้องสมัครด้วย "เบอร์โทรศัพท์" ในช่อง "อีเมล"
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _phoneController.text.trim(), // ส่งเบอร์โทรไปใน parameter email
        password: _passwordController.text.trim(),
      );

      // 2. ตรวจสอบว่า Login สำเร็จและมี user object หรือไม่
      if (credential.user != null) {
        // 3. เรียก ApiService เพื่อดึงข้อมูลโปรไฟล์จาก Backend
        final userProfile = await _apiService.getUserProfile();

        if (userProfile != null) {
          // 4. นำทางไปยังหน้าที่เหมาะสมตาม role
          // ใช้ mounted เพื่อเช็คว่า widget ยังอยู่ใน tree ก่อนเรียก context
          if (!mounted) return;

          if (userProfile.role == 'rider') {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const RiderNewOrderScreen(),
              ),
              (route) => false,
            );
          } else if (userProfile.role == 'user') {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const DeliveryMainScreen(),
              ),
              (route) => false,
            );
          } else {
            // กรณีมี role อื่นๆ หรือไม่มี role
            _showErrorSnackBar('ไม่พบ role ของผู้ใช้');
          }
        } else {
          _showErrorSnackBar('ไม่พบข้อมูลโปรไฟล์ผู้ใช้ในระบบ');
        }
      }
    } on FirebaseAuthException catch (e) {
      // จัดการ Error จาก Firebase Auth
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        _showErrorSnackBar('เบอร์โทรศัพท์หรือรหัสผ่านไม่ถูกต้อง');
      } else {
        _showErrorSnackBar('เกิดข้อผิดพลาด: ${e.message}');
      }
    } catch (e) {
      // จัดการ Error ทั่วไป
      _showErrorSnackBar('เกิดข้อผิดพลาดที่ไม่คาดคิด กรุณาลองใหม่อีกครั้ง');
      print(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ฟังก์ชันสำหรับแสดง SnackBar แจ้งเตือน
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
                'อีเมล',
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
                  onPressed: _isLoading ? null : _login, // ปิดปุ่มระหว่างโหลด
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('เข้าสู่ระบบ'),
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
