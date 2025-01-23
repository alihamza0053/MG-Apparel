<?php
// Enable error reporting for debugging
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Include database connection
include('db_connect.php'); // Ensure your dbConnection function is in this file

// Set header for CORS (Cross-Origin Resource Sharing)
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// Read POST data (JSON format)
$data = json_decode(file_get_contents("php://input"), true);

// Check if email and password are provided
if (isset($data['email']) && isset($data['password'])) {
    $email = $data['email'];
    $password = $data['password'];

    // Create a database connection
    $conn = dbConnection();

    // Prevent SQL Injection by using prepared statements
    $query = "SELECT * FROM users WHERE email = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();

    // Check if user exists
    if ($result->num_rows > 0) {
        $user = $result->fetch_assoc();

        // Verify password
        if (password_verify($password, $user['password'])) {
            // Successful login
            echo json_encode(["success" => true, "message" => "Login successful"]);
        } else {
            // Incorrect password
            echo json_encode(["success" => false, "message" => "Invalid password"]);
        }
    } else {
        // User not found
        echo json_encode(["success" => false, "message" => "User not found"]);
    }

    // Close the database connection
    $stmt->close();
    $conn->close();
} else {
    // Missing email or password
    echo json_encode(["success" => false, "message" => "Missing email or password"]);
}
?>
