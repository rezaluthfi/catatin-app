# Catatin 📊

**Catatin** adalah aplikasi pencatatan keuangan *offline-first* sederhana dan premium yang dirancang khusus untuk mempermudah operasional pembukuan pelaku UMKM. Aplikasi ini awalnya dikembangkan sebagai bagian dari luaran program kerja **KKN-PPM UGM** untuk digitalisasi UMKM di Kecamatan Kabola.

Dengan prinsip kerja yang sepenuhnya mandiri secara offline, seluruh data usaha disimpan secara aman di dalam penyimpanan lokal perangkat tanpa memerlukan koneksi internet ataupun registrasi akun.

---

## 🌟 Fitur Utama

- **🔒 Keamanan Akses PIN Lokal**: Melindungi data keuangan dengan PIN terenkripsi (`flutter_secure_storage`) beserta opsi pertanyaan keamanan untuk pemulihan PIN yang lupa.
- **🛒 Kasir / Point of Sale (POS) Sederhana**: Alur keranjang transaksi penjualan terintegrasi stok produk, lengkap dengan pilihan metode pembayaran Tunai atau Kasbon.
- **📦 Inventaris & Asisten Harga Jual**: Manajemen stok produk dengan asisten perhitungan harga jual otomatis berdasarkan harga beli dan target margin keuntungan (persentase/nominal).
- **💸 Buku Piutang (Kasbon) Pelanggan**: Pencatatan piutang terhubung transaksi maupun manual, pencatatan pembayaran cicilan dengan *inline overpayment validation*, dan penanda status pelunasan.
- **📈 Rekapitulasi & Grafik Tren**: Laporan keuangan periodik (harian, mingguan, bulanan) dilengkapi dengan grafik area/gradient laba bersih dan pengeluaran operasional.
- **📄 Ekspor Laporan Keuangan (PDF & XLSX)**: Pembuatan dokumen laporan siap cetak (PDF) dan berkas spreadsheet analisis (Excel/XLSX) yang dapat langsung disimpan ke perangkat (*Local Save*) maupun dibagikan ke media sosial (*Share*).
- **💾 Backup & Restore Mandiri**: Backup data lengkap berupa file JSON yang dapat diimpor kembali secara aman untuk portabilitas saat berganti perangkat.

---

## 🛠️ Tech Stack & Dependensi

Aplikasi dikembangkan menggunakan kerangka kerja **Flutter** dengan pustaka-pustaka andalan berikut:

- **State Management**: [Flutter Riverpod](https://pub.dev/packages/flutter_riverpod) (Arsitektur reaktif berbasis provider).
- **Database Lokal**: [sqflite](https://pub.dev/packages/sqflite) (SQLite untuk performa data offline).
- **Enkripsi Kredensial**: [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) (Menyimpan hash PIN secara aman).
- **Visualisasi Grafik**: [fl_chart](https://pub.dev/packages/fl_chart) (Grafik interaktif laba/pemasukan).
- **Pembuat PDF**: [pdf](https://pub.dev/packages/pdf) & [printing](https://pub.dev/packages/printing) (Dokumen layout laporan A4).
- **Pembuat Excel**: [excel](https://pub.dev/packages/excel) (Format file spreadsheet `.xlsx`).
- **Interaksi Perangkat**: [share_plus](https://pub.dev/packages/share_plus) & [file_picker](https://pub.dev/packages/file_picker) (Berbagi berkas dan pemilih file lokal).

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
│   ├── utils/            # Formatter & hasher PIN
│   └── widgets/          # Widget re-useable (Shimmer loading)
├── data/                 # Implementasi model data & repository konkret
├── domain/               # Kontrak abstraksi repository interfaces
└── features/             # Modul bisnis/fitur aplikasi
    ├── auth/             # Logika PIN Lock Screen & pertanyan keamanan
    ├── dashboard/        # Dashboard ringkasan & alert stok
    ├── inventory/        # Manajemen produk & asisten harga jual
    ├── pos/              # Keranjang belanja kasir & checkout
    ├── receivables/      # Buku piutang & pembayaran cicilan
    ├── recap/            # Rekap transaksi, pengeluaran & grafik laba
    └─ settings/          # Backup/restore & ekspor laporan
```

---

## 🚀 Memulai Proyek

Ikuti langkah berikut untuk menjalankan proyek Catatin di lingkungan pengembangan lokal Anda:

### Prasyarat
- [Flutter SDK](https://docs.flutter.dev/get-started/install) terpasang di perangkat Anda (direkomendasikan versi SDK `^3.9.2`).
- Koneksi ke emulator Android/iOS atau perangkat fisik dengan fitur debugging aktif.

### Langkah Instalasi

1. **Clone repositori proyek**:
   ```bash
   git clone <url-repository>
   cd catatin
   ```

2. **Dapatkan paket dependensi**:
   ```bash
   flutter pub get
   ```

3. **Jalankan aplikasi di perangkat tujuan**:
   ```bash
   flutter run
   ```

4. **Kompilasi build APK rilis (opsional)**:
   ```bash
   flutter build apk --release
   ```

---

## 📄 Lisensi

Dokumen dan produk akhir aplikasi ini dikembangkan untuk keperluan pengabdian masyarakat (KKN-PPM UGM Kabola) dan dapat dimodifikasi secara bebas untuk kebutuhan keberlanjutan digitalisasi UMKM Indonesia.
