// ============================================================
//  KIOSK SERVICE — Screen Pinning (kunci layar ke app ini saja)
// ============================================================
//  Jembatan ke kode native Android (MainActivity.kt) yang
//  memanggil startLockTask()/stopLockTask(). Lihat catatan
//  batasan di MainActivity.kt.
// ============================================================

import 'package:flutter/services.dart';

class KioskService {
  static const MethodChannel _channel = MethodChannel('com.raracafe.karaoke/kiosk');

  static Future<bool> startKiosk() async {
    try {
      final result = await _channel.invokeMethod<bool>('startKiosk');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> stopKiosk() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopKiosk');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
