/// Saklar global mock vs backend asli.
///
/// - true  = pakai Postman Mock (FakeBackendInterceptor aktif, header
///           x-mock-response-name ikut dikirim di tiap provider).
/// - false = pakai backend asli punya temenmu (ngrok/lokal). Mock TIDAK
///           dihapus, cuma dimatikan -- tinggal balikin ke true lagi
///           kalau backend lagi down dan kamu mau demo pakai mock.
class AppConfig {
  static const bool useMockBackend = true;
}