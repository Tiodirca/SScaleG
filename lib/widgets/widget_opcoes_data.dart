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
          // chamando modelos para fazer conversao
          fromFirestore: CheckBoxModelo.fromFirestore,
          toFirestore: (CheckBoxModelo checkbox, _) => checkbox.toFirestore(),
        );

    final docSnap = await ref.get();
    final dados = docSnap.data(); // convertendo
    if (dados != null) {
      // pegando o id para posteriormente excluir o item caso seja necessario
      dados.id = docSnap.id;
      //adicionando os dados convertidos na lista
      listaNomesCadastrados.add(dados);
      setState(() {
        recuperarCheckBoxMarcado(dataSelecionadaComDepartamento, quantidade);
      });
    }
  }

  // Metodo para chamar deletar tabela
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

  // metodo para remover das string o complemento caso o usuario faca a exclusao dele
  removerComplemetoExcluido(CheckBoxModelo checkbox) {
    dataSelecionadaComDepartamento =
        dataSelecionadaComDepartamento.split(checkbox.texto)[0];
    dataSelecionadaComDepartamento = dataSelecionadaComDepartamento.replaceAll(
      "(",
      "",
    );
    PassarPegarDados.passarDataComComplemento(dataSelecionadaComDepartamento);
  }

  // metodo para cadastrar item
  cadastrarNome(String nome) async {
    setState(() {
      exibirWidgetTelaCarregamento = true;
    });
    try {
      // instanciando Firebase
      var db = FirebaseFirestore.instance;
      db
          .collection(nomeColecaoUsuariosFireBase)
          .doc(uidUsuario)
          .collection(nomeColecaoFireBase) // passando a colecao
          .doc() //passando o documento
          .set({nomeDocumentoFireBase: nomeControle.text})
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

  //metodo para recuperar o nome selecionado e deixar a caixa
  // do checkbox marcado quando o usuario volta na tela
  // para fazer alguma alteracao apos ja ter selecionado uma opcao antes
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

  //remover complemento caso o usuario faca alguma selecao direfente
  // metodo necessario para que o nome anterior nao permanessa na string
  removerDepartamentoAnteriorSelecaoCheckBox(String dataComDepartamento) {
    for (var element in listaNomesCadastrados) {
      if (dataComDepartamento.contains(element.texto)) {
        dataComDepartamento = dataComDepartamento.split(element.texto)[0];
      }
    }
    return dataComDepartamento.replaceAll("(", "").replaceAll(")", "");
  }

  //metodo para alterar a opcao adicional da data confirme
  // o usuario seleciona uma opcao nos checkbox
  alterarDataComDepartamento() {
    String opcoesAdicionaisSelecionada = "";
    //percorrendo os nomes cadastrados
    for (var element in listaNomesCadastrados) {
      // caso o elemento seja verdadeiro
      if (element.checked) {
        //definir que a opcao adicional vai receber o valor do elemento
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
        title: Text(checkBoxModel.texto, style: const TextStyle(fontSize: 18)),
        value: checkBoxModel.checked,
        side: const BorderSide(width: 2, color: PaletaCores.corAzulEscuro),
        onChanged: (value) {
          setState(() {
            checkBoxModel.checked = value!;
            validarSelecoes(checkBoxModel);
          });
          // //chamando metodo
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
                                        Textos
                                            .descricaoSelecaoDepartamentosSelecao,
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                    ),
                                    // Area de Exibicao da lista com os nomes dos voluntarios
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
                )
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
