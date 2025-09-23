import 'package:flutter/material.dart';
import 'package:move_delivery/pages/welcome_screen.dart';

class UserAppBar extends StatelessWidget implements PreferredSizeWidget {
  const UserAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    // ใช้ SafeArea เพื่อให้แน่ใจว่า UI จะไม่โดนขอบบนของจอ (Notch) บัง
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            // ส่วนข้อมูลผู้ใช้ (ด้านซ้าย)
            const CircleAvatar(
              radius: 24, // ปรับขนาดให้เล็กลงเล็กน้อยสำหรับ AppBar
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 30, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Mike',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                // ส่วนของตำแหน่งที่อยู่
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Mahasarakham',
                      style: TextStyle(color: Colors.grey[800], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),

            const Spacer(), // Spacer() คือตัวทีเด็ด! มันจะดันทุกอย่างไปสุดขอบซ้าย-ขวา
            // ไอคอนออกจากระบบ (ด้านขวา)
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WelcomeScreen(),
                  ),
                );
                print('Logout tapped');
              },
              icon: Icon(Icons.logout, color: Colors.grey[700], size: 28),
            ),
          ],
        ),
      ),
    );
  }

  @override
  // กำหนดความสูงของ AppBar ที่เราสร้างขึ้น
  Size get preferredSize => const Size.fromHeight(70.0);
}
