<?php
// Include the database connection file
include("db_connect.php");

// Establish the database connection
$conn = dbConnection();

// Check connection
if (!$conn) {
    die(json_encode(['success' => false, 'error' => 'Database connection failed']));
}

// Set the response type to JSON
header('Content-Type: application/json');

// Read the request method
$method = $_SERVER['REQUEST_METHOD'];

// Fetch grievance details
if ($method === 'POST') {
    // Read POST data
    $grievanceId = isset($_POST['grievanceId']) ? $_POST['grievanceId'] : null;
    $action = isset($_POST['action']) ? $_POST['action'] : null;

    if (!$grievanceId) {
        echo json_encode(['success' => false, 'error' => 'Missing grievance ID']);
        exit;
    }

    if ($action === 'fetch') {
        // Fetch grievance details
        $query = "SELECT * FROM grievances WHERE id = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param('s', $grievanceId);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows > 0) {
            $data = $result->fetch_assoc();
            echo json_encode(['success' => true, 'data' => $data]);
        } else {
            echo json_encode(['success' => false, 'error' => 'Grievance not found']);
        }
        $stmt->close();
    } elseif ($action === 'update_status') {
        // Update grievance status
        $status = isset($_POST['status']) ? $_POST['status'] : null;
        if (!$status) {
            echo json_encode(['success' => false, 'error' => 'Missing status']);
            exit;
        }

        $query = "UPDATE grievances SET status = ?, last_updated = NOW() WHERE id = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param('ss', $status, $grievanceId);
        if ($stmt->execute()) {
            echo json_encode(['success' => true, 'message' => 'Status updated successfully']);
        } else {
            echo json_encode(['success' => false, 'error' => 'Failed to update status']);
        }
        $stmt->close();
    } elseif ($action === 'update_assigned') {
        // Update assigned person
        $assignedTo = isset($_POST['assignedTo']) ? $_POST['assignedTo'] : null;
        if (!$assignedTo) {
            echo json_encode(['success' => false, 'error' => 'Missing assigned person']);
            exit;
        }

        $query = "UPDATE grievances SET assigned_to = ?, last_updated = NOW() WHERE id = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param('ss', $assignedTo, $grievanceId);
        if ($stmt->execute()) {
            echo json_encode(['success' => true, 'message' => 'Assigned person updated successfully']);
        } else {
            echo json_encode(['success' => false, 'error' => 'Failed to update assigned person']);
        }
        $stmt->close();
    } else {
        echo json_encode(['success' => false, 'error' => 'Invalid action']);
    }
} else {
    echo json_encode(['success' => false, 'error' => 'Invalid request method']);
}

// Close the database connection
$conn->close();
?>
