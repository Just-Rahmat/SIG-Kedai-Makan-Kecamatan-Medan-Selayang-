<?php
// ============================================================
//  cek_foto.php  –  Diagnostik URL foto di tabel kedai_foto
//  Letakkan di root project (sejajar peta.php), lalu buka di browser:
//  http://localhost:3000/cek_foto.php
// ============================================================

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/database/db.php';

$pdo = Database::getConnection();

// ── Ambil semua foto beserta nama kedai ──────────────────────
$rows = $pdo->query("
    SELECT
        f.id,
        f.kedai_id,
        k.nama  AS kedai_nama,
        f.url,
        f.urutan
    FROM kedai_foto f
    JOIN kedai k ON k.id = f.kedai_id
    ORDER BY f.kedai_id, f.urutan ASC
")->fetchAll(PDO::FETCH_ASSOC);

$total = count($rows);

// ── Test satu URL via cURL ───────────────────────────────────
function cekUrl(string $url): array {
    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL            => $url,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_FOLLOWLOCATION => true,
        CURLOPT_MAXREDIRS      => 5,
        CURLOPT_TIMEOUT        => 8,
        CURLOPT_NOBODY         => true,   // HEAD request — lebih cepat, tidak download gambar
        CURLOPT_USERAGENT      => 'Mozilla/5.0 (compatible; SIGKedaiProxy/1.0)',
        CURLOPT_SSL_VERIFYPEER => true,
        CURLOPT_HTTPHEADER     => [
            'Accept: image/webp,image/apng,image/*,*/*;q=0.8',
            'Referer: https://www.google.com/',
        ],
    ]);
    curl_exec($ch);
    $http  = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $err   = curl_error($ch);
    $mime  = curl_getinfo($ch, CURLINFO_CONTENT_TYPE);
    curl_close($ch);

    $ok = ($http === 200 && empty($err));
    return [
        'http'  => $http,
        'ok'    => $ok,
        'error' => $err,
        'mime'  => $mime,
    ];
}

// ── Jalankan pengecekan ──────────────────────────────────────
$results = [];
$jumlahOk   = 0;
$jumlahMati = 0;

foreach ($rows as $r) {
    $cek = cekUrl($r['url']);
    $r['cek_http']  = $cek['http'];
    $cek['ok'] ? $jumlahOk++ : $jumlahMati++;
    $r['status_ok'] = $cek['ok'];
    $r['cek_error'] = $cek['error'];
    $r['cek_mime']  = $cek['mime'];
    $results[] = $r;
}

