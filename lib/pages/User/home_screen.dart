import 'package:flutter/material.dart';

// ไม่ต้อง import UserAppBar แล้ว เพราะเราจะย้ายไปไว้ที่ DeliveryMainScreen
// import 'user_app_bar.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onSendParcelPressed;
  final VoidCallback onReceiveParcelPressed;

  const HomeScreen({
    super.key,
    required this.onSendParcelPressed,
    required this.onReceiveParcelPressed,
  });

  @override
  Widget build(BuildContext context) {
    // ลบ Scaffold และ AppBar ออก ให้ return Padding โดยตรง
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        children: [
          // ไม่มี UserAppBar ที่นี่แล้ว
          const SizedBox(height: 20),
          _buildActionButton(
            context: context,
            icon: Icons.outbox,
            label: 'ส่งของ',
            onTap: onSendParcelPressed,
          ),
          const SizedBox(height: 24),
          _buildActionButton(
            context: context,
            icon: Icons.archive_outlined,
            label: 'รับของ',
            onTap: onReceiveParcelPressed,
          ),
        ],
      ),
    );
  }

  // ... โค้ด _buildActionButton เหมือนเดิม ...
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 120,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
