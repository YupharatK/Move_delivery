// rider_confirm_delivery_screen.dart (ไฟล์ใหม่)

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RiderConfirmDeliveryScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const RiderConfirmDeliveryScreen({
    super.key,
    required this.orderId,
    required this.orderData,
  });

  @override
  State<RiderConfirmDeliveryScreen> createState() =>
      _RiderConfirmDeliveryScreenState();
}

class _RiderConfirmDeliveryScreenState
    extends State<RiderConfirmDeliveryScreen> {
  File? _pickedImage;
  bool _isUploading = false;

  final _cloudinary = CloudinaryPublic(
    'ddl3wobhb',
    'Move_Upload',
    cache: false,
  );

  // ⭐️ 1. (เหมือนเดิม) Logic ถ่ายรูป
  Future<void> _takePhoto() async {
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (x == null) return;
      setState(() => _pickedImage = File(x.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เปิดกล้องไม่สำเร็จ: $e')));
    }
  }

  // ⭐️ 2. (แก้ไข) Logic อัปโหลด Cloudinary
  Future<String> _uploadToCloudinary(File file) async {
    final res = await _cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        file.path,
        // ⭐️ เปลี่ยนโฟลเดอร์เป็น 'delivery'
        folder: 'orders/${widget.orderId}/delivery',
        resourceType: CloudinaryResourceType.Image,
      ),
    );
    return res.secureUrl;
  }

  // ⭐️ 3. (แก้ไข) Logic ยืนยันการส่ง (Confirm Delivery)
  Future<void> _confirmDelivery() async {
    if (_pickedImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณาถ่ายรูปยืนยันก่อน')));
      return;
    }

    setState(() => _isUploading = true);
    try {
      final imageUrl = await _uploadToCloudinary(_pickedImage!);
      final driverId = FirebaseAuth.instance.currentUser?.uid;

      final orderRef = FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId);

      // ⭐️⭐️ อัปเดต field การส่ง ⭐️⭐️
      await orderRef.update({
        'status': 'DELIVERED', // ⭐️ เปลี่ยนสถานะเป็น "ส่งสำเร็จ"
        'deliveredPhotoUrl': imageUrl, // ⭐️ เก็บรูปล่าสุด
        'deliveredAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ⭐️⭐️ เก็บประวัติใน subcollection ⭐️⭐️
      await orderRef.collection('status_media').doc('DELIVERED').set({
        'type': 'image',
        'url': imageUrl,
        'byUid': driverId,
        'at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยืนยันส่งสินค้าสำเร็จ! (จบงาน)')),
      );

      // ⭐️ 4. (แก้ไข) กลับไปหน้าแรก (หน้า List)
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on CloudinaryException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('อัปโหลด Cloudinary ล้มเหลว: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ยืนยันการส่งสินค้า (ถึงที่หมาย)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // (UI ส่วนนี้เหมือนกับ RiderConfirmPickupScreen)
            // ... (คุณสามารถคัดลอก _buildPhotoSection() และปุ่มยืนยันมาได้) ...

            // --- ส่วนถ่ายรูป ---
            _buildPhotoSection(),
            const SizedBox(height: 24),

            // --- ปุ่มยืนยันการส่งสินค้า ---
            ElevatedButton(
              onPressed: _isUploading
                  ? null
                  : _confirmDelivery, // ⭐️ เรียก _confirmDelivery
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('ยืนยันการส่งสินค้า และ จบงาน'),
            ),
          ],
        ),
      ),
    );
  }

  // (Widget นี้เหมือนเดิม)
  Widget _buildPhotoSection() {
    return Column(
      children: [
        const Text(
          'ถ่ายรูปยืนยันการส่งสินค้า', // ⭐️ เปลี่ยน Text
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _isUploading ? null : _takePhoto,
          child: Container(
            height: 200, // (อาจจะทำให้ใหญ่ขึ้น)
            width: double.infinity,
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
      ],
    );
  }
}
