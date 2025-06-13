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
import 'package:sscaleg/widgets/widget_configuracao_pdf.dart';
import '../../Modelo/check_box_modelo.dart';
import '../../uteis/estilo.dart';
import '../../uteis/paleta_cores.dart';
import '../../uteis/constantes.dart';

class TelaObservacao extends StatefulWidget {
  const TelaObservacao({
    super.key,
    required this.cabecalhoEscala,
    required this.linhasEscala,
    required this.nomeTabela,
    required this.idTabelaSelecionada,
  });

  final List<dynamic> cabecalhoEscala;
  final List<Map> linhasEscala;
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
  TextEditingController nomeControle = TextEditingController(text: "");

  @override
  void initState() {
    super.initState();
    realizarBuscaDadosFireBase();
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
            verificarItensSelecionados();
          });
        },
      );

  // metodo para verificar se o item foi selecionado
  // para adicionar na lista de itens selecionados
  verificarItensSelecionados() {
    //verificando cada elemento da lista de nomes cadastrados
    for (var element in listaNomesCadastrados) {
      //verificando se o usuario selecionou um item
      if (element.checked == true) {
        // verificando se o item Nao foi adicionado anteriormente na lista
        if (!(listaObservacaoSelecionadas.contains(element.texto))) {
          //add item
          listaObservacaoSelecionadas.add(element.texto);
        }
      } else if (element.checked == false) {
        // removendo item caso seja desmarcado
        listaObservacaoSelecionadas.remove(element.texto);
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

  limparDados() {
    listaNomesCadastrados.clear();
    nomeControle.clear();
    listaObservacaoSelecionadas.clear();
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
              chamarExibirMensagemErro("Erro Buscar Locais: ${e.toString()}");
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

  redirecionarProximaTela() {
    PassarPegarDados.passarNomesLocaisTrabalho(listaObservacaoSelecionadas);
    Navigator.pushReplacementNamed(
      context,
      Constantes.rotaTelaCadastroSelecaoVoluntarios,
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

  Widget botoesAcoes(String nomeBotao, IconData icone) => SizedBox(
    height: 60,
    width: 150,
    child: FloatingActionButton(
      elevation: 0,
      heroTag: nomeBotao,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: PaletaCores.corCastanho),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      onPressed: () async {
        if (nomeBotao == Textos.btnBaixarPDF) {
          setState(() {
            exibirWidgetConfiguracaoPDF = true;
          });
          // GerarPDFEscala gerarPDF = GerarPDFEscala(
          //     escala: escala,
          //     nomeEscala: widget.nomeTabela,
          //     exibirMesaApoio: exibirOcultarCampoMesaApoio,
          //     exibirRecolherOferta: exibirOcultarCampoRecolherOferta,
          //     exibirIrmaoReserva: exibirOcultarCampoIrmaoReserva,
          //     exibirServirSantaCeia: exibirOcultarServirSantaCeia,
          //     exibirUniformes: exibirOcultarCampoUniforme);
          // gerarPDF.pegarDados();
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, color: PaletaCores.corAzulMagenta, size: 30),
          Text(
            nomeBotao,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: PaletaCores.corAzulMagenta,
            ),
          ),
        ],
      ),
    ),
  );

  Widget botaoIcone(
    IconData icone,
    Color corBotao,
    double largura,
    double altura,
  ) => Container(
    margin: EdgeInsets.symmetric(horizontal: 5.0),
    width: largura,
    height: altura,
    child: FloatingActionButton(
      heroTag: icone.toString(),
      onPressed: () {
        if (icone == Constantes.iconeExclusao) {
          setState(() {
            exibirWidgetConfiguracaoPDF = false;
          });
        }
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
                  title: Text(Textos.telaObservacaoTitulo),
                  leading: IconButton(
                    color: Colors.white,
                    onPressed: () {
                      redirecionarTelaAnterior();
                    },
                    icon: const Icon(Icons.arrow_back_ios),
                  ),
                ),
                body: LayoutBuilder(
                  builder: (context, constraints) {
                    if (exibirWidgetConfiguracaoPDF) {
                      return WidgetConfiguracaoPDF(
                        cabecalhoEscala: widget.cabecalhoEscala,
                        escalaCompleta: widget.linhasEscala,
                        observacoes: listaObservacaoSelecionadas,
                      );
                    } else {
                      return Container(
                        color: Colors.white,
                        width: larguraTela,
                        height: alturaTela,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Container(
                                height: alturaTela * 0.22,
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
                                          Textos.telaObservacaoCadastro,
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
                                                      ? larguraTela * 0.6
                                                      : 200,
                                              child: TextFormField(
                                                maxLines: 3,
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
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 10.0,
                                            ),
                                            width: 100,
                                            height: 50,
                                            child: FloatingActionButton(
                                              heroTag: Textos.btnCadastrar,
                                              onPressed: () {
                                                validarCampoEChamarCadastrar();
                                              },
                                              child: Text(Textos.btnCadastrar),
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
                                height: alturaTela * 0.48,
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
                                                    .telaObservacaoDescricaoSelecao,
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
                                                height: alturaTela * 0.37,
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
                          ),
                        ),
                      );
                    }
                  },
                ),
                bottomNavigationBar: Container(
                  alignment: Alignment.center,
                  color: Colors.white,
                  width: larguraTela,
                  height: 140,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (exibirWidgetConfiguracaoPDF) {
                            return botaoIcone(
                              Constantes.iconeExclusao,
                              PaletaCores.corRosaAvermelhado,
                              50,
                              50,
                            );
                          } else {
                            return botoesAcoes(
                              Textos.btnBaixarPDF,
                              Constantes.iconeBaixar,
                            );
                          }
                        },
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
