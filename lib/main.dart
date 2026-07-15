import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import file router yang sudah kita buat sebelumnya
import 'app/router/app_router.dart';

void main() {
  runApp(
    // ProviderScope wajib ada di paling luar agar Riverpod bisa berjalan
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// 1. Ubah StatelessWidget menjadi ConsumerWidget
// agar kita bisa membaca (read/watch) Provider dari Riverpod
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 2. Ambil konfigurasi GoRouter yang sudah dibuat di app_router.dart
    final router = ref.watch(goRouterProvider);

    // 3. Gunakan MaterialApp.router (bukan MaterialApp biasa)
    return MaterialApp.router(
      title: 'Dsolve Smart Lock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // 4. Masukkan variabel router ke dalam routerConfig
      routerConfig: router,
    );
  }
}