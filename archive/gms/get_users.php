<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

header("Content-Type: application/json");
include("db_connect.php");
$conn = dbConnection();

$response = array();

try {
    // Connect to the database
  

    // Check connection
    if ($conn->connect_error) {
        $response['success'] = false;
        $response['message'] = "Database connection failed: " . $conn->connect_error;
        echo json_encode($response);
        exit();
    }

    // Query to get users
    $sql = "SELECT id, email,role FROM users";
    $result = $conn->query($sql);

    if ($result->num_rows > 0) {
        $users = array();

        while ($row = $result->fetch_assoc()) {
            $users[] = $row;
        }

        $response['success'] = true;
        $response['data'] = $users;
    } else {
        $response['success'] = false;
        $response['message'] = "No users found.";
    }

    $conn->close();
} catch (Exception $e) {
    $response['success'] = false;
    $response['message'] = "Error: " . $e->getMessage();
}

echo json_encode($response);
?>
