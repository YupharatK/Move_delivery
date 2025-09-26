import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

// Import ไฟล์ Model และ Service ที่เราสร้างขึ้น
import 'package:move_delivery/models/user_model.dart';
import 'package:move_delivery/services/api_service.dart';

// Import หน้าจออื่นๆ (Note: We still need to keep the imports even if we don't use DeliveryMainScreen anymore,
// unless we are sure it's not needed anywhere else in the file.)
import 'package:move_delivery/pages/User/delivery_main_screen.dart'; // ยังคงไว้แต่ไม่ได้ใช้ในส่วน Navigator.pushReplacement
import 'package:move_delivery/pages/User/location_picker_screen.dart';

class RegisterUserScreen extends StatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  State<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {
  // State
  File? _profileImage;
  bool _isLoading = false;

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _gpsController = TextEditingController();

  // สร้าง instance ของ ApiService ไว้ใช้งาน
  final _apiService = ApiService();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _gpsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (ctx) => const LocationPickerScreen()),
    );
    if (result != null && mounted) {
      final latitude = result['latitude'] as double;
      final longitude = result['longitude'] as double;
      _gpsController.text = '$latitude, $longitude';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เลือกพิกัดสำเร็จ! กรุณากรอกรายละเอียดที่อยู่'),
        ),
      );
    }
  }

  Future<void> _register() async {
    final isValid =
        _nameController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _addressController.text.isNotEmpty &&
        _gpsController.text.isNotEmpty &&
        (_passwordController.text == _confirmPasswordController.text);

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วนและถูกต้อง')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      final uid = userCredential.user!.uid;

      String? photoUrl;
      if (_profileImage != null) {
        photoUrl = await _apiService.uploadProfileImage(_profileImage!);
      }

      final newUserProfile = UserProfile(
        uid: uid,
        name: _nameController.text,
        phone: _phoneController.text,
        userPhotoUrl: photoUrl,
      );

      await _apiService.createUserProfile(newUserProfile);

      final gpsParts = _gpsController.text.split(',');
      final latitude = double.parse(gpsParts[0].trim());
      final longitude = double.parse(gpsParts[1].trim());

      final newUserAddress = UserAddress(
        label: 'ที่อยู่หลัก',
        address: _addressController.text,
        latitude: latitude,
        longitude: longitude,
      );

      await _apiService.addUserAddress(uid, newUserAddress);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สมัครสมาชิกสำเร็จ! กรุณาเข้าสู่ระบบ')),
        );

        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Auth Error')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

              const Text(
                'GPS',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _gpsController,
                readOnly: true,
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

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('สมัครสมาชิก'),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('คุณมีบัญชีอยู่แล้ว? '),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
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
