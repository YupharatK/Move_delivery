// receiver_delivery_list_screen.dart (อัปเดต: ใช้ Firebase)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:move_delivery/pages/User/Sender/delivery_tracking_screen.dart';

class ReceiverDeliveryListScreen extends StatefulWidget {
  const ReceiverDeliveryListScreen({super.key});

  @override
  State<ReceiverDeliveryListScreen> createState() =>
      _ReceiverDeliveryListScreenState();
}

class _ReceiverDeliveryListScreenState
    extends State<ReceiverDeliveryListScreen> {
  // --- (ลบ Mock Data ออก) ---

  // ✅ 1. สร้าง Query สำหรับดึงออเดอร์ที่ "เรา" เป็นผู้รับ
  Query<Map<String, dynamic>> _ordersQuery(String uid) => FirebaseFirestore
      .instance
      .collection('orders')
      .withConverter<Map<String, dynamic>>(
        fromFirestore: (s, _) => s.data() ?? <String, dynamic>{},
        toFirestore: (m, _) => m,
      )
      // ⭐️ ค้นหาออเดอร์ที่ 'receiverId' คือ UID ของเรา
      .where('receiverId', isEqualTo: uid)
      .orderBy('createdAt', descending: true); // เรียงจากใหม่ไปเก่า

  @override
  Widget build(BuildContext context) {
    // ✅ 2. ดึงข้อมูลผู้ใช้ปัจจุบัน
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'รายการจัดส่ง',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      // ✅ 3. เปลี่ยนจาก ListView.builder ธรรมดามาเป็น StreamBuilder
      body: user == null
          ? const Center(child: Text('กรุณาเข้าสู่ระบบ'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _ordersQuery(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('ไม่มีรายการพัสดุที่รอรับ'));
                }

                // ✅ 4. ใช้ ListView.builder แสดงผลข้อมูลจาก Stream
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    // ✅ 5. ส่งข้อมูลไปให้ _OrderCard Widget ใหม่
                    return _OrderCard(orderId: doc.id, order: doc.data());
                  },
                );
              },
            ),
      // --- BottomNavigationBar (เหมือนเดิม) ---
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'หน้าแรก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox_outlined),
            activeIcon: Icon(Icons.inbox),
            label: 'ที่ต้องได้รับ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'โปรไฟล์',
          ),
        ],
        currentIndex: 1,
        // TODO: ใส่ navigation logic สำหรับ BottomNav ที่นี่
        onTap: (index) {},
        backgroundColor: Theme.of(context).primaryColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.7),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // (ลบ _buildIncomingItemCard ของเดิมทิ้ง)
}

// ✅ 6. สร้าง _OrderCard Widget ใหม่ (คล้ายกับฝั่ง Sender)
/// Card ที่แสดงข้อมูลออเดอร์ 1 รายการ
/// โดยจะดึงข้อมูล 'ผู้ส่ง (Sender)' และ 'สินค้าชิ้นแรก (Item)' มาแสดง
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.orderId, required this.order});
  final String orderId;
  final Map<String, dynamic> order;

  /// ดึงข้อมูลสินค้าชิ้นแรกจาก subcollection
  Future<Map<String, dynamic>?> _fetchFirstItem() async {
    final qs = await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .collection('items')
        .limit(1)
        .get();
    if (qs.docs.isEmpty) return null;
    return qs.docs.first.data();
  }

  /// ดึงข้อมูล "ผู้ส่ง" (Sender) จาก 'userId' ในออเดอร์
  Future<Map<String, dynamic>?> _fetchSender() async {
    // ⭐️ ใช้ 'userId' (รหัสผู้ส่ง) ที่อยู่ในออเดอร์
    final uid = (order['userId'] ?? '').toString();
    if (uid.isEmpty) return null;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return doc.data();
  }

  /// ดึงที่อยู่ (Address) จากข้อมูล User (ในที่นี้คือ Sender)
  String _extractAddressText(Map<String, dynamic>? senderData) {
    if (senderData == null) return '-';
    final List<dynamic> addresses =
        (senderData['addresses'] as List<dynamic>? ?? []);
    if (addresses.isNotEmpty && addresses.first is Map) {
      final a = (addresses.first as Map).cast<String, dynamic>();
      final label = (a['label'] ?? '-') as String;
      final addressText = (a['address'] ?? '-') as String;
      if (label != '-' && addressText != '-') {
        return '$label • $addressText';
      } else if (addressText != '-') {
        return addressText;
      } else if (label != '-') {
        return label;
      }
    }
    return '-';
  }

  /// รูปภาพสำรอง
  Widget _imgFallback() => Container(
    width: 80,
    height: 80,
    color: Colors.grey[200],
    child: const Icon(Icons.image),
  );

  @override
  Widget build(BuildContext context) {
    final status = (order['status'] ?? '-').toString();

    // ✅ 7. ใช้ FutureBuilder รอข้อมูล 2 ส่วน (Item และ Sender)
    return FutureBuilder<List<Map<String, dynamic>?>>(
      // ⭐️ รอ Future 2 ตัวพร้อมกัน
      future: Future.wait([_fetchFirstItem(), _fetchSender()]),
      builder: (context, snap) {
        // --- จัดการสถานะ Loading / Error ของ Future ---
        if (snap.connectionState == ConnectionState.waiting) {
          return const Card(
            margin: EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        }
        if (snap.hasError) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: ${snap.error}'),
            ),
          );
        }
        // --- จบการจัดการสถานะ ---

        // ดึงข้อมูลจากผลลัพธ์ Future
        final firstItem = (snap.data != null && snap.data!.isNotEmpty)
            ? snap.data![0]
            : null;
        final sender = (snap.data != null && snap.data!.length > 1)
            ? snap.data![1]
            : null;

        // ดึงข้อมูล Item
        final itemName = (firstItem?['name'] ?? '—').toString();
        final itemImg = (firstItem?['imageUrl'] ?? '').toString();

        // ⭐️ ดึงข้อมูล Sender (ตามข้อ 3.1.2)
        final senderName = (sender?['name'] ?? '—').toString();
        final senderPhone = (sender?['phone'] ?? '—').toString();
        final senderAddress = _extractAddressText(sender); // ดึงที่อยู่ Sender

        // ✅ 8. สร้าง Card โดยใช้ข้อมูลจริง
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // รูปสินค้า
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: (itemImg.isNotEmpty)
                          // ⭐️ ใช้ Image.network
                          ? Image.network(
                              itemImg,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _imgFallback(),
                            )
                          : _imgFallback(),
                    ),
                    const SizedBox(width: 12),
                    // รายละเอียด
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'รายละเอียดการจัดส่ง',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              // ⭐️ (Bonus) แสดงสถานะปัจจุบัน (ตามข้อ 3.1.3)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey.withOpacity(.08),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueGrey[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('รายการ : $itemName'),
                          Text('ผู้ส่ง : $senderName'), // ⭐️ ข้อมูลจริง
                          Text('เบอร์โทร : $senderPhone'), // ⭐️ ข้อมูลจริง
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Theme.of(context).primaryColor,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  senderAddress, // ⭐️ ข้อมูลจริง
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // ปุ่มดูสถานะ
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      // ✅ 9. แก้ไข: ส่ง orderId จริงไปหน้า Tracking
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DeliveryTrackingScreen(orderId: orderId),
                        ),
                      );
                    },
                    child: const Text('ดูสถานะการจัดส่ง'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
