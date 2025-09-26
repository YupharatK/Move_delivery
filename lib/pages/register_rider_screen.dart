import 'dart:io';
import 'package:flutter/material.dart';
import 'package:move_delivery/pages/Rider/rider_new_order_screen.dart';
// import 'package:image_picker/image_picker.dart'; // TODO: เพิ่ม dependency นี้

class RegisterRiderScreen extends StatefulWidget {
  const RegisterRiderScreen({super.key});

  @override
  State<RegisterRiderScreen> createState() => _RegisterRiderScreenState();
}

class _RegisterRiderScreenState extends State<RegisterRiderScreen> {
  // State สำหรับเก็บไฟล์รูปภาพ 2 รูป
  File? _profileImage;
  File? _vehicleImage;

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // ฟังก์ชันสำหรับเลือกรูปภาพ
  Future<void> _pickImage(Function(File) onImagePicked) async {
    // TODO: ใส่ Logic การเลือกรูปภาพโดยใช้ package image_picker
    // final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    // if (pickedFile != null) {
    //   onImagePicked(File(pickedFile.path));
    // }
    print('Picking image...');
  }

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
                'สมัครบัญชี',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'คุณสามารถสมัครบัญชีของคุณได้ที่นี่',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              // ส่วนเลือกรูปภาพ 2 รูป
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImagePicker(
                    label: 'รูปภาพ',
                    imageFile: _profileImage,
                    onTap: () async {
                      // TODO: Implement image picking logic
                      // For now, we'll just show a placeholder setState
                      setState(() {
                        // This is a placeholder. Real logic would use the picker.
                      });
                    },
                  ),
                  _buildImagePicker(
                    label: 'รูปภาพยานพาหนะ',
                    imageFile: _vehicleImage,
                    onTap: () async {
                      // TODO: Implement image picking logic
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ฟอร์มสมัคร
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

              const SizedBox(height: 12), // ลดระยะห่างเล็กน้อย
              // ปุ่มสมัครสมาชิก
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const RiderNewOrderScreen(), // ไปที่หน้าหลักของการส่งของ
                      ),
                    );
                  },
                  child: const Text('สมัครสมาชิก'),
                ),
              ),
              const SizedBox(height: 24),

              // ลิงก์สำหรับเข้าสู่ระบบ
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

  // Widget สำหรับสร้างช่องเลือกรูปภาพ
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
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  // Widget สำหรับสร้างฟอร์ม (เหมือนเดิม)
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

  // ฟังก์ชันสำหรับตกแต่ง TextFormField (เหมือนเดิม)
  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey[200],
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
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
