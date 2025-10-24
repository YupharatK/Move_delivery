// rider_app_bar.dart (อัปเดต: ดึงข้อมูลไรเดอร์จริง)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:move_delivery/pages/welcome_screen.dart';

class RiderAppBar extends StatefulWidget implements PreferredSizeWidget {
  const RiderAppBar({super.key});

  @override
  State<RiderAppBar> createState() => _RiderAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(60.0);
}

class _RiderAppBarState extends State<RiderAppBar> {
  // ⭐️ สถานะสำหรับเก็บข้อมูลไรเดอร์
  Map<String, dynamic>? _riderData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRiderData();
  }

  /// ⭐️ ดึงข้อมูลผู้ใช้ (ไรเดอร์) ที่ล็อกอินอยู่
  Future<void> _fetchRiderData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted) {
        setState(() {
          _riderData = doc.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch rider data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⭐️ แยกข้อมูลมาแสดง
    final name = (_riderData?['name'] ?? 'Rider').toString();
    final phone = (_riderData?['phone'] ?? '...').toString();
    final vehicle = (_riderData?['vehicleRegistration'] ?? '...').toString();
    final photoUrl = (_riderData?['userPhotoUrl'] ?? '').toString();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[300],
              backgroundImage: (photoUrl.isNotEmpty)
                  ? NetworkImage(photoUrl)
                  : null,
              child: (photoUrl.isEmpty && !_isLoading)
                  ? const Icon(Icons.person, size: 30, color: Colors.white)
                  : (_isLoading ? const CircularProgressIndicator() : null),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isLoading ? 'Loading...' : name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isLoading
                      ? '...'
                      : 'เบอร์โทร : $phone | ทะเบียนรถ : $vehicle',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              onPressed: () async {
                try {
                  // 1. สั่ง Sign Out
                  await FirebaseAuth.instance.signOut();

                  // 2. (สำคัญ) ตรวจสอบ mounted ก่อนใช้ context ข้าม async
                  if (!context.mounted) return;

                  // 3. นำทางกลับไปหน้า Login และ "ลบ" ทุกหน้าเก่าทิ้ง
                  // (ป้องกันการกด Back กลับมาหน้า Rider)
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      // ⭐️⭐️ (เปลี่ยน 'LoginPage' เป็นชื่อ Class หน้า Login ของคุณ) ⭐️⭐️
                      builder: (context) => const WelcomeScreen(),
                    ),
                    (Route<dynamic> route) =>
                        false, // (ลบทุก Route ที่ค้างอยู่)
                  );
                } catch (e) {
                  // (Optional) แสดง Error หาก Logout ล้มเหลว
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Logout ล้มเหลว: $e')));
                }
              },
              icon: Icon(Icons.logout, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
