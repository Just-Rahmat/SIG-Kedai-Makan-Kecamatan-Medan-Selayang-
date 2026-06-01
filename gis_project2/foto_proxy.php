<?php
// ============================================================
//  foto_proxy.php  –  Proxy gambar untuk URL Google Maps
//  Letakkan file ini di root folder project (sejajar peta.php)
//  Cara pakai: foto_proxy.php?url=https://lh3.googleusercontent.com/...
// ============================================================

// ── Keamanan: hanya izinkan domain Google yang diketahui ────
$ALLOWED_HOSTS = [
    'lh3.googleusercontent.com',
    'lh4.googleusercontent.com',
    'lh5.googleusercontent.com',
    'lh6.googleusercontent.com',
    'streetviewpixels-pa.googleapis.com',
];

// Ambil URL dari query string
$url = isset($_GET['url']) ? trim($_GET['url']) : '';

// Validasi URL tidak kosong
if (empty($url)) {
    http_response_code(400);
    exit('URL tidak boleh kosong');
}

// Decode jika sudah di-encode
$url = urldecode($url);

// Validasi host — hanya Google yang diizinkan
$parsed = parse_url($url);
$host   = strtolower($parsed['host'] ?? '');

if (!in_array($host, $ALLOWED_HOSTS, true)) {
    http_response_code(403);
    exit('Host tidak diizinkan: ' . htmlspecialchars($host));
}

// Validasi skema harus HTTPS
if (($parsed['scheme'] ?? '') !== 'https') {
    http_response_code(403);
    exit('Hanya HTTPS yang diizinkan');
}

// ── Cache sederhana di server (opsional tapi direkomendasikan)
$cacheDir  = sys_get_temp_dir() . '/foto_proxy_cache/';
$cacheKey  = md5($url);
$cachePath = $cacheDir . $cacheKey;
$cacheTime = 86400; // 24 jam dalam detik

if (!is_dir($cacheDir)) {
    mkdir($cacheDir, 0755, true);
}

// Sajikan dari cache jika masih fresh
if (file_exists($cachePath) && (time() - filemtime($cachePath) < $cacheTime)) {
    $meta     = json_decode(file_get_contents($cachePath . '.meta'), true);
    $mimeType = $meta['mime'] ?? 'image/jpeg';

    header('Content-Type: ' . $mimeType);
    header('Cache-Control: public, max-age=86400');
    header('X-Proxy-Cache: HIT');
    readfile($cachePath);
    exit;
}

// ── Fetch gambar dari Google via cURL ───────────────────────
$ch = curl_init();
curl_setopt_array($ch, [
    CURLOPT_URL            => $url,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_FOLLOWLOCATION => true,
    CURLOPT_MAXREDIRS      => 5,
    CURLOPT_TIMEOUT        => 15,
    CURLOPT_USERAGENT      => 'Mozilla/5.0 (compatible; SIGKedaiProxy/1.0)',
    CURLOPT_SSL_VERIFYPEER => true,
    CURLOPT_HTTPHEADER     => [
        'Accept: image/webp,image/apng,image/*,*/*;q=0.8',
        'Referer: https://www.google.com/',
    ],
]);

$imageData  = curl_exec($ch);
$httpCode   = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$mimeType   = curl_getinfo($ch, CURLINFO_CONTENT_TYPE);
$curlError  = curl_error($ch);
curl_close($ch);

// Tangani error cURL
if ($imageData === false || !empty($curlError)) {
    http_response_code(502);
    exit('Gagal mengambil gambar: ' . htmlspecialchars($curlError));
}

// Tangani HTTP error dari Google
if ($httpCode !== 200) {
    http_response_code($httpCode);
    exit('Google mengembalikan HTTP ' . $httpCode);
}

// Validasi bahwa ini memang gambar
$mime = explode(';', $mimeType)[0]; // hapus "; charset=..." jika ada
if (!str_starts_with($mime, 'image/')) {
    http_response_code(415);
    exit('Respons bukan gambar: ' . htmlspecialchars($mime));
}

// ── Simpan ke cache ─────────────────────────────────────────
file_put_contents($cachePath,          $imageData);
file_put_contents($cachePath . '.meta', json_encode(['mime' => $mime]));

// ── Kirim ke browser ─────────────────────────────────────────
header('Content-Type: ' . $mime);
header('Cache-Control: public, max-age=86400');
header('X-Proxy-Cache: MISS');
echo $imageData;
