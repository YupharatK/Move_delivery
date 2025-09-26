import 'dart:io';
import 'package:flutter/material.dart';
import 'package:move_delivery/pages/User/Sender/sender_delivery_tracking_screen.dart';
// import 'package:image_picker/image_picker.dart';

// เปลี่ยนชื่อ Class ให้ถูกต้อง
class SenderConfirmPhotoScreen extends StatefulWidget {
  const SenderConfirmPhotoScreen({super.key});

  @override
  State<SenderConfirmPhotoScreen> createState() =>
      _SenderConfirmPhotoScreenState();
}

class _SenderConfirmPhotoScreenState extends State<SenderConfirmPhotoScreen> {
  File? _pickedImage;

  Future<void> _takePhoto() async {
    // TODO: ใส่ Logic การถ่ายภาพ
    print('Taking photo...');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'สินค้าที่จะจัดส่ง',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildDetailsCard(),
              const SizedBox(height: 24),
              _buildPhotoSection(),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SenderTrackingListScreen(),
                      ),
                    );
                  },
                  child: const Text('ยืนยัน'),
                ),
              ),
            ],
          ),
        ),
      ),
      // หน้านี้ไม่จำเป็นต้องมี BottomNavBar เพราะเป็นหน้าย่อย
    );
  }

  // ... โค้ดส่วน _buildDetailsCard, _buildDetailRow, _buildPhotoSection ...
  // ... เหมือนเดิมทุกประการครับ ...
  Widget _buildDetailsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('ชื่อผู้รับ', 'รินดา สวยมาก'),
            _buildDetailRow('เบอร์โทร', '0911111111'),
            _buildDetailRow(
              'ที่อยู่',
              '123/45 ถ.ศรีนครินทร์ ต.ตลาด อ.เมือง...',
            ),
            _buildDetailRow('หมายเลขออร์เดอร์', '12'),
            const SizedBox(height: 8),
            const Text(
              'ตุ๊กตาเป็ด',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text('$label : ', style: TextStyle(color: Colors.grey[700])),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          children: [
            IconButton(
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera_alt),
              iconSize: 40,
              color: Theme.of(context).primaryColor,
            ),
            const Text('ถ่ายภาพ'),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                image: _pickedImage != null
                    ? DecorationImage(
                        image: FileImage(_pickedImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _pickedImage == null
                  ? Center(
                      child: Text(
                        'แสดงรูป',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
