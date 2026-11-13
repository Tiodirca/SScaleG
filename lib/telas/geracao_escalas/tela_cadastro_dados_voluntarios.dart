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
import '../../Modelo/check_box_modelo.dart';
import '../../uteis/estilo.dart';
import '../../uteis/paleta_cores.dart';
import '../../uteis/constantes.dart';

class TelaCadastroDadosVoluntarios extends StatefulWidget {
  const TelaCadastroDadosVoluntarios({super.key});

  @override
  State<TelaCadastroDadosVoluntarios> createState() =>
      _TelaCadastroDadosVoluntariosState();
}

class _TelaCadastroDadosVoluntariosState
    extends State<TelaCadastroDadosVoluntarios> {
  List<String> listaValidarQuantidadeVoluntarios = [];
  bool exibirWidgetCarregamento = false;
  final validacaoFormulario = GlobalKey<FormState>();
  Estilo estilo = Estilo();
  String nomeCadastro = "";
  String nomeCategoriaVoluntario = "";
  String observacaoVoluntario = " ";
  String uidUsuario = "";
  TextEditingController nomeVoluntarioControle = TextEditingController(
    text: "",
  );
  TextEditingController categoriaVoluntarioControle = TextEditingController(
    text: "",
  );
  TextEditingController observacaoVoluntarioControle = TextEditingController(
    text: "",
  );
  int indexTabela = 0;
  String nomeColecaoUsuariosFireBase = Constantes.fireBaseColecaoUsuarios;
  String nomeColecaoFireBase = Constantes.fireBaseColecaoNomeVoluntarios;
  String nomeDocumentoFireBase = Constantes.fireBaseDocumentoNomeVoluntarios;
  String nomeDocumentoCategoriaFireBase =
      Constantes.fireBaseDocumentoCategoriaVoluntario;
  String nomeDocumentoNomeVoluntariosDiasDisponiveis =
      Constantes.fireBaseDocumentoNomeVoluntariosDiasDisponiveis;
  String nomeDocumentoObservacaoFireBase =
      Constantes.fireBaseDocumentoVoluntariosObservacao;

  List<CheckBoxModelo> listaDiasSemana = [
    CheckBoxModelo(texto: Constantes.diaSegunda),
    CheckBoxModelo(texto: Constantes.diaTerca),
    CheckBoxModelo(texto: Constantes.diaQuarta),
    CheckBoxModelo(texto: Constantes.diaQuinta),
    CheckBoxModelo(texto: Constantes.diaSexta),
    CheckBoxModelo(texto: Constantes.diaSabado),
    CheckBoxModelo(texto: Constantes.diaDomingo),
  ];
  List<String> listaDiasSelecionado = [];

  @override
  void initState() {
    super.initState();
    uidUsuario =
        PassarPegarDados.recuperarInformacoesUsuario().entries.first.value;
  }

  Widget checkBoxPersonalizado(CheckBoxModelo checkBoxModel) =>
      CheckboxListTile(
        activeColor: PaletaCores.corAzulEscuro,
        checkColor: PaletaCores.corRosaClaro,
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

  // metodo para cadastrar item
  cadastrarVoluntario() async {
    setState(() {
      exibirWidgetCarregamento = true;
    });
    if (listaDiasSelecionado.isEmpty) {
      listaDiasSelecionado.add(
        Constantes.fireBaseVoluntariosDiasDisponiveisTodoDia,
      );
    }
    try {
      // instanciando Firebase
      var db = FirebaseFirestore.instance;
      db
          .collection(nomeColecaoUsuariosFireBase) // passando a colecao
          .doc(uidUsuario)
          .collection(nomeColecaoFireBase) // passando a colecao
          .doc() //passando o documento
          .set({
            nomeDocumentoFireBase: nomeCadastro,
            nomeDocumentoCategoriaFireBase: nomeCategoriaVoluntario,
            nomeDocumentoNomeVoluntariosDiasDisponiveis:
                listaDiasSelecionado.toString(),
            nomeDocumentoObservacaoFireBase: observacaoVoluntario,
          })
          .then(
            (value) {
              chamarExibirMensagemSucesso();
              chamarLimpezaInformacoes();
            },
            onError: (e) {
              setState(() {
                exibirWidgetCarregamento = false;
              });
              chamarExibirMensagemErro("Erro ao cadastrar : ${e.toString()}");
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

  chamarLimpezaInformacoes() {
    setState(() {
      listaDiasSelecionado.clear();
      for (var element in listaDiasSemana) {
        element.checked = false;
      }
      categoriaVoluntarioControle.clear();
      nomeVoluntarioControle.clear();
      observacaoVoluntarioControle.clear();
      exibirWidgetCarregamento = false;
    });
  }

  validarCampoEChamarCadastrar() {
    if (validacaoFormulario.currentState!.validate()) {
      setState(() {
        nomeCadastro =
            nomeVoluntarioControle.text
                .trim()
                .replaceAll(" ", "_")
                .toLowerCase();
        nomeCategoriaVoluntario =
            categoriaVoluntarioControle.text
                .trim()
                .replaceAll(" ", "_")
                .toLowerCase();
        if (observacaoVoluntarioControle.text.isEmpty) {
          observacaoVoluntario = Textos.observacaoSem;
        } else {
          observacaoVoluntario =
              observacaoVoluntarioControle.text
                  .trim()
                  .replaceAll(" ", "_")
                  .toLowerCase();
        }

        cadastrarVoluntario();
      });
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
                  title: Text(Textos.telaCadastroVoluntarios),
                  leading: IconButton(
                    color: Colors.white,
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        Constantes.rotaTelaSelecaoNomesVoluntarios,
                      );
                    },
                    icon: const Icon(Icons.arrow_back_ios),
                  ),
                  actions: [],
                ),
                body: Container(
                  color: Colors.white,
                  width: larguraTela,
                  height: alturaTela,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Expanded(
                          flex: 0,
                          child: Container(
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
                                      Textos.telaSCadastroVoluntariosDescricao,
                                      textAlign: TextAlign.center,
                                      style: TextTheme.of(context).bodySmall,
                                    ),
                                  ),
                                  Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.start,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      Form(
                                        key: validacaoFormulario,
                                        child: Wrap(
                                          children: [
                                            Container(
                                              margin: EdgeInsets.all(20),
                                              width:
                                                  MetodosAuxiliares.ajustarTamanhoTextField(
                                                    larguraTela,
                                                  ),
                                              child: TextFormField(
                                                decoration: InputDecoration(
                                                  label: Text(
                                                    Textos
                                                        .labelTextFieldNomeVoluntario,
                                                  ),
                                                ),
                                                controller:
                                                    nomeVoluntarioControle,
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
                                            Container(
                                              margin: EdgeInsets.all(20),
                                              width:
                                                  MetodosAuxiliares.ajustarTamanhoTextField(
                                                    larguraTela,
                                                  ),
                                              child: TextFormField(
                                                decoration: InputDecoration(
                                                  label: Text(
                                                    Textos
                                                        .labelTextFieldCategoriaVoluntario,
                                                  ),
                                                  hintText:
                                                      Textos
                                                          .labelHintCategoriaVoluntario,
                                                ),
                                                controller:
                                                    categoriaVoluntarioControle,
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
                                            Container(
                                              margin: EdgeInsets.all(20),
                                              width:
                                                  MetodosAuxiliares.ajustarTamanhoTextField(
                                                    larguraTela,
                                                  ),
                                              child: TextFormField(
                                                decoration: InputDecoration(
                                                  label: Text(
                                                    Textos
                                                        .labelTextFieldObservacao,
                                                  ),
                                                  hintText:
                                                      Textos
                                                          .labelHintObservacaoVoluntario,
                                                ),
                                                controller:
                                                    observacaoVoluntarioControle,
                                                onFieldSubmitted: (value) {
                                                  validarCampoEChamarCadastrar();
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 0,
                          child: Column(
                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 10.0,
                                ),
                                child: Text(
                                  Textos
                                      .telaCadatroVoluntariosDescricaoDiasSemana,
                                  textAlign: TextAlign.center,
                                  style: TextTheme.of(context).bodySmall,
                                ),
                              ),
                              Card(
                                child: SizedBox(
                                  height: alturaTela * 0.5,
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
                      ],
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
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10.0),
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
