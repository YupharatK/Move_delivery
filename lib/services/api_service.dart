// lib/services/api_service.dart
import 'dart:io';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:move_delivery/models/user_model.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class ApiService {
  static const String _baseUrl = 'http://10.0.2.2:3000';

  Future<String?> uploadProfileImage(File imageFile) async {
    final cloudinary = CloudinaryPublic('ddl3wobhb', 'Move_Upload');

    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl; // คืนค่าเป็น URL ของรูปภาพ
    } on CloudinaryException catch (e) {
      print(e.message);
      print(e.request);
      return null;
    }
  }

  Future<void> createUserProfile(UserProfile userProfile) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userProfile.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create user profile');
    }
  }

  Future<void> addUserAddress(String uid, UserAddress userAddress) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users/$uid/addresses'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userAddress.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add user address');
    }
  }

  // =======================================================
  Future<UserProfile?> getUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }
    final idToken = await user.getIdToken();

    final response = await http.get(
      Uri.parse('$_baseUrl/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return UserProfile.fromJson(json);
    } else {
      print('Failed to load user profile: ${response.body}');
      return null;
    }
  }
}
