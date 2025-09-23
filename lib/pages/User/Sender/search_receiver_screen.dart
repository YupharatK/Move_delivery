import 'package:flutter/material.dart';
import 'package:move_delivery/pages/User/Sender/product_details_screen.dart';

// เปลี่ยนเป็น StatelessWidget เพราะไม่มี State ภายในตัวเองแล้ว
class SearchReceiverScreen extends StatelessWidget {
  const SearchReceiverScreen({super.key});

  // ข้อมูลตัวอย่าง (ย้ายมาไว้ที่นี่ก่อนเพื่อความง่าย)
  final List<Map<String, String>> _mockResults = const [
    {
      'name': 'รินดา สวยมาก',
      'phone': '0911111111',
      'address': 'ที่อยู่หลัก',
      'imageUrl': '',
    },
    {
      'name': 'สมชาย ใจดี',
      'phone': '0822222222',
      'address': 'ที่ทำงาน',
      'imageUrl': '',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // ไม่มี Scaffold, ไม่มี AppBar แล้ว
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            // ... โค้ด TextFormField เหมือนเดิม ...
            decoration: InputDecoration(
              hintText: 'กรอกหมายเลขโทรศัพท์ของผู้รับ',
              filled: true,
              fillColor: Colors.grey[200],
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'เลือกผู้รับ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _mockResults.length,
              itemBuilder: (context, index) {
                return _buildResultTile(
                  context,
                  _mockResults[index],
                ); // ส่ง context ไปด้วย
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget สำหรับสร้างรายการผลลัพธ์แต่ละอัน
  Widget _buildResultTile(BuildContext context, Map<String, String> userData) {
    // ... โค้ด _buildResultTile เหมือนเดิมทุกประการ ...
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey[300],
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userData['name']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'เบอร์โทร ${userData['phone']!}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.grey[600], size: 14),
                    const SizedBox(width: 4),
                    Text(
                      userData['address']!,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductDetailsScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('เลือก'),
          ),
        ],
      ),
    );
  }
}
