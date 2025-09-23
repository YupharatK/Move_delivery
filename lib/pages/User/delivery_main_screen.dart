import 'package:flutter/material.dart';
import 'package:move_delivery/pages/User/Sender/search_receiver_screen.dart';
import 'home_screen.dart';
import 'custom_bottom_nav_bar.dart';
import 'user_app_bar.dart'; // Import UserAppBar เข้ามาที่นี่

class DeliveryMainScreen extends StatefulWidget {
  const DeliveryMainScreen({super.key});

  @override
  State<DeliveryMainScreen> createState() => _DeliveryMainScreenState();
}

class _DeliveryMainScreenState extends State<DeliveryMainScreen> {
  int _selectedIndex = 0;
  bool _isSearching = false;

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _isSearching = false;
    });
  }

  // แก้ไขฟังก์ชันนี้
  PreferredSizeWidget _buildAppBar() {
    if (_isSearching) {
      return AppBar(
        title: const Text(
          'ค้นหาผู้รับ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: _stopSearch,
        ),
      );
    } else {
      switch (_selectedIndex) {
        case 0: // เมื่ออยู่ที่แท็บ "หน้าแรก"
          return const UserAppBar(); // ให้แสดง UserAppBar ที่เราสร้างไว้
        case 1:
          return AppBar(title: const Text('รายการจัดส่ง'));
        case 2:
          return AppBar(title: const Text('โปรไฟล์'));
        default:
          return AppBar();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      HomeScreen(
        onSendParcelPressed: _startSearch,
        onReceiveParcelPressed: () {
          print('Receive Parcel Tapped');
        },
      ),
      // DeliveryListScreen(onSearchPressed: _startSearch),
      // const ProfileScreen(),
    ];

    return Scaffold(
      appBar: _buildAppBar(),
      body: _isSearching
          ? const SearchReceiverScreen()
          : pages.elementAt(_selectedIndex),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
