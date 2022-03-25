import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:convert';
import 'dart:io';

void main() {
  runApp(const MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _tarefasController = TextEditingController();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List _tarefasLista = [];

  late Map<String, dynamic> _ultimoRemovido;
  late int _posUltimoRemovido;

  @override
  void initState() {
    super.initState();

    _readData().then((value) {
      setState(() {
        _tarefasLista = json.decode(value);
      });
    });
  }

  void _addTarefa() {
    setState(() {
      Map<String, dynamic> novaTarefa = {};
      novaTarefa["title"] = _tarefasController.text;
      _tarefasController.text = "";
      novaTarefa["ok"] = false;
      _tarefasLista.add(novaTarefa);
      _saveData();
    });
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _tarefasLista.sort((a, b) {
        if (a["ok"] && !b["ok"]) {
          return 1;
        } else if (!a["ok"] && b["ok"]) {
          return -1;
        } else {
          return 0;
        }
      });
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Form(
            key: _formKey,
            child: Container(
              padding: const EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _tarefasController,
                      decoration: const InputDecoration(
                          labelText: "Nova Tarefa",
                          labelStyle: TextStyle(color: Colors.blueAccent)),
                      validator: (value){
                        if(value!.isEmpty){
                          return "Insira sua tarefa";
                        }
                      },
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        primary: const Color(0xff448aff)),
                    onPressed: (){
                      if(_formKey.currentState!.validate()){
                        _addTarefa;
                      }
                    },
                    child:
                    const Text("ADD", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
              child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
                padding: const EdgeInsets.only(top: 10.0),
                itemCount: _tarefasLista.length,
                itemBuilder: buildItem),
          )),
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: const Align(
          alignment: Alignment(-0.9, 0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_tarefasLista[index]["title"]),
        value: _tarefasLista[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_tarefasLista[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (bool? value) {
          setState(() {
            _tarefasLista[index]["ok"] = value;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _ultimoRemovido = Map.from(_tarefasLista[index]);
          _posUltimoRemovido = index;
          _tarefasLista.removeAt(index);
          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa \"${_ultimoRemovido["title"]}\" removida"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _tarefasLista.insert(_posUltimoRemovido, _ultimoRemovido);
                  _saveData();
                });
              },
            ),
            duration: const Duration(seconds: 5),
          );
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _getFile() async {
    final diretorio = await getApplicationDocumentsDirectory();
    return File("${diretorio.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_tarefasLista);

    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return "Error";
    }
  }
}
