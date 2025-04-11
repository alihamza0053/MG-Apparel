<?php
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

require 'phpmailer/src/PHPMailer.php';
require 'phpmailer/src/Exception.php';
require 'phpmailer/src/SMTP.php';

// ✅ Set Headers for CORS and UTF-8 Encoding
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

// ✅ Handle Preflight Requests (OPTIONS)
if ($_SERVER["REQUEST_METHOD"] == "OPTIONS") {
    http_response_code(200);
    exit;
}

// ✅ Read input data from Flutter request
$data = json_decode(file_get_contents("php://input"), true);

// ✅ Validate required fields
if (!isset($data["email"], $data["subject"], $data["message"])) {
    echo json_encode(["status" => "error", "message" => "Missing required fields."]);
    exit;
}

$recipient = filter_var($data["email"], FILTER_SANITIZE_EMAIL);
$subject = htmlspecialchars($data["subject"]);
$message = nl2br(htmlspecialchars($data["message"]));

$mail = new PHPMailer(true);

try {
    // ✅ SMTP Configuration
    $mail->isSMTP();
    $mail->Host = 'gms.mgapparel.com';
    $mail->SMTPAuth = true;
    $mail->Username = 'info@gms.mgapparel.com';
    $mail->Password = 'MG@pparel#ali053'; // 🔒 Use actual password
    $mail->SMTPSecure = PHPMailer::ENCRYPTION_SMTPS; 
    $mail->Port = 465;

    // ✅ Email Content
    $mail->setFrom('info@gms.mgapparel.com', 'GMS');
    $mail->addReplyTo('no-reply@mgapparel.com', 'No Reply');
    $mail->addAddress($recipient);
    $mail->Subject = $subject;
    $mail->isHTML(true);
    $mail->Body = $message;

    // ✅ Send Email
    if ($mail->send()) {
        echo json_encode(["status" => "success", "message" => "✅ Email sent successfully!"], JSON_UNESCAPED_UNICODE);
    } else {
        echo json_encode(["status" => "error", "message" => "❌ Failed to send email."]);
    }
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "❌ Mailer Error: {$mail->ErrorInfo}"]);
}
error_reporting(E_ALL);
ini_set('display_errors', 1);
?>
