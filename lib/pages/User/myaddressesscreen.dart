import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyAddressesScreen extends StatelessWidget {
  const MyAddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ที่อยู่ของฉัน')),
        body: const Center(child: Text('กรุณาเข้าสู่ระบบก่อน')),
      );
    }

    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    return Scaffold(
      appBar: AppBar(title: const Text('ที่อยู่ของฉัน')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: userDocRef.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('ไม่พบข้อมูลผู้ใช้'));
          }

          final data = snap.data!.data() as Map<String, dynamic>;
          final List<dynamic> addresses = (data['addresses'] ?? []) as List;

          if (addresses.isEmpty) {
            return const Center(child: Text('ยังไม่มีที่อยู่ในบัญชีของคุณ'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final addr = (addresses[i] as Map).cast<String, dynamic>();

              final label = (addr['label'] ?? '-') as String;
              final addressText = (addr['address'] ?? '-') as String;

              // รองรับ location ได้ทั้งแบบ [lat, lng] หรือ GeoPoint
              String coordsText = '';
              final loc = addr['location'];
              if (loc is List && loc.length >= 2) {
                coordsText = '(${loc[0]}, ${loc[1]})';
              } else if (loc is GeoPoint) {
                coordsText = '(${loc.latitude}, ${loc.longitude})';
              }

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.home, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ชื่อประเภทที่อยู่ เช่น "ที่อยู่หลัก"
                          Text(label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          // ที่อยู่ข้อความ
                          Text(addressText,
                              style: TextStyle(color: Colors.grey[700])),
                          if (coordsText.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(coordsText,
                                    style:
                                        TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
