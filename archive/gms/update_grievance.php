<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header('Content-Type: application/json');

// Debugging: Enable error reporting
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Include the database connection file
include("db_connect.php");
$conn = dbConnection();

// Check connection
if (!$conn) {
    echo json_encode(['success' => false, 'error' => 'Database connection failed: ' . mysqli_connect_error()]);
    exit;
}

// Validate POST data
$grievanceId = $_POST['grievanceId'] ?? null;
$status = $_POST['status'] ?? null;
$assignedTo = $_POST['assignedTo'] ?? null;

if (!$grievanceId || !$status || !$assignedTo) {
    echo json_encode(['success' => false, 'error' => 'Missing required parameters']);
    exit;
}

// Prepare query
$query = "UPDATE grievances SET status = ?, assigned_to = ?, updated_at = NOW() WHERE id = ?";
$stmt = $conn->prepare($query);

if (!$stmt) {
    echo json_encode(['success' => false, 'error' => 'Prepare failed: ' . $conn->error]);
    exit;
}

$stmt->bind_param('ssi', $status, $assignedTo, $grievanceId);

if (!$stmt->execute()) {
    echo json_encode(['success' => false, 'error' => 'Execution failed: ' . $stmt->error]);
    exit;
}

echo json_encode(['success' => true, 'message' => 'Grievance updated successfully']);
$stmt->close();
$conn->close();
?>
