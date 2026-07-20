import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Interceptor ini "menyamar" jadi backend asli untuk 6 endpoint onboarding.
/// Selain 6 endpoint ini, semua request tetap diteruskan ke Postman Mock
/// seperti biasa (lihat handler.next(options) di paling bawah).
class FakeBackendInterceptor extends Interceptor {
  Box get _box => Hive.box('mock_db_box');

  // Data default kalau belum pernah register sama sekali —
  // supaya kamu tetap bisa login tanpa harus register dulu tiap testing.
  Map<String, dynamic> _defaultUser() => {
    'email': 'mahasiswa1@smartlock.test',
    'password': 'Password123!',
    'role': 'mahasiswa',
    'nama_lengkap': 'Mahasiswa Uji Coba',
    'nim': '-',
    'program_studi': '-',
    'angkatan': null,
    'profile_completed': false,
    'face_enrolled': false,
    'device_registered': false,
    'assigned_to_rombel': false,
    'can_attend': false,
    'must_change_password': false,
  };

  Map<String, dynamic> _readUser() {
    final saved = _box.get('user_data');
    if (saved == null) return _defaultUser();
    return Map<String, dynamic>.from(saved);
  }

  void _saveUser(Map<String, dynamic> data) {
    _box.put('user_data', data);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.path;
    final method = options.method.toUpperCase();

    // 1. REGISTER MAHASISWA
    if (path.contains('/auth/register/mahasiswa') && method == 'POST') {
      final body = options.data as Map<String, dynamic>? ?? {};
      final userData = _defaultUser();
      userData['email'] = body['email'] ?? userData['email'];
      userData['password'] = body['password'] ?? userData['password'];
      _saveUser(userData);

      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 201,
        data: {'message': 'Registrasi berhasil'},
      ));
    }

    // 2. LOGIN
    // Bentuk respons ini WAJIB sama persis dengan yang dibaca
    // AuthResponse.fromJson di auth_model.dart — flag onboarding
    // ada di LEVEL ATAS json, bukan di dalam "user".
    if (path.contains('/auth/login') && method == 'POST') {
      final userData = _readUser();

      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'access_token': 'fake_token_${DateTime.now().millisecondsSinceEpoch}',
          'user': {
            'id': 1,
            'email': userData['email'],
            'role': userData['role'],
            'nama_lengkap': userData['nama_lengkap'],
          },
          'must_change_password': userData['must_change_password'],
          'profile_completed': userData['profile_completed'],
          'face_enrolled': userData['face_enrolled'],
          'device_registered': userData['device_registered'],
          'assigned_to_rombel': userData['assigned_to_rombel'],
          'can_attend': userData['can_attend'],
        },
      ));
    }

    // 3. GET USER (dipakai profile_provider.dart)
    // Bentuk ini WAJIB sama dengan UserProfile.fromJson di profile_model.dart.
    if (path == '/user' && method == 'GET') {
      final userData = _readUser();

      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'nama_lengkap': userData['nama_lengkap'],
          'nim': userData['nim'],
          'email': userData['email'],
          'program_studi': userData['program_studi'],
          'role': userData['role'],
          'angkatan': userData['angkatan'],
          // Flag onboarding ikut disertakan juga, buat dipakai router guard nanti.
          'profile_completed': userData['profile_completed'],
          'face_enrolled': userData['face_enrolled'],
          'device_registered': userData['device_registered'],
          'assigned_to_rombel': userData['assigned_to_rombel'],
          'can_attend': userData['can_attend'],
        },
      ));
    }

    // 4. LENGKAPI PROFIL
    if (path.contains('/mobile/mahasiswa/profile') && method == 'PATCH') {
      final body = options.data as Map<String, dynamic>? ?? {};
      final userData = _readUser();

      userData['nim'] = body['nim'] ?? userData['nim'];
      userData['nama_lengkap'] = body['nama_lengkap'] ?? userData['nama_lengkap'];
      userData['program_studi'] = body['program_studi'] ?? userData['program_studi'];
      userData['angkatan'] = body['angkatan'] ?? userData['angkatan'];
      userData['profile_completed'] = true;

      _saveUser(userData);

      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {'message': 'Profil berhasil diupdate'},
      ));
    }

    // 5. DAFTARKAN WAJAH
    if (path.contains('/mobile/mahasiswa/face/enroll') && method == 'POST') {
      final userData = _readUser();
      userData['face_enrolled'] = true;
      _saveUser(userData);

      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {'message': 'Wajah berhasil didaftarkan', 'template_version': 2},
      ));
    }

    // 6. REGISTER DEVICE (HP)
    if (path.contains('/mobile/devices') && method == 'POST') {
      final userData = _readUser();
      userData['device_registered'] = true;
      _saveUser(userData);

      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 201,
        data: {
          'id': 'mock-device-${DateTime.now().millisecondsSinceEpoch}',
          'message': 'Device berhasil didaftarkan',
        },
      ));
    }

    // Bukan salah satu dari 6 endpoint di atas -> teruskan ke Postman seperti biasa.
    handler.next(options);
  }
}