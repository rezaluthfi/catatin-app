<p align="center">
  <img src="assets/images/logo_bg_primary.jpeg" alt="Logo CatatIn" width="120" style="border-radius: 24px;" />
</p>

<h1 align="center">CatatIn</h1>

<p align="center">
  <b>Aplikasi Kasir (POS) & Pencatatan Keuangan UMKM Offline-First Cross-Platform</b><br />
  <i>Satu Codebase untuk Android & Windows</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat-square&logo=Flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Platforms-Android%20%7C%20Windows-198D8D?style=flat-square" alt="Platforms" />
  <img src="https://img.shields.io/badge/Version-1.0.0-success?style=flat-square" alt="Version" />
  <img src="https://img.shields.io/badge/Offline--First-100%25-orange?style=flat-square" alt="Offline-First" />
</p>

---

## 📖 Tentang CatatIn

**CatatIn** adalah aplikasi pencatatan keuangan dan kasir *offline-first* yang dirancang untuk memenuhi kebutuhan pembukuan pelaku UMKM. Seluruh transaksi penjualan, inventaris stok, hingga piutang pelanggan dapat dikelola dengan mudah tanpa memerlukan koneksi internet maupun registrasi akun.

CatatIn dikembangkan sebagai bagian dari program kerja **KKN-PPM UGM Alor Carita 2026** untuk mendukung digitalisasi UMKM di Kecamatan Kabola, Kabupaten Alor, Nusa Tenggara Timur. Seluruh data transaksi disimpan secara lokal di dalam perangkat pengguna untuk menjamin keandalan dan privasi data.

---

## 🌟 Fitur Utama

- 📱💻 **Desain Antarmuka Adaptif**:
  - **Android (Mobile)**: Layout ringkas dan ergonomis yang dioptimalkan untuk penggunaan smartphone.
  - **Windows (Desktop)**: Layout profesional dengan *Navigation Sidebar* dan *Split-Screen POS* untuk pengoperasian komputer/kasir desktop.
- 🔒 **Keamanan PIN Lokal**: Perlindungan data keuangan dengan PIN 6-digit terenkripsi, pertanyaan keamanan untuk pemulihan, serta dukungan keyboard fisik & Numpad pada desktop.
- 🛒 **Kasir / Point of Sale (POS)**: Pencatatan transaksi penjualan dengan kalkulasi uang diterima dan kembalian *real-time*. Mendukung metode pembayaran Tunai, Non-Tunai (QRIS & Transfer Bank), dan Piutang (Kasbon).
- 📦 **Inventaris & Manajemen Stok**: Katalog produk lengkap dengan kalkulasi harga jual berdasarkan margin, riwayat stok masuk/keluar, serta foto produk.
- 💸 **Buku Piutang Pelanggan**: Pencatatan piutang terintegrasi dengan kasir maupun input manual, mendukung pembayaran cicilan bertahap dan pembaruan status pelunasan otomatis.
- 📈 **Rekapitulasi & Grafik Tren**: Visualisasi laporan keuangan periodik (harian, mingguan, bulanan) dengan grafik tren laba dan pemasukan.
- 📄 **Ekspor Laporan Keuangan**: Cetak dokumen laporan keuangan dalam format PDF (A4) dan Excel (.xlsx) multi-sheet.
- 💾 **Penyimpanan Lokal & Backup Data**: Penyimpanan data lokal mandiri serta fitur *Backup & Restore* dalam format berkas JSON.

---

## 🛠️ Tech Stack & Dependensi

Aplikasi dikembangkan menggunakan **Flutter SDK** (`^3.9.2`) dengan dependensi utama:

