import 'package:flutter/material.dart';

class RiderAppBar extends StatelessWidget implements PreferredSizeWidget {
  const RiderAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey,
              // TODO: ใส่รูปโปรไฟล์ไรเดอร์
              child: Icon(Icons.person, size: 30, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'มีนัด แล้วจ้า', // TODO: ใส่ชื่อไรเดอร์จริง
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'เบอร์โทร : 039474333 | ทะเบียนรถ : 887', // TODO: ใส่ข้อมูลจริง
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const Spacer(), // ดันไอคอนไปทางขวา
            IconButton(
              onPressed: () {
                // TODO: ใส่ Logic การ Logout
              },
              icon: Icon(Icons.logout, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  // กำหนดความสูงของ AppBar
  Size get preferredSize => const Size.fromHeight(60.0);
}
