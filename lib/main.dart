import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
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

  runApp(const RaraCafeKaraokeApp());
}

class RaraCafeKaraokeApp extends StatelessWidget {
  const RaraCafeKaraokeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RaRa Cafe Karaoke',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE85D00),
          secondary: Color(0xFFC2A06A),
          surface: Color(0xFF111111),
        ),
        scaffoldBackgroundColor: const Color(0xFF111111),
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}
