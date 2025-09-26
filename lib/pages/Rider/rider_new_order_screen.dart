import 'package:flutter/material.dart';
import 'package:move_delivery/pages/Rider/rider_confirm_pickup_screen.dart';
import 'rider_app_bar.dart'; // Import AppBar ที่สร้างไว้

class RiderNewOrderScreen extends StatelessWidget {
  const RiderNewOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RiderAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'ออเดอร์',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // --- ส่วนรายละเอียดสินค้า ---
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/burger.png',
                            width: 60,
                          ), // TODO: ใส่ path รูป
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'ออเดอร์ใหม่',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text('รายการ : ตุ๊กตาเป็ด'),
                              Text('จำนวน : 1 รายการ'),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      // --- ส่วนที่อยู่ ---
                      _buildAddressDetail(
                        context: context,
                        role: 'ผู้ส่ง',
                        name: 'Mike',
                        phone: '0954444444',
                        address: 'ที่อยู่ผู้ส่ง',
                      ),
                      const SizedBox(height: 16),
                      _buildAddressDetail(
                        context: context,
                        role: 'ผู้รับ',
                        name: 'รินดา สวยมาก',
                        phone: '09485222',
                        address: 'ที่อยู่ผู้รับ',
                      ),
                      const SizedBox(height: 24),
                      // --- ปุ่ม รับ/ยกเลิก ---
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RiderConfirmPickupScreen(), // ไปที่หน้าหลักของการส่งของ
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('รับ'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                /* TODO: Logic ยกเลิก */
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber[700],
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('ยกเลิก'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget ช่วยสร้างส่วนแสดงรายละเอียดที่อยู่
  Widget _buildAddressDetail({
    required BuildContext context,
    required String role,
    required String name,
    required String phone,
    required String address,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$role : $name',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text('เบอร์โทร : $phone'),
        Row(
          children: [
            Icon(
              Icons.location_on,
              color: Theme.of(context).primaryColor,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(address),
          ],
        ),
      ],
    );
  }
}
