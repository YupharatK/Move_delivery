import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:move_delivery/pages/User/Sender/productpickerscreen.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.receiverUid});
  final String receiverUid;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  File? _productImage;
  final _productNameController = TextEditingController();
  final _productDetailsController = TextEditingController();

  Map<String, dynamic>? _selectedProduct;
  bool _isPlacingOrder = false;

  @override
  void dispose() {
    _productNameController.dispose();
    _productDetailsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    debugPrint('Picking product image...');
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>?> _senderStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Stream<DocumentSnapshot<Map<String, dynamic>>?>.empty();
    }
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _receiverStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.receiverUid)
        .snapshots();
  }

  Future<void> _openProductPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const ProductPickerScreen()),
    );
    if (result != null) {
      setState(() => _selectedProduct = result);
    }
  }

  // -------------------- สร้างออเดอร์ --------------------
  Future<void> _placeOrder() async {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณาเลือกสินค้าก่อน')));
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนทำรายการ')),
      );
      return;
    }
    if (widget.receiverUid.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ไม่พบผู้รับที่เลือก')));
      return;
    }

    // ดึงค่าจากสินค้าที่เลือก — ทำให้ชนิดตรงแน่นอน
    final String productId = '${_selectedProduct!['productId']}';
    final String name = (_selectedProduct!['name'] ?? '-').toString();
    final String imageUrl = (_selectedProduct!['imageUrl'] ?? '').toString();

    final rawPrice = _selectedProduct!['price'];
    final double price = (rawPrice is num)
        ? rawPrice.toDouble()
        : double.tryParse('${rawPrice ?? ''}') ?? 0.0;

    final dynamic rawQty = _selectedProduct!['qty'];
    final int qty = (rawQty is int)
        ? rawQty
        : int.tryParse('${rawQty ?? '1'}') ?? 1;

    // คำนวณยอด
    final double amount = price * qty;
    final double subtotal = amount;
    const double discount = 0.0;
    const double shipping = 0.0;
    final double total = subtotal - discount + shipping;

    setState(() => _isPlacingOrder = true);

    try {
      // (ทางเลือก) ตรวจว่ามี receiver อยู่จริง
      final receiverDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.receiverUid)
          .get();
      if (!receiverDoc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่พบผู้รับ (uid: ${widget.receiverUid})')),
        );
        setState(() => _isPlacingOrder = false);
        return;
      }

      final db = FirebaseFirestore.instance;
      final orderRef = db.collection('orders').doc(); // auto-id
      final itemRef = orderRef.collection('items').doc(productId);

      // ใช้ WriteBatch (อ่าน error ง่าย)
      final batch = db.batch();

      batch.set(orderRef, {
        'userId': user.uid,
        'receiverId': widget.receiverUid,
        'status': 'PENDING',
        'itemCount': 1,
        'subtotal': subtotal,
        'discount': discount,
        'shippingFee': shipping,
        'total': total,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.set(itemRef, {
        'productId': productId,
        'name': name,
        'price': price,
        'qty': qty,
        'amount': amount,
        'imageUrl': imageUrl,
      });

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('สร้างออเดอร์สำเร็จ (#${orderRef.id})')),
      );

      Navigator.of(
        context,
      ).pop({'orderId': orderRef.id, 'product': _selectedProduct});
    } catch (e, st) {
      debugPrint('Place order failed: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('สร้างออเดอร์ไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  // -------------------- UI --------------------
  @override
  Widget build(BuildContext context) {
    final hasSelected = _selectedProduct != null;

    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดสินค้า'), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.store),
                      label: Text(
                        hasSelected ? 'เปลี่ยนสินค้า' : 'เลือกจากคลังสินค้า',
                      ),
                      onPressed: _isPlacingOrder ? null : _openProductPicker,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (hasSelected) _buildSelectedProductSection(_selectedProduct!),
              const SizedBox(height: 24),

              // ผู้ส่ง + ผู้รับ
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
                stream: _senderStream(),
                builder: (context, senderSnap) {
                  if (senderSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!senderSnap.hasData || senderSnap.data == null) {
                    return _errorCard('ยังไม่ได้เข้าสู่ระบบ');
                  }
                  if (!senderSnap.data!.exists) {
                    return _errorCard('ไม่พบข้อมูลผู้ส่ง');
                  }
                  final sender = senderSnap.data!.data()!;

                  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: _receiverStream(),
                    builder: (context, receiverSnap) {
                      if (receiverSnap.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!receiverSnap.hasData || !receiverSnap.data!.exists) {
                        return _errorCard(
                          'ไม่พบข้อมูลผู้รับ (uid: ${widget.receiverUid})',
                        );
                      }
                      final receiver = receiverSnap.data!.data()!;
                      return _buildAddressSection(
                        sender: sender,
                        receiver: receiver,
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 48),

              ElevatedButton.icon(
                onPressed: _isPlacingOrder ? null : _placeOrder,
                icon: _isPlacingOrder
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  _isPlacingOrder ? 'กำลังสร้างคำสั่งซื้อ…' : 'ยืนยัน',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorCard(String message) {
    return Card(
      color: Colors.red.withOpacity(.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(message, style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildSelectedProductSection(Map<String, dynamic> p) {
    final name = (p['name'] ?? '-').toString();
    // กันกรณี description เป็น null
    final desc = (p['description'] ?? '').toString();
    // กันชนราคา -> double แน่นอน
    final double price = (p['price'] is num)
        ? (p['price'] as num).toDouble()
        : double.tryParse('${p['price'] ?? 0}') ?? 0.0;
    final img = (p['imageUrl'] ?? '').toString();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (img.isNotEmpty)
                  ? Image.network(img, width: 90, height: 90, fit: BoxFit.cover)
                  : Container(
                      width: 90,
                      height: 90,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${price.toStringAsFixed(2)} ฿',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'ล้างสินค้า',
              onPressed: _isPlacingOrder
                  ? null
                  : () => setState(() => _selectedProduct = null),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }

  ({String label, String address, String coords}) _extractAddress(
    Map<String, dynamic> user,
  ) {
    final List<dynamic> addresses = (user['addresses'] as List<dynamic>? ?? []);
    if (addresses.isNotEmpty && addresses.first is Map) {
      final a = (addresses.first as Map).cast<String, dynamic>();
      final label = (a['label'] ?? '-') as String;
      final addressText = (a['address'] ?? '-') as String;

      String coords = '';
      final loc = a['location'];
      if (loc is List && loc.length >= 2) {
        coords = '(${loc[0]}, ${loc[1]})';
      } else if (loc is GeoPoint) {
        coords = '(${loc.latitude}, ${loc.longitude})';
      }
      return (label: label, address: addressText, coords: coords);
    }
    return (label: '-', address: '-', coords: '');
  }

  Widget _buildAddressSection({
    required Map<String, dynamic> sender,
    required Map<String, dynamic> receiver,
  }) {
    final s = _extractAddress(sender);
    final r = _extractAddress(receiver);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildAddressRow(
              icon: Icons.location_on,
              label: 'ที่อยู่ผู้ส่ง',
              name: sender['name'] ?? '-',
              phone: sender['phone'] ?? '-',
              addressLabel: s.label,
              addressText: s.address,
              iconColor: Colors.red,
              coordsText: s.coords,
            ),
            const Divider(height: 24),
            _buildAddressRow(
              icon: Icons.location_on,
              label: 'ที่อยู่ผู้รับ',
              name: receiver['name'] ?? '-',
              phone: receiver['phone'] ?? '-',
              addressLabel: r.label,
              addressText: r.address,
              iconColor: Colors.green,
              coordsText: r.coords,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String name,
    required String phone,
    required String addressLabel,
    required String addressText,
    String coordsText = '',
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                '$name  •  $phone',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text('$addressLabel • $addressText'),
              if (coordsText.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(coordsText, style: TextStyle(color: Colors.grey[600])),
              ],
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
