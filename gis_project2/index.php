<?php
require_once __DIR__ . '/database/db.php';

$pdo = Database::getConnection();

// ── Statistik real-time dari view v_statistik ────────────────
$dbStats    = $pdo->query("SELECT * FROM v_statistik")->fetch(PDO::FETCH_ASSOC);
$stats = [
    'total_kedai' => (int) $dbStats['total_kedai'],
    'kelurahan'   => (int) $dbStats['total_kelurahan'],
];

// ── Kategori + jumlah kedai real-time ────────────────────────
$stmtCat = $pdo->query(
    "SELECT kat.nama, kat.emoji, COUNT(k.id) AS jumlah
       FROM kategori kat
  LEFT JOIN kedai k ON k.kategori_id = kat.id
   GROUP BY kat.id, kat.nama, kat.emoji
   ORDER BY kat.id"
);
$categories = [];
while ($row = $stmtCat->fetch(PDO::FETCH_ASSOC)) {
    $categories[] = [
        'emoji' => $row['emoji'],
        'name'  => $row['nama'],
        'count' => (int) $row['jumlah'],
    ];
}

$features = [
    [
        'icon'  => '🗺️',
        'title' => 'Peta Interaktif Real-time',
        'desc'  => 'Lihat persebaran kedai secara visual. Klik pin untuk detail lengkap tiap kedai.',
    ],
    [
        'icon'  => '📸',
        'title' => 'Foto & Detail Kedai',
        'desc'  => 'Lihat foto toko, rating, ulasan, kisaran harga, dan kontak tiap kedai langsung dari peta.',
    ],
    [
        'icon'  => '📊',
        'title' => 'Statistik Wilayah',
        'desc'  => 'Pantau total kedai dan data per kelurahan.',
    ],
    [
        'icon'  => '🔍',
        'title' => 'Pencarian & Filter',
        'desc'  => 'Filter berdasarkan kategori, kelurahan, status buka/tutup, dan rating minimum. Urutkan sesuai kebutuhan.',
    ],
];

$nav_links = [
    ['href' => 'index.php',   'label' => 'Beranda'],
    ['href' => '#fitur',      'label' => 'Fitur'],
    ['href' => '#kategori',   'label' => 'Kategori'],
];
?>
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SIG Kedai Makan - Medan Selayang</title>

<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">

<style>
*{
    margin:0;
    padding:0;
    box-sizing:border-box;
    scroll-behavior:smooth;
}

body{
    font-family:'Inter',sans-serif;
    background:#fff;
    color:#111827;
}

:root{
    --green:#2a7a4b;
    --green-light:#e8f5ee;
    --border:#e5e7eb;
    --muted:#6b7280;
    --bg:#f9fafb;
}

/* NAVBAR */
nav{
    height:60px;
    padding:0 32px;
    display:flex;
    justify-content:space-between;
    align-items:center;
    border-bottom:1px solid var(--border);
    position:sticky;
    top:0;
    background:#fff;
    z-index:100;
}

.nav-logo{
    text-decoration:none;
    color:var(--green);
    font-weight:700;
}

.nav-links{
    display:flex;
    list-style:none;
    gap:8px;
}

.nav-links a{
    text-decoration:none;
    color:#374151;
    padding:8px 14px;
    border-radius:8px;
    font-size:14px;
}

.nav-links a:hover{
    background:var(--bg);
}

.nav-cta{
    background:var(--green);
    color:#fff !important;
}

/* HERO */
.hero{
    max-width:900px;
    margin:auto;
    text-align:center;
    padding:80px 20px;
}

.hero-badge{
    display:inline-block;
    padding:6px 14px;
    background:var(--green-light);
    color:var(--green);
    border-radius:30px;
    font-size:12px;
    font-weight:600;
    margin-bottom:20px;
}

.hero h1{
    font-size:52px;
    line-height:1.1;
    margin-bottom:18px;
}

.hero h1 em{
    color:var(--green);
    font-style:normal;
}

.hero p{
    max-width:620px;
    margin:auto;
    color:var(--muted);
    font-size:16px;
    line-height:1.7;
}

