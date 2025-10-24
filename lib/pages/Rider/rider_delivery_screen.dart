// rider_delivery_screen.dart (ไฟล์ใหม่)

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart'; // ⭐️ Import
import 'package:latlong2/latlong.dart' as latlong;
// ⭐️ Import หน้าถัดไป
import 'rider_confirm_delivery_screen.dart';

class RiderDeliveryScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const RiderDeliveryScreen({
    super.key,
    required this.orderId,
    required this.orderData,
  });

  @override
  State<RiderDeliveryScreen> createState() => _RiderDeliveryScreenState();
}

class _RiderDeliveryScreenState extends State<RiderDeliveryScreen> {
  final MapController _mapController = MapController();

  // ⭐️ สถานะตำแหน่ง
  latlong.LatLng? _receiverLocation;
  latlong.LatLng? _riderLocation; // ⭐️ ตำแหน่งไรเดอร์ (Real-time)
  final List<Marker> _markers = [];
  StreamSubscription<Position>? _positionStream; // ⭐️ ตัวฟังตำแหน่ง

  // ⭐️ สถานะ UI
  bool _isLoadingLocation = true;
  String _statusText = 'กำลังติดตามตำแหน่ง...';
  bool _isNearDestination = false; // ⭐️ (ข้อ 4.2.4)

  @override
  void initState() {
    super.initState();
    _setupReceiverLocation();
    _startLocationTracking();
  }

  @override
  void dispose() {
    // ⭐️ (สำคัญ) ปิดการฟังตำแหน่ง
    _positionStream?.cancel();
    super.dispose();
  }

  // --- (Helper: _extractLatLng เหมือนเดิม) ---
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

  // 1. ตั้งค่าหมุด "ผู้รับ" (ปลายทาง)
  void _setupReceiverLocation() {
    final receiverData = widget.orderData['receiver'] as Map<String, dynamic>?;
    _receiverLocation = _extractLatLng(receiverData);

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

  // 2. ⭐️ (สำคัญ) เริ่มติดตามตำแหน่งไรเดอร์
  Future<void> _startLocationTracking() async {
    // 2.1 ตรวจสอบ Permission
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _statusText = 'กรุณาเปิด GPS');
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _statusText = 'กรุณาอนุญาตให้เข้าถึงตำแหน่ง');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() => _statusText = 'ไม่อนุญาตให้เข้าถึงตำแหน่ง (ถาวร)');
      return;
    }

    // 2.2 เริ่มฟังตำแหน่ง
    setState(() => _isLoadingLocation = false);
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // อัปเดตทุก 10 เมตร
          ),
        ).listen((Position position) {
          final newPos = latlong.LatLng(position.latitude, position.longitude);

          // 2.3 อัปเดตตำแหน่ง + แผนที่
          setState(() {
            _riderLocation = newPos;
            _updateMarkers(); // (อัปเดตหมุดไรเดอร์)
          });

          // 2.4 ย้ายกล้อง
          _mapController.move(newPos, 16.0);

          // 2.5 อัปเดตตำแหน่งใน Firestore (เพื่อให้ Sender เห็น)
          _updateDriverLocationInFirestore(position);

          // 2.6 ⭐️ (ข้อ 4.2.4) ตรวจสอบระยะทาง
          _checkDistance(newPos);
        });
  }

  // 3. ⭐️ อัปเดตหมุด
  void _updateMarkers() {
    _markers.removeWhere(
      (m) => m.key == const ValueKey('rider'),
    ); // ลบหมุดไรเดอร์เก่า
    if (_riderLocation != null) {
      _markers.add(
        Marker(
          key: const ValueKey('rider'),
          point: _riderLocation!,
          child: Icon(
            Icons.moped,
            color: Theme.of(context).primaryColor,
            size: 40,
          ),
        ),
      );
    }
  }

  // 4. ⭐️ (ข้อ 4.2.3) อัปเดต Firestore
  Future<void> _updateDriverLocationInFirestore(Position position) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
            // ⭐️ นี่คือ field ที่ Sender ใช้
            'driverLocation': GeoPoint(position.latitude, position.longitude),
            'status': 'IN_TRANSIT', // ⭐️ อัปเดตสถานะเป็น "กำลังส่ง"
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Failed to update driver location: $e');
    }
  }

  // 5. ⭐️ (ข้อ 4.2.4) ตรวจสอบระยะทาง
  void _checkDistance(latlong.LatLng riderPos) {
    if (_receiverLocation == null) return;

    final distance = Geolocator.distanceBetween(
      riderPos.latitude,
      riderPos.longitude,
      _receiverLocation!.latitude,
      _receiverLocation!.longitude,
    );

    setState(() {
      _statusText = 'ระยะทาง: ${distance.toStringAsFixed(0)} เมตร';
      // ⭐️ (ข้อ 4.2.4) ถ้าใกล้กว่า 20 เมตร
      if (distance <= 20) {
        _isNearDestination = true;
      } else {
        _isNearDestination = false;
      }
    });
  }

  // 6. ⭐️ ไปหน้ายืนยันการส่งของ
  void _goToConfirmDelivery() {
    Navigator.push(
      // ⭐️ ใช้ Push (ไม่ใช่ Replacement)
      context,
      MaterialPageRoute(
        builder: (_) => RiderConfirmDeliveryScreen(
          orderId: widget.orderId,
          // (เราส่ง orderData ไปด้วย เผื่อต้องใช้)
          orderData: widget.orderData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ⭐️ จุดศูนย์กลางแผนที่เริ่มต้น
    final mapCenter = _receiverLocation ?? const latlong.LatLng(16.43, 102.83);

    return Scaffold(
      appBar: AppBar(title: const Text('กำลังนำส่งสินค้า')),
      body: Stack(
        children: [
          // --- 1. แผนที่ ---
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: mapCenter, initialZoom: 14.0),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.example.move_delivery', // ⭐️ เปลี่ยนเป็น Package Name ของคุณ
              ),
              MarkerLayer(markers: _markers),
            ],
          ),

          // --- 2. แผงควบคุมด้านล่าง ---
          if (!_isLoadingLocation)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _statusText, // 'ระยะทาง: ... เมตร'
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // ⭐️ (ข้อ 4.2.4) ปุ่มจะปรากฏเมื่อใกล้ถึง
                    ElevatedButton(
                      // ⭐️ ถ้าไม่ใกล้ (false) ปุ่มจะกดไม่ได้ (null)
                      onPressed: _isNearDestination
                          ? _goToConfirmDelivery
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isNearDestination
                            ? Colors
                                  .green // ⭐️ สีเขียวเมื่อพร้อม
                            : Colors.grey, // ⭐️ สีเทาเมื่อยังไม่ถึง
                      ),
                      child: Text(
                        _isNearDestination
                            ? 'ถ่ายรูปยืนยันการส่ง (ถึงที่หมายแล้ว)'
                            : 'ยังไม่ถึงที่หมาย',
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // --- 3. Loading (ขณะรอ Permission) ---
          if (_isLoadingLocation)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(_statusText), // 'กำลังติดตามตำแหน่ง...'
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
