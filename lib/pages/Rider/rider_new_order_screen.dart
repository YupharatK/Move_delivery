// rider_new_order_screen.dart (อัปเดต: แสดง "List" งานทั้งหมด)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'rider_app_bar.dart';
// ⭐️ 1. Import หน้า Detail ที่เราจะสร้างใหม่
import 'rider_order_details_screen.dart';

class RiderNewOrderScreen extends StatefulWidget {
  const RiderNewOrderScreen({super.key});

  @override
  State<RiderNewOrderScreen> createState() => _RiderNewOrderScreenState();
}

class _RiderNewOrderScreenState extends State<RiderNewOrderScreen> {
  // ⭐️ 2. สร้าง Stream ที่คอยดึงออเดอร์ PENDING ทั้งหมด
  final Stream<QuerySnapshot<Map<String, dynamic>>> _ordersStream =
      FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'PENDING')
          .where('pendingPhotoUrl', isNotEqualTo: null)
          .orderBy('createdAt', descending: false)
          .snapshots(); // ⭐️ .snapshots() เพื่อให้เป็น Real-time

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RiderAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ออเดอร์ที่รอรับงาน',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // ⭐️ 3. ใช้ StreamBuilder เพื่อแสดง List
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _ordersStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    // (อาจจะต้องเช็ค Index เหมือนเดิม)
                    return Center(
                      child: Text(
                        'เกิดข้อผิดพลาดในการโหลดงาน: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'ไม่พบออเดอร์ที่รอรับงานในขณะนี้',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }

                  // ⭐️ 4. สร้าง ListView
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final orderDoc = docs[index];
                      // ⭐️ 5. ส่งข้อมูลออเดอร์ไปให้ Card Widget
                      return _OrderListItem(
                        orderId: orderDoc.id,
                        orderData: orderDoc.data(),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ⭐️ 6. (ใหม่) Widget สำหรับแสดง Card ใน List
// (Widget นี้จะดึงข้อมูลย่อยๆ ของตัวเอง เช่น ชื่อผู้ส่ง/ผู้รับ)
class _OrderListItem extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const _OrderListItem({required this.orderId, required this.orderData});

  @override
  State<_OrderListItem> createState() => _OrderListItemState();
}

class _OrderListItemState extends State<_OrderListItem> {
  Map<String, dynamic>? _senderData;
  Map<String, dynamic>? _receiverData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  // Helper: ดึงที่อยู่ (ย่อ)
  String _extractAddressText(Map<String, dynamic>? userData) {
    if (userData == null) return '-';
    final List<dynamic> addresses =
        (userData['addresses'] as List<dynamic>? ?? []);
    if (addresses.isNotEmpty && addresses.first is Map) {
      final a = (addresses.first as Map).cast<String, dynamic>();
      return (a['address'] ?? '-') as String;
    }
    return '-';
  }

  // ดึงข้อมูล Sender/Receiver (เฉพาะที่จำเป็นสำหรับ List)
  Future<void> _fetchDetails() async {
    try {
      final db = FirebaseFirestore.instance;
      final senderId = widget.orderData['userId'] as String?;
      final receiverId = widget.orderData['receiverId'] as String?;

      final List<DocumentSnapshot> userDocs = await Future.wait([
        if (senderId != null) db.collection('users').doc(senderId).get(),
        if (receiverId != null) db.collection('users').doc(receiverId).get(),
      ]);

      if (mounted) {
        setState(() {
          if (userDocs.isNotEmpty) {
            _senderData = userDocs[0].data() as Map<String, dynamic>?;
          }
          if (userDocs.length > 1) {
            _receiverData = userDocs[1].data() as Map<String, dynamic>?;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch item details: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        margin: EdgeInsets.only(bottom: 12),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final total = (widget.orderData['total'] as num?)?.toDouble() ?? 0.0;
    final itemCount = (widget.orderData['itemCount'] as num?)?.toInt() ?? 0;

    final senderAddress = _extractAddressText(_senderData);
    final receiverAddress = _extractAddressText(_receiverData);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        // ⭐️ 7. (สำคัญ) เมื่อกด Card ให้ไปหน้า Detail
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  RiderOrderDetailsScreen(orderId: widget.orderId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order #${widget.orderId.substring(0, 6)}...', // แสดง ID ย่อ
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Divider(height: 16),
              _buildAddressRow(
                context,
                icon: Icons.store,
                label: 'รับจาก:',
                address: senderAddress,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 8),
              _buildAddressRow(
                context,
                icon: Icons.location_on,
                label: 'ส่งที่:',
                address: receiverAddress,
                color: Colors.green.shade700,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$itemCount รายการ',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  Text(
                    '${total.toStringAsFixed(2)} ฿',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String address,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                address,
                style: const TextStyle(fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
