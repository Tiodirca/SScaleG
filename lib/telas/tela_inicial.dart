import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sscaleg/Uteis/paleta_cores.dart';
import 'package:sscaleg/uteis/constantes.dart';
import 'package:sscaleg/uteis/estilo.dart';
import 'package:sscaleg/uteis/passar_pegar_dados.dart';
import 'package:sscaleg/uteis/usuario/validar_alteracao_email.dart';
import 'package:sscaleg/widgets/tela_carregamento.dart';
import 'package:sscaleg/widgets/widget_ajustar_horario.dart';
import '../uteis/textos.dart';

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  Estilo estilo = Estilo();
  String uidUsuario = "";
  String emailCadastrado = "";
  String teste = "";
  bool exibirTelaCarregamento = true;
  bool exibirWidgetAjustarHorario = false;
  String nomeCampoEmailAlterado = Constantes.fireBaseCampoUsuarioEmailAlterado;
  String nomeColecaoUsuariosFireBase = Constantes.fireBaseColecaoUsuarios;

  @override
  void initState() {
    super.initState();
    emailCadastrado = PassarPegarDados.recuperarInformacoesUsuario().values
        .elementAt(1);
    chamarValidarConfirmacaoAlteracaoEmail(
      PassarPegarDados.recuperarInformacoesUsuario().values.elementAt(0),
    );
  }

  chamarValidarConfirmacaoAlteracaoEmail(String uid) async {
    String emailAlteracao = await ValidarAlteracaoEmail.consultarEmailAlterado(
      uid,
    );
    validarConfirmacaoAlteracaoEmail(uid, emailAlteracao);
  }

  validarConfirmacaoAlteracaoEmail(String uid, String emailAlteracao) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //recuperando senha do usuario gravada ao
    // fazer login,cadastro ou alteracao da senha
    String senhaUsuario = prefs.getString(Constantes.infoUsuarioSenha) ?? '';
    //fazendo autenticacao do usuario usando o email puxado do banco de dados para verificar
    // se houve confirmacao de alteracao de email
    AuthCredential credencial = EmailAuthProvider.credential(
      email: emailAlteracao,
      password: senhaUsuario,
    );
    try {
      //vazendo login utilizando as informacoes passadas no credencial
      FirebaseAuth.instance
          .signInWithCredential(credencial)
          .then(
            (value) {
              // caso a autenticacao seja VERDADEIRA sera feito
              // a atualizacao no banco de dados e redicionamento de tela
              if (mounted) {
                gravarEmailAlteradoBancoDados(uid, emailAlteracao);
              }
            },
            onError: (e) {
              setState(() {
                exibirTelaCarregamento = false;
              });
              debugPrint("o mesmo");
            },
          );
    } on FirebaseAuthException {
      setState(() {
        exibirTelaCarregamento = false;
      });
      debugPrint("Email mesmo");
    }
  }

  //metodo para gravar no bando de dados caso o
  // usuario tenha confirmado a alteracao de email
  gravarEmailAlteradoBancoDados(String uid, String emailAlteracao) async {
    try {
      // instanciando Firebase
      var db = FirebaseFirestore.instance;
      db
          .collection(nomeColecaoUsuariosFireBase)
          .doc(uid)
          // sera setado vazio no banco de dados
          .set({nomeCampoEmailAlterado: ""})
          .then(
            (value) {
              //redirecionar tela passando as seguintes informacoes
              setState(() {
                emailCadastrado = emailAlteracao;
                exibirTelaCarregamento = false;
                passarInformacoes(uid, emailAlteracao);
              });
            },
            onError: (e) {
              setState(() {
                exibirTelaCarregamento = false;
              });
              debugPrint(e.toString());
            },
          );
    } catch (e) {
      setState(() {
        exibirTelaCarregamento = false;
      });
      debugPrint(e.toString());
    }
  }

  passarInformacoes(String uid, String email) {
    Map dados = {};
    dados[Constantes.infoUsuarioUID] = uid;
    dados[Constantes.infoUsuarioEmail] = email;
    PassarPegarDados.passarInformacoesUsuario(dados);
  }

  Widget botao(String nomeBtn) => Container(
    margin: const EdgeInsets.all(10),
    width: 160,
    height: 40,
    child: FloatingActionButton(
      heroTag: nomeBtn,
      onPressed: () {
        if (nomeBtn == Textos.btnCriarEscala) {
          Navigator.pushReplacementNamed(
            context,
            Constantes.rotaTelaCadastroSelecaoLocalTrabalho,
          );
        } else if (nomeBtn == Textos.btnListarEscalas) {
          Navigator.pushReplacementNamed(
            context,
            Constantes.rotaTelaListagemEscalaBandoDados,
          );
        } else if (nomeBtn == Textos.btnDadosUsuario) {
          Navigator.pushReplacementNamed(
            context,
            Constantes.rotaTelaDadosUsuario,
          );
        }
      },
      child: Text(
        nomeBtn,
        textAlign: TextAlign.center,
        style: TextTheme.of(context).titleSmall,
        // style: TextStyle(fontSize: 18, color: Colors.black),
      ),
    ),
  );

  Widget botoesIcones(IconData icone) => Container(
    margin: EdgeInsets.symmetric(horizontal: 10),
    height: 40,
    width: 40,
    child: FloatingActionButton(
      heroTag: icone.toString(),
      onPressed: () async {
        if (icone == Constantes.iconeConfiguracao) {
          setState(() {
            exibirWidgetAjustarHorario = true;
          });
        } else if (icone == Constantes.iconeExclusao) {
          setState(() {
            exibirWidgetAjustarHorario = false;
          });
        }
      },
      child: Icon(icone, color: PaletaCores.corAzulEscuro, size: 30),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (exibirTelaCarregamento) {
            return TelaCarregamento();
          } else {
            return Scaffold(
              appBar: AppBar(
                title: Text(Textos.nomeApp),
                leading: const Image(
                  image: AssetImage('assets/imagens/Logo.png'),
                  width: 10,
                  height: 10,
                ),
                actions: [
                  botoesIcones(
                    exibirWidgetAjustarHorario == true
                        ? Constantes.iconeExclusao
                        : Constantes.iconeConfiguracao,
                  ),
                ],
              ),
              body: Container(
                width: larguraTela,
                height: alturaTela,
                color: Colors.white,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (exibirWidgetAjustarHorario) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          botao(Textos.btnDadosUsuario),
                          WidgetAjustarHorario(),
                        ],
                      );
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: larguraTela,
                            height: alturaTela * 0.7,
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              children: [
                                Container(
                                  margin: EdgeInsets.only(right: 10.0,bottom: 20),
                                  width: larguraTela,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        Textos.telaInicialEmailCadastrado,
                                        style: const TextStyle(fontSize: 14),
                                        textAlign: TextAlign.center,
                                      ),
                                      Text(
                                        emailCadastrado,
                                        style: TextTheme.of(context).titleSmall,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: larguraTela,
                                  child: Text(
                                    Textos.telaInicialDescricao,
                                    style: TextTheme.of(context).bodySmall,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                botao(Textos.btnCriarEscala),
                                botao(Textos.btnListarEscalas),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
              bottomNavigationBar: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                color: Colors.white,
                width: larguraTela,
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(Textos.versaoAppDescricao),
                    Text(
                      Textos.versaoAppNumero,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
