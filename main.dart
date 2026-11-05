import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// --- CONFIGURAÇÃO DO SERVIDOR ---
const String baseUrl = 'http://10.106.76.13/appmauro';

// --- MODELO DE DADOS ---
class FotoModel {
  final int id;
  final String caminho;
  final String descricao;

  const FotoModel(
      {required this.id, required this.caminho, required this.descricao});

  factory FotoModel.fromJson(Map<String, dynamic> json) {
    return FotoModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] ?? 0,
      caminho: json['caminho'] ?? '',
      descricao: json['descricao'] ?? '',
    );
  }
}

// --- REQUISIÇÕES HTTP ---
Future<void> uploadFotoComDescricao(
    String caminhoFoto, String descricao) async {
  var uri = Uri.parse('$baseUrl/recebe_foto.php');
  var request = http.MultipartRequest('POST', uri);

  // Adiciona a descrição como um campo de texto no envio
  request.fields['descricao'] = descricao;

  // Adiciona o arquivo físico
  request.files.add(await http.MultipartFile.fromPath('foto', caminhoFoto));

  var response = await request.send();
  if (response.statusCode != 200) {
    throw Exception('Falha ao enviar foto para o servidor.');
  }
}

Future<FotoModel?> fetchProximaFoto(int currentId) async {
  final resposta = await http.get(
    Uri.parse('$baseUrl/busca_foto.php?id=$currentId'),
    headers: {'Accept': 'application/json'},
  );

  if (resposta.statusCode == 200) {
    final jsonMap = jsonDecode(resposta.body) as Map<String, dynamic>;
    if (jsonMap.containsKey('erro')) return null;
    return FotoModel.fromJson(jsonMap);
  } else {
    throw Exception('Falha na comunicação.');
  }
}

// --- ESTRUTURA PRINCIPAL ---
void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Galeria PHP',
      home: PaginaPrincipal(),
    );
  }
}

class PaginaPrincipal extends StatelessWidget {
  const PaginaPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fotos com Descrição'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Enviar Foto'),
              Tab(text: 'Ver Fotos'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AbaEnviarFoto(),
            AbaBuscarFoto(),
          ],
        ),
      ),
    );
  }
}

// --- ABA 1: TIRAR FOTO E ENVIAR DESCRIÇÃO ---
class AbaEnviarFoto extends StatefulWidget {
  const AbaEnviarFoto({super.key});
  @override
  State<AbaEnviarFoto> createState() => _AbaEnviarFotoState();
}

class _AbaEnviarFotoState extends State<AbaEnviarFoto> {
  final TextEditingController _controlaDescricao = TextEditingController();
  File? _imagemSelecionada;
  bool _enviando = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _tirarFoto() async {
    final XFile? foto = await _picker.pickImage(source: ImageSource.camera);
    if (foto != null) {
      setState(() => _imagemSelecionada = File(foto.path));
    }
  }

  void _enviarParaServidor() {
    if (_imagemSelecionada != null) {
      setState(() => _enviando = true);

      uploadFotoComDescricao(_imagemSelecionada!.path, _controlaDescricao.text)
          .then((_) {
        setState(() {
          _imagemSelecionada = null;
          _controlaDescricao.clear();
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Salvo com sucesso!')));
      }).catchError((erro) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $erro')));
      }).whenComplete(() => setState(() => _enviando = false));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          TextField(
            controller: _controlaDescricao,
            decoration: const InputDecoration(
                border: OutlineInputBorder(), labelText: 'Descrição da Foto'),
          ),
          const SizedBox(height: 20),
          if (_imagemSelecionada != null)
            Image.file(_imagemSelecionada!, height: 200)
          else
            const Text('Nenhuma foto selecionada.'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _tirarFoto,
            child: const Text('Abrir Câmera'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: (_imagemSelecionada == null || _enviando)
                ? null
                : _enviarParaServidor,
            child: Text(_enviando ? 'Enviando...' : 'Enviar para o Servidor'),
          ),
        ],
      ),
    );
  }
}

// --- ABA 2: VISUALIZAR FOTOS DO SERVIDOR ---
class AbaBuscarFoto extends StatefulWidget {
  const AbaBuscarFoto({super.key});
  @override
  State<AbaBuscarFoto> createState() => _AbaBuscarFotoState();
}

class _AbaBuscarFotoState extends State<AbaBuscarFoto> {
  Future<FotoModel?>? _fotoBuscada;
  int _currentId = 0;
  bool _temMaisFotos = true;

  void _buscarProximaFoto() {
    setState(() {
      _fotoBuscada = fetchProximaFoto(_currentId).then((fotoObj) {
        if (fotoObj == null) {
          _temMaisFotos = false;
          return null;
        }
        _currentId = fotoObj.id;
        return fotoObj;
      });
    });
  }

  void _reiniciarBusca() {
    setState(() {
      _currentId = 0;
      _temMaisFotos = true;
      _fotoBuscada = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                  onPressed: _temMaisFotos ? _buscarProximaFoto : null,
                  child: const Text('Próxima')),
              const SizedBox(width: 10),
              ElevatedButton(
                  onPressed: _reiniciarBusca, child: const Text('Reiniciar')),
            ],
          ),
          const SizedBox(height: 20),
          if (_fotoBuscada != null)
            FutureBuilder<FotoModel?>(
              future: _fotoBuscada,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Text('Carregando...');
                else if (snapshot.hasError)
                  return Text('${snapshot.error}');
                else if (snapshot.data == null)
                  return const Text('Fim da lista');
                else if (snapshot.hasData) {
                  return Column(
                    children: [
                      Text('ID: ${snapshot.data!.id}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      // Carrega a imagem a partir do caminho físico armazenado no servidor
                      Image.network(
                        '$baseUrl/${snapshot.data!.caminho}',
                        height: 300,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 10),
                      Text(snapshot.data!.descricao,
                          style: const TextStyle(fontSize: 18)),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
        ],
      ),
    );
  }
}
