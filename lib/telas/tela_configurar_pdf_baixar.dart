import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sscaleg/Widgets/tela_carregamento.dart';
import 'package:sscaleg/uteis/metodos_auxiliares.dart';
import 'package:sscaleg/uteis/passar_pegar_dados.dart';
import 'package:sscaleg/uteis/textos.dart';
import 'package:sscaleg/widgets/barra_navegacao_widget.dart';
import '../Modelo/check_box_modelo.dart';
import '../uteis/estilo.dart';
import '../uteis/paleta_cores.dart';
import '../uteis/constantes.dart';

class TelaConfigurarPDFBaixar extends StatefulWidget {
  const TelaConfigurarPDFBaixar({
    super.key,
    required this.cabecalhoEscala,
    required this.linhasEscala,
    required this.observacoes,
    required this.nomeTabela,
    required this.idTabelaSelecionada,
  });

  final List<dynamic> cabecalhoEscala;
  final List<Map> linhasEscala;
  final List<String> observacoes;
  final String nomeTabela;
  final String idTabelaSelecionada;

  @override
  State<TelaConfigurarPDFBaixar> createState() =>
      _TelaConfigurarPDFBaixarState();
}

class _TelaConfigurarPDFBaixarState extends State<TelaConfigurarPDFBaixar> {
  List<CheckBoxModelo> listaNomesCadastrados = [];
  List<CheckBoxModelo> listaCabecalhosExibicao = [];
  List<String> listaObservacoes = [];
  bool exibirWidgetCarregamento = true;
  bool exibirSelecaoCamposEscala = false;
  final validacaoFormulario = GlobalKey<FormState>();
  Estilo estilo = Estilo();
  String checkBoxSelecionado = "";
  int indexTabela = 0;
  String nomeCadastro = "";
  String nomeColecaoFireBase = Constantes.fireBaseColecaoNomeCabecalhoPDF;
  String nomeDocumentoFireBase = Constantes.fireBaseDocumentoNomeCabecalhoPDF;
  TextEditingController nomeControle = TextEditingController(text: "");

  @override
  void initState() {
    super.initState();
    listaObservacoes = PassarPegarDados.recuperarObservacoesPDF();
    for (var element in widget.cabecalhoEscala) {
      if (!(element.contains(Constantes.dataCulto) ||
          element.contains(Constantes.horarioTrabalho) ||
          element.contains(Constantes.editar) ||
          element.contains(Constantes.excluir))) {
        listaCabecalhosExibicao.add(
          CheckBoxModelo(texto: element, checked: true),
        );
      }
    }
    realizarBuscaDadosFireBase();
  }

