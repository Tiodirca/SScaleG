import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sscaleg/Modelo/check_box_modelo.dart';
import 'package:sscaleg/Uteis/paleta_cores.dart';
import 'package:sscaleg/Widgets/tela_carregamento.dart';
import 'package:sscaleg/uteis/constantes.dart';
import 'package:sscaleg/uteis/estilo.dart';
import 'package:sscaleg/uteis/metodos_auxiliares.dart';
import 'package:sscaleg/uteis/passar_pegar_dados.dart';
import 'package:sscaleg/uteis/textos.dart';
import 'package:sscaleg/widgets/barra_navegacao_widget.dart';

class WidgetOpcoesData extends StatefulWidget {
  const WidgetOpcoesData({super.key, required this.dataSelecionada});

  final String dataSelecionada;

  @override
  State<WidgetOpcoesData> createState() => _WidgetOpcoesDataState();
}

class _WidgetOpcoesDataState extends State<WidgetOpcoesData> {
  Estilo estilo = Estilo();
  String checkBoxSelecionado = "";
  bool exibirWidgetTelaCarregamento = true;
  String dataSelecionadaComDepartamento = "";
  TextEditingController nomeControle = TextEditingController(text: "");
  final validacaoFormulario = GlobalKey<FormState>();
  List<CheckBoxModelo> listaNomesCadastrados = [];
  int indexQuantidadeItensCadastrados = 0;
  String uidUsuario = "";
  String nomeColecaoUsuariosFireBase = Constantes.fireBaseColecaoUsuarios;
  String nomeColecaoFireBase = Constantes.fireBaseColecaoNomeDepartamentosData;
  String nomeDocumentoFireBase =
      Constantes.fireBaseDocumentoNomeDepartamentosData;

