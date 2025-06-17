import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sscaleg/Modelo/check_box_modelo.dart';
import 'package:sscaleg/Uteis/paleta_cores.dart';
import 'package:sscaleg/Widgets/tela_carregamento.dart';
import 'package:sscaleg/uteis/constantes.dart';
import 'package:sscaleg/uteis/estilo.dart';
import 'package:sscaleg/uteis/metodos_auxiliares.dart';
import 'package:sscaleg/uteis/passar_pegar_dados.dart';
import 'package:sscaleg/uteis/textos.dart';
import 'package:sscaleg/widgets/barra_navegacao_widget.dart';

class TelaRemoverCampos extends StatefulWidget {
  const TelaRemoverCampos({
    super.key,
    required this.idDocumento,
    required this.nomeEscala,
    required this.tipoTelaAnterior,
  });

  final String idDocumento;
  final String nomeEscala;
  final String tipoTelaAnterior;

  @override
  State<TelaRemoverCampos> createState() => _TelaRemoverCamposState();
}

class _TelaRemoverCamposState extends State<TelaRemoverCampos> {
  List<Map> escalaQuantidadeItensCadastrados = [];
  int index = 0;
  Estilo estilo = Estilo();
  List<String> listaNomesSelecionados = [];
  bool exibirWidgetTelaCarregamento = true;
  String nomeCampoFormatado = "";
  final validacaoFormulario = GlobalKey<FormState>();
  Map itensRecebidosCabecalhoLinha = {};
  String idItemAtualizar = "";
  List<CheckBoxModelo> listaNomesCadastrados = [];
  int quantidadeNomes = 2;
  TextEditingController nomeAdicionarCampo = TextEditingController(text: "");

  @override
  void initState() {
    super.initState();
    realizarBuscaDadosFireBase(widget.idDocumento, "");
    itensRecebidosCabecalhoLinha = PassarPegarDados.recuperarItens();
    idItemAtualizar = PassarPegarDados.recuperarIdAtualizarSelecionado();
  }

  @override
  void dispose() {
    super.dispose();
    PassarPegarDados.passarItens({});
    PassarPegarDados.passarIdAtualizarSelecionado("");
    PassarPegarDados.passarDataComComplemento("");
  }

  realizarBuscaDadosFireBase(String idDocumento, String tipoBusca) async {
    try {
      var db = FirebaseFirestore.instance;
      //instanciano variavel
      db
          .collection(Constantes.fireBaseColecaoEscalas)
          .doc(idDocumento)
          .collection(Constantes.fireBaseDadosCadastrados)
          .get()
          .then(
            (querySnapshot) async {
              //Veficando se nao e vazio
              if (querySnapshot.docs.isNotEmpty) {
                carregarDados(querySnapshot, tipoBusca);
                validarTipoBusca(querySnapshot, tipoBusca);
              } else {
                setState(() {
                  if (tipoBusca.contains(Constantes.tipoBuscaAdicionarCampo)) {
                    exibirWidgetTelaCarregamento = false;
                  }
                  chamarExibirMensagemErro(Textos.erroBaseDadosVazia);
                });
              }
            },
            onError: (e) {
              setState(() {
                exibirWidgetTelaCarregamento = false;
              });
              chamarExibirMensagemErro(
                "Erro ao buscar escala : ${e.toString()}",
              );
            },
          );
    } catch (e) {
      setState(() {
        exibirWidgetTelaCarregamento = false;
      });
      chamarExibirMensagemErro("Erro ao buscar escala : ${e.toString()}");
    }
  }

  carregarDados(var querySnapshot, String tipoBusca) {
    // for para percorrer todos os dados que a variavel recebeu
    for (var documentoFirebase in querySnapshot.docs) {
      if (!tipoBusca.contains(Constantes.tipoBuscaAdicionarCampo)) {
        Map idDocumentoData = {};
        idDocumentoData[Constantes.idDocumento] = documentoFirebase.id;
        escalaQuantidadeItensCadastrados.addAll([
          idDocumentoData,
          documentoFirebase.data(),
        ]);
      }
    }
  }

  validarTipoBusca(var querySnapshot, String tipoBusca) {
    List<String> listaCabecalho = [];
    // caso a busca contenha o seguinte parametro entrar no if
    // metodo para poder verificar se a busca e a primeira busca ao entrar na tela
    if (tipoBusca.contains(Constantes.tipoBuscaAdicionarCampo)) {
      setState(() {
        // pegando as keys uma unica vez para adicionar no map
        listaCabecalho = querySnapshot.docs.first.data().keys.toList();
        for (var element in listaCabecalho) {
          if (!itensRecebidosCabecalhoLinha.keys.contains(element)) {
            itensRecebidosCabecalhoLinha[element] = "";
          }
        }
        //adicionando no cabecalho colunas de editar e excluir
        itensRecebidosCabecalhoLinha[Constantes.editar] = "";
        itensRecebidosCabecalhoLinha[Constantes.excluir] = "";
      });
      if (widget.tipoTelaAnterior == Constantes.tipoTelaAnteriorCadastroItem) {
        validarRedirecionamentoTela();
      }
    } else {
      setState(() {
        querySnapshot.docs.first.data().keys.toList().forEach((element) {
          if (!(element.toString().contains(Constantes.dataCulto) ||
              element.toString().contains(Constantes.horarioTrabalho))) {
            listaNomesCadastrados.add(CheckBoxModelo(texto: element));
          }
        });
        exibirWidgetTelaCarregamento = false;
      });
    }
  }

