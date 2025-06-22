import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sscaleg/Uteis/paleta_cores.dart';
import 'package:sscaleg/Widgets/tela_carregamento.dart';
import 'package:sscaleg/uteis/constantes.dart';
import 'package:sscaleg/uteis/estilo.dart';
import 'package:sscaleg/uteis/metodos_auxiliares.dart';
import 'package:sscaleg/uteis/passar_pegar_dados.dart';
import 'package:sscaleg/uteis/textos.dart';
import 'package:sscaleg/widgets/barra_navegacao_widget.dart';

class TelaEscalaDetalhada extends StatefulWidget {
  const TelaEscalaDetalhada({
    super.key,
    required this.nomeTabela,
    required this.idTabelaSelecionada,
  });

  final String nomeTabela;
  final String idTabelaSelecionada;

  @override
  State<TelaEscalaDetalhada> createState() => _TelaEscalaDetalhadaState();
}

class _TelaEscalaDetalhadaState extends State<TelaEscalaDetalhada> {
  Estilo estilo = Estilo();
  bool exibirBarraPesquisa = false;
  bool exibirObservacoes = false;
  bool exibirWidgetCarregamento = true;
  bool exibirOcultarBtnAcao = true;
  List<Map> listaEscalaBancoDados = [];
  List<Map> listaLinhaEscalaOrdenada = [];
  List<String> listaObservacoesPDF = [];
  List<dynamic> cabecalhoEscala = [];
  List<Map> listaIDDocumento = [];
  Map mapExibirCampos = {};
  int contadorBtnFloat = 0;
  int indexSwitch = 0;
  int quantidadeRepeticaoNomePesquisa = 0;
  List<DataColumn> cabecalhoDataColumn = [];
  List<DataRow> linhasDataRow = [];
  String nomeReacar = "";
  final validacaoFormulario = GlobalKey<FormState>();
  TextEditingController textoPesquisa = TextEditingController(text: "");

  @override
  void initState() {
    super.initState();
    listaObservacoesPDF = PassarPegarDados.recuperarObservacoesPDF();
    realizarBuscaDadosFireBase(widget.idTabelaSelecionada);
  }

  limparVariaveis() {
    setState(() {
      listaEscalaBancoDados.clear();
      linhasDataRow.clear();
      cabecalhoEscala.clear();
      cabecalhoDataColumn.clear();
      listaIDDocumento.clear();
    });
  }

