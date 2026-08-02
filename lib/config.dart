// ============================================================
//  KONFIGURASI APLIKASI — EDIT FILE INI UNTUK GANTI BRANDING
// ============================================================
//  Cukup ubah nilai-nilai di bawah ini, commit & push ke GitHub.
//  GitHub Actions akan otomatis build ulang APK dengan branding
//  baru (termasuk launcher icon, kalau logo.png juga diganti).
// ============================================================

import 'package:flutter/material.dart';

class AppConfig {
  // Nama usaha / brand. Contoh: "RaRa Cafe", "Prince Entertainment"
  static const String brandName = 'RaRa Cafe';

  // Sub-judul di bawah nama brand
  static const String subBrand = 'Karaoke';

  // Tagline kecil di layar utama
  static const String tagline = '✦ Nyanyikan Hati Anda ✦';

  // Path logo -- HARUS sama dengan nama file di root repo (logo.png)
  static const String logoAssetPath = 'logo.png';

  // ── Warna tema ──
  static const Color orange = Color(0xFFE85D00);
  static const Color orangeLight = Color(0xFFFF8C00);
  static const Color gold = Color(0xFFC2A06A);
  static const Color dark = Color(0xFF111111);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkOrange = Color(0xFF1C0800);

  // Judul lengkap (dipakai untuk MaterialApp title & topbar)
  static String get fullTitle => '$brandName $subBrand';
}
