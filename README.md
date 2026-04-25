<p align="center">
  <img src="assets/images/logo.png" alt="TemanNakes Logo" width="120"/>
</p>

<h1 align="center">TemanNakes</h1>
<p align="center">
  <b>Asisten Klinis Referensi Obat Offline untuk Tenaga Kesehatan Indonesia</b>
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter" alt="Flutter"/></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.x-blue?logo=dart" alt="Dart"/></a>
  <img src="https://img.shields.io/badge/Platform-Android-green?logo=android" alt="Android"/>
  <img src="https://img.shields.io/badge/Database-SQLite%20FTS5-orange" alt="SQLite"/>
  <img src="https://img.shields.io/badge/Status-Production Ready-brightgreen" alt="Status"/>
  <img src="https://img.shields.io/badge/Obat-20.565%20entri-blueviolet" alt="Database"/>
</p>

---

## 📖 Tentang Aplikasi

**TemanNakes** adalah aplikasi referensi klinis obat yang dirancang khusus untuk **tenaga kesehatan Indonesia** — dokter, perawat, bidan, apoteker, dan profesi medis lainnya. Aplikasi ini bekerja **100% offline** dan menyediakan akses cepat ke database 20.565 obat terverifikasi BPOM, disertai kalkulator medis klinis terintegrasi.

> ⚠️ **Disclaimer**: Aplikasi ini adalah alat bantu pengambilan keputusan klinis. Tidak menggantikan keputusan dokter atau tenaga medis profesional.

---

## ✨ Fitur Utama

### 🔍 Pencarian Obat Canggih
- **FTS5 + BM25 Ranked Search** — sub-300ms untuk 20.565+ entri
- **Pencarian prefix** — ketik sebagian nama langsung ditemukan
- **Filter Golongan**: Keras, Bebas, Terbatas, Narkotika, Psikotropika
- **Filter Bentuk Sediaan**: Tablet, Kapsul, Sirup, Injeksi, Salep, Tetes, Inhaler
- **Mode Emergency** — menampilkan obat-obat resusitasi kritis dengan satu ketukan
- **Riwayat & Saran Pencarian** — saran cepat obat-obat esensial

### 💊 Detail Obat Klinis Lengkap
Setiap obat dilengkapi:

| Field | Keterangan |
|-------|-----------|
| Indikasi | Penyakit/kondisi yang ditangani |
| Dosis Dewasa & Anak | Termasuk range mg/kg dan mg/m² |
| Efek Samping | Daftar efek yang mungkin terjadi |
| Kontraindikasi | Kondisi yang tidak boleh diberikan |
| Interaksi Obat | Interaksi signifikan secara klinis |
| Penyesuaian Ginjal | Dosis pada gangguan renal |
| Kategori Kehamilan | A / B / C / D / X |
| Kelas Terapi | Klasifikasi farmakologi |
| Clinical Pearls | Mutiara klinis terpilih |
| Storage | Petunjuk penyimpanan |

### ⚡ Cek Interaksi Obat
- **Pharmacological Class-Matrix v2.0** — deteksi interaksi antar kelas farmakologi
- 20+ pasangan interaksi klinis signifikan
- Skala keparahan: **Minor** / **Moderate** / **Major**
- Tambah & hapus obat secara dinamis

### 🧮 Kalkulator Medis Nakes (6 Modul)

| # | Modul | Formula / Fitur |
|---|-------|----------------|
| 1 | **Dosis Obat** | mg/kgBB, capping dosis maks, konversi tablet & sirup/injeksi |
| 2 | **Infus** | Tetes/menit (faktor 20/60) & kecepatan pump mL/jam |
| 3 | **Status Pasien** | BMI + kategori, MAP, Shock Index |
| 4 | **Kebidanan** | HPL (Naegele), usia kehamilan, TBJ (Johnson) |
| 5 | **Emergency** | GCS (Eye+Verbal+Motor) + APGAR Score |
| 6 | **Ginjal & Obat** | CrCl (Cockcroft-Gault) + eGFR (CKD-EPI 2021) |

Semua modul dilengkapi:
- 🟢🟡🔴 Indikator keparahan klinis otomatis
- 📚 Mode Edukasi — langkah-langkah perhitungan bisa di-expand
- 💾 Riwayat 50 perhitungan terakhir
- ⚠️ Disclaimer klinis pada setiap hasil

### 💉 Kalkulator Dosis Klinis Per-Obat
Diakses dari halaman detail obat:
- **BSA Mosteller** — kalkulasi berbasis luas permukaan tubuh
- **Age-Guard** — peringatan otomatis obat dewasa pada anak
- **Safety Buffer** — capping ke maksimum dewasa otomatis
- **Renal Guard** — menampilkan penyesuaian ginjal bila dipilih

---

