import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart'; // TODO: เพิ่ม dependency นี้

class RiderConfirmPickupScreen extends StatefulWidget {
  const RiderConfirmPickupScreen({super.key});

  @override
  State<RiderConfirmPickupScreen> createState() =>
      _RiderConfirmPickupScreenState();
}

class _RiderConfirmPickupScreenState extends State<RiderConfirmPickupScreen> {
  File? _pickedImage; // State สำหรับเก็บรูปที่ถ่าย

  Future<void> _pickImage() async {
    // TODO: ใส่ Logic การเลือก/ถ่ายรูป
    print('Picking image...');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ยืนยันการรับสินค้า')),
      body: Stack(
        children: [
          // --- 1. พื้นที่จำลองแผนที่ (Placeholder) ---
          Container(
            color: Colors.grey[300],
            child: const Center(
              child: Text(
                'Map Placeholder',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ),

          // --- 2. แผงข้อมูลที่เลื่อนได้ ---
          DraggableScrollableSheet(
            initialChildSize: 0.65, // ขนาดเริ่มต้น
            minChildSize: 0.65, // ขนาดเล็กสุด (ทำให้เลื่อนลงไม่ได้)
            maxChildSize: 0.9, // ขนาดใหญ่สุด
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- การ์ดรายละเอียดสินค้า ---
                        _buildDetailsCard(),
                        const SizedBox(height: 24),

                        // --- ส่วนถ่ายรูป ---
                        _buildPhotoSection(),
                        const SizedBox(height: 24),

                        // --- ปุ่มยืนยันการรับสินค้า ---
                        ElevatedButton(
                          onPressed: () {
                            // TODO: Logic ยืนยันการรับสินค้า
                          },
                          child: const Text('ยืนยันการรับสินค้า'),
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

  // Widget สำหรับสร้างการ์ดรายละเอียด
  Widget _buildDetailsCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'รายละเอียดสินค้า',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Image.asset(
                  'assets/images/duck_doll.png',
                  width: 50,
                ), // TODO: ใส่ path รูป
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'ตุ๊กตาเป็ด',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('จำนวน : 1 รายการ'),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            _buildAddressRow(
              icon: Icons.storefront,
              label: 'รับสินค้าที่',
              address: 'ที่อยู่ผู้ส่ง',
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 12),
            _buildAddressRow(
              icon: Icons.person_pin_circle,
              label: 'ส่งสินค้าที่',
              address: 'ที่อยู่ผู้รับ',
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  // Widget สำหรับสร้างแถวที่อยู่
  Widget _buildAddressRow({
    required IconData icon,
    required String label,
    required String address,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            Text(address, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  // Widget สำหรับส่วนถ่ายรูป
  Widget _buildPhotoSection() {
    return Column(
      children: [
        const Text(
          'ถ่ายรูปยืนยันสถานะ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 150,
            width: 150,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              image: _pickedImage != null
                  ? DecorationImage(
                      image: FileImage(_pickedImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _pickedImage == null
                ? Center(
                    child: Icon(
                      Icons.camera_alt,
                      size: 50,
                      color: Colors.grey[600],
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _pickImage,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber[700],
            foregroundColor: Colors.white,
          ),
          child: const Text('เพิ่มรูปภาพ'),
        ),
      ],
    );
  }
}
