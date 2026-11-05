<?php
header('Content-Type: application/json; charset=utf-8');

$id = $_GET["id"];

$comando = "SELECT * FROM `fotos` WHERE `id` > $id LIMIT 1";

$dsn = 'mysql:dbname=banco;host=127.0.0.1';
$dbh = new PDO($dsn, 'root', '');

$sth = $dbh->prepare($comando);
$sth->execute();
$resultado = $sth->fetch(PDO::FETCH_ASSOC);

if($resultado) {
    echo json_encode($resultado);
} else {
    $erro = ['erro' => "Sem mais fotos"];
    echo json_encode($erro);
}
?>