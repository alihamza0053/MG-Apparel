<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, X-Requested-With");
include("db_connect.php");
$conn = dbConnection();

// Receive the raw POST data
$data = json_decode(file_get_contents('php://input'), true);

// Initialize response array
$response = ["success" => "false", "message" => "An error occurred"];

try {
    // Check if both email and password are set
    if (isset($data["email"]) && isset($data["password"]) && isset($data["role"])) {
        $email = $data["email"];
        $password = $data["password"];
      	$role = $data["role"];

        // Ensure email and password are not empty
        if (empty($email) || empty($password)) {
            $response["message"] = "Email or password cannot be empty.";
            echo json_encode($response);
            exit();
        }

        // Secure password hashing
        $hashed_password = password_hash($password, PASSWORD_DEFAULT);

        // Check if email already exists
        $checkEmailQuery = "SELECT * FROM users WHERE email = ?";
        $stmt = $conn->prepare($checkEmailQuery);
        $stmt->bind_param("s", $email);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows > 0) {
            $response["message"] = "Email already exists.";
        } else {
            // Insert the new user
            $insertQuery = "INSERT INTO users (email, password,role) VALUES (?, ?, ?)";
            $stmt = $conn->prepare($insertQuery);
            $stmt->bind_param("sss", $email, $hashed_password, $role);

            if ($stmt->execute()) {
                $response["success"] = "true";
                $response["message"] = "Registration successful.";
            } else {
                $response["message"] = "Failed to register user.";
            }
        }

        $stmt->close();
    } else {
        $response["message"] = "Missing email or password";
    }
} catch (Exception $e) {
    $response["message"] = "An error occurred: " . $e->getMessage();
}

echo json_encode($response);
?>
