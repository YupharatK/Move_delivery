import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:move_delivery/pages/welcome_screen.dart'; // Keep this for logout navigation

class UserAppBar extends StatefulWidget implements PreferredSizeWidget {
  const UserAppBar({super.key});

  @override
  State<UserAppBar> createState() => _UserAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(70.0);
}

class _UserAppBarState extends State<UserAppBar> {
  // ⭐️ 1. Add state variables to hold user data and loading status
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // ⭐️ 2. Fetch user data when the widget initializes
    _fetchUserData();
  }

  // ⭐️ 3. Function to fetch user data from Firestore
  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return; // Not logged in
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection(
            'users',
          ) // Assuming user data is in the 'users' collection
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() {
          _userData = doc.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Failed to fetch user data: $e');
      if (mounted) setState(() => _isLoading = false); // Handle error case
    }
  }

  // Helper function to extract the first address city/label (or fallback)
  String _getAddressDisplay(Map<String, dynamic>? userData) {
    if (userData == null) return '...'; // Fallback for loading/error
    final List<dynamic> addresses =
        (userData['addresses'] as List<dynamic>? ?? []);
    if (addresses.isNotEmpty && addresses.first is Map) {
      final a = (addresses.first as Map).cast<String, dynamic>();
      // Prioritize label, then address, then fallback
      final label = (a['label'] ?? '').toString();
      if (label.isNotEmpty && label != '-') return label;
      final addressText = (a['address'] ?? '').toString();
      if (addressText.isNotEmpty && addressText != '-')
        return addressText; // You might want to extract just the city here if needed
    }
    return 'ที่อยู่หลัก'; // Default text if no address found
  }

  @override
  Widget build(BuildContext context) {
    // ⭐️ 4. Use fetched data or show loading/defaults
    final name = (_userData?['name'] ?? 'User').toString();
    final photoUrl = (_userData?['userPhotoUrl'] ?? '').toString();
    final addressDisplay = _getAddressDisplay(_userData);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            // User profile picture
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[300], // Background while loading
              backgroundImage: (photoUrl.isNotEmpty)
                  ? NetworkImage(photoUrl)
                  : null,
              child: (_isLoading)
                  ? const CircularProgressIndicator(
                      strokeWidth: 2,
                    ) // Show loading indicator
                  : (photoUrl.isEmpty)
                  ? const Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.white,
                    ) // Fallback icon
                  : null,
            ),
            const SizedBox(width: 12),
            // User name and address
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isLoading ? 'Loading...' : name, // Show name or 'Loading...'
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _isLoading
                          ? '...'
                          : addressDisplay, // Show address or '...'
                      style: TextStyle(color: Colors.grey[800], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),

            const Spacer(),
            // Logout button
            IconButton(
              onPressed: () async {
                // Make onPressed async for sign out
                try {
                  // ⭐️ 5. Add Firebase sign out logic
                  await FirebaseAuth.instance.signOut();

                  if (!context.mounted)
                    return; // Check mounted before navigation

                  // Navigate back to WelcomeScreen and remove all previous routes
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const WelcomeScreen(),
                    ),
                    (Route<dynamic> route) => false, // Remove all routes
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
                }
              },
              icon: Icon(Icons.logout, color: Colors.grey[700], size: 28),
            ),
          ],
        ),
      ),
    );
  }
}
