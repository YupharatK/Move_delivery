// delivery_tracking_screen.dart (อัปเดต: ดึงข้อมูลไรเดอร์)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;

class DeliveryTrackingScreen extends StatefulWidget {
  const DeliveryTrackingScreen({super.key, required this.orderId});
  final String orderId;

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  final MapController _mapController = MapController();

  // --- สถานะแผนที่ ---
  latlong.LatLng? _receiverLocation;
  latlong.LatLng? _senderLocation;
  final List<Marker> _markers = [];
  bool _isLoadingLocations = true;

  // ⭐️ 1. (เพิ่ม) สถานะข้อมูลไรเดอร์
  Map<String, dynamic>? _riderData;
  bool _isLoadingRider = false;
  String? _currentDriverId; // เก็บ ID ไรเดอร์ปัจจุบัน

  late final DocumentReference<Map<String, dynamic>> _orderRef;

  @override
  void initState() {
    super.initState();
    _orderRef = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId);
    _fetchInitialLocations();
  }

  /// ⭐️ (แก้ไข) ฟังก์ชันดึงตำแหน่ง "ผู้ส่ง" (ต้นทาง) และ "ผู้รับ" (ปลายทาง)
  Future<void> _fetchInitialLocations() async {
    setState(() => _isLoadingLocations = true);
    try {
      // 1. ดึงออเดอร์เพื่อหา receiverId และ userId (Sender)
      final orderDoc = await _orderRef.get();
      if (!orderDoc.exists) {
        throw Exception('ไม่พบออเดอร์');
      }
      final orderData = orderDoc.data()!;
      final receiverId = orderData['receiverId'] as String?;
      final senderId = orderData['userId'] as String?; // ⭐️ ID ผู้ส่ง

      // 2. ดึงข้อมูล User ของทั้งคู่ (ถ้ามี)
      final List<DocumentSnapshot> docs = await Future.wait([
        if (receiverId != null && receiverId.isNotEmpty)
          FirebaseFirestore.instance.collection('users').doc(receiverId).get(),
        if (senderId != null && senderId.isNotEmpty)
          FirebaseFirestore.instance.collection('users').doc(senderId).get(),
      ]);

      // 3. แยกข้อมูลพิกัด
      if (docs.isNotEmpty && docs[0].exists) {
        _receiverLocation = _extractLatLng(
          docs[0].data() as Map<String, dynamic>?,
        );
      }
      if (docs.length > 1 && docs[1].exists) {
        _senderLocation = _extractLatLng(
          docs[1].data() as Map<String, dynamic>?,
        );
      }

      if (_receiverLocation == null) debugPrint('ไม่พบพิกัดผู้รับ');
      if (_senderLocation == null) debugPrint('ไม่พบพิกัดผู้ส่ง');
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการดึงตำแหน่ง: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ไม่สามารถโหลดตำแหน่งได้: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocations = false);
      }
    }
  }

  /// ⭐️ ฟังก์ชันช่วยแปลงข้อมูล location (GeoPoint หรือ List) เป็น LatLng
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

  /// แปลง status เป็น step (1-4)
  int _stepFromStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 1;
      case 'ASSIGNED':
      case 'PICKED_UP':
        return 2;
      case 'IN_TRANSIT':
        return 3;
      case 'DELIVERED':
      default:
        return 4;
    }
  }

  /// อ่าน item แรกของออเดอร์ (ชื่อ/รูปสินค้า)
  Future<Map<String, dynamic>?> _fetchFirstItem(String orderId) async {
    final qs = await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .collection('items')
        .limit(1)
        .get();
    if (qs.docs.isEmpty) return null;
    return qs.docs.first.data();
  }

  // ⭐️ 2. (เพิ่ม) ฟังก์ชันดึงข้อมูลไรเดอร์
  Future<void> _fetchRiderInfo(String driverId) async {
    // ถ้ากำลังโหลดอยู่ หรือ ID เดิม ไม่ต้องดึงซ้ำ
    if (_isLoadingRider || driverId == _currentDriverId) return;

    setState(() {
      _isLoadingRider = true;
      _currentDriverId = driverId; // อัปเดต ID ล่าสุด
    });

    try {
      final riderDoc = await FirebaseFirestore.instance
          .collection('riders') // ⭐️ ดึงจาก collection 'riders'
          .doc(driverId)
          .get();

      if (mounted) {
        setState(() {
          _riderData = riderDoc.data();
          _isLoadingRider = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch rider info: $e');
      if (mounted) {
        setState(() => _isLoadingRider = false);
        // (Optional: แสดง SnackBar แจ้งเตือน)
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สถานะการจัดส่ง')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _orderRef.snapshots(),
        builder: (context, snap) {
          // ⭐️ อัปเดตเงื่อนไข loading
          if (snap.connectionState == ConnectionState.waiting ||
              _isLoadingLocations) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snap.error}'));
          }
          if (!snap.hasData || !snap.hasData!) {
            return const Center(child: Text('ไม่พบออเดอร์นี้'));
          }

          final order = snap.data!.data()!;

          // ⭐️⭐️ [ย้ายขึ้นมา] คำนวณ step ทันที ⭐️⭐️
          final status = (order['status'] ?? 'PENDING').toString();
          final step = _stepFromStatus(status);
          // ⭐️⭐️ [จบการย้าย] ⭐️⭐️

          // ⭐️ 3. (แก้ไข) ดึง driverId และเรียก _fetchRiderInfo
          final String? driverId = order['driverId'] as String?;
          if (step >= 2 && driverId != null && driverId.isNotEmpty) {
            // ใช้ addPostFrameCallback เพื่อเรียก setState หลังจาก build เสร็จ
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _fetchRiderInfo(driverId);
              }
            });
          } else if (step < 2 && _riderData != null) {
            // ถ้าสถานะกลับไปน้อยกว่า 2 ให้ล้างข้อมูลไรเดอร์เก่า (เผื่อกรณี Edge Case)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _riderData = null;
                  _currentDriverId = null;
                });
              }
            });
          }

          // --- ⭐️ โลจิกแผนที่ (แก้ไข) ---
          final driverGeoPoint = order['driverLocation'] as GeoPoint?;
          latlong.LatLng? currentDriverLocation;
          _markers.clear(); // ล้างหมุดเก่าเพื่อสร้างใหม่

          // 1. (แสดงเสมอ) เพิ่มหมุดผู้รับ (ปลายทาง) 📍
          if (_receiverLocation != null) {
            _markers.add(
              Marker(
                width: 80.0,
                height: 80.0,
                point: _receiverLocation!,
                child: Icon(
                  Icons.location_on, // ไอคอนหมุดปลายทาง
                  color: Colors.green.shade700,
                  size: 45,
                ),
              ),
            );
          }

          // ⭐️ 2. (เงื่อนไข) เพิ่มหมุดคนขับ หรือ ผู้ส่ง
          // ถ้า step >= 2 (มีคนรับงานแล้ว) -> แสดงคนขับ 🛵
          if (step >= 2 && driverGeoPoint != null) {
            currentDriverLocation = latlong.LatLng(
              driverGeoPoint.latitude,
              driverGeoPoint.longitude,
            );
            _markers.add(
              Marker(
                width: 80.0,
                height: 80.0,
                point: currentDriverLocation,
                child: Icon(
                  Icons.moped, // ไอคอนคนขับ
                  color: Theme.of(context).primaryColor,
                  size: 40,
                ),
              ),
            );

            // ย้ายกล้องไปหาคนขับ
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && currentDriverLocation != null) {
                // Add null check
                _mapController.move(currentDriverLocation!, 16.0);
              }
            });
          }
          // ⭐️ ถ้า step == 1 (ยังไม่มีคนรับงาน) -> แสดงผู้ส่ง 🏬
          else if (step == 1 && _senderLocation != null) {
            _markers.add(
              Marker(
                width: 80.0,
                height: 80.0,
                point: _senderLocation!,
                child: Icon(
                  Icons.store, // ⭐️ ไอคอนผู้ส่ง (ต้นทาง)
                  color: Colors.blue.shade700,
                  size: 40,
                ),
              ),
            );
            // (Optional) ย้ายกล้องไปหาผู้ส่ง
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _senderLocation != null) {
                // Add null check
                _mapController.move(_senderLocation!, 15.0);
              }
            });
          }

          // ⭐️ 3. (แก้ไข) กำหนดจุดศูนย์กลางแผนที่
          final latlong.LatLng mapCenter =
              currentDriverLocation ?? // 1. ถ้ามีคนขับ, ตามคนขับ
              _senderLocation ?? // 2. ถ้าไม่มี, ไปที่ผู้ส่ง
              _receiverLocation ?? // 3. ถ้าไม่มีอีก, ไปที่ผู้รับ
              const latlong.LatLng(16.43, 102.83); // 4. ค่าเริ่มต้น

          final double mapZoom = (currentDriverLocation != null) ? 16.0 : 14.0;
          // --- ⭐️ จบโลจิกแผนที่ ---

          return Stack(
            children: [
              // --- 1) พื้นที่แผนที่ ---
              _buildMapArea(mapCenter, mapZoom),

              // --- 2) แผงข้อมูลด้านล่าง ---
              DraggableScrollableSheet(
                initialChildSize: 0.5,
                minChildSize: 0.2,
                maxChildSize: 0.9,
                builder: (context, scrollController) {
                  final pendingPhotoUrl = (order['pendingPhotoUrl'] ?? '')
                      .toString();
                  final deliveredPhotoUrl = (order['deliveredPhotoUrl'] ?? '')
                      .toString();
                  final total = (order['total'] as num?)?.toDouble() ?? 0.0;
                  final itemCount = (order['itemCount'] as num?)?.toInt() ?? 1;

                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: FutureBuilder<Map<String, dynamic>?>(
                          future: _fetchFirstItem(widget.orderId),
                          builder: (context, itemSnap) {
                            final firstItem = itemSnap.data;
                            final itemName = (firstItem?['name'] ?? '—')
                                .toString();
                            final itemImg = (firstItem?['imageUrl'] ?? '')
                                .toString();
                            final imageToShow = pendingPhotoUrl.isNotEmpty
                                ? pendingPhotoUrl
                                : itemImg;

                            return Column(
                              children: [
                                _buildStatusTracker(
                                  context: context,
                                  currentStep: step,
                                  statusText: status,
                                ),
                                const SizedBox(height: 24),
                                _buildInfoCard(
                                  title: 'รายละเอียดสินค้า',
                                  child: _buildProductDetails(
                                    imageUrl: imageToShow,
                                    name: itemName,
                                    itemCount: itemCount,
                                    total: total,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // ⭐️ (เงื่อนไขนี้ถูกต้องอยู่แล้ว)
                                // ซ่อนข้อมูลไรเดอร์ ถ้า step < 2
                                if (step >= 2) ...[
                                  _buildInfoCard(
                                    title: 'ข้อมูลไรเดอร์',
                                    // ⭐️ 4. (แก้ไข) ส่งข้อมูลไรเดอร์ไปให้ Widget
                                    child: _buildRiderInfo(
                                      riderData: _riderData,
                                      isLoading: _isLoadingRider,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                _buildInfoCard(
                                  title: 'รายงานการส่งสินค้า',
                                  child: _buildDeliveryReport(
                                    deliveredPhotoUrl: deliveredPhotoUrl,
                                    status: status,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed:
                                        (status.toUpperCase() == 'DELIVERED')
                                        ? () => Navigator.pop(context)
                                        : null,
                                    child: Text(
                                      (status.toUpperCase() == 'DELIVERED')
                                          ? 'ปิด'
                                          : 'กำลังจัดส่ง',
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------- Widgets (ส่วนประกอบ UI) ----------

  Widget _buildMapArea(latlong.LatLng center, double zoom) {
    const String yourAppPackageName =
        'com.example.move_delivery'; // ⭐️⭐️⭐️ เปลี่ยนเป็น Package Name ของคุณ

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

  Widget _buildInfoCard({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(padding: const EdgeInsets.all(12.0), child: child),
        ),
      ],
    );
  }

  Widget _buildStatusTracker({
    required BuildContext context,
    required int currentStep,
    required String statusText,
  }) {
    final activeColor = Theme.of(context).primaryColor;
    final inactiveColor = Colors.grey.shade400;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: activeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สถานะการจัดส่ง',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            statusText == 'DELIVERED' ? 'จัดส่งสินค้าเรียบร้อย' : statusText,
            style: TextStyle(color: Colors.white.withOpacity(0.9)),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusIcon(
                Icons.store, // 1. ร้านค้า/รอรับ
                1,
                activeColor,
                inactiveColor,
                isActive: currentStep >= 1,
              ),
              _buildStatusLine(currentStep >= 2, activeColor, inactiveColor),
              _buildStatusIcon(
                Icons.moped, // 2. ไรเดอร์รับของ
                2,
                activeColor,
                inactiveColor,
                isActive: currentStep >= 2,
              ),
              _buildStatusLine(currentStep >= 3, activeColor, inactiveColor),
              _buildStatusIcon(
                Icons.local_shipping, // 3. กำลังนำส่ง
                3,
                activeColor,
                inactiveColor,
                isActive: currentStep >= 3,
              ),
              _buildStatusLine(currentStep >= 4, activeColor, inactiveColor),
              _buildStatusIcon(
                Icons.location_on, // 4. ถึงปลายทาง
                4,
                activeColor,
                inactiveColor,
                isActive: currentStep >= 4,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(
    IconData icon,
    int step,
    Color active,
    Color inactive, {
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : inactive.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: isActive ? active : Colors.white, size: 24),
    );
  }

  Widget _buildStatusLine(bool filled, Color active, Color inactive) {
    return Expanded(
      child: Container(height: 4, color: filled ? active : inactive),
    );
  }

  Widget _buildProductDetails({
    required String imageUrl,
    required String name,
    required int itemCount,
    required double total,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: (imageUrl.isNotEmpty)
              ? Image.network(
                  imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imgFallback(),
                )
              : _imgFallback(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? 'สินค้า' : name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text('จำนวนชิ้น: $itemCount'),
              Text('ยอดรวม: ${total.toStringAsFixed(2)} ฿'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _imgFallback() => Container(
    width: 80,
    height: 80,
    color: Colors.grey[200],
    child: const Icon(Icons.image),
  );

  // ⭐️ 5. (แก้ไข) Widget แสดงข้อมูลไรเดอร์
  Widget _buildRiderInfo({
    required Map<String, dynamic>? riderData,
    required bool isLoading,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (riderData == null) {
      return const Center(child: Text('ไม่พบข้อมูลไรเดอร์'));
    }

    // ดึงข้อมูลจาก Map
    final name = (riderData['name'] ?? 'ไรเดอร์').toString();
    final phone = (riderData['phone'] ?? '-').toString();
    final vehicle = (riderData['vehicleRegistration'] ?? '-').toString();
    final photoUrl = (riderData['userPhotoUrl'] ?? '').toString();

    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey[300],
          backgroundImage: (photoUrl.isNotEmpty)
              ? NetworkImage(photoUrl)
              : null,
          child: (photoUrl.isEmpty)
              ? const Icon(Icons.person, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('เบอร์โทร : $phone'),
            Text('ทะเบียนรถ : $vehicle'),
          ],
        ),
      ],
    );
  }

  Widget _buildDeliveryReport({
    required String deliveredPhotoUrl,
    required String status,
  }) {
    if (status.toUpperCase() != 'DELIVERED') {
      return Row(
        children: [
          Container(
            width: 80,
            height: 80,
            color: Colors.grey[200],
            child: const Icon(Icons.inventory_2_outlined),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('การจัดส่งยังไม่เสร็จสิ้น...')),
        ],
      );
    }

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: (deliveredPhotoUrl.isNotEmpty)
              ? Image.network(
                  deliveredPhotoUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imgFallback(),
                )
              : _imgFallback(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              deliveredPhotoUrl.isNotEmpty
                  ? 'สินค้าของคุณถึงจุดหมายเรียบร้อยแล้ว'
                  : 'จัดส่งสำเร็จ (ไม่มีรูปยืนยัน)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.green.shade900),
            ),
          ),
        ),
      ],
    );
  }
}
