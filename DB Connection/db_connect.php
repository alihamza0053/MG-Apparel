<?php
function dbConnection(){
$servername = "localhost";
$username = "grouned0grievanceh4"
$password = "MG@pparelH4";
$database = "grouned0grievance";

$conn = new mysqli($servername, $username, $password, $database);
return $conn;
}
?>