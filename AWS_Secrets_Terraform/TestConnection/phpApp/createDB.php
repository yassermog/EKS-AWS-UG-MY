<?php

require 'connect.php';
$conn=DBConnect();

$sql = "CREATE DATABASE AWS_USG_MY";

if ($conn->query($sql) === TRUE) {
    echo "Table MyGuests created successfully";
} else {
    echo "Error creating table: " . $conn->error;
}

$conn->close();

?>