  chamarAtualizarCampoPercorrerLista() {
    int tamanhoEscala = 0;
    setState(() {
      if (idItemAtualizar.isEmpty) {
        itensRecebidosCabecalhoLinha.clear();
      }
      exibirWidgetTelaCarregamento = true;
    });
    String idDocumentoItem = "";
    //percorendo a lista contendo todos os itens cadastrados
    // no banco de dados da tabela selecionada
    for (var element in escalaQuantidadeItensCadastrados) {
      //verificando para pegar o id do documento
      if (element.keys.contains(Constantes.idDocumento)) {
        idDocumentoItem = element.values
            .toString()
            .replaceAll("(", "")
            .replaceAll(")", "");
      }
      //caso a key nao contenha id documento pegar os dados para atulizar
      if (!element.keys.contains(Constantes.idDocumento)) {
        tamanhoEscala++;
        atualizarRemocaoCampos(
          element.entries.toList(),
          widget.idDocumento,
          idDocumentoItem,
          tamanhoEscala,
        );
      }
    }
  }

  atualizarRemocaoCampos(
    List<MapEntry> escala,
    String idDocumentoFirebase,
    String idItem,
    int tamanhoEscala,
  ) async {
    setState(() {
      index = 0;
    });
    try {
      var db = FirebaseFirestore.instance;
      db
          .collection(Constantes.fireBaseColecaoEscalas)
          .doc(idDocumentoFirebase)
          .collection(Constantes.fireBaseDadosCadastrados)
          .doc(idItem)
          // passando o metodo que cria o map contendo os valores formatados
          .set(criarMapComTodosOsDados(escala))
          .then(
            (value) {
              //definindo que a cada iteracao o index ira aumentar para poder realizar
              // as acoes abaixo somente quando lista tiver sido toda percorrida
              index++;
              //caso o index seja igual ao tamanho
              // da escala realizar acoes
              if (index == tamanhoEscala) {
                index = 0;
                realizarBuscaDadosFireBase(
                  widget.idDocumento,
                  Constantes.tipoBuscaAdicionarCampo,
                );
                chamarExibirMensagemSucesso();
              }
            },
            onError: (e) {
              chamarExibirMensagemErro(
                "Erro ao remover campos : ${e.toString()}",
              );
            },
          );
    } catch (e) {
      setState(() {
        exibirWidgetTelaCarregamento = false;
      });
      chamarExibirMensagemErro(
        "Erro ao remover campos campo : ${e.toString()}",
      );
    }
  }

  criarMapComTodosOsDados(List<MapEntry> escala) {
    Map<String, dynamic> itemFinal = {};
    //percorrendo a escala para pegar cada item da escala
    // e colocar num Map para ser retornado
    for (var element in escala) {
      //veficando se na lista de nomes seleciodos
      // NAO contem o valor do elemento KEY
      // caso tiver Nao Entrar no IF
      if (!listaNomesSelecionados.contains(element.key)) {
        itemFinal[element.key] = element.value;
      }
    }
    return itemFinal;
  }

  chamarRemoverCampo() {
    if (listaNomesSelecionados.isNotEmpty) {
      alertaRemoverCampos(context);
    } else {
      chamarExibirMensagemErro(Textos.erroListaVazia);
    }
  }

  redirecionarTelaCadastroItem() {
    PassarPegarDados.passarItens(itensRecebidosCabecalhoLinha);
    var dados = {};
    dados[Constantes.rotaArgumentoNomeEscala] = widget.nomeEscala;
    dados[Constantes.rotaArgumentoIDEscalaSelecionada] = widget.idDocumento;
    Navigator.pushReplacementNamed(
      context,
      Constantes.rotaTelaCadastroItem,
      arguments: dados,
    );
  }

  redirecionarTelaAtualizarItem() {
    PassarPegarDados.passarItens(itensRecebidosCabecalhoLinha);
    PassarPegarDados.passarIdAtualizarSelecionado(idItemAtualizar);
    var dados = {};
    dados[Constantes.rotaArgumentoNomeEscala] = widget.nomeEscala;
    dados[Constantes.rotaArgumentoIDEscalaSelecionada] = widget.idDocumento;
    Navigator.pushReplacementNamed(
      context,
      Constantes.rotaTelaAtualizarItem,
      arguments: dados,
    );
  }

