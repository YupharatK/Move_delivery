// create_product_screen.dart (ไฟล์ใหม่)

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _pickedImage;
  bool _isUploading = false;

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();

  // (ใช้ Cloudinary config เดียวกันกับ sender_confirm_screen)
  final _cloudinary = CloudinaryPublic(
    'ddl3wobhb',
    'Move_Upload',
    cache: false,
  );

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // --- (ฟังก์ชัน _takePhoto และ _pickFromGallery เหมือนเดิม) ---
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

  Future<void> _pickFromGallery() async {
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (x == null) return;
      setState(() => _pickedImage = File(x.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เลือกรูปจากคลังไม่สำเร็จ: $e')));
    }
  }

  // --- อัปโหลดไป Cloudinary ---
  Future<String> _uploadToCloudinary(File file) async {
    final res = await _cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        file.path,
        folder: 'products', // เก็บในโฟลเดอร์ products
        resourceType: CloudinaryResourceType.Image,
      ),
    );
    return res.secureUrl;
  }

  // --- บันทึกสินค้าใหม่ ---
  Future<void> _saveProduct() async {
    // 1. ตรวจสอบ Form และ รูปภาพ
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_pickedImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณาเลือกรูปสินค้า')));
      return;
    }

    setState(() => _isUploading = true);
    try {
      // 2. อัปโหลดรูป ได้ URL
      final imageUrl = await _uploadToCloudinary(_pickedImage!);

      // 3. เตรียมข้อมูล
      final name = _nameController.text.trim();
      final desc = _descController.text.trim();
      final price = double.tryParse(_priceController.text) ?? 0.0;

      final db = FirebaseFirestore.instance;
      final newProductRef = db.collection('products').doc(); // จอง ID

      final newProductData = {
        'name': name,
        'description': desc,
        'price': price,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // 4. บันทึกลง Firestore
      await newProductRef.set(newProductData);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกสินค้าใหม่สำเร็จ!')));

      // 5. ส่งข้อมูลสินค้าใหม่ (รวม ID) กลับไปหน้า ProductPicker
      // (เพิ่ม ID เข้าไปใน Map)
      newProductData['id'] = newProductRef.id;
      Navigator.pop(context, newProductData);
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
      appBar: AppBar(title: const Text('เพิ่มสินค้าใหม่')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- ส่วนเลือกรูป ---
              AspectRatio(
                aspectRatio: 16 / 10,
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
                            'เลือกรูปสินค้า',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : null,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _isUploading ? null : _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    tooltip: 'ถ่ายภาพ',
                  ),
                  IconButton(
                    onPressed: _isUploading ? null : _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    tooltip: 'เลือกจากคลัง',
                  ),
                ],
              ),

              // --- ฟอร์มรายละเอียด ---
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'ชื่อสินค้า'),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'กรุณาใส่ชื่อสินค้า' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'รายละเอียด (ย่อ)',
                ),
                maxLines: 3,
                // (validator อาจจะไม่จำเป็นสำหรับ desc)
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'ราคา',
                  prefixText: '฿ ',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v?.trim().isEmpty ?? true) return 'กรุณาใส่ราคา';
                  if (double.tryParse(v!) == null) return 'ราคาไม่ถูกต้อง';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // --- ปุ่มบันทึก ---
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _saveProduct,
                icon: _isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isUploading ? 'กำลังบันทึก...' : 'บันทึกสินค้า'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
