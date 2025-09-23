import 'package:flutter/material.dart';
import 'package:move_delivery/pages/register_rider_screen.dart';
import 'package:move_delivery/pages/register_user_screen.dart';

class SelectRoleScreen extends StatelessWidget {
  const SelectRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // AppBar จะใช้สีตาม theme ที่เราตั้งไว้ (พื้นหลังขาว, ไอคอนดำ)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'เลือกสมัครตาม\nความต้องการของคุณ',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'คุณคือใคร ?',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),

            Center(
              child: Image.asset(
                'assets/images/p.png',
                width: 200,
                height: 200,
              ),
            ),

            const SizedBox(height: 40),

            // ปุ่มเลือก "ผู้ใช้งานทั่วไป"
            _buildRoleButton(
              context: context,
              icon: Icons.person, // ไอคอนชั่วคราว
              label: 'ผู้ใช้งานทั่วไป',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterUserScreen(),
                  ),
                );
                print('Tapped User');
              },
            ),
            const SizedBox(height: 50),

            // ปุ่มเลือก "ไรเดอร์"
            _buildRoleButton(
              context: context,
              icon: Icons.moped, // ไอคอนชั่วคราว
              label: 'ไรเดอร์',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterRiderScreen(),
                  ),
                );
                print('Tapped Rider');
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget สำหรับสร้างปุ่มเลือก Role เพื่อลดการเขียนโค้ดซ้ำ
  Widget _buildRoleButton({
    required BuildContext context,
    required IconData icon, // เปลี่ยนเป็น ImageProvider ถ้าใช้รูป
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(width: 20),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
