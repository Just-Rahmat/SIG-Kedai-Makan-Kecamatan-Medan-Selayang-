<?php
// ============================================================
//  DATA LAYER – PostgreSQL
//  data/kedai.php
//  Semua data diambil dari database PostgreSQL via PDO
//  Database: sig_kedai_makan (Kecamatan Medan Selayang)
// ============================================================

require_once __DIR__ . '/../database/db.php';

// ── Ambil koneksi PDO ────────────────────────────────────────
$pdo = Database::getConnection();

// ── $KATEGORI — diambil dari tabel kategori di database ──────
$stmtKat = $pdo->query(
    "SELECT nama, color, emoji FROM kategori ORDER BY id"
);
$KATEGORI = [];
while ($k = $stmtKat->fetch(PDO::FETCH_ASSOC)) {
    $KATEGORI[$k['nama']] = [
        'color' => $k['color'],
        'emoji' => $k['emoji'],
    ];
}

// ── Foto per kedai (query terpisah agar urutan kolom `urutan` ─
$stmtFoto = $pdo->query(
    "SELECT kedai_id, url
       FROM kedai_foto
      ORDER BY kedai_id, urutan ASC"
);
$fotoMap = [];   // [ kedai_id => [url1, url2, url3] ]
while ($f = $stmtFoto->fetch(PDO::FETCH_ASSOC)) {
    $fotoMap[(int)$f['kedai_id']][] = $f['url'];
}

// ── Query semua kedai ─────────────────────────────────────────
$stmtKedai = $pdo->query(
    "SELECT
        k.id,
        k.nama            AS name,
        kel.nama          AS kel,
        kat.nama          AS cat,
        kat.color         AS cat_color,
        kat.emoji         AS cat_emoji,
        k.lat,
        k.lng,
        k.rating,
        k.reviews,
        k.status,
        k.jam,
        k.harga,
        k.harga_rata      AS \"hargaRata\",
        k.telp
     FROM kedai k
     JOIN kelurahan kel ON kel.id = k.kelurahan_id
     JOIN kategori  kat ON kat.id = k.kategori_id
     ORDER BY k.id"
);

$KEDAI = [];
while ($row = $stmtKedai->fetch(PDO::FETCH_ASSOC)) {

    // ── Type cast agar konsisten dengan JS ──────────────────
    $row['id']        = (int)   $row['id'];
    $row['rating']    = (float) $row['rating'];
    $row['reviews']   = (int)   $row['reviews'];
    $row['hargaRata'] = (int)   $row['hargaRata'];
    $row['lat']       = (float) $row['lat'];
    $row['lng']       = (float) $row['lng'];

    // ── Foto dari $fotoMap (urutan berdasarkan kolom urutan) ─
    $row['foto'] = $fotoMap[$row['id']] ?? [];

    $KEDAI[] = $row;
}

// ── Statistik dari tabel kedai langsung ──────────────────────
$dbStats = $pdo->query("SELECT * FROM v_statistik")->fetch(PDO::FETCH_ASSOC);

// ============================================================
//  HELPER FUNCTIONS
// ============================================================

function fmtRupiah(int $n): string {
    return 'Rp ' . number_format($n, 0, ',', '.');
}

function getKelurahan(array $data): array {
    $kels = array_unique(array_column($data, 'kel'));
    sort($kels);
    return $kels;
}

function getKategori(array $data): array {
    $cats = array_unique(array_column($data, 'cat'));
    sort($cats);
    return $cats;
}

function hitungStatistik(array $data): array {
    global $dbStats;
    // Gunakan hasil query database jika tersedia
    if (!empty($dbStats)) {
        return [
            'total'     => (int)   $dbStats['total_kedai'],
            'buka'      => (int)   $dbStats['total_buka'],
            'avgRating' => (float) $dbStats['avg_rating'],
            'avgHarga'  => (int)   $dbStats['avg_harga'],
        ];
    }
    // Fallback: hitung dari array PHP
    $total     = count($data);
    $buka      = count(array_filter($data, fn($d) => $d['status'] === 'Buka'));
    $avgRating = $total > 0 ? round(array_sum(array_column($data, 'rating'))    / $total, 1) : 0;
    $avgHarga  = $total > 0 ? (int) round(array_sum(array_column($data, 'hargaRata')) / $total) : 0;
    return compact('total', 'buka', 'avgRating', 'avgHarga');
}