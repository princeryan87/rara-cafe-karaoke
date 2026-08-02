"""
tool/generate_icon_source.py
-----------------------------------------------------------
Dijalankan otomatis oleh GitHub Actions sebelum build APK.
Membaca logo.png di root repo, lalu menghasilkan 2 versi
gambar persegi (dibutuhkan flutter_launcher_icons):

  1. build_assets/icon_legacy.png     - untuk icon biasa (Android < 8)
  2. build_assets/icon_adaptive_fg.png - untuk adaptive icon foreground
     (dikasih padding ekstra, karena Android adaptive icon suka
     "memotong" bagian tepi icon dengan bentuk bulat/persegi
     rounded -- padding ini mencegah logo kepotong)

logo.png TIDAK harus persegi -- proporsi asli dijaga (tidak gepeng),
sisanya diisi transparan.

icon.ico di root TIDAK dipakai untuk generate launcher icon Android
(format .ico tidak didesain untuk ini). logo.png adalah satu-satunya
sumber, supaya launcher icon Android tetap konsisten visual dengan
icon.ico di aplikasi Windows (yang juga di-generate dari logo.png
yang sama persis).
-----------------------------------------------------------
"""

import os
import sys

try:
    from PIL import Image
except ImportError:
    print("❌ Modul Pillow belum terinstall. Jalankan: pip install pillow")
    sys.exit(1)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_LOGO = os.path.join(ROOT, "logo.png")
OUT_DIR = os.path.join(ROOT, "build_assets")
CANVAS_SIZE = 1024


def pad_to_square(src_path, out_path, canvas_size, content_ratio=1.0):
    img = Image.open(src_path).convert("RGBA")

    target_content = int(canvas_size * content_ratio)
    scale = min(target_content / img.width, target_content / img.height)
    new_w = max(1, int(img.width * scale))
    new_h = max(1, int(img.height * scale))
    resized = img.resize((new_w, new_h), Image.LANCZOS)

    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    x = (canvas_size - new_w) // 2
    y = (canvas_size - new_h) // 2
    canvas.paste(resized, (x, y), resized)
    canvas.save(out_path)


def main():
    if not os.path.exists(SRC_LOGO):
        print(f"❌ logo.png tidak ditemukan di root repo: {SRC_LOGO}")
        sys.exit(1)

    os.makedirs(OUT_DIR, exist_ok=True)

    legacy_path = os.path.join(OUT_DIR, "icon_legacy.png")
    adaptive_fg_path = os.path.join(OUT_DIR, "icon_adaptive_fg.png")

    print(f"🎨 Generate launcher icon dari logo.png ...")
    pad_to_square(SRC_LOGO, legacy_path, CANVAS_SIZE, content_ratio=1.0)
    # content_ratio 0.66 = safe zone standar Android adaptive icon,
    # supaya logo tidak kepotong saat di-mask jadi bentuk bulat/rounded
    pad_to_square(SRC_LOGO, adaptive_fg_path, CANVAS_SIZE, content_ratio=0.66)

    print(f"✅ {legacy_path}")
    print(f"✅ {adaptive_fg_path}")


if __name__ == "__main__":
    main()
