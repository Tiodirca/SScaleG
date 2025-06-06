import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sscaleg/uteis/constantes.dart';
import 'package:sscaleg/uteis/estilo.dart';
import 'package:sscaleg/uteis/paleta_cores.dart';
import 'package:sscaleg/uteis/textos.dart';
import 'package:sscaleg/Widgets/tela_carregamento.dart';
import 'package:sscaleg/modelo/tabelas_modelo.dart';

class TelaListagemTabelasBancoDados extends StatefulWidget {
  const TelaListagemTabelasBancoDados({super.key});

  @override
  State<TelaListagemTabelasBancoDados> createState() =>
      _TelaListagemTabelasBancoDadosState();
}

class _TelaListagemTabelasBancoDadosState
    extends State<TelaListagemTabelasBancoDados> {
  String nomeItemDrop = "";
  String idTabelaSelecionada = "";
  String nomeTabelaSelecionada = "";
  bool exibirConfirmacaoTabelaSelecionada = false;
  Estilo estilo = Estilo();
  bool exibirWidgetCarregamento = true;
  List<TabelaModelo> tabelasBancoDados = [];

  @override
  void initState() {
    super.initState();
    chamarConsultarTabelas();
  }

  chamarConsultarTabelas() async {
    tabelasBancoDados = await consultarTabelas();
    if (tabelasBancoDados.isEmpty) {
      setState(() {
        nomeItemDrop = "";
        exibirWidgetCarregamento = false;
      });
    } else {
      setState(() {
        nomeItemDrop = tabelasBancoDados.first.nomeTabela;
        exibirWidgetCarregamento = false;
      });
    }
  }

  static Future consultarTabelas() async {
    List<TabelaModelo> tabelasBancoDados = [];
    var db = FirebaseFirestore.instance;
    await db.collection(Constantes.fireBaseColecaoEscalas).get().then((event) {
      for (var doc in event.docs) {
        var nomeTabela = doc
            .data()
            .values
            .toString()
            .replaceAll("(", "")
            .replaceAll(")", "");
        tabelasBancoDados.add(
          TabelaModelo(nomeTabela: nomeTabela, idTabela: doc.id),
        );
      }
    });
    return tabelasBancoDados;
  }

  Future<void> alertaExclusao(BuildContext context) async {
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
                      nomeTabelaSelecionada,
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
                chamarDeletar();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Metodo para chamar deletar tabela
  chamarDeletar() async {
    setState(() {
      exibirWidgetCarregamento = true;
    });
    String retornoIdDocumentoFireBase =
        await realizarConsultaDocumentoFirebase();
    var db = FirebaseFirestore.instance;
    excluirDadosColecaoDocumento(retornoIdDocumentoFireBase);
    db
        .collection(Constantes.fireBaseColecaoEscalas)
        .doc(retornoIdDocumentoFireBase)
        .delete()
        .then((doc) {
          setState(() {
            tabelasBancoDados = [];
            nomeItemDrop = "";
            nomeTabelaSelecionada = "";
            exibirConfirmacaoTabelaSelecionada = false;
          });
          // MetodosAuxiliares.exibirMensagens(Textos.sucessoMsgExcluirEscala,
          //     Textos.tipoNotificacaoSucesso, context);
          chamarConsultarTabelas();
        }, onError: (e) {});
  }

  realizarConsultaDocumentoFirebase() async {
    String idDocumentoFirebase = "";

    var db = FirebaseFirestore.instance;
    //consultando id do documento no firebase para posteriormente excluir
    await db
        .collection(Constantes.fireBaseColecaoEscalas)
        .where(Constantes.fireBaseDocumentoNomeEscalas)
        .get()
        .then((querySnapshot) {
          for (var docSnapshot in querySnapshot.docs) {
            if (docSnapshot.data().values.contains(nomeTabelaSelecionada)) {
              idDocumentoFirebase = docSnapshot.id;
            }
          }
        });
    return idDocumentoFirebase;
  }

  // metodo para excluir a colecao dentro do documento
  // antes de excluir o documento
  excluirDadosColecaoDocumento(String idDocumentoFirebase) async {
    var db = FirebaseFirestore.instance;
    //consultando id do documento no firebase para posteriormente excluir
    await db
        .collection(Constantes.fireBaseColecaoEscalas)
        .doc(idDocumentoFirebase)
        .collection(Constantes.fireBaseDadosCadastrados)
        .get()
        .then((querySnapshot) {
          // para cada iteracao do FOR excluir o
          // item corresponde ao ID da iteracao
          for (var docSnapshot in querySnapshot.docs) {
            db
                .collection(Constantes.fireBaseColecaoEscalas)
                .doc(idDocumentoFirebase)
                .collection(Constantes.fireBaseDadosCadastrados)
                .doc(docSnapshot.id)
                .delete();
          }
        });
  }

  Widget botoesAcoes(
    String nomeBotao,
    IconData icone,
    Color corBotao,
    double largura,
    double altura,
  ) => SizedBox(
    height: altura,
    width: largura,
    child: FloatingActionButton(
      heroTag: nomeBotao,
      elevation: 0,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: corBotao),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      onPressed: () async {
        if (nomeBotao == Textos.btnCriarEscala) {
          Navigator.pushReplacementNamed(
            context,
            Constantes.rotaTelaCadastroSelecaoLocalTrabalho,
          );
        } else if (nomeBotao == Textos.btnRecarregar) {
          setState(() {
            exibirWidgetCarregamento = true;
          });
          chamarConsultarTabelas();
        } else {
          alertaExclusao(context);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, color: PaletaCores.corAzulMagenta, size: 30),
          LayoutBuilder(
            builder: (context, constraints) {
              if (nomeBotao == Textos.btnExcluir) {
                return Container();
              } else {
                return Text(
                  nomeBotao,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: PaletaCores.corAzulMagenta,
                  ),
                );
              }
            },
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    double larguraTela = MediaQuery.of(context).size.width;
    double alturaTela = MediaQuery.of(context).size.height;
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
                  title: Text(Textos.btnListarEscalas),
                  leading: IconButton(
                    color: Colors.white,
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        Constantes.rotaTelaInicial,
                      );
                    },
                    icon: const Icon(Icons.arrow_back_ios),
                  ),
                ),
                body: LayoutBuilder(
                  builder: (context, constraints) {
                    if (tabelasBancoDados.isEmpty) {
                      return Container(
                        color: Colors.white,
                        width: larguraTela,
                        height: alturaTela,
                        child: Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 20,
                              ),
                              width: larguraTela * 0.5,
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
                                  Textos.btnCriarEscala,
                                  Constantes.iconeAdicionar,
                                  PaletaCores.corCastanho,
                                  100,
                                  60,
                                ),
                                botoesAcoes(
                                  Textos.btnRecarregar,
                                  Constantes.iconeRecarregar,
                                  PaletaCores.corCastanho,
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
                        child: Column(
                          children: [
                            SizedBox(
                              width: larguraTela,
                              child: Text(
                                textAlign: TextAlign.center,
                                Textos.descricaoDropDownTabelas,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                            DropdownButton(
                              value: nomeItemDrop,
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                size: 40,
                                color: Colors.black,
                              ),
                              items:
                                  tabelasBancoDados
                                      .map(
                                        (item) => DropdownMenuItem<String>(
                                          value: item.nomeTabela,
                                          child: Text(
                                            item.nomeTabela.toString(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.normal,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (String? value) {
                                setState(() {
                                  nomeItemDrop = value!;
                                  nomeTabelaSelecionada = nomeItemDrop;
                                  for (var element in tabelasBancoDados) {
                                    if (element.nomeTabela.contains(
                                      nomeTabelaSelecionada,
                                    )) {
                                      idTabelaSelecionada = element.idTabela;
                                    }
                                  }
                                  exibirConfirmacaoTabelaSelecionada = true;
                                });
                              },
                            ),
                            Visibility(
                              visible: exibirConfirmacaoTabelaSelecionada,
                              child: Container(
                                margin: const EdgeInsets.all(10),
                                width: larguraTela,
                                child: Column(
                                  children: [
                                    Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        Text(
                                          textAlign: TextAlign.center,
                                          Textos.descricaoTabelaSelecionada,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                        Text(
                                          textAlign: TextAlign.center,
                                          nomeTabelaSelecionada,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                          ),
                                          child: botoesAcoes(
                                            Textos.btnExcluir,
                                            Constantes.iconeExclusao,
                                            PaletaCores.corRosaAvermelhado,
                                            40,
                                            40,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      margin: const EdgeInsets.all(20),
                                      width: 200,
                                      height: 50,
                                      child: ElevatedButton(
                                        child: Text(
                                          Textos.btnUsarEscala,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                            fontSize: 18,
                                          ),
                                        ),
                                        onPressed: () {
                                          var dados = {};
                                          dados[Constantes
                                                  .rotaArgumentEscalaDetalhadaNomeEscala] =
                                              nomeTabelaSelecionada;
                                          dados[Constantes
                                                  .rotaArgumentoEscalaDetalhadaIDEscalaSelecionada] =
                                              idTabelaSelecionada;
                                          Navigator.pushReplacementNamed(
                                            context,
                                            Constantes.rotaTelaEscalaDetalhada,
                                            arguments: dados,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
