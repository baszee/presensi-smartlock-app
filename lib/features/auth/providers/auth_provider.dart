import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';

// 1. Definisikan State (Kondisi)
enum AuthStatus { initial, loading, success, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;

  AuthState({required this.status, this.errorMessage});

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => AuthState(status: AuthStatus.loading);
  factory AuthState.success() => AuthState(status: AuthStatus.success);
  factory AuthState.error(String message) => AuthState(status: AuthStatus.error, errorMessage: message);
}

// 2. Buat Notifier pengontrol state
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState.initial());

  Future<void> login(String email, String password) async {
    state = AuthState.loading(); // UI berubah jadi muter-muter (loading)
    try {
      await _repository.login(email, password);
      state = AuthState.success(); // UI otomatis pindah halaman
    } catch (e) {
      state = AuthState.error(e.toString()); // UI nampilin snackbar error
    }
  }

  Future<void> loginWithGoogle() async {
    state = AuthState.loading();
    try {
      await _repository.loginWithGoogle();
      state = AuthState.success();
    } catch (e) {
      // Kalau user cancel dialog Google, balikin ke initial (bukan error)
      // biar nggak muncul snackbar merah nakut-nakutin buat aksi yang
      // sebenarnya normal (user emang sengaja batal pilih akun).
      if (e.toString().contains('dibatalkan')) {
        state = AuthState.initial();
      } else {
        state = AuthState.error(e.toString());
      }
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = AuthState.initial();
  }
}

// 3. Daftarkan ke Riverpod
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});