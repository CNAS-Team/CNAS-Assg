<?php
include 'db.php';

$id = intval($_GET['id']);
$stmt = $conn->prepare("DELETE FROM users WHERE id=?");
$stmt->bind_param("i", $id);
$stmt->execute();
$stmt->close();
header("Location: index.php");
exit();
?>
