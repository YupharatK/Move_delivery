import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:move_delivery/pages/User/myaddressesscreen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildUserProfile(context),
          const Divider(height: 1),
          _buildMenuListItem(
            context: context,
            title: 'ที่อยู่ของฉัน',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyAddressesScreen()),
              );
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
            textColor: Colors.red,
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              // TODO: นำทางกลับไปหน้า Login ของคุณ
            },
          ),
        ],
      ),
    );
  }

  /// เฮดเดอร์โปรไฟล์: ดึงข้อมูลจริงจาก Firestore (users/{uid})
  Widget _buildUserProfile(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Container(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Row(
          children: const [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 35, color: Colors.white),
            ),
            SizedBox(width: 16),
            Text(
              'ไม่ได้เข้าสู่ระบบ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid);

    return StreamBuilder<DocumentSnapshot>(
      stream: userDoc.snapshots(),
      builder: (context, snap) {
        final bg = Theme.of(context).primaryColor.withOpacity(0.1);

        if (snap.connectionState == ConnectionState.waiting) {
          return Container(
            color: bg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Row(
              children: const [
                CircleAvatar(radius: 30, backgroundColor: Colors.grey),
                SizedBox(width: 16),
                SizedBox(
                  height: 18,
                  width: 120,
                  child: LinearProgressIndicator(),
                ),
              ],
            ),
          );
        }

        if (!snap.hasData || !snap.data!.exists) {
          return Container(
            color: bg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Row(
              children: const [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 35, color: Colors.white),
                ),
                SizedBox(width: 16),
                Text(
                  'ไม่พบข้อมูลผู้ใช้',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }

        final data = snap.data!.data() as Map<String, dynamic>;
        final name = (data['name'] ?? '-') as String;
        final phone = (data['phone'] ?? '-') as String;
        final photoUrl = (data['userPhotoUrl'] ?? '') as String;

        return Container(
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey,
                backgroundImage: photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl.isEmpty
                    ? const Icon(Icons.person, size: 35, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'เบอร์โทรศัพท์ $phone',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuListItem({
    required BuildContext context,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor ?? Colors.black,
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
