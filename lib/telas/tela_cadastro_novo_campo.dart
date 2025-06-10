import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sscaleg/Widgets/tela_carregamento.dart';
import 'package:sscaleg/uteis/constantes.dart';
import 'package:sscaleg/uteis/estilo.dart';
import 'package:sscaleg/uteis/metodos_auxiliares.dart';
import 'package:sscaleg/uteis/passar_pegar_dados.dart';
import 'package:sscaleg/uteis/textos.dart';
import 'package:sscaleg/widgets/barra_navegacao_widget.dart';

class TelaCadastroCampoNovo extends StatefulWidget {
  const TelaCadastroCampoNovo({
    super.key,
    required this.idDocumento,
    required this.nomeEscala,
    required this.tipoTelaAnterior,
  });

  final String idDocumento;
  final String nomeEscala;
  final String tipoTelaAnterior;

  @override
  State<TelaCadastroCampoNovo> createState() => _TelaCadastroCampoNovoState();
}

class _TelaCadastroCampoNovoState extends State<TelaCadastroCampoNovo> {
  List<Map> escalaQuantidadeItensCadastrados = [];
  int index = 0;
  Estilo estilo = Estilo();
  bool exibirWidgetTelaCarregamento = true;
  String nomeCampoFormatado = "";
  final validacaoFormulario = GlobalKey<FormState>();
  List<String> cabecalhoEscala = [];
  Map itensRecebidosCabecalhoLinha = {};
  String idItemAtualizar = "";
  TextEditingController nomeAdicionarCampo = TextEditingController(text: "");

  @override
  void initState() {
    super.initState();
    realizarBuscaDadosFireBase(widget.idDocumento, "");
    cabecalhoEscala = PassarPegarDados.recuperarCamposItem();
    itensRecebidosCabecalhoLinha = PassarPegarDados.recuperarItensAtualizar();
    idItemAtualizar = PassarPegarDados.recuperarIdAtualizarSelecionado();
  }

  @override
  void dispose() {
    super.dispose();
    PassarPegarDados.passarCamposItem([]);
    PassarPegarDados.passarItensAtualizar({});
    PassarPegarDados.passarIdAtualizarSelecionado("");
    PassarPegarDados.passarDataComComplemento("");
  }

  realizarBuscaDadosFireBase(String idDocumento, String tipoBusca) async {
    setState(() {
      //exibirWidgetCarregamento = true;
    });
    try {
      var db = FirebaseFirestore.instance;
      //instanciano variavel
      db
          .collection(Constantes.fireBaseColecaoEscalas)
          .doc(idDocumento)
          .collection(Constantes.fireBaseDadosCadastrados)
          .get()
          .then(
            (querySnapshot) async {
              //Veficando se nao e vazio
              if (querySnapshot.docs.isNotEmpty) {
                carregarDados(querySnapshot, tipoBusca);
                validarTipoBusca(querySnapshot, tipoBusca);
              } else {
                setState(() {
                  if (tipoBusca.contains(Constantes.tipoBuscaAdicionarCampo)) {
                    exibirWidgetTelaCarregamento = false;
                  }
                  chamarExibirMensagemErro(Textos.erroBaseDadosVazia);
                });
              }
            },
            onError: (e) {
              setState(() {
                exibirWidgetTelaCarregamento = false;
              });
              chamarExibirMensagemErro(
                "Erro ao buscar escala : ${e.toString()}",
              );
            },
          );
    } catch (e) {
      setState(() {
        exibirWidgetTelaCarregamento = false;
      });
      chamarExibirMensagemErro("Erro ao buscar escala : ${e.toString()}");
    }
  }

  carregarDados(var querySnapshot, String tipoBusca) {
    // for para percorrer todos os dados que a variavel recebeu
    for (var documentoFirebase in querySnapshot.docs) {
      if (!tipoBusca.contains(Constantes.tipoBuscaAdicionarCampo)) {
        Map idDocumentoData = {};
        idDocumentoData[Constantes.idDocumento] = documentoFirebase.id;
        escalaQuantidadeItensCadastrados.addAll([
          idDocumentoData,
          documentoFirebase.data(),
        ]);
      }
    }
  }

  validarTipoBusca(var querySnapshot, String tipoBusca) {
    if (tipoBusca.contains(Constantes.tipoBuscaAdicionarCampo)) {
      setState(() {
        cabecalhoEscala = querySnapshot.docs.first.data().keys.toList();
        //adicionando no cabecalho colunas de editar e excluir
        cabecalhoEscala.addAll([Constantes.editar, Constantes.excluir]);
      });
      if (widget.tipoTelaAnterior == Constantes.tipoTelaAnteriorCadastroItem) {
        validarRedirecionamentoTela();
      } else {}
    } else {
      setState(() {
        exibirWidgetTelaCarregamento = false;
      });
    }
  }

  chamarAtualizarCampoPercorrerEscala() {
    int tamanhoEscala = 0;
    setState(() {
      exibirWidgetTelaCarregamento = true;
    });
    nomeCampoFormatado = nomeAdicionarCampo.text;
    String idDocumentoItem = "";
    for (var element in escalaQuantidadeItensCadastrados) {
      if (element.keys.contains(Constantes.idDocumento)) {
        idDocumentoItem = element.values
            .toString()
            .replaceAll("(", "")
            .replaceAll(")", "");
      }
      if (!element.keys.contains(Constantes.idDocumento)) {
        tamanhoEscala++;
        atualizarCampos(
          element.entries.toList(),
          widget.idDocumento,
          idDocumentoItem,
          tamanhoEscala,
        );
      }
    }
  }

