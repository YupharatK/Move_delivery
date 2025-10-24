// rider_confirm_pickup_screen.dart (อัปเดต: เชื่อมกล้อง, Cloudinary, Firebase)

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // ⭐️ Import
import 'package:flutter_map/flutter_map.dart'; // ⭐️ Import
import 'package:latlong2/latlong.dart' as latlong;
import 'package:move_delivery/pages/Rider/rider_delivery_screen.dart'; // ⭐️ Import

class RiderConfirmPickupScreen extends StatefulWidget {
  // ⭐️ รับ Order ID และ ข้อมูลที่ดึงมาแล้ว
  final String orderId;
  final Map<String, dynamic> orderData;

  const RiderConfirmPickupScreen({
    super.key,
    required this.orderId,
    required this.orderData,
  });

  @override
  State<RiderConfirmPickupScreen> createState() =>
      _RiderConfirmPickupScreenState();
}

class _RiderConfirmPickupScreenState extends State<RiderConfirmPickupScreen> {
  File? _pickedImage; // State สำหรับเก็บรูปที่ถ่าย
  bool _isUploading = false; // ⭐️ สถานะกำลังอัปโหลด

  // ⭐️ (ใช้ Cloudinary config เดียวกันกับ sender_confirm_screen)
  final _cloudinary = CloudinaryPublic(
    'ddl3wobhb',
    'Move_Upload',
    cache: false,
  );

