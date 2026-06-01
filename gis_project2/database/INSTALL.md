# Panduan Koneksi PostgreSQL
## SIG Persebaran Kedai Makan – Kecamatan Medan Selayang

---

## LANGKAH 1 – Buat Database (opsional)

Di pgAdmin 4, klik kanan **Databases → Create → Database**:

```
Database name : sig_kedai_makan
Owner         : postgres
Encoding      : UTF8
```

Atau via Query Tool:
```sql
CREATE DATABASE sig_kedai_makan ENCODING 'UTF8' OWNER postgres;
```

---

## LANGKAH 2 – Jalankan proses migrasi database dengan memggunakan file sig_kedai_makan.sql 

1. Buka **pgAdmin 4**
2. Pilih database target (`postgres` atau `sig_kedai_makan`)
3. Klik **Tools → Query Tool**
4. Buka file `database/sig_kedai_makan.sql`
5. Klik tombol **Execute / Run (F5)**

Jika berhasil, output terakhir akan menampilkan:

```
tabel       | jumlah
------------|-------
kelurahan   | 5
kategori    | 5
kedai       | 25
kedai_foto  | 75
```

---

## LANGKAH 3 – Set Password di config.php

Edit file `config.php`, isi `DB_PASS` dengan password PostgreSQL Anda:

```php
define('DB_HOST',    'localhost');
define('DB_PORT',    '5432');
define('DB_NAME',    'postgres');    // atau 'sig_kedai_makan'
define('DB_USER',    'postgres');
define('DB_PASS',    'password_anda_di_sini');  // ← ISI INI
```

---

## LANGKAH 4 – Jalankan Project PHP

```bash
cd gis_project
php -S localhost:8000
```

Buka browser: **http://localhost:8000**

---

## Struktur Tabel Database

```
kelurahan          kategori           sesi
─────────          ────────           ────
id (PK)            id (PK)            id (PK)
nama               nama               nama
                   color              color
                   emoji              bg
                                      teks
                                      icon
                                      label

kedai                          kedai_sesi
─────                          ──────────
id (PK)                        kedai_id (FK → kedai.id)
nama                           sesi_id  (FK → sesi.id)
kelurahan_id (FK → kelurahan)
kategori_id  (FK → kategori)
lat, lng
rating, reviews
status (Buka/Tutup)
jam, harga, harga_rata, telp
created_at, updated_at

VIEWS
──────────────────────────────
v_kedai_lengkap   → JOIN semua tabel + ARRAY_AGG sesi
v_statistik       → total, avg rating, avg harga
```

---

## Verifikasi Koneksi

Buka browser ke: `http://localhost:8000/peta.php`

Jika koneksi berhasil → peta dan data kedai tampil.
Jika gagal → halaman error dengan panduan perbaikan.

---

## Troubleshooting

| Error | Solusi |
|-------|--------|
| `password authentication failed` | Periksa `DB_PASS` di config.php |
| `database does not exist` | Ganti `DB_NAME` atau buat database baru |
| `could not connect to server` | Pastikan PostgreSQL berjalan (cek pgAdmin) |
| `relation does not exist` | Jalankan `migration.sql` terlebih dahulu |
| Extension PDO tidak ada | Aktifkan `extension=pdo_pgsql` di `php.ini` |