  Widget botoesSwitch(String label,bool valorSwitch) => Container(
    color: Colors.green,
    margin: EdgeInsets.symmetric(horizontal: 1.0),
    width: 120,
    height: 60,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Text(label),
          Switch(
            inactiveThumbColor: PaletaCores.corAzulMagenta,
            value: valorSwitch,
            activeColor: PaletaCores.corAzulMagenta,
            onChanged: (bool valor) {
              setState(() {});
            },
          ),
        ],
      ),
    ),
  );

  Widget checkBoxPersonalizado(CheckBoxModelo checkBoxModel) =>
      CheckboxListTile(
        activeColor: PaletaCores.corAzulEscuro,
        checkColor: PaletaCores.corRosaClaro,
        secondary: SizedBox(
          width: 30,
          height: 30,
          child: FloatingActionButton(
            heroTag: "btnExcluir${checkBoxModel.id}",
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
        title: Text(checkBoxModel.texto, style: const TextStyle(fontSize: 20)),
        value: checkBoxModel.checked,
        side: const BorderSide(width: 2, color: PaletaCores.corAzulEscuro),
        onChanged: (value) {
          setState(() {
            // verificando se o balor
            checkBoxModel.checked = value!;
            validarSelecoes(checkBoxModel);
          });
        },
      );

  Widget checkBox(CheckBoxModelo checkBoxModel) => CheckboxListTile(
    activeColor: PaletaCores.corAzulEscuro,
    checkColor: PaletaCores.corRosaClaro,
    title: Text(checkBoxModel.texto, style: const TextStyle(fontSize: 20)),
    value: checkBoxModel.checked,
    side: const BorderSide(width: 2, color: PaletaCores.corAzulEscuro),
    onChanged: (value) {
      setState(() {
        // verificando se o balor
        checkBoxModel.checked = value!;
        //validarSelecoes(checkBoxModel);
      });
    },
  );

  validarSelecoes(CheckBoxModelo checkBoxModel) {
    //verificando se o checkbox selecionado
    if (checkBoxModel.checked == true) {
      // caso tenha sido definir que a variavel receber o valor
      checkBoxSelecionado = checkBoxModel.texto;
    } else {
      // caso seja desmarcado vai receber o seguinte valor
      checkBoxSelecionado = "";
    }
    //percorrendo a lista
    for (var element in listaNomesCadastrados) {
      //caso a variavel seja DIFERENTE do elemento passado
      if (checkBoxSelecionado != element.texto) {
        // definir que o valor do elemento sera
        // false para poder desmarcar na lista de checkbox
        element.checked = false;
      }
    }
  }

  // metodo para cadastrar item
  cadastrarNome() async {
    setState(() {
      exibirWidgetCarregamento = true;
    });
    try {
      // instanciando Firebase
      var db = FirebaseFirestore.instance;
      db
          .collection(nomeColecaoFireBase) // passando a colecao
          .doc() //passando o documento
          .set({nomeDocumentoFireBase: nomeCadastro})
          .then(
            (value) {
              limparDados();
              realizarBuscaDadosFireBase();
              chamarExibirMensagemSucesso();
            },
            onError: (e) {
              setState(() {
                exibirWidgetCarregamento = false;
              });
              chamarExibirMensagemErro("Erro Cadastrar : ${e.toString()}");
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

  chamarExibirMensagemSucesso() {
    MetodosAuxiliares.exibirMensagens(
      Constantes.tipoNotificacaoSucesso,
      Textos.notificacaoSucesso,
      context,
    );
  }

  limparDados() {
    listaNomesCadastrados.clear();
    nomeControle.clear();
  }

  realizarBuscaDadosFireBase() async {
    try {
      var db = FirebaseFirestore.instance;
      //instanciano variavel
      db
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
              chamarExibirMensagemErro("Erro Buscar Item: ${e.toString()}");
            },
          );
    } catch (e) {
      setState(() {
        exibirWidgetCarregamento = false;
      });
      chamarExibirMensagemErro(e.toString());
    }
  }

  converterJsonParaObjeto(String id, int tamanhoTabela) async {
    var db = FirebaseFirestore.instance;
    final ref = db
        .collection(nomeColecaoFireBase)
        .doc(id)
        .withConverter(
          // chamando modelos para fazer conversao
          fromFirestore: CheckBoxModelo.fromFirestore,
          toFirestore: (CheckBoxModelo checkbox, _) => checkbox.toFirestore(),
        );

    final docSnap = await ref.get();
    final dados = docSnap.data(); // convertendo
    if (dados != null) {
      // pegando o id para posteriormente excluir o item caso seja necessario
      dados.id = docSnap.id;
      indexTabela++;
      //adicionando os dados convertidos na lista
      listaNomesCadastrados.add(dados);
      if (indexTabela == tamanhoTabela) {
        setState(() {
          indexTabela = 0;
          ordenarListaOrdemAlfabetica();
          exibirWidgetCarregamento = false;
        });
      }
    }
  }

  ordenarListaOrdemAlfabetica() {
    // ordenando a lista por ondem alfabetica de A-Z
    listaNomesCadastrados.sort((a, b) {
      return a.texto.compareTo(b.texto);
    });
  }

  @override
  void dispose() {
    super.dispose();
    PassarPegarDados.passarObservacoesPDF([]);
  }

  // Metodo para chamar deletar tabela
  chamarDeletar(CheckBoxModelo checkbox) async {
    setState(() {
      exibirWidgetCarregamento = true;
    });
    var db = FirebaseFirestore.instance;
    await db
        .collection(nomeColecaoFireBase)
        .doc(checkbox.id)
        .delete()
        .then(
          (doc) {
            setState(() {
              limparDados();
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

  Future<void> alertaExclusao(
    BuildContext context,
    CheckBoxModelo checkbox,
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

  validarCampoEChamarCadastrar() {
    if (validacaoFormulario.currentState!.validate()) {
      setState(() {
        nomeCadastro = nomeControle.text.trim();
        cadastrarNome();
      });
    }
  }

  redirecionarTelaAnterior() {
    PassarPegarDados.passarObservacoesPDF(listaObservacoes);
    var dados = {};
    dados[Constantes.rotaArgumentoNomeEscala] = widget.nomeTabela;
    dados[Constantes.rotaArgumentoIDEscalaSelecionada] =
        widget.idTabelaSelecionada;
    Navigator.pushReplacementNamed(
      context,
      Constantes.rotaTelaEscalaDetalhada,
      arguments: dados,
    );
  }

  Widget botoesAcoes(
    String nomeBotao,
    IconData icone,
    Color corBotao,
    double largura,
    double altura,
  ) => SizedBox(
    height: altura,
    width: largura,
    child: FloatingActionButton(
      heroTag: nomeBotao,
      elevation: 0,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: corBotao),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      onPressed: () async {
        if (nomeBotao == Textos.btnAvancar) {
          if (checkBoxSelecionado.isNotEmpty) {
            setState(() {
              exibirSelecaoCamposEscala = true;
            });
          } else {
            MetodosAuxiliares.exibirMensagens(
              Constantes.tipoNotificacaoErro,
              Textos.erroListaVazia,
              context,
            );
          }
        } else if (nomeBotao == Textos.btnBaixarPDF) {
          List<Map> linhas = widget.linhasEscala;

          for (var element in linhas) {}
          for (var element in listaCabecalhosExibicao) {
            print("T${element.texto} ${element.checked}");
          }
        } else if (nomeBotao == Textos.btnExcluir) {
          setState(() {
            exibirSelecaoCamposEscala = false;
          });
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Visibility(
            visible: nomeBotao == Textos.btnAvancar ? false : true,
            child: Icon(icone, color: PaletaCores.corAzulMagenta, size: 30),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              if (nomeBotao == Textos.btnExcluir) {
                return Container();
              } else {
                return SizedBox(
                  width: 90,
                  child: Text(
                    nomeBotao,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                );
              }
            },
          ),
        ],
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
                  title: Text(Textos.telaConfiguracaoPDFTitulo),
                  leading: IconButton(
                    color: Colors.white,
                    onPressed: () {
                      redirecionarTelaAnterior();
                    },
                    icon: const Icon(Icons.arrow_back_ios),
                  ),
                ),
                body: Container(
                  color: Colors.white,
                  width: larguraTela,
                  height: alturaTela,
                  child: SingleChildScrollView(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (exibirSelecaoCamposEscala) {
                          return Column(
                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 10.0,
                                ),
                                width: larguraTela,
                                child: Text(
                                  Textos.descricaoTabelaSelecionada +
                                      widget.nomeTabela,
                                  textAlign: TextAlign.end,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 10.0,
                                ),
                                child: Text(
                                  Textos.telaConfiguracaoPDFDescricao,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                              Card(
                                color: Colors.white,
                                shape: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                  borderSide: BorderSide(
                                    width: 1,
                                    color: PaletaCores.corCastanho,
                                  ),
                                ),
                                child: SizedBox(
                                  height: alturaTela * 0.4,
                                  width:
                                      Platform.isAndroid || Platform.isIOS
                                          ? larguraTela
                                          : larguraTela * 0.8,
                                  child: ListView(
                                    children: [
                                      ...listaCabecalhosExibicao.map(
                                        (e) => checkBox(e),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 10.0,
                                ),
                                child: Text(
                                  Textos.switchDescricao,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              Container(
                                height: alturaTela * 0.2,
                                padding: const EdgeInsets.only(bottom: 20.0),
                                width: larguraTela,
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 10.0,
                                        ),
                                        width: larguraTela,
                                        child: Text(
                                          Textos.descricaoTabelaSelecionada +
                                              widget.nomeTabela,
                                          textAlign: TextAlign.end,
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 10.0,
                                        ),
                                        child: Text(
                                          Textos
                                              .telaConfiguracaoPDFDescricaoCadastroTitulo,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                      Wrap(
                                        crossAxisAlignment:
                                            WrapCrossAlignment.start,
                                        alignment: WrapAlignment.center,
                                        children: [
                                          Form(
                                            key: validacaoFormulario,
                                            child: SizedBox(
                                              width:
                                                  Platform.isWindows
                                                      ? 400
                                                      : 200,
                                              child: TextFormField(
                                                controller: nomeControle,
                                                onFieldSubmitted: (value) {
                                                  validarCampoEChamarCadastrar();
                                                },
                                                validator: (value) {
                                                  if (value!.isEmpty) {
                                                    return Textos
                                                        .erroCampoVazio;
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                          ),
                                          Container(
                                            margin: EdgeInsets.symmetric(
                                              vertical:
                                                  Platform.isAndroid ||
                                                          Platform.isIOS
                                                      ? 10
                                                      : 0,
                                              horizontal: 10.0,
                                            ),
                                            width: 100,
                                            height: 40,
                                            child: FloatingActionButton(
                                              heroTag: Textos.btnCadastrar,
                                              onPressed: () {
                                                validarCampoEChamarCadastrar();
                                              },
                                              child: Text(
                                                Textos.btnCadastrar,
                                                style: TextStyle(
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // area de listagem de nomes geral
                              SizedBox(
                                width: larguraTela,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    if (listaNomesCadastrados.isNotEmpty) {
                                      // area de exibicao de descricao e listagem de nomes
                                      return SingleChildScrollView(
                                        child: Column(
                                          children: [
                                            Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10.0,
                                                  ),
                                              width: larguraTela,
                                              child: Text(
                                                textAlign: TextAlign.center,
                                                Textos
                                                    .telaConfiguracaoPDFDescricaoSelecaoTitulo,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                ),
                                              ),
                                            ),
                                            // Area de Exibicao da lista com os nomes dos voluntarios
                                            Card(
                                              color: Colors.white,
                                              shape: const OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(20),
                                                ),
                                                borderSide: BorderSide(
                                                  width: 1,
                                                  color:
                                                      PaletaCores.corCastanho,
                                                ),
                                              ),
                                              child: SizedBox(
                                                height: alturaTela * 0.4,
                                                width:
                                                    Platform.isAndroid ||
                                                            Platform.isIOS
                                                        ? larguraTela
                                                        : larguraTela * 0.8,
                                                child: ListView(
                                                  children: [
                                                    ...listaNomesCadastrados.map(
                                                      (e) =>
                                                          checkBoxPersonalizado(
                                                            e,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    } else {
                                      // area caso nao tenha
                                      // nenhum voluntario cadastrado
                                      return Container(
                                        margin: const EdgeInsets.all(10.0),
                                        transformAlignment: Alignment.center,
                                        alignment: Alignment.center,
                                        child: Text(
                                          Textos.erroBaseDadosVazia,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                ),
                bottomNavigationBar: Container(
                  alignment: Alignment.center,
                  color: Colors.white,
                  width: larguraTela,
                  height: 100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Visibility(
                        visible: !exibirSelecaoCamposEscala,
                        child: botoesAcoes(
                          Textos.btnAvancar,
                          Constantes.iconeLista,
                          PaletaCores.corCastanho,
                          120,
                          40,
                        ),
                      ),
                      Visibility(
                        visible: exibirSelecaoCamposEscala,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 120,
                              height: 40,
                              child: botoesAcoes(
                                Textos.btnBaixarPDF,
                                Constantes.iconeBaixar,
                                PaletaCores.corCastanho,
                                120,
                                40,
                              ),
                            ),
                            SizedBox(width: 10),
                            botoesAcoes(
                              Textos.btnExcluir,
                              Constantes.iconeExclusao,
                              PaletaCores.corRosaAvermelhado,
                              35,
                              35,
                            ),
                          ],
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
