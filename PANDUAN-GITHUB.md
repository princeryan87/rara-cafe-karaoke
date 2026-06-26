# 📱 PANDUAN UPLOAD KE GITHUB & BUILD APK
### RaRa Cafe Karaoke — Android & Android TV

---

## APA YANG AKAN TERJADI?

```
Anda upload file ke GitHub (gratis, lewat browser)
           ↓
GitHub otomatis build APK (±10 menit, di cloud)
           ↓
File APK siap didownload dari GitHub
           ↓
Install di HP Android / Android TV
```

Tidak perlu install Flutter, Android Studio, atau apapun di PC Anda! ✅

---

## LANGKAH 1 — Buat Akun GitHub (jika belum punya)

1. Buka **https://github.com**
2. Klik **Sign up**
3. Daftar dengan email → verifikasi → selesai

---

## LANGKAH 2 — Buat Repository Baru

1. Login ke GitHub
2. Klik tombol **"+"** di pojok kanan atas → **New repository**
3. Isi:
   - **Repository name:** `rara-cafe-karaoke`
   - **Description:** `Aplikasi Karaoke RaRa Cafe`
   - Pilih: **Public** (gratis)
   - ✅ Centang: **Add a README file**
4. Klik **Create repository**

---

## LANGKAH 3 — Upload File ke GitHub

Di halaman repository yang baru dibuat:

### Upload folder satu per satu:

1. Klik **"uploading an existing file"** atau tombol **Add file → Upload files**

2. Upload file-file berikut dengan **struktur folder yang benar**:

```
rara-cafe-karaoke/
├── .github/
│   └── workflows/
│       └── build.yml
├── android/
│   ├── app/
│   │   ├── build.gradle
│   │   └── src/
│   │       └── main/
│   │           ├── AndroidManifest.xml
│   │           └── kotlin/
│   │               └── com/raracafe/karaoke/
│   │                   └── MainActivity.kt
│   ├── build.gradle
│   ├── gradle.properties
│   └── settings.gradle
├── assets/
│   └── logo.png          ← PENTING! Copy dari logo Windows
├── lib/
│   ├── main.dart
│   └── screens/
│       ├── home_screen.dart
│       └── karaoke_screen.dart
├── pubspec.yaml
└── .gitignore
```

> 💡 **Tips upload:** GitHub bisa upload folder sekaligus.
> Drag & drop seluruh folder `rara-cafe-karaoke` ke halaman upload.

3. Setelah semua file terupload, scroll ke bawah
4. Klik **Commit changes** → **Commit directly to main**

---

## LANGKAH 4 — Lihat Proses Build

Setelah commit, GitHub Actions otomatis mulai build!

1. Klik tab **"Actions"** di repository Anda
2. Akan ada proses berjalan bernama **"Build RaRa Cafe Karaoke APK"**
3. Klik untuk melihat progress
4. Tunggu ±10 menit sampai ada tanda ✅ hijau

---

## LANGKAH 5 — Download APK

Setelah build selesai (tanda ✅):

1. Klik workflow yang sudah selesai
2. Scroll ke bawah ke bagian **"Artifacts"**
3. Klik **"RaRa-Cafe-Karaoke-APK"** → Download ZIP
4. Ekstrak ZIP → ambil file `app-release.apk`

---

## LANGKAH 6 — Install di HP Android

1. **Pindahkan APK** ke HP via kabel / WhatsApp / Google Drive
2. Di HP, buka **Pengaturan → Keamanan**
3. Aktifkan **"Instal aplikasi dari sumber tidak dikenal"**
   *(atau "Unknown sources")*
4. Buka file APK → **Install**
5. Selesai! Buka app **RaRa Cafe Karaoke** ✅

---

## LANGKAH 7 — Install di Android TV

### Cara A: Via USB
1. Colok flashdisk berisi APK ke Android TV
2. Buka **File Manager** di TV
3. Temukan file APK → klik → Install

### Cara B: Via Aplikasi (lebih mudah)
1. Install **"Downloader"** dari Google Play di Android TV
2. Buka Downloader → masukkan link download APK dari GitHub
3. Install

### Cara C: Via ADB (untuk yang lebih teknis)
```
adb connect [IP-TV]
adb install app-release.apk
```

---

## JIKA BUILD GAGAL ❌

1. Klik workflow yang gagal di tab Actions
2. Klik bagian yang merah untuk lihat error
3. Error paling umum dan solusinya:

| Error | Solusi |
|-------|--------|
| `assets/logo.png not found` | Pastikan file logo.png ada di folder `assets/` |
| `SDK version` error | Sudah dikonfigurasi, coba push ulang |
| `pubspec.yaml` error | Periksa format file, tidak boleh ada tab |

---

## UPDATE APLIKASI

Jika ingin update tampilan/fitur:

1. Edit file langsung di GitHub (klik file → ikon pensil)
2. Klik **Commit changes**
3. GitHub Actions otomatis build ulang
4. Download APK baru → install ulang di HP/TV ✅

---

## FILE PENTING

| File | Fungsi |
|------|--------|
| `lib/main.dart` | Entry point app |
| `lib/screens/home_screen.dart` | Halaman utama (logo, search, tombol) |
| `lib/screens/karaoke_screen.dart` | Halaman WebView YouTube |
| `pubspec.yaml` | Konfigurasi & dependencies |
| `android/app/src/main/AndroidManifest.xml` | Izin & konfigurasi Android |
| `.github/workflows/build.yml` | Script build otomatis |
| `assets/logo.png` | Logo RaRa Cafe |

---

*RaRa Cafe Karaoke © 2025 — Flutter + GitHub Actions*
