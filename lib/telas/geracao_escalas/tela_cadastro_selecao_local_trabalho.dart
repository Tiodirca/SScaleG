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

class TelaCadastroSelecaoLocalTrabalho extends StatefulWidget {
  const TelaCadastroSelecaoLocalTrabalho({super.key});

  @override
  State<TelaCadastroSelecaoLocalTrabalho> createState() =>
      _TelaCadastroSelecaoLocalTrabalhoState();
}

class _TelaCadastroSelecaoLocalTrabalhoState
    extends State<TelaCadastroSelecaoLocalTrabalho> {
  List<CheckBoxModelo> listaNomesCadastrados = [];
  List<String> listaNomesSelecionados = [];
  bool exibirWidgetCarregamento = true;
  final validacaoFormulario = GlobalKey<FormState>();
  Estilo estilo = Estilo();
  int indexTabela = 0;
  String nomeCadastro = "";
  String uidUsuario = "";
  String nomeColecaoFireBase = Constantes.fireBaseColecaoNomeLocaisTrabalho;
  String nomeDocumentoFireBase = Constantes.fireBaseDocumentoNomeLocaisTrabalho;
  String nomeColecaoUsuariosFireBase = Constantes.fireBaseColecaoUsuarios;
  TextEditingController nomeControle = TextEditingController(text: "");

  @override
  void initState() {
    super.initState();
    uidUsuario =
        PassarPegarDados.recuperarInformacoesUsuario().entries.first.value;
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
        title: Text(
          checkBoxModel.texto.replaceAll("_", " "),
          style: const TextStyle(fontSize: 20),
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
      );

  // metodo para verificar se o item foi selecionado
  // para adicionar na lista de itens selecionados
  verificarItensSelecionados() {
    //verificando cada elemento da lista de nomes cadastrados
    for (var element in listaNomesCadastrados) {
      //verificando se o usuario selecionou um item
      if (element.checked == true) {
        // verificando se o item Nao foi adicionado anteriormente na lista
        if (!(listaNomesSelecionados.contains(element.texto))) {
          //add item
          listaNomesSelecionados.add(element.texto);
        }
      } else if (element.checked == false) {
        // removendo item caso seja desmarcado
        listaNomesSelecionados.remove(element.texto);
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
    listaNomesSelecionados.clear();
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

  redirecionarProximaTela() {
    PassarPegarDados.passarNomesLocaisTrabalho(listaNomesSelecionados);
    Navigator.pushReplacementNamed(
      context,
      Constantes.rotaTelaCadastroSelecaoVoluntarios,
    );
  }

  validarCampoEChamarCadastrar() {
    if (validacaoFormulario.currentState!.validate()) {
      setState(() {
        nomeCadastro =
            nomeControle.text
                .trim()
                .replaceAll("-", "")
                .replaceAll(RegExp(r'[0-9]'), "")
                .replaceAll(" ", "_")
                .replaceAll(RegExp(r'[^\w\s]+'), "")
                .toLowerCase();
        cadastrarNome();
      });
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
                  title: Text(Textos.telaCadastroTituloSelecaoLocal),
                  leading: IconButton(
                    color: Colors.white,
                    onPressed: () {
                      Navigator.popAndPushNamed(
                        context,
                        Constantes.rotaTelaInicial,
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
                                  child: Text(
                                    Textos.telaCadastroDescricaoCadastroLocal,
                                    textAlign: TextAlign.center,
                                    style: TextTheme.of(context).bodySmall,
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
                                            hintText:
                                                Textos.labelTextFieldCampo,
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
                                    Container(
                                      margin: const EdgeInsets.symmetric(
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
                        // area de listagem de nomes geral
                        SizedBox(
                          height: alturaTela * 0.55,
                          width: larguraTela,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              if (listaNomesCadastrados.isNotEmpty) {
                                // area de exibicao de descricao e listagem de nomes
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
                                          Textos.telaCadastroDescricaoSelecaoLocal,
                                          style: TextTheme.of(context).bodySmall,
                                        ),
                                      ),
                                      // Area de Exibicao da lista com os nomes dos voluntarios
                                      Card(
                                        child: SizedBox(
                                          height: alturaTela * 0.45,
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
                                // area caso nao tenha
                                // nenhum voluntario cadastrado
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
                  height: 100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 40,
                        child: FloatingActionButton(
                          heroTag: Textos.btnAvancar,
                          onPressed: () {
                            if (listaNomesSelecionados.isEmpty) {
                              MetodosAuxiliares.exibirMensagens(
                                Constantes.tipoNotificacaoErro,
                                Textos.erroListaVazia,
                                context,
                              );
                            } else {
                              redirecionarProximaTela();
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
