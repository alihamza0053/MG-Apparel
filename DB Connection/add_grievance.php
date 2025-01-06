<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, X-Requested-With");
include("db_connect.php");
$conn = dbConnection();

$data = json_decode(file_get_contents('php://input'), true);

$response = ["success" => false, "message" => "An error occurred"];

try {
    if (isset($data["title"], $data["description"], $data["submitted_by"])) {
        $title = $data["title"];
        $description = $data["description"];
        $submitted_by = $data["submitted_by"];
        $assigned_to = $data["assigned_to"] ?? null;

        $query = "INSERT INTO grievances (title, description, submitted_by, assigned_to) VALUES (?, ?, ?, ?)";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("ssss", $title, $description, $submitted_by, $assigned_to);

        if ($stmt->execute()) {
            $response["success"] = true;
            $response["message"] = "Grievance added successfully.";
        } else {
            $response["message"] = "Failed to add grievance.";
        }
    } else {
        $response["message"] = "Missing required fields.";
    }
} catch (Exception $e) {
    $response["message"] = "An error occurred: " . $e->getMessage();
}

echo json_encode($response);
?>
