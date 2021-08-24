<?php

require 'connect.php';
$conn=DBConnect();
if ($conn->connect_error) {
	die("Connection failed: " . $conn->connect_error);
}else{
    echo "Connected successfully";
	return $conn;
}
$conn->close();
?>