// sender_confirm_photo_screen.dart (ใช้ Cloudinary แบบเดียวกับ register_user_screen)

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:move_delivery/pages/User/Sender/delivery_tracking_screen.dart';

class SenderConfirmPhotoScreen extends StatefulWidget {
  const SenderConfirmPhotoScreen({super.key, required this.orderId});
  final String orderId;

  @override
  State<SenderConfirmPhotoScreen> createState() =>
      _SenderConfirmPhotoScreenState();
}

class _SenderConfirmPhotoScreenState extends State<SenderConfirmPhotoScreen> {
  File? _pickedImage;
  bool _isUploading = false;
  String? _uploadedUrl;

  // ---------- Cloudinary (same settings as register_user_screen) ----------
  // cloud_name: ddl3wobhb, upload_preset: Move_Upload
  final _cloudinary = CloudinaryPublic(
    'ddl3wobhb',
    'Move_Upload',
    cache: false,
  );

  // ---------- Take or pick photo ----------
  Future<void> _takePhoto() async {
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (x == null) return;
      setState(() {
        _pickedImage = File(x.path);
        _uploadedUrl = null; // ถ่ายใหม่ → รีเซ็ต URL เดิม
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เปิดกล้องไม่สำเร็จ: $e')));
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (x == null) return;
      setState(() {
        _pickedImage = File(x.path);
        _uploadedUrl = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เลือกรูปจากคลังไม่สำเร็จ: $e')));
    }
  }

  // ---------- Upload to Cloudinary (UNSIGNED) ----------
  Future<String> _uploadToCloudinary(File file) async {
    // แนะนำให้จัดโฟลเดอร์ใน Cloudinary เป็น orders/<orderId> เพื่อระเบียบเรียบร้อย
    final folder = 'orders/${widget.orderId}';
    final res = await _cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        file.path,
        folder: folder,
        resourceType: CloudinaryResourceType.Image,
      ),
    );
    return res.secureUrl;
  }

  // ---------- Commit to Firestore ----------
  Future<void> _confirmAndGo() async {
    if (_pickedImage == null && _uploadedUrl == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณาถ่าย/เลือกรูปก่อน')));
      return;
    }

    setState(() => _isUploading = true);
    try {
      // 1) อัปโหลดรูป → ได้ URL จาก Cloudinary
      final url = _uploadedUrl ?? await _uploadToCloudinary(_pickedImage!);

      // 2) อัปเดต Firestore: ใส่รูปยืนยันสถานะ PENDING + บันทึกไทม์สแตมป์
      final orderRef = FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId);

      await orderRef.update({
        'status': 'PENDING', // ถ้าเดิม PENDING อยู่แล้วก็ไม่เป็นไร
        'pendingPhotoUrl': url,
        'pendingPhotoAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // เก็บเป็นประวัติใน subcollection ด้วย (สำหรับไทม์ไลน์สถานะ)
      await orderRef.collection('status_media').doc('PENDING').set({
        'type': 'image',
        'url': url,
        'byUid': FirebaseAuth.instance.currentUser?.uid,
        'at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      // 3) ไปหน้าเช็คสถานะ
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DeliveryTrackingScreen(orderId: widget.orderId),
        ),
      );
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
    final canConfirm =
        (_pickedImage != null || _uploadedUrl != null) && !_isUploading;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ยืนยันด้วยรูป (สถานะ: รอไรเดอร์รับของ)',
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
              _buildOrderHeader(),
              const SizedBox(height: 24),
              _buildPhotoSection(),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: canConfirm ? _confirmAndGo : null,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    _isUploading ? 'กำลังบันทึก…' : 'ยืนยันและไปเช็คสถานะ',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- UI ----------
  Widget _buildOrderHeader() {
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
            _detailRow('หมายเลขออเดอร์', widget.orderId),
            const SizedBox(height: 8),
            const Text(
              'โปรดถ่าย/เลือกรูปพัสดุเพื่อยืนยันสถานะ PENDING',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
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
              onPressed: _isUploading ? null : _takePhoto,
              icon: const Icon(Icons.camera_alt),
              iconSize: 40,
              color: Theme.of(context).primaryColor,
              tooltip: 'ถ่ายรูปด้วยกล้อง',
            ),
            const Text('ถ่ายภาพ'),
            const SizedBox(height: 8),
            IconButton(
              onPressed: _isUploading ? null : _pickFromGallery,
              icon: const Icon(Icons.photo_library),
              iconSize: 32,
              color: Theme.of(context).primaryColor,
              tooltip: 'เลือกรูปจากคลัง',
            ),
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
                        'แสดงรูปที่เลือก/ถ่าย',
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
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
}
