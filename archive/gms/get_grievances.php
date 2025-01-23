<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, X-Requested-With");

include("db_connect.php");
$conn = dbConnection();

// Initialize response array
$response = ["success" => false, "message" => "An error occurred"];

try {
    // Fetch grievances from the database
    $query = "SELECT * FROM grievances ORDER BY created_at DESC";
    $result = $conn->query($query);

    if ($result->num_rows > 0) {
        $grievances = [];
        while ($row = $result->fetch_assoc()) {
            $grievances[] = $row;
        }
        $response["success"] = true;
        $response["data"] = $grievances;
    } else {
        $response["message"] = "No grievances found";
    }
} catch (Exception $e) {
    $response["message"] = "An error occurred: " . $e->getMessage();
}

echo json_encode($response);
?>
