import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sscaleg/uteis/constantes.dart';
import 'package:sscaleg/uteis/estilo.dart';
import 'package:sscaleg/uteis/passar_pegar_dados.dart';
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

  @override
  void initState() {
    emailCadastrado = PassarPegarDados.recuperarInformacoesUsuario().entries.last.value;
    super.initState();
  }

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
            Constantes.rotaTelaCadastroSelecaoLocalTrabalho,
          );
        } else if (nomeBtn == Textos.btnListarEscalas) {
          Navigator.pushReplacementNamed(
            context,
            Constantes.rotaTelaListagemEscalaBandoDados,
          );
        }else if(nomeBtn == Textos.btnConfiguracao){
          Navigator.pushReplacementNamed(
            context,
            Constantes.rotaTelaDadosUsuario,
          );
        }
      },
      child: Text(
        nomeBtn,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          color: Colors.black,
        ),
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
                height: alturaTela * 0.7,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: 10.0),
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
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: larguraTela,
                      child: Text(
                        Textos.telaInicialDescricao,
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    botao(Textos.btnCriarEscala),
                    botao(Textos.btnListarEscalas),
                    botao(Textos.btnConfiguracao),
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
      ),
    );
  }
}
