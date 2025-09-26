// lib/models/user_model.dart

class UserProfile {
  final String uid;
  final String name;
  final String phone;
  final String role;
  final String? userPhotoUrl; // อาจเป็นค่าว่างได้

  UserProfile({
    required this.uid,
    required this.name,
    required this.phone,
    this.role = 'user', // กำหนดค่าเริ่มต้น
    this.userPhotoUrl,
  });

  // ฟังก์ชันสำหรับแปลง Class เป็น Map<String, dynamic> เพื่อส่งไปยัง Backend
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'role': role,
      'user_photo': userPhotoUrl,
    };
  }

  static Future<UserProfile?> fromJson(json) async {}
}

class UserAddress {
  final String label;
  final String address;
  final double latitude;
  final double longitude;

  UserAddress({
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  // ฟังก์ชันสำหรับแปลง Class เป็น Map<String, dynamic>
  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'address': address,
      'geopoint': {'latitude': latitude, 'longitude': longitude},
    };
  }
}
