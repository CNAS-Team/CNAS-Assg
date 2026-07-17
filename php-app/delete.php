<?php
include 'db.php';

// Only allow deletion via POST to prevent CSRF via GET (e.g. <img src="delete.php?id=1">)
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    die("Method not allowed.");
}

// Validate CSRF token
if (!isset($_POST['csrf_token']) || $_POST['csrf_token'] !== $_SESSION['csrf_token']) {
    http_response_code(403);
    die("Invalid CSRF token.");
}

$id = intval($_POST['id']);
if ($id <= 0) {
    http_response_code(400);
    die("Invalid ID.");
}

$stmt = $conn->prepare("DELETE FROM users WHERE id=?");
$stmt->bind_param("i", $id);
$stmt->execute();
$stmt->close();

header("Location: index.php");
exit();
?>
