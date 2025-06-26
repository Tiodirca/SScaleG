import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

class TelaDadosUsuario extends StatefulWidget {
  const TelaDadosUsuario({super.key});

  @override
  State<TelaDadosUsuario> createState() => _TelaDadosUsuarioState();
}

class _TelaDadosUsuarioState extends State<TelaDadosUsuario> {
  Estilo estilo = Estilo();
  bool exibirWidgetCarregamento = false;
  bool exibirOcultarSenha = true;
  bool exibirOcultarTelaAutenticarUsuario = false;
  bool edicaoAtiva = false;
  String tipoAcaoAutenticar = "";
  IconData iconeExibirSenha = Icons.visibility;
  TextEditingController controleEmail = TextEditingController(text: "");
  TextEditingController controleSenha = TextEditingController(text: "");
  TextEditingController controleSenhaAutenticacao = TextEditingController(
    text: "",
  );
  final _formKeyFormulario = GlobalKey<FormState>();
  final formularioSenhaAutenticar = GlobalKey<FormState>();
  String nomeColecaoUsuariosFireBase = Constantes.fireBaseColecaoUsuarios;
  String nomeColecaoFireBaseLocal =
      Constantes.fireBaseColecaoNomeLocaisTrabalho;
  String nomeColecaoFireBaseVoluntario =
      Constantes.fireBaseColecaoNomeVoluntarios;
  String nomeColecaoFireBaseObservacao =
      Constantes.fireBaseColecaoNomeObservacao;
  String nomeColecaoFireBaseCabecalhoPDF =
      Constantes.fireBaseColecaoNomeCabecalhoPDF;
  String nomeColecaoFireBaseEscalas = Constantes.fireBaseColecaoEscalas;
  String nomeColecaoFireBaseDepartamentoData =
      Constantes.fireBaseColecaoNomeDepartamentosData;
  String nomeDocumentoFireBaseEscalas = Constantes.fireBaseDadosCadastrados;
  String emailCadastrado = "";
  String uidUsuario = "";

  @override
  void initState() {
    super.initState();
    emailCadastrado =
        PassarPegarDados.recuperarInformacoesUsuario().entries.last.value;
    uidUsuario =
        PassarPegarDados.recuperarInformacoesUsuario().entries.first.value;
    controleEmail.text = emailCadastrado;
  }

  chamarSairConta() async {
    await FirebaseAuth.instance.signOut();
    redirecionarTelaLoginCadastro();
  }

  redirecionarTelaLoginCadastro() {
    Navigator.pushReplacementNamed(context, Constantes.rotaTelaLoginCadastro);
  }

  chamarExibicaoOcultarSenha() {
    return IconButton(
      onPressed: () {
        setState(() {
          if (exibirOcultarSenha) {
            setState(() {
              exibirOcultarSenha = false;
              iconeExibirSenha = Icons.visibility_off;
            });
          } else {
            setState(() {
              exibirOcultarSenha = true;
              iconeExibirSenha = Icons.visibility;
            });
          }
        });
      },
      icon: Icon(iconeExibirSenha),
    );
  }

