/* ============================================================
   SIG Persebaran Kedai Makan – Kecamatan Medan Selayang
   app.js  –  data di-inject dari PHP via window.APP_DATA
   ============================================================ */

const { DATA, CAT_CFG, MAP_CONFIG } = window.APP_DATA;

/* ── State ─────────────────────────────────────────────── */
let filters    = { search:'', cats:new Set(), kel:'semua', status:'semua', minRating:0, sort:'default' };
let selectedId = null;
let markers    = {};
let map;

/* ── Photo modal state ─────────────────────────────────── */
let fotoState  = { photos:[], idx:0, kedai:null };

/* ── Routing state ─────────────────────────────────────── */
let userLocation = null;   // { lat, lng } posisi pengguna
let userMarker   = null;   // Leaflet marker posisi pengguna
let routeLine    = null;   // Leaflet polyline rute aktif

/* ── Polygon state ─────────────────────────────────────── */
let polygonGroup = null;   // L.layerGroup semua poligon kelurahan
let showPolygons = true;   // status toggle poligon

/* ============================================================
   FOTO — Proxy lokal untuk URL Google Maps/Lh3
   ============================================================ */

/**
 * Base URL proxy — sesuaikan jika foto_proxy.php tidak di root.
 * Contoh jika ada di subfolder: '/sig/foto_proxy.php'
 */
const PROXY_URL = '/foto_proxy.php';

// Label foto fallback (untuk sub-judul modal)
const FOTO_LABELS = ['Tampak Depan', 'Suasana Dalam', 'Menu Unggulan', 'Tampak Malam'];

/**
 * Ubah URL Google Photos menjadi URL proxy lokal.
 * Jika size diberikan, ganti parameter ukuran di URL Google.
 */
function proxyUrl(url, size = null) {
    let finalUrl = url;
    if (size) {
        // Ganti parameter ukuran di akhir URL Google
        // contoh: =s1360-w1360-h1020-rw  →  =s280-w280-h207-rw
        finalUrl = url.replace(/=s\d+(-w\d+)?(-h\d+)?(-rw)?$/, `=s${size}-w${size}-h${Math.round(size * 0.74)}-rw`);
    }
    return PROXY_URL + '?url=' + encodeURIComponent(finalUrl);
}

/**
 * Ambil foto dari data kedai (d.foto = array URL dari DB).
 * Semua URL dilewatkan melalui foto_proxy.php agar tidak diblokir CORS.
 */
function getPhotos(kedai) {
    const urls = (kedai.foto && kedai.foto.length > 0) ? kedai.foto : [];
    return urls.map((url, i) => ({
        url  : proxyUrl(url),        // full size via proxy
        thumb: proxyUrl(url, 280),   // thumbnail 280px via proxy
        label: FOTO_LABELS[i] ?? `Foto ${i + 1}`,
    }));
}

/* ============================================================
   PHOTO MODAL
   ============================================================ */

function openFotoModal() {
    const d = DATA.find(x => x.id === selectedId);
    if (!d) return;

    const photos = getPhotos(d);
    if (photos.length === 0) return;   // tidak ada foto, tidak buka modal

    fotoState.kedai  = d;
    fotoState.photos = photos;
    fotoState.idx    = 0;

    // Isi header modal
    const cfg = CAT_CFG[d.cat] || { emoji: '🍽' };
    document.getElementById('fotoModalTitle').textContent = cfg.emoji + ' ' + d.name;
    document.getElementById('fotoModalSub').textContent   = d.cat + ' · ' + d.kel;

    // Buat thumbnails
    buildThumbs();

    // Tampilkan foto pertama
    loadFoto(0);

    // Tampilkan overlay
    document.getElementById('fotoOverlay').classList.add('open');
    document.body.style.overflow = 'hidden';
}

function closeFotoModal() {
    document.getElementById('fotoOverlay').classList.remove('open');
    document.body.style.overflow = '';
}

// Klik di luar modal menutupnya
function handleOverlayClick(e) {
    if (e.target === document.getElementById('fotoOverlay')) closeFotoModal();
}

