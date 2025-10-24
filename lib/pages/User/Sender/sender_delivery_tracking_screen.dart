// sender_delivery_tracking_screen.dart (Complete with Address Fix)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:move_delivery/pages/User/Sender/delivery_tracking_screen.dart';
import 'package:move_delivery/pages/User/Sender/sender_confirm_screen.dart';

class SenderTrackingListScreen extends StatefulWidget {
  const SenderTrackingListScreen({super.key});

  @override
  State<SenderTrackingListScreen> createState() =>
      _SenderTrackingListScreenState();
}

class _SenderTrackingListScreenState extends State<SenderTrackingListScreen> {
  Query<Map<String, dynamic>> _ordersQuery(String uid) => FirebaseFirestore
      .instance
      .collection('orders')
      .withConverter<Map<String, dynamic>>(
        fromFirestore: (s, _) => s.data() ?? <String, dynamic>{},
        toFirestore: (m, _) => m,
      )
      .where('userId', isEqualTo: uid) // ✅ Specific to the sender
      // Use docId to prevent issues with createdAt type variations
      .orderBy(FieldPath.documentId, descending: true);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Track My Shipments')), // English text
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: user == null
            ? const Center(child: Text('Please log in'))
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _ordersQuery(user.uid).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Firestore error: ${snapshot.error}'),
                    );
                  }
                  final orders = snapshot.data?.docs ?? [];
                  if (orders.isEmpty) {
                    return const Center(
                      child: Text('You have no orders yet'), // English text
                    );
                  }

                  return ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final d = orders[index];
                      final orderId = d.id;
                      final order = d.data();
                      // Pass data to _OrderCard
                      return _OrderCard(orderId: orderId, order: order);
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.orderId, required this.order});
  final String orderId;
  final Map<String, dynamic> order;

  Future<Map<String, dynamic>?> _fetchFirstItem() async {
    final qs = await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .collection('items')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (s, _) => s.data() ?? <String, dynamic>{},
          toFirestore: (m, _) => m,
        )
        .limit(1)
        .get();
    if (qs.docs.isEmpty) return null;
    return qs.docs.first.data();
  }

  Future<Map<String, dynamic>?> _fetchReceiver() async {
    final rid = (order['receiverId'] ?? '').toString();
    if (rid.isEmpty) return null;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(rid)
        .get();
    return doc.data();
  }

  // Helper to extract address string (same as in delivery_list_screen)
  String _extractAddressText(Map<String, dynamic>? receiverData) {
    if (receiverData == null) return '-';
    final List<dynamic> addresses =
        (receiverData['addresses'] as List<dynamic>? ?? []);
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
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    final status = (order['status'] ?? '-').toString();
    final total = (order['total'] is num)
        ? (order['total'] as num).toDouble()
        : 0.0;
    final itemCount = (order['itemCount'] is num)
        ? (order['itemCount'] as num).toInt()
        : 1;
    final ts = order['createdAt'];
    final createdAt = (ts is Timestamp) ? ts.toDate() : null;

    final pendingPhotoUrl = (order['pendingPhotoUrl'] ?? '').toString();
    final bool isPendingConfirmed = pendingPhotoUrl.isNotEmpty;

    return FutureBuilder<List<Map<String, dynamic>?>>(
      future: Future.wait([_fetchFirstItem(), _fetchReceiver()]),
      builder: (context, snap) {
        // Handle loading and error states for futures
        if (snap.connectionState == ConnectionState.waiting) {
          return const Card(
            margin: EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        }
        if (snap.hasError) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text('Error loading details: ${snap.error}'),
            ),
          );
        }

        final firstItem = (snap.data != null && snap.data!.isNotEmpty)
            ? snap.data![0]
            : null;
        final receiver = (snap.data != null && snap.data!.length > 1)
            ? snap.data![1]
            : null;

        final name = (firstItem?['name'] ?? '—').toString();
        final img = (firstItem?['imageUrl'] ?? '').toString();
        final receiverName = (receiver?['name'] ?? '—').toString();
        final receiverPhone = (receiver?['phone'] ?? '—').toString();
        // Get the address text
        final receiverAddress = _extractAddressText(receiver);

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  /* ... Image ... */
                  borderRadius: BorderRadius.circular(8),
                  child: (img.isNotEmpty)
                      ? Image.network(
                          img,
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
                      Row(
                        /* ... Header + Status ... */
                        children: [
                          const Text(
                            'Shipment Details', // English text
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.withOpacity(.08),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        /* ... Item details ... */
                        'Item: $name${itemCount > 1 ? " (+${itemCount - 1} more)" : ""}', // English text
                      ),
                      Text('To: $receiverName'), // English prefix
                      Text('Phone: $receiverPhone'), // English prefix
                      // Display the receiver address
                      Text(
                        'Address: $receiverAddress', // English prefix
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[700],
                        ), // Optional styling
                      ),
                      Text(
                        'Total: ${total.toStringAsFixed(2)} ฿',
                      ), // English prefix
                      if (createdAt != null) ...[
                        /* ... Date ... */
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${createdAt.day.toString().padLeft(2, '0')}/'
                              '${createdAt.month.toString().padLeft(2, '0')}/'
                              '${createdAt.year} '
                              '${createdAt.hour.toString().padLeft(2, '0')}:'
                              '${createdAt.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),

                      // ▶️ Conditional Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: Icon(
                            isPendingConfirmed
                                ? Icons.check_circle
                                : Icons.camera_alt,
                          ),
                          label: Text(
                            // English text
                            isPendingConfirmed
                                ? 'Check Status'
                                : 'Confirm w/ Photo',
                          ),
                          onPressed: () {
                            if (isPendingConfirmed) {
                              // Go to tracking screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DeliveryTrackingScreen(orderId: orderId),
                                ),
                              );
                            } else {
                              // Go to photo confirmation screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SenderConfirmPhotoScreen(
                                    orderId: orderId,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _imgFallback() => Container(
    /* ... Fallback Image ... */
    width: 80,
    height: 80,
    color: Colors.grey[200],
    child: const Icon(Icons.image),
  );
}
