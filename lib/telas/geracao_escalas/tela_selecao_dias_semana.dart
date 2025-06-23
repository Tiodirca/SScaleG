import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sscaleg/Modelo/check_box_modelo.dart';
import 'package:sscaleg/Uteis/paleta_cores.dart';
import 'package:sscaleg/uteis/constantes.dart';
import 'package:sscaleg/uteis/estilo.dart';
import 'package:sscaleg/uteis/metodos_auxiliares.dart';
import 'package:sscaleg/uteis/passar_pegar_dados.dart';
import 'package:sscaleg/uteis/textos.dart';
import 'package:sscaleg/widgets/barra_navegacao_widget.dart';

class TelaSelecaoDiasSemana extends StatefulWidget {
  const TelaSelecaoDiasSemana({super.key});

  @override
  State<TelaSelecaoDiasSemana> createState() => _TelaSelecaoDiasSemanaState();
}

class _TelaSelecaoDiasSemanaState extends State<TelaSelecaoDiasSemana> {
  Estilo estilo = Estilo();
  List<String> listaDiasSelecionado = [];

  List<CheckBoxModelo> listaDiasSemana = [
    CheckBoxModelo(texto: Constantes.diaSegunda),
    CheckBoxModelo(texto: Constantes.diaTerca),
    CheckBoxModelo(texto: Constantes.diaQuarta),
    CheckBoxModelo(texto: Constantes.diaQuinta),
    CheckBoxModelo(texto: Constantes.diaSexta),
    CheckBoxModelo(texto: Constantes.diaSabado),
    CheckBoxModelo(texto: Constantes.diaDomingo),
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  Widget checkBoxPersonalizado(CheckBoxModelo checkBoxModel) =>
      CheckboxListTile(
        activeColor: PaletaCores.corAzulEscuro,
        checkColor: PaletaCores.corRosaClaro,
        title: Text(checkBoxModel.texto, style: const TextStyle(fontSize: 20)),
        value: checkBoxModel.checked,
        side: const BorderSide(width: 2, color: PaletaCores.corAzulEscuro),
        onChanged: (value) {
          setState(() {
            checkBoxModel.checked = value!;
            verificarItensSelecionados();
          });
        },
      );

  // metodo para verificar se o item foi selecionado
  // para adicionar na lista de itens selecionados
  verificarItensSelecionados() {
    //verificando cada elemento da lista de nomes cadastrados
    for (var element in listaDiasSemana) {
      //verificando se o usuario selecionou um item
      if (element.checked == true) {
        // verificando se o item Nao foi adicionado anteriormente na lista
        if (!(listaDiasSelecionado.contains(element.texto))) {
          //add item
          listaDiasSelecionado.add(element.texto);
        }
      } else if (element.checked == false) {
        // removendo item caso seja desmarcado
        listaDiasSelecionado.remove(element.texto);
      }
    }
  }

  redirecionarProximaTela() {
    PassarPegarDados.passarDiasSemana(listaDiasSelecionado);
    Navigator.pushReplacementNamed(
      context,
      Constantes.rotaTelaSelecaoIntervaloTrabalho,
    );
  }

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
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(Textos.tituloTelaSelecaoDiasSemana),
            leading: IconButton(
              color: Colors.white,
              onPressed: () {
                PassarPegarDados.passarNomesVoluntarios([]);
                Navigator.pushReplacementNamed(
                  context,
                  Constantes.rotaTelaCadastroSelecaoVoluntarios,
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
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(10.0),
                    child: Text(
                      Textos.descricaoSelecaoDiasSemana,
                      textAlign: TextAlign.justify,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  Card(
                    child: SizedBox(
                      height: alturaTela * 0.6,
                      width:
                          Platform.isAndroid || Platform.isIOS
                              ? larguraTela
                              : larguraTela * 0.7,
                      child: ListView(
                        children: [
                          ...listaDiasSemana.map(
                            (e) => checkBoxPersonalizado(e),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Container(
            color: Colors.white,
            width: larguraTela,
            height: 100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 100,
                  height: 40,
                  child: FloatingActionButton(
                    heroTag: Textos.btnAvancar,
                    onPressed: () {
                      if (listaDiasSelecionado.isNotEmpty) {
                        redirecionarProximaTela();
                      } else {
                        MetodosAuxiliares.exibirMensagens(
                          Constantes.tipoNotificacaoErro,
                          Textos.erroListaVazia,
                          context,
                        );
                      }
                    },
                    child: Text(
                      Textos.btnAvancar,
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                BarraNavegacao(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
