# Product Requirements Document (PRD)
# Catatin — Aplikasi Pencatatan Keuangan Offline untuk UMKM

| | |
|---|---|
| **Nama Produk** | Catatin |
| **Versi Dokumen** | 1.0 |
| **Tanggal** | 7 Juli 2026 |
| **Platform** | Mobile (Android — Flutter) |
| **Konteks** | Program Kerja KKN — Digitalisasi UMKM Kabola |
| **Status** | Draft |

---

## 1. Latar Belakang

Pelaku UMKM di wilayah Kabola pada umumnya belum memiliki sistem pencatatan keuangan yang rapi. Pencatatan transaksi, stok barang, dan biaya operasional masih dilakukan secara manual atau bahkan tidak dicatat sama sekali, sehingga pemilik usaha kesulitan mengetahui kondisi keuntungan usahanya secara pasti.

Keterbatasan akses internet yang stabil di beberapa area juga menjadi pertimbangan, sehingga aplikasi perlu dapat beroperasi **sepenuhnya offline**, termasuk dalam hal penyimpanan data.

## 2. Tujuan Produk

- Memberikan alat bantu pencatatan keuangan yang **sederhana dan mudah digunakan** oleh pelaku UMKM tanpa latar belakang teknis.
- Memungkinkan pemilik usaha memantau **stok barang, transaksi harian, dan keuntungan** tanpa perlu koneksi internet.
- Menghasilkan **rekapitulasi otomatis** (harian, mingguan, bulanan) agar pemilik usaha tidak perlu menghitung manual.
- Menjadi luaran proker KKN yang dapat **diserahterimakan dan digunakan mandiri** oleh UMKM setelah masa KKN berakhir.

## 3. Target Pengguna

| Peran | Deskripsi |
|---|---|
| **User (Pemilik UMKM)** | Satu pengguna per perangkat, mengelola seluruh data usahanya sendiri. Tidak ada peran admin/kasir terpisah pada versi ini. |

> Catatan: Sesuai kesepakatan sebelumnya, aplikasi didesain **single-user, single-device** — tidak ada sistem login multi-akun.

## 4. Ruang Lingkup (Scope)

### 4.1 Termasuk dalam Scope (In Scope)
- Keamanan akses via PIN lokal
- CRUD data produk/inventaris, termasuk bantuan penentuan harga jual
- Pencatatan transaksi (Point of Sale sederhana)
- Pencatatan piutang pelanggan (kasbon)
- Rekapitulasi harian, mingguan, dan bulanan
- Dashboard ringkasan usaha
- Profil usaha dan pengaturan dasar
- Penyimpanan data 100% lokal (offline)

### 4.2 Tidak Termasuk dalam Scope (Out of Scope)
- Sinkronisasi data antar perangkat (multi-device sync)
- Sistem multi-user/role (kasir, admin, dsb.)
- Cloud backup otomatis
- Integrasi pembayaran digital (QRIS, e-wallet, dll.)
- Manajemen banyak cabang/usaha dalam satu akun
- Pencatatan utang usaha ke supplier (fokus hanya pada piutang pelanggan)

## 5. Asumsi & Batasan

- Aplikasi berjalan **tanpa koneksi internet** pada seluruh fiturnya, termasuk penyimpanan data (menggunakan database lokal).
- Aplikasi didesain **ringan** dari sisi ukuran maupun penggunaan memori HP, mengingat target pengguna umumnya memakai perangkat kelas menengah-bawah.
- Data tidak berpindah otomatis antar perangkat; perpindahan data (misal saat ganti HP) dilakukan melalui fitur **export/import manual**.
- Tidak ada proses autentikasi berbasis akun (username/password); keamanan akses cukup menggunakan **PIN**.

## 6. Alur Pengguna (High-Level User Flow)

```
Buka Aplikasi
   └─▶ Input PIN
         └─▶ Dashboard
               ├─▶ Inventarisasi (kelola produk)
               ├─▶ POS (catat transaksi)
               ├─▶ Rekapitulasi (harian/mingguan/bulanan)
               └─▶ Profil & Pengaturan
```

### 6.1 Struktur Navigasi

Aplikasi menggunakan **Bottom Navigation Bar** sebagai pola navigasi utama, mengingat jumlah destinasi utama (4-5 menu) yang idealnya sejajar dengan angka ini, serta familiaritas pattern ini bagi pengguna non-teknis.

**POS diposisikan sebagai Floating Action Button (FAB) di tengah**, mengingat fitur ini adalah aksi yang paling sering dilakukan pengguna sehari-hari:

```
[Dashboard]   [Inventarisasi]   ( + POS )   [Rekapitulasi]   [Profil]
```