// Navigasi panah
function fotoNav(dir) {
    const n = fotoState.photos.length;
    fotoState.idx = (fotoState.idx + dir + n) % n;
    loadFoto(fotoState.idx);
}

// Load foto ke stage
function loadFoto(idx) {
    fotoState.idx = idx;
    const photo = fotoState.photos[idx];
    const n     = fotoState.photos.length;

    // Counter
    document.getElementById('fotoCounter').textContent = `${idx + 1} / ${n}`;

    // Arrow state
    document.getElementById('fotoPrev').disabled = false;
    document.getElementById('fotoNext').disabled = false;

    // Spinner + loading state
    const img     = document.getElementById('fotoImg');
    const spinner = document.getElementById('fotoSpinner');
    spinner.style.display = 'flex';
    spinner.textContent   = 'Memuat foto…';
    img.classList.add('loading');
    img.src = photo.url;

    // Update sub-judul dengan label foto
    document.getElementById('fotoModalSub').textContent =
        (fotoState.kedai.cat + ' · ' + fotoState.kedai.kel + '  |  ' + photo.label);

    // Sync thumbnail active state
    document.querySelectorAll('.foto-thumb').forEach((th, i) => {
        th.classList.toggle('active', i === idx);
        if (i === idx) th.scrollIntoView({ behavior: 'smooth', inline: 'center', block: 'nearest' });
    });
}

// Callback saat gambar berhasil dimuat
function onImgLoad() {
    document.getElementById('fotoSpinner').style.display = 'none';
    document.getElementById('fotoImg').classList.remove('loading');
}

// Callback saat gambar gagal dimuat
function onImgError() {
    const spinner = document.getElementById('fotoSpinner');
    spinner.style.display = 'flex';
    spinner.textContent   = '⚠ Foto tidak tersedia';
    document.getElementById('fotoImg').classList.add('loading');
}

// Buat strip thumbnail
function buildThumbs() {
    const container = document.getElementById('fotoThumbs');
    container.innerHTML = fotoState.photos.map((p, i) =>
        `<div class="foto-thumb${i === 0 ? ' active' : ''}" onclick="loadFoto(${i})" title="${p.label}">
            <img src="${p.thumb}" alt="${p.label}" loading="lazy">
         </div>`
    ).join('');
}

// Keyboard navigation
document.addEventListener('keydown', e => {
    if (!document.getElementById('fotoOverlay').classList.contains('open')) return;
    if (e.key === 'ArrowLeft')  fotoNav(-1);
    if (e.key === 'ArrowRight') fotoNav(1);
    if (e.key === 'Escape')     closeFotoModal();
});

/* ============================================================
   ROUTING — Posisi Pengguna & Rute ke Kedai
   ============================================================ */

/**
 * Ambil posisi pengguna via browser Geolocation API.
 * Setelah berhasil, simpan ke userLocation dan pasang marker di peta.
 * Callback opsional dipanggil dengan { lat, lng } jika berhasil.
 */
