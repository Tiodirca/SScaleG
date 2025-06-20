import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sscaleg/uteis/metodos_auxiliares.dart';
import '../Uteis/paleta_cores.dart';
import '../Widgets/tela_carregamento.dart';
import '../uteis/constantes.dart';

class TelaSplashScreen extends StatefulWidget {
  const TelaSplashScreen({super.key});

  @override
  State<TelaSplashScreen> createState() => _TelaSplashScreenState();
}

class _TelaSplashScreenState extends State<TelaSplashScreen> {
  @override
  void initState() {
    super.initState();
    chamarMetodoGravarDadosSharePreferences();
    Timer(const Duration(seconds: 1), () {
      Navigator.pushReplacementNamed(context, Constantes.rotaTelaInicial);
    });
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
                // const Image(
                //   image: AssetImage('assets/imagens/Logo.png'),
                //   width: 200,
                //   height: 200,
                // ),
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
