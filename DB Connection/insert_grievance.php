<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");

include("db_connect.php");

$response = ["success" => "false", "message" => "An error occurred"];

try {
    $conn = dbConnection();

    // Check if required fields are set
    if (!isset($_POST["email"]) || !isset($_POST["password"])) {
        $response["message"] = "Missing email or password";
        echo json_encode($response);
        exit();
    }

    $email = $_POST["email"];
    $password = $_POST["password"];

    // Use prepared statements
    $stmt = $conn->prepare("INSERT INTO users (email, password) VALUES (?, ?)");
    $stmt->bind_param("ss", $email, $password);

    if ($stmt->execute()) {
        $response["success"] = "true";
        $response["message"] = "Record inserted successfully";
    } else {
        $response["message"] = "Failed to insert record";
    }

    $stmt->close();
    $conn->close();
} catch (Exception $e) {
    $response["message"] = $e->getMessage();
}

echo json_encode($response);
?>
