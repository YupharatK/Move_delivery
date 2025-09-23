import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex; // รับค่า index ที่ถูกเลือกมาจากหน้าแม่
  final Function(int)
  onTap; // รับฟังก์ชันที่จะทำงานเมื่อมีการกดปุ่มมาจากหน้าแม่

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // ย้ายโค้ด BottomNavigationBar ทั้งหมดมาไว้ที่นี่
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'หน้าแรก',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt_outlined),
          activeIcon: Icon(Icons.list_alt),
          label: 'การจัดส่ง',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'โปรไฟล์',
        ),
      ],
      currentIndex: currentIndex, // ใช้ค่าที่รับเข้ามา
      onTap: onTap, // ใช้ฟังก์ชันที่รับเข้ามา
      // การตกแต่ง (เหมือนเดิม)
      backgroundColor: Theme.of(context).primaryColor,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white.withOpacity(0.7),
      selectedFontSize: 12,
      unselectedFontSize: 12,
      type: BottomNavigationBarType.fixed,
    );
  }
}
