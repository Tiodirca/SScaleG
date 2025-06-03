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
  bool exibirTelaPesquisa = false;
  bool exibirBarraPesquisa = false;
  late List<Map> escala;
  List<String> cabecalhoEscala = [];
  bool exibirWidgetCarregamento = true;
  bool exibirOcultarBtnAcao = true;
  int contadorItensEscala = 0;
  int quantRepeticaoNome = 0;
  int contadorQuantiItemEscala = 0;
  List<Map> listaIDDocumento = [];
  List<String> nomesFiltrados = [];
  List<DataColumn> cabecalho = [];
  List<DataRow> linhas = [];
  Set<String> nomes = Set();
  String nomeReacar = "";
  final validacaoFormulario = GlobalKey<FormState>();
  TextEditingController nomePesquisa = TextEditingController(text: "");
  Map<String, int> quantidadeRepeticaoNome = {};

  @override
  void initState() {
    super.initState();
    escala = [];
    realizarBuscaDadosFireBase(widget.idTabelaSelecionada);
  }

  realizarBuscaDadosFireBase(String idDocumento) async {
    setState(() {
      nomes.clear();
      escala.clear();
      quantidadeRepeticaoNome.clear();
      nomesFiltrados.clear();
      nomeReacar = "";
      contadorItensEscala = 0;
      quantRepeticaoNome = 0;
    });
    var db = FirebaseFirestore.instance;
    //instanciano variavel
    db
        .collection(Constantes.fireBaseColecaoEscalas)
        .doc(idDocumento)
        .collection(Constantes.fireBaseDadosCadastrados)
        .get()
        .then((querySnapshot) async {
          //Veficando se nao e vazio
          if (querySnapshot.docs.isNotEmpty) {
            // for para percorrer todos os dados que a variavel recebeu
            for (var documentoFirebase in querySnapshot.docs) {
              //mudando estado da lista adicionando os itens nela
              setState(() {
                Map idDocumentoData = {};
                idDocumentoData[documentoFirebase.id] =
                    documentoFirebase.data().values.first;
                listaIDDocumento.addAll([idDocumentoData]);
                escala.addAll([documentoFirebase.data()]);
                //escala.add(documentoFirebase.data());
                //ordandando lista pela data
                ordenarListaPelaData();
              });
            }
            if (escala.isEmpty) {
              setState(() {
                exibirOcultarBtnAcao = false;
                exibirWidgetCarregamento = false;
              });
            } else {
              for (var element in escala) {
                List<dynamic> elementos = [];
                //adicionando somente os VALORES na lista
                elementos = element.values.toList();
                elementos.addAll([Constantes.editar, Constantes.excluir]);
                //chamando metodo para adicionar cada item em uma linha e coluna
                adicionarLinhasNaEscala(elementos);
              }
              setState(() {
                cabecalhoEscala = querySnapshot.docs.first.data().keys.toList();
                cabecalhoEscala.addAll([Constantes.editar, Constantes.excluir]);
                carregarCabecalho();
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
        });
  }

  carregarCabecalho() {
    for (var element in cabecalhoEscala) {
      cabecalho.add(
        DataColumn(
          label: Text(
            element.toString().replaceAll("DD", "D").replaceAll("DH", "H"),
          ),
        ),
      );
    }
  }

  adicionarLinhasNaEscala(List<dynamic> listaItem) {
    linhas.addAll([
      DataRow(
        cells: [
          ...listaItem.map((e) {
            if (e.toString() == Constantes.editar) {
              return DataCell(
                SizedBox(
                  width: 40,
                  height: 40,
                  child: FloatingActionButton(
                    heroTag: Constantes.editar,
                    onPressed: () {},
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
                botoesAreaPesquisa(
                  Constantes.iconeExclusao,
                  PaletaCores.corAzulMagenta,
                  40,
                  40,
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

  pegarIDDocumentoLinha(List<dynamic> listaItem) {
    for (var elemento in listaIDDocumento) {
      for (var element in listaItem) {
        if (elemento.values.contains(element)) {
          return {elemento.keys};
        }
      }
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
    if (nome.toLowerCase().contains("jhonatan")) {
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

  // converterJsonParaObjeto(
  //     String idDocumento, String id, int tamanhoEscala) async {
  //   // instanciando variavel
  //   var db = FirebaseFirestore.instance;
  //   //fazendo busca no banco de dados
  //   final ref = db
  //       .collection(Constantes.fireBaseColecaoEscala)
  //       .doc(idDocumento)
  //       .collection(Constantes.fireBaseDadosCadastrados)
  //       .doc(id)
  //       // chamando conversao
  //       .withConverter(
  //         fromFirestore: EscalaModelo.fromFirestore,
  //         toFirestore: (EscalaModelo escalaModelo, _) =>
  //             escalaModelo.toFirestore(),
  //       );
  //
  //   final docSnap = await ref.get();
  //   final dados = docSnap.data(); // convertendo
  //   if (dados != null) {
  //     dados.id = docSnap.id;
  //     //adicionando os dados convertidos na lista
  //     escala.add(dados);
  //     contadorItensEscala++;
  //     setState(() {
  //       ordenarLista();
  //       chamarVerificarColunaVazia();
  //       exibirWidgetCarregamento = false;
  //     });
  //     if (contadorItensEscala == tamanhoEscala) {
  //       setState(() {
  //         pegarNomesEscala();
  //       });
  //     }
  //   }
  // }

  // pegarNomesEscala() {
  //   List<String> nomesFiltradosAuxiliar = [];
  //   if (exibirOcultarCampoMesaApoio) {
  //     for (EscalaModelo voluntarios in escala) {
  //       if (!nomes.contains(voluntarios.primeiraHoraEntrada) ||
  //           !nomes.contains(voluntarios.irmaoReserva) ||
  //           !nomes.contains(voluntarios.mesaApoio)) {
  //         nomes.add(voluntarios.primeiraHoraEntrada.toLowerCase());
  //         nomes.add(voluntarios.irmaoReserva.toLowerCase());
  //         nomes.add(voluntarios.mesaApoio.toLowerCase());
  //         nomesFiltradosAuxiliar.add(voluntarios.mesaApoio.toLowerCase());
  //         nomesFiltradosAuxiliar
  //             .add(voluntarios.primeiraHoraEntrada.toLowerCase());
  //         nomesFiltradosAuxiliar.add(voluntarios.irmaoReserva.toLowerCase());
  //       }
  //     }
  //   } else {
  //     for (EscalaModelo voluntarios in escala) {
  //       if (!nomes.contains(voluntarios.recolherOferta) ||
  //           !nomes.contains(voluntarios.primeiraHoraPulpito) ||
  //           !nomes.contains(voluntarios.primeiraHoraEntrada) ||
  //           !nomes.contains(voluntarios.irmaoReserva)) {
  //         nomesFiltradosAuxiliar.add(voluntarios.recolherOferta.toLowerCase());
  //         nomesFiltradosAuxiliar.add(voluntarios.primeiraHoraPulpito.toLowerCase());
  //         nomesFiltradosAuxiliar.add(voluntarios.primeiraHoraEntrada.toLowerCase());
  //         nomesFiltradosAuxiliar.add(voluntarios.irmaoReserva.toLowerCase());
  //       }
  //     }
  //   }
  //   nomesFiltradosAuxiliar.forEach(
  //     (element) {
  //       if (element.isNotEmpty) {
  //         if (element.contains(" e ") || element.contains("/")) {
  //           element = element.replaceAll(" e ", "/");
  //           nomesFiltrados.addAll(element.split("/"));
  //         } else {
  //           nomesFiltrados.add(element);
  //         }
  //       }
  //     },
  //   );
  //   chamarPercorrerEscalaCompleta();
  //   print(quantidadeRepeticaoNome.toString());
  // }

  chamarPercorrerEscalaCompleta() {
    for (int i = 0; i < nomesFiltrados.length; i++) {
      //percorrerEscalaCompleta(i);
      quantRepeticaoNome = 0;
    }
  }

  // //metodo para percorrer a escala completa
  // percorrerEscalaCompleta(int index) {
  //   escala.forEach(
  //     (element) {
  //       verificarQuantRepeticaoNome(
  //           element.primeiraHoraEntrada.toLowerCase(), index);
  //       //validando se a escala e de cooperadoras
  //       //caso o campo mesa apoio estiver ativo fazer os seguintes passos
  //       if (exibirOcultarCampoMesaApoio) {
  //         verificarQuantRepeticaoNome(element.mesaApoio.toLowerCase(), index);
  //       } else {
  //         verificarQuantRepeticaoNome(
  //             element.recolherOferta.toLowerCase(), index);
  //         verificarQuantRepeticaoNome(
  //             element.primeiraHoraPulpito.toLowerCase(), index);
  //       }
  //       verificarQuantRepeticaoNome(element.irmaoReserva.toLowerCase(), index);
  //     },
  //   );
  // }

  // //metodo para verificar q quantidade de repeticoes que a escala tem
  // verificarQuantRepeticaoNome(String nome, int index) {
  //   //verificando se a string JA contem na LISTA nome filtrados
  //   if (nome.contains(nomesFiltrados.elementAt(index))) {
  //     //caso JA tenha aumentar a quantidade
  //     quantRepeticaoNome++;
  //     //passando MAP para colocar o nome e a quantidade
  //     quantidadeRepeticaoNome[nomesFiltrados.elementAt(index)] =
  //         quantRepeticaoNome;
  //   }
  // }
  //
  // ordenarLista() {
  //   // ordenando a lista pela data colocando
  //   // a data mais antiga no topo da listagem
  //   escala.sort(
  //     (a, b) {
  //       //convertendo data para o formato correto
  //       int data = DateFormat("dd/MM/yyyy EEEE", "pt_BR")
  //           .parse(a.dataCulto)
  //           .compareTo(
  //               DateFormat("dd/MM/yyyy EEEE", "pt_BR").parse(b.dataCulto));
  //
  //       // caso a variavel seja diferente de 0 quer dizer que as datas nao sao iguais
  //       // logo sera colocado em ordem baseado na ordem acima
  //       if (data != 0) {
  //         return data;
  //       }
  //       // caso a condicao acima retorne 0 quer dizer que as datas sao iguais
  //       // logo sera colocado em ordem baseado na ordem a baixo
  //       return a.horarioTroca.compareTo(b.horarioTroca);
  //     },
  //   );
  // }
  //
  // formatarHorario(String horarioTrocaRecuperado) {
  //   String horaSeparada = horarioTrocaRecuperado.split(" : ")[1];
  //   DateTime conversaoHorarioPData = new DateFormat("hh").parse(horaSeparada);
  //   print(conversaoHorarioPData.hour.toString());
  //   return conversaoHorarioPData;
  // }
  //
  // // metodo para chamar metodo para verificar
  // // se a coluna esta vazia
  // chamarVerificarColunaVazia() {
  //   for (var element in escala) {
  //     if (element.mesaApoio.isNotEmpty) {
  //       exibirOcultarCampoMesaApoio = true;
  //       break;
  //     } else {
  //       exibirOcultarCampoMesaApoio = false;
  //     }
  //   }
  //   for (var element in escala) {
  //     if (element.irmaoReserva.isNotEmpty) {
  //       exibirOcultarCampoIrmaoReserva = true;
  //       break;
  //     } else {
  //       exibirOcultarCampoIrmaoReserva = false;
  //     }
  //   }
  //   for (var element in escala) {
  //     if (element.recolherOferta.isNotEmpty) {
  //       exibirOcultarCampoRecolherOferta = true;
  //       break;
  //     } else {
  //       exibirOcultarCampoRecolherOferta = false;
  //     }
  //   }
  //   for (var element in escala) {
  //     if (element.servirSantaCeia.isNotEmpty) {
  //       exibirOcultarServirSantaCeia = true;
  //       break;
  //     } else {
  //       exibirOcultarServirSantaCeia = false;
  //     }
  //   }
  //   for (var element in escala) {
  //     if (element.banheiroFeminino.isNotEmpty) {
  //       //exibirPortaBanheiroFeminino = true;
  //       break;
  //     } else {
  //       //exibirPortaBanheiroFeminino = false;
  //     }
  //   }
  // }
  //
  // // Metodo para chamar deletar tabela
  // chamarDeletar(EscalaModelo escalaModelo) async {
  //   var db = FirebaseFirestore.instance;
  //   await db
  //       .collection(Constantes.fireBaseColecaoEscala)
  //       .doc(widget.idTabelaSelecionada)
  //       .collection(Constantes.fireBaseDadosCadastrados)
  //       .doc(escalaModelo.id)
  //       .delete()
  //       .then(
  //     (doc) {
  //       setState(() {
  //         escala.clear();
  //         realizarBuscaDadosFireBase(widget.idTabelaSelecionada);
  //       });
  //       MetodosAuxiliares.exibirMensagens(
  //           Textos.sucessoExcluirItem, Textos.tipoNotificacaoSucesso, context);
  //     },
  //     onError: (e) => MetodosAuxiliares.exibirMensagens(
  //         Textos.erroMsgExcluirItemEscala, Textos.tipoNotificacaoErro, context),
  //   );
  // }

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
        } else if (nomeBotao == Textos.btnRecarregar) {
          setState(() {
            //exibirWidgetCarregamento = true;
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

  // metodo para mudar status dos switch
  // mudarSwitch(String label, bool valor) {
  //   if (label == Textos.labelSwitchUniforme) {
  //     setState(() {
  //       exibirOcultarCampoUniforme = !exibirOcultarCampoUniforme;
  //     });
  //   }
  // }

  // Future<void> alertaExclusao(EscalaModelo escala, BuildContext context) async {
  //   return showDialog<void>(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text(
  //           Textos.tituloAlertaExclusao,
  //           style: const TextStyle(color: Colors.black),
  //         ),
  //         content: SingleChildScrollView(
  //           child: ListBody(
  //             children: <Widget>[
  //               Text(
  //                 Textos.descricaoAlerta,
  //                 style: const TextStyle(color: Colors.black),
  //               ),
  //               const SizedBox(
  //                 height: 10,
  //               ),
  //               Wrap(
  //                 children: [
  //                   Text(
  //                     escala.dataCulto,
  //                     style: const TextStyle(fontWeight: FontWeight.bold),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),
  //         actions: <Widget>[
  //           TextButton(
  //             child: const Text(
  //               'Não',
  //               style: TextStyle(color: Colors.black),
  //             ),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //           TextButton(
  //             child: const Text(
  //               'Sim',
  //               style: TextStyle(color: Colors.black),
  //             ),
  //             onPressed: () {
  //               setState(() {
  //                 exibirWidgetCarregamento = true;
  //               });
  //               chamarDeletar(escala);
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  Widget botoesAreaPesquisa(
    IconData icone,
    Color corBotao,
    double largura,
    double altura,
  ) => SizedBox(
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
              nomeReacar = nomePesquisa.text;
            });
          }
        } else {
          setState(() {
            exibirBarraPesquisa = false;
            nomeReacar = "";
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
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
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
                                            ? alturaTela * 0.55
                                            : alturaTela * 0.5,
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
                                          children: [
                                            DataTable(
                                              columnSpacing: 10,
                                              columns: cabecalho,
                                              rows: linhas,
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
                                              ? larguraTela * 0.9
                                              : larguraTela * 0.3,
                                      child: Card(
                                        color: Colors.transparent,
                                        elevation: 0,
                                        child: Column(
                                          children: [
                                            // Padding(
                                            //   padding: EdgeInsets.all(10),
                                            //   child: Text(
                                            //     Textos.telaFiltragemDescricao,
                                            //     textAlign: TextAlign.center,
                                            //   ),
                                            // ),
                                            Row(
                                              children: [
                                                Container(
                                                  width: 300,
                                                  height: 50,
                                                  color: Colors.white,
                                                  child: TextFormField(
                                                    validator: (value) {
                                                      if (value!.isEmpty) {
                                                        return Textos.erroCampoVazio;
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                ),
                                                // Container(
                                                //   height: 200,
                                                //   width: larguraTela,
                                                //   child: Center(
                                                //     child: GridView.builder(
                                                //       itemCount:
                                                //           quantidadeRepeticaoNome
                                                //               .length,
                                                //       gridDelegate:
                                                //           SliverGridDelegateWithFixedCrossAxisCount(
                                                //             crossAxisCount:
                                                //                 Platform.isAndroid ||
                                                //                         Platform
                                                //                             .isIOS
                                                //                     ? 3
                                                //                     : 4,
                                                //           ),
                                                //       itemBuilder: (
                                                //         context,
                                                //         index,
                                                //       ) {
                                                //         return Container(
                                                //           height: 100,
                                                //           margin:
                                                //               EdgeInsets.symmetric(
                                                //                 vertical: 5,
                                                //                 horizontal: 5,
                                                //               ),
                                                //           child: FloatingActionButton(
                                                //             heroTag:
                                                //                 quantidadeRepeticaoNome
                                                //                     .keys
                                                //                     .elementAt(
                                                //                       index,
                                                //                     )
                                                //                     .toString(),
                                                //             onPressed: () {
                                                //               setState(() {
                                                //                 exibirOcultarTelaQuantiRepeticaoNomes =
                                                //                     false;
                                                //                 nomeReacar = "";
                                                //                 nomeReacar =
                                                //                     quantidadeRepeticaoNome
                                                //                         .keys
                                                //                         .elementAt(
                                                //                           index,
                                                //                         );
                                                //                 print(
                                                //                   nomeReacar,
                                                //                 );
                                                //               });
                                                //             },
                                                //             child: Wrap(
                                                //               alignment:
                                                //                   WrapAlignment
                                                //                       .center,
                                                //               children: [
                                                //                 Text(
                                                //                   textAlign:
                                                //                       TextAlign
                                                //                           .center,
                                                //                   " ${quantidadeRepeticaoNome.keys.elementAt(index)}",
                                                //                   style: TextStyle(
                                                //                     color:
                                                //                         Colors
                                                //                             .black,
                                                //                   ),
                                                //                 ),
                                                //                 Text(
                                                //                   textAlign:
                                                //                       TextAlign
                                                //                           .center,
                                                //                   ": ${quantidadeRepeticaoNome.values.elementAt(index).toString()}",
                                                //                   style: TextStyle(
                                                //                     fontWeight:
                                                //                         FontWeight
                                                //                             .bold,
                                                //                     color:
                                                //                         Colors
                                                //                             .black,
                                                //                   ),
                                                //                 ),
                                                //               ],
                                                //             ),
                                                //           ),
                                                //         );
                                                //       },
                                                //     ),
                                                //   ),
                                                // ),
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
                              // botoesSwitch(Textos.labelSwitchUniforme,
                              //     exibirOcultarCampoUniforme),
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
