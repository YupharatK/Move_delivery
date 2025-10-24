// product_details_screen.dart (Complete code using flutter_map)

import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'
    as latlong; // Use alias to avoid conflict
import 'package:move_delivery/pages/User/Sender/productpickerscreen.dart'; // Ensure this path is correct
import 'package:move_delivery/pages/User/Sender/create_product_screen.dart'; // Ensure this path is correct

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.receiverUid});
  final String receiverUid;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final List<Map<String, dynamic>> _selectedProducts = [];
  bool _isPlacingOrder = false;

  // Map Controller and State for flutter_map
  final MapController _mapController = MapController();
  latlong.LatLng? _receiverLocation; // Use latlong.LatLng
  List<Marker> _markers = []; // Use Marker from flutter_map

  // --- Firestore Streams ---
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

  // --- Product Selection ---
  Future<void> _openProductPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const ProductPickerScreen()),
    );
    if (result != null) {
      final existingIndex = _selectedProducts.indexWhere(
        (p) => p['productId'] == result['productId'],
      );
      setState(() {
        if (existingIndex >= 0) {
          // Update quantity if product already in cart
          _selectedProducts[existingIndex]['qty'] = result['qty'];
        } else {
          // Add new product to cart
          _selectedProducts.add(result);
        }
      });
    }
  }

  void _removeProduct(int index) {
    setState(() {
      _selectedProducts.removeAt(index);
    });
  }

  // --- Place Order Logic ---
  Future<void> _placeOrder() async {
    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add products to the order first')),
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in before placing an order')),
      );
      return;
    }
    if (widget.receiverUid.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Receiver not selected')));
      return;
    }

    setState(() => _isPlacingOrder = true);

    // Calculate totals
    double calculatedSubtotal = 0;
    int calculatedItemCount = 0; // Counts distinct product types
    for (var product in _selectedProducts) {
      final price = (product['price'] as num?)?.toDouble() ?? 0.0;
      final qty = (product['qty'] as int?) ?? 1;
      calculatedSubtotal += price * qty;
      calculatedItemCount += 1; // Count each product entry as 1 item type
    }
    const double discount = 0.0;
    const double shipping = 0.0;
    final double calculatedTotal = calculatedSubtotal - discount + shipping;

    try {
      // Verify receiver exists
      final receiverDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.receiverUid)
          .get();
      if (!receiverDoc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receiver not found (uid: ${widget.receiverUid})'),
          ),
        );
        setState(() => _isPlacingOrder = false);
        return;
      }

      final db = FirebaseFirestore.instance;
      final orderRef = db.collection('orders').doc(); // Auto-generate ID
      final batch = db.batch();

      // Set main order document
      batch.set(orderRef, {
        'userId': user.uid,
        'receiverId': widget.receiverUid,
        'status': 'PENDING',
        'itemCount': calculatedItemCount,
        'subtotal': calculatedSubtotal,
        'discount': discount,
        'shippingFee': shipping,
        'total': calculatedTotal,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Set each item in the subcollection
      for (var product in _selectedProducts) {
        final productId = product['productId'] as String;
        final itemRef = orderRef
            .collection('items')
            .doc(productId); // Use product ID for item doc ID
        final name = (product['name'] ?? '-').toString();
        final imageUrl = (product['imageUrl'] ?? '').toString();
        final price = (product['price'] as num?)?.toDouble() ?? 0.0;
        final qty = (product['qty'] as int?) ?? 1;
        final amount = price * qty;
        batch.set(itemRef, {
          'productId': productId,
          'name': name,
          'price': price,
          'qty': qty,
          'amount': amount,
          'imageUrl': imageUrl,
        });
      }

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order placed successfully (#${orderRef.id})')),
      );
      Navigator.of(
        context,
      ).pop({'orderId': orderRef.id}); // Pop back with order ID
    } catch (e, st) {
      debugPrint('Place order failed: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to place order: $e')));
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  // --- Map Update Logic ---
  void _updateMap(Map<String, dynamic> receiverData) {
    // Extract location data (can be GeoPoint or List [lat, lng])
    final locationData = receiverData['addresses']?[0]?['location'];
    latlong.LatLng? targetPosition;

    if (locationData is GeoPoint) {
      targetPosition = latlong.LatLng(
        locationData.latitude,
        locationData.longitude,
      );
    } else if (locationData is List &&
        locationData.length >= 2 &&
        locationData[0] is num &&
        locationData[1] is num) {
      targetPosition = latlong.LatLng(
        locationData[0].toDouble(),
        locationData[1].toDouble(),
      );
    }

    // Update state and map only if position is valid and changed
    if (targetPosition != null && targetPosition != _receiverLocation) {
      // Use addPostFrameCallback to ensure the map controller is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Ensure widget is still mounted
          setState(() {
            _receiverLocation = targetPosition;
            _markers = [
              Marker(
                width: 80.0,
                height: 80.0,
                point: targetPosition!,
                child: Icon(
                  // Simple marker icon
                  Icons.location_pin,
                  color: Colors.green.shade700,
                  size: 45.0,
                ),
              ),
            ];
          });
          // Move map camera
          _mapController.move(targetPosition!, 15.0); // Zoom level 15
        }
      });
    } else if (targetPosition == null && _receiverLocation != null) {
      // If location becomes invalid, clear marker
      setState(() {
        _receiverLocation = null;
        _markers = [];
      });
      debugPrint("Receiver location data is missing or invalid.");
    } else if (targetPosition == null && _markers.isNotEmpty) {
      // Ensure markers are clear if location was never valid
      setState(() {
        _markers = [];
      });
      debugPrint("Receiver location data is missing or invalid.");
    }
  }

  // -------------------- UI Build Method --------------------
  @override
  Widget build(BuildContext context) {
    final bool hasProducts = _selectedProducts.isNotEmpty;
    // ⭐️⭐️⭐️ IMPORTANT: Replace with your actual package name ⭐️⭐️⭐️
    // Find this in android/app/build.gradle (look for applicationId)
    const String yourAppPackageName =
        'com.example.move_delivery'; // <-- REPLACE THIS

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details'), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // "Add Product" Button
              OutlinedButton.icon(
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Add Product from Catalog'),
                onPressed: _isPlacingOrder ? null : _openProductPicker,
              ),
              const SizedBox(height: 12),

              // Product List (Cart) or Empty Message
              if (hasProducts)
                _buildProductList()
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'Your order is empty. Add products using the button above.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Sender, Receiver, and Map Section
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
                stream: _senderStream(),
                builder: (context, senderSnap) {
                  if (senderSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!senderSnap.hasData ||
                      senderSnap.data == null ||
                      !senderSnap.data!.exists) {
                    return _errorCard(
                      'Sender data not found. Please log in again.',
                    );
                  }
                  final sender = senderSnap.data!.data()!;

                  // Stream for Receiver Data
                  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: _receiverStream(),
                    builder: (context, receiverSnap) {
                      Map<String, dynamic>? receiver;
                      // Only process receiver data if loaded successfully
                      if (receiverSnap.connectionState !=
                              ConnectionState.waiting &&
                          receiverSnap.hasData &&
                          receiverSnap.data!.exists) {
                        receiver = receiverSnap.data!.data()!;
                        // Call _updateMap when receiver data is available
                        _updateMap(receiver!);
                      }

                      // Build UI structure (Address Card + Map Container)
                      return Column(
                        children: [
                          // Address Card (Shows sender always, receiver when loaded)
                          _buildAddressSection(
                            sender: sender,
                            receiver: receiver, // Can be null while loading
                          ),
                          const SizedBox(height: 16),

                          // Map Container
                          SizedBox(
                            height: 250, // Map height
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter:
                                      _receiverLocation ??
                                      const latlong.LatLng(
                                        16.43,
                                        102.83,
                                      ), // Default center (Khon Kaen)
                                  initialZoom: _receiverLocation == null
                                      ? 10.0
                                      : 15.0, // Adjust zoom based on location availability
                                ),
                                children: [
                                  // OpenStreetMap Tile Layer
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    // ⭐️ Use the correct package name here ⭐️
                                    userAgentPackageName: yourAppPackageName,
                                  ),
                                  // Marker Layer
                                  MarkerLayer(markers: _markers),
                                ],
                              ),
                            ),
                          ),
                          // Display error if receiver failed to load
                          if (receiverSnap.connectionState !=
                                  ConnectionState.waiting &&
                              (!receiverSnap.hasData ||
                                  !receiverSnap.data!.exists))
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: _errorCard(
                                'Receiver not found (uid: ${widget.receiverUid})',
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 48),

              // Confirm Order Button
              ElevatedButton.icon(
                onPressed: hasProducts && !_isPlacingOrder ? _placeOrder : null,
                icon: _isPlacingOrder
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  _isPlacingOrder ? 'Placing Order…' : 'Confirm Order',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: hasProducts
                      ? Theme.of(context).primaryColor
                      : Colors.grey, // Grey out if no products
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _errorCard(String message) {
    return Card(
      color: Colors.red.withOpacity(.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(message, style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  // Widget to display the list of selected products (Cart)
  Widget _buildProductList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Selected Products:",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true, // Needed inside SingleChildScrollView
          physics:
              const NeverScrollableScrollPhysics(), // Disable internal scrolling
          itemCount: _selectedProducts.length,
          separatorBuilder: (context, index) =>
              const Divider(height: 1, indent: 16, endIndent: 16),
          itemBuilder: (context, index) {
            final p = _selectedProducts[index];
            final name = (p['name'] ?? '-').toString();
            final double price = (p['price'] as num?)?.toDouble() ?? 0.0;
            final int qty = (p['qty'] as int?) ?? 1;
            final img = (p['imageUrl'] ?? '').toString();
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ), // Adjust padding
              leading: ClipRRect(
                // Add rounded corners to image
                borderRadius: BorderRadius.circular(4.0),
                child: (img.isNotEmpty)
                    ? Image.network(
                        img,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image),
                      ),
              ),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                '${qty} x ${price.toStringAsFixed(2)} ฿ = ${(qty * price).toStringAsFixed(2)} ฿',
                style: TextStyle(color: Colors.grey[600]),
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red.shade400,
                ),
                tooltip: 'Remove',
                onPressed: _isPlacingOrder ? null : () => _removeProduct(index),
              ),
            );
          },
        ),
        const Divider(height: 1), // Add final divider
      ],
    );
  }

  // Extracts address details from user data
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
      // Handle both GeoPoint and List [lat, lng]
      if (loc is GeoPoint) {
        coords =
            '(${loc.latitude.toStringAsFixed(6)}, ${loc.longitude.toStringAsFixed(6)})'; // Format coords
      } else if (loc is List &&
          loc.length >= 2 &&
          loc[0] is num &&
          loc[1] is num) {
        coords =
            '(${loc[0].toStringAsFixed(6)}, ${loc[1].toStringAsFixed(6)})'; // Format coords
      }
      return (label: label, address: addressText, coords: coords);
    }
    return (label: '-', address: '-', coords: ''); // Default values
  }

  // Builds the card showing sender and receiver addresses
  Widget _buildAddressSection({
    required Map<String, dynamic> sender,
    required Map<String, dynamic>?
    receiver, // Receiver can be null while loading
  }) {
    final s = _extractAddress(sender);
    // Extract receiver address only if receiver data is available
    final r = receiver != null ? _extractAddress(receiver) : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildAddressRow(
              icon: Icons.person_pin_circle_outlined, // Sender icon
              label: 'Sender Address',
              name: sender['name'] ?? '-',
              phone: sender['phone'] ?? '-',
              addressLabel: s.label,
              addressText: s.address,
              iconColor: Colors.blueAccent, // Sender color
              coordsText: s.coords,
            ),
            const Divider(height: 24, thickness: 0.5),
            // Show receiver details or a loading placeholder
            if (receiver != null && r != null)
              _buildAddressRow(
                icon: Icons.location_on_outlined, // Receiver icon
                label: 'Receiver Address',
                name: receiver['name'] ?? '-',
                phone: receiver['phone'] ?? '-',
                addressLabel: r.label,
                addressText: r.address,
                iconColor: Colors.green.shade600, // Receiver color
                coordsText: r.coords,
              )
            else
              const Padding(
                // Loading state placeholder
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: Colors.grey,
                      size: 24,
                    ),
                    SizedBox(width: 16),
                    Text(
                      "Loading receiver details...",
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Builds a single row within the address card
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
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ), // Smaller label
              ),
              const SizedBox(height: 4),
              Text(
                '$name  •  $phone', // Display name and phone together
                style: const TextStyle(
                  fontSize: 15, // Slightly smaller main text
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              // Display address label and text, handle cases where one might be missing
              if (addressLabel != '-' && addressText != '-')
                Text(
                  '$addressLabel • $addressText',
                  style: TextStyle(color: Colors.grey[800]),
                )
              else if (addressText != '-')
                Text(addressText, style: TextStyle(color: Colors.grey[800]))
              else if (addressLabel != '-')
                Text(addressLabel, style: TextStyle(color: Colors.grey[800])),

              // Display coordinates if available
              if (coordsText.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  coordsText,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
} // End of _ProductDetailsScreenState
