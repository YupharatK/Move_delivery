import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  const DeliveryTrackingScreen({super.key, required this.orderId});
  final String orderId;

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  /// แปลง status เป็น step (1-4)
  int _stepFromStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': // [1] รอไรเดอร์รับของ (มีรูปยืนยันแล้ว)
        return 1;
      case 'ASSIGNED': // [2] จับคู่ไรเดอร์แล้ว
      case 'PICKED_UP': // [2] ไรเดอร์รับของแล้ว
        return 2;
      case 'IN_TRANSIT': // [3] กำลังนำส่ง
        return 3;
      case 'DELIVERED': // [4] จัดส่งสำเร็จ
      default:
        return 4;
    }
  }

  /// อ่าน item แรกของออเดอร์ (ชื่อ/รูปสินค้า) เผื่อใช้ fallback ถ้าไม่มี pendingPhotoUrl
  Future<Map<String, dynamic>?> _fetchFirstItem(String orderId) async {
    final qs = await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .collection('items')
        .limit(1)
        .get();
    if (qs.docs.isEmpty) return null;
    return qs.docs.first.data();
  }

  @override
  Widget build(BuildContext context) {
    final orderRef = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId);

    return Scaffold(
      appBar: AppBar(title: const Text('สถานะการจัดส่ง')),
      body: Stack(
        children: [
          // --- 1) พื้นที่แผนที่ (placeholder ชั่วคราว) ---
          Container(
            color: Colors.grey[300],
            child: const Center(
              child: Text(
                'Map Placeholder',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ),

          // --- 2) แผงข้อมูลด้านล่าง ---
          DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.2,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: orderRef.snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(
                        child: Text('เกิดข้อผิดพลาด: ${snap.error}'),
                      );
                    }
                    if (!snap.hasData || !snap.data!.exists) {
                      return const Center(child: Text('ไม่พบออเดอร์นี้'));
                    }

                    final order = snap.data!.data()!;
                    final status = (order['status'] ?? 'PENDING')
                        .toString(); // ex. PENDING
                    final step = _stepFromStatus(status);
                    final pendingPhotoUrl = (order['pendingPhotoUrl'] ?? '')
                        .toString();

                    // ตัวเลขสรุป
                    final total = (order['total'] is num)
                        ? (order['total'] as num).toDouble()
                        : 0.0;
                    final itemCount = (order['itemCount'] is num)
                        ? (order['itemCount'] as num).toInt()
                        : 1;

                    return SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: FutureBuilder<Map<String, dynamic>?>(
                          future: _fetchFirstItem(widget.orderId),
                          builder: (context, itemSnap) {
                            final firstItem = itemSnap.data;
                            final itemName = (firstItem?['name'] ?? '—')
                                .toString();
                            final itemImg = (firstItem?['imageUrl'] ?? '')
                                .toString();
                            final imageToShow = pendingPhotoUrl.isNotEmpty
                                ? pendingPhotoUrl
                                : itemImg; // ✅ ถ้ามีรูปยืนยัน ให้ใช้ก่อน

                            return Column(
                              children: [
                                _buildStatusTracker(
                                  context: context,
                                  currentStep: step,
                                  statusText: status,
                                ),
                                const SizedBox(height: 24),

                                // รายละเอียดสินค้า (มีรูปจาก Cloudinary ถ่ายยืนยัน หรือรูปสินค้าแรก)
                                _buildInfoCard(
                                  title: 'รายละเอียดสินค้า',
                                  child: _buildProductDetails(
                                    imageUrl: imageToShow,
                                    name: itemName,
                                    itemCount: itemCount,
                                    total: total,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // ข้อมูลไรเดอร์ (ตัวอย่างเดิม)
                                _buildInfoCard(
                                  title: 'ข้อมูลไรเดอร์',
                                  child: _buildRiderInfo(),
                                ),

                                const SizedBox(height: 16),

                                // รายงานการส่ง (ตัวอย่างเดิม)
                                _buildInfoCard(
                                  title: 'รายงานการส่งสินค้า',
                                  child: _buildDeliveryReport(),
                                ),

                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    child: const Text('ยืนยัน'),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------- Widgets ----------

  Widget _buildInfoCard({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(padding: const EdgeInsets.all(12.0), child: child),
        ),
      ],
    );
  }

  Widget _buildStatusTracker({
    required BuildContext context,
    required int currentStep, // 1-4
    required String statusText,
  }) {
    final activeColor = Theme.of(context).primaryColor;
    final inactiveColor = Colors.grey.shade400;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: activeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สถานะการจัดส่ง',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            statusText == 'DELIVERED' ? 'จัดส่งสินค้าเรียบร้อย' : statusText,
            style: TextStyle(color: Colors.white.withOpacity(0.9)),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusIcon(
                Icons.store,
                1,
                activeColor,
                inactiveColor,
                isActive: currentStep >= 1,
              ),
              _buildStatusLine(currentStep >= 2, activeColor, inactiveColor),
              _buildStatusIcon(
                Icons.moped,
                2,
                activeColor,
                inactiveColor,
                isActive: currentStep >= 2,
              ),
              _buildStatusLine(currentStep >= 3, activeColor, inactiveColor),
              _buildStatusIcon(
                Icons.local_shipping,
                3,
                activeColor,
                inactiveColor,
                isActive: currentStep >= 3,
              ),
              _buildStatusLine(currentStep >= 4, activeColor, inactiveColor),
              _buildStatusIcon(
                Icons.location_on,
                4,
                activeColor,
                inactiveColor,
                isActive: currentStep >= 4,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(
    IconData icon,
    int step,
    Color active,
    Color inactive, {
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : inactive.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: isActive ? active : Colors.white, size: 24),
    );
  }

  Widget _buildStatusLine(bool filled, Color active, Color inactive) {
    return Expanded(
      child: Container(height: 4, color: filled ? active : inactive),
    );
  }

  /// ✅ เอารูปมาแสดงตรงรายละเอียดสินค้า (รูปยืนยันจาก Cloudinary จะมาก่อน)
  Widget _buildProductDetails({
    required String imageUrl,
    required String name,
    required int itemCount,
    required double total,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: (imageUrl.isNotEmpty)
              ? Image.network(
                  imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imgFallback(),
                )
              : _imgFallback(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? 'สินค้า' : name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text('จำนวนชิ้น: $itemCount'),
              Text('ยอดรวม: ${total.toStringAsFixed(2)} ฿'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _imgFallback() => Container(
    width: 80,
    height: 80,
    color: Colors.grey[200],
    child: const Icon(Icons.image),
  );

  Widget _buildRiderInfo() {
    // TODO: ต่อเข้าข้อมูลจริงเมื่อมี (ปัจจุบันเป็น mock)
    return Row(
      children: [
        const CircleAvatar(radius: 25, child: Icon(Icons.person)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Mana Manee', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('เบอร์โทร : 0922222222'),
            Text('ทะเบียนรถ : กท 678'),
          ],
        ),
      ],
    );
  }

  Widget _buildDeliveryReport() {
    // TODO: ต่อเข้ารูป/ข้อมูลส่งสำเร็จจริงในภายหลัง
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          color: Colors.grey[200],
          child: const Icon(Icons.image),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'สินค้าของคุณถึงจุดหมายเรียบร้อยแล้ว',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
