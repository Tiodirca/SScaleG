import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sscaleg/Widgets/tela_carregamento.dart';
import 'package:sscaleg/modelo/escala_modelo.dart';
import 'package:sscaleg/uteis/constantes.dart';
import 'package:sscaleg/uteis/estilo.dart';
import 'package:sscaleg/uteis/metodos_auxiliares.dart';
import 'package:sscaleg/uteis/passar_pegar_dados.dart';
import 'package:sscaleg/uteis/textos.dart';

class TelaGerarEscala extends StatefulWidget {
  const TelaGerarEscala({super.key});

  @override
  State<TelaGerarEscala> createState() => _TelaGerarEscalaState();
}

class _TelaGerarEscalaState extends State<TelaGerarEscala> {
  String ordenarCadastroVoluntarios = "";
  bool exibirWidgetCarregamento = false;
  final validacaoFormulario = GlobalKey<FormState>();
  Estilo estilo = Estilo();
  String idDocumento = "";
  List<String> intervaloTrabalho =
      PassarPegarDados.recuperarIntervaloTrabalho();
  List<String> locaisSorteioVoluntarios =
      PassarPegarDados.recuperarNomesLocaisTrabalho();
  TextEditingController nomeEscala = TextEditingController(text: "");
  Random random = Random();
  List<int> listaNumeroAuxiliarRepeticao = [];

  List<String> nomeVoluntarios = PassarPegarDados.recuperarNomesVoluntarios();

  List<Map> escalaSorteada = [];

  // List<EscalaSonoplatasModelo> escalaSorteadaSom = [];
  // List<String> locaisSorteioVoluntarios = [
  //   Constantes.porta01,
  //   Constantes.banheiroFeminino,
  //   Constantes.primeiraHoraPulpito,
  //   Constantes.segundaHoraPulpito,
  //   Constantes.primeiraHoraEntrada,
  //   Constantes.segundaHoraEntrada,
  //   Constantes.mesaApoio,
  //   Constantes.recolherOferta,
  //   Constantes.irmaoReserva
  // ];

  String horarioSemana = "19:20";
  String horarioFinalSemana = "17:50";

