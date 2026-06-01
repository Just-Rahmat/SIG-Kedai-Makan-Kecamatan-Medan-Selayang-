<?php
// ============================================================
//  SIG PERSEBARAN KEDAI MAKAN – KECAMATAN MEDAN SELAYANG
//  peta.php  –  Halaman peta interaktif GIS
// ============================================================

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/data/kedai.php';

// Hitung statistik awal (semua data)
$statistik  = hitungStatistik($KEDAI);
$kelurahan  = getKelurahan($KEDAI);
$kategoris  = getKategori($KEDAI);

// Inject data ke JavaScript via window.APP_DATA (JSON-encode)
$appDataJson = json_encode([
    'DATA'       => array_values($KEDAI),
    'CAT_CFG'    => $KATEGORI,
    'MAP_CONFIG' => [
        'lat'         => MAP_LAT,
        'lng'         => MAP_LNG,
        'zoom'        => MAP_ZOOM,
        'tileUrl'     => MAP_TILE_URL,
        'attribution' => MAP_ATTRIBUTION,
    ],
], JSON_UNESCAPED_UNICODE);

include __DIR__ . '/includes/header.php';
?>

<div class="main">

  <!-- ═══════════════════ SIDEBAR ══════════════════════════ -->
  <aside class="sidebar">
    <div class="sidebar-scroll">

      <!-- Statistik -->
      <div class="sec-lbl">Statistik Wilayah</div>
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-num" id="statTotal"><?= $statistik['total'] ?></div>
          <div class="stat-lbl">Total Kedai</div>
        </div>
        <div class="stat-card">
          <div class="stat-num" id="statFiltered"><?= $statistik['total'] ?></div>
          <div class="stat-lbl">Ditampilkan</div>
        </div>
        <div class="stat-card">
          <div class="stat-num" id="statRating"><?= $statistik['avgRating'] ?></div>
          <div class="stat-lbl">Rata-rata Rating</div>
        </div>
        <div class="stat-card">
          <div class="stat-num sm" id="statHarga"><?= fmtRupiah($statistik['avgHarga']) ?></div>
          <div class="stat-lbl">Rata-rata Harga</div>
        </div>
        <div class="stat-card">
          <div class="stat-num"><?= count($kelurahan) ?></div>
          <div class="stat-lbl">Kelurahan</div>
        </div>
        <div class="stat-card">
          <div class="stat-num" id="statBuka"><?= $statistik['buka'] ?></div>
          <div class="stat-lbl">Sedang Buka</div>
        </div>
      </div>

      <div class="divider"></div>

      <!-- Pencarian -->
      <div class="sec-lbl">Pencarian</div>
      <div class="search-wrap">
        <span class="search-icon">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/>
          </svg>
        </span>
        <input type="text" id="searchInput" placeholder="Cari nama kedai makan...">
      </div>

      <!-- Filter Kategori (multi-select) -->
      <div class="filter-section">
        <div class="filter-label">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <path d="M4 6h16M7 12h10M10 18h4"/>
          </svg>
          Kategori Kedai
          <span class="hint">pilih lebih dari satu ✓</span>
        </div>
        <div class="chips" id="categoryChips">
          <div class="chip active" data-cat="semua">Semua</div>
          <!-- chip kategori diisi oleh app.js via buildFilters() -->
        </div>
      </div>

      <!-- Filter Kelurahan -->
      <div class="filter-section">
        <div class="filter-label">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>
            <polyline points="9 22 9 12 15 12 15 22"/>
          </svg>
          Kelurahan
        </div>
        <select class="filter-select" id="kelurahanSelect">
          <option value="semua">Semua Kelurahan</option>
          <?php foreach ($kelurahan as $kel): ?>
          <option value="<?= htmlspecialchars($kel) ?>"><?= htmlspecialchars($kel) ?></option>
          <?php endforeach; ?>
        </select>
      </div>

      <!-- Toggle Batas Wilayah Kelurahan -->
      <div class="filter-section">
        <div class="filter-label">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <rect x="3" y="3" width="18" height="18" rx="2"/><path d="M3 9h18M3 15h18M9 3v18M15 3v18"/>
          </svg>
          Batas Wilayah
        </div>
        <button id="btnTogglePolygon" onclick="togglePolygons()">
          <span>◻</span> Sembunyikan Batas Kelurahan
        </button>
        <!-- Mini-legend warna kelurahan -->
        <div style="margin-top:8px;display:flex;flex-direction:column;gap:4px">
          <?php
            $kelColors = [
              'PB Selayang I'  => '#3b82f6',
              'PB Selayang II' => '#8b5cf6',
              'Tanjung Sari'   => '#f59e0b',
              'Asam Kumbang'   => '#10b981',
              'Sempakata'      => '#ef4444',
            ];
            foreach ($kelColors as $nama => $warna): ?>
          <div style="display:flex;align-items:center;gap:6px;font-size:11px;color:var(--text2)">
            <div style="width:28px;height:3px;background:<?= $warna ?>;border-radius:2px;border:1px dashed <?= $warna ?>"></div>
            <span><?= $nama ?></span>
          </div>
          <?php endforeach; ?>
        </div>
      </div>

      <!-- Filter Status -->
      <div class="filter-section">
        <div class="filter-label">Status Operasional</div>
        <div class="chips" id="statusChips">
          <div class="chip active" data-status="semua">Semua</div>
          <div class="chip" data-status="Buka">● Buka</div>
          <div class="chip" data-status="Tutup">● Tutup</div>
        </div>
      </div>

      <!-- Filter Rating -->
      <div class="filter-section">
        <div class="filter-label">Rating Minimum</div>
        <div class="rating-row" id="ratingChips">
          <div class="rating-chip active" data-min="0">Semua</div>
          <div class="rating-chip" data-min="3">3+</div>
          <div class="rating-chip" data-min="4">4+</div>
          <div class="rating-chip" data-min="4.5">4.5+</div>
        </div>
      </div>

      <!-- Urutkan -->
      <div class="filter-section">
        <div class="filter-label">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <path d="M3 6h18M7 12h10M11 18h2"/>
          </svg>
          Urutkan
        </div>
        <select class="filter-select" id="sortSelect">
          <option value="default">Urutan Default</option>
          <option value="rating_desc">⭐ Rating Tertinggi</option>
          <option value="rating_asc">⭐ Rating Terendah</option>
          <option value="harga_asc">💰 Harga Terendah</option>
          <option value="harga_desc">💰 Harga Tertinggi</option>
          <option value="ulasan_desc">💬 Ulasan Terbanyak</option>
          <option value="nama_az">🔤 Nama A–Z</option>
          <option value="nama_za">🔤 Nama Z–A</option>
        </select>
      </div>

      <button class="btn-reset" onclick="resetFilters()">↺ Reset Semua Filter</button>
      <div class="divider"></div>

      <!-- Daftar Kedai -->
      <div class="sec-lbl">Daftar Kedai (<span id="listCount"><?= $statistik['total'] ?></span>)</div>
      <div class="kedai-list" id="kedaiList"></div>
      <div class="no-result" id="noResult" style="display:none">Tidak ada kedai ditemukan</div>

    </div>
  </aside><!-- /sidebar -->

  <!-- ═══════════════════ MAP ═══════════════════════════════ -->
  <div class="map-wrap">
    <div id="map"></div>

    <!-- Counter -->
    <div class="counter-bar">
      Menampilkan <strong id="mapCount"><?= $statistik['total'] ?></strong> kedai makan
    </div>

    <!-- Legend -->
    <div class="map-overlay-br">
      <div class="legend-box">
        <div class="legend-title">Kategori</div>
        <?php foreach ($kategoris as $kat):
          $cfg   = $KATEGORI[$kat] ?? ['color' => '#666', 'emoji' => '🍽'];
          $count = count(array_filter($KEDAI, fn($d) => $d['cat'] === $kat));
        ?>
        <div class="legend-row">
          <div class="legend-dot" style="background:<?= htmlspecialchars($cfg['color']) ?>"></div>
          <span><?= $cfg['emoji'] ?> <?= htmlspecialchars($kat) ?></span>
          <span class="legend-count"><?= $count ?></span>
        </div>
        <?php endforeach; ?>
      </div>
    </div>

    <!-- Detail Panel -->
    <div class="detail-panel" id="detailPanel">
      <div class="dp-header">
        <div class="dp-name" id="dpName"></div>
        <div class="dp-close" onclick="closeDetail()">✕</div>
      </div>
      <div class="dp-badge-row" id="dpBadges"></div>
      <div class="dp-grid"     id="dpGrid"></div>
      <div class="dp-coords"   id="dpCoords"></div>
      <button class="btn-foto" id="btnFoto" onclick="openFotoModal()">
        <span>📷</span> Lihat Foto Toko
      </button>
      <button id="btnRute">
        🗺️ Rute ke Sini via Google Maps
      </button>
      <button id="btnLokasiSaya">
        📍 Tandai Posisi Saya di Peta
      </button>
    </div>

  </div><!-- /map-wrap -->

