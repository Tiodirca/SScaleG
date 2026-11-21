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

class TelaObservacao extends StatefulWidget {
  const TelaObservacao({
    super.key,
    required this.nomeTabela,
    required this.idTabelaSelecionada,
  });

  final String nomeTabela;
  final String idTabelaSelecionada;

  @override
  State<TelaObservacao> createState() => _TelaObservacaoState();
}

class _TelaObservacaoState extends State<TelaObservacao> {
  List<CheckBoxModelo> listaNomesCadastrados = [];
  List<String> listaObservacaoSelecionadas = [];
  bool exibirWidgetCarregamento = true;
  final validacaoFormulario = GlobalKey<FormState>();
  Estilo estilo = Estilo();
  bool exibirWidgetConfiguracaoPDF = false;
  int indexTabela = 0;
  String nomeCadastro = "";
  String nomeColecaoFireBase = Constantes.fireBaseColecaoNomeObservacao;
  String nomeDocumentoFireBase = Constantes.fireBaseDocumentoNomeObservacao;
  String uidUsuario = "";
  String nomeColecaoUsuariosFireBase = Constantes.fireBaseColecaoUsuarios;
  TextEditingController nomeControle = TextEditingController(text: "");

  @override
  void initState() {
    super.initState();
    uidUsuario =
        PassarPegarDados.recuperarInformacoesUsuario().entries.first.value;
    listaObservacaoSelecionadas = PassarPegarDados.recuperarObservacoesPDF();
    Timer(const Duration(seconds: 1), () {
      realizarBuscaDadosFireBase();
    });
  }

  Widget checkBoxPersonalizado(CheckBoxModelo checkBoxModel) =>
      CheckboxListTile(
        activeColor: PaletaCores.corAzulEscuro,
        checkColor: PaletaCores.corRosaClaro,
        secondary: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(left: 10),
              width: 30,
              height: 30,
              child: FloatingActionButton(
                tooltip: Textos.btnEditar,
                heroTag: "btnEditar${checkBoxModel.id}",
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(
                    color: PaletaCores.corAzulEscuro,
                    width: 1,
                  ),
                ),
                child: const Icon(Icons.edit, size: 20),
                onPressed: () {
                  alertaEdicao(context, checkBoxModel);
                },
              ),
            ),
            const SizedBox(width: 8),
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
            verificarItensSelecionados();
          });
        },
      );

  verificarItensSelecionados() {
    for (var element in listaNomesCadastrados) {
      if (element.checked == true) {
        if (!(listaObservacaoSelecionadas.contains(element.texto))) {
          listaObservacaoSelecionadas.add(element.texto);
        }
      } else if (element.checked == false) {
        listaObservacaoSelecionadas.remove(element.texto);
      }
    }
  }

  atualizarObservacao(CheckBoxModelo checkbox, String novoTexto) async {
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

      // Atualiza na lista de observações selecionadas para o PDF, se estiver presente
      final indiceSelecionado = listaObservacaoSelecionadas.indexOf(
        checkbox.texto,
      );
      if (indiceSelecionado != -1) {
        listaObservacaoSelecionadas[indiceSelecionado] = textoLimpo;
      }

      limparDados();
      realizarBuscaDadosFireBase();
      chamarExibirMensagemSucesso();
    } catch (e) {
      setState(() {
        exibirWidgetCarregamento = false;
      });
      chamarExibirMensagemErro(
        "Erro Atualizar Observação: ${e.toString()}",
      );
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
            "Editar observação",
            style: TextStyle(color: Colors.black),
          ),
          content: Form(
            key: formEdicaoKey,
            child: TextFormField(
              controller: edicaoControle,
              autofocus: true,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: Textos.telaObservacaoHintTextField,
              ),
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
                  atualizarObservacao(checkbox, textoAtualizado);
                }
              },
            ),
          ],
        );
      },
    );
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
          chamarExibirMensagemErro(
            "Erro Cadastrar Observação: ${e.toString()}",
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
          chamarExibirMensagemErro(
            "Erro Buscar Observações: ${e.toString()}",
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
      indexTabela++;
      listaNomesCadastrados.add(dados);
      if (indexTabela == tamanhoTabela) {
        setState(() {
          indexTabela = 0;
          for (var element in listaObservacaoSelecionadas) {
            recuperarCheckBoxMarcado(element);
          }
          ordenarListaOrdemAlfabetica();
          exibirWidgetCarregamento = false;
        });
      }
    }
  }

  recuperarCheckBoxMarcado(String item) {
    for (var element in listaNomesCadastrados) {
      if (item == element.texto) {
        setState(() {
          element.checked = true;
        });
      }
    }
  }

  ordenarListaOrdemAlfabetica() {
    listaNomesCadastrados.sort((a, b) {
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
          listaObservacaoSelecionadas.remove(checkbox.texto);
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
    PassarPegarDados.passarObservacoesPDF(listaObservacaoSelecionadas);
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
                  title: Text(Textos.telaObservacaoTitulo),
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
                                    Textos.telaObservacaoCadastro,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.start,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    Form(
                                      key: validacaoFormulario,
                                      child: SizedBox(
                                        width:
                                        Platform.isWindows
                                            ? larguraTela * 0.6
                                            : larguraTela * 0.9,
                                        child: TextFormField(
                                          maxLines: 2,
                                          controller: nomeControle,
                                          onFieldSubmitted: (value) {
                                            validarCampoEChamarCadastrar();
                                          },
                                          decoration: InputDecoration(
                                            hintText:
                                            Textos
                                                .telaObservacaoHintTextField,
                                          ),
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
                                      margin: EdgeInsets.symmetric(
                                        vertical:
                                        Platform.isAndroid || Platform.isIOS
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
                                          style: TextStyle(color: Colors.black),
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
                              if (listaNomesCadastrados.isNotEmpty) {
                                return SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 10.0,
                                        ),
                                        width: larguraTela,
                                        child: Text(
                                          textAlign: TextAlign.center,
                                          Textos.telaObservacaoDescricaoSelecao,
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                      ),
                                      Card(
                                        child: SizedBox(
                                          height: alturaTela * 0.35,
                                          width:
                                          Platform.isAndroid ||
                                              Platform.isIOS
                                              ? larguraTela
                                              : larguraTela * 0.8,
                                          child: ListView(
                                            children: [
                                              ...listaNomesCadastrados.map(
                                                    (e) => checkBoxPersonalizado(e),
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
                    ),
                  ),
                ),
                bottomNavigationBar: Container(
                  alignment: Alignment.center,
                  color: Colors.white,
                  width: larguraTela,
                  height: 70,
                  child: BarraNavegacao(),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}