import 'package:flutter/material.dart';
import 'package:move_delivery/pages/User/Sender/delivery_tracking_screen.dart';

// 1. ตรวจสอบให้แน่ใจว่า Widget หลักเป็น StatefulWidget
class SenderTrackingListScreen extends StatefulWidget {
  const SenderTrackingListScreen({super.key});

  @override
  State<SenderTrackingListScreen> createState() =>
      _SenderTrackingListScreenState();
}

// State Class คือที่ที่เราจะเก็บข้อมูลและสร้าง UI
class _SenderTrackingListScreenState extends State<SenderTrackingListScreen> {
  // 2. ข้อมูล (_trackingItems) ต้องอยู่ภายใน State Class นี้
  final List<Map<String, String>> _trackingItems = [
    {
      'item': 'ตุ๊กตาเป็ด',
      'receiver': 'รินดา สวยมาก',
      'phone': '0911111111',
      'address': 'ที่อยู่ผู้รับ',
      'imageUrl': 'assets/images/duck_doll.png',
    },
    {
      'item': 'หนังสือ Flutter',
      'receiver': 'สมชาย ใจดี',
      'phone': '0822222222',
      'address': 'ที่ทำงาน',
      'imageUrl': 'assets/images/book.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: _trackingItems.length,
          itemBuilder: (context, index) {
            // build() สามารถเรียกใช้ _buildTrackingItemCard ได้เพราะอยู่ class เดียวกัน
            return _buildTrackingItemCard(_trackingItems[index]);
          },
        ),
      ),
    );
  }

  // 3. ฟังก์ชัน Helper (_buildTrackingItemCard) ก็ต้องอยู่ภายใน State Class นี้ด้วย
  Widget _buildTrackingItemCard(Map<String, String> itemData) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                itemData['imageUrl']!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'รายละเอียดการจัดส่ง',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text('รายการ : ${itemData['item']}'),
                  Text('ผู้รับ : ${itemData['receiver']}'),
                  Text('เบอร์โทร : ${itemData['phone']}'),
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
                          itemData['address']!,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const DeliveryTrackingScreen(),
                          ),
                        );
                      },
                      child: const Text('เช็คสถานะ'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} // <--- สิ้นสุด State Class
