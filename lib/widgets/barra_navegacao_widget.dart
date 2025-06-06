import 'package:flutter/material.dart';
import 'package:sscaleg/Uteis/paleta_cores.dart';

import '../uteis/constantes.dart';
import '../uteis/textos.dart';

class BarraNavegacao extends StatelessWidget {
  BarraNavegacao({Key? key}) : super(key: key);

  final Color corTextoBotao = PaletaCores.corAzulEscuro;

  Widget botoesIcones(BuildContext context, IconData icon) =>
      SizedBox(
          height: 50,
          width: 50,
          child: FloatingActionButton(
            heroTag: icon.toString(),
            onPressed: () {
              if (icon == Constantes.iconeTelaInicial) {
                Navigator.pushReplacementNamed(
                    context, Constantes.rotaTelaInicial);
              } else if (icon == Constantes.iconeLista) {
                Navigator.pushReplacementNamed(
                    context, Constantes.rotaTelaListagemEscalaBandoDados);
              }
            },
            child: Center(
              child: Icon(
                icon,
                size: 25,
                color: corTextoBotao,
              ),
            ),
          ));

  @override
  Widget build(BuildContext context) {
    double larguraTela = MediaQuery
        .of(context)
        .size
        .width;

    return SizedBox(
      width: larguraTela,
      height: 65,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          botoesIcones(context, Constantes.iconeTelaInicial),
          botoesIcones(context, Constantes.iconeLista),
        ],
      ),
    );
  }
}
