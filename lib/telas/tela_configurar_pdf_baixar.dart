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
import 'package:sscaleg/uteis/seletor_cor.dart';
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
  final List linhasEscala;
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
  String corSelecionada = "#FFFFFF";
  List linhasRecebidas = [];
  List linhasEscalaAuxiliarRemocao = [];
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

    final List<dynamic> colunasRecebidasOrdenadas = [];
    for (var element in widget.cabecalhoEscala) {
      if (!(element.contains(Constantes.dataCulto) ||
          element.contains(Constantes.horarioTrabalho) ||
          element.contains(Constantes.editar) ||
          element.contains(Constantes.excluir))) {
        colunasRecebidasOrdenadas.add(element);
        listaCabecalhosExibicao.add(
          CheckBoxModelo(texto: element, checked: true),
        );
      }
    }

    for (var element in widget.linhasEscala) {
      final Map linhaOrdenada = {};

      for (final entry in element.entries) {
        final chave = entry.key.toString();
        if (chave.contains(Constantes.dataCulto) ||
            chave.contains(Constantes.horarioTrabalho)) {
          linhaOrdenada[entry.key] = entry.value;
        }
      }

      for (final coluna in colunasRecebidasOrdenadas) {
        if (element.containsKey(coluna)) {
          linhaOrdenada[coluna] = element[coluna];
        }
      }

      for (final entry in element.entries) {
        if (!linhaOrdenada.containsKey(entry.key)) {
          linhaOrdenada[entry.key] = entry.value;
        }
      }

      linhasRecebidas.add(linhaOrdenada);
    }

    listaObservacoes = PassarPegarDados.recuperarObservacoesPDF();

    Timer(const Duration(seconds: 1), () {
      realizarBuscaDadosFireBase();
    });
  }

  // Método para atualizar título de cabeçalho editado no Firestore
  atualizarCabecalhoPDF(CheckBoxModelo checkbox, String novoTexto) async {
    final textoLimpo = novoTexto.trim();
    if (textoLimpo.isEmpty || textoLimpo == checkbox.texto) {
      return;
    }

    setState(() {
      exibirWidgetCarregamento = true;
    });

    try {
      var db = FirebaseFirestore.instance;
      await db
          .collection(nomeColecaoUsuariosFireBase)
          .doc(uidUsuario)
          .collection(nomeColecaoFireBase)
          .doc(checkbox.id)
          .update({nomeDocumentoFireBase: textoLimpo});

      if (nomeCabelhadoPDFSelecionado == checkbox.texto) {
        nomeCabelhadoPDFSelecionado = textoLimpo;
      }

      final textoSelecionadoAnterior = nomeCabelhadoPDFSelecionado;
      limparDados();
      nomeCabelhadoPDFSelecionado = textoSelecionadoAnterior;
      realizarBuscaDadosFireBase();
      chamarExibirMensagemSucesso();
    } catch (e) {
      setState(() {
        exibirWidgetCarregamento = false;
      });
      chamarExibirMensagemErro("Erro Atualizar Cabeçalho: ${e.toString()}");
    }
  }

  Future<void> alertaEdicao(
    BuildContext context,
    CheckBoxModelo checkbox,
  ) async {
    final TextEditingController edicaoControle = TextEditingController(
      text: checkbox.texto,
    );
    final GlobalKey<FormState> formEdicaoKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Editar título",
            style: TextStyle(color: Colors.black),
          ),
          content: Form(
            key: formEdicaoKey,
            child: TextFormField(
              controller: edicaoControle,
              autofocus: true,
              decoration: InputDecoration(hintText: Textos.labelTextFieldCampo),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return Textos.erroCampoVazio;
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Salvar',
                style: TextStyle(
                  color: PaletaCores.corAzulEscuro,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                if (formEdicaoKey.currentState!.validate()) {
                  final textoAtualizado = edicaoControle.text;
                  Navigator.of(context).pop();
                  atualizarCabecalhoPDF(checkbox, textoAtualizado);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget checkBoxPersonalizado(CheckBoxModelo checkBoxModel) =>
      CheckboxListTile(
        activeColor: PaletaCores.corAzulEscuro,
        checkColor: PaletaCores.corRosaClaro,
        secondary: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(right: 10),
              width: 30,
              height: 30,
              child: FloatingActionButton(
                tooltip: Textos.btnEditar,
                heroTag: "btnEditar${checkBoxModel.id}",
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(
                    color: PaletaCores.corCastanho,
                    width: 1,
                  ),
                ),
                child: const Icon(Icons.edit, size: 20),
                onPressed: () {
                  alertaEdicao(context, checkBoxModel);
                },
              ),
            ),
            SizedBox(
              width: 30,
              height: 30,
              child: FloatingActionButton(
                tooltip: Textos.btnExcluir,
                heroTag: "btnExcluir${checkBoxModel.id}",
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Colors.red, width: 1),
                ),
                child: const Icon(Icons.close, size: 20),
                onPressed: () {
                  alertaExclusao(context, checkBoxModel);
                },
              ),
            ),
          ],
        ),
        title: Text(checkBoxModel.texto, style: const TextStyle(fontSize: 18)),
        value: checkBoxModel.checked,
        side: const BorderSide(width: 2, color: PaletaCores.corAzulEscuro),
        onChanged: (value) {
          setState(() {
            checkBoxModel.checked = value!;
            validarSelecaoCabecalhoPDF(checkBoxModel);
          });
        },
      );

  validarSelecaoCabecalhoPDF(CheckBoxModelo checkBoxModel) {
    if (checkBoxModel.checked == true) {
      nomeCabelhadoPDFSelecionado = checkBoxModel.texto;
    } else {
      nomeCabelhadoPDFSelecionado = "";
    }
    for (var element in listaNomeCabecalhoPDF) {
      if (nomeCabelhadoPDFSelecionado != element.texto) {
        element.checked = false;
      }
    }
  }

  Widget itemReordenavelColuna(CheckBoxModelo checkBoxModel) => ListTile(
    key: ValueKey(checkBoxModel.texto),
    leading: const Icon(Icons.drag_handle, color: PaletaCores.corAzulEscuro),
    title: Text(
      checkBoxModel.texto.replaceAll("_", " "),
      style: const TextStyle(fontSize: 18),
    ),
    trailing: Checkbox(
      activeColor: PaletaCores.corAzulEscuro,
      checkColor: PaletaCores.corRosaClaro,
      side: const BorderSide(width: 2, color: PaletaCores.corAzulEscuro),
      value: checkBoxModel.checked,
      onChanged: (value) {
        setState(() {
          checkBoxModel.checked = value!;
          validarSelecaoCamposExibicao(checkBoxModel);
        });
      },
    ),
  );

  validarSelecaoCamposExibicao(CheckBoxModelo checkBoxModel) {
    if (checkBoxModel.checked == false) {
      for (var element in linhasRecebidas) {
        element.removeWhere((key, value) {
          if (key.toString().contains(checkBoxModel.texto)) {
            String data = element.entries.elementAt(0).value;
            Map itens = {};
            itens.addEntries([
              MapEntry(key, value),
              MapEntry(Constantes.dataCulto, data),
            ]);
            linhasEscalaAuxiliarRemocao.add(itens);
          }
          return key.toString().contains(checkBoxModel.texto);
        });
      }
    } else if (checkBoxModel.checked == true) {
      for (var itemRemovido in linhasEscalaAuxiliarRemocao) {
        if (itemRemovido.keys.elementAt(0).contains(checkBoxModel.texto)) {
          for (var element in linhasRecebidas) {
            String dataListaPrincipal = element.values.elementAt(0).toString();
            String dataListaAuxiliar = itemRemovido.values.elementAt(1);

            if (dataListaPrincipal.contains(dataListaAuxiliar)) {
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

  List _obterLinhasOrdenadasParaPDF() {
    final List<String> colunasOrdenadas =
        listaCabecalhosExibicao
            .where((coluna) => coluna.checked)
            .map((coluna) => coluna.texto)
            .toList();

    return linhasRecebidas.map((linhaOriginal) {
      final Map novaLinha = {};

      for (final entry in linhaOriginal.entries) {
        final chave = entry.key.toString();
        if (chave.contains(Constantes.dataCulto) ||
            chave.contains(Constantes.horarioTrabalho)) {
          novaLinha[entry.key] = entry.value;
        }
      }

      for (final nomeColuna in colunasOrdenadas) {
        for (final entry in linhaOriginal.entries) {
          final chave = entry.key.toString();
          if (chave == nomeColuna || chave.contains(nomeColuna)) {
            novaLinha[entry.key] = entry.value;
          }
        }
      }

      for (final entry in linhaOriginal.entries) {
        if (!novaLinha.containsKey(entry.key)) {
          novaLinha[entry.key] = entry.value;
        }
      }

      return novaLinha;
    }).toList();
  }

  cadastrarNome() async {
    setState(() {
      exibirWidgetCarregamento = true;
    });
    try {
      var db = FirebaseFirestore.instance;
      db
          .collection(nomeColecaoUsuariosFireBase)
          .doc(uidUsuario)
          .collection(nomeColecaoFireBase)
          .doc()
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
      db
          .collection(nomeColecaoUsuariosFireBase)
          .doc(uidUsuario)
          .collection(nomeColecaoFireBase)
          .get()
          .then(
            (querySnapshot) async {
              if (querySnapshot.docs.isNotEmpty) {
                for (var documentoFirebase in querySnapshot.docs) {
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
          fromFirestore: CheckBoxModelo.fromFirestore,
          toFirestore: (CheckBoxModelo checkbox, _) => checkbox.toFirestore(),
        );

    final docSnap = await ref.get();
    final dados = docSnap.data();
    if (dados != null) {
      dados.id = docSnap.id;
      if (dados.texto == nomeCabelhadoPDFSelecionado) {
        dados.checked = true;
      }
      indexTabela++;
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
    listaNomeCabecalhoPDF.sort((a, b) {
      return a.texto.compareTo(b.texto);
    });
  }

  @override
  void dispose() {
    nomeControle.dispose();
    super.dispose();
    PassarPegarDados.passarObservacoesPDF([]);
  }

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
    if (arquivo != null && context.mounted) {
      setState(() {
        imagemLogo = arquivo;
      });
    }
  }

  removerLogoImagem() {
    setState(() {
      imagemLogo = null;
    });
  }

  chamarGerarPDF() {
    final linhasOrdenadas = _obterLinhasOrdenadasParaPDF();
    GerarPDFEscala gerarPDFEscala = GerarPDFEscala(
      escala: linhasOrdenadas,
      nomeEscala: widget.nomeTabela,
      nomeCabecalho: nomeCabelhadoPDFSelecionado,
      imagemLogo: imagemLogo,
      observacoes: listaObservacoes,
      cor: corSelecionada,
      valorOrientacaoPagina: valorRadioButtonSelecionado,
    );
    gerarPDFEscala.pegarDados();
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
                                      child: ReorderableListView.builder(
                                        itemCount:
                                            listaCabecalhosExibicao.length,
                                        onReorder: (
                                          int oldIndex,
                                          int newIndex,
                                        ) {
                                          setState(() {
                                            if (newIndex > oldIndex) {
                                              newIndex -= 1;
                                            }
                                            final CheckBoxModelo item =
                                                listaCabecalhosExibicao
                                                    .removeAt(oldIndex);
                                            listaCabecalhosExibicao.insert(
                                              newIndex,
                                              item,
                                            );
                                          });
                                        },
                                        itemBuilder: (context, index) {
                                          return itemReordenavelColuna(
                                            listaCabecalhosExibicao[index],
                                          );
                                        },
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
                                          width: 420,
                                          height: 50,
                                          child: ListTile(
                                            enableFeedback: true,
                                            trailing:
                                                imagemLogo != null
                                                    ? Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Image.file(
                                                          File(
                                                            imagemLogo!.path,
                                                          ),
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.close,
                                                            color: Colors.red,
                                                          ),
                                                          onPressed:
                                                              removerLogoImagem,
                                                        ),
                                                      ],
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
                                  SizedBox(
                                    width: 300,
                                    height: 100,
                                    child: SeletorCor(
                                      corInicial: '#FFFFFF',
                                      onColorSelected: (hex) {
                                        corSelecionada = hex;
                                      },
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
                                  SizedBox(
                                    width: larguraTela,
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        if (listaNomeCabecalhoPDF.isNotEmpty) {
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
                                          return Container(
                                            margin: const EdgeInsets.all(10.0),
                                            transformAlignment:
                                                Alignment.center,
                                            alignment: Alignment.center,
                                            child: SizedBox(
                                              width: larguraTela,
                                              child: Text(
                                                Textos.erroBaseDadosVazia,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
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
