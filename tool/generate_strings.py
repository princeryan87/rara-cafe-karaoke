"""
tool/generate_strings.py
-----------------------------------------------------------
Dijalankan otomatis oleh GitHub Actions sebelum build APK.
Membaca brandName & subBrand dari lib/config.dart, lalu
menuliskannya ke android/app/src/main/res/values/strings.xml
sebagai app_name -- ini yang menentukan nama aplikasi yang
tampil di launcher (home screen) HP/Android TV.

Sebelumnya nilai ini harus diedit manual & terpisah dari
config.dart. Sekarang keduanya otomatis sinkron: cukup ubah
brandName/subBrand di config.dart, lalu build ulang.
-----------------------------------------------------------
"""

import os
import re
import sys
import html

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONFIG_PATH = os.path.join(ROOT, "lib", "config.dart")
STRINGS_PATH = os.path.join(
    ROOT, "android", "app", "src", "main", "res", "values", "strings.xml"
)


def extract_value(field_name, content):
    # Cocokkan: static const String fieldName = 'isi';  (kutip ' atau ")
    pattern = rf"""static\s+const\s+String\s+{field_name}\s*=\s*['"](.*?)['"]"""
    match = re.search(pattern, content)
    if not match:
        print(f"ERROR: tidak menemukan '{field_name}' di config.dart")
        sys.exit(1)
    return match.group(1)


def main():
    if not os.path.exists(CONFIG_PATH):
        print(f"ERROR: config.dart tidak ditemukan di: {CONFIG_PATH}")
        sys.exit(1)

    with open(CONFIG_PATH, "r", encoding="utf-8") as f:
        config_content = f.read()

    brand_name = extract_value("brandName", config_content)
    sub_brand = extract_value("subBrand", config_content)
    app_name = f"{brand_name} {sub_brand}".strip()
    app_name_escaped = html.escape(app_name, quote=False)

    xml_content = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<resources>\n"
        "    <!-- File ini digenerate otomatis oleh tool/generate_strings.py -->\n"
        "    <!-- Sumber nilai: lib/config.dart (brandName + subBrand) -->\n"
        f'    <string name="app_name">{app_name_escaped}</string>\n'
        "</resources>\n"
    )

    os.makedirs(os.path.dirname(STRINGS_PATH), exist_ok=True)
    with open(STRINGS_PATH, "w", encoding="utf-8") as f:
        f.write(xml_content)

    print(f"Nama launcher diset ke: \"{app_name}\"")
    print(f"  Ditulis ke: {STRINGS_PATH}")


if __name__ == "__main__":
    main()
