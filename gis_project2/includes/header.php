<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><?= htmlspecialchars(APP_NAME) ?> – <?= htmlspecialchars(APP_WILAYAH) ?></title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&family=Inter:wght@400;500;600;700;800&family=DM+Mono:wght@400;500&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.css">
<link rel="stylesheet" href="assets/css/style.css">
</head>
<body>

<style>
.header {
  padding: 0 32px;
  height: 60px;
  background: #fff;
  border-bottom: 1px solid #e5e7eb;
  display: flex;
  align-items: center;
  justify-content: space-between;
  position: sticky;
  top: 0;
  z-index: 200;
  box-shadow: none;
}
.header-left { display: flex; align-items: center; }
.header-logo-link {
  text-decoration: none;
  color: #2a7a4b;
  font-weight: 700;
  font-family: 'Inter', sans-serif;
  font-size: 16px;
  display: inline-flex;
  align-items: center;
  gap: 0;
  letter-spacing: normal;
}
.header-nav {
  display: flex;
  align-items: center;
  gap: 6px;
}
.hnav-link {
  text-decoration: none;
  color: #374151;
  padding: 8px 14px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
  font-family: 'Inter', sans-serif;
  transition: background .15s;
}
.hnav-link:hover { background: #f9fafb; }
.hnav-active {
  background: #2a7a4b !important;
  color: #fff !important;
  padding: 8px 14px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  font-family: 'Inter', sans-serif;
}
.hnav-active:hover { background: #145c2f !important; }
.hnav-year {
  padding: 8px 14px;
  font-size: 14px;
  font-weight: 500;
  color: #374151;
  font-family: 'Inter', sans-serif;
}
</style>

<header class="header">
  <div class="header-left">
    <a href="index.php" class="header-logo-link">🗺️ SIG Kedai Makan</a>
  </div>
  <div class="header-nav">
    <a href="index.php" class="hnav-link">← Beranda</a>
    <a href="peta.php"  class="hnav-link hnav-active">🗺 Peta Interaktif</a>
    <span class="hnav-year"><?= APP_TAHUN ?></span>
  </div>
</header>