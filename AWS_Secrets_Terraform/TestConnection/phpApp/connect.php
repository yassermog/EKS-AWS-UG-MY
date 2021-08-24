<?php

require 'vendor/autoload.php';
require 'getAWSSecretValue.php';
include 'config.php';

	function DBConnect(){
		global $AWS_Secret_ID;
		$jsonCreds=getAWSSecretValue($AWS_Secret_ID);
		$creds=json_decode($jsonCreds,true);
		var_dump($creds);
		$password = $creds['password'];
		$servername = $creds['host'];
		$username = $creds['username'];
		
		// Create connection
		$conn = new mysqli($servername, $username, $password);

		// Check connection
		if ($conn->connect_error) {
			die("Connection failed: " . $conn->connect_error);
		}else{
		//	echo "Connected successfully";
			return $conn;
		}
		
	}
?>