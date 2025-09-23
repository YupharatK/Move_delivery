import 'dart:io'; // ใช้สำหรับจัดการไฟล์รูปภาพ
import 'package:flutter/material.dart';
import 'package:move_delivery/pages/User/delivery_main_screen.dart';
// import 'package:image_picker/image_picker.dart'; // TODO: เพิ่ม dependency นี้สำหรับเลือกรูป
// import 'location_picker_screen.dart'; // TODO: import หน้าเลือกพิกัด

class RegisterUserScreen extends StatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  State<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {
  // State สำหรับเก็บไฟล์รูปภาพที่เลือก
  File? _profileImage;

  // Controllers สำหรับช่องกรอกข้อมูล
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _gpsController =
      TextEditingController(); // ช่องนี้จะให้ map อัปเดตค่าให้

  // ฟังก์ชันสำหรับเลือกรูปภาพ (UI-only for now)
  Future<void> _pickImage() async {
    // TODO: ใส่ Logic การเลือกรูปภาพโดยใช้ package image_picker
    // final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    // if (pickedFile != null) {
    //   setState(() {
    //     _profileImage = File(pickedFile.path);
    //   });
    // }
    print('Picking image...');
  }

  // ฟังก์ชันสำหรับเลือกพิกัดจากแผนที่ (UI-only for now)
  Future<void> _pickLocation() async {
    // TODO: ใส่ Logic การนำทางและรับค่าจาก LocationPickerScreen
    // final result = await Navigator.of(context).push(
    //   MaterialPageRoute(builder: (ctx) => const LocationPickerScreen()),
    // );
    // if (result != null) {
    //   final selectedAddress = result['address'];
    //   final selectedLatLng = result['latlng'];
    //   _addressController.text = selectedAddress;
    //   _gpsController.text = '${selectedLatLng.latitude}, ${selectedLatLng.longitude}';
    // }
    print('Picking location...');
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

              // ส่วนเลือกรูปโปรไฟล์
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : null,
                    child: _profileImage == null
                        ? Icon(
                            Icons.camera_alt,
                            color: Colors.grey[800],
                            size: 40,
                          )
                        : null,
                  ),
                ),
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
                label: 'รหัสผ่าน',
                controller: _passwordController,
                obscureText: true,
              ),
              _buildTextField(
                label: 'ยืนยันรหัสผ่าน',
                controller: _confirmPasswordController,
                obscureText: true,
              ),
              _buildTextField(
                label: 'ที่อยู่',
                controller: _addressController,
                maxLines: 3,
              ),

              // ช่อง GPS ที่มีไอคอนให้กด
              const Text(
                'GPS',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _gpsController,
                readOnly: true, // ทำให้พิมพ์แก้ไขไม่ได้
                decoration: _inputDecoration().copyWith(
                  hintText: 'เลือกจากแผนที่',
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.map,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: _pickLocation,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ปุ่มสมัครสมาชิก
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const DeliveryMainScreen(), // ไปที่หน้าหลักของการส่งของ
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
                      // TODO: นำทางกลับไปหน้า Login
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

  // Widget สำหรับสร้างฟอร์ม เพื่อลดการเขียนโค้ดซ้ำ
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    int maxLines = 1,
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
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: _inputDecoration(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ฟังก์ชันสำหรับตกแต่ง TextFormField (เหมือนกับหน้า Login)
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
