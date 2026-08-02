import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'config.dart';
import 'services/kiosk_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Paksa landscape fullscreen (cocok untuk TV & karaoke)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Sembunyikan status bar & navigation bar (kiosk mode)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Layar tidak mati saat karaoke
  await WakelockPlus.enable();

  // Kunci layar ke app ini saja (Screen Pinning) -- lihat catatan
  // batasan di kiosk_service.dart / MainActivity.kt
  await KioskService.startKiosk();

  runApp(const RaraCafeKaraokeApp());
}

class RaraCafeKaraokeApp extends StatelessWidget {
  const RaraCafeKaraokeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.fullTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: AppConfig.orange,
          secondary: AppConfig.gold,
          surface: AppConfig.dark,
        ),
        scaffoldBackgroundColor: AppConfig.dark,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}
