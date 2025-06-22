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
  String nomeColecaoFireBase = Constantes.fireBaseColecaoNomeDepartamentosData;
  String nomeDocumentoFireBase =
      Constantes.fireBaseDocumentoNomeDepartamentosData;

  @override
  void initState() {
    super.initState();
    dataSelecionadaComDepartamento = widget.dataSelecionada;
    realizarBuscaDadosFireBase();
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
    PassarPegarDados.passarConfirmacaoCarregamentoConcluido("");
  }

  realizarBuscaDadosFireBase() async {
    setState(() {
      indexQuantidadeItensCadastrados = 0;
    });
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
                  exibirWidgetTelaCarregamento = false;
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
      PassarPegarDados.passarConfirmacaoCarregamentoConcluido(
        Constantes.confirmacaoCarregamentoConcluidoData,
      );
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

  //metodo para verificar
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
      PassarPegarDados.passarDataComComplemento(dataSelecionadaComDepartamento);
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
        title: Text(checkBoxModel.texto, style: const TextStyle(fontSize: 20)),
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

  Widget botoesAcoes(
    String nomeBotao,
    IconData icone,
    double largura,
    double altura,
  ) => Container(
    margin: const EdgeInsets.only(bottom: 10.0),
    height: altura,
    width: largura,
    child: FloatingActionButton(
      heroTag: nomeBotao,
      elevation: 0,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: PaletaCores.corCastanho),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      onPressed: () async {
        if (nomeBotao == Textos.btnSalvarOpcaoData) {
          PassarPegarDados.passarDataComComplemento(
            dataSelecionadaComDepartamento,
          );
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, color: PaletaCores.corAzulEscuro, size: 30),
          Text(
            nomeBotao,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: PaletaCores.corAzulEscuro,
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    double larguraTela = MediaQuery.of(context).size.width;
    double alturaTela = MediaQuery.of(context).size.height;
    double alturaBarraStatus = MediaQuery.of(context).padding.top;
    double alturaAppBar = AppBar().preferredSize.height;
    return Theme(
      data: estilo.estiloGeral,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (exibirWidgetTelaCarregamento) {
            //Dentro de um SizezBox para ajustar a Exibicao da tela para nao aparecer barra rolagem
            return SizedBox(
              width: larguraTela,
              height: alturaTela - alturaBarraStatus - alturaAppBar,
              child: TelaCarregamento(),
            );
          } else {
            return Column(
              children: [
                Text(
                  Textos.descricaoSelecaoDepartamentos,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                Text(
                  dataSelecionadaComDepartamento,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  width: larguraTela,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(
                            Textos.descricaoSelecaoDepartamentosCadastro,
                            textAlign: TextAlign.justify,
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
                                  decoration:
                                  InputDecoration(
                                    hintText:
                                    Textos
                                        .labelTextFieldCampo,
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
                                child: Text(Textos.btnCadastrar,style: TextStyle(color: Colors.black),),
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
                                  Textos.descricaoSelecaoDepartamentosSelecao,
                                  style: const TextStyle(fontSize: 18),
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
            );
          }
        },
      ),
    );
  }
}
