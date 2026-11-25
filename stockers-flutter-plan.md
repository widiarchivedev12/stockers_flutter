# Stockers Mobile — Rencana Pengerjaan (Flutter, Android, Offline-First)

Port dari web **Stockers** (Laravel + Livewire, stock opname roastery) menjadi aplikasi Android native-feel dengan Flutter. Semua data disimpan lokal di HP, tanpa server dan tanpa akun.

---

## 1. Tujuan & Scope

**Tujuan:** mencatat mutasi stok green bean / roasted bean, mengelola periode bulanan, tutup buku, dan laporan, sepenuhnya offline.

**Termasuk (MVP)**
- Dashboard saldo periode aktif per kode barang
- Input mutasi (masuk / keluar / adjustment) dengan auto-generate kode barang
- Daftar mutasi: filter, sort, pencarian
- Detail per kode barang (kartu stok)
- Laporan periode (total masuk, keluar, saldo akhir)
- Buka periode dan tutup buku (snapshot + carry-over Opening Stock)
- Export Excel (.xlsx) lewat share sheet Android
- Backup dan restore database manual (file `.db` lewat share / file picker)

**Tidak termasuk (sengaja ditunda)**
- Sinkronisasi cloud / multi-device
- Login / multi-user (satu perangkat = satu pemilik; opsional PIN kunci app, lihat fase 5)
- iOS dan web (struktur kode tidak menghalangi, tapi tidak diuji)

---

## 2. Keputusan Arsitektur

| Area | Pilihan | Alasan |
|---|---|---|
| Framework | Flutter 3.x, Dart 3.x | Target Android, satu codebase |
| State management | **Riverpod** (`flutter_riverpod`, `riverpod_generator`) | Sejalan dengan proyek Flutter lain; mudah dites |
| Database | **Drift** (SQLite) | Type-safe, migrasi terversi, transaksi, query reaktif (`watch`) |
| Navigasi | `go_router` | Deep link ke `/stock/:kode`, bottom nav dengan shell route |
| Export | `excel` + `share_plus` | Tulis .xlsx di perangkat lalu bagikan |
| File | `path_provider`, `file_picker` | Backup / restore DB |
| Format tanggal & angka | `intl` (locale `id_ID`) | |
| Tes | `flutter_test`, Drift in-memory DB | Logika saldo dan periode harus tertutup tes |

**Pola:** feature-first, tiga lapis per fitur: `data` (tabel Drift + DAO) → `domain` (aturan bisnis murni Dart) → `presentation` (widget + provider). Logika saldo dan periode ada di `domain`, tidak boleh bocor ke widget.

---

## 3. Yang Diperbaiki dari Versi Web

Temuan dari review kode Laravel; di versi Flutter dijadikan keputusan desain sejak awal:

1. **Saldo tidak disimpan per baris, tapi dihitung** (running total berdasarkan `tanggal, id`). Entri mundur tanggal, edit, atau hapus tidak membuat saldo basi.
2. **Qty disimpan sebagai integer** (satuan terkecil x1000, mis. 12,5 kg = `12500`), bukan float/decimal. Tidak ada galat pembulatan.
3. **Saldo tidak boleh negatif.** `keluar` yang melebihi saldo ditolak (kecuali jenis Adjustment yang ditandai eksplisit).
4. **Tepat satu periode Open** pada satu waktu, ditegakkan di domain dan di DB (partial unique index).
5. **Buka periode baru hanya setelah periode sebelumnya Closed**, dan carry-over diambil dari periode sebelumnya yang sebenarnya, bukan "snapshot dengan id terbesar".
6. **Tutup buku idempoten:** menolak periode yang sudah Closed.
7. **Master barang terpisah** (`items`), bukan data nama/jenis/kategori yang diulang di tiap entri.
8. **Sort hanya dari enum** yang diizinkan (tidak ada nama kolom dari input).
9. **Kode barang di-generate lewat query portabel** (tanpa fungsi khusus MySQL), dan dibungkus transaksi.
10. **Entri bisa diedit/dihapus selama periodenya Open**, dengan catatan audit sederhana.

---

## 4. Model Data (Drift)

### `items`
| Kolom | Tipe | Catatan |
|---|---|---|
| `id` | int PK | |
| `code` | text unique | `RB-001`, `GB-001` |
| `name` | text | Nama bean |
| `variety` | text | Arabica / Robusta / Blend |
| `category` | text | Green Bean / Roasted Bean |
| `unit` | text | kg / pcs |
| `created_at` | datetime | |

