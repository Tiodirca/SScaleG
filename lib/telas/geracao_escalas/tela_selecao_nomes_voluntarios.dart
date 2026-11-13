import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sscaleg/Widgets/tela_carregamento.dart';
import 'package:sscaleg/modelo/check_box_modelo_local_trabalho.dart';
import 'package:sscaleg/modelo/check_box_modelo_voluntario.dart';
import 'package:sscaleg/uteis/metodos_auxiliares.dart';
import 'package:sscaleg/uteis/passar_pegar_dados.dart';
import 'package:sscaleg/uteis/textos.dart';
import 'package:sscaleg/widgets/barra_navegacao_widget.dart';
import '../../uteis/estilo.dart';
import '../../uteis/paleta_cores.dart';
import '../../uteis/constantes.dart';

class TelaSelecaoNomesVoluntarios extends StatefulWidget {
  const TelaSelecaoNomesVoluntarios({super.key});

  @override
  State<TelaSelecaoNomesVoluntarios> createState() =>
      _TelaSelecaoNomesVoluntariosState();
}

class _TelaSelecaoNomesVoluntariosState
    extends State<TelaSelecaoNomesVoluntarios> {
  List<CheckBoxModeloVoluntario> listaNomesVoluntariosListaReferencia = [];
  List<CheckBoxModeloVoluntario> listaNomesExibicaoFiltragram = [];
  Map<String, int> listaNomeCategoriasVoluntario = {};
  List<CheckBoxModeloVoluntario> listaNomesSelecionados = [];
  List<String> listaNomesSelecionadosExibicao = [];
  List<CheckBoxModeloLocalTrabalho> listaValidarQuantidadeVoluntarios = [];
  bool exibirWidgetCarregamento = true;
  Estilo estilo = Estilo();
  String uidUsuario = "";
  int indexTabela = 0;
  int indexRadioButton = 0;
  String filtroDesativado = Textos.telaSelecaoVoluntariosFiltrarTodos;
  bool exibirTelaFiltro = false;
  String nomeColecaoUsuariosFireBase = Constantes.fireBaseColecaoUsuarios;
  String nomeColecaoFireBase = Constantes.fireBaseColecaoNomeVoluntarios;
  String nomeDocumentoFireBase = Constantes.fireBaseDocumentoNomeVoluntarios;

  @override
  void initState() {
    super.initState();
    Map<String, int> dados = {};
    dados[Textos.telaSelecaoVoluntariosFiltrarTodos] = 0;
    listaNomeCategoriasVoluntario.addAll(dados);
    uidUsuario =
        PassarPegarDados.recuperarInformacoesUsuario().entries.first.value;
    Timer(const Duration(seconds: 1), () {
      realizarBuscaDadosFireBase();
    });
  }

  validarQuantidadeVoluntarios() {
    listaValidarQuantidadeVoluntarios =
        PassarPegarDados.recuperarNomesLocaisTrabalho();
    if (listaValidarQuantidadeVoluntarios.length <=
        listaNomesSelecionados.length) {
      return true;
    } else {
      return false;
    }
  }

  Widget checkBoxPersonalizado(
    CheckBoxModeloVoluntario checkBoxModel,
    double largura,
  ) => Card(
    shape: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
      borderSide: BorderSide(
        width: 1,
        color:
            checkBoxModel.checked == true
                ? PaletaCores.corCastanho
                : PaletaCores.corAzulCiano,
      ),
    ),
    child: CheckboxListTile(
      activeColor: PaletaCores.corAzulEscuro,
      checkColor: PaletaCores.corRosaClaro,
      secondary: SizedBox(
        width: 80,
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: FloatingActionButton(
                heroTag: "btnExcluir ${checkBoxModel.id}",
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Colors.red, width: 1),
                ),
                child: const Icon(Icons.close, size: 20),
                onPressed: () {
                  // chamando alerta para confirmar exclusao do item
                  alertaExclusao(context, checkBoxModel);
                },
              ),
            ),
            SizedBox(
              width: 30,
              height: 30,
              child: FloatingActionButton(
                heroTag: "btnEditar ${checkBoxModel.id}",
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: PaletaCores.corCastanho, width: 1),
                ),
                child: const Icon(Icons.edit, size: 20),
                onPressed: () {
                  var dadosUsuario = {};
                  dadosUsuario[Constantes
                          .rotaArgumentoAtualizarDadosVoluntario] =
                      checkBoxModel;
                  Navigator.pushReplacementNamed(
                    context,
                    Constantes.rotaTelaAtualizarDadosVoluntario,
                    arguments: dadosUsuario,
                  );
                  // chamando alerta para confirmar exclusao do item
                  // alertaExclusao(context, checkBoxModel);
                },
              ),
            ),
          ],
        ),
      ),
      title: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            checkBoxModel.texto.replaceAll("_", " ").toUpperCase(),
            style: const TextStyle(fontSize: 20),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 300,
                  height: 40,
                  child: Row(
                    children: [
                      Text(
                        Textos.telaSelecaoVoluntariosCategoria,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        checkBoxModel.categoriaVoluntario.replaceAll("_", " "),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 300,
                  height: 40,
                  child: Row(
                    children: [
                      Text(
                        Textos.telaSelecaoVoluntariosDiasDisponiveis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        checkBoxModel.diasDisponiveis
                            .replaceAll("_", " ")
                            .replaceAll("[", " ")
                            .replaceAll("]", " "),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 400,
                  height: 40,
                  child: Row(
                    children: [
                      Text(
                        Textos.telaSelecaoVoluntariosObservacao,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        checkBoxModel.observacao
                            .replaceAll("_", " ")
                            .replaceAll("[", " ")
                            .replaceAll("]", " "),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),

      value: checkBoxModel.checked,

      side: const BorderSide(width: 2, color: PaletaCores.corAzulEscuro),
      onChanged: (value) {
        setState(() {
          // verificando se o balor
          checkBoxModel.checked = value!;
          verificarItensSelecionados();
        });
      },
    ),
  );

  // metodo para verificar se o item foi selecionado
  // para adicionar na lista de itens selecionados
  verificarItensSelecionados() {
    //verificando cada elemento da lista de nomes cadastrados
    for (var element in listaNomesVoluntariosListaReferencia) {
      //verificando se o usuario selecionou um item
      if (element.checked == true) {
        // verificando se o item Nao foi adicionado anteriormente na lista
        if (!(listaNomesSelecionados.contains(element))) {
          //add item
          listaNomesSelecionados.add(element);
          listaNomesSelecionadosExibicao.add(element.texto);
        }
      } else if (element.checked == false) {
        // removendo item caso seja desmarcado
        listaNomesSelecionados.remove(element);
        listaNomesSelecionadosExibicao.remove(element.texto);
      }
    }
  }

  chamarExibirMensagemErro(String erro) {
    MetodosAuxiliares.exibirMensagens(
      Constantes.tipoNotificacaoErro,
      erro,
      context,
    );
  }

  chamarExibirMensagemSucesso() {
    MetodosAuxiliares.exibirMensagens(
      Constantes.tipoNotificacaoSucesso,
      Textos.notificacaoSucesso,
      context,
    );
  }

  chamarTelaCarregamento() {
    listaNomesVoluntariosListaReferencia.clear();
    listaNomesExibicaoFiltragram.clear();
    listaNomesSelecionados.clear();
    listaNomeCategoriasVoluntario.clear();
    setState(() {
      exibirWidgetCarregamento = true;
    });
  }

  //metodo para recuperar dados no firebase
  realizarBuscaDadosFireBase() async {
    try {
      var db = FirebaseFirestore.instance;
      //instanciano variavel
      db
          .collection(nomeColecaoUsuariosFireBase)
          .doc(uidUsuario)
          .collection(nomeColecaoFireBase)
          .get()
          .then(
            (querySnapshot) async {
              // for para percorrer todos os dados que a variavel recebeu
              if (querySnapshot.docs.isNotEmpty) {
                for (var documentoFirebase in querySnapshot.docs) {
                  // chamando metodo para converter json
                  // recebido do firebase para objeto
                  converterJsonParaObjeto(
                    documentoFirebase.id,
                    querySnapshot.size,
                  );
                }
              } else {
                setState(() {
                  exibirWidgetCarregamento = false;
                });
              }
            },
            onError: (e) {
              setState(() {
                exibirWidgetCarregamento = false;
              });
              chamarExibirMensagemErro(
                "Erro Buscar Voluntarios: ${e.toString()}",
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

  Widget radioButtonFiltro(String nome, int index) => ListTile(
    title: Text(nome),
    leading: Radio(
      value: index,
      groupValue: indexRadioButton,
      onChanged: (value) {
        setState(() {
          indexRadioButton = value!;
          if (nome == Textos.telaSelecaoVoluntariosFiltrarTodos) {
            filtroDesativado = Textos.telaSelecaoVoluntariosFiltrarTodos;
          } else {
            filtroDesativado = "";
          }
          fazerFiltragemVoluntarios(nome);
        });
      },
    ),
  );

  fazerFiltragemVoluntarios(String nome) {
    //limpando lista de exibicao
    listaNomesExibicaoFiltragram.clear();
    //verificando que se a opcao do radio button selecionado for listar todos
    // caso contrario listar somente os nomes que contem a categoria selecionada
    if (nome == Textos.telaSelecaoVoluntariosFiltrarTodos) {
      for (var voluntarios in listaNomesVoluntariosListaReferencia) {
        listaNomesExibicaoFiltragram.add(voluntarios);
        ordenarListaNomesVoluntarios();
      }
      exibirTelaFiltro = false;
    } else {
      //pegando os nomes cadastrados de forma original
      for (var voluntario in listaNomesVoluntariosListaReferencia) {
        // pegando a categoria e separando as
        // categorias de forma individual para separar os voluntarios
        // que tem mais de uma categoria
        List<String> categoriaSeparadas = voluntario.categoriaVoluntario.split(
          ",",
        );
        for (var categoria in categoriaSeparadas) {
          //caso a categoria tenha o mesmo nome do radio
          // button fazer a listagem somente
          // dos voluntarios que tem aquela categoria
          if (categoria == nome) {
            listaNomesExibicaoFiltragram.add(voluntario);
            exibirTelaFiltro = false;
          }
        }
      }
    }
  }

  listarCategoriasVoluntarios() {
    // criando um index para poder fazer o radioButton
    int indexCategoria = 0;
    for (var categoriasCadastrada in listaNomesVoluntariosListaReferencia) {
      //separando as categorias em seguimentos separados,
      // pois o mesmo voluntario pode estar em mais de uma categoria
      List<String> categoriaSeparadas = categoriasCadastrada.categoriaVoluntario
          .split(",");
      //percorrendo a lista criada de categorias separadas
      for (var categoriaSeparada in categoriaSeparadas) {
        //verificando se a lista de catoria voluntario NAO contem a categoria cadastrada
        // caso nao conter adicionar
        if (!listaNomeCategoriasVoluntario.entries.contains(
          categoriaSeparada,
        )) {
          Map<String, int> dados = {};
          indexCategoria++;
          dados[categoriaSeparada] = indexCategoria;
          listaNomeCategoriasVoluntario.addAll(dados);
        }
      }
    }
  }

  //metodo para converter json em Objeto
  converterJsonParaObjeto(String id, int tamanhoEscala) async {
    var db = FirebaseFirestore.instance;
    final ref = db
        .collection(nomeColecaoUsuariosFireBase)
        .doc(uidUsuario)
        .collection(nomeColecaoFireBase)
        .doc(id)
        .withConverter(
          // chamando modelos para fazer conversao
          // baseado na classe modelo
          fromFirestore: CheckBoxModeloVoluntario.fromFirestore,
          toFirestore:
              (CheckBoxModeloVoluntario checkbox, _) => checkbox.toFirestore(),
        );

    final docSnap = await ref.get();
    final dados = docSnap.data(); // convertendo

    if (dados != null) {
      // pegando o id para posteriormente excluir
      // ou editar as informaçoes do item caso seja necessario
      dados.id = docSnap.id;
      indexTabela++;
      //adicionando os dados convertidos na lista
      listaNomesVoluntariosListaReferencia.add(dados);
      listaNomesExibicaoFiltragram.add(dados);
      if (indexTabela == tamanhoEscala) {
        setState(() {
          indexTabela = 0;
          //chamando ordenacao dos itens
          ordenarListaNomesVoluntarios();
          listarCategoriasVoluntarios();
          exibirWidgetCarregamento = false;
        });
      }
    }
  }

  ordenarListaNomesVoluntarios() {
    // ordenando a lista por ondem alfabetica de A-Z
    listaNomesExibicaoFiltragram.sort((a, b) {
      return a.categoriaVoluntario.compareTo(b.categoriaVoluntario);
    });
  }

  // Metodo para chamar deletar tabela
  chamarDeletar(CheckBoxModeloVoluntario checkbox) async {
    var db = FirebaseFirestore.instance;
    await db
        .collection(nomeColecaoUsuariosFireBase)
        .doc(uidUsuario)
        .collection(nomeColecaoFireBase)
        .doc(checkbox.id)
        .delete()
        .then(
          (doc) {
            setState(() {
              chamarTelaCarregamento();
              realizarBuscaDadosFireBase();
              chamarExibirMensagemSucesso();
            });
          },
          onError: (e) {
            setState(() {
              exibirWidgetCarregamento = false;
            });
            chamarExibirMensagemErro("Erro Deletar: ${e.toString()}");
          },
        );
  }

  redirecionarProximaTela() {
    PassarPegarDados.passarNomesVoluntarios(listaNomesSelecionados);
    Navigator.pushReplacementNamed(
      context,
      Constantes.rotaTelaSelecaoDiasSemana,
    );
  }

  Future<void> alertaExclusao(
    BuildContext context,
    CheckBoxModeloVoluntario checkbox,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            Textos.tituloAlertaExclusao,
            style: const TextStyle(color: Colors.black),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  Textos.descricaoAlertaExclusao,
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 10),
                Wrap(
                  children: [
                    Text(
                      checkbox.texto,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Não', style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Sim', style: TextStyle(color: Colors.black)),
              onPressed: () {
                chamarDeletar(checkbox);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget botoesIcone(IconData icone, Color corBotao) => Container(
    margin: EdgeInsets.symmetric(horizontal: 5.0),
    width: 40,
    height: 40,
    child: FloatingActionButton(
      heroTag: icone.toString(),
      onPressed: () {
        setState(() {
          exibirTelaFiltro = !exibirTelaFiltro;
        });
      },
      child: Icon(icone, color: corBotao, size: 25),
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
                  title: Text(Textos.telaSelecaoVoluntariosTitulo),
                  actions: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (listaNomesVoluntariosListaReferencia.isEmpty) {
                          return Container();
                        } else {
                          return botoesIcone(
                            filtroDesativado ==
                                    Textos.telaSelecaoVoluntariosFiltrarTodos
                                ? Constantes.iconeFiltroDesativado
                                : Constantes.iconeFiltroAtivo,
                            PaletaCores.corAzulEscuro,
                          );
                        }
                      },
                    ),
                  ],
                  leading: IconButton(
                    color: Colors.white,
                    onPressed: () {
                      PassarPegarDados.passarNomesLocaisTrabalho([]);
                      Navigator.popAndPushNamed(
                        context,
                        Constantes.rotaTelaSelecaoLocalTrabalho,
                      );
                    },
                    icon: const Icon(Icons.arrow_back_ios),
                  ),
                ),
                body: Container(
                  color: Colors.white,
                  width: larguraTela,
                  height: alturaTela,
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (listaNomesExibicaoFiltragram.isEmpty) {
                              return Container(
                                margin: const EdgeInsets.all(10.0),
                                transformAlignment: Alignment.center,
                                alignment: Alignment.center,
                                child: Text(
                                  Textos.erroBaseDadosVazia,
                                  textAlign: TextAlign.center,
                                  style: TextTheme.of(context).bodySmall,
                                ),
                              );
                            } else {
                              return LayoutBuilder(
                                builder: (context, constraints) {
                                  if (exibirTelaFiltro) {
                                    return Column(
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 10.0,
                                          ),
                                          width: larguraTela,
                                          child: Text(
                                            textAlign: TextAlign.center,
                                            Textos
                                                .telaSelecaoVoluntariosFiltroDescricao,
                                            style:
                                                TextTheme.of(context).bodySmall,
                                          ),
                                        ),
                                        //Area de exibicao dos voluntarios
                                        Card(
                                          child: SizedBox(
                                            height:
                                                Platform.isAndroid ||
                                                        Platform.isIOS
                                                    ? listaNomesSelecionados
                                                            .isNotEmpty
                                                        ? alturaTela * 0.35
                                                        : alturaTela * 0.45
                                                    : listaNomesSelecionados
                                                        .isNotEmpty
                                                    ? alturaTela * 0.45
                                                    : alturaTela * 0.6,
                                            width:
                                                Platform.isAndroid ||
                                                        Platform.isIOS
                                                    ? larguraTela
                                                    : larguraTela * 0.9,
                                            child: ListView(
                                              children: [
                                                ...listaNomeCategoriasVoluntario
                                                    .entries
                                                    .map((e) {
                                                      return radioButtonFiltro(
                                                        e.key
                                                            .toString()
                                                            .replaceAll("(", "")
                                                            .replaceAll(
                                                              ")",
                                                              "",
                                                            ),
                                                        e.value,
                                                      );
                                                    }),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  } else {
                                    return Column(
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 10.0,
                                          ),
                                          width: larguraTela,
                                          child: Text(
                                            textAlign: TextAlign.center,
                                            Textos
                                                .telaSelecaoDescricaoSelecaoVoluntarios,
                                            style:
                                                TextTheme.of(context).bodySmall,
                                          ),
                                        ),

                                        //Area de exibicao dos voluntarios
                                        Card(
                                          child: SizedBox(
                                            height:
                                                Platform.isAndroid ||
                                                        Platform.isIOS
                                                    ? listaNomesSelecionados
                                                            .isNotEmpty
                                                        ? alturaTela * 0.35
                                                        : alturaTela * 0.45
                                                    : listaNomesSelecionados
                                                        .isNotEmpty
                                                    ? alturaTela * 0.45
                                                    : alturaTela * 0.6,
                                            width:
                                                Platform.isAndroid ||
                                                        Platform.isIOS
                                                    ? larguraTela
                                                    : larguraTela * 0.9,
                                            child: ListView(
                                              children: [
                                                ...listaNomesExibicaoFiltragram
                                                    .map(
                                                      (e) =>
                                                          checkBoxPersonalizado(
                                                            e,
                                                            larguraTela,
                                                          ),
                                                    ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                },
                              );
                            }
                          },
                        ),
                      ),
                      Visibility(
                        visible:
                            listaNomesSelecionados.isNotEmpty ? true : false,
                        child: SizedBox(
                          height: 100,
                          width:
                              Platform.isAndroid || Platform.isIOS
                                  ? larguraTela
                                  : larguraTela * 0.9,
                          child: Card(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        textAlign: TextAlign.center,
                                        Textos
                                            .telaSelecaoDescricaoVoluntarioNomesSelecionadosQuantidade,
                                        style: TextTheme.of(context).bodySmall,
                                      ),
                                      Text(
                                        textAlign: TextAlign.center,
                                        listaNomesSelecionados.length
                                            .toString(),
                                        style: TextTheme.of(context).bodySmall,
                                      ),
                                    ],
                                  ),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    children: [
                                      Text(
                                        textAlign: TextAlign.center,
                                        Textos
                                            .telaSelecaoDescricaoVoluntarioNomesSelecionados,
                                        style: TextTheme.of(context).bodySmall,
                                      ),
                                      Text(
                                        textAlign: TextAlign.center,
                                        listaNomesSelecionadosExibicao
                                            .toString()
                                            .replaceAll("_", " ")
                                            .replaceAll("[", " ")
                                            .replaceAll("]", " "),
                                        style: TextTheme.of(context).bodySmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                bottomNavigationBar: Container(
                  alignment: Alignment.center,
                  color: Colors.white,
                  width: larguraTela,
                  height: 100,
                  child: Wrap(
                    alignment: WrapAlignment.spaceAround,
                    children: [
                      SizedBox(
                        width: 160,
                        height: 40,
                        child: FloatingActionButton(
                          heroTag: Textos.btnAvancar,
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                              context,
                              Constantes.rotaTelaCadastroDadosVoluntarios,
                            );
                          },
                          child: Text(
                            Textos.btnCadastrarVoluntarios,
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        height: 40,
                        child: FloatingActionButton(
                          heroTag: Textos.btnAvancar,
                          onPressed: () {
                            if (validarQuantidadeVoluntarios()) {
                              redirecionarProximaTela();
                            } else if (validarQuantidadeVoluntarios() ==
                                false) {
                              MetodosAuxiliares.exibirMensagens(
                                Constantes.tipoNotificacaoErro,
                                Textos.erroQuantidadeSelecionadaInsuficiente +
                                    listaValidarQuantidadeVoluntarios.length
                                        .toString(),
                                context,
                              );
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
              );
            }
          },
        ),
      ),
    );
  }
}
