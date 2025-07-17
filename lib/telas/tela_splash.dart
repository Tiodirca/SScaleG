import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sscaleg/uteis/metodos_auxiliares.dart';
import 'package:sscaleg/uteis/passar_pegar_dados.dart';
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
          passarInformacoes(usuarioUID, usuarioEmail);
          redirecionarTelaInicial();
        } else {
          debugPrint("Sem Usuario Logado");
          redirecionarTelaLoginCadastro();
        }
      }
    });
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
                  height: 200,
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