  @override
  void initState() {
    super.initState();
    uidUsuario =
        PassarPegarDados.recuperarInformacoesUsuario().entries.first.value;
    dataSelecionadaComDepartamento = widget.dataSelecionada;
    Timer(const Duration(seconds: 1), () {
      realizarBuscaDadosFireBase();
    });
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

  @override
  void dispose() {
    nomeControle.dispose();
    super.dispose();
    PassarPegarDados.passarConfirmacaoSelecaoDataComplemento(
      Constantes.confirmacaoSelecaoDataComplemento,
    );
  }

  realizarBuscaDadosFireBase() async {
    setState(() {
      indexQuantidadeItensCadastrados = 0;
    });
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
              Timer(const Duration(milliseconds: 500), () {
                setState(() {
                  exibirWidgetTelaCarregamento = false;
                });
              });
            });
          }
        },
        onError: (e) {
          setState(() {
            exibirWidgetTelaCarregamento = false;
          });
          chamarExibirMensagemErro(
            "Erro Buscar Departamento: ${e.toString()}",
          );
        },
      );
    } catch (e) {
      setState(() {
        exibirWidgetTelaCarregamento = false;
      });
      chamarExibirMensagemErro(e.toString());
    }
  }

  converterJsonParaObjeto(String id, int quantidade) async {
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
      listaNomesCadastrados.add(dados);
      setState(() {
        recuperarCheckBoxMarcado(dataSelecionadaComDepartamento, quantidade);
      });
    }
  }

  // Método para atualizar item editado no Firestore
  atualizarNome(CheckBoxModelo checkbox, String novoNome) async {
    final nomeLimpo = novoNome.trim();
    if (nomeLimpo.isEmpty || nomeLimpo == checkbox.texto) {
      return;
    }

    setState(() {
      exibirWidgetTelaCarregamento = true;
    });

    try {
      var db = FirebaseFirestore.instance;
      await db
          .collection(nomeColecaoUsuariosFireBase)
          .doc(uidUsuario)
          .collection(nomeColecaoFireBase)
          .doc(checkbox.id)
          .update({nomeDocumentoFireBase: nomeLimpo});

      // Atualiza o texto na data selecionada caso estivesse aplicado
      if (dataSelecionadaComDepartamento.contains("(${checkbox.texto})")) {
        dataSelecionadaComDepartamento = dataSelecionadaComDepartamento.replaceAll(
          "(${checkbox.texto})",
          "($nomeLimpo)",
        );
        PassarPegarDados.passarDataComComplemento(
          dataSelecionadaComDepartamento,
        );
      }
      if (checkBoxSelecionado == checkbox.texto) {
        checkBoxSelecionado = nomeLimpo;
      }

      limparDados();
      realizarBuscaDadosFireBase();
      chamarExibirMensagemSucesso();
    } catch (e) {
      setState(() {
        exibirWidgetTelaCarregamento = false;
      });
      chamarExibirMensagemErro(
        "Erro Atualizar Departamento: ${e.toString()}",
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
            "Editar item",
            style: TextStyle(color: Colors.black),
          ),
          content: Form(
            key: formEdicaoKey,
            child: TextFormField(
              controller: edicaoControle,
              autofocus: true,
              decoration: InputDecoration(
                hintText: Textos.labelTextFieldCampo,
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
                  final novoTexto = edicaoControle.text;
                  Navigator.of(context).pop();
                  atualizarNome(checkbox, novoTexto);
                }
              },
            ),
          ],
        );
      },
    );
  }

  chamarDeletar(CheckBoxModelo checkbox) async {
    setState(() {
      exibirWidgetTelaCarregamento = true;
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
          removerComplemetoExcluido(checkbox);
        });
      },
      onError: (e) {
        setState(() {
          exibirWidgetTelaCarregamento = false;
        });
        chamarExibirMensagemErro(
          "Erro Deletar Departamento: ${e.toString()}",
        );
      },
    );
  }

  removerComplemetoExcluido(CheckBoxModelo checkbox) {
    dataSelecionadaComDepartamento =
    dataSelecionadaComDepartamento.split(checkbox.texto)[0];
    dataSelecionadaComDepartamento = dataSelecionadaComDepartamento.replaceAll(
      "(",
      "",
    );
    PassarPegarDados.passarDataComComplemento(dataSelecionadaComDepartamento);
  }

  cadastrarNome(String nome) async {
    setState(() {
      exibirWidgetTelaCarregamento = true;
    });
    try {
      var db = FirebaseFirestore.instance;
      db
          .collection(nomeColecaoUsuariosFireBase)
          .doc(uidUsuario)
          .collection(nomeColecaoFireBase)
          .doc()
          .set({nomeDocumentoFireBase: nome.trim()})
          .then(
            (value) {
          limparDados();
          realizarBuscaDadosFireBase();
          chamarExibirMensagemSucesso();
        },
        onError: (e) {
          setState(() {
            exibirWidgetTelaCarregamento = false;
          });
          chamarExibirMensagemErro(
            "Erro Cadastrar Departamento: ${e.toString()}",
          );
        },
      );
    } catch (e) {
      setState(() {
        exibirWidgetTelaCarregamento = false;
      });
      chamarExibirMensagemErro(e.toString());
    }
  }

  validarCampoEChamarCadastrar() {
    if (validacaoFormulario.currentState!.validate()) {
      setState(() {
        cadastrarNome(nomeControle.text);
      });
    }
  }

  recuperarCheckBoxMarcado(String departamento, int quantidade) {
    indexQuantidadeItensCadastrados++;
    if (indexQuantidadeItensCadastrados == quantidade) {
      for (var element in listaNomesCadastrados) {
        if (departamento.contains(element.texto)) {
          setState(() {
            element.checked = true;
          });
        } else {
          element.checked = false;
        }
      }
      Timer(const Duration(milliseconds: 500), () {
        setState(() {
          exibirWidgetTelaCarregamento = false;
        });
      });
    }
  }

  removerDepartamentoAnteriorSelecaoCheckBox(String dataComDepartamento) {
    for (var element in listaNomesCadastrados) {
      if (dataComDepartamento.contains(element.texto)) {
        dataComDepartamento = dataComDepartamento.split(element.texto)[0];
      }
    }
    return dataComDepartamento.replaceAll("(", "").replaceAll(")", "");
  }

  alterarDataComDepartamento() {
    String opcoesAdicionaisSelecionada = "";
    for (var element in listaNomesCadastrados) {
      if (element.checked) {
        opcoesAdicionaisSelecionada = "(${element.texto})";
      }
    }
    setState(() {
      dataSelecionadaComDepartamento =
          removerDepartamentoAnteriorSelecaoCheckBox(widget.dataSelecionada);
      dataSelecionadaComDepartamento =
      "$dataSelecionadaComDepartamento$opcoesAdicionaisSelecionada";
    });
  }

  validarSelecoes(CheckBoxModelo checkBoxModel) {
    if (checkBoxModel.checked == true) {
      checkBoxSelecionado = checkBoxModel.texto;
    } else {
      checkBoxSelecionado = "";
    }
    for (var element in listaNomesCadastrados) {
      if (checkBoxSelecionado != element.texto) {
        element.checked = false;
      }
    }
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
            validarSelecoes(checkBoxModel);
          });
          alterarDataComDepartamento();
        },
      );

  Widget botoesAcoes(String nomeBotao) => Container(
    margin: EdgeInsets.symmetric(horizontal: 10),
    height: 40,
    width: 100,
    child: FloatingActionButton(
      heroTag: nomeBotao,
      elevation: 0,
      backgroundColor: Colors.white,
      onPressed: () async {
        if (nomeBotao == Textos.btnSalvarOpcaoData) {
          setState(() {
            exibirWidgetTelaCarregamento = true;
            PassarPegarDados.passarDataComComplemento(
              dataSelecionadaComDepartamento,
            );
            PassarPegarDados.passarConfirmacaoSelecaoDataComplemento(
              Constantes.confirmacaoSelecaoDataComplemento,
            );
          });
        } else if (nomeBotao == Textos.btnCadastrar) {
          validarCampoEChamarCadastrar();
        }
      },
      child: Text(
        nomeBotao,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: Colors.black),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    double larguraTela = MediaQuery.of(context).size.width;
    double alturaTela = MediaQuery.of(context).size.height;
    return Theme(
      data: estilo.estiloGeral,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (exibirWidgetTelaCarregamento) {
            return TelaCarregamento();
          } else {
            return Scaffold(
              appBar: AppBar(
                title: Text(Textos.selecaoDepartamentosTitulo),
                leading: IconButton(
                  color: Colors.white,
                  onPressed: () {
                    setState(() {
                      exibirWidgetTelaCarregamento = true;
                      PassarPegarDados.passarConfirmacaoSelecaoDataComplemento(
                        Constantes.confirmacaoSelecaoDataComplemento,
                      );
                    });
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
                      Text(
                        Textos.descricaoSelecaoDepartamentos,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(
                        dataSelecionadaComDepartamento,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        width: larguraTela,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 10.0,
                                ),
                                child: Text(
                                  Textos.descricaoSelecaoDepartamentosCadastro,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.start,
                                alignment: WrapAlignment.center,
                                children: [
                                  Form(
                                    key: validacaoFormulario,
                                    child: SizedBox(
                                      width: Platform.isWindows ? 300 : 200,
                                      child: TextFormField(
                                        decoration: InputDecoration(
                                          hintText: Textos.labelTextFieldCampo,
                                        ),
                                        controller: nomeControle,
                                        onFieldSubmitted: (value) {
                                          validarCampoEChamarCadastrar();
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
                                  botoesAcoes(Textos.btnCadastrar),
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
                                        Textos
                                            .descricaoSelecaoDepartamentosSelecao,
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                    ),
                                    Card(
                                      child: SizedBox(
                                        height: alturaTela * 0.35,
                                        width:
                                        Platform.isAndroid || Platform.isIOS
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
                width: larguraTela,
                color: Colors.white,
                height: 100,
                child: Column(
                  children: [
                    Visibility(
                      visible: listaNomesCadastrados.isNotEmpty ? true : false,
                      child: botoesAcoes(Textos.btnSalvarOpcaoData),
                    ),
                    BarraNavegacao(),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}