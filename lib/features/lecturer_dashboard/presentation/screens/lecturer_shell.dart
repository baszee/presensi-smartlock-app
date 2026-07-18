import 'package:flutter/material.dart';
import 'lecturer_home_screen.dart';
import 'lecturer_profile_screen.dart';
import '../../../jadwal/presentation/screens/lecturer_jadwal_screen.dart';

class LecturerShell extends StatefulWidget {
  const LecturerShell({super.key});

  @override
  State<LecturerShell> createState() => _LecturerShellState();
}

class _LecturerShellState extends State<LecturerShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    LecturerHomeScreen(),
    LecturerJadwalScreen(),
    LecturerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Jadwal'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}