| Kategori | Paket / Library | Fungsi |
|---|---|---|
| **State Management** | [Flutter Riverpod](https://pub.dev/packages/flutter_riverpod) | Manajemen state reaktif & deklaratif |
| **Database Lokal** | [sqflite](https://pub.dev/packages/sqflite) & [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) | Engine SQLite untuk Android & Windows Desktop |
| **Penyimpanan Aman** | [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) | Penyimpanan kredensial PIN terenkripsi |
| **Visualisasi Grafik** | [fl_chart](https://pub.dev/packages/fl_chart) | Grafik tren pemasukan & laba bersih |
| **Dokumen PDF** | [pdf](https://pub.dev/packages/pdf) & [printing](https://pub.dev/packages/printing) | Pembuatan file PDF A4 |
| **Spreadsheet Excel** | [excel](https://pub.dev/packages/excel) | Pembuatan file `.xlsx` multi-sheet |
| **Media & Gambar** | [image_picker](https://pub.dev/packages/image_picker) & [image_cropper](https://pub.dev/packages/image_cropper) | Pengambilan dan pemotongan foto produk |
| **File System** | [path_provider](https://pub.dev/packages/path_provider) & [file_picker](https://pub.dev/packages/file_picker) | Manajemen folder lokal & dialog pemilih berkas |

---

## 📂 Struktur Direktori Proyek

Proyek ini menggunakan pembagian folder berbasis fitur (*feature-first*) untuk memudahkan pemeliharaan kode:

```text
lib/
├── app/                  # Konfigurasi tema global, router navigasi, dan warna
├── core/                 # Komponen bersama global
│   ├── constants/        # Nama tabel DB & kunci konstan
│   ├── extensions/       # Ekstensi angka Rupiah (.toRupiah())
│   ├── providers/        # Riverpod repository providers
│   ├── services/         # Service logika ekspor PDF/XLSX & backup
│   ├── utils/            # Formatter, hasher PIN, & note parser
│   └── widgets/          # Widget re-useable (Custom Shimmer loading)
├── data/                 # Implementasi model data & repository konkret
├── domain/               # Kontrak abstraksi repository interfaces
└── features/             # Modul bisnis/fitur aplikasi
    ├── auth/             # Logika PIN Lock Screen & pertanyaan keamanan
    ├── dashboard/        # Dashboard ringkasan & alert stok
    ├── inventory/        # Manajemen produk, foto, & asisten harga jual
    ├── pos/              # Keranjang belanja kasir, metode bayar, & checkout
    ├── receivables/      # Buku piutang & pembayaran cicilan
    ├── recap/            # Rekap transaksi, pengeluaran & grafik laba
    └── settings/         # Backup/restore & ekspor laporan
```

---

## 🚀 Memulai & Kompilasi Proyek

Ikuti langkah berikut untuk menjalankan proyek CatatIn di lingkungan pengembangan lokal Anda:

### Prasyarat
- [Flutter SDK](https://docs.flutter.dev/get-started/install) terpasang di perangkat Anda (direkomendasikan versi SDK `^3.9.2`).
- Perangkat Android (emulator/fisik) atau Windows 10/11 (dengan Visual Studio C++ Build Tools).

### Langkah Instalasi

1. **Clone repositori proyek**:
   ```bash
   git clone https://github.com/rezaluthfi/catatin-app.git
   cd catatin
   ```

2. **Dapatkan paket dependensi**:
   ```bash
   flutter pub get
   ```

3. **Jalankan aplikasi di perangkat tujuan**:
   - **Android**:
     ```bash
     flutter run -d android
     ```
   - **Windows Desktop**:
     ```bash
     flutter run -d windows
     ```

4. **Kompilasi build rilis (release build)**:
   - **Kompilasi APK Android**:
     ```bash
     flutter build apk --release
     ```
     *Berkas output*: `build/app/outputs/flutter-apk/app-release.apk`

   - **Kompilasi Executable Windows**:
     ```bash
     flutter build windows --release
     ```
     *Berkas output*: `build/windows/x64/runner/Release/`

---

## 📄 Lisensi

Aplikasi ini dikembangkan untuk kepentingan publik dan pemberdayaan UMKM oleh **Tim KKN-PPM UGM Alor Carita 2026** (Kecamatan Kabola, Kabupaten Alor, Nusa Tenggara Timur).