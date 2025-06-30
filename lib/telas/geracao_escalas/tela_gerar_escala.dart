import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sscaleg/Widgets/tela_carregamento.dart';
import 'package:sscaleg/uteis/constantes.dart';
import 'package:sscaleg/uteis/estilo.dart';
import 'package:sscaleg/uteis/metodos_auxiliares.dart';
import 'package:sscaleg/uteis/passar_pegar_dados.dart';
import 'package:sscaleg/uteis/textos.dart';
import 'package:sscaleg/widgets/barra_navegacao_widget.dart';
import 'package:sscaleg/widgets/widget_ajustar_horario.dart';

class TelaGerarEscala extends StatefulWidget {
  const TelaGerarEscala({super.key});

  @override
  State<TelaGerarEscala> createState() => _TelaGerarEscalaState();
}

class _TelaGerarEscalaState extends State<TelaGerarEscala> {
  bool exibirWidgetCarregamento = false;
  final validacaoFormulario = GlobalKey<FormState>();
  Estilo estilo = Estilo();
  String idDocumento = "";
  List<String> intervaloTrabalho =
      PassarPegarDados.recuperarIntervaloTrabalho();
  List<String> locaisSorteioVoluntarios =
      PassarPegarDados.recuperarNomesLocaisTrabalho();
  List<String> nomeVoluntarios = PassarPegarDados.recuperarNomesVoluntarios();
  TextEditingController nomeEscala = TextEditingController(text: "");
  Random random = Random();
  List<int> listaNumeroAuxiliarRepeticao = [];
  List<int> listaNumeroAuxiliarRepeticaoNomesNaoListados = [];
  List<Map> escalaSorteada = [];
  int index = 0;
  String horarioSemana = "";
  String nomeEscalaFormatada = "";
  String horarioFinalSemana = "";
  Map dadosUsuario = {};
  String uidUsuario = "";
  String nomeColecaoUsuariosFireBase = Constantes.fireBaseColecaoUsuarios;
  String nomeColecaoFireBase = Constantes.fireBaseColecaoEscalas;
  String nomeDocumentoFireBase = Constantes.fireBaseDocumentoNomeEscalas;

  @override
  void initState() {
    super.initState();
    uidUsuario =
        PassarPegarDados.recuperarInformacoesUsuario().entries.first.value;
  }

  recuperarHorarioDefinidoInicioTrabalho() {
    setState(() {
      horarioSemana = PassarPegarDados.recuperarHorarioSemanaDefinido();
      horarioFinalSemana =
          PassarPegarDados.recuperarHorarioFinalSemanaDefinido();
    });
  }

  // metodo para realizar o sorteio dos nomes nos locais de trabalho
  fazerSorteio() {
    // limpando listas
    escalaSorteada.clear();
    listaNumeroAuxiliarRepeticao.clear();
    int numeroRandomico = 0;
    // chamando metodo para sortear posicoes na lista de numero
    // sem repeticao para ser utilizado no FOR abaixo
    sortearNomesSemRepeticao(numeroRandomico);
    for (var datas in intervaloTrabalho) {
      Map linha = {};
      String horarioInicioTrabalho = "";
      //verificando se a data Contem algum dos parametros a abaixo para
      // definir qual sera o horario de troca de turno
      if (datas.contains(Constantes.diaDomingo.toLowerCase()) ||
          datas.contains(Constantes.diaSabado.toLowerCase())) {
        horarioInicioTrabalho = horarioFinalSemana;
      } else {
        horarioInicioTrabalho = horarioSemana;
      }
      linha[Constantes.horarioTrabalho] = horarioInicioTrabalho;
      linha[Constantes.dataCulto] = datas;
      // fazendo a iteracao baseado na quantidade de dias selecionados no intervalo de trabalho
      for (int index = 0; index < locaisSorteioVoluntarios.length; index++) {
        // fazendo iteracao baseado na quantidade de locais de trabalho disponiveis
        // a cada interacao a LINHA vai receber um ELEMENTO/LOCAL de trabalho baseado
        // no index que esta e vai atribuir um NOME DE VOLUNTARIO a esse LOCAL da
        // LINHA baseado no valor que a LISTA de NUMEROS AUXILIAR recebeu para que
        // não haja repeticao de nomes na mesma LINHA
        // linha[nome_local_trabalho] = "nome voluntario"
        linha[locaisSorteioVoluntarios.elementAt(index)] = nomeVoluntarios
            .elementAt(listaNumeroAuxiliarRepeticao.elementAt(index));
      }
      escalaSorteada.add(linha);
      sortearNomesSemRepeticao(numeroRandomico);
    }
    verificarNomes();
  }