.hero-actions{
    margin-top:28px;
    display:flex;
    justify-content:center;
    gap:12px;
    flex-wrap:wrap;
}

.btn-primary,
.btn-outline,
.btn-white{
    text-decoration:none;
    padding:12px 24px;
    border-radius:10px;
    font-weight:600;
    font-size:14px;
}

.btn-primary{
    background:var(--green);
    color:#fff;
}

.btn-outline{
    border:1px solid var(--border);
    color:#111827;
}

.btn-white{
    background:#fff;
    color:var(--green);
}

/* STATS */
.stats{
    background:var(--bg);
    border-top:1px solid var(--border);
    border-bottom:1px solid var(--border);
}

.stats-inner{
    max-width:900px;
    margin:auto;
    display:grid;
    grid-template-columns:repeat(3,1fr);
}

.stat-item{
    padding:28px;
    text-align:center;
    border-right:1px solid var(--border);
    text-decoration:none;
    color:inherit;
    transition:0.2s;
}

.stat-item:hover{
    background:#eef7f1;
}

.stat-item:last-child{
    border-right:none;
}

.stat-num{
    font-size:36px;
    color:var(--green);
    font-weight:800;
}

.stat-label{
    font-size:13px;
    color:var(--muted);
}

/* SECTION */
.section-header{
    text-align:center;
    margin-bottom:40px;
}

.section-tag{
    color:var(--green);
    font-size:12px;
    font-weight:700;
    letter-spacing:1px;
    text-transform:uppercase;
}

.section-title{
    font-size:32px;
    font-weight:700;
    margin:8px 0;
}

.section-sub{
    color:var(--muted);
    font-size:14px;
}

/* FEATURES */
.features{
    max-width:900px;
    margin:auto;
    padding:70px 20px;
}

.features-grid{
    display:grid;
    grid-template-columns:repeat(2,1fr);
    gap:18px;
}

.feature-card{
    border:1px solid var(--border);
    border-radius:14px;
    padding:22px;
}

.feature-icon{
    font-size:28px;
}

.feature-title{
    font-weight:700;
    margin:10px 0;
}

.feature-desc{
    color:var(--muted);
    font-size:14px;
    line-height:1.6;
}

/* CATEGORY */
.categories{
    background:var(--bg);
    padding:70px 20px;
}

.categories-inner{
    max-width:900px;
    margin:auto;
}

.cat-grid{
    display:grid;
    grid-template-columns:repeat(3,1fr);
    gap:16px;
}

.cat-card{
    text-decoration:none;
    background:#fff;
    border:1px solid var(--border);
    border-radius:12px;
    padding:20px;
    text-align:center;
}

.cat-card:hover{
    border-color:var(--green);
}

.cat-name{
    color:#111827;
    font-weight:600;
    margin-top:6px;
}

.cat-count{
    color:var(--muted);
    font-size:13px;
}

.cat-card-all{
    background:var(--green);
}

.cat-card-all .cat-name,
.cat-card-all .cat-count{
    color:#fff;
}

/* CTA */
.cta{
    max-width:900px;
    margin:auto;
    padding:70px 20px;
}

.cta-card{
    background:var(--green);
    border-radius:18px;
    padding:36px;
    display:flex;
    justify-content:space-between;
    align-items:center;
    gap:20px;
    color:#fff;
}

.cta-title{
    font-size:28px;
    font-weight:700;
}

.cta-desc{
    opacity:.85;
    margin-top:8px;
}

/* FOOTER */
footer{
    border-top:1px solid var(--border);
    padding:22px;
    display:flex;
    justify-content:space-between;
    flex-wrap:wrap;
}

.footer-brand{
    color:var(--green);
    font-weight:700;
}

/* RESPONSIVE */
@media(max-width:768px){

.hero h1{
    font-size:38px;
}

.stats-inner,
.features-grid,
.cat-grid{
    grid-template-columns:1fr;
}

.nav-links{
    display:none;
}

.cta-card{
    flex-direction:column;
    text-align:center;
}
}
</style>
</head>
<body>

