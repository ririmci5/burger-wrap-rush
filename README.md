# Burger Wrap Rush (Godot 4.3+)

Game clicker portrait: tap untuk membungkus burger, 20 detik per ronde.

## Struktur
```
burger_wrap_rush/
├── project.godot          <- file yang dibuka di Godot
├── icon.svg
├── scenes/main.tscn       <- satu-satunya scene (UI dibangun lewat kode)
└── scripts/
    ├── save_system.gd     (autoload) simpan/muat JSON lokal
    ├── game_manager.gd    (autoload) koin, XP, level, gem, upgrade, skin
    ├── timer_system.gd    hitung mundur ronde
    ├── click_counter.gd   total tap + Clicks/s
    ├── upgrade_shop.gd    layar toko
    ├── main.gd            UI + alur permainan
    ├── burger_view.gd     gambar burger, animasi bungkus, partikel, teks melayang
    ├── table_view.gd      meja kayu + piring
    ├── sfx.gd             suara hasil sintesis kode
    └── ui_kit.gd          helper style/label/tombol
```

## Coba di komputer
1. Pasang Godot 4.3 atau lebih baru (versi Standard, bukan .NET): https://godotengine.org/download
2. Buka Godot -> **Import** -> pilih `project.godot` di folder ini -> **Import & Edit**.
3. Tekan **F5** (tombol Play di kanan atas). Klik mouse = tap.
4. Data tersimpan di folder `user://` Godot. Untuk reset: hapus `burger_wrap_save.json`
   (Project -> Open User Data Folder).

## Jadi APK
1. Godot: **Editor -> Manage Export Templates -> Download and Install**.
2. Pasang JDK 17 dan Android SDK (cara paling mudah: Android Studio, lalu SDK Manager:
   Android SDK Platform 34, Build-Tools 34.0.0, Command-line Tools, Platform-Tools).
   Angka versi persisnya: lihat dokumen "Exporting for Android" untuk versi Godot kamu.
3. **Editor -> Editor Settings -> Export -> Android**: isi *Java SDK Path* dan *Android SDK Path*.
4. Buat debug keystore (sekali saja), lalu isi path-nya di Editor Settings yang sama:
   ```
   keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore debug.keystore -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999 -deststoretype pkcs12
   ```
5. **Project -> Export -> Add... -> Android**:
   - Package -> Unique Name: `com.namakamu.burgerwraprush`
   - Architectures: arm64-v8a **dan** armeabi-v7a (HP Android 8 spek rendah banyak yang 32-bit)
   - Permissions: centang **Vibrate**
   - Biarkan "Use Gradle Build" mati (APK lebih kecil, lebih simpel)
6. Colok HP (Opsi Pengembang -> USB debugging) lalu klik ikon Android di kanan atas editor
   (One-click deploy), atau **Export Project** -> simpan `.apk` -> kirim ke HP dan install.
7. Untuk rilis/Play Store: buat release keystore
   (`keytool -v -genkey -keystore burgerwrap-release.keystore -alias burgerwrap -keyalg RSA -keysize 2048 -validity 10000`),
   isi di preset Export (Release), dan **simpan keystore + passwordnya baik-baik**.

## Aset
Tidak ada aset eksternal. Burger, meja, kertas, partikel digambar lewat kode; suara disintesis kode;
font bawaan Godot. Ikon: `icon.svg` milik proyek ini. Kalau mau mempercantik (semuanya gratis):
- Model 3D & ikon: Kenney.nl ("Food Kit", "Game Icons") — CC0
- Suara: Kenney "Interface Sounds"/"Impact Sounds" (CC0), atau freesound.org (filter lisensi CC0)
- Font: Google Fonts "Lilita One" atau "Baloo 2" (SIL OFL)

## Ide pengembangan
Mode endless (waktu bertambah per combo), leaderboard (Google Play Games / server sendiri),
quest harian + login streak, pelanggan & pesanan (burger harus dibungkus sesuai permintaan),
skin burger/meja, power-up (waktu beku, 2x koin), efek suara musik latar, iklan reward opsional.