  chamarExibirMensagemSucesso(String mensagem) {
    MetodosAuxiliares.exibirMensagens(
      Constantes.tipoNotificacaoSucesso,
      mensagem,
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

  chamarAutenticarUsuario() {
    setState(() {
      exibirWidgetCarregamento = true;
    });
    AuthCredential credential = EmailAuthProvider.credential(
      email: emailCadastrado,
      password: controleSenhaAutenticacao.text,
    );
    FirebaseAuth.instance
        .signInWithCredential(credential)
        .then(
          (value) {
            setState(() {
              exibirOcultarTelaAutenticarUsuario = false;
              exibirOcultarSenha = true;
              controleSenhaAutenticacao.clear();
              if (tipoAcaoAutenticar == Constantes.acaoAutenticarExcluirConta) {
                chamarDeletarDados();
              } else if (tipoAcaoAutenticar ==
                  Constantes.acaoAutenticarEditarConta) {}
            });
          },
          onError: (e) {
            setState(() {
              exibirWidgetCarregamento = false;
            });
            chamarExibirMensagemErro(
              "${Textos.notificacaoErro} : ${e.toString()}",
            );
          },
        );
  }

  chamarDeletarDados() async {
    bool retornoLocal = await chamarDeletarItemAItem(nomeColecaoFireBaseLocal);
    bool retornoVoluntario = await chamarDeletarItemAItem(
      nomeColecaoFireBaseVoluntario,
    );
    bool retornoObservacao = await chamarDeletarItemAItem(
      nomeColecaoFireBaseObservacao,
    );
    bool retornoCabecalhoPDF = await chamarDeletarItemAItem(
      nomeColecaoFireBaseCabecalhoPDF,
    );
    bool retornoDepartamentoData = await chamarDeletarItemAItem(
      nomeColecaoFireBaseDepartamentoData,
    );
    bool retornoEscalas = await buscarDadosDentroEscala();
    if (retornoLocal &&
        retornoVoluntario &&
        retornoObservacao &&
        retornoCabecalhoPDF &&
        retornoEscalas &&
        retornoDepartamentoData) {
      chamarDeletarUsuario();
    } else {
      chamarExibirMensagemErro(Textos.notificacaoErro);
    }
  }

  chamarDeletarUsuario() {
    if (FirebaseAuth.instance.currentUser != null) {
      //chama deletar usuario
      FirebaseAuth.instance.currentUser?.delete().then(
        (value) {
          chamarExibirMensagemSucesso(Textos.notificacaoSucesso);
          chamarSairConta();
        },
        onError: (e) {
          setState(() {
            chamarExibirMensagemErro(e.toString());
            exibirWidgetCarregamento = false;
          });
        },
      );
    }
  }

  Future<bool> buscarDadosDentroEscala() async {
    bool retorno = false;
    try {
      var db = FirebaseFirestore.instance;
      await db
          .collection(nomeColecaoUsuariosFireBase) // passando a colecao
          .doc(uidUsuario)
          .collection(nomeColecaoFireBaseEscalas)
          .where(Constantes.fireBaseDocumentoNomeEscalas)
          .get()
          .then(
            (querySnapshot) async {
              for (var docSnapshot in querySnapshot.docs) {
                //deletando o CAMPO de CADA ID para poder excluir a colecao
                db
                    .collection(
                      nomeColecaoUsuariosFireBase,
                    ) // passando a colecao
                    .doc(uidUsuario)
                    .collection(nomeColecaoFireBaseEscalas)
                    .doc(docSnapshot.id)
                    .delete()
                    .then(
                      (value) {
                        retorno = true;
                      },
                      onError: (e) {
                        retorno = false;
                        debugPrint("Erro Excluir: ${e.toString()}");
                      },
                    );
                retorno = await excluirDadosColecaoDocumentoDentroEscala(
                  docSnapshot.id,
                );
              }
              retorno = true;
            },
            onError: (e) {
              retorno = false;
              debugPrint("Erro : ${e.toString()}");
            },
          );
    } catch (e) {
      retorno = false;
      debugPrint("Erro : ${e.toString()}");
    }
    return retorno;
  }

  //metodo para percorrer cadas ESCALA EXCLUINDO CADA ELEMENTO DENTRO DELA
  Future<bool> excluirDadosColecaoDocumentoDentroEscala(
    String idDocumentoFirebase,
  ) async {
    int index = 0;
    bool retornoFinalizacaoExclusao = false;
    try {
      var db = FirebaseFirestore.instance;
      await db
          .collection(nomeColecaoUsuariosFireBase) // passando a colecao
          .doc(uidUsuario)
          .collection(nomeColecaoFireBaseEscalas)
          .doc(idDocumentoFirebase)
          .collection(nomeDocumentoFireBaseEscalas)
          .get()
          .then(
            (querySnapshot) {
              // para cada iteracao do FOR excluir o
              // item corresponde ao ID da iteracao
              for (var docSnapshot in querySnapshot.docs) {
                db
                    .collection(
                      nomeColecaoUsuariosFireBase,
                    ) // passando a colecao
                    .doc(uidUsuario)
                    .collection(nomeColecaoFireBaseEscalas)
                    .doc(idDocumentoFirebase)
                    .collection(nomeDocumentoFireBaseEscalas)
                    .doc(docSnapshot.id)
                    .delete()
                    .then(
                      (value) {
                        index++;
                        if (index == querySnapshot.size) {
                          retornoFinalizacaoExclusao = true;
                        }
                      },
                      onError: (e) {
                        retornoFinalizacaoExclusao = false;
                        debugPrint(
                          "Erro Excluir Item a item Tabela : ${e.toString()}",
                        );
                      },
                    );
              }
            },
            onError: (e) {
              retornoFinalizacaoExclusao = false;
              debugPrint("Erro Excluir Item a item Tabela : ${e.toString()}");
            },
          );
    } catch (e) {
      retornoFinalizacaoExclusao = false;
      debugPrint("Erro Excluir Item a item Tabela : ${e.toString()}");
    }
    return retornoFinalizacaoExclusao;
  }

  Future<bool> chamarDeletarItemAItem(String nomeColecao) async {
    bool retorno = false;
    var db = FirebaseFirestore.instance;
    await db
        .collection(nomeColecaoUsuariosFireBase)
        .doc(uidUsuario)
        .collection(nomeColecao)
        .get()
        .then(
          (querySnapshot) {
            //para cada iteracao do FOR excluir o
            //item corresponde ao ID da iteracao
            for (var docSnapshot in querySnapshot.docs) {
              db
                  .collection(nomeColecaoUsuariosFireBase)
                  .doc(uidUsuario)
                  .collection(nomeColecao)
                  .doc(docSnapshot.id)
                  .delete()
                  .then(
                    (value) {
                      retorno = true;
                    },
                    onError: (e) {
                      debugPrint("Erro Excluir Item a item : ${e.toString()}");
                    },
                  );
            }
            retorno = true;
          },
          onError: (e) {
            debugPrint("Erro Excluir Item a item : ${e.toString()}");
            retorno = false;
          },
        );
    return retorno;
  }

  Future<void> alertaExclusao() async {
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
                  Textos.alertaExclusaoUsuario,
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 10),
                Wrap(
                  children: [
                    Text(
                      emailCadastrado,
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
                  tipoAcaoAutenticar = Constantes.acaoAutenticarExcluirConta;
                  exibirOcultarTelaAutenticarUsuario = true;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget camposFormulario(
    String label,
    TextEditingController controle,
    IconData icone,
  ) => SizedBox(
    width: 300,
    height: 70,
    child: TextFormField(
      enabled: edicaoAtiva,
      controller: controle,
      validator: (value) {
        if (value!.isEmpty) {
          return Textos.erroCampoVazio;
        }
        return null;
      },
      keyboardType: TextInputType.text,
      obscureText: label == Textos.labelSenha ? exibirOcultarSenha : false,
      decoration: InputDecoration(
        prefixIcon: Icon(icone),
        label: Text(label),
        suffixIcon:
            label == Textos.labelSenha ? chamarExibicaoOcultarSenha() : null,
      ),
    ),
  );

  Widget campoSenhaAutenticar() => SizedBox(
    width: 300,
    height: 70,
    child: TextFormField(
      controller: controleSenhaAutenticacao,
      validator: (value) {
        if (value!.isEmpty) {
          return Textos.erroCampoVazio;
        }
        return null;
      },
      keyboardType: TextInputType.text,
      obscureText: exibirOcultarSenha,
      decoration: InputDecoration(
        prefixIcon: Icon(Constantes.iconeSenha),
        label: Text(Textos.labelSenha),
        suffixIcon: chamarExibicaoOcultarSenha(),
      ),
    ),
  );

  Widget botao(String nomeBtn) => Container(
    margin: const EdgeInsets.all(10),
    width: 100,
    height: 40,
    child: FloatingActionButton(
      heroTag: nomeBtn,
      onPressed: () {
        if (nomeBtn == Textos.btnSairConta) {
          chamarSairConta();
        } else if (nomeBtn == Textos.btnAutenticar) {
          if (formularioSenhaAutenticar.currentState!.validate()) {
            chamarAutenticarUsuario();
          }
        } else if (nomeBtn == Textos.btnExcluirConta) {
          alertaExclusao();
        }
      },
      child: Text(
        nomeBtn,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black),
      ),
    ),
  );

  Widget botoesIcones(String label) => Container(
    margin: EdgeInsets.symmetric(horizontal: 10),
    height: 35,
    width: 35,
    child: FloatingActionButton(
      heroTag: label,
      onPressed: () async {
        if (label == Textos.labelEmail) {
        } else if (label == Textos.labelSenha) {
        } else if (label == Textos.btnExcluir) {
          setState(() {
            tipoAcaoAutenticar = "";
            exibirOcultarSenha = true;
            controleSenhaAutenticacao.clear();
            exibirOcultarTelaAutenticarUsuario = false;
            edicaoAtiva = false;
          });
        }
      },
      child: Icon(
        label != Constantes.excluir
            ? Constantes.iconeEditar
            : Constantes.iconeExclusao,
        color: PaletaCores.corAzulEscuro,
        size: 30,
      ),
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
                  title: Text(Textos.telaDadosUsuarioTitulo),
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
                body: Container(
                  color: Colors.white,
                  width: larguraTela,
                  height: alturaTela,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (exibirOcultarTelaAutenticarUsuario) {
                          return SizedBox(
                            width: larguraTela,
                            height: 300,
                            child: Card(
                              child: Column(
                                children: [
                                  Container(
                                    margin: EdgeInsets.all(10),
                                    width: larguraTela,
                                    child: Text(
                                      Textos
                                          .telaDadosUsuarioAutenticarDescricao,
                                      style: const TextStyle(fontSize: 18),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Form(
                                    key: formularioSenhaAutenticar,
                                    child: campoSenhaAutenticar(),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      botao(Textos.btnAutenticar),
                                      botoesIcones(Textos.btnExcluir),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          return Column(
                            children: [
                              Container(
                                margin: EdgeInsets.all(10),
                                width: larguraTela,
                                child: Text(
                                  Textos.telaDadosUsuarioDescricao,
                                  style: const TextStyle(fontSize: 18),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Form(
                                key: _formKeyFormulario,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        camposFormulario(
                                          Textos.labelEmail,
                                          controleEmail,
                                          Constantes.iconeEmail,
                                        ),
                                        botoesIcones(Textos.labelEmail),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        camposFormulario(
                                          Textos.labelSenha,
                                          controleSenha,
                                          Constantes.iconeSenha,
                                        ),
                                        botoesIcones(Textos.labelSenha),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Visibility(
                                visible: edicaoAtiva,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    botao(Textos.btnSalvar),
                                    botoesIcones(Textos.btnExcluir),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                ),
                bottomNavigationBar: Container(
                  width: larguraTela,
                  color: Colors.white,
                  height: 120,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Visibility(
                        visible: !exibirOcultarTelaAutenticarUsuario,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            botao(Textos.btnSairConta),
                            botao(Textos.btnExcluirConta),
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
