import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sscaleg/Widgets/tela_carregamento.dart';
import 'package:sscaleg/uteis/PDF/gerar_pdf_escala.dart';
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
  List<CheckBoxModelo> listaNomeCabecalhoPDF = [];
  List<CheckBoxModelo> listaCabecalhosExibicao = [];
  List<String> listaObservacoes = [];
  bool exibirWidgetCarregamento = true;
  bool exibirSelecaoCamposEscala = false;
  final validacaoFormulario = GlobalKey<FormState>();
  Estilo estilo = Estilo();
  String nomeCabelhadoPDFSelecionado = "";
  int indexTabela = 0;
  int valorRadioButtonSelecionado = 0;
  String nomeCadastro = "";
  List<Map> linhasRecebidas = [];
  List<Map> linhasEscalaAuxiliarRemocao = [];
  double indicadorPagina = 0.5;
  String nomeColecaoFireBase = Constantes.fireBaseColecaoNomeCabecalhoPDF;
  String nomeDocumentoFireBase = Constantes.fireBaseDocumentoNomeCabecalhoPDF;
  String uidUsuario = "";
  String nomeColecaoUsuariosFireBase = Constantes.fireBaseColecaoUsuarios;
  TextEditingController nomeControle = TextEditingController(text: "");
  XFile? imagemLogo;

  @override
  void initState() {
    super.initState();
    uidUsuario =
        PassarPegarDados.recuperarInformacoesUsuario().entries.first.value;
    for (var element in widget.linhasEscala) {
      linhasRecebidas.add(element);
    }
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
    Timer(const Duration(seconds: 1), () {
      realizarBuscaDadosFireBase();
    });
  }

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
            validarSelecaoCabecalhoPDF(checkBoxModel);
          });
        },
      );

  validarSelecaoCabecalhoPDF(CheckBoxModelo checkBoxModel) {
    //verificando se o checkbox selecionado
    if (checkBoxModel.checked == true) {
      // caso tenha sido definir que a variavel receber o valor
      nomeCabelhadoPDFSelecionado = checkBoxModel.texto;
    } else {
      // caso seja desmarcado vai receber o seguinte valor
      nomeCabelhadoPDFSelecionado = "";
    }
    //percorrendo a lista
    for (var element in listaNomeCabecalhoPDF) {
      //caso a variavel seja DIFERENTE do elemento passado
      if (nomeCabelhadoPDFSelecionado != element.texto) {
        // definir que o valor do elemento sera
        // false para poder desmarcar na lista de checkbox
        element.checked = false;
      }
    }
  }

  Widget checkBoxExibicaoCamposEscala(CheckBoxModelo checkBoxModel) =>
      CheckboxListTile(
        activeColor: PaletaCores.corAzulEscuro,
        checkColor: PaletaCores.corRosaClaro,
        title: Text(
          checkBoxModel.texto.replaceAll("_", " "),
          style: const TextStyle(fontSize: 20),
        ),
        value: checkBoxModel.checked,
        onChanged: (value) {
          setState(() {
            // verificando se o balor
            checkBoxModel.checked = value!;

            validarSelecaoCamposExibicao(checkBoxModel);
          });
        },
      );

  validarSelecaoCamposExibicao(CheckBoxModelo checkBoxModel) {
    if (checkBoxModel.checked == false) {
      for (var element in linhasRecebidas) {
        element.removeWhere((key, value) {
          //verificando se a key contem o valor do texto
          if (key.toString().contains(checkBoxModel.texto)) {
            //pegando a data de cada elemento
            String data = element.entries.elementAt(0).value;
            Map itens = {};
            //adicionando no MAP os itens e a data
            itens.addEntries([
              MapEntry(key, value),
              MapEntry(Constantes.dataCulto, data),
            ]);
            //adicionando na lsita Auxiliar
            linhasEscalaAuxiliarRemocao.add(itens);
          }
          //removendo itens da lista principal
          return key.toString().contains(checkBoxModel.texto);
        });
      }
    } else if (checkBoxModel.checked == true) {
      //percorendo a lista auxiliar
      for (var itemRemovido in linhasEscalaAuxiliarRemocao) {
        // INDEX 0 sempre sera o campo QUE FOI REMOVIDO
        // verificando se o item contem o valor do texto
        if (itemRemovido.keys.elementAt(0).contains(checkBoxModel.texto)) {
          //percorrendo lista principal
          for (var element in linhasRecebidas) {
            //verificando se
            String dataListaPrincipal = element.values.elementAt(0).toString();
            String dataListaAuxiliar = itemRemovido.values.elementAt(1);

            if (dataListaPrincipal.contains(dataListaAuxiliar)) {
              //caso contenha adicionar item INDEX 0 ITEM QUE FOI REMOVIDO
              element.addEntries([
                MapEntry(
                  itemRemovido.keys.elementAt(0),
                  itemRemovido.values.elementAt(0),
                ),
              ]);
            }
          }
        }
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
          .collection(nomeColecaoUsuariosFireBase)
          .doc(uidUsuario)
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
    nomeCabelhadoPDFSelecionado = "";
    listaNomeCabecalhoPDF.clear();
    nomeControle.clear();
  }

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
        .collection(nomeColecaoUsuariosFireBase)
        .doc(uidUsuario)
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
      listaNomeCabecalhoPDF.add(dados);
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
    listaNomeCabecalhoPDF.sort((a, b) {
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
        .collection(nomeColecaoUsuariosFireBase)
        .doc(uidUsuario)
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

  selecionarLogoImagem() async {
    final ImagePicker logoImagem = ImagePicker();
    try {
      if (Platform.isIOS || Platform.isAndroid) {
        XFile? arquivoImagem = await logoImagem.pickImage(
          source: ImageSource.gallery,
        );
        if (arquivoImagem != null) {
          setState(() {
            imagemLogo = arquivoImagem;
          });
        }
      } else {
        selecionarImagemWindows(context);
      }
    } catch (e) {
      chamarExibirMensagemErro("Erro ao importar Imagem : ${e.toString()}");
    }
  }

  Future<void> selecionarImagemWindows(BuildContext context) async {
    const XTypeGroup tipoImagem = XTypeGroup(
      label: 'images',
      extensions: <String>['jpg', 'png'],
    );
    final XFile? arquivo = await openFile(
      acceptedTypeGroups: <XTypeGroup>[tipoImagem],
    );
    if (arquivo == null) {
      return;
    }
    final String arquivoCaminho = arquivo.path;

    if (context.mounted) {
      setState(() {
        imagemLogo = XFile(arquivoCaminho);
      });
    }
  }

  chamarGerarPDF() {
    if (imagemLogo != null) {
      GerarPDFEscala gerarPDFEscala = GerarPDFEscala(
        escala: linhasRecebidas,
        nomeEscala: widget.nomeTabela,
        nomeCabecalho: nomeCabelhadoPDFSelecionado,
        imagemLogo: imagemLogo,
        observacoes: listaObservacoes,
        valorOrientacaoPagina: valorRadioButtonSelecionado,
      );
      gerarPDFEscala.pegarDados();
    } else {
      chamarExibirMensagemErro(Textos.erroSemLogo);
    }
  }

  Widget botoesAcoes(String nomeBotao) => SizedBox(
    height: 40,
    width: 110,
    child: FloatingActionButton(
      heroTag: nomeBotao,
      elevation: 0,
      backgroundColor: Colors.white,
      onPressed: () async {
        if (nomeBotao == Textos.btnAvancar) {
          if (nomeCabelhadoPDFSelecionado.isNotEmpty) {
            setState(() {
              indicadorPagina = 1.0;
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
          chamarGerarPDF();
        }
      },
      child: Text(
        nomeBotao,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black),
      ),
    ),
  );

  Widget radioButton(int valor, String nomeBtn) => SizedBox(
    width: 150,
    height: 40,
    child: Row(
      children: [
        Radio(
          value: valor,
          groupValue: valorRadioButtonSelecionado,
          onChanged: (value) {
            setState(() {
              valorRadioButtonSelecionado = valor;
            });
          },
        ),
        Text(nomeBtn),
      ],
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
                      if (!exibirSelecaoCamposEscala) {
                        redirecionarTelaAnterior();
                      } else {
                        setState(() {
                          indicadorPagina = 0.5;
                          exibirSelecaoCamposEscala = false;
                        });
                      }
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
                          width: larguraTela,
                          child: Text(
                            Textos.descricaoTabelaSelecionada +
                                widget.nomeTabela,
                            textAlign: TextAlign.end,
                          ),
                        ),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (exibirSelecaoCamposEscala) {
                              return Column(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 10.0,
                                    ),
                                    child: Text(
                                      Textos.telaConfiguracaoPDFDescricao,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                  Card(
                                    child: SizedBox(
                                      height: alturaTela * 0.3,
                                      width:
                                          Platform.isAndroid || Platform.isIOS
                                              ? larguraTela
                                              : larguraTela * 0.5,
                                      child: ListView(
                                        children: [
                                          ...listaCabecalhosExibicao.map(
                                            (e) =>
                                                checkBoxExibicaoCamposEscala(e),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Card(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 10.0,
                                          ),
                                          child: Text(
                                            Textos
                                                .telaConfiguracaoPDFAdicaoLogo,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          margin: const EdgeInsets.all(10),
                                          width: 400,
                                          height: 50,
                                          child: ListTile(
                                            enableFeedback: true,
                                            trailing:
                                                imagemLogo != null
                                                    ? Image.file(
                                                      File(imagemLogo!.path),
                                                    )
                                                    : null,

                                            title: Text(
                                              Textos.btnAdicionarLogoImagem,
                                            ),
                                            leading: Icon(Icons.attach_file),
                                            onTap: () {
                                              selecionarLogoImagem();
                                            },
                                          ),
                                        ),
                                      ],
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
                                    child: Text(
                                      Textos
                                          .telaConfiguracaoPDFDescricaoCadastroTitulo,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                  SizedBox(
                                    height: alturaTela * 0.1,
                                    width: larguraTela,
                                    child: SingleChildScrollView(
                                      child: Column(
                                        children: [
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
                                                          ? 300
                                                          : 200,
                                                  child: TextFormField(
                                                    controller: nomeControle,
                                                    decoration: InputDecoration(
                                                      hintText:
                                                          Textos
                                                              .labelTextFieldCampo,
                                                    ),
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
                                        if (listaNomeCabecalhoPDF.isNotEmpty) {
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
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ),
                                                // Area de Exibicao da lista com os nomes
                                                Card(
                                                  child: SizedBox(
                                                    height: alturaTela * 0.3,
                                                    width:
                                                        Platform.isAndroid ||
                                                                Platform.isIOS
                                                            ? larguraTela
                                                            : larguraTela * 0.6,
                                                    child: ListView(
                                                      children: [
                                                        ...listaNomeCabecalhoPDF
                                                            .map(
                                                              (e) =>
                                                                  checkBoxPersonalizado(
                                                                    e,
                                                                  ),
                                                            ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width:
                                                      Platform.isAndroid ||
                                                              Platform.isIOS
                                                          ? larguraTela
                                                          : larguraTela * 0.4,
                                                  child: Card(
                                                    child: Column(
                                                      children: [
                                                        Container(
                                                          margin:
                                                              const EdgeInsets.symmetric(
                                                                horizontal:
                                                                    10.0,
                                                              ),
                                                          child: Text(
                                                            Textos
                                                                .telaConfiguracaoPDFRadioButtonDescricao,
                                                            textAlign:
                                                                TextAlign
                                                                    .center,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 18,
                                                                ),
                                                          ),
                                                        ),
                                                        Wrap(
                                                          crossAxisAlignment:
                                                              WrapCrossAlignment
                                                                  .center,
                                                          alignment:
                                                              WrapAlignment
                                                                  .center,
                                                          children: [
                                                            radioButton(
                                                              0,
                                                              Textos
                                                                  .telaConfiguracaoPDFRadioButtonHorizontalPDF,
                                                            ),
                                                            radioButton(
                                                              1,
                                                              Textos
                                                                  .telaConfiguracaoPDFRadioButtonVerticalPDF,
                                                            ),
                                                          ],
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
                                            transformAlignment:
                                                Alignment.center,
                                            alignment: Alignment.center,
                                            child: SizedBox(
                                              width: larguraTela * 0.5,
                                              child: Text(
                                                Textos.erroBaseDadosVazia,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      PaletaCores
                                                          .corRosaAvermelhado,
                                                  fontSize: 18,
                                                ),
                                              ),
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
                      ],
                    ),
                  ),
                ),
                bottomNavigationBar: Container(
                  alignment: Alignment.center,
                  color: Colors.white,
                  width: larguraTela,
                  height: 150,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Visibility(
                        visible:
                            listaNomeCabecalhoPDF.isNotEmpty ? true : false,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 150,
                              margin: EdgeInsets.all(20),
                              child: LinearProgressIndicator(
                                value: indicadorPagina,
                                minHeight: 3,
                                borderRadius: BorderRadius.circular(10),
                                valueColor: AlwaysStoppedAnimation(
                                  PaletaCores.corAzulEscuro,
                                ),
                              ),
                            ),
                            Visibility(
                              visible: !exibirSelecaoCamposEscala,
                              child: botoesAcoes(Textos.btnAvancar),
                            ),
                            Visibility(
                              visible: exibirSelecaoCamposEscala,
                              child: SizedBox(
                                width: 120,
                                height: 40,
                                child: botoesAcoes(Textos.btnBaixarPDF),
                              ),
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