  validarRedirecionamentoTela() {
    if (idItemAtualizar.isEmpty) {
      redirecionarTelaCadastroItem();
    } else {
      //percorendo a lista de nomes selecionados para remover do map
      for (var item in listaNomesSelecionados) {
        itensRecebidosCabecalhoLinha.removeWhere((key, value) {
          //caso a key contenha o valor remover do map
          return key.toString().contains(item);
        });
      }
      redirecionarTelaAtualizarItem();
    }
  }

  chamarExibirMensagemSucesso() {
    MetodosAuxiliares.exibirMensagens(
      Constantes.tipoNotificacaoSucesso,
      Textos.notificacaoSucesso,
      context,
    );
  }

  chamarExibirMensagemErro(String erro) {
    MetodosAuxiliares.exibirMensagens(
      Constantes.tipoNotificacaoErro,
      erro,
      context,
    );
  }

  Future<void> alertaRemoverCampos(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            Textos.telaRemoverCamposTitulo,
            style: const TextStyle(color: Colors.black),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  Textos.telaRemoverCamposDescricaoAlerta,
                  style: const TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Não', style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Sim', style: TextStyle(color: Colors.black)),
              onPressed: () {
                chamarAtualizarCampoPercorrerLista();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget checkBoxPersonalizado(CheckBoxModelo checkBoxModel) =>
      CheckboxListTile(
        activeColor: PaletaCores.corAzulEscuro,
        checkColor: PaletaCores.corRosaClaro,
        title: Text(
          checkBoxModel.texto.replaceAll("_", " "),
          style: const TextStyle(fontSize: 20),
        ),
        value: checkBoxModel.checked,
        side: const BorderSide(width: 2, color: PaletaCores.corAzulEscuro),
        onChanged: (value) {
          setState(() {
            // verificando se o balor
            checkBoxModel.checked = value!;
            verificarItensSelecionados();
          });
        },
      );

  verificarItensSelecionados() {
    //verificando cada elemento da lista de nomes cadastrados
    for (var element in listaNomesCadastrados) {
      //verificando se o usuario selecionou um item
      if (element.checked == true) {
        // verificando se o item Nao foi adicionado anteriormente na lista
        if (!(listaNomesSelecionados.contains(element.texto))) {
          //add item
          listaNomesSelecionados.add(element.texto);
        }
      } else if (element.checked == false) {
        // removendo item caso seja desmarcado
        listaNomesSelecionados.remove(element.texto);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double larguraTela = MediaQuery.of(context).size.width;
    double alturaTela = MediaQuery.of(context).size.height;
    return Theme(
      data: estilo.estiloGeral,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (exibirWidgetTelaCarregamento) {
              return TelaCarregamento();
            } else {
              return Scaffold(
                appBar: AppBar(
                  title: Text(Textos.telaRemoverCamposTitulo),
                  leading: IconButton(
                    color: Colors.white,
                    onPressed: () {
                      validarRedirecionamentoTela();
                    },
                    icon: const Icon(Icons.arrow_back_ios),
                  ),
                ),
                body: Container(
                  color: Colors.white,
                  width: larguraTela,
                  height: alturaTela,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10.0),
                          width: larguraTela,
                          child: Text(
                            Textos.descricaoTabelaSelecionada +
                                widget.nomeEscala,
                            textAlign: TextAlign.end,
                          ),
                        ),
                        SizedBox(
                          height: alturaTela * 0.65,
                          width: larguraTela,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              if (listaNomesCadastrados.isNotEmpty) {
                                // area de exibicao de descricao e listagem de nomes
                                return Column(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 10.0,
                                      ),
                                      width: larguraTela,
                                      child: Text(
                                        textAlign: TextAlign.center,
                                        Textos.telaRemoverCamposDescricao,
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    ),
                                    // Area de Exibicao da lista com os nomes dos voluntarios
                                    Card(
                                      color: Colors.white,
                                      shape: const OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(20),
                                        ),
                                        borderSide: BorderSide(
                                          width: 1,
                                          color: PaletaCores.corCastanho,
                                        ),
                                      ),
                                      child: SizedBox(
                                        height: alturaTela * 0.5,
                                        width:
                                            Platform.isAndroid || Platform.isIOS
                                                ? larguraTela
                                                : larguraTela * 0.8,
                                        child: ListView(
                                          children: [
                                            ...listaNomesCadastrados.map(
                                              (e) => checkBoxPersonalizado(e),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                // area caso nao tenha
                                // nenhum voluntario cadastrado
                                return Container(
                                  margin: const EdgeInsets.all(10.0),
                                  transformAlignment: Alignment.center,
                                  alignment: Alignment.center,
                                  child: Text(
                                    Textos.erroBaseDadosVazia,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                bottomNavigationBar: Container(
                  height: 160,
                  color: Colors.white,
                  child: Column(
                    children: [
                      Container(
                        margin: EdgeInsets.all(20),
                        width: 120,
                        height: 40,
                        child: FloatingActionButton(
                          heroTag: Textos.btnRemoverCampo,
                          onPressed: () {
                            chamarRemoverCampo();
                          },
                          child: Text(
                            Textos.btnRemoverCampo,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      BarraNavegacao(),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
