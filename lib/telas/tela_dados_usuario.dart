import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sscaleg/Uteis/paleta_cores.dart';
import 'package:sscaleg/Widgets/tela_carregamento.dart';
import 'package:sscaleg/uteis/constantes.dart';
import 'package:sscaleg/uteis/estilo.dart';
import 'package:sscaleg/uteis/usuario/exclusao_dados.dart';
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
  bool edicaoEmailAtiva = false;
  bool edicaoSenhaAtiva = false;
  String tipoAcaoAutenticar = "";
  String emailAlteracao = "";
  IconData iconeExibirSenha = Icons.visibility;
  TextEditingController controleEmail = TextEditingController(text: "");
  TextEditingController controleSenha = TextEditingController(text: "");
  TextEditingController controleSenhaAutenticacao = TextEditingController(
    text: "",
  );

  final formularioSenhaNova = GlobalKey<FormState>();
  final formularioEmailNovo = GlobalKey<FormState>();
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
  String nomeCampoEmailAlterado = Constantes.fireBaseCampoUsuarioEmailAlterado;
  String uidUsuario = "";
  String senhaUsuario = "";

  @override
  void initState() {
    setState(() {
      exibirWidgetCarregamento = true;
    });
    super.initState();
    emailCadastrado =
        PassarPegarDados.recuperarInformacoesUsuario().entries.last.value;
    uidUsuario =
        PassarPegarDados.recuperarInformacoesUsuario().entries.first.value;
    print(PassarPegarDados.recuperarInformacoesUsuario());
    controleEmail.text = emailCadastrado;
    consultarEmailAlterado();
  }

  consultarEmailAlterado() async {
    var db = FirebaseFirestore.instance;
    await db
        .collection(nomeColecaoUsuariosFireBase) // passando a colecao
        .doc(uidUsuario)
        .get()
        .then((event) {
      setState(() {
        exibirWidgetCarregamento = false;
        emailAlteracao = event
            .data()!
            .values
            .toString()
            .replaceAll("(", "")
            .replaceAll(")", "");
      });
    });
  }

  chamarSairConta() async {
    await FirebaseAuth.instance.signOut();
    redirecionarTelaLoginCadastro();
  }

  redirecionarTelaLoginCadastro() {
    Navigator.pushReplacementNamed(context, Constantes.rotaTelaLoginCadastro);
  }

  redirecionarTelaSplash() {
    Navigator.pushReplacementNamed(context, Constantes.rotaTelaSplash);
  }

  recarregarTela() {
    Timer(const Duration(seconds: 1), () {
      Navigator.pushReplacementNamed(context, Constantes.rotaTelaDadosUsuario);
    });
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

  //metodo para autenticar o usuario antes de fazer uma acao critica
  // como excluir a conta, alterar senha ou email
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
              validarAcaoAutenticacao();
            });
          },
          onError: (e) {
            setState(() {
              chamarValidarErro(e.toString());
              exibirWidgetCarregamento = false;
            });
          },
        );
  }

  chamarValidarErro(String erro) {
    MetodosAuxiliares.validarErro(erro, context);
  }

  validarAcaoAutenticacao() {
    if (tipoAcaoAutenticar == Constantes.acaoAutenticarExcluirConta) {
      chamarDeletarDados();
    } else if (tipoAcaoAutenticar == Constantes.acaoAutenticarAlterarSenha) {
      chamarAlterarSenha();
    } else if (tipoAcaoAutenticar == Constantes.acaoAutenticarAlterarEmail) {
      chamarAlterarEmail();
    } else if (tipoAcaoAutenticar == Constantes.acaoAutenticarReenviarEmail) {
      reenviarEmailAlteracao();
    }
  }

  //metodo para alterar a senha da conta do usuario
  chamarAlterarSenha() {
    if (FirebaseAuth.instance.currentUser != null) {
      FirebaseAuth.instance.currentUser
          ?.updatePassword(controleSenha.text)
          .then(
            (value) {
              chamarExibirMensagemSucesso(Textos.notificacaoSucesso);
              recarregarTela();
            },
            onError: (e) {
              setState(() {
                exibirWidgetCarregamento = false;
                chamarValidarErro(e.toString());
              });
              debugPrint("SENHA ${e.toString()}");
            },
          );
    }
  }

  //metodo para alterar o email da conta do usuario
  chamarAlterarEmail() {
    if (FirebaseAuth.instance.currentUser != null) {
      FirebaseAuth.instance.currentUser
          ?.verifyBeforeUpdateEmail(controleEmail.text)
          .then(
            (value) {
              gravarEmailAlteradoValidacao(uidUsuario);
            },
            onError: (e) {
              setState(() {
                exibirWidgetCarregamento = false;
                chamarValidarErro(e.toString());
              });
              debugPrint("Email ${e.toString()}");
            },
          );
    }
  }

  gravarEmailAlteradoValidacao(String uid) async {
    try {
      // instanciando Firebase
      var db = FirebaseFirestore.instance;
      db
          .collection(nomeColecaoUsuariosFireBase)
          .doc(uid)
          .set({nomeCampoEmailAlterado: controleEmail.text})
          .then(
            (value) {
              setState(() {
                exibirWidgetCarregamento = false;
              });
              //redirecionarTelaSplash();
              //chamarExibirMensagemSucesso(Textos.notificacaoSucesso);
              //recarregarTela();
            },
            onError: (e) {
              debugPrint(e.toString());
            },
          );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  //metodo para reenviar o link de alteracao do email
  reenviarEmailAlteracao() {
    if (FirebaseAuth.instance.currentUser != null) {
      FirebaseAuth.instance.currentUser
          ?.verifyBeforeUpdateEmail(emailAlteracao)
          .then(
            (value) {
              chamarExibirMensagemSucesso(Textos.notificacaoSucesso);
              setState(() {
                exibirWidgetCarregamento = false;
              });
            },
            onError: (e) {
              debugPrint("Reenvio de Email ${e.toString()}");
              chamarValidarErro("Reenvio de Email : ${e.toString()}");
            },
          );
    }
  }

  chamarDeletarDados() async {
    bool retornoLocal = await ExclusaoDados.chamarDeletarItemAItem(
      nomeColecaoFireBaseLocal,
      uidUsuario,
    );
    bool retornoVoluntario = await ExclusaoDados.chamarDeletarItemAItem(
      nomeColecaoFireBaseVoluntario,
      uidUsuario,
    );
    bool retornoObservacao = await ExclusaoDados.chamarDeletarItemAItem(
      nomeColecaoFireBaseObservacao,
      uidUsuario,
    );
    bool retornoCabecalhoPDF = await ExclusaoDados.chamarDeletarItemAItem(
      nomeColecaoFireBaseCabecalhoPDF,
      uidUsuario,
    );
    bool retornoDepartamentoData = await ExclusaoDados.chamarDeletarItemAItem(
      nomeColecaoFireBaseDepartamentoData,
      uidUsuario,
    );
    bool retornoEscalas = await ExclusaoDados.buscarDadosDentroEscala(
      uidUsuario,
    );
    if (retornoLocal &&
        retornoVoluntario &&
        retornoObservacao &&
        retornoCabecalhoPDF &&
        retornoEscalas &&
        retornoDepartamentoData) {
      chamarDeletarUsuario();
    } else {
      chamarValidarErro(Textos.notificacaoErro);
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
            chamarValidarErro(e.toString());
            exibirWidgetCarregamento = false;
          });
        },
      );
    }
  }

  Future<void> alerta(
    String tituloAlerta,
    String descricaoAlerta,
    String tipoAutenticacao,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            tituloAlerta,
            style: const TextStyle(color: Colors.black),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  descricaoAlerta,
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 10),
                Wrap(
                  children: [
                    Text(
                      tipoAutenticacao == Constantes.acaoAutenticarAlterarSenha
                          ? emailCadastrado
                          : controleEmail.text,
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
                  tipoAcaoAutenticar = tipoAutenticacao;
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

  Widget camposFormularioEmail(
    String label,
    TextEditingController controle,
    IconData icone,
  ) => SizedBox(
    width: 300,
    height: 70,
    child: TextFormField(
      enabled: edicaoEmailAtiva,
      controller: controle,
      validator: (value) {
        if (value!.isEmpty) {
          return Textos.erroCampoVazio;
        }
        return null;
      },
      keyboardType: TextInputType.text,
      decoration: InputDecoration(prefixIcon: Icon(icone), label: Text(label)),
    ),
  );

  Widget camposFormularioSenha(
    String label,
    TextEditingController controle,
    IconData icone,
  ) => SizedBox(
    width: 300,
    height: 70,
    child: TextFormField(
      controller: controle,
      validator: (value) {
        if (value!.isEmpty) {
          return Textos.erroCampoVazio;
        }
        return null;
      },
      keyboardType: TextInputType.text,
      obscureText: exibirOcultarSenha,
      decoration: InputDecoration(
        prefixIcon: Icon(icone),
        label: Text(label),
        suffixIcon: chamarExibicaoOcultarSenha(),
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
        label: Text(
          tipoAcaoAutenticar == Constantes.acaoAutenticarAlterarSenha
              ? Textos.labelSenhaAntiga
              : Textos.labelSenha,
        ),
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
          alerta(
            Textos.alertaExclusaoUsuario,
            Textos.descricaoAlertaExclusao,
            Constantes.acaoAutenticarExcluirConta,
          );
        } else if (nomeBtn == Textos.btnAlterarSenha) {
          setState(() {
            edicaoSenhaAtiva = true;
          });
        } else if (nomeBtn == Textos.btnSalvar) {
          validarTipoSalvarAlteracaoDado();
        } else if (nomeBtn == Textos.btnReenviarEmail) {
          setState(() {
            tipoAcaoAutenticar = Constantes.acaoAutenticarReenviarEmail;
            exibirOcultarTelaAutenticarUsuario = true;
          });
        }
      },
      child: Text(
        nomeBtn,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black),
      ),
    ),
  );

  validarTipoSalvarAlteracaoDado() {
    if (edicaoEmailAtiva) {
      if (formularioEmailNovo.currentState!.validate()) {
        alerta(
          Textos.tituloAlertaAlterarEmail,
          Textos.descricaoAlertaAlterarEmail,
          Constantes.acaoAutenticarAlterarEmail,
        );
      }
    } else {
      if (formularioSenhaNova.currentState!.validate()) {
        alerta(
          Textos.tituloAlertaAlterarSenha,
          Textos.descricaoAlertaAlterarSenha,
          Constantes.acaoAutenticarAlterarSenha,
        );
      }
    }
  }

  Widget botoesIcones(String label) => Container(
    margin: EdgeInsets.symmetric(horizontal: 10),
    height: 35,
    width: 35,
    child: FloatingActionButton(
      heroTag: label,
      onPressed: () async {
        if (label == Textos.labelEmail) {
          setState(() {
            edicaoEmailAtiva = true;
          });
        } else if (label == Textos.labelSenha) {
        } else if (label == Textos.btnExcluir) {
          setState(() {
            tipoAcaoAutenticar = "";
            exibirOcultarSenha = true;
            controleSenhaAutenticacao.clear();
            exibirOcultarTelaAutenticarUsuario = false;
            edicaoEmailAtiva = false;
            edicaoSenhaAtiva = false;
            controleEmail.text = emailCadastrado;
            controleSenha.clear();
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
                            height: 300,
                            child: Card(
                              child: Column(
                                children: [
                                  Container(
                                    margin: EdgeInsets.all(10),
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
                                key: formularioEmailNovo,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Visibility(
                                      visible: !edicaoSenhaAtiva,
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              camposFormularioEmail(
                                                Textos.labelEmail,
                                                controleEmail,
                                                Constantes.iconeEmail,
                                              ),
                                              botoesIcones(Textos.labelEmail),
                                            ],
                                          ),
                                          Visibility(
                                            visible:
                                                emailAlteracao.isNotEmpty &&
                                                        edicaoEmailAtiva ==
                                                            false
                                                    ? true
                                                    : false,
                                            child: Column(
                                              children: [
                                                SizedBox(
                                                  width: 400,
                                                  child: Text(
                                                    textAlign: TextAlign.center,
                                                    Textos
                                                        .telaDadosUsuarioEmailAlterado,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                Text(emailAlteracao),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Visibility(
                                      visible: edicaoSenhaAtiva,
                                      child: Column(
                                        children: [
                                          Form(
                                            key: formularioSenhaNova,
                                            child: camposFormularioSenha(
                                              Textos.labelSenhaNova,
                                              controleSenha,
                                              Constantes.iconeSenha,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        if (edicaoSenhaAtiva ||
                                            edicaoEmailAtiva) {
                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              botao(Textos.btnSalvar),
                                              botoesIcones(Textos.btnExcluir),
                                            ],
                                          );
                                        } else {
                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              botao(Textos.btnAlterarSenha),
                                              Visibility(
                                                visible:
                                                    emailAlteracao.isNotEmpty
                                                        ? true
                                                        : false,
                                                child: botao(
                                                  Textos.btnReenviarEmail,
                                                ),
                                              ),
                                            ],
                                          );
                                        }
                                      },
                                    ),
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