- **Rekapitulasi** (harian, mingguan, bulanan) digabung menjadi **satu tab** dengan sub-tab/segmented control di dalamnya, agar bottom navigation tidak terlalu penuh dengan menu.
- **Piutang** tidak dijadikan tab bottom navigation tersendiri (agar tidak melebihi 5 item) — melainkan diakses melalui:
  - Shortcut/kartu ringkasan di **Dashboard** (menampilkan total piutang, tap untuk buka daftar lengkap), dan
  - Otomatis muncul sebagai bagian dari alur checkout POS saat metode Kasbon dipilih.
- Implementasi teknis: `Scaffold` dengan `bottomNavigationBar` (`NavigationBar` — Material 3) dikombinasikan dengan `floatingActionButton` pada `FloatingActionButtonLocation.centerDocked`.

---

## 7. Kebutuhan Fungsional (Functional Requirements)

### FR-1. PIN Keamanan
| | |
|---|---|
| **Deskripsi** | Pengguna mengatur PIN saat pertama kali membuka aplikasi, dan wajib memasukkan PIN setiap kali membuka aplikasi. |
| **User Story** | Sebagai pemilik usaha, saya ingin mengunci aplikasi dengan PIN agar data usaha saya tidak sembarang diakses orang lain. |
| **Acceptance Criteria** | - Pengguna dapat membuat PIN (4–6 digit) saat setup awal.<br>- Aplikasi meminta PIN setiap kali dibuka.<br>- Tersedia fitur ubah PIN di menu Pengaturan.<br>- Tersedia mekanisme reset PIN (misal via pertanyaan keamanan sederhana) untuk kasus lupa PIN. |
| **Catatan Teknis** | PIN disimpan dalam bentuk terenkripsi menggunakan `flutter_secure_storage`, bukan disimpan sebagai teks biasa. |

### FR-2. CRUD Inventarisasi Persediaan
| | |
|---|---|
| **Deskripsi** | Pengguna dapat menambah, melihat, mengubah, dan menghapus data produk yang dijual. Form tambah/edit produk juga menyediakan bantuan penentuan harga jual berdasarkan harga beli dan margin yang diinginkan. |
| **Field Data** | Nama produk, harga beli, harga jual, kuantitas (stok), biaya operasional terkait produk (opsional per item). |
| **User Story** | Sebagai pemilik usaha, saya ingin mencatat semua produk yang saya jual beserta harga dan stoknya, dan mendapat bantuan menentukan harga jual yang wajar tanpa perlu hitung manual. |
| **Alur Bantuan Harga Jual** | 1) Pengguna input harga beli.<br>2) Pengguna memilih mode bantuan: **persentase margin** (mis. 20%) atau **nominal keuntungan** (mis. Rp 3.000).<br>3) Sistem otomatis menghitung dan mengisi kolom harga jual berdasarkan pilihan tersebut.<br>4) Pengguna tetap dapat mengedit manual hasil perhitungan sebelum menyimpan. |
| **Acceptance Criteria** | - Tambah produk baru dengan field wajib: nama, harga beli, harga jual, kuantitas.<br>- Edit data produk yang sudah ada.<br>- Hapus produk (dengan konfirmasi).<br>- Lihat daftar seluruh produk beserta stok tersisa.<br>- Validasi input (harga dan kuantitas tidak boleh negatif).<br>- Tersedia opsi bantuan hitung harga jual (mode persentase margin atau nominal keuntungan) yang terintegrasi langsung di form produk.<br>- Hasil perhitungan harga jual tetap dapat diubah manual oleh pengguna. |

### FR-3. Point of Sale (POS) — Input Transaksi
| | |
|---|---|
| **Deskripsi** | Fitur pencatatan transaksi penjualan bergaya keranjang (cart) — pengguna memilih produk langsung dari data inventaris yang sudah ada, bisa lebih dari satu produk berbeda dalam satu transaksi, tanpa perlu input ulang nama/harga produk. |
| **User Story** | Sebagai pemilik usaha, saya ingin mencatat transaksi dengan cepat cukup dengan menekan produk yang terjual, termasuk saat pembeli membeli beberapa produk berbeda sekaligus. |
| **Alur** | 1) Tampilkan daftar/grid produk dari data Inventarisasi.<br>2) Pengguna tap produk → produk masuk ke keranjang sementara.<br>3) Pengguna dapat menambahkan produk lain ke keranjang yang sama, atau mengubah kuantitas tiap item di keranjang.<br>4) Sistem menghitung subtotal per item dan total keseluruhan transaksi secara otomatis.<br>5) Pengguna memilih metode pembayaran: **Tunai** atau **Kasbon**.<br>6) Jika Kasbon dipilih, pengguna input nama pelanggan → transaksi otomatis tercatat sebagai piutang.<br>7) Pengguna menekan "Selesai" untuk menyimpan transaksi. |
| **Acceptance Criteria** | - Produk dipilih langsung dari daftar inventaris (tanpa input manual nama/harga).<br>- Satu transaksi dapat berisi lebih dari satu produk berbeda (keranjang).<br>- Kuantitas tiap item dalam keranjang dapat diubah sebelum transaksi disimpan.<br>- Item dapat dihapus dari keranjang sebelum disimpan.<br>- Sistem otomatis menghitung subtotal per item dan total transaksi.<br>- Stok tiap produk otomatis berkurang sesuai kuantitas pada transaksi setelah disimpan.<br>- Transaksi tersimpan dengan timestamp otomatis, mencakup seluruh item di dalamnya.<br>- Pengguna dapat memilih metode pembayaran Tunai atau Kasbon saat checkout.<br>- Jika Kasbon dipilih, sistem otomatis membuat catatan piutang baru terhubung ke transaksi tersebut.<br>- (Opsional) Input transaksi pengeluaran/biaya operasional di luar penjualan. |

