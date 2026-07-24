import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Interceptor ini "menyamar" jadi backend asli, TAPI KHUSUS UNTUK MAHASISWA,
/// dan CUMA untuk endpoint yang butuh state (login/profil/device/wajah).
///
/// PRINSIP UTAMA (biar tinggal saklar AppConfig.useMockBackend, JSON SAMA):
/// Setiap response yang di-resolve di sini WAJIB persis sama bentuknya
/// dengan response asli Laravel -- envelope {"status","data"}, relasi
/// "profil_mahasiswa" nested di dalam "user", flag onboarding dibungkus
/// di object "onboarding", dst. Acuan pasti: postman_examples_sesuai_backend.md
/// (ditarik langsung dari source code controller Laravel, bukan tebakan).
///
/// Endpoint yang TIDAK butuh state tersimpan (jadwal, sesi, riwayat,
/// face/verify, ble challenge, presensi) TIDAK dicegat di sini -- mereka
/// diteruskan ke Postman Mock (handler.next), yang Example-nya juga sudah
/// disamakan ke bentuk backend asli di MD yang sama.
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
  // Field-field ini adalah "state internal" mock, BUKAN bentuk JSON API --
  // bentuk JSON API-nya baru dirakit di _userJson()/_onboardingJson().
  Map<String, dynamic> _defaultUser() => {
    'id': '10000000-0000-4000-8000-000000000099',
    'email': 'mahasiswa1@smartlock.test',
    'password': 'Password123!',
    'role': 'mahasiswa',
    'nama_lengkap': 'Mahasiswa Uji Coba',
    'nim': '-',
    'program_studi': '-',
    'angkatan': null,
    'profile_id': '20000000-0000-4000-8000-000000000099',
    'face_enrolled': false,
    'device_registered': false,
    'assigned_to_rombel': false,
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

  // profile_completed itu DIHITUNG backend (StudentOnboardingService), bukan
  // kolom tersimpan -- jadi di sini juga dihitung dari data yang ada,
  // supaya tidak ada kemungkinan "lupa update flag" kayak sebelumnya.
  bool _profileCompleted(Map<String, dynamic> u) =>
      (u['nim'] ?? '-') != '-' &&
          (u['nama_lengkap'] ?? '').toString().isNotEmpty &&
          (u['program_studi'] ?? '-') != '-' &&
          u['angkatan'] != null;

  Map<String, dynamic> _onboardingJson(Map<String, dynamic> u) {
    final profileCompleted = _profileCompleted(u);
    final faceEnrolled = u['face_enrolled'] ?? false;
    final deviceRegistered = u['device_registered'] ?? false;
    final assignedToRombel = u['assigned_to_rombel'] ?? false;
    return {
      'profile_completed': profileCompleted,
      'face_enrolled': faceEnrolled,
      'device_registered': deviceRegistered,
      'assigned_to_rombel': assignedToRombel,
      'must_change_password': u['must_change_password'] ?? false,
      'can_attend': profileCompleted && faceEnrolled && deviceRegistered && assignedToRombel,
    };
  }

  // Bentuk object "user" PERSIS seperti User::toArray() + relasi
  // profilMahasiswa yang di-load backend asli (lihat AuthController::login,
  // ProfileController::show).
  Map<String, dynamic> _userJson(Map<String, dynamic> u) => {
    'id': u['id'],
    'email': u['email'],
    'role': 'mahasiswa',
    'google_id': null,
    'avatar_url': null,
    'face_consent': u['face_enrolled'] ?? false,
    'status_akses': 'aktif',
    'must_change_password': u['must_change_password'] ?? false,
    'profil_mahasiswa': {
      'id': u['profile_id'],
      'user_id': u['id'],
      'nim': u['nim'],
      'nama_lengkap': u['nama_lengkap'],
      'program_studi': u['program_studi'],
      'angkatan': u['angkatan'],
    },
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final path = options.path;
    final method = options.method.toUpperCase();

    // 0. LOGIN GOOGLE -- popup pilih akun Google di Flutter SELALU beneran
    // (nggak bisa di-mock, itu punya Google). Yang dicegat di sini cuma
    // langkah VERIFIKASI idToken ke backend -- supaya kamu nggak perlu
    // nunggu Client ID Web + backend asli hidup buat nge-tes alur UI-nya.
    // Bentuk response WAJIB sama dengan AuthController::google (status
    // 200, {status,data:{access_token,user,onboarding}}), user selalu
    // dianggap mahasiswa baru (profil masih kosong, biar keliatan realistis
    // sama seperti akun Google yang baru pertama kali daftar).
    if (path.contains('/auth/google') && method == 'POST') {
      final body = options.data as Map<String, dynamic>? ?? {};
      final googleEmail = body['google_email'] ?? 'akun.google@gmail.com';
      final googleName = body['google_name'] ?? 'Pengguna Google';

      final userData = _defaultUser();
      userData['id'] = 'mock-google-${DateTime.now().millisecondsSinceEpoch}';
      userData['profile_id'] = 'mock-profile-google-${DateTime.now().millisecondsSinceEpoch}';
      userData['email'] = googleEmail;
      // Nama dari Google dipakai duluan (biar kerasa "beneran" akunnya),
      // tapi field akademik (nim, program_studi, dst) tetap kosong --
      // sama seperti user baru asli via Google di backend (lihat
      // AuthController::google: ProfilMahasiswa::create kosong tanpa nim).
      userData['nama_lengkap'] = googleName;
      _saveUser(userData);
      await _secureStorage.write(key: 'user_role', value: 'mahasiswa');

      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'status': 'success',
          'data': {
            'access_token': 'fake_token_google_${DateTime.now().millisecondsSinceEpoch}',
            'user': _userJson(userData),
            'onboarding': _onboardingJson(userData),
          },
        },
      ));
    }

    // 1. REGISTER MAHASISWA -- path eksplisit /mahasiswa/, aman untuk dosen.
    // Bentuk PERSIS AuthController::registerMahasiswa (status 201, envelope
    // {status,message,data:{access_token,user,onboarding}}).
    if (path.contains('/auth/register/mahasiswa') && method == 'POST') {
      final body = options.data as Map<String, dynamic>? ?? {};
      final userData = _defaultUser();
      userData['id'] = 'mock-user-${DateTime.now().millisecondsSinceEpoch}';
      userData['profile_id'] = 'mock-profile-${DateTime.now().millisecondsSinceEpoch}';
      userData['email'] = body['email'] ?? userData['email'];
      userData['password'] = body['password'] ?? userData['password'];
      _saveUser(userData);
      await _secureStorage.write(key: 'user_role', value: 'mahasiswa');

      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 201,
        data: {
          'status': 'success',
          'message': 'Registrasi mahasiswa berhasil.',
          'data': {
            'access_token': 'fake_token_${DateTime.now().millisecondsSinceEpoch}',
            'user': _userJson(userData),
            'onboarding': _onboardingJson(userData),
          },
        },
      ));
    }

    // 2. LOGIN -- GATE PENTING: kalau emailnya dosen, JANGAN dicegat,
    // teruskan ke Postman supaya Example "Login Dosen" yang dipakai.
    // Bentuk PERSIS AuthController::login: {status,data:{access_token,user,onboarding}}.
    if (path.contains('/auth/login') && method == 'POST') {
      final body = options.data as Map<String, dynamic>? ?? {};
      final email = (body['email'] ?? '').toString();

      if (email.contains('dosen')) {
        return handler.next(options);
      }

      final userData = _readUser();
      await _secureStorage.write(key: 'user_role', value: 'mahasiswa');

      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'status': 'success',
          'data': {
            'access_token': 'fake_token_${DateTime.now().millisecondsSinceEpoch}',
            'user': _userJson(userData),
            'onboarding': _onboardingJson(userData),
          },
        },
      ));
    }

    // 3. GET USER (dipakai profile_provider.dart) -- GATE PENTING JUGA:
    // GET tidak punya body untuk dicek emailnya, jadi kita baca role
    // yang disimpan saat login berhasil. Kalau dosen, teruskan ke Postman
    // supaya Example "Profile Aktif Dosen" yang dipakai.
    // Bentuk PERSIS ProfileController::show: {status,data:{...user,onboarding}}
    // (onboarding di sini rata di dalam "data", BUKAN di dalam "user" --
    // beda dengan endpoint login/register, karena controllernya array_merge
    // ke $user->toArray() langsung).
    if (path == '/user' && method == 'GET') {
      final storedRole = await _secureStorage.read(key: 'user_role');
      if (storedRole == 'dosen') {
        return handler.next(options);
      }

      final userData = _readUser();
      final userJson = _userJson(userData);

      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'status': 'success',
          'data': {
            ...userJson,
            'onboarding': _onboardingJson(userData),
          },
        },
      ));
    }

    // 4. LENGKAPI PROFIL -- bentuk PERSIS StudentProfileController::update:
    // {status,message,data:{profile,onboarding}}.
    if (path.contains('/mobile/mahasiswa/profile') && method == 'PATCH') {
      final body = options.data as Map<String, dynamic>? ?? {};
      final userData = _readUser();

      userData['nim'] = body['nim'] ?? userData['nim'];
      userData['nama_lengkap'] = body['nama_lengkap'] ?? userData['nama_lengkap'];
      userData['program_studi'] = body['program_studi'] ?? userData['program_studi'];
      userData['angkatan'] = body['angkatan'] ?? userData['angkatan'];

      _saveUser(userData);

      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'status': 'success',
          'message': 'Profil mahasiswa berhasil dilengkapi.',
          'data': {
            'profile': {
              'id': userData['profile_id'],
              'user_id': userData['id'],
              'nim': userData['nim'],
              'nama_lengkap': userData['nama_lengkap'],
              'program_studi': userData['program_studi'],
              'angkatan': userData['angkatan'],
            },
            'onboarding': _onboardingJson(userData),
          },
        },
      ));
    }

    // 5. DAFTARKAN WAJAH -- bentuk PERSIS FaceRecognitionController::enroll
    // (status 201, {status,message,data:{id,quality_score,consent_version,
    // consented_at,template_version,model,liveness_mode}}).
    if (path.contains('/mobile/mahasiswa/face/enroll') && method == 'POST') {
      final userData = _readUser();
      userData['face_enrolled'] = true;
      _saveUser(userData);

      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 201,
        data: {
          'status': 'success',
          'message': 'Wajah berhasil didaftarkan.',
          'data': {
            'id': 'mock-faceprofile-${DateTime.now().millisecondsSinceEpoch}',
            'quality_score': 0.92,
            'consent_version': 'v1',
            'consented_at': DateTime.now().toIso8601String(),
            'template_version': 2,
            'model': 'mock-model',
            'liveness_mode': 'mock',
          },
        },
      ));
    }

    // 6. REGISTER DEVICE (HP) -- GATE PENTING JUGA: endpoint ini dipakai
    // dosen (saat daftar HP ber-NFC) dan mahasiswa. Kalau dosen, teruskan
    // ke Postman -- jangan tulis ke data mahasiswa di Hive.
    // Bentuk PERSIS MobileDeviceController::store.
    if (path.contains('/mobile/devices') && method == 'POST') {
      final storedRole = await _secureStorage.read(key: 'user_role');
      if (storedRole == 'dosen') {
        return handler.next(options);
      }

      final body = options.data as Map<String, dynamic>? ?? {};
      final userData = _readUser();
      userData['device_registered'] = true;
      _saveUser(userData);

      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 201,
        data: {
          'status': 'success',
          'message': 'Perangkat mobile berhasil didaftarkan.',
          'data': {
            'id': 'mock-device-${DateTime.now().millisecondsSinceEpoch}',
            'user_id': userData['id'],
            'device_public_id': body['device_public_id'],
            'device_name': body['device_name'],
            'platform': body['platform'] ?? 'android',
            'nfc_supported': body['nfc_supported'] ?? false,
            'nfc_verified_at': (body['nfc_supported'] ?? false) ? DateTime.now().toIso8601String() : null,
            'status': 'active',
            'revoked_at': null,
          },
        },
      ));
    }

    // Bukan salah satu dari 6 endpoint stateful di atas -> teruskan ke
    // Postman Mock seperti biasa (jadwal, sesi, riwayat, face/verify, ble,
    // presensi -- semua Example-nya sudah disamakan ke bentuk backend asli).
    handler.next(options);
  }
}