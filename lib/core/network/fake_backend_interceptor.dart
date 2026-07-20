import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Interceptor ini "menyamar" jadi backend asli, TAPI KHUSUS UNTUK MAHASISWA.
///
/// PENTING -- role gate:
/// Dosen SELALU diteruskan ke Postman Mock (handler.next), karena backend
/// palsu ini cuma "kenal" data mahasiswa yang disimpan di Hive. Tanpa gate
/// ini, tombol "Login Dummy (Dosen)" dan GET /user milik dosen akan
/// dibajak dan diam-diam dikembalikan data mahasiswa.
class FakeBackendInterceptor extends Interceptor {
  Box get _box => Hive.box('mock_db_box');
  static const _secureStorage = FlutterSecureStorage();

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
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final path = options.path;
    final method = options.method.toUpperCase();

    // 1. REGISTER MAHASISWA -- path eksplisit /mahasiswa/, aman untuk dosen.
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

    // 2. LOGIN -- GATE PENTING: kalau emailnya dosen, JANGAN dicegat,
    // teruskan ke Postman supaya Example "Login Dosen" yang dipakai.
    if (path.contains('/auth/login') && method == 'POST') {
      final body = options.data as Map<String, dynamic>? ?? {};
      final email = (body['email'] ?? '').toString();

      if (email.contains('dosen')) {
        return handler.next(options);
      }

      // Bentuk respons ini WAJIB sama persis dengan yang dibaca
      // AuthResponse.fromJson di auth_model.dart — flag onboarding
      // ada di LEVEL ATAS json, bukan di dalam "user".
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

    // 3. GET USER (dipakai profile_provider.dart) -- GATE PENTING JUGA:
    // GET tidak punya body untuk dicek emailnya, jadi kita baca role
    // yang disimpan auth_repository.dart saat login berhasil. Kalau
    // dosen, teruskan ke Postman supaya Example "Profile Aktif Dosen"
    // (perlu kamu buat manual di Postman) yang dipakai.
    if (path == '/user' && method == 'GET') {
      final storedRole = await _secureStorage.read(key: 'user_role');
      if (storedRole == 'dosen') {
        return handler.next(options);
      }

      // Bentuk ini WAJIB sama dengan UserProfile.fromJson di profile_model.dart.
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

    // 6. REGISTER DEVICE (HP) -- GATE PENTING JUGA: endpoint ini dipakai
    // dosen (saat daftar HP ber-NFC) dan mahasiswa. Kalau dosen, teruskan
    // ke Postman -- jangan tulis ke data mahasiswa di Hive.
    if (path.contains('/mobile/devices') && method == 'POST') {
      final storedRole = await _secureStorage.read(key: 'user_role');
      if (storedRole == 'dosen') {
        return handler.next(options);
      }

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