  criarMapComTodosOsDados(List<MapEntry> escala) {
    Map<String, dynamic> itemFinal = {};
    //percorrendo a escala para pegar cada item da escala
    // e colocar num Map para ser retornado
    for (var element in escala) {
      itemFinal[element.key] = element.value;
    }
    setState(() {
      itemFinal[nomeCampoFormatado] = "";
    });
    return itemFinal;
  }

  validarCampoEChamarAtualizarCampo() {
    if (validacaoFormulario.currentState!.validate()) {
      setState(() {
        cabecalhoEscala.clear();
        chamarAtualizarCampoPercorrerEscala();
      });
    }
  }

  redirecionarTelaCadastroItem() {
    PassarPegarDados.passarCamposItem(cabecalhoEscala);
    var dados = {};
    dados[Constantes.rotaArgumentoNomeEscala] = widget.nomeEscala;
    dados[Constantes.rotaArgumentoIDEscalaSelecionada] = widget.idDocumento;
    Navigator.pushReplacementNamed(
      context,
      Constantes.rotaTelaCadastroItem,
      arguments: dados,
    );
  }

  redirecionarTelaAtualizarItem() {
    PassarPegarDados.passarCamposItem(cabecalhoEscala);
    //PassarPegarDados.passarItensAtualizar(listaDadosItem);
    PassarPegarDados.passarIdAtualizarSelecionado(idItemAtualizar);
    var dados = {};
    dados[Constantes.rotaArgumentoNomeEscala] = widget.nomeEscala;
    dados[Constantes.rotaArgumentoIDEscalaSelecionada] = widget.idDocumento;
    Navigator.pushReplacementNamed(
      context,
      Constantes.rotaTelaAtualizarItem,
      arguments: dados,
    );
  }

  validarRedirecionamentoTela() {
    if (idItemAtualizar.isEmpty && itensRecebidosCabecalhoLinha.isEmpty) {
      redirecionarTelaCadastroItem();
    } else {
      redirecionarTelaAtualizarItem();
    }
  }

  atualizarCampos(
    List<MapEntry> escala,
    String idDocumentoFirebase,
    String idItem,
    int tamanhoEscala,
  ) async {
    try {
      var db = FirebaseFirestore.instance;
      db
          .collection(Constantes.fireBaseColecaoEscalas)
          .doc(idDocumentoFirebase)
          .collection(Constantes.fireBaseDadosCadastrados)
          .doc(idItem)
          .set(criarMapComTodosOsDados(escala))
          .then(
            (value) {
              //definindo que a cada iteracao o index ira aumentar
              index++;
              //caso o index seja igual ao tamanho da escala realizar acoes
              if (index == tamanhoEscala) {
                index = 0;
                realizarBuscaDadosFireBase(
                  widget.idDocumento,
                  Constantes.tipoBuscaAdicionarCampo,
                );
                chamarExibirMensagemSucesso();
              }
            },
            onError: (e) {
              chamarExibirMensagemErro(
                "Erro ao adicionar campo : ${e.toString()}",
              );
            },
          );
    } catch (e) {
      setState(() {
        exibirWidgetTelaCarregamento = false;
      });
      chamarExibirMensagemErro("Erro adicionar campo : ${e.toString()}");
    }
  }

  chamarExibirMensagemSucesso() {
    MetodosAuxiliares.exibirMensagens(
      Constantes.tipoNotificacaoSucesso,
      Textos.notificacaoSucesso,
      context,
    );
  }

  chamarExibirMensagemErro(String erro) {
    MetodosAuxiliares.exibirMensagens(
      Constantes.tipoNotificacaoErro,
      erro,
      context,
    );
  }

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
                title: Text(Textos.telaCadastroNovoCampoTitulo),
                leading: IconButton(
                  color: Colors.white,
                  onPressed: () {
                    validarRedirecionamentoTela();
                  },
                  icon: const Icon(Icons.arrow_back_ios),
                ),
              ),
              body: Container(
                color: Colors.white,
                width: larguraTela,
                height: alturaTela,
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10.0),
                      width: larguraTela,
                      child: Text(
                        Textos.descricaoTabelaSelecionada + widget.nomeEscala,
                        textAlign: TextAlign.end,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.all(10),
                      child: Text(
                        Textos.telaCadastroNovoCampoDescricao,
                        textAlign: TextAlign.justify,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    SizedBox(
                      width: MetodosAuxiliares.ajustarTamanhoTextField(
                        larguraTela,
                      ),
                      child: Form(
                        key: validacaoFormulario,
                        child: TextFormField(
                          controller: nomeAdicionarCampo,
                          keyboardType: TextInputType.text,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return Textos.erroCampoVazio;
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: Textos.telaCadastroCampoNovolabel,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.all(20),
                      width: 100,
                      height: 50,
                      child: FloatingActionButton(
                        heroTag: Textos.btnCadastrar,
                        onPressed: () {
                          validarCampoEChamarAtualizarCampo();
                        },
                        child: Text(Textos.btnCadastrar),
                      ),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: Container(
                color: Colors.white,
                child: BarraNavegacao(),
              ),
            );
          }
        },
      ),
    );
  }
}
