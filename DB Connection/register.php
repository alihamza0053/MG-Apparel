<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");

include("db_connect.php");
$conn = dbConnection();

$response = ["success" => "false", "message" => "An error occurred"];

try {
    // Check if email and password are provided
    if (isset($_POST["email"]) && isset($_POST["password"])) {
        $email = $_POST["email"];
        $password = $_POST["password"];
    } else {
        $response["message"] = "Missing email or password";
        echo json_encode($response);
        exit();
    }

    // Hash the password
    $hashedPassword = password_hash($password, PASSWORD_DEFAULT);

    // Prepare and execute the SQL query
    $query = "INSERT INTO users (email, password) VALUES (?, ?)";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("ss", $email, $hashedPassword);

    if ($stmt->execute()) {
        $response = [
            "success" => "true",
            "message" => "User registered successfully"
        ];
    } else {
        $response["message"] = "Failed to register user. Error: " . $stmt->error;
    }

    $stmt->close();
    $conn->close();
} catch (Exception $e) {
    $response["message"] = "An error occurred: " . $e->getMessage();
}

// Return JSON response
echo json_encode($response);
?>
