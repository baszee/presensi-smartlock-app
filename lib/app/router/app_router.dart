import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// --- IMPORTS ---
import '../../features/auth/presentation/screens/login_screen.dart';
import '../main_shell.dart'; // Shell untuk Mahasiswa
import '../../features/lecturer_dashboard/presentation/screens/lecturer_shell.dart'; // Shell untuk Dosen

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    // Gerbang Tol: Cek role setiap kali navigasi
    redirect: (context, state) async {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token');
      final role = await storage.read(key: 'user_role');

      final isGoingToLogin = state.matchedLocation == '/login';

      if (token == null) {
        return isGoingToLogin ? null : '/login';
      }

      if (isGoingToLogin) {
        return role == 'dosen' ? '/lecturer/home' : '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home', // Rute Mahasiswa
        builder: (context, state) => const MainShell(),
      ),
      GoRoute(
        path: '/lecturer/home', // Rute Dosen
        builder: (context, state) => const LecturerShell(), // 👈 Sudah diganti jadi LecturerShell
      ),
    ],
  );
});