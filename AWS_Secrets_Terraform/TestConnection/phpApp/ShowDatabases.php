<?php

require 'connect.php';
$conn=DBConnect();

$sql = "SHOW DATABASES";
$result = $conn->query($sql);

echo "Databases:\n";
echo "=============================\n";
$i=1;

if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        echo ($i++)."- ".$row["Database"]."\n";
    }
} else {
    echo "0 results";
}
$conn->close();

?>