### `periods`
| Kolom | Tipe | Catatan |
|---|---|---|
| `id` | int PK | |
| `label` | text unique | `YYYY-MM` |
| `start_date` | date | |
| `closed_date` | date? | |
| `status` | enum `open` / `closed` | Partial unique index: hanya satu `open` |
| `closed_by` | text? | Label bebas ("pemilik") |

### `stock_entries`
| Kolom | Tipe | Catatan |
|---|---|---|
| `id` | int PK | |
| `item_id` | FK items | |
| `period_id` | FK periods | Diturunkan dari tanggal, divalidasi |
| `date` | date | |
| `type` | enum | `opening`, `production_in`, `sales_out`, `adjustment_in`, `adjustment_out` |
| `qty_in` | int | x1000 |
| `qty_out` | int | x1000, salah satu `qty_in`/`qty_out` > 0 |
| `note` | text? | Catatan bebas |
| `created_at`, `updated_at` | datetime | |

Index: `(item_id, period_id, date, id)`.

### `closing_snapshots`
Saldo akhir per barang saat tutup buku, dipakai sebagai audit dan sumber carry-over.
`id`, `period_id`, `item_id`, `closing_qty` (int x1000), `created_at`. Unique `(period_id, item_id)`.

### `entry_audit` (ringan)
`id`, `entry_id`, `action` (`create`/`update`/`delete`), `before_json`, `after_json`, `at`.

---

## 5. Aturan Bisnis (domain layer)

**Saldo**
```
saldo(item, period, sampai entri X) = SUM(qty_in - qty_out)
   untuk entri item+period dengan (date, id) <= (X.date, X.id)
```
- Opening Stock adalah entri `type = opening`, bukan kolom khusus.
- Validasi simpan / edit / hapus: simulasikan ulang urutan entri item+period; tolak jika ada titik saldo < 0.

**Buka periode** (`OpenPeriod`)
1. Tolak jika ada periode `open`.
2. Tolak jika `label` sudah ada atau lebih awal dari periode terakhir.
3. Dalam satu transaksi: buat periode, lalu untuk tiap snapshot periode Closed terakhir dengan saldo > 0, buat entri `opening` bertanggal `start_date`.
4. Periode pertama kali (belum ada riwayat): opsi input Opening Stock manual setelah periode dibuat.

**Tutup buku** (`ClosePeriod`)
1. Tolak jika periode bukan `open`.
2. Dalam satu transaksi: hitung saldo akhir tiap barang, tulis `closing_snapshots`, set status `closed`, `closed_date`.
3. Entri periode Closed bersifat read-only (ditegakkan di repository, bukan hanya UI).

**Kode barang**
`{PREFIX}-{NNN}` → ambil nomor terbesar dari prefix itu, +1, pad 3 digit; jalan dalam transaksi dan dicek unik.

---

## 6. Struktur Folder

```
lib/
├── main.dart
├── app/
│   ├── router.dart
│   ├── theme.dart
│   └── app.dart
├── core/
│   ├── database/            # app_database.dart, tables, migrations
│   ├── formatters/          # qty, tanggal, periode
│   └── utils/
├── features/
│   ├── dashboard/
│   ├── entries/             # form input + daftar mutasi
│   ├── items/               # master barang, generate kode
│   ├── stock_card/          # detail per kode
│   ├── report/              # laporan periode + export
│   ├── period/              # buka / tutup buku
│   └── backup/              # backup, restore
└── shared/widgets/
test/
├── domain/                  # saldo, periode, kode barang
└── data/                    # DAO dengan DB in-memory
```

---

## 7. Layar & Navigasi

Bottom navigation (5 tab), sesuai pola mobile versi web:

| Tab | Layar | Isi |
|---|---|---|
| Beranda | Dashboard | Chip periode aktif, kartu saldo per barang, shortcut "Tambah mutasi" |
| Mutasi | Daftar mutasi | Filter (periode, kode, jenis), sort, pencarian; tap → edit; export |
| Input | Form mutasi | Pilih barang atau buat baru (prefix → Generate), jenis, qty, tanggal; auto-fill dari barang |
| Laporan | Laporan periode | Pilih periode, total masuk/keluar/saldo akhir, export Excel |
| Periode | Panel periode | Status, Tutup Buku (dialog pratinjau saldo), Buka Periode Baru, riwayat |

