<?php
// Start session for CSRF token support
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// Generate a CSRF token once per session
if (empty($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}

// Require all DB connection variables — fail loudly if any are missing
// so misconfigured deployments are caught immediately rather than
// silently falling back to hardcoded credentials.
$host = getenv('DB_HOST') ?: (function() { error_log('FATAL: DB_HOST not set'); http_response_code(500); die('Application configuration error.'); })();
$user = getenv('DB_USER') ?: (function() { error_log('FATAL: DB_USER not set'); http_response_code(500); die('Application configuration error.'); })();
$pass = getenv('DB_PASSWORD') ?: (function() { error_log('FATAL: DB_PASSWORD not set'); http_response_code(500); die('Application configuration error.'); })();
$db   = getenv('DB_NAME') ?: (function() { error_log('FATAL: DB_NAME not set'); http_response_code(500); die('Application configuration error.'); })();
$port = intval(getenv('DB_PORT') ?: 3306);

$conn = new mysqli($host, $user, $pass, $db, $port);

if ($conn->connect_error) {
    // Log the real error server-side, show a generic message to the browser
    error_log('Database connection failed: ' . $conn->connect_error);
    http_response_code(500);
    die('Unable to connect to the database. Please try again later.');
}
?>
