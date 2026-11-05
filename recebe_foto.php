<?php
$pasta_destino = "uploads/";
if (!is_dir($pasta_destino)) {
    mkdir($pasta_destino, 0777, true);
}
$descricao = $_POST["descricao"] ?? ''; 

$nome_arquivo = basename($_FILES["foto"]["name"]);
$caminho_temporario = $_FILES["foto"]["tmp_name"];
$caminho_final = $pasta_destino . $nome_arquivo;

if (move_uploaded_file($caminho_temporario, $caminho_final)) {
    $comando = "INSERT INTO `fotos` (`id`, `caminho`, `descricao`) VALUES (NULL, '$caminho_final', '$descricao')";
    
    $dsn = 'mysql:dbname=banco;host=127.0.0.1';
    $dbh = new PDO($dsn, 'root', '');
    $resultado = $dbh->query($comando);

    if($resultado) {
        echo "Foto salva com sucesso!";
    } else {
        echo "Erro ao salvar no banco de dados!";
    }
} else {
    echo "Erro ao receber o arquivo físico!";
}
?>