Layar sekunder: Kartu Stok (`/stock/:kode`), Pengaturan (backup, restore, tentang).

---

## 8. Export, Backup, Restore

- **Excel:** buat workbook di memori, simpan ke direktori temp, `Share.shareXFiles`. Dua jenis: Mutasi (ikut filter aktif) dan Laporan Periode. Nama file `mutasi-stok-YYYY-MM.xlsx`, `laporan-YYYY-MM.xlsx`.
- **Backup:** salin file SQLite (setelah `PRAGMA wal_checkpoint`) ke temp, bagikan sebagai `stockers-backup-YYYYMMDD-HHmm.db`.
- **Restore:** pilih file `.db`, validasi (`PRAGMA integrity_check` dan cek versi skema), konfirmasi menimpa, tutup koneksi, ganti file, buka ulang.
- Karena data hanya ada di HP, tampilkan pengingat backup mingguan dan setiap kali tutup buku.

---

## 9. Tahapan Pengerjaan

### Fase 0 — Fondasi
- [ ] `flutter create`, set `applicationId`, ikon, locale `id_ID`
- [ ] Tambah dependency; lint (`flutter_lints`), struktur folder
- [ ] Tema (warna, tipografi), shell navigasi + bottom nav

### Fase 1 — Database & Domain
- [ ] Tabel Drift + migrasi v1, partial unique index periode `open`
- [ ] Domain: hitung saldo, validasi saldo non-negatif, generator kode
- [ ] Tes domain dan DAO (DB in-memory) — **ini gerbang sebelum UI**

### Fase 2 — Periode
- [ ] Buka periode pertama (+ Opening Stock manual)
- [ ] Tutup buku + snapshot, buka periode berikut (carry-over)
- [ ] Panel Periode + dialog pratinjau

### Fase 3 — Input & Daftar
- [ ] Form mutasi (auto-fill, generate kode, validasi, pesan error jelas)
- [ ] Daftar mutasi: filter, sort (enum), pencarian, paginasi/lazy list
- [ ] Edit / hapus entri periode Open + audit

### Fase 4 — Pantau & Laporan
- [ ] Dashboard kartu saldo (stream reaktif)
- [ ] Kartu Stok per kode
- [ ] Laporan periode + export Excel (mutasi & laporan)

### Fase 5 — Keamanan Data & Polish
- [ ] Backup / restore + pengingat
- [ ] (Opsional) PIN / biometrik kunci app (`local_auth`)
- [ ] Empty state, loading, error handling, aksesibilitas, mode gelap
- [ ] Panduan singkat di app (setara halaman `/panduan` versi web)

### Fase 6 — Rilis
- [ ] Tes manual di perangkat fisik (HP kecil + layar besar)
- [ ] Build `appbundle` / APK release, signing, versi
- [ ] Uji skenario migrasi: install lama → update dengan skema baru

---

## 10. Strategi Tes

| Lapisan | Yang diuji |
|---|---|
| Domain | Saldo urut tanggal, entri mundur tanggal, edit/hapus, saldo negatif ditolak, generator kode, aturan satu periode open |
| Data | Transaksi tutup buku atomik (gagal di tengah = tidak ada snapshot setengah jadi), carry-over benar, unique index |
| Widget | Form validasi, dialog tutup buku, filter daftar |
| Manual | Backup → hapus data → restore; export dibuka di Excel / Sheets |

Skenario wajib (golden): 3 barang, 2 periode, entri mundur tanggal, tutup buku, buka periode, saldo awal cocok dengan saldo akhir sebelumnya.

---

## 11. Risiko & Pertanyaan Terbuka

- **Data hilang bila HP rusak/hilang** (tanpa cloud). Mitigasi: pengingat backup; opsi backup ke Google Drive via share sheet.
- **Migrasi data dari versi web (MySQL):** perlu? Jika ya, buat importer CSV dari export `stock_entries` (fase tambahan).
- **Satuan:** hanya kg/pcs, atau perlu gram? Menentukan faktor skala qty (default x1000).
- **Adjustment negatif:** boleh membuat saldo < 0 (koreksi opname) atau tetap ditolak? Default rencana ini: ditolak.
- **Lebih dari satu perangkat** (mis. HP dan tablet)? Di luar scope; butuh strategi sinkron bila nanti diperlukan.