  // ⭐️ สถานะแผนที่
  final MapController _mapController = MapController();
  latlong.LatLng? _receiverLocation;
  latlong.LatLng? _senderLocation;
  final List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    // ⭐️ ใช้ข้อมูลที่ส่งมาจากหน้าก่อนหน้าเพื่อตั้งค่าแผนที่
    _setupMapLocations();
  }

  // ⭐️ 1. Helper: แปลง GeoPoint/List เป็น LatLng
  // (คัดลอกมาจาก delivery_tracking_screen.dart)
  latlong.LatLng? _extractLatLng(Map<String, dynamic>? userData) {
    if (userData == null) return null;
    final locationData = userData['addresses']?[0]?['location'];
    if (locationData is GeoPoint) {
      return latlong.LatLng(locationData.latitude, locationData.longitude);
    } else if (locationData is List &&
        locationData.length >= 2 &&
        locationData[0] is num &&
        locationData[1] is num) {
      return latlong.LatLng(
        locationData[0].toDouble(),
        locationData[1].toDouble(),
      );
    }
    return null;
  }

  // ⭐️ 2. Helper: ดึงข้อมูลที่อยู่จาก User Data
  String _extractAddressText(Map<String, dynamic>? userData) {
    if (userData == null) return 'ไม่พบที่อยู่';
    // (เหมือนกับในไฟล์ rider_new_order_screen.dart)
    final List<dynamic> addresses =
        (userData['addresses'] as List<dynamic>? ?? []);
    if (addresses.isNotEmpty && addresses.first is Map) {
      final a = (addresses.first as Map).cast<String, dynamic>();
      final label = (a['label'] ?? '-') as String;
      final addressText = (a['address'] ?? '-') as String;
      if (label != '-' && addressText != '-') return '$label • $addressText';
      if (addressText != '-') return addressText;
      if (label != '-') return label;
    }
    return 'ไม่พบที่อยู่';
  }

  // ⭐️ 3. ตั้งค่าแผนที่จาก widget.orderData
  void _setupMapLocations() {
    final senderData = widget.orderData['sender'] as Map<String, dynamic>?;
    final receiverData = widget.orderData['receiver'] as Map<String, dynamic>?;

    _senderLocation = _extractLatLng(senderData);
    _receiverLocation = _extractLatLng(receiverData);

    _markers.clear();
    if (_senderLocation != null) {
      _markers.add(
        Marker(
          point: _senderLocation!,
          child: Icon(Icons.store, color: Colors.blue.shade700, size: 40),
        ),
      );
    }
    if (_receiverLocation != null) {
      _markers.add(
        Marker(
          point: _receiverLocation!,
          child: Icon(
            Icons.location_on,
            color: Colors.green.shade700,
            size: 45,
          ),
        ),
      );
    }
  }

  // ⭐️ 4. Logic ถ่ายรูป (Requirement 4.2.2)
  // (คัดลอกมาจาก sender_confirm_screen.dart)
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

  // ⭐️ 5. Logic อัปโหลด Cloudinary
  Future<String> _uploadToCloudinary(File file) async {
    final res = await _cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        file.path,
        // ⭐️ เก็บในโฟลเดอร์ย่อยของออเดอร์
        folder: 'orders/${widget.orderId}/pickup',
        resourceType: CloudinaryResourceType.Image,
      ),
    );
    return res.secureUrl;
  }

  // ⭐️ 6. Logic ยืนยันการรับสินค้า (Confirm Pickup)
  Future<void> _confirmPickup() async {
    if (_pickedImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณาถ่ายรูปยืนยันก่อน')));
      return;
    }

    setState(() => _isUploading = true);
    try {
      // 1. อัปโหลดรูป ได้ URL
      final imageUrl = await _uploadToCloudinary(_pickedImage!);
      final driverId = FirebaseAuth.instance.currentUser?.uid;

      // 2. อัปเดต Firestore
      final orderRef = FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId);

      await orderRef.update({
        'status': 'PICKED_UP', // ⭐️ เปลี่ยนสถานะ
        'pickedUpPhotoUrl': imageUrl, // ⭐️ เก็บรูปล่าสุด
        'pickedUpAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. (แนะนำ) เก็บประวัติใน subcollection
      await orderRef.collection('status_media').doc('PICKED_UP').set({
        'type': 'image',
        'url': imageUrl,
        'byUid': driverId,
        'at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ยืนยันรับสินค้าสำเร็จ!')));

      // ⭐️ TODO: ไปหน้าถัดไป (เช่น หน้าแผนที่นำทางไปส่งของ)
      // สำหรับตอนนี้ เราจะแค่ Pop กลับไปหน้า List (ที่ยังไม่มี)
      // เราใช้ popUntil เพื่อกลับไปหน้าแรก (หน้า List ของ Rider)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RiderDeliveryScreen(
            orderId: widget.orderId,
            orderData: widget.orderData, // ⭐️ ส่งข้อมูลเดิมต่อไปเลย
          ),
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
    // ⭐️ จุดศูนย์กลางแผนที่
    final mapCenter =
        _senderLocation ??
        _receiverLocation ??
        const latlong.LatLng(16.43, 102.83);

    return Scaffold(
      appBar: AppBar(title: const Text('ยืนยันการรับสินค้า')),
      body: Stack(
        children: [
          // --- 1. พื้นที่แผนที่จริง ---
          _buildMapArea(mapCenter, 14.0),

          // --- 2. แผงข้อมูลที่เลื่อนได้ ---
          DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.65,
            maxChildSize: 0.9,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- การ์ดรายละเอียดสินค้า (ใช้ข้อมูลที่ส่งมา) ---
                        _buildDetailsCard(),
                        const SizedBox(height: 24),

                        // --- ส่วนถ่ายรูป (Requirement 4.2.2) ---
                        _buildPhotoSection(),
                        const SizedBox(height: 24),

                        // --- ปุ่มยืนยันการรับสินค้า ---
                        ElevatedButton(
                          onPressed: _isUploading ? null : _confirmPickup,
                          child: _isUploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('ยืนยันการรับสินค้า'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- (Widgets ช่วย) ---

  // ⭐️ (เพิ่ม) Widget แผนที่
  Widget _buildMapArea(latlong.LatLng center, double zoom) {
    // ⭐️⭐️⭐️ ใส่ Package Name ของแอปคุณตรงนี้ ⭐️⭐️⭐️
    const String yourAppPackageName = 'com.example.move_delivery';

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(initialCenter: center, initialZoom: zoom),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: yourAppPackageName,
        ),
        MarkerLayer(markers: _markers),
      ],
    );
  }

  // Widget สำหรับสร้างการ์ดรายละเอียด (ใช้ข้อมูลจาก widget.orderData)
  Widget _buildDetailsCard() {
    // ⭐️ ดึงข้อมูลจาก widget
    final item = widget.orderData['item'] as Map<String, dynamic>?;
    final sender = widget.orderData['sender'] as Map<String, dynamic>?;
    final receiver = widget.orderData['receiver'] as Map<String, dynamic>?;
    final order = widget.orderData['order'] as Map<String, dynamic>?;

    final itemName = (item?['name'] ?? 'สินค้า').toString();
    final itemCount = (order?['itemCount'] ?? 1).toString();
    final itemImgUrl = (item?['imageUrl'] ?? order?['pendingPhotoUrl'] ?? '')
        .toString();

    final senderAddress = _extractAddressText(sender);
    final receiverAddress = _extractAddressText(receiver);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'รายละเอียดสินค้า',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (itemImgUrl.isNotEmpty)
                      ? Image.network(
                          itemImgUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imgFallback(),
                        )
                      : _imgFallback(),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('จำนวน : $itemCount รายการ'),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            _buildAddressRow(
              icon: Icons.storefront,
              label: 'รับสินค้าที่',
              address: senderAddress, // ⭐️ ใช้ข้อมูลจริง
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 12),
            _buildAddressRow(
              icon: Icons.person_pin_circle,
              label: 'ส่งสินค้าที่',
              address: receiverAddress, // ⭐️ ใช้ข้อมูลจริง
              color: Colors.green.shade700,
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgFallback() => Container(
    width: 50,
    height: 50,
    color: Colors.grey[200],
    child: const Icon(Icons.image),
  );

  // Widget สำหรับสร้างแถวที่อยู่
  Widget _buildAddressRow({
    required IconData icon,
    required String label,
    required String address,
    required Color color,
  }) {
    // (เหมือนเดิม)
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey)),
              Text(
                address,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget สำหรับส่วนถ่ายรูป
  Widget _buildPhotoSection() {
    return Column(
      children: [
        const Text(
          'ถ่ายรูปยืนยันการรับสินค้า', // ⭐️ เปลี่ยน Text
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _isUploading ? null : _takePhoto, // ⭐️ เรียกใช้ _takePhoto
          child: Container(
            height: 150,
            width: 150,
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
        const SizedBox(height: 12),
        // ⭐️ อาจจะไม่จำเป็นต้องมีปุ่มนี้ ถ้ากดที่รูปได้เลย
        // ElevatedButton(
        //   onPressed: _isUploading ? null : _takePhoto,
        //   style: ElevatedButton.styleFrom(
        //     backgroundColor: Colors.amber[700],
        //     foregroundColor: Colors.white,
        //   ),
        //   child: const Text('ถ่าย/เปลี่ยนรูป'),
        // ),
      ],
    );
  }
}