### FR-4. Pencatatan Piutang Pelanggan (Kasbon)
| | |
|---|---|
| **Deskripsi** | Fitur pencatatan pelanggan yang membeli secara kasbon (belum bayar penuh), agar pemilik usaha dapat memantau dan menagih piutang yang belum lunas. |
| **User Story** | Sebagai pemilik usaha, saya ingin mencatat siapa saja pelanggan yang masih punya utang ke saya, supaya tidak ada yang terlupa saat menagih. |
| **Sumber Data Piutang** | - **Otomatis**: dibuat dari transaksi POS saat metode pembayaran "Kasbon" dipilih (lihat FR-3).<br>- **Manual**: pengguna juga dapat menambahkan catatan piutang secara langsung (misal piutang lama yang belum tercatat di sistem). |
| **Acceptance Criteria** | - Menampilkan daftar piutang aktif (belum lunas) beserta nama pelanggan, jumlah, dan tanggal.<br>- Tambah piutang manual (nama pelanggan, jumlah, tanggal, catatan opsional).<br>- Tandai piutang sebagai **lunas** (baik lunas penuh maupun cicilan/bayar sebagian).<br>- Menampilkan total keseluruhan piutang yang belum tertagih.<br>- Riwayat piutang yang sudah lunas tetap tersimpan (tidak dihapus, hanya berubah status). |

### FR-5. Rekapitulasi Harian & Mingguan
| | |
|---|---|
| **Deskripsi** | Ringkasan otomatis atas transaksi dalam rentang harian dan mingguan. |
| **User Story** | Sebagai pemilik usaha, saya ingin melihat ringkasan penjualan hari ini dan minggu ini tanpa perlu menghitung manual. |
| **Acceptance Criteria** | - Menampilkan total barang terjual (harian & mingguan).<br>- Menampilkan total kas masuk (penjualan) dan kas keluar (biaya operasional/pembelian stok).<br>- Data dapat difilter berdasarkan tanggal/rentang minggu. |

### FR-6. Rekapitulasi Bulanan
| | |
|---|---|
| **Deskripsi** | Ringkasan bulanan yang berfokus pada perhitungan **keuntungan** (bukan hanya kas masuk-keluar). |
| **User Story** | Sebagai pemilik usaha, saya ingin tahu berapa keuntungan bersih usaha saya setiap bulan. |
| **Acceptance Criteria** | - Perhitungan keuntungan = total penjualan − (harga beli produk terjual + biaya operasional).<br>- Ditampilkan per bulan, dengan opsi melihat bulan-bulan sebelumnya.<br>- (Nice-to-have) Grafik tren keuntungan antar bulan. |

### FR-7. Dashboard
| | |
|---|---|
| **Deskripsi** | Halaman utama yang menampilkan ringkasan kondisi usaha secara sekilas. |
| **User Story** | Sebagai pemilik usaha, saya ingin langsung melihat kondisi usaha saya begitu membuka aplikasi. |
| **Acceptance Criteria** | - Menampilkan ringkasan kas hari ini (masuk/keluar).<br>- Menampilkan total piutang yang belum tertagih.<br>- Menampilkan jumlah produk dengan stok menipis (opsional, jika sederhana untuk diimplementasi).<br>- Akses cepat (shortcut) ke fitur POS dan Inventarisasi. |

