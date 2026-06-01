<?php
// ============================================================
//  KONFIGURASI APLIKASI
//  SIG Persebaran Kedai Makan – Kecamatan Medan Selayang
// ============================================================

// ── Identitas Aplikasi ───────────────────────────────────────
define('APP_NAME',    'SIG Persebaran Kedai Makan');
define('APP_WILAYAH', 'Kecamatan Medan Selayang');
define('APP_KOTA',    'Kota Medan · Sumatera Utara');
define('APP_TAHUN',   date('Y'));

// ── Konfigurasi PostgreSQL ───────────────────────────────────
// ⚠ Sesuaikan dengan setting pgAdmin / PostgreSQL Anda
define('DB_HOST',    'localhost');   // host server PostgreSQL
define('DB_PORT',    '5432');        // port default PostgreSQL
define('DB_NAME',    'sig_kedai_makan');    // nama database (ganti jika pakai DB baru)
define('DB_USER',    'postgres');    // username PostgreSQL
define('DB_PASS',    '13BuLaN5');            // ← isi password PostgreSQL Anda di sini
define('DB_CHARSET', 'UTF8');

// ── Peta (Leaflet + OpenStreetMap) ───────────────────────────
define('MAP_LAT',  3.565);
define('MAP_LNG',  98.655);
define('MAP_ZOOM', 14);
define('MAP_TILE_URL',    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png');
define('MAP_ATTRIBUTION', '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors');
