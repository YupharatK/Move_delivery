import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

// หน้านี้คือหน้าที่ Rider จะเห็นหลังจากสมัครสมาชิกหรือล็อกอินสำเร็จ
import 'package:move_delivery/pages/Rider/rider_new_order_screen.dart';
import 'package:move_delivery/pages/login_page.dart';

class RegisterRiderScreen extends StatefulWidget {
  const RegisterRiderScreen({super.key});

  @override
  State<RegisterRiderScreen> createState() => _RegisterRiderScreenState();
}

class _RegisterRiderScreenState extends State<RegisterRiderScreen> {
  //============================================================================
  // ส่วนจัดการ State และ Controllers
  //============================================================================
  File? _profileImage;
  File? _vehicleImage;
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _licensePlateController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  //============================================================================
  // ฟังก์ชันสำหรับเลือกรูปภาพ
  //============================================================================
  Future<void> _pickImage(Function(File) onImagePicked) async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      onImagePicked(File(pickedFile.path));
    }
  }

  //============================================================================
  // ฟังก์ชันสำหรับอัปโหลดไปยัง Cloudinary
  //============================================================================
  Future<String> _uploadFile(File file) async {
    // ใช้ข้อมูล Cloudinary ของคุณ: cloudName และ uploadPreset
    // ตรวจสอบให้แน่ใจว่า 'Move_Upload' เป็น Unsigned Upload Preset
    final cloudinary = CloudinaryPublic(
      'ddl3wobhb',
      'Move_Upload',
      cache: false,
    );

    try {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl; // คืนค่าเป็น URL ของรูปภาพ
    } on CloudinaryException catch (e) {
      print(e.message);
      print(e.request);
      throw Exception('Failed to upload image: ${e.message}');
    }
  }

  //============================================================================
  // ฟังก์ชันหลักในการสมัครสมาชิก
  //============================================================================
  Future<void> _registerRider() async {
    // ตรวจสอบความถูกต้องของข้อมูลในฟอร์ม
    final isValid =
        _nameController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _licensePlateController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _profileImage != null &&
        _vehicleImage != null &&
        (_passwordController.text == _confirmPasswordController.text);

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกข้อมูลและอัปโหลดรูปภาพให้ครบถ้วน'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. สร้างบัญชีใน Firebase Authentication
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      final uid = userCredential.user!.uid;

      // 2. อัปโหลดรูปภาพ 2 รูปไปยัง Cloudinary พร้อมกัน
      final [profileUrl, vehicleUrl] = await Future.wait([
        _uploadFile(_profileImage!),
        _uploadFile(_vehicleImage!),
      ]);

      // 3. เตรียมข้อมูล Rider เพื่อบันทึกลง Cloud Firestore
      final riderData = {
        'uid': uid,
        'name': _nameController.text,
        'phone': _phoneController.text,
        'email': _emailController.text.trim(),
        'licensePlate': _licensePlateController.text,
        'profileImageUrl': profileUrl,
        'vehicleImageUrl': vehicleUrl,
        'role': 'rider', // ระบุ role เพื่อแยกประเภทผู้ใช้ในระบบ
        'createdAt': Timestamp.now(),
        'isAvailable': true, // สถานะเริ่มต้นของไรเดอร์ (พร้อมรับงาน)
      };

      // 4. บันทึกข้อมูลลงใน collection 'riders' ใน Firestore
      await FirebaseFirestore.instance
          .collection('riders')
          .doc(uid)
          .set(riderData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สมัครสมาชิก Rider สำเร็จ!')),
        );
        // เมื่อสำเร็จ, นำทางไปหน้าหลักของ Rider และลบหน้าก่อนหน้าทั้งหมดออก
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (ctx) => const LoginScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Auth Error')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  //============================================================================
  // ส่วนของ UI (User Interface)
  //============================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'สมัครบัญชีไรเดอร์',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'กรอกข้อมูลเพื่อเข้าร่วมเป็นส่วนหนึ่งกับเรา',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImagePicker(
                    label: 'รูปโปรไฟล์',
                    imageFile: _profileImage,
                    onTap: () => _pickImage(
                      (file) => setState(() => _profileImage = file),
                    ),
                  ),
                  _buildImagePicker(
                    label: 'รูปภาพยานพาหนะ',
                    imageFile: _vehicleImage,
                    onTap: () => _pickImage(
                      (file) => setState(() => _vehicleImage = file),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildTextField(
                label: 'ชื่อ-นามสกุล',
                controller: _nameController,
              ),
              _buildTextField(
                label: 'เบอร์โทร',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),
              _buildTextField(
                label: 'อีเมล',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              _buildTextField(
                label: 'ทะเบียนรถ',
                controller: _licensePlateController,
              ),
              _buildTextField(
                label: 'รหัสผ่าน',
                controller: _passwordController,
                obscureText: true,
              ),
              _buildTextField(
                label: 'ยืนยันรหัสผ่าน',
                controller: _confirmPasswordController,
                obscureText: true,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _registerRider,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text('สมัครสมาชิก'),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('คุณมีบัญชีอยู่แล้ว? '),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'เข้าสู่ระบบ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  //============================================================================
  // Widgets ช่วยสร้าง UI เพื่อลดโค้ดซ้ำซ้อน
  //============================================================================
  Widget _buildImagePicker({
    required String label,
    required File? imageFile,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              image: imageFile != null
                  ? DecorationImage(
                      image: FileImage(imageFile),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageFile == null
                ? Icon(Icons.camera_alt, color: Colors.grey[800], size: 40)
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: _inputDecoration(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey[200],
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
    );
  }
}
