package com.raracafe.karaoke

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity
 * -----------------------------------------------------------
 * Jembatan (MethodChannel) ke fitur native Android "Screen
 * Pinning" (startLockTask/stopLockTask) -- mengunci layar ke
 * app ini saja (tombol Home/Recents diblokir), TANPA perlu app
 * jadi "Device Owner". Ini fitur bawaan Android biasa (API 21+),
 * bisa dipanggil app manapun.
 *
 * Batasan yang perlu diketahui: karena bukan Device Owner, staf
 * TETAP BISA keluar dari pin dengan cara resmi Android (tahan
 * tombol Back + Recents beberapa detik). Ini sengaja dibiarkan
 * oleh Android sebagai jalan keluar darurat -- dan sebenarnya
 * cocok untuk kebutuhan kita (staf tetap bisa keluar untuk
 * maintenance kalau perlu), meski bukan kunci yang 100% tidak
 * bisa ditembus pelanggan yang tahu caranya.
 * -----------------------------------------------------------
 */
class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.raracafe.karaoke/kiosk"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startKiosk" -> {
                        try {
                            startLockTask()
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "stopKiosk" -> {
                        try {
                            stopLockTask()
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