  realizarBuscaDadosFireBase(String idDocumento) async {
    setState(() {
      exibirWidgetCarregamento = true;
    });
    limparVariaveis();
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
              // for para percorrer todos os dados que a variavel recebeu
              for (var documentoFirebase in querySnapshot.docs) {
                //adicionando na lista os id dos documentos
                listaIDDocumento.addAll([
                  recuperarIDDocumento(documentoFirebase),
                ]);
                //adicionando na lista
                listaEscalaBancoDados.addAll([documentoFirebase.data()]);
              }
              if (listaEscalaBancoDados.isEmpty) {
                setState(() {
                  exibirOcultarBtnAcao = false;
                  exibirWidgetCarregamento = false;
                });
              } else {
                setState(() {
                  percorrerListaRetornadaBancoDados();
                  exibirOcultarBtnAcao = true;
                  exibirWidgetCarregamento = false;
                });
              }
            } else {
              setState(() {
                exibirOcultarBtnAcao = false;
                exibirWidgetCarregamento = false;
              });
            }
          },
          onError: (e) {
            chamarExibirMensagemErro("Erro ao buscar escala : ${e.toString()}");
          },
        );
  }

  //metodo para recuperar o id e colocar num map onde o key vai receber o id do documento
  // e no value vai receber a concatenacao da data com o horario de trabalho
  recuperarIDDocumento(var documentoFirebase) {
    Map idDocumentoData = {};
    String dataComHorario = "";
    //percorrendo map
    documentoFirebase.data().forEach((key, value) {
      if (key.toString().contains(Constantes.dataCulto)) {
        dataComHorario = "$value $dataComHorario";
      }
      if (key.toString().contains(Constantes.horarioTrabalho)) {
        dataComHorario = "$dataComHorario$value";
      }
    });
    idDocumentoData[documentoFirebase.id] = dataComHorario;
    return idDocumentoData;
  }

  percorrerListaRetornadaBancoDados() {
    Map itemOrdenado = {};
    for (var item in listaEscalaBancoDados) {
      contadorBtnFloat++;
      itemOrdenado = fazerOrdenacaoItemAItemMap(item);
      listaLinhaEscalaOrdenada.add(itemOrdenado);
    }
    listaLinhaEscalaOrdenada = ordenarListaPelaDataEHorario(
      listaLinhaEscalaOrdenada,
    );
    chamarCarregarLinhas(listaLinhaEscalaOrdenada, itemOrdenado);
  }

  //metodo para fazer a ordenacao de cada item que for puxado do banco de dados
  // para que a data e o horario de trabalho fiquem no comeco
  fazerOrdenacaoItemAItemMap(var item) {
    Map escalaOrdenadaMap = {};
    List<MapEntry> escalaOrdenadaItemMap = [];
    // adicinando na lista todos os itens transformados em entries item  a item
    escalaOrdenadaItemMap.addAll(item.entries);
    //fazendo ordenacao da lista para os itens menores ficarem em primeiro
    // ou seja os item que contem numeracao no comeco
    escalaOrdenadaItemMap.sort((a, b) {
      return a.key.toString().compareTo(b.key.toString());
    });
    for (var element in escalaOrdenadaItemMap) {
      escalaOrdenadaMap[element.key] = element.value;
    }
    return escalaOrdenadaMap;
  }

  chamarCarregarLinhas(List<Map> listaLinhaEscalaOrdenada, Map itemOrdenado) {
    for (var element in listaLinhaEscalaOrdenada) {
      List<dynamic> elementos = [];
      chamarCarregarCabecalho(itemOrdenado);
      elementos = element.values.toList();
      elementos.addAll([Constantes.editar, Constantes.excluir]);
      adicionarLinhasNaEscala(elementos);
    }
  }

  ordenarListaPelaDataEHorario(List<Map> listaOrdernar) {
    listaOrdernar.sort((a, b) {
      int data = DateFormat("dd/MM/yyyy EEEE", "pt_BR")
          .parse(a.values.elementAt(0))
          .compareTo(
            DateFormat("dd/MM/yyyy EEEE", "pt_BR").parse(b.values.elementAt(0)),
          );
      if (data != 0) {
        return data;
      }
      // caso a condicao acima retorne 0 quer dizer que as datas sao iguais
      // logo sera colocado em ordem baseado na ordem a baixo
      return a.values.elementAt(1).compareTo(b.values.elementAt(1));
    });
    return listaOrdernar;
  }

  // metodo para pegar os valores que irao compor o cabecalho
  chamarCarregarCabecalho(Map escalaOrdenadaMap) {
    if (cabecalhoEscala.isEmpty) {
      cabecalhoEscala = escalaOrdenadaMap.keys.toList();
      //adicionando no cabecalho colunas de editar e excluir
      cabecalhoEscala.addAll([Constantes.editar, Constantes.excluir]);
      carregarCabecalho();
    }
  }

  adicionarLinhasNaEscala(List<dynamic> listaItem) {
    linhasDataRow.addAll([
      DataRow(
        cells: [
          ...listaItem.map((e) {
            if (e.toString() == Constantes.editar) {
              return DataCell(
                SizedBox(
                  width: 35,
                  height: 35,
                  child: FloatingActionButton(
                    heroTag: "${Constantes.editar}$contadorBtnFloat",
                    onPressed: () {
                      String dataComHoraItem =
                          "${listaItem[0]} ${listaItem[1]}";
                      for (var elemento in listaIDDocumento) {
                        String dataComHora = elemento.values.toString();
                        if (dataComHora.contains(dataComHoraItem)) {
                          String idDocumento = elemento.keys
                              .toString()
                              .replaceAll("(", "")
                              .replaceAll(")", "");
                          redirecionarTelaAtualizar(listaItem, idDocumento);
                        }
                      }
                    },
                    child: Icon(
                      Constantes.iconeEditar,
                      color: PaletaCores.corAzulEscuro,
                      size: 25,
                    ),
                  ),
                ),
              );
            } else if (e.toString() == Constantes.excluir) {
              return DataCell(
                SizedBox(
                  width: 35,
                  height: 35,
                  child: FloatingActionButton(
                    heroTag: "${Constantes.excluir}$contadorBtnFloat",
                    onPressed: () {
                      String dataComHoraItem =
                          "${listaItem[0]} ${listaItem[1]}";
                      for (var elemento in listaIDDocumento) {
                        String dataComHora = elemento.values.toString();
                        if (dataComHora.contains(dataComHoraItem)) {
                          String idDocumento = elemento.keys
                              .toString()
                              .replaceAll("(", "")
                              .replaceAll(")", "");
                          alertaExclusao(
                            context,
                            elemento.values.toString(),
                            idDocumento,
                          );
                        }
                      }
                    },
                    child: Icon(
                      Constantes.iconeExclusao,
                      color: PaletaCores.corAzulEscuro,
                      size: 25,
                    ),
                  ),
                ),
              );
            } else {
              return DataCell(
                Container(
                  decoration: validarNomeFoco(e.replaceAll("_", " ")),
                  width: 90,
                  //SET width
                  child: SingleChildScrollView(
                    child: Text(
                      e.toString().replaceAll("_", " "),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }
          }),
        ],
      ),
    ]);
  }

  carregarCabecalho() {
    for (var element in cabecalhoEscala) {
      cabecalhoDataColumn.add(
        DataColumn(
          label: Text(
            element
                .toString()
                .replaceAll("01_", "")
                .replaceAll("02_", "")
                .replaceAll("_", " ")
                .replaceAll(RegExp(r'[0-9]'), '')
                .toUpperCase(),
          ),
        ),
      );
    }
  }

  validarNomeFoco(String nome) {
    //colocando tudo em minuscolo pois se tiver maiusculo nao localiza
    if (nome.toLowerCase().contains(nomeReacar.toLowerCase()) &&
        nomeReacar.isNotEmpty) {
      quantidadeRepeticaoNomePesquisa++;
      return BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border(
          bottom: BorderSide(width: 1, color: Colors.green),
          left: BorderSide(width: 1, color: Colors.green),
          right: BorderSide(width: 1, color: Colors.green),
          top: BorderSide(width: 1, color: Colors.green),
        ),
      );
    } else {
      return null;
    }
  }

  // // Metodo para chamar deletar tabela
  chamarDeletar(String idDocumento) async {
    try {
      var db = FirebaseFirestore.instance;
      await db
          .collection(Constantes.fireBaseColecaoEscalas)
          .doc(widget.idTabelaSelecionada)
          .collection(Constantes.fireBaseDadosCadastrados)
          .doc(idDocumento)
          .delete()
          .then(
            (doc) {
              setState(() {
                linhasDataRow.clear();
                listaLinhaEscalaOrdenada.clear();
                realizarBuscaDadosFireBase(widget.idTabelaSelecionada);
              });
              chamarExibirMensagemSucesso();
            },
            onError: (e) {
              setState(() {
                exibirWidgetCarregamento = false;
              });
              chamarExibirMensagemErro("Erro ao Deletar : ${e.toString()}");
            },
          );
    } catch (e) {
      setState(() {
        exibirWidgetCarregamento = false;
      });
      chamarExibirMensagemErro(e.toString());
    }
  }

  chamarExibirMensagemErro(String erro) {
    MetodosAuxiliares.exibirMensagens(
      Constantes.tipoNotificacaoErro,
      erro,
      context,
    );
  }

  chamarExibirMensagemSucesso() {
    MetodosAuxiliares.exibirMensagens(
      Constantes.tipoNotificacaoSucesso,
      Textos.notificacaoSucesso,
      context,
    );
  }

  redirecionarTelaCadastroItem() {
    Map dadosCabecalhoLinha = {};
    for (int i = 0; i < cabecalhoEscala.length; i++) {
      dadosCabecalhoLinha[cabecalhoEscala[i]] = "";
    }

    PassarPegarDados.passarItens(dadosCabecalhoLinha);
    var dados = {};
    dados[Constantes.rotaArgumentoNomeEscala] = widget.nomeTabela;
    dados[Constantes.rotaArgumentoIDEscalaSelecionada] =
        widget.idTabelaSelecionada;
    Navigator.pushReplacementNamed(
      context,
      Constantes.rotaTelaCadastroItem,
      arguments: dados,
    );
  }

  redirecionarTelaAtualizar(List<dynamic> listaItens, String id) {
    Map dadosCabecalhoLinha = {};
    for (int i = 0; i < cabecalhoEscala.length; i++) {
      dadosCabecalhoLinha[cabecalhoEscala[i]] = listaItens[i];
    }
    PassarPegarDados.passarItens(dadosCabecalhoLinha);
    PassarPegarDados.passarIdAtualizarSelecionado(id);
    var dados = {};
    dados[Constantes.rotaArgumentoNomeEscala] = widget.nomeTabela;
    dados[Constantes.rotaArgumentoIDEscalaSelecionada] =
        widget.idTabelaSelecionada;
    Navigator.pushReplacementNamed(
      context,
      Constantes.rotaTelaAtualizarItem,
      arguments: dados,
    );
  }

  redirecionarTelaObservacao() {
    var dados = {};
    dados[Constantes.rotaArgumentoNomeEscala] = widget.nomeTabela;
    dados[Constantes.rotaArgumentoIDEscalaSelecionada] =
        widget.idTabelaSelecionada;
    Navigator.pushReplacementNamed(
      context,
      Constantes.rotaTelaObservacao,
      arguments: dados,
    );
  }

  redirecionarTelaConfigurarPDFBaixar() {
    var dados = {};
    PassarPegarDados.passarObservacoesPDF(listaObservacoesPDF);
    dados[Constantes.rotaArgumentoCabecalhoEscala] = cabecalhoEscala;
    dados[Constantes.rotaArgumentoLinhasEscala] = listaLinhaEscalaOrdenada;
    dados[Constantes.rotaArgumentoObservacaoEscala] = listaObservacoesPDF;
    dados[Constantes.rotaArgumentoNomeEscala] = widget.nomeTabela;
    dados[Constantes.rotaArgumentoIDEscalaSelecionada] =
        widget.idTabelaSelecionada;
    Navigator.pushReplacementNamed(
      context,
      Constantes.rotaTelaConfigurarPDFBaixar,
      arguments: dados,
    );
  }

  chamarPesquisarNome() {
    if (validacaoFormulario.currentState!.validate()) {
      setState(() {
        nomeReacar = textoPesquisa.text;
        linhasDataRow.clear();
        listaLinhaEscalaOrdenada.clear();
        quantidadeRepeticaoNomePesquisa = 0;
        percorrerListaRetornadaBancoDados();
      });
    }
  }

  Future<void> alertaExclusao(
    BuildContext context,
    String data,
    String idDocumento,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            Textos.tituloAlertaExclusao,
            style: const TextStyle(color: Colors.black),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  Textos.descricaoAlertaExclusao,
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 10),
                Wrap(
                  children: [
                    Text(
                      data,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
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
                setState(() {
                  nomeReacar = "";
                  textoPesquisa.clear();
                  exibirBarraPesquisa = false;
                  exibirWidgetCarregamento = true;
                });
                chamarDeletar(idDocumento);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget botoesAcoes(String nomeBotao) => SizedBox(
    height: 40,
    width: 110,
    child: FloatingActionButton(
      elevation: 0,
      heroTag: nomeBotao,
      backgroundColor: Colors.white,
      onPressed: () async {
        if (nomeBotao == Textos.telaObservacaoTitulo) {
          PassarPegarDados.passarObservacoesPDF(listaObservacoesPDF);
          redirecionarTelaObservacao();
        } else if (nomeBotao == Textos.btnAdicionar) {
          redirecionarTelaCadastroItem();
        } else if (nomeBotao == Textos.btnBaixarPDF) {
          redirecionarTelaConfigurarPDFBaixar();
        } else if (nomeBotao == Textos.btnRecarregar) {
          setState(() {
            exibirWidgetCarregamento = true;
            realizarBuscaDadosFireBase(widget.idTabelaSelecionada);
          });
        }
      },
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        children: [
          Text(
            nomeBotao,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.black),
          ),
        ],
      ),
    ),
  );

  Widget botoesIcone(
    IconData icone,
    Color corBotao,
    double largura,
    double altura,
  ) => Container(
    margin: EdgeInsets.symmetric(horizontal: 5.0),
    width: largura,
    height: altura,
    child: FloatingActionButton(
      heroTag: icone.toString(),
      onPressed: () {
        if (icone == Constantes.iconeAbrirBarraPesquisa) {
          setState(() {
            exibirBarraPesquisa = true;
          });
        } else if (icone == Constantes.iconeBarraPesquisar) {
          chamarPesquisarNome();
        } else {
          setState(() {
            exibirBarraPesquisa = false;
            nomeReacar = "";
            textoPesquisa.clear();
            linhasDataRow.clear();
            listaLinhaEscalaOrdenada.clear();
            quantidadeRepeticaoNomePesquisa = 0;
            percorrerListaRetornadaBancoDados();
          });
        }
      },
      child: Icon(icone, color: corBotao, size: 25),
    ),
  );

  @override
  Widget build(BuildContext context) {
    double alturaTela = MediaQuery.of(context).size.height;
    double larguraTela = MediaQuery.of(context).size.width;
    Timer(Duration(seconds: 2), () {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [SystemUiOverlay.bottom],
      );
    });
    return Theme(
      data: estilo.estiloGeral,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (exibirWidgetCarregamento) {
              return const TelaCarregamento();
            } else {
              return Scaffold(
                appBar: AppBar(
                  actions: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (listaLinhaEscalaOrdenada.isEmpty) {
                          return Container();
                        } else {
                          return botoesIcone(
                            Constantes.iconeAbrirBarraPesquisa,
                            PaletaCores.corAzulEscuro,
                            40,
                            40,
                          );
                        }
                      },
                    ),
                  ],
                  title: Text(Textos.telaEscalaDetalhadaTitulo),
                  leading: IconButton(
                    color: Colors.white,
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        Constantes.rotaTelaListagemEscalaBandoDados,
                      );
                    },
                    icon: const Icon(Icons.arrow_back_ios),
                  ),
                ),
                body: LayoutBuilder(
                  builder: (context, constraints) {
                    if (listaEscalaBancoDados.isEmpty) {
                      return Container(
                        color: Colors.white,
                        width: larguraTela,
                        height: alturaTela,
                        child: Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 20),
                              width: larguraTela * 0.5,
                              height: 200,
                              child: Text(
                                Textos.erroBaseDadosVazia,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [botoesAcoes(Textos.btnRecarregar)],
                            ),
                          ],
                        ),
                      );
                    } else {
                      return Container(
                        color: Colors.white,
                        width: larguraTela,
                        height: alturaTela,
                        child: Column(
                          children: [
                            Expanded(
                              flex: 0,
                              child: Stack(
                                children: [
                                  SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 10.0,
                                          ),
                                          width: larguraTela,
                                          child: Text(
                                            Textos.descricaoTabelaSelecionada +
                                                widget.nomeTabela,
                                            textAlign: TextAlign.end,
                                          ),
                                        ),
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 10.0,
                                            horizontal: 0,
                                          ),
                                          width: larguraTela,
                                          child: Text(
                                            Textos
                                                .telaEscalaDetalhadaDescricaoItens,
                                            style: const TextStyle(
                                              fontSize: 18,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Visibility(
                                    visible: exibirBarraPesquisa,
                                    child: Positioned(
                                      right: 0,
                                      child: Center(
                                        child: Container(
                                          padding: EdgeInsets.all(10),
                                          child: Column(
                                            children: [
                                              Wrap(
                                                children: [
                                                  Container(
                                                    width:
                                                        Platform.isAndroid ||
                                                                Platform.isIOS
                                                            ? 200
                                                            : 300,
                                                    height: 80,
                                                    color: Colors.white,
                                                    child: Form(
                                                      key: validacaoFormulario,
                                                      child: TextFormField(
                                                        onFieldSubmitted: (
                                                          value,
                                                        ) {
                                                          chamarPesquisarNome();
                                                        },
                                                        decoration: InputDecoration(
                                                          hintText:
                                                              Textos
                                                                  .labelTextFieldCampo,
                                                        ),
                                                        controller:
                                                            textoPesquisa,
                                                        validator: (value) {
                                                          if (value!.isEmpty) {
                                                            return Textos
                                                                .erroCampoVazio;
                                                          }
                                                          return null;
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                  botoesIcone(
                                                    Constantes
                                                        .iconeBarraPesquisar,
                                                    PaletaCores.corVerdeCiano,
                                                    40,
                                                    40,
                                                  ),
                                                  botoesIcone(
                                                    Constantes.iconeExclusao,
                                                    PaletaCores.corRosaAvermelhado,
                                                    35,
                                                    35,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 10.0,
                                  vertical: 0.0,
                                ),
                                width: larguraTela,
                                child: Card(
                                  child: Center(
                                    child: ListView(
                                      scrollDirection: Axis.vertical,
                                      children: [
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: DataTable(
                                            headingTextStyle: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            columnSpacing: 20,
                                            horizontalMargin: 10,
                                            dataTextStyle: TextStyle(
                                              fontSize: 14,
                                            ),
                                            columns: cabecalhoDataColumn,
                                            rows: linhasDataRow,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: exibirBarraPesquisa,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    Textos
                                        .telaEscalaDetalhadaQuantiNomePesquisa,
                                  ),
                                  Text(
                                    quantidadeRepeticaoNomePesquisa.toString(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
                bottomNavigationBar: Container(
                  alignment: Alignment.center,
                  color: Colors.white,
                  width: larguraTela,
                  height: 110,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Visibility(
                        visible: exibirOcultarBtnAcao,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            botoesAcoes(Textos.btnBaixarPDF),
                            botoesAcoes(Textos.telaObservacaoTitulo),
                            botoesAcoes(Textos.btnAdicionar),
                          ],
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
