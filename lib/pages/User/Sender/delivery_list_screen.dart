import 'package:flutter/material.dart';
import 'package:move_delivery/pages/User/Sender/sender_confirm_photo_screen.dart';

// 1. แก้ไข Constructor ให้ไม่ต้องรับ Parameter ใดๆ
class ItemsToDispatchScreen extends StatefulWidget {
  const ItemsToDispatchScreen({super.key});

  @override
  State<ItemsToDispatchScreen> createState() => _ItemsToDispatchScreenState();
}

class _ItemsToDispatchScreenState extends State<ItemsToDispatchScreen> {
  final List<Map<String, String>> _deliveryItems = [
    {
      'item': 'ตุ๊กตาเป็ด',
      'receiver': 'รินดา สวยมาก',
      'phone': '0911111111',
      'address': 'ที่อยู่ผู้รับ',
      'imageUrl': 'assets/images/duck_doll.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'รายการที่ต้องจัดส่ง',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                // 2. แก้ไข onPressed ให้ทำงานได้ในตัวเอง
                onPressed: () {
                  print('Add button pressed!');
                  // TODO: ในอนาคตจะใส่ Logic การเพิ่มรายการที่นี่
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('เพิ่ม'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _deliveryItems.length,
                itemBuilder: (context, index) {
                  return _buildDeliveryItemCard(_deliveryItems[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SenderConfirmPhotoScreen(),
                      ),
                    );
                  },
                  child: const Text('ส่งสินค้า'),
                ),
              ),
            ),
          ],
        ),
      ),
      // ... โค้ด BottomNavigationBar เหมือนเดิม ...
    );
  }

  // ... โค้ด _buildDeliveryItemCard เหมือนเดิม ...
  Widget _buildDeliveryItemCard(Map<String, String> itemData) {
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
