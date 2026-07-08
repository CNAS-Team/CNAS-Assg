<?php
include 'db.php';

$id = intval($_GET['id']);

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $name  = $_POST['name'];
    $email = $_POST['email'];
    $stmt = $conn->prepare("UPDATE users SET name=?, email=? WHERE id=?");
    $stmt->bind_param("ssi", $name, $email, $id);
    $stmt->execute();
    $stmt->close();
    header("Location: index.php");
    exit();
}

$stmt_select = $conn->prepare("SELECT * FROM users WHERE id=?");
$stmt_select->bind_param("i", $id);
$stmt_select->execute();
$result = $stmt_select->get_result();
$user = $result->fetch_assoc();
$stmt_select->close();
?>
<!DOCTYPE html>
<html><body>
<h2>Edit Member</h2>
<form method="POST">
    Member Name: <input name="name" value="<?= $user['name'] ?>" required><br><br>
    Email: <input name="email" value="<?= $user['email'] ?>" required><br><br>
    <button type="submit">Update</button>
</form>
<a href="index.php">Back</a>
</body></html>
