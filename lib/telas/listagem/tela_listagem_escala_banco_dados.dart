import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sscaleg/uteis/constantes.dart';
import 'package:sscaleg/uteis/estilo.dart';
import 'package:sscaleg/uteis/metodos_auxiliares.dart';
import 'package:sscaleg/uteis/paleta_cores.dart';
import 'package:sscaleg/uteis/passar_pegar_dados.dart';
import 'package:sscaleg/uteis/textos.dart';
import 'package:sscaleg/Widgets/tela_carregamento.dart';
import 'package:sscaleg/modelo/tabelas_modelo.dart';
import 'package:sscaleg/widgets/barra_navegacao_widget.dart';

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
  String uidUsuario = "";
  String nomeColecaoUsuariosFireBase = Constantes.fireBaseColecaoUsuarios;

  @override
  void initState() {
    super.initState();
    uidUsuario =
        PassarPegarDados.recuperarInformacoesUsuario().entries.first.value;
    Timer(const Duration(seconds: 1), () {
      chamarConsultarTabelas();
    });
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

  Future consultarTabelas() async {
    List<TabelaModelo> tabelasBancoDados = [];
    var db = FirebaseFirestore.instance;
    await db
        .collection(nomeColecaoUsuariosFireBase) // passando a colecao
        .doc(uidUsuario)
        .collection(Constantes.fireBaseColecaoEscalas)
        .get()
        .then((event) {
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
        .collection(nomeColecaoUsuariosFireBase) // passando a colecao
        .doc(uidUsuario)
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
          chamarExibirMensagemSucesso();
          chamarConsultarTabelas();
        }, onError: (e) {});
  }

  chamarExibirMensagemSucesso() {
    MetodosAuxiliares.exibirMensagens(
      Constantes.tipoNotificacaoSucesso,
      Textos.notificacaoSucesso,
      context,
    );
  }

  realizarConsultaDocumentoFirebase() async {
    String idDocumentoFirebase = "";

    var db = FirebaseFirestore.instance;
    //consultando id do documento no firebase para posteriormente excluir
    await db
        .collection(nomeColecaoUsuariosFireBase) // passando a colecao
        .doc(uidUsuario)
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
        .collection(nomeColecaoUsuariosFireBase) // passando a colecao
        .doc(uidUsuario)
        .collection(Constantes.fireBaseColecaoEscalas)
        .doc(idDocumentoFirebase)
        .collection(Constantes.fireBaseDadosCadastrados)
        .get()
        .then((querySnapshot) {
          // para cada iteracao do FOR excluir o
          // item corresponde ao ID da iteracao
          for (var docSnapshot in querySnapshot.docs) {
            db
                .collection(nomeColecaoUsuariosFireBase) // passando a colecao
                .doc(uidUsuario)
                .collection(Constantes.fireBaseColecaoEscalas)
                .doc(idDocumentoFirebase)
                .collection(Constantes.fireBaseDadosCadastrados)
                .doc(docSnapshot.id)
                .delete();
          }
        });
  }

  Widget botoesAcoes(String nomeBotao) => Container(
    margin: EdgeInsets.only(top: nomeBotao != Textos.btnExcluir ? 20 : 0),
    height: nomeBotao == Textos.btnExcluir ? 30 : 40,
    width: nomeBotao == Textos.btnExcluir ? 30 : 110,
    child: FloatingActionButton(
      shape: RoundedRectangleBorder(
        side: BorderSide(
          width: 1,
          color:
              nomeBotao == Textos.btnExcluir
                  ? PaletaCores.corRosaAvermelhado
                  : PaletaCores.corCastanho,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      heroTag: nomeBotao,
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
        } else if (nomeBotao == Textos.btnUsarEscala) {
          var dados = {};
          dados[Constantes.rotaArgumentoNomeEscala] = nomeTabelaSelecionada;
          dados[Constantes.rotaArgumentoIDEscalaSelecionada] =
              idTabelaSelecionada;
          Navigator.pushReplacementNamed(
            context,
            Constantes.rotaTelaEscalaDetalhada,
            arguments: dados,
          );
        } else {
          alertaExclusao(context);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (nomeBotao == Textos.btnExcluir) {
                return Icon(Constantes.iconeExclusao);
              } else {
                return Text(
                  nomeBotao,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black),
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
                                botoesAcoes(Textos.btnCriarEscala),
                                botoesAcoes(Textos.btnRecarregar),
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
                                style: const TextStyle(fontSize: 18),
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
                                              fontSize: 18,
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
                                          style: const TextStyle(fontSize: 18),
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
                                          child: botoesAcoes(Textos.btnExcluir),
                                        ),
                                      ],
                                    ),
                                    botoesAcoes(Textos.btnUsarEscala),
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
                bottomNavigationBar: Container(
                  color: Colors.white,
                  width: larguraTela,
                  child: BarraNavegacao(),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
