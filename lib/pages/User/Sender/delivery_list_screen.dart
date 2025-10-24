// delivery_list_screen.dart (Complete with Address Fix)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// Import SearchReceiverScreen
import 'package:move_delivery/pages/User/Sender/search_receiver_screen.dart';
// Import the CORRECT SenderTrackingListScreen
import 'package:move_delivery/pages/User/Sender/sender_delivery_tracking_screen.dart'; // Make sure this is the correct filename

class ItemsToDispatchScreen extends StatefulWidget {
  const ItemsToDispatchScreen({super.key});

  @override
  State<ItemsToDispatchScreen> createState() => _ItemsToDispatchScreenState();
}

class _ItemsToDispatchScreenState extends State<ItemsToDispatchScreen> {
  Query<Map<String, dynamic>> _ordersQuery(String uid) => FirebaseFirestore
      .instance
      .collection('orders')
      .withConverter<Map<String, dynamic>>(
        fromFirestore: (s, _) => s.data() ?? <String, dynamic>{},
        toFirestore: (m, _) => m,
      )
      .where('userId', isEqualTo: uid)
      .orderBy('createdAt', descending: true);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Items to Dispatch', // Changed to English for clarity
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text('Please log in'))
          : Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      // Updated onPressed for the "Add" button
                      onPressed: () {
                        // Navigate to the screen for searching/selecting a receiver
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SearchReceiverScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'), // Changed to English
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ===== Stream my orders =====
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _ordersQuery(user.uid).snapshots(),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snap.hasError) {
                          return Center(child: Text('Error: ${snap.error}'));
                        }
                        final docs = snap.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return const Center(child: Text('No orders yet'));
                        }

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final d = docs[index];
                            final orderId = d.id;
                            final order = d.data();
                            return _OrderCard(orderId: orderId, order: order);
                          },
                        );
                      },
                    ),
                  ),

                  // Button to go to tracking list
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Ensure navigation goes to the CORRECT tracking screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              // Use the screen that checks 'pendingPhotoUrl'
                              builder: (context) =>
                                  const SenderTrackingListScreen(),
                            ),
                          );
                        },
                        // Changed text for clarity
                        child: const Text('Go to Tracking List'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Card showing 1 order + fetch first item + receiver name + ADDRESS
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.orderId, required this.order, Key? key})
    : super(key: key);

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

  // Helper to extract address string
  String _extractAddressText(Map<String, dynamic>? receiverData) {
    if (receiverData == null) return '-';
    final List<dynamic> addresses =
        (receiverData['addresses'] as List<dynamic>? ?? []);
    if (addresses.isNotEmpty && addresses.first is Map) {
      final a = (addresses.first as Map).cast<String, dynamic>();
      final label = (a['label'] ?? '-') as String;
      final addressText = (a['address'] ?? '-') as String;
      // Combine label and address for display
      if (label != '-' && addressText != '-') {
        return '$label • $addressText';
      } else if (addressText != '-') {
        return addressText;
      } else if (label != '-') {
        return label; // Less likely, but handle just in case
      }
    }
    return '-'; // Default if no address found
  }

  @override
  Widget build(BuildContext context) {
    final status = (order['status'] ?? '-').toString();
    final itemCount = (order['itemCount'] is num)
        ? (order['itemCount'] as num).toInt()
        : 1;
    final total = (order['total'] is num)
        ? (order['total'] as num).toDouble()
        : 0.0;
    final ts = order['createdAt'];
    final createdAt = (ts is Timestamp) ? ts.toDate() : null;

    return FutureBuilder<List<Map<String, dynamic>?>>(
      future: Future.wait([_fetchFirstItem(), _fetchReceiver()]),
      builder: (context, snap) {
        // Handle loading state for futures
        if (snap.connectionState == ConnectionState.waiting) {
          return const Card(
            // Show a placeholder card while loading
            margin: EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        }
        // Handle error state for futures
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
        // Get the address text using the helper
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
                // First item image
                ClipRRect(
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
                // Card content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          const Text(
                            'Shipment Details', // Changed to English
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
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Item details
                      Text(
                        // Changed to English
                        'Item: $name ${itemCount > 1 ? '(+${itemCount - 1} more)' : ''}',
                      ),
                      Text(
                        'Order Total: ${total.toStringAsFixed(2)} ฿',
                      ), // Changed to English
                      // Receiver details
                      const SizedBox(height: 4),
                      Text('To: $receiverName'), // Changed prefix
                      Text('Phone: $receiverPhone'), // Changed prefix
                      // Display the receiver address
                      Text(
                        'Address: $receiverAddress', // Changed prefix
                        maxLines: 2, // Allow address to wrap if long
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[700],
                        ), // Optional styling
                      ),

                      // Date
                      if (createdAt != null) ...[
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
                              '${createdAt.year}  '
                              '${createdAt.hour.toString().padLeft(2, '0')}:'
                              '${createdAt.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
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
    width: 80,
    height: 80,
    color: Colors.grey[200],
    child: const Icon(Icons.image),
  );
}
