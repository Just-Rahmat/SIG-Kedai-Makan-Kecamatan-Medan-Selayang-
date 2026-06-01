<?php
// ============================================================
//  DATABASE CONNECTION  –  PDO PostgreSQL
//  database/db.php
// ============================================================
require_once __DIR__ . '/../config.php';

class Database
{
    private static ?PDO $instance = null;

    /**
     * Singleton: kembalikan koneksi PDO yang sudah ada,
     * atau buat koneksi baru jika belum ada.
     */
    public static function getConnection(): PDO
    {
        if (self::$instance === null) {
            $dsn = sprintf(
                'pgsql:host=%s;port=%s;dbname=%s',
                DB_HOST, DB_PORT, DB_NAME
            );

            $options = [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
            ];

            try {
                self::$instance = new PDO($dsn, DB_USER, DB_PASS, $options);
                self::$instance->exec("SET NAMES '" . DB_CHARSET . "'");
            } catch (PDOException $e) {
                // Tampilkan pesan error yang ramah pengguna
                http_response_code(500);
                die(self::renderDbError($e->getMessage()));
            }
        }

        return self::$instance;
    }

    /**
     * Render halaman error koneksi yang informatif
     */
    private static function renderDbError(string $msg): string
    {
        // Sembunyikan credential sensitif dari pesan error di production
        $safeMsg = preg_replace('/password=[^\s]*/i', 'password=***', $msg);
        return <<<HTML
<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <title>Koneksi Database Gagal</title>
  <style>
    body { font-family: system-ui, sans-serif; background: #f8f6f0; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; }
    .box { background: #fff; border-radius: 14px; padding: 2rem 2.5rem; max-width: 520px; box-shadow: 0 4px 24px rgba(0,0,0,.12); border-top: 4px solid #dc2626; }
    h2  { color: #dc2626; margin-bottom: .5rem; font-size: 1.25rem; }
    p   { color: #555; font-size: 14px; line-height: 1.6; margin-bottom: .75rem; }
    code{ display: block; background: #f3f3f3; border-radius: 7px; padding: .75rem 1rem; font-size: 12px; color: #333; margin: .5rem 0; white-space: pre-wrap; word-break: break-all; }
    ul  { color: #555; font-size: 13px; line-height: 1.8; padding-left: 1.25rem; }
    a   { color: #1c4a2e; font-weight: 600; }
  </style>
</head>
<body>
<div class="box">
  <h2>⚠ Koneksi PostgreSQL Gagal</h2>
  <p>Tidak dapat terhubung ke database. Periksa konfigurasi di <strong>config.php</strong>.</p>
  <code>$safeMsg</code>
  <p><strong>Langkah perbaikan:</strong></p>
  <ul>
    <li>Pastikan PostgreSQL sudah berjalan (cek pgAdmin)</li>
    <li>Periksa <code>DB_HOST</code>, <code>DB_PORT</code>, <code>DB_NAME</code></li>
    <li>Isi <code>DB_PASS</code> dengan password PostgreSQL Anda</li>
    <li>Pastikan database <strong>postgres</strong> (atau nama DB Anda) sudah ada</li>
    <li>Jalankan <a href="database/migration.sql">migration.sql</a> terlebih dahulu</li>
  </ul>
</div>
</body>
</html>
HTML;
    }

    // Tutup konstruktor & clone agar singleton terjaga
    private function __construct() {}
    private function __clone()    {}
}
