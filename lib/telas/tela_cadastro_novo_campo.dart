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
  });

  final String idDocumento;
  final String nomeEscala;

  @override
  State<TelaCadastroCampoNovo> createState() => _TelaCadastroCampoNovoState();
}

class _TelaCadastroCampoNovoState extends State<TelaCadastroCampoNovo> {
  List<Map> escala = [];
  int index = 0;
  Estilo estilo = Estilo();
  bool ativarDesativarBtn = true;
  bool exibirWidgetTelaCarregamento = true;
  String nomeCampoFormatado = "";
  final validacaoFormulario = GlobalKey<FormState>();
  List<String> cabecalhoEscala = [];
  TextEditingController nomeAdicionarCampo = TextEditingController(text: "");

  @override
  void initState() {
    super.initState();
    realizarBuscaDadosFireBase(widget.idDocumento, "");
    cabecalhoEscala = PassarPegarDados.recuperarCamposCadastroItem();
  }

  @override
  void dispose() {
    super.dispose();
    PassarPegarDados.passarCamposCadastroItem([]);
  }

  realizarBuscaDadosFireBase(String idDocumento, String tipoBusca) async {
    setState(() {
      //exibirWidgetCarregamento = true;
    });
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
              // for para percorrer todos os dados que a variavel recebeu
              for (var documentoFirebase in querySnapshot.docs) {
                if (!tipoBusca.contains(Constantes.tipoBuscaAdicionarCampo)) {
                  Map idDocumentoData = {};
                  idDocumentoData[Constantes.idDocumento] =
                      documentoFirebase.id;
                  escala.addAll([idDocumentoData, documentoFirebase.data()]);
                }
              }

              if (tipoBusca.contains(Constantes.tipoBuscaAdicionarCampo)) {
                setState(() {
                  cabecalhoEscala =
                      querySnapshot.docs.first.data().keys.toList();
                  //adicionando no cabecalho colunas de editar e excluir
                  cabecalhoEscala.addAll([
                    Constantes.editar,
                    Constantes.excluir,
                  ]);
                });
                redirecionarTelaCadastroItem();
              } else {
                setState(() {
                  exibirWidgetTelaCarregamento = false;
                });
              }
            } else {
              setState(() {
                if (tipoBusca.contains(Constantes.tipoBuscaAdicionarCampo)) {
                  exibirWidgetTelaCarregamento = false;
                } else {
                  ativarDesativarBtn = false;
                }
                chamarExibirMensagemErro(Textos.erroBaseDadosVazia);
              });
            }
          },
          onError: (e) {
            setState(() {
              ativarDesativarBtn = false;
            });
            chamarExibirMensagemErro("Erro ao buscar escala : ${e.toString()}");
          },
        );
  }

  chamarAtualizarCampoPercorrerEscala() {
    setState(() {
      exibirWidgetTelaCarregamento = true;
    });
    nomeCampoFormatado = nomeAdicionarCampo.text;
    //
    String idDocumentoItem = "";
    for (var element in escala) {
      if (element.keys.contains(Constantes.idDocumento)) {
        idDocumentoItem = element.values
            .toString()
            .replaceAll("(", "")
            .replaceAll(")", "");
      }
      if (!element.keys.contains(Constantes.idDocumento)) {
        atualizarCampos(
          element.entries.toList(),
          widget.idDocumento,
          idDocumentoItem,
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
    PassarPegarDados.passarCamposCadastroItem(cabecalhoEscala);
    var dados = {};
    dados[Constantes.rotaArgumentEscalaDetalhadaNomeEscala] = widget.nomeEscala;
    dados[Constantes.rotaArgumentoEscalaDetalhadaIDEscalaSelecionada] =
        widget.idDocumento;
    Navigator.pushReplacementNamed(
      context,
      Constantes.rotaTelaCadastroItem,
      arguments: dados,
    );
  }



  atualizarCampos(
    List<MapEntry> escala,
    String idDocumentoFirebase,
    String idItem,
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
              index++;
              if (index == escala.length) {
                index = 0;
                realizarBuscaDadosFireBase(
                  widget.idDocumento,
                  Constantes.tipoBuscaAdicionarCampo,
                );
                MetodosAuxiliares.exibirMensagens(
                  Constantes.tipoNotificacaoSucesso,
                  Textos.notificacaoSucesso,
                  context,
                );
              }
            },
            onError: (e) {
              chamarExibirMensagemErro("Erro ao atualizar : ${e.toString()}");
            },
          );
    } catch (e) {
      setState(() {
        //exibirWidgetCarregamento = false;
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

  Widget botoesAcoes(
    double larguraTela,
    TextEditingController controleHorario,
    String label,
  ) => Container(
    margin: const EdgeInsets.symmetric(vertical: 20.0),
    width: larguraTela,
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: []),
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
                title: Text(Textos.telaCadastroNovoCampoTitulo),
                leading: IconButton(
                  color: Colors.white,
                  onPressed: () {
                    redirecionarTelaCadastroItem();
                  },
                  icon: const Icon(Icons.arrow_back_ios),
                ),
              ),
              body: Container(
                color: Colors.white,
                width: larguraTela,
                height: alturaTela,
                child:Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                      ),
                      width: larguraTela,
                      child: Text(
                        Textos.descricaoTabelaSelecionada +
                            widget.nomeEscala,
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