</div><!-- /main -->

<!-- ═══════════════════ PHOTO MODAL ══════════════════════════ -->
<div class="foto-overlay" id="fotoOverlay" onclick="handleOverlayClick(event)">
  <div class="foto-modal" id="fotoModal">

    <!-- Modal header -->
    <div class="foto-modal-header">
      <div>
        <div class="foto-modal-title" id="fotoModalTitle"></div>
        <div class="foto-modal-sub"   id="fotoModalSub"></div>
      </div>
      <button class="foto-modal-close" onclick="closeFotoModal()">✕</button>
    </div>

    <!-- Stage -->
    <div class="foto-stage" id="fotoStage">
      <div class="foto-spinner" id="fotoSpinner">Memuat foto…</div>
      <img class="foto-img loading" id="fotoImg" src="" alt="Foto Toko" onload="onImgLoad()" onerror="onImgError()">
      <button class="foto-arrow prev" id="fotoPrev" onclick="fotoNav(-1)">&#8249;</button>
      <button class="foto-arrow next" id="fotoNext" onclick="fotoNav(1)">&#8250;</button>
      <div class="foto-counter" id="fotoCounter"></div>
    </div>

    <!-- Thumbnails -->
    <div class="foto-thumbs" id="fotoThumbs"></div>
  </div>
</div>

<!-- Inject data PHP → JavaScript -->
<script>
window.APP_DATA = <?= $appDataJson ?>;
</script>

<?php include __DIR__ . '/includes/footer.php'; ?>