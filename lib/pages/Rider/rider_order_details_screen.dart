// rider_order_details_screen.dart (ไฟล์ใหม่)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:move_delivery/pages/Rider/rider_confirm_pickup_screen.dart';
import 'rider_app_bar.dart'; // (ถ้า AppBar อยู่คนละ Folder ต้องแก้ Path)

class RiderOrderDetailsScreen extends StatefulWidget {
  // ⭐️ 1. รับ Order ID เข้ามา
  final String orderId;
  const RiderOrderDetailsScreen({super.key, required this.orderId});

  @override
  State<RiderOrderDetailsScreen> createState() =>
      _RiderOrderDetailsScreenState();
}

class _RiderOrderDetailsScreenState extends State<RiderOrderDetailsScreen> {
  late Future<Map<String, dynamic>> _dataFuture;
  bool _isAccepting = false;

  final MapController _mapController = MapController();
  latlong.LatLng? _receiverLocation;
  latlong.LatLng? _senderLocation;
  final List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    // ⭐️ 2. เรียกใช้ฟังก์ชันดึงข้อมูล โดยใช้ ID จาก widget
    _dataFuture = _fetchAllData(widget.orderId);
  }

  // (Helper: _extractAddressText, _extractLatLng เหมือนเดิม)
  String _extractAddressText(Map<String, dynamic>? userData) {
    if (userData == null) return 'ไม่พบที่อยู่';
    final List<dynamic> addresses =
        (userData['addresses'] as List<dynamic>? ?? []);
    if (addresses.isNotEmpty && addresses.first is Map) {
      final a = (addresses.first as Map).cast<String, dynamic>();
      final label = (a['label'] ?? '-') as String;
      final addressText = (a['address'] ?? '-') as String;
      if (label != '-' && addressText != '-') {
        return '$label • $addressText';
      } else if (addressText != '-') {
        return addressText;
      } else if (label != '-') {
        return label;
      }
    }
    return 'ไม่พบที่อยู่';
  }

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

  // ⭐️ 3. (แก้ไข) ฟังก์ชันดึงข้อมูลโดยใช้ ID
  Future<Map<String, dynamic>> _fetchAllData(String orderId) async {
    try {
      final db = FirebaseFirestore.instance;

      // 1. ดึง Order
      final orderRef = db.collection('orders').doc(orderId);
      final orderDoc = await orderRef.get();
      if (!orderDoc.exists) throw Exception('ไม่พบออเดอร์');
      final orderData = orderDoc.data()!;

      final senderId = orderData['userId'] as String;
      final receiverId = orderData['receiverId'] as String;

      // 2. ดึง Sender และ Receiver
      final List<DocumentSnapshot> userDocs = await Future.wait([
        db.collection('users').doc(senderId).get(),
        db.collection('users').doc(receiverId).get(),
      ]);
      final senderData = userDocs[0].data() as Map<String, dynamic>?;
      final receiverData = userDocs[1].data() as Map<String, dynamic>?;

      // 3. ดึง Item ชิ้นแรก
      final itemsSnap = await orderRef.collection('items').limit(1).get();
      final firstItemData = itemsSnap.docs.isNotEmpty
          ? itemsSnap.docs.first.data()
          : null;

      // 4. (สำหรับแผนที่) แยกพิกัด
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

      // 5. ส่งข้อมูลทั้งหมดกลับไปให้ FutureBuilder
      return {
        'order': orderData,
        'sender': senderData,
        'receiver': receiverData,
        'item': firstItemData,
      };
    } catch (e) {
      debugPrint('Error fetching all data: $e');
      rethrow;
    }
  }

  // ⭐️ 4. (เหมือนเดิม) ฟังก์ชันกดยรับงาน
  Future<void> _acceptOrder(Map<String, dynamic> dataToPass) async {
    final driver = FirebaseAuth.instance.currentUser;
    if (driver == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณาล็อกอินก่อนรับงาน')));
      return;
    }

    setState(() => _isAccepting = true);
    final db = FirebaseFirestore.instance;
    final orderRef = db
        .collection('orders')
        .doc(widget.orderId); // ⭐️ ใช้ ID จาก widget

    try {
      // ⭐️ ใช้ Transaction เพื่อป้องกันการรับงานซ้ำ
      await db.runTransaction((transaction) async {
        final freshDoc = await transaction.get(orderRef);
        if (!freshDoc.exists) throw Exception('ออเดอร์นี้ไม่มีอยู่แล้ว');

        final data = freshDoc.data()!;
        final status = data['status'] ?? '';
        final pendingPhotoUrl = data['pendingPhotoUrl'] ?? '';

        if (status != 'PENDING' || pendingPhotoUrl.isEmpty) {
          throw Exception('ออเดอร์นี้ถูกรับไปแล้ว หรือ ยังไม่พร้อม');
        }

        transaction.update(orderRef, {
          'status': 'ASSIGNED',
          'driverId': driver.uid,
          'assignedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;
      // ⭐️ ส่งต่อไปหน้ายืนยันรับของ (Confirm Pickup)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RiderConfirmPickupScreen(
            orderId: widget.orderId,
            orderData: dataToPass,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('รับงานล้มเหลว: $e')));
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⭐️ ใช้ AppBar ปกติ (เพราะหน้านี้จะมาจากหน้า List)
    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดออเดอร์')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('ไม่พบข้อมูลออเดอร์'));
          }

          // (ส่วน UI ที่เหลือเหมือนเดิมทั้งหมด)
          final data = snapshot.data!;
          final order = data['order'] as Map<String, dynamic>?;
          final sender = data['sender'] as Map<String, dynamic>?;
          final receiver = data['receiver'] as Map<String, dynamic>?;
          final item = data['item'] as Map<String, dynamic>?;

          if (order == null || sender == null || receiver == null) {
            return const Center(child: Text('ข้อมูลออเดอร์ไม่สมบูรณ์'));
          }

          final itemName = (item?['name'] ?? 'สินค้า').toString();
          final itemCount = (order['itemCount'] ?? 1).toString();
          final itemImgUrl =
              (item?['imageUrl'] ?? order['pendingPhotoUrl'] ?? '').toString();

          final senderName = (sender['name'] ?? 'ผู้ส่ง').toString();
          final senderPhone = (sender['phone'] ?? '-').toString();
          final senderAddress = _extractAddressText(sender);

          final receiverName = (receiver['name'] ?? 'ผู้รับ').toString();
          final receiverPhone = (receiver['phone'] ?? '-').toString();
          final receiverAddress = _extractAddressText(receiver);

          final mapCenter =
              _senderLocation ??
              _receiverLocation ??
              const latlong.LatLng(16.43, 102.83);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // (ไม่ต้องมี Text 'ออเดอร์ใหม่' เพราะอยู่ใน AppBar)
                  _buildMapArea(mapCenter, 13.0),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: (itemImgUrl.isNotEmpty)
                                    ? Image.network(
                                        itemImgUrl,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _imgFallback(),
                                      )
                                    : _imgFallback(),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'รายการสินค้า',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text('รายการ : $itemName'),
                                  Text('จำนวน : $itemCount รายการ'),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildAddressDetail(
                            context: context,
                            role: 'ผู้ส่ง',
                            name: senderName,
                            phone: senderPhone,
                            address: senderAddress,
                          ),
                          const SizedBox(height: 16),
                          _buildAddressDetail(
                            context: context,
                            role: 'ผู้รับ',
                            name: receiverName,
                            phone: receiverPhone,
                            address: receiverAddress,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isAccepting
                                      ? null
                                      : () => _acceptOrder(data),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).primaryColor,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: _isAccepting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('รับ'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isAccepting
                                      ? null
                                      : () {
                                          Navigator.pop(
                                            context,
                                          ); // ⭐️ กด "ยกเลิก" คือการ "กลับ"
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber[700],
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('ยกเลิก'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- (Widgets ช่วย ที่เหลือเหมือนเดิม) ---
  Widget _imgFallback() => Container(
    width: 60,
    height: 60,
    color: Colors.grey[200],
    child: const Icon(Icons.image),
  );

  Widget _buildAddressDetail({
    required BuildContext context,
    required String role,
    required String name,
    required String phone,
    required String address,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$role : $name',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text('เบอร์โทร : $phone'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.location_on,
              color: (role == 'ผู้ส่ง')
                  ? Theme.of(context).primaryColor
                  : Colors.green.shade700,
              size: 16,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(address, style: TextStyle(color: Colors.grey[800])),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMapArea(latlong.LatLng center, double zoom) {
    const String yourAppPackageName = 'com.example.move_delivery';

    return SizedBox(
      height: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: center, initialZoom: zoom),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: yourAppPackageName,
            ),
            MarkerLayer(markers: _markers),
          ],
        ),
      ),
    );
  }
}