function getAndSetUserLocation(callback) {
    if (!navigator.geolocation) {
        showRouteToast('⚠️ Browser Anda tidak mendukung Geolocation.', 'error');
        return;
    }
    showRouteToast('📡 Mendeteksi lokasi Anda…', 'info');
    navigator.geolocation.getCurrentPosition(
        pos => {
            userLocation = { lat: pos.coords.latitude, lng: pos.coords.longitude };
            placeUserMarker(userLocation);
            hideRouteToast();
            if (callback) callback(userLocation);
        },
        err => {
            const msg = {
                1: '🚫 Izin lokasi ditolak. Aktifkan izin lokasi di browser.',
                2: '📡 Posisi tidak dapat ditentukan.',
                3: '⏱ Waktu habis saat mengambil lokasi.',
            }[err.code] || '❌ Gagal mengambil lokasi.';
            showRouteToast(msg, 'error');
        },
        { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
    );
}

/** Pasang / update marker posisi pengguna di peta */
function placeUserMarker(loc) {
    if (userMarker) map.removeLayer(userMarker);
    userMarker = L.marker([loc.lat, loc.lng], {
        icon: L.divIcon({
            className: '',
            html: `<div style="width:38px;height:38px;border-radius:50%;
                        background:#2563eb;border:3px solid #fff;
                        display:flex;align-items:center;justify-content:center;
                        font-size:16px;box-shadow:0 3px 10px rgba(37,99,235,.5);
                        animation:pulse-blue 1.8s infinite">📍</div>`,
            iconSize: [38, 38], iconAnchor: [19, 19]
        }),
        zIndexOffset: 2000
    }).addTo(map);
    userMarker.bindTooltip('<b>Posisi Anda</b>', { permanent: false, direction: 'top', offset: [0, -10] });
}

/**
 * Buka Google Maps dengan rute dari posisi pengguna ke kedai yang dipilih.
 * Jika posisi pengguna belum diambil, ambil dulu lalu buka.
 */
function bukaRuteGoogleMaps(kedaiLat, kedaiLng, kedaiNama) {
    const buka = (loc) => {
        const url = `https://www.google.com/maps/dir/${loc.lat},${loc.lng}/${kedaiLat},${kedaiLng}`;
        window.open(url, '_blank');
    };

    if (userLocation) {
        buka(userLocation);
    } else {
        getAndSetUserLocation(loc => buka(loc));
    }
}

/**
 * Gambar garis rute lurus (straight line) di peta dari posisi pengguna ke kedai.
 * Dipakai sebagai pratinjau di dalam peta; rute sebenarnya di Google Maps.
 */
function gambarGarisPratinjau(kedaiLat, kedaiLng) {
    if (routeLine) map.removeLayer(routeLine);
    if (!userLocation) return;
    routeLine = L.polyline(
        [[userLocation.lat, userLocation.lng], [kedaiLat, kedaiLng]],
        { color: '#2563eb', weight: 3, dashArray: '8, 8', opacity: 0.7 }
    ).addTo(map);
    map.fitBounds(routeLine.getBounds(), { padding: [60, 60] });
}

/** Hapus garis pratinjau dari peta */
function hapusGarisPratinjau() {
    if (routeLine) { map.removeLayer(routeLine); routeLine = null; }
}

/* ── Toast notifikasi ringan untuk status routing ─────── */
function showRouteToast(msg, type = 'info') {
    let toast = document.getElementById('routeToast');
    if (!toast) {
        toast = document.createElement('div');
        toast.id = 'routeToast';
        toast.style.cssText = `
            position:fixed;bottom:24px;left:50%;transform:translateX(-50%);
            background:#1e293b;color:#fff;padding:10px 18px;border-radius:10px;
            font-size:13px;font-weight:500;z-index:9999;box-shadow:0 4px 16px rgba(0,0,0,.3);
            transition:opacity .3s;pointer-events:none;white-space:nowrap`;
        document.body.appendChild(toast);
    }
    toast.textContent = msg;
    toast.style.opacity = '1';
    toast.style.background = type === 'error' ? '#dc2626' : '#1e293b';
    if (type !== 'info') setTimeout(() => hideRouteToast(), 4000);
}
function hideRouteToast() {
    const t = document.getElementById('routeToast');
    if (t) t.style.opacity = '0';
}

/* ── CSS animasi pulse untuk marker posisi pengguna ───── */
(function injectPulseCSS() {
    const s = document.createElement('style');
    s.textContent = `
        @keyframes pulse-blue {
            0%   { box-shadow: 0 0 0 0 rgba(37,99,235,.5); }
            70%  { box-shadow: 0 0 0 12px rgba(37,99,235,0); }
            100% { box-shadow: 0 0 0 0 rgba(37,99,235,0); }
        }
        #btnRute {
            display:flex;align-items:center;justify-content:center;gap:7px;
            width:100%;padding:11px 0;border:none;border-radius:10px;
            background:linear-gradient(135deg,#2563eb,#1d4ed8);color:#fff;
            font-size:13px;font-weight:600;cursor:pointer;margin-top:8px;
            transition:opacity .2s,transform .1s;
        }
        #btnRute:hover  { opacity:.9; }
        #btnRute:active { transform:scale(.97); }
        #btnLokasiSaya {
            display:flex;align-items:center;justify-content:center;gap:6px;
            width:100%;padding:9px 0;border:1.5px solid #2563eb;border-radius:10px;
            background:transparent;color:#2563eb;
            font-size:12px;font-weight:600;cursor:pointer;margin-top:6px;
            transition:background .2s,color .2s;
        }
        #btnLokasiSaya:hover { background:#2563eb; color:#fff; }

        /* ── Poligon kelurahan ───────────────────────────────── */
        .kel-tooltip-wrap { background:transparent!important; border:none!important;
                            box-shadow:none!important; padding:0!important; }
        .kel-tooltip      { background:rgba(15,23,42,.82); color:#fff; font-size:12px;
                            font-weight:600; padding:5px 10px; border-radius:8px;
                            white-space:nowrap; pointer-events:none; }
        #btnTogglePolygon {
            display:flex; align-items:center; justify-content:center; gap:6px;
            width:100%; padding:9px 12px; border:1.5px solid #3b82f6; border-radius:10px;
            background:#eff6ff; color:#1d4ed8; font-size:12px; font-weight:600;
            cursor:pointer; margin-top:4px; transition:background .2s,color .2s,border-color .2s;
        }
        #btnTogglePolygon:hover { background:#dbeafe; }
        #btnTogglePolygon.polygon-off {
            background:#f9fafb; color:#6b7280; border-color:#d1d5db;
        }
    `;
    document.head.appendChild(s);
})();

/* ============================================================
   POLIGON KELURAHAN
   ⚠ Koordinat di bawah adalah PERKIRAAN.
     Sesuaikan dengan batas administratif resmi jika diperlukan.
   ============================================================ */

const KELURAHAN_STYLE = {
    'PB Selayang I' : { color: '#3b82f6', fill: '#3b82f6' },  // biru
    'PB Selayang II': { color: '#8b5cf6', fill: '#8b5cf6' },  // ungu
    'Tanjung Sari'  : { color: '#f59e0b', fill: '#f59e0b' },  // amber
    'Asam Kumbang'  : { color: '#10b981', fill: '#10b981' },  // hijau
    'Sempakata'     : { color: '#ef4444', fill: '#ef4444' },  // merah
};

// GeoJSON — 5 poligon kelurahan Kecamatan Medan Selayang
// Ubah koordinat sesuai batas wilayah resmi jika ada datanya
const KELURAHAN_GEOJSON = {
    type: 'FeatureCollection',
    features: [
        {
            type: 'Feature',
            properties: { nama: 'PB Selayang I' },
            geometry: {
                type: 'Polygon',
                coordinates: [[[98.610,3.570],[98.672,3.570],
                               [98.672,3.602],[98.610,3.602],[98.610,3.570]]]
            }
        },
        {
            type: 'Feature',
            properties: { nama: 'PB Selayang II' },
            geometry: {
                type: 'Polygon',
                coordinates: [[[98.638,3.548],[98.672,3.548],
                               [98.672,3.570],[98.638,3.570],[98.638,3.548]]]
            }
        },
        {
            type: 'Feature',
            properties: { nama: 'Tanjung Sari' },
            geometry: {
                type: 'Polygon',
                coordinates: [[[98.610,3.548],[98.638,3.548],
                               [98.638,3.570],[98.610,3.570],[98.610,3.548]]]
            }
        },
        {
            type: 'Feature',
            properties: { nama: 'Asam Kumbang' },
            geometry: {
                type: 'Polygon',
                coordinates: [[[98.610,3.523],[98.645,3.523],
                               [98.645,3.548],[98.610,3.548],[98.610,3.523]]]
            }
        },
        {
            type: 'Feature',
            properties: { nama: 'Sempakata' },
            geometry: {
                type: 'Polygon',
                coordinates: [[[98.645,3.523],[98.672,3.523],
                               [98.672,3.548],[98.645,3.548],[98.645,3.523]]]
            }
        },
    ]
};

/** Inisialisasi layer poligon kelurahan dan tambahkan ke peta */
function initPolygons() {
    polygonGroup = L.layerGroup().addTo(map);

    L.geoJSON(KELURAHAN_GEOJSON, {
        style: feature => {
            const s = KELURAHAN_STYLE[feature.properties.nama]
                   || { color: '#666', fill: '#666' };
            return {
                color      : s.color,
                fillColor  : s.fill,
                fillOpacity: 0.10,
                weight     : 2,
                opacity    : 0.75,
                dashArray  : '6, 5',
            };
        },
        onEachFeature: (feature, layer) => {
            const nama = feature.properties.nama;
            const s    = KELURAHAN_STYLE[nama] || { color: '#666' };

            // Tooltip nama kelurahan
            layer.bindTooltip(
                `<div class="kel-tooltip"><span style="color:${s.color}">■</span> ${nama}</div>`,
                { permanent: false, direction: 'center', className: 'kel-tooltip-wrap' }
            );

            // Klik poligon → otomatis filter kelurahan di sidebar
            layer.on('click', () => {
                const sel = document.getElementById('kelurahanSelect');
                if (sel) {
                    sel.value   = nama;
                    filters.kel = nama;
                    applyFilters();
                }
            });

            // Hover highlight
            layer.on('mouseover', function () {
                this.setStyle({ fillOpacity: 0.22, weight: 2.5 });
            });
            layer.on('mouseout', function () {
                this.setStyle({ fillOpacity: 0.10, weight: 2 });
            });
        }
    }).addTo(polygonGroup);
}

/** Toggle tampil/sembunyikan semua poligon kelurahan */
function togglePolygons() {
    showPolygons = !showPolygons;
    if (showPolygons) map.addLayer(polygonGroup);
    else              map.removeLayer(polygonGroup);

    const btn = document.getElementById('btnTogglePolygon');
    if (btn) {
        btn.classList.toggle('polygon-off', !showPolygons);
        btn.innerHTML = showPolygons
            ? '<span>◻</span> Sembunyikan Batas Kelurahan'
            : '<span>◼</span> Tampilkan Batas Kelurahan';
    }
}

/* ============================================================
   MAP & MARKERS
   ============================================================ */

function fmtRp(n) {
    if (!n) return '–';
    return 'Rp ' + Math.round(n / 1000).toLocaleString('id-ID') + '.000';
}

function initMap() {
    map = L.map('map', { center:[MAP_CONFIG.lat, MAP_CONFIG.lng], zoom:MAP_CONFIG.zoom });
    L.tileLayer(MAP_CONFIG.tileUrl, { attribution:MAP_CONFIG.attribution, maxZoom:19 }).addTo(map);
    initPolygons();   // ← tambah poligon kelurahan
}

function markerIcon(cat, selected) {
    const c  = CAT_CFG[cat] || { color:'#666', emoji:'🍽' };
    const sz = selected ? 38 : 30;
    const b  = selected ? '3px solid #fff' : '2px solid rgba(0,0,0,.2)';
    return L.divIcon({
        className: '',
        html: `<div style="width:${sz}px;height:${sz}px;border-radius:50%;background:${c.color};border:${b};
                display:flex;align-items:center;justify-content:center;
                font-size:${selected ? 16 : 13}px;box-shadow:0 3px 8px rgba(0,0,0,.3)">${c.emoji}</div>`,
        iconSize:[sz,sz], iconAnchor:[sz/2,sz/2], popupAnchor:[0,-sz/2]
    });
}

/* ── Sorting ────────────────────────────────────────────── */
function sorted(arr) {
    const copy = [...arr];
    switch (filters.sort) {
        case 'rating_desc':  copy.sort((a,b) => b.rating    - a.rating);    break;
        case 'rating_asc':   copy.sort((a,b) => a.rating    - b.rating);    break;
        case 'harga_asc':    copy.sort((a,b) => a.hargaRata - b.hargaRata); break;
        case 'harga_desc':   copy.sort((a,b) => b.hargaRata - a.hargaRata); break;
        case 'ulasan_desc':  copy.sort((a,b) => b.reviews   - a.reviews);   break;
        case 'nama_az':      copy.sort((a,b) => a.name.localeCompare(b.name)); break;
        case 'nama_za':      copy.sort((a,b) => b.name.localeCompare(a.name)); break;
    }
    return copy;
}

/* ── Filter ─────────────────────────────────────────────── */
function getFiltered() {
    return sorted(DATA.filter(d => {
        if (filters.search && !d.name.toLowerCase().includes(filters.search.toLowerCase())) return false;
        if (filters.cats.size > 0 && !filters.cats.has(d.cat)) return false;
        if (filters.kel    !== 'semua' && d.kel    !== filters.kel)    return false;
        if (filters.status !== 'semua' && d.status !== filters.status) return false;
        if (d.rating < filters.minRating) return false;
        return true;
    }));
}

/* ── Render markers ─────────────────────────────────────── */
function renderMarkers() {
    Object.values(markers).forEach(m => map.removeLayer(m));
    markers = {};
    const f = getFiltered();
    f.forEach(d => {
        const sel = d.id === selectedId;
        const m = L.marker([d.lat, d.lng], { icon:markerIcon(d.cat, sel), zIndexOffset:sel?1000:0 })
            .addTo(map).on('click', () => selectKedai(d.id));
        m.bindTooltip(`<b>${d.name}</b><br>${d.cat} · ⭐ ${d.rating}<br>🕐 ${d.jam}`,
            { direction:'top', offset:[0,-8] });
        markers[d.id] = m;
    });
    document.getElementById('mapCount').textContent     = f.length;
    document.getElementById('statFiltered').textContent = f.length;
}

/* ── Render list ────────────────────────────────────────── */
function renderList() {
    const f    = getFiltered();
    const list = document.getElementById('kedaiList');
    document.getElementById('listCount').textContent = f.length;
    if (!f.length) {
        list.innerHTML = '';
        document.getElementById('noResult').style.display = 'block';
        return;
    }
    document.getElementById('noResult').style.display = 'none';
    list.innerHTML = f.map(d => {
        const c           = CAT_CFG[d.cat] || { color:'#666', emoji:'🍽' };
        const statusColor = d.status === 'Buka' ? '#16a34a' : '#dc2626';
        return `
        <div class="kedai-item${d.id === selectedId ? ' selected' : ''}" onclick="selectKedai(${d.id})">
            <div style="display:flex;align-items:flex-start;justify-content:space-between;gap:6px">
                <div style="min-width:0">
                    <div class="ki-name">${c.emoji} ${d.name}</div>
                    <div class="ki-row">
                        <span class="ki-cat" style="background:${c.color}18;color:${c.color}">${d.cat}</span>
                        <span style="color:${statusColor};font-size:10px;font-weight:600">● ${d.status}</span>
                    </div>
                    <div class="ki-foto-btn" onclick="event.stopPropagation();selectKedai(${d.id});openFotoModal()">
                        📷 Lihat Foto
                    </div>
                </div>
                <div style="text-align:right;flex-shrink:0">
                    <div style="font-size:12px;font-weight:700;color:#d97706">⭐ ${d.rating}</div>
                    <div style="font-size:10px;color:var(--text3)">${d.reviews} ulasan</div>
                    <div style="font-size:10px;color:var(--primary);font-weight:600;margin-top:2px">${fmtRp(d.hargaRata)}</div>
                </div>
            </div>
            <div class="ki-meta">📍 ${d.kel} · 🕐 ${d.jam}</div>
        </div>`;
    }).join('');
}

/* ── Render stats ───────────────────────────────────────── */
function renderStats() {
    const f    = getFiltered();
    const avgR = f.length ? (f.reduce((s,d) => s + d.rating,    0) / f.length).toFixed(1) : '–';
    const avgH = f.length ? Math.round(f.reduce((s,d) => s + d.hargaRata, 0) / f.length) : 0;
    const buka = f.filter(d => d.status === 'Buka').length;
    document.getElementById('statRating').textContent = avgR;
    document.getElementById('statHarga').textContent  = avgH ? fmtRp(avgH) : '–';
    document.getElementById('statBuka').textContent   = buka;
}

/* ── Select kedai ───────────────────────────────────────── */
function selectKedai(id) {
    selectedId = id;
    const d = DATA.find(x => x.id === id);
    if (!d) return;
    map.panTo([d.lat, d.lng], { animate:true });
    Object.entries(markers).forEach(([mid, m]) => {
        m.setIcon(markerIcon(DATA.find(x => x.id == mid).cat, parseInt(mid) === id));
        m.setZIndexOffset(parseInt(mid) === id ? 1000 : 0);
    });
    showDetail(d);
    renderList();
}

/* ── Show detail panel ──────────────────────────────────── */
function showDetail(d) {
    const c = CAT_CFG[d.cat] || { color:'#666', emoji:'🍽' };
    document.getElementById('dpName').textContent = c.emoji + ' ' + d.name;
    document.getElementById('dpBadges').innerHTML = `
        <span class="dp-badge" style="background:${c.color}18;color:${c.color}">${d.cat}</span>
        <span class="dp-badge kel">📍 ${d.kel}</span>
        <span class="dp-badge ${d.status === 'Buka' ? 'buka' : 'tutup'}">● ${d.status}</span>`;
    document.getElementById('dpGrid').innerHTML = `
        <div class="dp-info">
            <div class="dp-ilbl">Rating</div>
            <div class="dp-ival">⭐ ${d.rating} <span style="font-size:10px;color:var(--text3)">(${d.reviews})</span></div>
        </div>
        <div class="dp-info">
            <div class="dp-ilbl">Harga Rata-rata</div>
            <div class="dp-ival" style="color:var(--primary)">${fmtRp(d.hargaRata)}</div>
        </div>
        <div class="dp-info">
            <div class="dp-ilbl">Kontak</div>
            <div class="dp-ival" style="font-size:11px">📞 ${d.telp || '–'}</div>
        </div>
        <div class="dp-info wide">
            <div class="dp-ilbl">Kisaran Harga</div>
            <div class="dp-ival">💰 ${d.harga}</div>
        </div>
        <div class="dp-info wide">
            <div class="dp-ilbl">Jam Buka</div>
            <div class="dp-ival">🕐 ${d.jam}</div>
        </div>`;
    document.getElementById('dpCoords').textContent = `📌 ${d.lat.toFixed(4)}° N, ${d.lng.toFixed(4)}° E`;

    // Preview foto kecil (thumbnail 3 foto pertama dari database)
    const photos = getPhotos(d);
    const previewHtml = photos.length > 0 ? `
        <div style="display:flex;gap:5px;margin-top:8px;cursor:pointer" onclick="openFotoModal()">
            ${photos.slice(0,3).map((p,i) =>
                `<div style="flex:1;height:52px;border-radius:7px;overflow:hidden;border:1.5px solid var(--border)">
                    <img src="${p.thumb}" alt="Foto ${i+1}" style="width:100%;height:100%;object-fit:cover;display:block" loading="lazy">
                 </div>`
            ).join('')}
            ${photos.length > 3 ? `
            <div style="width:36px;height:52px;border-radius:7px;background:var(--bg);border:1.5px solid var(--border);
                        display:flex;align-items:center;justify-content:center;flex-direction:column;flex-shrink:0">
                <span style="font-size:14px">📷</span>
                <span style="font-size:8.5px;color:var(--text3);margin-top:1px">+${photos.length - 3}</span>
            </div>` : ''}
        </div>` : `<div style="margin-top:8px;font-size:11px;color:var(--text3)">📷 Belum ada foto tersedia</div>`;

    document.getElementById('dpCoords').innerHTML =
        `<div style="font-family:'DM Mono',monospace;font-size:10px;color:var(--text3);margin-bottom:4px">📌 ${d.lat.toFixed(4)}° N, ${d.lng.toFixed(4)}° E</div>`
        + previewHtml;

    // ── Simpan koordinat kedai di tombol rute ───────────────
    const btnRute = document.getElementById('btnRute');
    if (btnRute) {
        btnRute.onclick = () => {
            gambarGarisPratinjau(d.lat, d.lng);
            bukaRuteGoogleMaps(d.lat, d.lng, d.name);
        };
    }
    const btnLokasiSaya = document.getElementById('btnLokasiSaya');
    if (btnLokasiSaya) {
        btnLokasiSaya.onclick = () => getAndSetUserLocation(loc => {
            map.panTo([loc.lat, loc.lng], { animate: true });
        });
    }

    document.getElementById('detailPanel').classList.add('show');
}

/* ── Close detail ───────────────────────────────────────── */
function closeDetail() {
    document.getElementById('detailPanel').classList.remove('show');
    selectedId = null;
    hapusGarisPratinjau();
    Object.entries(markers).forEach(([mid, m]) => {
        m.setIcon(markerIcon(DATA.find(x => x.id == mid).cat, false));
        m.setZIndexOffset(0);
    });
    renderList();
}

/* ── Build filter controls ──────────────────────────────── */
function buildFilters() {
    // Category chips
    const cats = [...new Set(DATA.map(d => d.cat))].sort();
    const cc   = document.getElementById('categoryChips');
    cats.forEach(cat => {
        const cfg = CAT_CFG[cat] || { color:'#666', emoji:'🍽' };
        const ch  = document.createElement('div');
        ch.className = 'chip'; ch.dataset.cat = cat;
        ch.textContent = cfg.emoji + ' ' + cat;
        ch.onclick = () => {
            if (filters.cats.has(cat)) { filters.cats.delete(cat); ch.classList.remove('active'); }
            else { filters.cats.add(cat); ch.classList.add('active'); document.querySelector('[data-cat="semua"]').classList.remove('active'); }
            if (filters.cats.size === 0) document.querySelector('[data-cat="semua"]').classList.add('active');
            applyFilters();
        };
        cc.appendChild(ch);
    });
    document.querySelector('[data-cat="semua"]').onclick = () => {
        filters.cats.clear();
        document.querySelectorAll('#categoryChips .chip').forEach(c => c.classList.remove('active'));
        document.querySelector('[data-cat="semua"]').classList.add('active');
        applyFilters();
    };

    document.getElementById('kelurahanSelect').onchange = e => { filters.kel = e.target.value; applyFilters(); };

    document.querySelectorAll('#statusChips .chip').forEach(c => {
        c.onclick = () => {
            document.querySelectorAll('#statusChips .chip').forEach(x => x.classList.remove('active'));
            c.classList.add('active'); filters.status = c.dataset.status; applyFilters();
        };
    });

    document.querySelectorAll('#ratingChips .rating-chip').forEach(c => {
        c.onclick = () => {
            document.querySelectorAll('#ratingChips .rating-chip').forEach(x => x.classList.remove('active'));
            c.classList.add('active'); filters.minRating = parseFloat(c.dataset.min); applyFilters();
        };
    });

    document.getElementById('sortSelect').onchange = e => { filters.sort = e.target.value; applyFilters(); };
    document.getElementById('searchInput').oninput  = e => { filters.search = e.target.value; applyFilters(); };
}

/* ── Reset ──────────────────────────────────────────────── */
function resetFilters() {
    filters = { search:'', cats:new Set(), kel:'semua', status:'semua', minRating:0, sort:'default' };
    document.getElementById('searchInput').value     = '';
    document.getElementById('kelurahanSelect').value = 'semua';
    document.getElementById('sortSelect').value      = 'default';
    document.querySelectorAll('#categoryChips .chip').forEach(c => c.classList.remove('active'));
    document.querySelector('[data-cat="semua"]').classList.add('active');
    document.querySelectorAll('#statusChips .chip').forEach(c => c.classList.remove('active'));
    document.querySelector('#statusChips [data-status="semua"]').classList.add('active');
    document.querySelectorAll('#ratingChips .rating-chip').forEach(c => c.classList.remove('active'));
    document.querySelector('#ratingChips [data-min="0"]').classList.add('active');
    closeDetail();
    applyFilters();
}

/* ── Apply ──────────────────────────────────────────────── */
function applyFilters() { renderMarkers(); renderList(); renderStats(); }

/* ── Boot ───────────────────────────────────────────────── */
document.addEventListener('DOMContentLoaded', () => {
    initMap();
    buildFilters();
    applyFilters();
});