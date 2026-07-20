<p align="center">
  <img src="assets/images/logo_bg_primary.jpeg" alt="Logo CatatIn" width="120" />
</p>

<h1 align="center">CatatIn</h1>

**CatatIn** adalah aplikasi pencatatan keuangan *offline-first* untuk pelaku UMKM. Tanpa koneksi internet dan tanpa registrasi akun, setiap transaksi, stok, hingga piutang usaha bisa dicatat rapi langsung dari genggaman sehingga pembukuan tidak lagi jadi beban di tengah kesibukan berjualan.

CatatIn lahir dari program kerja **KKN-PPM UGM Alor Carita 2026** untuk digitalisasi UMKM di Kecamatan Kabola, Kabupaten Alor, Nusa Tenggara Timur. Aplikasi ini dirancang khusus untuk kondisi lapangan dengan akses internet yang terbatas, di mana keandalan offline justru menjadi kebutuhan utama, bukan sekadar fitur tambahan.

Berkat prinsip kerja yang sepenuhnya mandiri secara offline, seluruh data usaha disimpan secara aman di dalam penyimpanan lokal perangkat.

---

## 🌟 Fitur Utama

- **🔒 Keamanan Akses PIN Lokal**: Melindungi data keuangan dengan PIN terenkripsi (`flutter_secure_storage`), lengkap dengan opsi pertanyaan keamanan untuk pemulihan PIN jika lupa.
- **🛒 Kasir / Point of Sale (POS)**: Alur keranjang transaksi penjualan yang terintegrasi dengan stok produk, lengkap dengan pilihan metode pembayaran **Tunai**, **Non-Tunai** (QRIS/Transfer), dan **Kasbon**.
- **📦 Inventaris & Riwayat Stok**: Manajemen produk dilengkapi asisten perhitungan harga jual otomatis berdasarkan harga beli dan margin keuntungan. Mendukung unggah foto produk melalui kamera/galeri, dilengkapi fitur potong gambar (*Image Cropper*), serta pelacakan **Riwayat Stok & Harga**.
- **💸 Buku Piutang (Kasbon) Pelanggan**: Pencatatan piutang dapat dilakukan baik melalui transaksi maupun secara manual dengan pembayaran cicilan yang dilengkapi *inline overpayment validation* serta penanda status pelunasan otomatis.
- **📈 Rekapitulasi & Grafik Tren Sinkron**: Laporan keuangan periodik (harian, mingguan, bulanan) dengan grafik tren keuangan yang tersinkronisasi penuh antara Dashboard dan Menu Rekap.
- **📄 Ekspor Laporan Keuangan (PDF & XLSX)**: Pembuatan dokumen laporan siap cetak (PDF) dengan format A4 yang rapi serta dokumen spreadsheet analisis (Excel/XLSX). Dokumen dapat disimpan secara lokal (*Save*) maupun dibagikan langsung (*Share*) ke aplikasi lain.
- **💾 Backup & Restore Mandiri**: Ekspor data lengkap berupa file JSON yang dapat diimpor kembali secara aman saat berganti perangkat.

---

## 🛠️ Tech Stack & Dependensi

Aplikasi dikembangkan menggunakan *framework* **Flutter** dengan *library* berikut:

- **State Management**: [Flutter Riverpod](https://pub.dev/packages/flutter_riverpod) (arsitektur reaktif berbasis provider).
- **Database Lokal**: [sqflite](https://pub.dev/packages/sqflite) (SQLite untuk performa data offline).
- **Enkripsi Kredensial**: [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) (menyimpan hash PIN secara aman).
- **Visualisasi Grafik**: [fl_chart](https://pub.dev/packages/fl_chart) (grafik interaktif laba/pemasukan).
- **Pembuat PDF**: [pdf](https://pub.dev/packages/pdf) & [printing](https://pub.dev/packages/printing) (dokumen layout laporan A4).
- **Pembuat Excel**: [excel](https://pub.dev/packages/excel) (format file spreadsheet `.xlsx`).
- **Media & Foto Produk**: [image_picker](https://pub.dev/packages/image_picker) & [image_cropper](https://pub.dev/packages/image_cropper) (pengambilan foto dan pemotongan gambar produk).
- **Interaksi Perangkat**: [share_plus](https://pub.dev/packages/share_plus) & [file_picker](https://pub.dev/packages/file_picker) (berbagi berkas dan pemilih file lokal).

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

## 🚀 Memulai Proyek

Ikuti langkah berikut untuk menjalankan proyek CatatIn di lingkungan pengembangan lokal Anda:

### Prasyarat
- [Flutter SDK](https://docs.flutter.dev/get-started/install) terpasang di perangkat Anda (direkomendasikan versi SDK `^3.9.2`).
- Koneksi ke emulator Android/iOS atau perangkat fisik dengan fitur debugging aktif.

### Langkah Instalasi

1. **Clone repositori proyek**:
   ```bash
   git clone https://github.com/rezaluthfi/catatin-app
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

Dokumen dan produk akhir aplikasi ini dikembangkan untuk keperluan pengabdian masyarakat (KKN-PPM UGM Alor Carita 2026) dan dapat dimodifikasi secara bebas untuk kebutuhan keberlanjutan digitalisasi UMKM Indonesia.