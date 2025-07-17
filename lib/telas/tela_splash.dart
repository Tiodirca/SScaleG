import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sscaleg/uteis/metodos_auxiliares.dart';
import 'package:sscaleg/uteis/passar_pegar_dados.dart';
import 'package:sscaleg/uteis/usuario/validar_alteracao_email.dart';
import '../Uteis/paleta_cores.dart';
import '../Widgets/tela_carregamento.dart';
import '../uteis/constantes.dart';

class TelaSplashScreen extends StatefulWidget {
  const TelaSplashScreen({super.key});

  @override
  State<TelaSplashScreen> createState() => _TelaSplashScreenState();
}

class _TelaSplashScreenState extends State<TelaSplashScreen> {
  late StreamSubscription<User?> validacao;
  int index = 0;
  String emailAlteracao = "";
  String usuarioEmail = "";
  String usuarioUID = "";
  String nomeCampoEmailAlterado = Constantes.fireBaseCampoUsuarioEmailAlterado;
  String nomeColecaoUsuariosFireBase = Constantes.fireBaseColecaoUsuarios;

  @override
  void initState() {
    super.initState();
    chamarMetodoGravarDadosSharePreferences();
    Timer(const Duration(seconds: 2), () {
      validarUsuarioLogado();
    });
  }

  validarUsuarioLogado() async {
    validacao = FirebaseAuth.instance.authStateChanges().listen((
      User? user,
    ) async {
      index++;
      if (index == 2 && (!Platform.isIOS || !Platform.isAndroid) ||
          index == 1 && (Platform.isIOS || Platform.isAndroid)) {
        index = 0;
        if (user != null) {
          debugPrint("Usuario Logado");
          usuarioEmail = user.email.toString();
          usuarioUID = user.uid.toString();
          emailAlteracao = await ValidarAlteracaoEmail.consultarEmailAlterado(
            user.uid,
          );
          passarInformacoes(usuarioUID, usuarioEmail);
          redirecionarTelaInicial();
          //print(emailAlteracao);
          //validarConfirmacaoAlteracaoEmail();
        } else {
          debugPrint("Sem Usuario Logado");
          redirecionarTelaLoginCadastro();
        }
      }
    });
  }

  validarConfirmacaoAlteracaoEmail() async {
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
                gravarEmailAlteradoBancoDados(usuarioUID);
              }
            },
            onError: (e) {
              // caso de erro quer dizer que o usuario ainda nao confirmou a alteracao de de email
              // por isso redicionar a tela passando as seguintes informacoes
              if (mounted) {
                passarInformacoes(usuarioUID, usuarioEmail);
                redirecionarTelaInicial();
              }
              //debugPrint("permanece o mesmo");
            },
          );
    } on FirebaseAuthException {
      if (mounted) {
        passarInformacoes(usuarioUID, usuarioEmail);
        redirecionarTelaInicial();
      }
    }
  }

  //metodo para gravar no bando de dados caso o
  // usuario tenha confirmado a alteracao de email
  gravarEmailAlteradoBancoDados(String uid) async {
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
              passarInformacoes(usuarioUID, emailAlteracao);
              redirecionarTelaInicial();
            },
            onError: (e) {
              debugPrint(e.toString());
            },
          );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void dispose() {
    super.dispose();
    validacao.cancel();
  }

  redirecionarTelaLoginCadastro() {
    Navigator.pushReplacementNamed(context, Constantes.rotaTelaLoginCadastro);
  }

  redirecionarTelaInicial() {
    Navigator.pushReplacementNamed(context, Constantes.rotaTelaInicial);
  }

  passarInformacoes(String uid, String email) {
    Map dados = {};
    dados[Constantes.infoUsuarioUID] = uid;
    dados[Constantes.infoUsuarioEmail] = email;
    PassarPegarDados.passarInformacoesUsuario(dados);
  }

  chamarMetodoGravarDadosSharePreferences() {
    String horarioSemana = MetodosAuxiliares.formatarHorarioAjuste(
      Constantes.horarioPadraoSemana,
    );
    MetodosAuxiliares.gravarHorarioInicioTrabalhoDefinido(
      Constantes.sharePreferencesAjustarHorarioSemana,
      horarioSemana,
    );
    String horarioFinalSemana = MetodosAuxiliares.formatarHorarioAjuste(
      Constantes.horarioPadraoFinalSemana,
    );
    MetodosAuxiliares.gravarHorarioInicioTrabalhoDefinido(
      Constantes.sharePreferencesAjustarHorarioFinalSemana,
      horarioFinalSemana,
    );
  }

  @override
  Widget build(BuildContext context) {
    double alturaTela = MediaQuery.of(context).size.height;
    double larguraTela = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        height: alturaTela,
        width: larguraTela,
        color: PaletaCores.corAzulEscuro,
        child: SingleChildScrollView(
          child: SizedBox(
            width: larguraTela,
            height: alturaTela,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Image(
                  image: AssetImage('assets/imagens/Logo.png'),
                  width: 200,
                  height: 200,
                ),
                SizedBox(
                  width: larguraTela,
                  height: 300,
                  child: const TelaCarregamento(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