  // List<String> gravataCor = [
  //   Constantes.gravataPreta,
  //   Constantes.gravataAmarela,
  //   Constantes.gravataAzul,
  //   Constantes.gravataDourada,
  //   Constantes.gravataMarsala,
  //   Constantes.gravataVerde,
  //   Constantes.gravataVermelha
  // ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    // // removendo da lista de locais de trabalho os pontos
    // // que nao irao receber voluntarios baseado no tipo de voluntario
    // if (widget.tipoCadastroVoluntarios ==
    //     Constantes.fireBaseDocumentoSonoplastas) {
    //   locaisSorteioVoluntarios.clear();
    //   locaisSorteioVoluntarios = [
    //     Constantes.mesaSom,
    //     Constantes.notebook,
    //     Constantes.videos,
    //     Constantes.irmaoReserva,
    //   ];
    // } else {
    //   if (widget.tipoCadastroVoluntarios !=
    //       Constantes.fireBaseDocumentoCooperadores) {
    //     // caso o tipo de voluntario seja diferente do parametro
    //     // passado entrar no if e remover os seguintes elementos
    //     locaisSorteioVoluntarios.removeWhere(
    //       (element) =>
    //           element.contains(Constantes.primeiraHoraPulpito) ||
    //           element.contains(Constantes.segundaHoraPulpito) ||
    //           element.contains(Constantes.recolherOferta) ||
    //           element.contains(Constantes.porta01),
    //     );
    //   } else {
    //     locaisSorteioVoluntarios.removeWhere(
    //       (element) =>
    //           element.contains(Constantes.mesaApoio) ||
    //           element.contains(Constantes.banheiroFeminino),
    //     );
    //   }
    // }
    // //adicionando o nome dos voluntarios a uma lista de String
    // for (var element in widget.voluntariosSelecionados) {
    //   // add somente o nome na lista
    //   nomeVoluntarios.add(element.texto);
    // }
    // // chamando metodo para recuperar o horario de troca de turno
    // chamarRecuperarHorarioTroca();
  }

  // metodo para chamar recuperacao do horario de troca de turno
  // chamarRecuperarHorarioTroca() async {
  //   horarioSemana = await MetodosAuxiliares.recuperarValoresSharePreferences(
  //     Constantes.diaSegunda,
  //   );
  //   horarioFinalSemana =
  //       await MetodosAuxiliares.recuperarValoresSharePreferences(
  //         Constantes.diaDomingo,
  //       );
  // }

  // metodo para realizar o sorteio dos nomes nos locais de trabalho
  fazerSorteio() {
    setState(() {
      //exibirWidgetCarregamento = true;
    });
    // limpando listas
    escalaSorteada.clear();
    listaNumeroAuxiliarRepeticao.clear();
    Map linha = {};
    int numeroRandomico = 0;
    // chamando metodo para sortear posicoes na lista de numero
    // sem repeticao para ser utilizado no FOR abaixo
    sortearNomesSemRepeticao(numeroRandomico);
    for (var datas in intervaloTrabalho) {
      String horarioInicioTrabalho = "";
      //verificando se a data Contem algum dos parametros a abaixo para
      // definir qual sera o horario de troca de turno
      if (datas.contains(Constantes.diaDomingo.toLowerCase()) ||
          datas.contains(Constantes.diaSabado.toLowerCase())) {
        horarioInicioTrabalho = horarioFinalSemana;
      } else {
        horarioInicioTrabalho = horarioSemana;
      }
      linha[Constantes.dataCulto] = datas;
      linha[Constantes.horarioTrabalho] = horarioInicioTrabalho;
      // fazendo a iteracao baseado na quantidade de dias selecionados no intervalo de trabalho
      for (int index = 0; index < locaisSorteioVoluntarios.length; index++) {
        // fazendo iteracao baseado na quantidade de locais de trabalho disponiveis
        // a cada interacao a LINHA vai receber um ELEMENTO/LOCAL de trabalho baseado
        // no index que esta e vai atribuir um NOME DE VOLUNTARIO a esse LOCAL da
        // LINHA baseado no valor que a LISTA de NUMEROS AUXILIAR recebeu para que
        // não haja repeticao de nomes na mesma LINHA
        linha[locaisSorteioVoluntarios.elementAt(index)] = nomeVoluntarios
            .elementAt(listaNumeroAuxiliarRepeticao.elementAt(index));
      }

      // //chamando metodo para sortear
      // // novas combinacoes de nome
      sortearNomesSemRepeticao(numeroRandomico);
    }
    print("Linha:${linha}");
    chamarCadastroItens(linha);
  }

  // sortearGravata() {
  //   int numeroRandom = random.nextInt(gravataCor.length);
  //   return gravataCor.elementAt(numeroRandom);
  // }

  // metodo para chamar o sorteio de nomes sem repeticao
  sortearNomesSemRepeticao(int numeroRandomico) {
    listaNumeroAuxiliarRepeticao.clear(); //limpando lista
    for (var element in locaisSorteioVoluntarios) {
      // para cada interacao sortear um numero entre 0 e o
      // tamanho da lista de locais de trabalho
      numeroRandomico = random.nextInt(nomeVoluntarios.length);
      sortearNumeroSemRepeticao(numeroRandomico); //chamando metodo
    }
  }

  // metodo para sortear numero sem repeticao
  sortearNumeroSemRepeticao(int numeroRandomico) {
    //caso a lista nao contenha o numero randomico entrar no if
    if (!listaNumeroAuxiliarRepeticao.contains(numeroRandomico)) {
      //adicionando numero NAO repetido a lista para posteriormente
      // ser utilizada ao posicionar o nome dos voluntarios
      // nos locais de trabalho
      listaNumeroAuxiliarRepeticao.add(numeroRandomico);
      return numeroRandomico;
    } else {
      // sorteando outro numero pois o numero
      // sorteado anteriormente ja esta na lista
      numeroRandomico = random.nextInt(nomeVoluntarios.length);
      sortearNumeroSemRepeticao(numeroRandomico);
    }
  }

  // metodo para chamar o cadastro de itens no banco de dados
  chamarCadastroItens(Map linha) async {
    int contador = 0;
    var db = FirebaseFirestore.instance;
    db
        // definindo a COLECAO no Firebase
        .collection(Constantes.fireBaseColecaoEscalas)
        // definindo o nome do DOCUMENTO
        .add({Constantes.fireBaseDocumentoDadosEscalas: nomeEscala.text});
    String idDocumentoFirebase = await buscarIDDocumentoFirebase();

    linha.forEach((key, value) {
      print(key);
      print(value);
     cadastrarItens(key, value, idDocumentoFirebase);
    });
  }

  buscarIDDocumentoFirebase() async {
    String idDocumentoFirebase = "";
    var db = FirebaseFirestore.instance;
    await db
        // definindo a COLECAO no Firebase
        .collection(Constantes.fireBaseColecaoEscalas)
        // selecionar todos os itens que contem o parametro passado
        .where(Constantes.fireBaseDocumentoDadosEscalas)
        .get()
        .then((querySnapshot) {
          for (var docSnapshot in querySnapshot.docs) {
            if (docSnapshot.data().values.contains(nomeEscala.text)) {
              // caso seja definir que a variavel vai receber o valor
              idDocumentoFirebase = docSnapshot.id;
            }
          }
        });
    return idDocumentoFirebase;
  }

  cadastrarItens(
    String chaveNomeCampo,
    String valorDadosCampos,
    String idDocumentoFirebase,
  ) async {
    try {
      var db = FirebaseFirestore.instance;
      db
          .collection(Constantes.fireBaseColecaoEscalas)
          .doc(idDocumentoFirebase)
          .collection(Constantes.fireBaseDocumentoDadosEscalas)
          .doc()
          .set({chaveNomeCampo: valorDadosCampos.toString()});
    } catch (e) {
      MetodosAuxiliares.exibirMensagens(
        Constantes.tipoNotificacaoErro,
        Textos.erroListaVazia,
        context,
      );
      if (kDebugMode) {
        print(e.toString());
      }
    }
  }

  chamarTelaCarregamento() {
    setState(() {
      exibirWidgetCarregamento = true;
    });
  }

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
                  title: Text(Textos.btnGerarEscala),
                  leading: IconButton(
                    color: Colors.white,
                    onPressed: () {
                      PassarPegarDados.passarIntervaloTrabalho([]);
                      Navigator.pushReplacementNamed(
                        context,
                        Constantes.rotaTelaSelecaoIntervaloTrabalho,
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
                          height: alturaTela * 0.3,
                          padding: const EdgeInsets.only(bottom: 20.0),
                          width: larguraTela,
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 10.0,
                                  ),
                                  child: Text(
                                    Textos.descricaoGerarEscala,
                                    textAlign: TextAlign.justify,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Form(
                                      key: validacaoFormulario,
                                      child: SizedBox(
                                        width: Platform.isWindows ? 300 : 200,
                                        child: TextFormField(
                                          controller: nomeEscala,
                                          onFieldSubmitted: (value) {
                                            if (validacaoFormulario
                                                .currentState!
                                                .validate()) {
                                              fazerSorteio();
                                            }
                                          },
                                          validator: (value) {
                                            if (value!.isEmpty) {
                                              return Textos.erroCampoVazio;
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 10.0,
                                      ),
                                      width: 100,
                                      height: 50,
                                      child: FloatingActionButton(
                                        heroTag: Textos.btnGerarEscala,
                                        onPressed: () {
                                          if (validacaoFormulario.currentState!
                                              .validate()) {
                                            fazerSorteio();
                                          }
                                        },
                                        child: Text(Textos.btnGerarEscala),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 10.0,
                                      ),
                                      width: 100,
                                      height: 50,
                                      child: FloatingActionButton(
                                        heroTag: Textos.btnGerarEscala,
                                        onPressed: () {
                                          escalaSorteada.forEach((element) {
                                            print(element);
                                          });
                                          print(escalaSorteada.length);
                                        },
                                        child: Text("Textos.btnGerarEscala"),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
