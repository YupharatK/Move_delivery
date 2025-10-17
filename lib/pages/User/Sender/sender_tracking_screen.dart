import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:move_delivery/pages/User/Sender/delivery_tracking_screen.dart';
import 'package:move_delivery/pages/User/Sender/sender_confirm_screen.dart';
import 'package:move_delivery/pages/User/Sender/sender_tracking_screen.dart';

class SenderTrackingListScreen extends StatefulWidget {
  const SenderTrackingListScreen({super.key});

  @override
  State<SenderTrackingListScreen> createState() =>
      _SenderTrackingListScreenState();
}

class _SenderTrackingListScreenState extends State<SenderTrackingListScreen> {
  Query<Map<String, dynamic>> _ordersQuery(String uid) => FirebaseFirestore
      .instance
      .collection('orders')
      .withConverter<Map<String, dynamic>>(
        fromFirestore: (s, _) => s.data() ?? <String, dynamic>{},
        toFirestore: (m, _) => m,
      )
      .where('userId', isEqualTo: uid)
      .orderBy(FieldPath.documentId, descending: true); // กัน createdAt เพี้ยน

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('ติดตามสถานะการส่งของฉัน')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: user == null
            ? const Center(child: Text('กรุณาเข้าสู่ระบบ'))
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _ordersQuery(user.uid).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Firestore error: ${snapshot.error}'),
                    );
                  }
                  final orders = snapshot.data?.docs ?? [];
                  if (orders.isEmpty) {
                    return const Center(
                      child: Text('ยังไม่มีคำสั่งซื้อของคุณ'),
                    );
                  }

                  return ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final d = orders[index];
                      final orderId = d.id;
                      final order = d.data();
                      return _OrderCard(orderId: orderId, order: order);
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.orderId, required this.order});
  final String orderId;
  final Map<String, dynamic> order;

  Future<Map<String, dynamic>?> _fetchFirstItem() async {
    final qs = await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .collection('items')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (s, _) => s.data() ?? <String, dynamic>{},
          toFirestore: (m, _) => m,
        )
        .limit(1)
        .get();
    if (qs.docs.isEmpty) return null;
    return qs.docs.first.data();
  }

  Future<Map<String, dynamic>?> _fetchReceiver() async {
    final rid = (order['receiverId'] ?? '').toString();
    if (rid.isEmpty) return null;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(rid)
        .get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    final status = (order['status'] ?? '-').toString();
    final total = (order['total'] is num)
        ? (order['total'] as num).toDouble()
        : 0.0;
    final itemCount = (order['itemCount'] is num)
        ? (order['itemCount'] as num).toInt()
        : 1;
    final ts = order['createdAt'];
    final createdAt = (ts is Timestamp) ? ts.toDate() : null;

    // ฟิลด์รูปยืนยันจากผู้ส่ง (ถ้ามีถือว่ายืนยันแล้ว)
    final String senderPhotoUrl = (order['senderPhotoUrl'] ?? '').toString();
    final bool isConfirmedBySender = senderPhotoUrl.isNotEmpty;

    return FutureBuilder<List<Map<String, dynamic>?>>(
      future: Future.wait([_fetchFirstItem(), _fetchReceiver()]),
      builder: (context, snap) {
        final firstItem = (snap.data != null) ? snap.data![0] : null;
        final receiver = (snap.data != null) ? snap.data![1] : null;

        final name = (firstItem?['name'] ?? '—').toString();
        final img = (firstItem?['imageUrl'] ?? '').toString();
        final receiverName = (receiver?['name'] ?? '—').toString();
        final receiverPhone = (receiver?['phone'] ?? '—').toString();

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // รูปสินค้าแรก
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (img.isNotEmpty)
                      ? Image.network(
                          img,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imgFallback(),
                        )
                      : _imgFallback(),
                ),
                const SizedBox(width: 12),
                // เนื้อหา
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // แถวหัวเรื่อง + สถานะ
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
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'สินค้า: $name${itemCount > 1 ? " (+${itemCount - 1} ชิ้น)" : ""}',
                      ),
                      Text('ผู้รับ: $receiverName'),
                      Text('เบอร์โทร: $receiverPhone'),
                      Text('ยอดรวม: ${total.toStringAsFixed(2)} ฿'),
                      if (createdAt != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${createdAt.day.toString().padLeft(2, '0')}/'
                              '${createdAt.month.toString().padLeft(2, '0')}/'
                              '${createdAt.year} '
                              '${createdAt.hour.toString().padLeft(2, '0')}:'
                              '${createdAt.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),

                      // ปุ่มตามเงื่อนไข
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: Icon(
                            isConfirmedBySender
                                ? Icons.check_circle
                                : Icons.camera_alt,
                          ),
                          label: Text(
                            isConfirmedBySender
                                ? 'เช็คสถานะ'
                                : 'ยืนยันด้วยรูปก่อน',
                          ),
                          onPressed: () {
                            if (isConfirmedBySender) {
                              // ไปหน้า tracking ได้เลย
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DeliveryTrackingScreen(orderId: orderId),
                                ),
                              );
                            } else {
                              // ต้องยืนยันรูปก่อน
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SenderConfirmPhotoScreen(
                                    orderId: orderId,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _imgFallback() => Container(
    width: 80,
    height: 80,
    color: Colors.grey[200],
    child: const Icon(Icons.image),
  );
}
