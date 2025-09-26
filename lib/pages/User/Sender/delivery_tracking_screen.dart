import 'package:flutter/material.dart';
// ไม่ต้อง import google_maps_flutter แล้ว
// import 'package:google_maps_flutter/google_maps_flutter.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  const DeliveryTrackingScreen({super.key});

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  // สถานะปัจจุบัน (1-4)
  final int _currentStatus = 2; // ตัวอย่าง: ไรเดอร์รับงานแล้ว

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สถานะการจัดส่ง')),
      body: Stack(
        children: [
          // --- 1. พื้นที่จำลองแผนที่ (Placeholder) ---
          // TODO: เมื่อพร้อม ให้เปลี่ยนส่วนนี้กลับไปเป็น GoogleMap widget
          Container(
            color: Colors.grey[300],
            child: const Center(
              child: Text(
                'Map Placeholder',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ),

          // --- 2. แผงข้อมูลที่เลื่อนได้ (อยู่ชั้นบน) ---
          DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.2,
            maxChildSize: 0.9,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildStatusTracker(context),
                        const SizedBox(height: 24),
                        _buildInfoCard(
                          title: 'รายละเอียดสินค้า',
                          child: _buildProductDetails(),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          title: 'ข้อมูลไรเดอร์',
                          child: _buildRiderInfo(),
                        ),
                        const SizedBox(height: 16),
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
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Widget ย่อยสำหรับสร้างส่วนต่างๆ (เหมือนเดิมทุกประการ) ---
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

  Widget _buildStatusTracker(BuildContext context) {
    Color activeColor = Theme.of(context).primaryColor;
    Color inactiveColor = Colors.grey.shade400;

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
            _currentStatus == 4 ? 'จัดส่งสินค้าเรียบร้อย' : 'กำลังดำเนินการ',
            style: TextStyle(color: Colors.white.withOpacity(0.9)),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusIcon(Icons.store, 1, activeColor, inactiveColor),
              _buildStatusLine(2, activeColor, inactiveColor),
              _buildStatusIcon(Icons.moped, 2, activeColor, inactiveColor),
              _buildStatusLine(3, activeColor, inactiveColor),
              _buildStatusIcon(
                Icons.local_shipping,
                3,
                activeColor,
                inactiveColor,
              ),
              _buildStatusLine(4, activeColor, inactiveColor),
              _buildStatusIcon(
                Icons.location_on,
                4,
                activeColor,
                inactiveColor,
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
    Color inactive,
  ) {
    bool isActive = _currentStatus >= step;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : inactive.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: isActive ? active : Colors.white, size: 24),
    );
  }

  Widget _buildStatusLine(int step, Color active, Color inactive) {
    return Expanded(
      child: Container(
        height: 4,
        color: _currentStatus >= step ? active : inactive,
      ),
    );
  }

  Widget _buildProductDetails() {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          color: Colors.grey[200],
          child: const Icon(Icons.image),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            decoration: const InputDecoration(labelText: 'รายละเอียด'),
          ),
        ),
      ],
    );
  }

  Widget _buildRiderInfo() {
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
