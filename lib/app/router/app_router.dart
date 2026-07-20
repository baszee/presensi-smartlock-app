import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// --- IMPORTS ---
import '../../features/auth/presentation/screens/login_screen.dart';
import '../main_shell.dart'; // Shell untuk Mahasiswa
import '../../features/lecturer_dashboard/presentation/screens/lecturer_shell.dart'; // Shell untuk Dosen
import '../../features/onboarding/presentation/screens/complete_profile_screen.dart';
import '../../features/onboarding/presentation/screens/face_enroll_screen.dart';
import '../../features/onboarding/presentation/screens/waiting_rombel_screen.dart';

// Urutan tahap onboarding mahasiswa. device_registered sengaja TIDAK
// dijadikan gerbang navigasi -- sesuai Flow_Navigasi.md, itu proses
// otomatis di background, bukan layar manual.
const _onboardingPaths = [
  '/onboarding/profile',
  '/onboarding/face',
];

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token');
      final role = await storage.read(key: 'user_role');
      final currentPath = state.matchedLocation;
      final isGoingToLogin = currentPath == '/login';

      // Belum login -> paksa ke /login, kecuali memang sudah di situ.
      if (token == null) {
        return isGoingToLogin ? null : '/login';
      }

      // Dosen tidak punya gerbang onboarding (sesuai Flow_Navigasi.md 2.1).
      if (role == 'dosen') {
        return isGoingToLogin ? '/lecturer/home' : null;
      }

      // --- Mahasiswa: cek flag onboarding satu-satu, urut ---
      // Catatan: assigned_to_rombel SENGAJA tidak dijadikan gerbang blocking.
      // Kalau belum di-assign rombel, mahasiswa tetap masuk Home/Jadwal
      // seperti biasa -- akan terlihat empty state ("Belum ada jadwal,
      // hubungi admin rombel") yang memang sudah didesain untuk kondisi ini.
      // Begitu admin assign rombel, data muncul otomatis pas provider
      // fetch ulang -- tidak perlu mekanisme polling/refresh khusus.
      final profileCompleted = (await storage.read(key: 'profile_completed')) == 'true';
      final faceEnrolled = (await storage.read(key: 'face_enrolled')) == 'true';

      String target;
      if (!profileCompleted) {
        target = '/onboarding/profile';
      } else if (!faceEnrolled) {
        target = '/onboarding/face';
      } else {
        target = '/home';
      }

      if (isGoingToLogin) return target;

      // Sudah lengkap semua tapi masih nyangkut di layar onboarding -> lempar ke Home.
      if (target == '/home' && _onboardingPaths.contains(currentPath)) {
        return '/home';
      }

      // Belum lengkap tapi mencoba akses selain tahap yang seharusnya -> paksa balik.
      if (target != '/home' && currentPath != target) {
        return target;
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
        builder: (context, state) => const LecturerShell(),
      ),
      GoRoute(
        path: '/onboarding/profile',
        builder: (context, state) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: '/onboarding/face',
        builder: (context, state) => const FaceEnrollScreen(),
      ),
      GoRoute(
        path: '/onboarding/waiting-rombel',
        builder: (context, state) => const WaitingRombelScreen(),
      ),
    ],
  );
});