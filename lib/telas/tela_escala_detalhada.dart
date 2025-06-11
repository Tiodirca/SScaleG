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
  bool exibirWidgetCarregamento = true;
  bool exibirOcultarBtnAcao = true;
  late List<Map> escala;
  List<dynamic> cabecalhoEscala = [];
  List<Map> listaIDDocumento = [];
  List<DataColumn> cabecalhoDataColumn = [];
  List<DataRow> linhasDataRow = [];
  String nomeReacar = "";
  int contadorBtnFloat = 0;
  final validacaoFormulario = GlobalKey<FormState>();
  TextEditingController textoPesquisa = TextEditingController(text: "");

  @override
  void initState() {
    super.initState();
    escala = [];
    realizarBuscaDadosFireBase(widget.idTabelaSelecionada);
  }

  limparVariaveis() {
    setState(() {
      escala.clear();
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
                Map idDocumentoData = {};
                idDocumentoData[documentoFirebase.id] =
                    "${documentoFirebase.data().values.elementAt(0)} "
                    "${documentoFirebase.data().values.elementAt(1)}";
                listaIDDocumento.addAll([idDocumentoData]);
                //ordandando lista pela data
                escala.addAll([documentoFirebase.data()]);
              }
              //ordenarListaPelaData();
              if (escala.isEmpty) {
                setState(() {
                  exibirOcultarBtnAcao = false;
                  exibirWidgetCarregamento = false;
                });
              } else {
                setState(() {
                  print(querySnapshot.docs.first.data().keys.toList());

                  chamarCarregarLinhas();
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

  chamarCarregarLinhas() {
    List<MapEntry> escalaOrdenadaItemMap = [];
    String dataComparacao = "";
    Map escalaOrdenadaMap = {};
    for (var item in escala) {
      contadorBtnFloat++;

      List<dynamic> elementos = [];
      // adicinando na lista todos os itens transformados em entries item  a item
      escalaOrdenadaItemMap.addAll(item.entries);
      //ordenando a lista para que a data e o
      escalaOrdenadaItemMap.sort((a, b) {
        return a.key.toString().compareTo(b.key.toString());
      });
      //percorrendo cada item do map que esta na lista Escala
      item.forEach((key, value) {
        //verificando se a key corrende ao seguinte valor
        if (key.contains(Constantes.dataCulto)) {
          //definindo que variavel vai receber o seguinte valor
          dataComparacao = value;
          //percorrendo lista ja ordenada
          for (var elemento in escalaOrdenadaItemMap) {
            //verificando se o map NAO contem a data de comparadacao
            // caso nao tenha entrar no IF
            if (!(escalaOrdenadaMap.containsKey(dataComparacao))) {
              //definindo que o map vai receber os valores
              escalaOrdenadaMap[elemento.key] = elemento.value;
            }
          }
        }
      });
      //print(t.toString());
      if (cabecalhoEscala.isEmpty) {
        cabecalhoEscala = escalaOrdenadaMap.keys.toList();
        //adicionando no cabecalho colunas de editar e excluir
        cabecalhoEscala.addAll([Constantes.editar, Constantes.excluir]);
        carregarCabecalho();
      }
      elementos = escalaOrdenadaMap.values.toList();
      elementos.addAll([Constantes.editar, Constantes.excluir]);
      adicionarLinhasNaEscala(elementos);
    }
  }

  chamarCarregarCabecalho(Map item) {
    cabecalhoEscala = item.keys.toList();
    //adicionando no cabecalho colunas de editar e excluir
    cabecalhoEscala.addAll([Constantes.editar, Constantes.excluir]);
    carregarCabecalho();
  }

  adicionarLinhasNaEscala(List<dynamic> listaItem) {
    linhasDataRow.addAll([
      DataRow(
        cells: [
          ...listaItem.map((e) {
            if (e.toString() == Constantes.editar) {
              return DataCell(
                SizedBox(
                  width: 40,
                  height: 40,
                  child: FloatingActionButton(
                    heroTag: "${Constantes.editar}$contadorBtnFloat",
                    onPressed: () {
                      for (var elemento in listaIDDocumento) {
                        String dataComHora = elemento.values.toString();
                        String dataComHoraItem =
                            "${listaItem[0]} ${listaItem[1]}";

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
                      color: PaletaCores.corAzulMagenta,
                      size: 25,
                    ),
                  ),
                ),
              );
            } else if (e.toString() == Constantes.excluir) {
              return DataCell(
                SizedBox(
                  width: 40,
                  height: 40,
                  child: FloatingActionButton(
                    heroTag: "${Constantes.excluir}$contadorBtnFloat",
                    onPressed: () {
                      for (var elemento in listaIDDocumento) {
                        String dataComHora = elemento.values.toString();
                        String dataComHoraItem =
                            "${listaItem[0]} ${listaItem[1]}";

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
                      color: PaletaCores.corAzulMagenta,
                      size: 25,
                    ),
                  ),
                ),
              );
            } else {
              return DataCell(
                Container(
                  decoration: validarNomeFoco(e),
                  width: 90,
                  //SET width
                  child: SingleChildScrollView(
                    child: Text(e.toString(), textAlign: TextAlign.center),
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
                .replaceAll(RegExp(r'[0-9]'), ''),
          ),
        ),
      );
    }
  }

  ordenarListaPelaData() {
    // ordenando a lista pela data colocando
    // a data mais antiga no topo da listagem
    escala.sort((a, b) {
      //convertendo data para o formato correto
      int data = DateFormat("dd/MM/yyyy EEEE", "pt_BR")
          .parse(a.values.elementAt(0))
          .compareTo(
            DateFormat("dd/MM/yyyy EEEE", "pt_BR").parse(b.values.elementAt(0)),
          );
      // caso a variavel seja diferente de 0 quer dizer que as datas nao sao iguais
      // logo sera colocado em ordem baseado na ordem acima
      if (data != 0) {
        return data;
      }
      // caso a condicao acima retorne 0 quer dizer que as datas sao iguais
      // logo sera colocado em ordem baseado na ordem a baixo
      return a.values.elementAt(1).compareTo(b.values.elementAt(1));
    });
  }

  validarNomeFoco(String nome) {
    //colocando tudo em minuscolo pois se tiver maiusculo nao localiza
    if (nome.toLowerCase().contains(nomeReacar.toLowerCase()) &&
        nomeReacar.isNotEmpty) {
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

  Widget botoesAcoes(
    String nomeBotao,
    IconData icone,
    double largura,
    double altura,
  ) => SizedBox(
    height: altura,
    width: largura,
    child: FloatingActionButton(
      elevation: 0,
      heroTag: nomeBotao,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: PaletaCores.corCastanho),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      onPressed: () async {
        if (nomeBotao == Textos.btnBaixar) {
          // GerarPDFEscala gerarPDF = GerarPDFEscala(
          //     escala: escala,
          //     nomeEscala: widget.nomeTabela,
          //     exibirMesaApoio: exibirOcultarCampoMesaApoio,
          //     exibirRecolherOferta: exibirOcultarCampoRecolherOferta,
          //     exibirIrmaoReserva: exibirOcultarCampoIrmaoReserva,
          //     exibirServirSantaCeia: exibirOcultarServirSantaCeia,
          //     exibirUniformes: exibirOcultarCampoUniforme);
          // gerarPDF.pegarDados();
        } else if (nomeBotao == Textos.btnAdicionar) {
          redirecionarTelaCadastroItem();
        } else if (nomeBotao == Textos.btnRecarregar) {
          setState(() {
            exibirWidgetCarregamento = true;
            realizarBuscaDadosFireBase(widget.idTabelaSelecionada);
          });
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, color: PaletaCores.corAzulMagenta, size: 30),
          Text(
            nomeBotao,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: PaletaCores.corAzulMagenta,
            ),
          ),
        ],
      ),
    ),
  );

  Widget botoesSwitch(String label, bool valorBotao) => Container(
    margin: EdgeInsets.symmetric(horizontal: 1.0),
    width: 180,
    child: Row(
      children: [
        Text(label),
        Switch(
          inactiveThumbColor: PaletaCores.corAzulMagenta,
          value: valorBotao,
          activeColor: PaletaCores.corAzulMagenta,
          onChanged: (bool valor) {
            setState(() {
              //mudarSwitch(label, valor);
            });
          },
        ),
      ],
    ),
  );

  Widget botoesAreaPesquisa(
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
          if (validacaoFormulario.currentState!.validate()) {
            setState(() {
              nomeReacar = textoPesquisa.text;
              linhasDataRow.clear();
              chamarCarregarLinhas();
            });
          }
        } else {
          setState(() {
            exibirBarraPesquisa = false;
            nomeReacar = "";
            textoPesquisa.clear();
            linhasDataRow.clear();
            chamarCarregarLinhas();
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
                    botoesAreaPesquisa(
                      Constantes.iconeAbrirBarraPesquisa,
                      PaletaCores.corAzulMagenta,
                      40,
                      40,
                    ),
                  ],
                  title: Text(Textos.tituloTelaEscalaDetalhada),
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
                    if (escala.isEmpty) {
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
                              children: [
                                botoesAcoes(
                                  Textos.btnRecarregar,
                                  Constantes.iconeRecarregar,
                                  100,
                                  60,
                                ),
                                botoesAcoes(
                                  Textos.btnAdicionar,
                                  Constantes.iconeAdicionar,
                                  100,
                                  60,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    } else {
                      return Container(
                        color: Colors.white,
                        width: larguraTela,
                        height: alturaTela,
                        child: SingleChildScrollView(
                          child: Stack(
                            alignment: AlignmentDirectional.topEnd,
                            children: [
                              Column(
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
                                      Textos.descricaoTelaListagemItens,
                                      style: const TextStyle(fontSize: 18),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 10.0,
                                      vertical: 0.0,
                                    ),
                                    height:
                                        Platform.isWindows
                                            ? alturaTela * 0.6
                                            : alturaTela * 0.55,
                                    width: larguraTela,
                                    child: Card(
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
                                      child: Center(
                                        child: ListView(
                                          scrollDirection: Axis.vertical,
                                          children: [
                                            SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: DataTable(
                                                columnSpacing: 20,
                                                columns: cabecalhoDataColumn,
                                                rows: linhasDataRow,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Visibility(
                                visible: exibirBarraPesquisa,
                                child: Positioned(
                                  right: 0,
                                  child: Center(
                                    child: Container(
                                      padding: EdgeInsets.all(10),
                                      width:
                                          Platform.isAndroid || Platform.isIOS
                                              ? larguraTela
                                              : larguraTela * 0.3,
                                      child: Card(
                                        color: Colors.transparent,
                                        elevation: 0,
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
                                                  height: 50,
                                                  color: Colors.white,
                                                  child: Form(
                                                    key: validacaoFormulario,
                                                    child: TextFormField(
                                                      controller: textoPesquisa,
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
                                                botoesAreaPesquisa(
                                                  Constantes
                                                      .iconeBarraPesquisar,
                                                  PaletaCores.corVerdeCiano,
                                                  50,
                                                  50,
                                                ),
                                                botoesAreaPesquisa(
                                                  Constantes.iconeExclusao,
                                                  PaletaCores.corVermelha,
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
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
                bottomNavigationBar: Container(
                  alignment: Alignment.center,
                  color: Colors.white,
                  width: larguraTela,
                  height: 150,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Visibility(
                        visible: exibirOcultarBtnAcao,
                        child: Container(
                          margin: const EdgeInsets.only(top: 10.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              botoesAcoes(
                                Textos.btnBaixar,
                                Constantes.iconeBaixar,
                                100,
                                60,
                              ),
                              botoesAcoes(
                                Textos.btnAdicionar,
                                Constantes.iconeAdicionar,
                                80,
                                60,
                              ),
                            ],
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