## 🏗️ Arsitektur

```
lib/
├── main.dart                          # Entry point, Splash, Disclaimer
├── core/
│   ├── database/database_helper.dart  # SQLite + FTS5 + Favorites
│   ├── theme/app_theme.dart           # MaterialTheme (Green Medical)
│   └── utils/logger.dart
└── features/
    ├── medicine/                      # Fitur pencarian & referensi obat
    │   ├── domain/models/medicine.dart
    │   └── presentation/
    │       ├── providers/medicine_provider.dart
    │       ├── views/ (home, detail, interaction, category)
    │       └── widgets/medicine_list_tile.dart
    ├── calculator/                    # Kalkulator dosis per-obat
    ├── favorites/                     # Obat favorit (SQLite persisten)
    └── medical_calculator/            # Kalkulator Medis 6 modul
        ├── domain/
        │   ├── models/calc_result.dart
        │   └── logic/ (6 modul logika murni Dart)
        └── presentation/
            ├── providers/calc_history_provider.dart
            ├── widgets/ (CalcResultCard, CalcInputField)
            └── views/ (hub + 6 modul)
```

### State Management: Flutter Riverpod

| Provider | Tipe | Fungsi |
|----------|------|--------|
| `searchQueryProvider` | StateProvider | Query pencarian aktif |
| `categoryFilterProvider` | StateProvider | Filter golongan obat |
| `formFilterProvider` | StateProvider | Filter bentuk sediaan |
| `medicineListProvider` | FutureProvider | Hasil FTS5 search |
| `medicineDetailProvider` | FutureProvider.family | Detail obat (auto-dispose) |
| `favoritesProvider` | StateNotifierProvider | Favorit persisten |
| `trendingMedicinesProvider` | FutureProvider | 5 referensi cepat |
| `calcHistoryProvider` | StateNotifierProvider | Riwayat kalkulator |

---

## 🗄️ Database

- **File**: `assets/database/temannakes.db` (SQLite)
- **Tabel**:

| Tabel | Isi |
|-------|-----|
| `obat` | 20.565 obat generik & dagang |
| `obat_fts` | FTS5 virtual table |
| `obat_detail` | Data klinis lengkap |
| `obat_kategori` | Relasi obat ↔ kategori |
| `kategori` | Daftar kategori penyakit |
| `favorit` | Favorit pengguna |

- **Performa**: BM25 ranked FTS5 — sub-300ms pada 20k+ entri
- **Integritas**: `PRAGMA integrity_check` saat pertama buka

### Regenerasi Database
```bash
python3 scripts/generate_db.py
```

---

## 🚀 Setup & Build

### Prasyarat
- Flutter SDK 3.x+
- Dart 3.x+
- JDK 17
- Android SDK 34 (Android 14)

### Instalasi
```bash
git clone https://github.com/gilangrizkyr/TemanNakes.git
cd TemanNakes
flutter pub get
flutter run
```

### Build APK
```bash
# Debug
flutter build apk --debug

# Release
flutter build apk --release
```

**Output**: `build/app/outputs/flutter-apk/`

---

## 📦 Dependencies

```yaml
dependencies:
  flutter_riverpod: ^2.x   # State management
  sqflite: ^2.x            # SQLite database
  path: ^1.x               # Path utilities
  google_fonts: ^6.x       # Typography
  url_launcher: ^6.x       # External links
```

---

## 🔒 Keamanan & Privasi

- ✅ **100% Offline** — tidak ada data yang dikirim ke server
- ✅ **Tidak ada tracking** — tidak ada analytics, tidak ada iklan
- ✅ **Data lokal** — semua data tersimpan di perangkat pengguna
- ✅ **BPOM Compliant** — data bersumber dari registrasi resmi BPOM

---

## 📱 Kompatibilitas

| Platform | Status |
|----------|--------|
| Android 5.0+ (API 21+) | ✅ Didukung |
| Android 14 (API 34) | ✅ Target SDK |
| iOS | ⚠️ Belum diuji |

---

## 🤝 Kontribusi

1. Fork repository
2. Buat branch: `git checkout -b fitur/nama-fitur`
3. Commit: `git commit -m 'feat: tambah fitur X'`
4. Push: `git push origin fitur/nama-fitur`
5. Buat Pull Request

> Untuk pembaruan data obat, edit `scripts/generate_db.py` lalu jalankan ulang.

---

## 📄 Lisensi

```
Copyright (c) 2024-2025 GilangRizky
MIT License
```

---

## 👨‍💻 Pengembang

**GilangRizky**
- GitHub: [@gilangrizkyr](https://github.com/gilangrizkyr)
- Package: `com.gilangrizky.temannakes`

---

<p align="center"><i>Dibuat dengan ❤️ untuk tenaga kesehatan Indonesia</i></p>