  verificarNomes() {
    listaNumeroAuxiliarRepeticaoNomesNaoListados.clear();
    List<String> nomes = [];
    List<String> nomesNaoListados = [];
    List<Map> escala = [];
    for (var element in escalaSorteada) {
      escala.add(element);
    }
    for (var element in nomeVoluntarios) {
      nomesNaoListados.add(element);
      nomes.add(element);
    }

    List<String> nomesJaAdicionados = verificarNomesAdicionadosEscala(
      escala,
      nomes,
    );
    nomesNaoListados = verificarNomesNaoAdicionados(nomesJaAdicionados);

    Random random = Random();
    for (int i = 0; i < nomesNaoListados.length; i++) {
      int numeroRandomico = random.nextInt(locaisSorteioVoluntarios.length);
      escala
          .elementAt(listaNumeroAuxiliarRepeticaoNomesNaoListados.elementAt(i))
          .update(locaisSorteioVoluntarios.elementAt(numeroRandomico), (value) {
            return value = nomesNaoListados[i];
          });
    }
    if (nomesNaoListados.isNotEmpty && escalaSorteada.length >= 7) {
      verificarNomes();
    } else {
      escalaSorteada.clear();
      for (var element in escala) {
        escalaSorteada.add(element);
      }
      chamarCadastroItens();
    }
  }

  verificarNomesAdicionadosEscala(List<Map> escala, List<String> nomes) {
    List<String> nomesJaAdicionados = [];
    for (var element in escala) {
      for (var nomeVoluntario in nomes) {
        //verificando se na escala sorteada contem o nome do voluntario
        if (element.values.toString().contains(nomeVoluntario)) {
          //verificando se na lista de nomes nao contem o nome do voluntario ja
          if (!nomesJaAdicionados.contains(nomeVoluntario)) {
            //caso nao tenha adicionar na lista
            nomesJaAdicionados.add(nomeVoluntario);
          }
        }
      }
    }
    return nomesJaAdicionados;
  }

  verificarNomesNaoAdicionados(List<String> nomesJaAdicionados) {
    List<String> nomesNaoListados = [];
    //percorrendo os nomes ja adicionados
    for (var element in nomesJaAdicionados) {
      //removendo da lista nao adicionados os nomes que ja foram adicionados
      nomesNaoListados.removeWhere((elemento) {
        return elemento == element;
      });
    }
    //percorrendo a lista de nomes nao listados
    for (var element in nomesNaoListados) {
      //para cada iteracao instanciar um rando,
      Random random = Random();
      // para cada iteracao gerar um numero entre  0 e o tamanho da escala sorteada
      int numeroRandomico = random.nextInt(escalaSorteada.length);
      // adicionar na lista de repeticoes
      listaNumeroAuxiliarRepeticaoNomesNaoListados.add(numeroRandomico);
    }
    return nomesNaoListados;
  }

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

  //metodo para buscar o id na base de dados para poder adicionar os dados
  // naquele id buscado
  buscarIDDocumentoFirebase() async {
    String idDocumentoFirebase = "";
    var db = FirebaseFirestore.instance;
    await db
        .collection(nomeColecaoUsuariosFireBase) // passando a colecao
        .doc(uidUsuario)
        // definindo a COLECAO no Firebase
        .collection(nomeColecaoFireBase)
        // selecionar todos os itens que contem o parametro passado
        .where(nomeDocumentoFireBase)
        .get()
        .then((querySnapshot) {
          for (var docSnapshot in querySnapshot.docs) {
            //verificando se o retorno do banco de dados contem
            // o nome digitado no campo de texto
            if (docSnapshot.data().values.contains(nomeEscalaFormatada)) {
              // caso seja definir que a variavel vai receber o valor
              idDocumentoFirebase = docSnapshot.id;
            }
          }
        });
    return idDocumentoFirebase;
  }

