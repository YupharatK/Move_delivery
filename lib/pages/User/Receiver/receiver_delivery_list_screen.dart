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
  // --- ข้อมูลตัวอย่าง (Mock Data) ---
  final List<Map<String, String>> _incomingItems = [
    {
      'item': 'ตุ๊กตาเป็ด',
      'sender': 'Mike',
      'phone': '0954444444',
      'address': 'ที่อยู่ผู้ส่ง',
      'imageUrl': 'assets/images/duck_doll.png', // TODO: ใส่ path รูปภาพของคุณ
    },
    // สามารถเพิ่มรายการอื่นๆ ที่นี่
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // AppBar สีขาวตามดีไซน์
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
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _incomingItems.length,
        itemBuilder: (context, index) {
          return _buildIncomingItemCard(_incomingItems[index]);
        },
      ),
      // --- BottomNavigationBar สำหรับผู้รับ ---
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
        currentIndex: 1, // กำหนดให้แท็บ "ที่ต้องได้รับ" ถูกเลือกอยู่
        onTap: (index) {},
        backgroundColor: Theme.of(context).primaryColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.7),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // Widget สำหรับสร้าง Card ของแต่ละรายการ
  Widget _buildIncomingItemCard(Map<String, String> itemData) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                // รายละเอียด
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'รายละเอียดการจัดส่ง',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('รายการ : ${itemData['item']}'),
                      Text(
                        'ผู้ส่ง : ${itemData['sender']}',
                      ), // <<-- แสดงชื่อผู้ส่ง
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DeliveryTrackingScreen(),
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
  }
}
