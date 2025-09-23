import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart'; // TODO: เพิ่ม dependency นี้

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  File? _productImage;
  final _productNameController = TextEditingController();
  final _productDetailsController = TextEditingController();

  // ฟังก์ชันสำหรับเลือกรูปภาพ
  Future<void> _pickImage() async {
    // TODO: ใส่ Logic การเลือกรูปภาพ
    print('Picking product image...');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดสินค้า'), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- ส่วนข้อมูลสินค้า (พื้นหลังสีเขียว) ---
              _buildProductInfoSection(context),
              const SizedBox(height: 24),

              // --- ส่วนที่อยู่ (การ์ดสีขาว) ---
              _buildAddressSection(),
              const SizedBox(height: 48),

              // --- ปุ่มยืนยัน ---
              ElevatedButton(
                onPressed: () {
                  // TODO: Logic ยืนยันการสร้างออเดอร์
                },
                child: const Text('ยืนยัน'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget สำหรับส่วนข้อมูลสินค้า
  Widget _buildProductInfoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // ช่องเลือกรูปภาพ
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                image: _productImage != null
                    ? DecorationImage(
                        image: FileImage(_productImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _productImage == null
                  ? const Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 50,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          const Text('รูปภาพสินค้า', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 16),

          // ช่องกรอกชื่อและรายละเอียด
          TextFormField(
            controller: _productNameController,
            decoration: _inputDecoration(hintText: 'กรอกชื่อสินค้า'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _productDetailsController,
            decoration: _inputDecoration(hintText: 'กรอกรายละเอียดสินค้า'),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  // Widget สำหรับส่วนที่อยู่
  Widget _buildAddressSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildAddressRow(
              icon: Icons.location_on,
              label: 'ที่อยู่ผู้ส่ง',
              address:
                  '123/45 ถ.ศรีนครินทร์ ต.ตลาด อ.เมือง จ.มหาสารคาม 44000', // TODO: ใส่ข้อมูลจริง
              iconColor: Colors.red,
            ),
            const Divider(height: 24),
            _buildAddressRow(
              icon: Icons.location_on,
              label: 'ที่อยู่ผู้รับ',
              address:
                  '987/65 ถ.แจ้งสนิท ต.ตลาด อ.เมือง จ.มหาสารคาม 44000', // TODO: ใส่ข้อมูลจริง
              iconColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  // Widget สำหรับแสดงแถวที่อยู่
  Widget _buildAddressRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String address,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ฟังก์ชันสำหรับตกแต่ง TextFormField (สำหรับพื้นหลังสีเขียว)
  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
