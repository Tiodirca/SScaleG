import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sscaleg/uteis/constantes.dart';
import 'package:sscaleg/uteis/estilo.dart';
import '../uteis/textos.dart';

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  Estilo estilo = Estilo();

  Widget botao(String nomeBtn) => Container(
    margin: const EdgeInsets.all(10),
    width: 200,
    height: 50,
    child: FloatingActionButton(
      heroTag: nomeBtn,
      onPressed: () {
        if (nomeBtn == Textos.btnCriarEscala) {
          Navigator.pushReplacementNamed(
              context,
              Constantes.rotaTelaCadastroSelecaoLocalTrabalho);
        }else if(nomeBtn == Textos.btnListarEscalas){
          Navigator.pushReplacementNamed(
              context,
              Constantes.rotaTelaListagemEscalaBandoDados);
        }
        //else if (nomeBtn == Textos.btnConfiguracoes) {
        //   // Navigator.pushReplacementNamed(
        //   //     context, Constantes.rotaTelaConfiguracoes);
        // } else if (nomeBtn == Textos.btnListarEscalas) {
        //   // Navigator.pushReplacementNamed(
        //   //     context, Constantes.rotaListarEscalas);
        // } else if (nomeBtn == Textos.btnSonoplastas) {
        //   // Navigator.pushReplacementNamed(
        //   //     arguments: Constantes.fireBaseDocumentoSonoplastas,
        //   //     context,
        //   //     Constantes.rotaTelaCadastroVoluntarios);
        // } else {
        //   // Navigator.pushReplacementNamed(
        //   //     arguments: Constantes.fireBaseDocumentoCooperadores,
        //   //     context,
        //   //     Constantes.rotaTelaCadastroVoluntarios);
        // }
      },
      child: Text(
        nomeBtn,
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
      );
    });
    return Theme(
      data: estilo.estiloGeral,
      child: Scaffold(
        appBar: AppBar(
          title: Text(Textos.nomeApp),
          leading: const Image(
            image: AssetImage('assets/imagens/Logo.png'),
            width: 10,
            height: 10,
          ),
        ),
        body: Container(
          width: larguraTela,
          height: alturaTela,
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: larguraTela,
                height: alturaTela * 0.6,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    // SizedBox(
                    // width: larguraTela,
                    // child: Text(Textos.descricaoTelaInicial,
                    //     style: const TextStyle(fontSize: 18),
                    //     textAlign: TextAlign.center)),
                    botao(Textos.btnCriarEscala),
                    botao(Textos.btnListarEscalas),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.0),
          color: Colors.white,
          width: larguraTela,
          height: 40,
          child: Text("Textos.versaoApp", textAlign: TextAlign.end),
        ),
      ),
    );
  }
}
