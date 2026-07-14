import 'package:logger/logger.dart';

/// Logger global yang bisa dipakai di seluruh aplikasi.
/// Cara pakai: import file ini, lalu panggil `appLogger.d("pesan")`, dst.
final Logger appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0, // gak usah nampilin banyak baris "jejak" pemanggilan
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
  ),
);