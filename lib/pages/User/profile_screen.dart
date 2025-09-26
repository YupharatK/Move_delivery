import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // เราไม่ต้องใช้ Scaffold ที่นี่ เพราะหน้าหลัก (DeliveryMainScreen) มีให้อยู่แล้ว
    return Container(
      color: Colors.white, // กำหนดสีพื้นหลังเป็นสีขาว
      child: Column(
        children: [
          // --- 1. ส่วนข้อมูลผู้ใช้ ---
          _buildUserProfile(context),
          const Divider(height: 1), // เส้นคั่น
          // --- 2. รายการเมนู ---
          _buildMenuListItem(
            context: context,
            title: 'ที่อยู่ของฉัน',
            onTap: () {
              // TODO: ไปหน้าจัดการที่อยู่
            },
          ),
          _buildMenuListItem(
            context: context,
            title: 'แก้ไขโปรไฟล์',
            onTap: () {
              // TODO: ไปหน้าแก้ไขโปรไฟล์
            },
          ),
          _buildMenuListItem(
            context: context,
            title: 'ออกจากระบบ',
            textColor: Colors.red, // ทำให้เป็นสีแดง
            onTap: () {
              // TODO: Logic การออกจากระบบ
            },
          ),
        ],
      ),
    );
  }

  // Widget สำหรับสร้างส่วนข้อมูลผู้ใช้
  Widget _buildUserProfile(BuildContext context) {
    return Container(
      color: Theme.of(
        context,
      ).primaryColor.withOpacity(0.1), // สีพื้นหลังฟ้าอ่อนๆ
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, size: 35, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Mike',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'เบอร์โทรศัพท์ 0922222222',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget สำหรับสร้างรายการเมนูแต่ละอัน
  Widget _buildMenuListItem({
    required BuildContext context,
    required String title,
    required VoidCallback onTap,
    Color? textColor, // Parameter เสริมสำหรับเปลี่ยนสีตัวอักษร
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor ?? Colors.black, // ใช้สีแดงถ้ามีการส่งค่ามา
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}