?><!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<title>Diagnostik Foto – SIG Kedai Makan</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: system-ui, sans-serif; background: #f1f5f9; color: #1e293b; padding: 24px; }
  h1   { font-size: 1.3rem; margin-bottom: 4px; }
  .sub { font-size: 13px; color: #64748b; margin-bottom: 20px; }

  /* Summary cards */
  .cards { display: flex; gap: 14px; margin-bottom: 24px; flex-wrap: wrap; }
  .card  { background: #fff; border-radius: 12px; padding: 16px 22px;
           box-shadow: 0 1px 6px rgba(0,0,0,.08); min-width: 130px; }
  .card .num { font-size: 2rem; font-weight: 700; }
  .card .lbl { font-size: 12px; color: #64748b; margin-top: 2px; }
  .card.ok   .num { color: #16a34a; }
  .card.mati .num { color: #dc2626; }

  /* Table */
  .wrap  { overflow-x: auto; }
  table  { width: 100%; border-collapse: collapse; background: #fff;
           border-radius: 12px; overflow: hidden; box-shadow: 0 1px 6px rgba(0,0,0,.08); }
  th     { background: #f8fafc; font-size: 12px; font-weight: 600; color: #475569;
           padding: 10px 14px; text-align: left; border-bottom: 1px solid #e2e8f0; }
  td     { padding: 9px 14px; font-size: 12px; border-bottom: 1px solid #f1f5f9;
           vertical-align: middle; }
  tr:last-child td { border-bottom: none; }
  tr:hover td { background: #f8fafc; }

  .badge-ok   { background: #dcfce7; color: #15803d; padding: 3px 8px;
                border-radius: 20px; font-weight: 600; font-size: 11px; }
  .badge-mati { background: #fee2e2; color: #dc2626; padding: 3px 8px;
                border-radius: 20px; font-weight: 600; font-size: 11px; }
  .url-cell   { max-width: 360px; overflow: hidden; text-overflow: ellipsis;
                white-space: nowrap; color: #3b82f6; font-family: monospace; font-size: 10.5px; }
  .http-ok    { color: #16a34a; font-weight: 700; }
  .http-err   { color: #dc2626; font-weight: 700; }
  .err-msg    { color: #dc2626; font-size: 10.5px; max-width: 200px;
                overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

  /* Filter tabs */
  .tabs { display: flex; gap: 8px; margin-bottom: 14px; }
  .tab  { padding: 7px 16px; border-radius: 8px; border: 1.5px solid #e2e8f0;
          font-size: 12px; font-weight: 600; cursor: pointer; background: #fff;
          transition: background .15s; }
  .tab.active       { background: #1e293b; color: #fff; border-color: #1e293b; }
  .tab:hover:not(.active) { background: #f1f5f9; }
</style>
</head>
<body>

<h1>🔍 Diagnostik URL Foto Kedai</h1>
<p class="sub">Database: <strong>kedai_foto</strong> · Diperiksa: <strong><?= $total ?> URL</strong></p>

<!-- Summary -->
<div class="cards">
  <div class="card">
    <div class="num"><?= $total ?></div>
    <div class="lbl">Total URL</div>
  </div>
  <div class="card ok">
    <div class="num"><?= $jumlahOk ?></div>
    <div class="lbl">✅ Masih Aktif</div>
  </div>
  <div class="card mati">
    <div class="num"><?= $jumlahMati ?></div>
    <div class="lbl">❌ Tidak Bisa Diakses</div>
  </div>
  <div class="card">
    <div class="num"><?= $total > 0 ? round($jumlahOk / $total * 100) : 0 ?>%</div>
    <div class="lbl">Persentase Aktif</div>
  </div>
</div>

<!-- Filter tabs -->
<div class="tabs">
  <div class="tab active" onclick="filterTabel('semua', this)">Semua (<?= $total ?>)</div>
  <div class="tab"        onclick="filterTabel('ok',    this)">✅ Aktif (<?= $jumlahOk ?>)</div>
  <div class="tab"        onclick="filterTabel('mati',  this)">❌ Mati (<?= $jumlahMati ?>)</div>
</div>

<!-- Tabel hasil -->
<div class="wrap">
<table id="tabelHasil">
  <thead>
    <tr>
      <th>#</th>
      <th>Kedai</th>
      <th>Foto ke-</th>
      <th>Status</th>
      <th>HTTP</th>
      <th>URL (potong)</th>
      <th>Error</th>
    </tr>
  </thead>
  <tbody>
  <?php foreach ($results as $i => $r): ?>
  <tr class="row-<?= $r['status_ok'] ? 'ok' : 'mati' ?>">
    <td><?= $r['id'] ?></td>
    <td><strong><?= htmlspecialchars($r['kedai_nama']) ?></strong>
        <span style="color:#94a3b8"> #<?= $r['kedai_id'] ?></span></td>
    <td style="text-align:center"><?= $r['urutan'] ?></td>
    <td>
      <?php if ($r['status_ok']): ?>
        <span class="badge-ok">✅ Aktif</span>
      <?php else: ?>
        <span class="badge-mati">❌ Mati</span>
      <?php endif; ?>
    </td>
    <td class="<?= $r['cek_http'] === 200 ? 'http-ok' : 'http-err' ?>">
      <?= $r['cek_http'] ?: '–' ?>
    </td>
    <td class="url-cell" title="<?= htmlspecialchars($r['url']) ?>">
      <a href="<?= htmlspecialchars($r['url']) ?>" target="_blank"><?= htmlspecialchars(substr($r['url'], 0, 70)) ?>…</a>
    </td>
    <td class="err-msg" title="<?= htmlspecialchars($r['cek_error']) ?>">
      <?= $r['cek_error'] ? htmlspecialchars($r['cek_error']) : '<span style="color:#94a3b8">–</span>' ?>
    </td>
  </tr>
  <?php endforeach; ?>
  </tbody>
</table>
</div>

<p style="margin-top:16px;font-size:11px;color:#94a3b8">
  Waktu cek: <?= date('d M Y H:i:s') ?> · Script: cek_foto.php
  <?php if ($jumlahMati > 0): ?>
  · <strong style="color:#dc2626">Ada <?= $jumlahMati ?> URL yang tidak aktif — perlu diperbarui di tabel kedai_foto.</strong>
  <?php endif; ?>
</p>

<script>
function filterTabel(mode, el) {
  document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
  el.classList.add('active');
  document.querySelectorAll('#tabelHasil tbody tr').forEach(tr => {
    if (mode === 'semua')       tr.style.display = '';
    else if (mode === 'ok')     tr.style.display = tr.classList.contains('row-ok')   ? '' : 'none';
    else if (mode === 'mati')   tr.style.display = tr.classList.contains('row-mati') ? '' : 'none';
  });
}
</script>
</body>
</html>
