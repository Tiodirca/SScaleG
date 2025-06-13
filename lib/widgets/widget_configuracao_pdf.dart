import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sscaleg/Uteis/paleta_cores.dart';

class WidgetConfiguracaoPDF extends StatefulWidget {
  const WidgetConfiguracaoPDF({
    super.key,
    required this.cabecalhoEscala,
    required this.escalaCompleta,
    required this.observacoes,
  });

  final List<String> observacoes;
  final List<Map> escalaCompleta;
  final List<dynamic> cabecalhoEscala;

  @override
  State<WidgetConfiguracaoPDF> createState() => _WidgetConfiguracaoPDFState();
}

class _WidgetConfiguracaoPDFState extends State<WidgetConfiguracaoPDF> {
  @override
  Widget build(BuildContext context) {
    double larguraTela = MediaQuery.of(context).size.width;
    double alturaTela = MediaQuery.of(context).size.height;
    return Container(
      width: larguraTela,
      height: alturaTela,
      child: Card(
        color: Colors.white,
        shape: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          borderSide: BorderSide(width: 1, color: PaletaCores.corCastanho),
        ),
        child: Column(
          children: [

          ],
        )
      ),
    );
  }
}