<!-- NAVBAR -->
<nav>
    <a href="index.php" class="nav-logo">🗺️ SIG Kedai Makan</a>

    <ul class="nav-links">
        <?php foreach($nav_links as $link): ?>
        <li><a href="<?= $link['href']; ?>"><?= $link['label']; ?></a></li>
        <?php endforeach; ?>

        <li><a href="peta.php" class="nav-cta">Jelajahi Peta</a></li>
    </ul>
</nav>

<!-- HERO -->
<section class="hero">
    <div class="hero-badge">📍 Kecamatan Medan Selayang · <?= date('Y'); ?></div>

    <h1>
        Temukan <em>Kedai Makan</em><br>
        Terbaik di Medan
    </h1>

    <p>
        Jelajahi persebaran kedai makan di Kecamatan Medan Selayang
        dengan peta interaktif. Filter kategori, kelurahan, dan rating sesuai selera.
    </p>

    <div class="hero-actions">
        <a href="peta.php" class="btn-primary">🗺 Buka Peta Interaktif</a>
        <a href="#kategori" class="btn-outline">🍽 Lihat Kategori</a>
    </div>
</section>

<!-- STATISTIK JADI KATEGORI -->
<div class="stats">
    <div class="stats-inner">

        <a href="#kategori" class="stat-item">
            <div class="stat-num"><?= $stats['total_kedai']; ?></div>
            <div class="stat-label">Total Kedai</div>
        </a>

        <a href="#kategori" class="stat-item">
            <div class="stat-num"><?= count($categories); ?></div>
            <div class="stat-label">Kategori</div>
        </a>

        <a href="#kategori" class="stat-item">
            <div class="stat-num"><?= $stats['kelurahan']; ?></div>
            <div class="stat-label">Kelurahan</div>
        </a>

    </div>
</div>

<!-- FEATURES -->
<section id="fitur">
<div class="features">

<div class="section-header">
<div class="section-tag">Fitur Unggulan</div>
<div class="section-title">Nikmati Kemudahan Eksplorasi</div>
<div class="section-sub">
Sistem informasi geografis kami dirancang untuk pengalaman terbaik.
</div>
</div>

<div class="features-grid">
<?php foreach($features as $f): ?>
<div class="feature-card">
<div class="feature-icon"><?= $f['icon']; ?></div>
<div class="feature-title"><?= $f['title']; ?></div>
<div class="feature-desc"><?= $f['desc']; ?></div>
</div>
<?php endforeach; ?>
</div>

</div>
</section>

<!-- CATEGORY -->
<div class="categories" id="kategori">
<div class="categories-inner">

<div class="section-header">
<div class="section-tag">Kategori Kedai</div>
<div class="section-title">Jelajahi Berdasarkan Jenis</div>
<div class="section-sub">Klik kategori untuk melihat persebaran di peta.</div>
</div>

<div class="cat-grid">

<?php foreach($categories as $cat): ?>
<a href="peta.php?kategori=<?= urlencode($cat['name']); ?>" class="cat-card">
<div style="font-size:28px"><?= $cat['emoji']; ?></div>
<div class="cat-name"><?= $cat['name']; ?></div>
<div class="cat-count"><?= $cat['count']; ?> kedai</div>
</a>
<?php endforeach; ?>

<a href="peta.php" class="cat-card cat-card-all">
<div style="font-size:28px">🗺️</div>
<div class="cat-name">Lihat Semua</div>
<div class="cat-count"><?= $stats['total_kedai']; ?> kedai</div>
</a>

</div>

</div>
</div>

<!-- CTA -->
<div class="cta">
<div class="cta-card">

<div>
<div class="cta-title">Siap Menemukan Kedai Favorit?</div>
<div class="cta-desc">
Buka peta interaktif dan jelajahi <?= $stats['total_kedai']; ?> kedai makan sekarang.
</div>
</div>

<a href="peta.php" class="btn-white">🗺 Mulai Jelajahi →</a>

</div>
</div>

<!-- FOOTER -->
<footer>
<div class="footer-brand">🗺️ SIG Kedai Makan · Medan Selayang</div>
<div>© <?= date('Y'); ?> Sistem Informasi Geografis</div>
</footer>

</body>
</html>