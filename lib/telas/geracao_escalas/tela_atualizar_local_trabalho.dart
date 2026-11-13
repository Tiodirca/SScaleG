import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sscaleg/Widgets/tela_carregamento.dart';
import 'package:sscaleg/modelo/check_box_modelo_local_trabalho.dart';
import 'package:sscaleg/uteis/metodos_auxiliares.dart';
import 'package:sscaleg/uteis/passar_pegar_dados.dart';
import 'package:sscaleg/uteis/textos.dart';
import 'package:sscaleg/widgets/barra_navegacao_widget.dart';
import '../../Modelo/check_box_modelo.dart';
import '../../uteis/estilo.dart';
import '../../uteis/paleta_cores.dart';
import '../../uteis/constantes.dart';

class TelaAtualizarLocalTrabalho extends StatefulWidget {
  const TelaAtualizarLocalTrabalho({
    super.key,
    required this.dadosLocalTrabalho,
  });

  final CheckBoxModeloLocalTrabalho dadosLocalTrabalho;

  @override
  State<TelaAtualizarLocalTrabalho> createState() =>
      _TelaAtualizarLocalTrabalhoState();
}

class _TelaAtualizarLocalTrabalhoState
    extends State<TelaAtualizarLocalTrabalho> {
  bool exibirWidgetCarregamento = false;
  final validacaoFormulario = GlobalKey<FormState>();
  Estilo estilo = Estilo();
  int indexTabela = 0;
  String nomeLocalTrabalho = "";
  String nomeLocalTrabalhoObservacao = "";
  String uidUsuario = "";
  String nomeColecaoFireBase = Constantes.fireBaseColecaoNomeLocaisTrabalho;
  String nomeDocumentoFireBaseNomeLocal =
      Constantes.fireBaseDocumentoNomeLocaisTrabalho;
  String nomeDocumentoFireBaseLocalObservacao =
      Constantes.fireBaseDocumentoLocaisTrabalhoObservacao;
  String nomeDocumentoFireBaseLocalTrabalhoDiasObservacao =
      Constantes.fireBaseDocumentLocaisTrabalhoDiasObservacao;
  String nomeColecaoUsuariosFireBase = Constantes.fireBaseColecaoUsuarios;
  TextEditingController nomeLocalTrabalhoControle = TextEditingController(
    text: "",
  );
  TextEditingController nomeLocalTrabalhoObservacaoControle =
      TextEditingController(text: "");

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

    recuperarInformacoesUsuario();
  }

  recuperarInformacoesUsuario() {
    nomeLocalTrabalhoObservacaoControle.text =
        widget.dadosLocalTrabalho.observacaoLocal.replaceAll("_"," ");
    nomeLocalTrabalhoControle.text = widget.dadosLocalTrabalho.nome.replaceAll("_", " ");
    String diasDisponiveis = widget.dadosLocalTrabalho.diasLocalObservacao;
    setState(() {
      //percorendo a lista de dias da semana
      for (var element in listaDiasSemana) {
        //verificando se tem algum dia da semana selecionado
        if (diasDisponiveis.contains(element.texto)) {
          //caso tiver marcar
          element.checked = true;
        }
      }
      verificarItensSelecionados();
    });
  }

  redirecionarTelaSelecaoLocalTrabalho() {
    Navigator.pushReplacementNamed(
      context,
      Constantes.rotaTelaSelecaoLocalTrabalho,
    );
  }

  Widget checkBoxPersonalizado(CheckBoxModelo checkBoxModel) =>
      CheckboxListTile(
        activeColor: PaletaCores.corAzulEscuro,
        checkColor: PaletaCores.corRosaClaro,
        title: Text(
          checkBoxModel.texto.replaceAll("_", " "),
          style: const TextStyle(fontSize: 18),
        ),
        value: checkBoxModel.checked,
        onChanged: (value) {
          setState(() {
            // verificando se o balor
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
  atualizarDadosLocal() async {
    setState(() {
      exibirWidgetCarregamento = true;
    });

    if (listaDiasSelecionado.isEmpty) {
      listaDiasSelecionado.add(Constantes.fireBaseLocaisDiasObservacaoSEM);
    }
    try {
      // instanciando Firebase
      var db = FirebaseFirestore.instance;
      db
          .collection(nomeColecaoUsuariosFireBase)
          .doc(uidUsuario)
          .collection(nomeColecaoFireBase) // passando a colecao
          .doc(widget.dadosLocalTrabalho.id) //passando o documento
          .set({
            nomeDocumentoFireBaseNomeLocal: nomeLocalTrabalho,
            nomeDocumentoFireBaseLocalObservacao: nomeLocalTrabalhoObservacao,
            nomeDocumentoFireBaseLocalTrabalhoDiasObservacao:
                listaDiasSelecionado.toString(),
          })
          .then(
            (value) {
              chamarExibirMensagemSucesso();
              redirecionarTelaSelecaoLocalTrabalho();
            },
            onError: (e) {
              setState(() {
                exibirWidgetCarregamento = false;
              });
              chamarExibirMensagemErro("Erro Cadastrar Local: ${e.toString()}");
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

  validarCampoEChamarCadastrar() {
    if (validacaoFormulario.currentState!.validate()) {
      setState(() {
        nomeLocalTrabalho =
            nomeLocalTrabalhoControle.text
                .trim()
                .replaceAll("-", "")
                .replaceAll(" ", "_")
                .replaceAll(RegExp(r'[^\w\s]+'), "")
                .toLowerCase();
        if (nomeLocalTrabalhoObservacaoControle.text.isEmpty) {
          nomeLocalTrabalhoObservacao = Textos.observacaoSem;
        } else {
          nomeLocalTrabalhoObservacao =
              nomeLocalTrabalhoObservacaoControle.text
                  .trim()
                  .replaceAll(" ", "_")
                  .toLowerCase();
        }
        atualizarDadosLocal();
      });
    }
  }

  chamarLimpezaInformacoes() {
    setState(() {
      listaDiasSelecionado.clear();
      for (var element in listaDiasSemana) {
        element.checked = false;
      }
      nomeLocalTrabalhoObservacaoControle.clear();
      nomeLocalTrabalhoControle.clear();
      exibirWidgetCarregamento = false;
    });
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
                  title: Text(Textos.telaAtualizarDadosLocalTrabalho),
                  leading: IconButton(
                    color: Colors.white,
                    onPressed: () {
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
                                      Textos
                                          .telaCadastroLocaisDescricaoNomeObservacao,
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
                                                        .localTrabalhoTextFieldNome,
                                                  ),
                                                  hintText:
                                                      Textos
                                                          .localTrabalhoHintNome,
                                                ),
                                                controller:
                                                    nomeLocalTrabalhoControle,
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
                                                          .localTrabalhoHintObservacao,
                                                ),
                                                controller:
                                                    nomeLocalTrabalhoObservacaoControle,
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
                        // area de listagem de nomes geral
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
                                      .telaCadastroLocaisDescricaoDiasNecessario,
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
                      SizedBox(
                        width: 100,
                        height: 40,
                        child: FloatingActionButton(
                          heroTag: Textos.btnAtualizar,
                          onPressed: () {
                            validarCampoEChamarCadastrar();
                          },
                          child: Text(
                            Textos.btnAtualizar,
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
