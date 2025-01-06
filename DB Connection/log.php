<?php
header("Access-Control-Allow-Origin: *");  // Allow all origins
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");  // Allow POST, GET, OPTIONS requests
header("Access-Control-Allow-Headers: Content-Type");  // Allow Content-Type header

include("db_connect.php"); // Correct file extension
$conn = dbConnection(); // Database connection

$response = ["success" => "false", "message" => "An error occurred"]; // Default response

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

    // Prepare SQL query
    $query = "SELECT * FROM users WHERE email = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();

    // Check if user exists
    if ($result->num_rows > 0) {
        $user = $result->fetch_assoc();

        // Verify password
        if ($password, $user['password']) {
            $response = [
                "success" => "true",
                "message" => "Login successful",
                "user" => [
                    "id" => $user['id'],
                    "email" => $user['email']
                ]
            ];
        } else {
            $response["message"] = "Invalid password";
            $response["message"] = $user;
        }
    } else {
        $response["message"] = "User not found";
    }

    $stmt->close();
    $conn->close();

} catch (Exception $e) {
    $response["message"] = "An error occurred: " . $e->getMessage();
}

// Return JSON response
echo json_encode($response);

?>
