<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
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

// Read the request method
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'POST') {
    // Read POST data
    $grievanceId = isset($_POST['id']) ? $_POST['id'] : null;

    if (!$grievanceId) {
        echo json_encode(['success' => false, 'error' => 'Missing grievance ID']);
        exit;
    }

    // Fetch grievance details
    $query = "SELECT * FROM grievances WHERE id = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param('i', $grievanceId);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $data = $result->fetch_assoc();

        // Append the full file URL if `file_path` exists
        if (!empty($data['file_path'])) {
            $baseUrl = "https://gms.alihamza.me/gms"; // Base URL of your project
            $data['file_url'] = $baseUrl . $data['file_path'];
        } else {
            $data['file_url'] = null; // No file attached
        }

        echo json_encode(['success' => true, 'data' => $data]);
    } else {
        echo json_encode(['success' => false, 'error' => 'Grievance not found']);
    }
    $stmt->close();
} else {
    echo json_encode(['success' => false, 'error' => 'Invalid request method']);
}

$conn->close();
?>