  // metodo para chamar o cadastro de itens no banco de dados
  chamarCadastroItens() async {
    try {
      var db = FirebaseFirestore.instance;
      db
          .collection(nomeColecaoUsuariosFireBase) // passando a colecao
          .doc(uidUsuario)
          // definindo a COLECAO no Firebase
          .collection(nomeColecaoFireBase)
          // definindo o nome do DOCUMENTO
          .add({nomeDocumentoFireBase: nomeEscalaFormatada})
          .then(
            (value) async {
              String idDocumentoFirebase = await buscarIDDocumentoFirebase();
              //percorrento a lista
              idDocumento = idDocumentoFirebase;
              for (var element in escalaSorteada) {
                // para cada iteracao chamar metodo
                cadastrarItens(element.entries.toList(), idDocumentoFirebase);
              }
            },
            onError: (e) {
              setState(() {
                exibirWidgetCarregamento = false;
              });
              chamarExibirMensagemErro(
                "Erro Criar Nome Escala : ${e.toString()}",
              );
            },
          );
    } catch (e) {
      setState(() {
        exibirWidgetCarregamento = false;
      });
      chamarExibirMensagemErro(e.toString());
    }
  }

  chamarExibirMensagemErro(String erro) {
    MetodosAuxiliares.exibirMensagens(
      Constantes.tipoNotificacaoErro,
      erro,
      context,
    );
  }

  cadastrarItens(List<MapEntry> escala, String idDocumentoFirebase) async {
    try {
      var db = FirebaseFirestore.instance;
      db
          .collection(nomeColecaoUsuariosFireBase) // passando a colecao
          .doc(uidUsuario)
          // definindo a COLECAO no Firebase
          .collection(nomeColecaoFireBase)
          .doc(idDocumentoFirebase)
          .collection(Constantes.fireBaseDadosCadastrados)
          .doc()
          .set(criarMapComTodosOsDados(escala))
          .then((value) {
            index++;
            //ve
            if (index == escalaSorteada.length) {
              index = 0;
              MetodosAuxiliares.exibirMensagens(
                Constantes.tipoNotificacaoSucesso,
                Textos.notificacaoSucesso,
                context,
              );
              limparListaDados();
              redirecionarProximaTela();
            }
          });
    } catch (e) {
      setState(() {
        exibirWidgetCarregamento = false;
      });
      chamarExibirMensagemErro(e.toString());
    }
  }

  limparListaDados() {
    PassarPegarDados.passarNomesLocaisTrabalho([]);
    PassarPegarDados.passarNomesVoluntarios([]);
    PassarPegarDados.passarIntervaloTrabalho([]);
    PassarPegarDados.passarDiasSemana([]);
    PassarPegarDados.passarHorarioSemanaDefinido("");
    PassarPegarDados.passarHorarioFinalSemanaDefinido("");
  }

  redirecionarProximaTela() {
    var dados = {};
    dados[Constantes.rotaArgumentoNomeEscala] = nomeEscalaFormatada;
    dados[Constantes.rotaArgumentoIDEscalaSelecionada] = idDocumento;
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(
        context,
        Constantes.rotaTelaEscalaDetalhada,
        arguments: dados,
      );
    });
  }

  criarMapComTodosOsDados(List<MapEntry> escala) {
    Map<String, dynamic> itemFinal = {};
    //percorrendo a escala para pegar cada item da escala
    // e colocar num Map para ser retornado
    for (var element in escala) {
      itemFinal[element.key] = element.value;
    }
    return itemFinal;
  }

  chamarFazerSorteio() {
    if (validacaoFormulario.currentState!.validate()) {
      setState(() {
        nomeEscalaFormatada =
            nomeEscala.text.trim().replaceAll(" ", "_").toLowerCase();
        exibirWidgetCarregamento = true;
      });
      recuperarHorarioDefinidoInicioTrabalho();
      fazerSorteio();
    }
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (exibirWidgetCarregamento) {
              return const TelaCarregamento();
            } else {
              return Scaffold(
                appBar: AppBar(
                  title: Text(Textos.btnCriarEscala),
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
                          margin: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(
                            Textos.telaGerarEscalaDescricao,
                            textAlign: TextAlign.justify,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        Column(
                          children: [
                            Form(
                              key: validacaoFormulario,
                              child: SizedBox(
                                width: Platform.isWindows ? 300 : 200,
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    hintText: Textos.labelTextFieldCampo,
                                  ),
                                  controller: nomeEscala,
                                  onFieldSubmitted: (value) {
                                    chamarFazerSorteio();
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

                            WidgetAjustarHorario(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                bottomNavigationBar: Container(
                  color: Colors.white,
                  height: 100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 40,
                        child: FloatingActionButton(
                          heroTag: Textos.btnCriarEscala,
                          onPressed: () {
                            chamarFazerSorteio();
                          },
                          child: Text(
                            Textos.btnCriarEscala,
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      BarraNavegacao(),
                    ],
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