### FR-8. Profil & Pengaturan
| | |
|---|---|
| **Deskripsi** | Pengaturan dasar aplikasi dan data usaha. |
| **User Story** | Sebagai pemilik usaha, saya ingin mengatur informasi usaha saya dan melakukan backup data agar aman jika suatu saat ganti HP. |
| **Acceptance Criteria** | - Edit nama usaha/pemilik.<br>- Ubah PIN.<br>- **Export data** (backup ke file lokal).<br>- **Import data** (restore dari file backup).<br>- Info versi aplikasi. |

---

## 8. Kebutuhan Non-Fungsional (Non-Functional Requirements)

| Aspek | Kebutuhan |
|---|---|
| **Offline-First** | Seluruh fitur, termasuk penyimpanan data, berfungsi tanpa koneksi internet. |
| **Ringan** | Ukuran aplikasi dan penggunaan memori dioptimalkan untuk perangkat kelas menengah-bawah (hindari library berat, kompres aset). |
| **Keamanan Data** | PIN tersimpan terenkripsi; data transaksi tersimpan lokal di database perangkat. |
| **Kemudahan Penggunaan** | UI sederhana, alur minim langkah, sesuai untuk pengguna non-teknis. |
| **Reliabilitas Data** | Tidak ada kehilangan data akibat crash aplikasi (transaksi tersimpan segera setelah input). |
| **Portabilitas Data** | Data dapat dipindahkan antar perangkat melalui export/import manual. |

## 9. Struktur Data (Gambaran Umum)

| Entitas | Field Utama |
|---|---|
| **Produk** | id, nama, harga_beli, harga_jual, kuantitas, biaya_operasional |
| **Transaksi** (header) | id, tanggal, total_harga, jenis (masuk/keluar), metode_pembayaran (tunai/kasbon) |
| **Transaksi_Item** (detail) | id, transaksi_id, produk_id, jumlah_terjual, subtotal |
| **Piutang** | id, transaksi_id (nullable — kosong jika input manual), nama_pelanggan, jumlah, tanggal, status (belum_lunas/lunas), catatan |
| **Biaya Operasional** | id, deskripsi, nominal, tanggal |
| **Pengaturan** | pin_hash, nama_usaha, nama_pemilik |

> Karena satu transaksi POS dapat berisi beberapa produk berbeda (keranjang), struktur data menggunakan **relasi satu-ke-banyak**: satu baris **Transaksi** (header, menyimpan total & tanggal) terhubung ke banyak baris **Transaksi_Item** (detail per produk). Ini menghindari duplikasi data transaksi saat 1 pembelian berisi beberapa item.
>
> Tabel **Piutang** terhubung secara opsional ke **Transaksi** — terisi otomatis jika transaksi dibayar dengan metode Kasbon, atau dapat diisi manual tanpa transaksi terkait (misal piutang lama).
>
> Struktur ini bersifat gambaran awal — detail skema tabel SQLite dapat disusun lebih lanjut pada tahap desain teknis.

## 10. Tech Stack Rujukan

Berdasarkan diskusi sebelumnya, berikut stack yang direkomendasikan:

- **Framework**: Flutter
- **Database**: `sqflite`
- **State Management**: `provider` / `riverpod`
- **Keamanan PIN**: `flutter_secure_storage`
- **Grafik**: `fl_chart`
- **Export/Import**: `path_provider`, `file_picker`, `share_plus`
- **Utilitas**: `intl` (format Rupiah & tanggal), `uuid`

## 11. Metrik Keberhasilan (Success Metrics)

- Aplikasi berhasil diinstal dan digunakan oleh minimal 1 UMKM mitra di Kabola.
- Pemilik usaha dapat melakukan pencatatan transaksi secara mandiri tanpa pendampingan setelah pelatihan.
- Laporan rekapitulasi (harian/mingguan/bulanan) dapat diakses dan dipahami oleh pemilik usaha tanpa bantuan lanjutan.
- Tidak ditemukan kendala penggunaan aplikasi tanpa koneksi internet selama masa uji coba.

## 12. Potensi Pengembangan Selanjutnya (Future Scope)

*Di luar scope proker KKN saat ini, namun dapat menjadi catatan pengembangan lanjutan:*

- Notifikasi/reminder stok menipis
- Cetak/export nota transaksi ke PDF
- Sistem multi-user/role (kasir terpisah dari pemilik)
- Sinkronisasi data antar perangkat (cloud atau local network)
- Manajemen multi-cabang/multi-usaha dalam satu akun

---

## Lampiran: Keputusan Desain yang Sudah Disepakati

- Aplikasi bersifat **single-device**, tidak ada sinkronisasi otomatis antar perangkat.
- Keamanan menggunakan **PIN lock**, bukan sistem login username/password.
- Perpindahan data antar perangkat dilakukan melalui **export/import manual**.
- Prioritas desain: **ringan, offline, mudah digunakan** oleh pelaku UMKM non-teknis.
