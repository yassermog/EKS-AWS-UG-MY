<?php

require 'vendor/autoload.php';
require 'getAWSSecretValue.php';

$secretName = 'DBSecrets';
$servername = "terraform-20210808071137513700000001.ckpwef0lcs0x.ap-southeast-1.rds.amazonaws.com";
$username = "mydbuser";
$password = getAWSSecretValue($secretName);

// Create connection
$conn = new mysqli($servername, $username, $password);

// Check connection
if ($conn->connect_error) {
	die("Connection failed: " . $conn->connect_error);
}
echo "Connected successfully";

?>