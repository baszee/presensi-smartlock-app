import 'package:flutter/material.dart';
import '../features/dashboard/presentation/screens/home_screen.dart';
import '../features/jadwal/presentation/screens/jadwal_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';

/// Widget ini adalah "kerangka utama" aplikasi setelah user login.
/// Isinya Bottom Navigation Bar + 3 halaman (Home, Jadwal, Profile)
/// yang bisa di-switch tanpa kehilangan state masing-masing halaman.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Index halaman yang lagi aktif (0 = Home, 1 = Jadwal, 2 = Profile)
  int _selectedIndex = 0;

  // Daftar halaman yang bakal ditampilkan.
  // IndexedStack menjaga semua halaman tetap "hidup" di background,
  // jadi kalau pindah tab, state halaman sebelumnya gak hilang.
  final List<Widget> _screens = const [
    HomeScreen(),
    JadwalScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Jadwal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}