<?php
// CORS headers for cross-origin requests (especially for web apps)
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Database connection parameters
include("db_connect.php");
$conn = dbConnection();

// Check connection
if ($conn->connect_error) {
    die(json_encode(array("success" => false, "message" => "Connection failed: " . $conn->connect_error)));
}

// Check if all required fields are provided
if (isset($_POST['title']) && isset($_POST['description']) && isset($_POST['submittedBy']) && isset($_POST['category'])) {
    // Get input values from POST request
    $title = $conn->real_escape_string($_POST['title']);
    $description = $conn->real_escape_string($_POST['description']);
    $status = 'Pending';
    $submittedBy = $conn->real_escape_string($_POST['submittedBy']);
    $assignedTo = "Not Assigned";
  	$category =$conn->real_escape_string($_POST['category']);

    // File handling
    $fileName = null;
    $filePath = null;
    if (isset($_FILES['file'])) {
        $file = $_FILES['file'];
        $fileName = $file['name'];
        $fileTmpName = $file['tmp_name'];
        $fileSize = $file['size'];
        $fileError = $file['error'];

        // Check if the file has no errors
        if ($fileError === 0) {
            // Check file size (max 10MB)
            if ($fileSize <= 10 * 1024 * 1024) {
                // Get file extension and set the file path
                $fileExtension = strtolower(pathinfo($fileName, PATHINFO_EXTENSION));
                $allowedExtensions = array("jpg", "jpeg", "png", "pdf");
                
                // Check if the file type is allowed
                if (in_array($fileExtension, $allowedExtensions)) {
                    $fileNameNew = uniqid('', true) . '.' . $fileExtension;
                    $filePath = 'uploads/' . $fileNameNew;
                    
                    // Move the uploaded file to the server
                    if (!move_uploaded_file($fileTmpName, $filePath)) {
                        die(json_encode(array("success" => false, "message" => "Failed to upload file")));
                    }
                } else {
                    die(json_encode(array("success" => false, "message" => "Invalid file type. Only JPG, PNG, and PDF are allowed.")));
                }
            } else {
                die(json_encode(array("success" => false, "message" => "File size exceeds the limit of 10MB")));
            }
        } else {
            die(json_encode(array("success" => false, "message" => "Error uploading the file")));
        }
    }

    // Insert grievance details into the database
    $sql = "INSERT INTO grievances (title, description, status, submitted_by, assigned_to, file_path, category)
            VALUES ('$title', '$description', '$status', '$submittedBy', '$assignedTo', '$filePath', '$category')";

    if ($conn->query($sql) === TRUE) {
        echo json_encode(array("success" => true, "message" => "Grievance submitted successfully"));
    } else {
        echo json_encode(array("success" => false, "message" => "Error: " . $conn->error));
    }

    $conn->close();
} else {
    echo json_encode(array("success" => false, "message" => "Missing required fields: title, description, submittedBy"));
}
?>
