<?php include 'db.php'; ?>
<!DOCTYPE html>
<html>
<head><title>CNAS Assignment - Team Members List</title></head>
<body>
<h2>Team Members in Class -T01 Team – 02 </h2>
<a href="create.php">Add New Team Member</a>
<table border="1" cellpadding="8" cellspacing="0">
<tr><th>ID</th><th>Student Name</th><th>Email</th><th>Actions</th></tr>
<?php
$result = $conn->query("SELECT * FROM users");
while ($row = $result->fetch_assoc()) {
    $id    = htmlspecialchars($row['id'],    ENT_QUOTES, 'UTF-8');
    $name  = htmlspecialchars($row['name'],  ENT_QUOTES, 'UTF-8');
    $email = htmlspecialchars($row['email'], ENT_QUOTES, 'UTF-8');
    $csrf  = htmlspecialchars($_SESSION['csrf_token'], ENT_QUOTES, 'UTF-8');
    echo "<tr>
            <td>{$id}</td>
            <td>{$name}</td>
            <td>{$email}</td>
            <td>
                <a href='update.php?id={$id}'>Edit</a> |
                <form method='POST' action='delete.php' style='display:inline'
                      onsubmit=\"return confirm('Delete {$name}?')\">
                    <input type='hidden' name='id' value='{$id}'>
                    <input type='hidden' name='csrf_token' value='{$csrf}'>
                    <button type='submit'>Delete</button>
                </form>
            </td>
          </tr>";
}
$conn->close();
?>
</table>
</body>
</html>
