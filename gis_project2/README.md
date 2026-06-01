# SIG Persebaran Kedai Makan
## Kecamatan Medan Selayang · Kota Medan · Sumatera Utara

Sistem Informasi Geografis (SIG) berbasis **PHP Native + Leaflet.js + PostgreSQL** untuk memetakan dan menganalisis persebaran kedai makan di Kecamatan Medan Selayang.

---

## Struktur File cek_foto.php            

```
gis_project2/
├── index.php               ← Halaman Beranda (landing page)
├── peta.php                ← Peta Interaktif GIS
├── foto_proxy.php          ← Proxy gambar Google Maps
├── config.php              ← Konfigurasi aplikasi, peta & database
├── README.md               ← Dokumentasi proyek 
├── cek_foto.php            ← Diagnostik URL foto di tabel kedai_foto
│
├── database/
│   ├── db.php              ← Koneksi PDO PostgreSQL (Singleton)
│   ├── INSTALL.md          ← Panduan instalasi & setup database
│   └── sig_kedai_makan.sql ← File migrasi database (struktur + data)
│
├── data/
│   └── kedai.php           ← Query data dari DB + helper functions
│
├── assets/
│   ├── css/
│   │   └── style.css       ← Stylesheet utama aplikasi
│   └── js/
│       └── app.js          ← Logic peta Leaflet, filter, routing, poligon
│
└── includes/
    ├── header.php          ← Template header HTML
    └── footer.php          ← Template footer HTML
```

---

## Fitur Utama

### 🗺️ Peta Interaktif
- Peta berbasis **OpenStreetMap** via Leaflet.js
- **25 marker** kedai makan dengan ikon warna per kategori
- Klik marker → panel detail kedai (rating, harga, jam, kontak, foto)

### 🏘️ Poligon Batas Kelurahan
- **5 poligon wilayah** kelurahan Kecamatan Medan Selayang:
  - PB Selayang I · PB Selayang II · Tanjung Sari · Asam Kumbang · Sempakata
- Hover tooltip nama kelurahan
- Klik poligon → otomatis filter kedai per kelurahan
- Toggle tampil/sembunyikan batas wilayah

### 🔍 Filter & Pencarian
- Pencarian nama kedai (real-time)
- Filter multi-kategori: Cafe, Fast Food, Kuliner Khas Lokal, Restoran, Rumah Makan
- Filter kelurahan, status operasional (Buka/Tutup), rating minimum
- Urutkan: rating, harga, ulasan, nama A–Z

### 📊 Statistik Wilayah
- Total kedai, rata-rata rating, rata-rata harga
- Jumlah kelurahan, jumlah sedang buka

### 📷 Foto Toko
- Galeri foto per kedai via `foto_proxy.php`
- Proxy server-side untuk gambar Google Maps
- Cache otomatis 24 jam di server

### 🧭 Routing & Lokasi
- Tandai posisi pengguna di peta
- Tombol rute ke Google Maps

---

## Cara Menjalankan

```bash
cd gis_project2
php -S localhost:3000
```

Buka browser: **http://localhost:3000**

Atau taruh di folder `htdocs/` (XAMPP) / `www/` (Laragon).

---

## Persyaratan Sistem

| Komponen | Versi Minimum |
|---|---|
| PHP | 7.4+ |
| PostgreSQL | 13+ |
| Extension PHP | `pdo`, `pdo_pgsql`, `curl` |
| Browser | Chrome / Firefox / Edge modern |
| Koneksi Internet | Untuk tile peta OpenStreetMap |

---

## Database

**Nama database:** `sig_kedai_makan`

| Tabel | Isi |
|---|---|
| `kelurahan` | 5 kelurahan Kecamatan Medan Selayang |
| `kategori` | 5 kategori kedai (warna & emoji) |
| `kedai` | 25 data kedai makan |
| `kedai_foto` | 75 URL foto (3 foto per kedai) |
| `v_statistik` | View: total, avg rating, avg harga |

Lihat **INSTALL.md** untuk panduan setup database lengkap.

---

## Konfigurasi

Edit `config.php` sesuaikan dengan environment Anda:

```php
define('DB_HOST', 'localhost');
define('DB_PORT', '5432');
define('DB_NAME', 'sig_kedai_makan');
define('DB_USER', 'postgres');
define('DB_PASS', 'password_anda');  // ← sesuaikan
```

---

## Teknologi

- **Backend:** PHP 8+ Native (tanpa framework)
- **Database:** PostgreSQL 18 + PDO
- **Peta:** Leaflet.js + OpenStreetMap
- **Frontend:** Vanilla JavaScript, CSS3
