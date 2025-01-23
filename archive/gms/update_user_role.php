<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// Include the database connection file
include("db_connect.php");
$conn = dbConnection();

// Check connection
if (!$conn) {
    die(json_encode(['success' => false, 'error' => 'Database connection failed']));
}

// Set the response type to JSON
header('Content-Type: application/json');

// Read POST data
$email = isset($_POST['email']) ? $_POST['email'] : null;
$role = isset($_POST['role']) ? $_POST['role'] : null;

if (!$email || !$role) {
    echo json_encode(['success' => false, 'error' => 'Missing email or role']);
    exit;
}

$query = "UPDATE users SET role = ? WHERE email = ?";
$stmt = $conn->prepare($query);
$stmt->bind_param('ss', $role, $email);

if ($stmt->execute()) {
    echo json_encode(['success' => true, 'message' => 'Role updated successfully']);
} else {
    echo json_encode(['success' => false, 'error' => 'Failed to update role']);
}

$stmt->close();
$conn->close();
?>
