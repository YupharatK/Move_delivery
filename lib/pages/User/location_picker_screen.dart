// lib/pages/User/location_picker_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; // ✅ 1. import geolocator

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? _selectedLocation;
  // ✅ 2. สร้าง Controller สำหรับควบคุมแผนที่
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // ✅ 3. เรียกใช้ฟังก์ชันเพื่อดึงตำแหน่งปัจจุบันเมื่อหน้าจอถูกสร้าง
    _determinePositionAndMoveMap();
  }

  // ✅ 4. สร้างฟังก์ชันสำหรับดึงตำแหน่งและย้ายแผนที่
  Future<void> _determinePositionAndMoveMap() async {
    bool serviceEnabled;
    LocationPermission permission;

    // ตรวจสอบว่า Location service เปิดอยู่หรือไม่
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // ถ้าปิดอยู่ ให้แสดง SnackBar แจ้งเตือน
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเปิด GPS เพื่อใช้งาน')),
        );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('แอปต้องการสิทธิ์เข้าถึงตำแหน่ง')),
          );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่สามารถเข้าถึงตำแหน่งได้ กรุณาไปที่การตั้งค่าแอป'),
          ),
        );
      return;
    }

    // เมื่อได้รับสิทธิ์แล้ว ให้ดึงตำแหน่งปัจจุบัน
    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final currentLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        // ปักหมุดที่ตำแหน่งปัจจุบัน
        _selectedLocation = currentLatLng;
      });

      // ย้ายแผนที่ไปยังตำแหน่งปัจจุบัน
      _mapController.move(currentLatLng, 15.0);
    } catch (e) {
      print('เกิดข้อผิดพลาดในการดึงตำแหน่ง: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกตำแหน่งของคุณ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _selectedLocation == null
                ? null
                : () {
                    final result = {
                      'latitude': _selectedLocation!.latitude,
                      'longitude': _selectedLocation!.longitude,
                    };
                    Navigator.of(context).pop(result);
                  },
          ),
        ],
      ),
      // ✅ 7. เพิ่มปุ่ม FloatingActionButton สำหรับกลับมาที่ตำแหน่งปัจจุบัน
      floatingActionButton: FloatingActionButton(
        onPressed: _determinePositionAndMoveMap,
        child: const Icon(Icons.my_location),
      ),
      body: FlutterMap(
        // ✅ 5. เชื่อม MapController เข้ากับ FlutterMap
        mapController: _mapController,
        options: MapOptions(
          initialCenter: const LatLng(13.7563, 100.5018), // fallback location
          initialZoom: 5.0, // ซูมออกมาไกลๆ ก่อน รอตำแหน่งจริง
          onTap: (tapPosition, point) {
            setState(() {
              _selectedLocation = point;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName:
                'com.example.move_delivery', // อย่าลืมเปลี่ยนเป็น package name ของคุณ
          ),
          if (_selectedLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  width: 80.0,
                  height: 80.0,
                  point: _selectedLocation!,
                  child: Icon(
                    Icons.location_pin,
                    color: Colors.red.shade400,
                    size: 60.0,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
