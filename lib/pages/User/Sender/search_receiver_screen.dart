import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:move_delivery/pages/User/Sender/product_details_screen.dart';

class SearchReceiverScreen extends StatefulWidget {
  const SearchReceiverScreen({super.key});

  @override
  State<SearchReceiverScreen> createState() => _SearchReceiverScreenState();
}

class _SearchReceiverScreenState extends State<SearchReceiverScreen> {
  String _searchPhone = "";

  String _normalizePhone(String s) =>
      s.replaceAll(RegExp(r'[^0-9]'), ''); // เก็บเฉพาะตัวเลข

  @override
  Widget build(BuildContext context) {
    final String normalized = _normalizePhone(_searchPhone);

    final Query<Map<String, dynamic>> query = (normalized.isEmpty)
        ? FirebaseFirestore.instance.collection('users')
        : FirebaseFirestore.instance
              .collection('users')
              .where('phone', isEqualTo: normalized);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ค้นหาด้วยเบอร์โทร
          TextFormField(
            keyboardType: TextInputType.phone,
            onChanged: (v) => setState(() => _searchPhone = v.trim()),
            decoration: InputDecoration(
              hintText: 'กรอกหมายเลขโทรศัพท์ของผู้รับ',
              filled: true,
              fillColor: Colors.grey[200],
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'เลือกผู้รับ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text('ไม่พบผู้รับที่ค้นหา'));
                }

                final currentUid = FirebaseAuth.instance.currentUser?.uid;
                final allDocs = snapshot.data!.docs;

                // ✅ กรอง “ไม่แสดงตัวเอง”
                final docs = (currentUid == null)
                    ? allDocs
                    : allDocs.where((d) => d.id != currentUid).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('ไม่พบผู้รับที่ค้นหา'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final uid = doc.id; // ใช้ doc.id เป็น receiverUid
                    final data = doc.data();

                    final name = (data['name'] ?? '-') as String;
                    // แนะนำให้เก็บ phone ในฐานข้อมูลแบบ normalized (ตัวเลขล้วน)
                    final phone = (data['phone'] ?? '-') as String;
                    final photo = (data['userPhotoUrl'] ?? '') as String;

                    // addresses: [{label, address, location:[lat,lng] หรือ GeoPoint}]
                    final List<dynamic> addresses =
                        (data['addresses'] as List<dynamic>? ?? []);

                    String addressLabel = '-';
                    String addressText = '-';
                    String coordsText = '';

                    if (addresses.isNotEmpty && addresses.first is Map) {
                      final addr = (addresses.first as Map)
                          .cast<String, dynamic>();
                      addressLabel = (addr['label'] ?? '-') as String;
                      addressText = (addr['address'] ?? '-') as String;

                      final loc = addr['location'];
                      if (loc is List && loc.length >= 2) {
                        coordsText = '(${loc[0]}, ${loc[1]})';
                      } else if (loc is GeoPoint) {
                        coordsText = '(${loc.latitude}, ${loc.longitude})';
                      }
                    }

                    return _buildResultTile(
                      context: context,
                      receiverUid: uid,
                      name: name,
                      phone: phone,
                      photoUrl: photo,
                      addressLabel: addressLabel,
                      addressText: addressText,
                      coordsText: coordsText,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTile({
    required BuildContext context,
    required String receiverUid,
    required String name,
    required String phone,
    required String photoUrl,
    required String addressLabel,
    required String addressText,
    required String coordsText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ชื่อ
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                // เบอร์โทร
                Text(
                  'เบอร์โทร $phone',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                // ที่อยู่ + พิกัด (สั้น ๆ)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on, color: Colors.grey[600], size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '$addressLabel • $addressText'
                        '${coordsText.isNotEmpty ? ' $coordsText' : ''}',
                        style: TextStyle(color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // ✅ ส่ง uid ไปหน้าถัดไป
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ProductDetailsScreen(receiverUid: receiverUid),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('เลือก'),
          ),
        ],
      ),
    );
  }
}
