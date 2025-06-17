import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sscaleg/Uteis/paleta_cores.dart';
import 'package:sscaleg/Widgets/tela_carregamento.dart';
import 'package:sscaleg/uteis/constantes.dart';
import 'package:sscaleg/uteis/estilo.dart';
import 'package:sscaleg/uteis/metodos_auxiliares.dart';
import 'package:sscaleg/uteis/passar_pegar_dados.dart';
import 'package:sscaleg/uteis/textos.dart';
import 'package:sscaleg/widgets/barra_navegacao_widget.dart';
import 'package:sscaleg/widgets/widget_opcoes_data.dart';

@immutable
class TelaCadastroItem extends StatefulWidget {
  const TelaCadastroItem({
    super.key,
    required this.nomeTabela,
    required this.idTabelaSelecionada,
  });

  final String nomeTabela;
  final String idTabelaSelecionada;

  @override
  State<TelaCadastroItem> createState() => _TelaCadastroItemState();
}

class _TelaCadastroItemState extends State<TelaCadastroItem> {
  Estilo estilo = Estilo();
  bool exibirTelaCarregamento = false;
  bool exibirTelaOpcoesData = false;
  bool exibirAcoesOpcaoData = false;
  String horarioTroca = "";
  bool exibirWidgetCarregamento = false;
  String nomeDigitado = "";
  String dataFormatada = "";
  Map itensRecebidosCabecalhoLinha = {};
  Map<dynamic, dynamic> itemDigitado = {};
  TimeOfDay? horarioTimePicker = const TimeOfDay(hour: 19, minute: 00);
  DateTime dataSelecionada = DateTime.now();
  final _formKeyFormulario = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    recuperarHorarioTroca();
    carregarCampos();
  }

  carregarCampos() {
    itensRecebidosCabecalhoLinha = PassarPegarDados.recuperarItens();
    itensRecebidosCabecalhoLinha.removeWhere((key, value) {
      return key.toString().contains(Constantes.editar);
    });
    itensRecebidosCabecalhoLinha.removeWhere((key, value) {
      return key.toString().contains(Constantes.excluir);
    });
    carregarLabelCampos();
  }

  carregarLabelCampos() {
    setState(() {
      itensRecebidosCabecalhoLinha.forEach((key, value) {
        if (!(key.toString().contains(Constantes.dataCulto) ||
            key.toString().contains(Constantes.horarioTrabalho))) {
          itemDigitado[key.toString()] = value.toString();
        }
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    PassarPegarDados.passarDataComComplemento("");
    PassarPegarDados.passarCamposItem([]);
  }

  redirecionarTelaCadastroNovoCampo() {
    var dados = {};
    PassarPegarDados.passarItens(itensRecebidosCabecalhoLinha);
    dados[Constantes.rotaArgumentoNomeEscala] = widget.nomeTabela;
    dados[Constantes.rotaArgumentoIDEscalaSelecionada] =
        widget.idTabelaSelecionada;
    dados[Constantes.rotaArgumentoTipoTelaAnteriorCadastroCampoNovo] =
        Constantes.tipoTelaAnteriorCadastroItem;
    Navigator.pushReplacementNamed(
      context,
      Constantes.rotaTelaCadastroCampoNovo,
      arguments: dados,
    );
  }

  redirecionarTelaRemoverCampos() {
    var dados = {};
    PassarPegarDados.passarItens(itensRecebidosCabecalhoLinha);
    dados[Constantes.rotaArgumentoNomeEscala] = widget.nomeTabela;
    dados[Constantes.rotaArgumentoIDEscalaSelecionada] =
        widget.idTabelaSelecionada;
    dados[Constantes.rotaArgumentoTipoTelaAnteriorCadastroCampoNovo] =
        Constantes.tipoTelaAnteriorCadastroItem;
    Navigator.pushReplacementNamed(
      context,
      Constantes.rotaTelaRemoverCampos,
      arguments: dados,
    );
  }

  // // metodo para recuperar os horarios definidos
  // // e gravados no share preferences
  recuperarHorarioTroca() async {
    //Definindo que a variavel vai receber o valor do metodo mais um pequeno espaco no final
    // espaco esse utilizado para o complemento de data para nao ficar grudado
    dataFormatada = "${formatarData(dataSelecionada)} ";
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String horarioSemana =
        prefs.getString(Constantes.sharePreferencesAjustarHorarioSemana) ?? '';
    String horarioFinalSemana =
        prefs.getString(Constantes.sharePreferencesAjustarHorarioFinalSemana) ??
        '';
    // verificando se a data corresponde a um dia do fim de semana
    if (dataFormatada.contains(Constantes.diaSabado.toLowerCase()) ||
        dataFormatada.contains(Constantes.diaDomingo.toLowerCase())) {
      setState(() {
        horarioTroca = horarioFinalSemana;
      });
    } else {
      setState(() {
        horarioTroca = horarioSemana;
      });
    }
    formatarHorario(horarioTroca);
  }

  formatarHorario(String horarioRecuperado) {
    String horarioSemCaracteres = horarioRecuperado
        .replaceAll(Textos.widgetAjustarHorarioInicio, "")
        .replaceAll(" ", "");
    DateTime conversaoHorarioPData = DateFormat(
      "HH:mm",
    ).parse(horarioSemCaracteres);
    setState(() {
      TimeOfDay conversaoDataPTimeOfDay = TimeOfDay.fromDateTime(
        conversaoHorarioPData,
      );
      horarioTimePicker = conversaoDataPTimeOfDay;
    });
  }

  formatarData(DateTime data) {
    String dataFormatada = DateFormat("dd/MM/yyyy EEEE", "pt_BR").format(data);
    return dataFormatada;
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

  verificarCarregamentoDadosConcluido() {
    String dados = PassarPegarDados.recuperarConfirmacaoCarregamentoConcluido();
    if (dados.isEmpty) {
      Timer(const Duration(seconds: 1), () {
        verificarCarregamentoDadosConcluido();
      });
    } else if (dados.contains(
      Constantes.confirmacaoCarregamentoConcluidoData,
    )) {
      setState(() {
        exibirAcoesOpcaoData = true;
      });
    }
  }

  chamarAdicionarItens() {
    itemDigitado[Constantes.dataCulto] = dataFormatada;
    itemDigitado[Constantes.horarioTrabalho] = horarioTroca;
    cadastrarItens(widget.idTabelaSelecionada);
  }

  cadastrarItens(String idDocumentoFirebase) async {
    setState(() {
      exibirWidgetCarregamento = true;
    });
    try {
      var db = FirebaseFirestore.instance;
      db
          .collection(Constantes.fireBaseColecaoEscalas)
          .doc(idDocumentoFirebase)
          .collection(Constantes.fireBaseDadosCadastrados)
          .doc()
          .set(criarMapCompativel(itemDigitado))
          .then((value) {
            setState(() {
              itemDigitado.clear();
              carregarCampos();
              exibirWidgetCarregamento = false;
            });
            chamarExibirMensagemSucesso();
          });
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

  //metodo para converter map do tipo dynamic,dynamic para o tipo String,dynamic
  criarMapCompativel(Map escala) {
    Map<String, dynamic> itemFinal = {};
    //percorrendo a escala para pegar cada item da escala
    // e colocar num Map para ser retornado
    escala.forEach((key, value) {
      itemFinal[key.toString()] = value.toString();
    });
    return itemFinal;
  }

  Widget botoesIcones(IconData icone, double tamanhoBotao, Color corBotao) =>
      SizedBox(
        height: tamanhoBotao,
        width: tamanhoBotao,
        child: FloatingActionButton(
          heroTag: icone.toString(),
          elevation: 0,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: corBotao),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          onPressed: () async {
            if (icone == Constantes.iconeExclusao) {
              setState(() {
                exibirTelaOpcoesData = false;
                exibirAcoesOpcaoData = false;
                PassarPegarDados.passarConfirmacaoCarregamentoConcluido("");
              });
            } else if (icone == Constantes.iconeMudarHorario) {
              exibirTimePicker();
            } else if (icone == Constantes.iconeDataCulto) {
              exibirDataPicker();
            }
          },
          child: Icon(icone, color: PaletaCores.corAzulMagenta, size: 30),
        ),
      );

  Widget camposFormulario(double larguraTela, String label) => Container(
    padding: const EdgeInsets.only(
      left: 5.0,
      top: 5.0,
      right: 5.0,
      bottom: 5.0,
    ),
    width: MetodosAuxiliares.ajustarTamanhoTextField(larguraTela),
    child: TextFormField(
      onChanged: (value) {
        itemDigitado[label] = value;
      },
      keyboardType: TextInputType.text,
      decoration: InputDecoration(labelText: label.replaceAll("_", " ")),
    ),
  );

  Widget botoesAcoes(
    String nomeBotao,
    IconData icone,
    double largura,
    double altura,
  ) => SizedBox(
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
        // verificando o tipo do botao
        // para fazer acoes diferentes
        if (nomeBotao == Textos.btnSalvar) {
          if (_formKeyFormulario.currentState!.validate()) {
            chamarAdicionarItens();
          }
        } else if (nomeBotao == Textos.btnAdicionarCampo) {
          redirecionarTelaCadastroNovoCampo();
        } else if (nomeBotao == Textos.btnRemoverCampo) {
          redirecionarTelaRemoverCampos();
        } else if (nomeBotao == Textos.btnData) {
        } else if (nomeBotao == Textos.btnOpcaoData) {
          PassarPegarDados.passarDataComComplemento("");
          setState(() {
            exibirTelaOpcoesData = true;
            verificarCarregamentoDadosConcluido();
          });
        } else if (nomeBotao == Textos.btnSalvarOpcaoData) {
          setState(() {
            if (PassarPegarDados.recuperarDataComComplemento().isNotEmpty) {
              dataFormatada = PassarPegarDados.recuperarDataComComplemento();
            }
            PassarPegarDados.passarConfirmacaoCarregamentoConcluido("");
            exibirAcoesOpcaoData = false;
            exibirTelaOpcoesData = false;
          });
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (nomeBotao == Textos.btnOpcaoData) {
                return Container();
              } else {
                return Icon(icone, color: PaletaCores.corAzulMagenta, size: 30);
              }
            },
          ),
          SizedBox(
            width: nomeBotao == Textos.btnOpcaoData ? 120 : 90,
            child: Text(
              nomeBotao,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  exibirTimePicker() async {
    TimeOfDay? novoHorario = await showTimePicker(
      context: context,
      initialTime: horarioTimePicker!,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.white,
              onPrimary: PaletaCores.corCastanho,
              surface: PaletaCores.corAzulEscuro,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (novoHorario != null) {
      setState(() {
        horarioTimePicker = novoHorario;
        horarioTroca = MetodosAuxiliares.formatarHorarioAjuste(
          horarioTimePicker!,
        );
      });
    }
  }

  // metodo para exibir data picker para
  // o usuario selecionar uma data
  exibirDataPicker() {
    showDatePicker(
      helpText: Textos.descricaoDataPicker,
      context: context,
      initialDate: dataSelecionada,
      firstDate: DateTime(2001),
      lastDate: DateTime(2222),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.white,
              onPrimary: PaletaCores.corCastanho,
              surface: PaletaCores.corAzulEscuro,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    ).then((date) {
      setState(() {
        //definindo que a  variavel vai receber o
        // valor selecionado no data picker
        if (date != null) {
          dataSelecionada = date;
        }
      });
      dataFormatada = formatarData(dataSelecionada);
      recuperarHorarioTroca();
    });
  }

  @override
  Widget build(BuildContext context) {
    double alturaTela = MediaQuery.of(context).size.height;
    double larguraTela = MediaQuery.of(context).size.width;
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
                  //Colocando Visible negando o valor da variavel ou quando a variavel for verdadeira
                  // para que quando o usuario clicar para mostrar o widget de opcoes data
                  // estes campos sejam ocultados enquanto a  tela de carregamento aparece
                  title: Visibility(
                    visible:
                        !exibirTelaOpcoesData || exibirAcoesOpcaoData == true,
                    child: Text(Textos.telaCadastroTitulo),
                  ),
                  leading: Visibility(
                    visible:
                        !exibirTelaOpcoesData || exibirAcoesOpcaoData == true,
                    child: IconButton(
                      color: Colors.white,
                      onPressed: () {
                        redirecionarTelaAnterior();
                      },
                      icon: const Icon(Icons.arrow_back_ios),
                    ),
                  ),
                ),
                body: Container(
                  color: Colors.white,
                  width: larguraTela,
                  height: alturaTela,
                  child: SingleChildScrollView(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 0,
                      ),
                      width: larguraTela,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (exibirTelaOpcoesData) {
                            return Column(
                              children: [
                                WidgetOpcoesData(
                                  dataSelecionada: dataFormatada,
                                ),
                                Visibility(
                                  visible: exibirAcoesOpcaoData,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      botoesAcoes(
                                        Textos.btnSalvarOpcaoData,
                                        Constantes.iconeSalvar,
                                        120,
                                        40
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        child: botoesIcones(
                                          Constantes.iconeExclusao,
                                          30,
                                          PaletaCores.corRosaAvermelhado,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return Column(
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
                                SizedBox(
                                  width: larguraTela,
                                  child: Text(
                                    Textos.telaCadastroDescricao,
                                    style: const TextStyle(fontSize: 18),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    botoesIcones(
                                      Constantes.iconeDataCulto,
                                      40,
                                      PaletaCores.corCastanho,
                                    ),
                                    botoesAcoes(
                                      Textos.btnOpcaoData,
                                      Constantes.iconeEditar,
                                      150,
                                      40,
                                    ),
                                    botoesIcones(
                                      Constantes.iconeMudarHorario,
                                      40,
                                      PaletaCores.corCastanho,
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    SizedBox(
                                      width: 250,
                                      child: Text(
                                        Textos.descricaoDataSelecionada +
                                            dataFormatada,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 150,
                                      child: Text(
                                        horarioTroca,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                                Form(
                                  key: _formKeyFormulario,
                                  child: Container(
                                    padding: EdgeInsets.only(bottom: 10),
                                    width: larguraTela,
                                    height: alturaTela * 0.47,
                                    child: GridView.builder(
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount:
                                                MetodosAuxiliares.quantidadeColunasGridView(
                                                  larguraTela,
                                                ),
                                            mainAxisExtent: 70,
                                          ),
                                      itemCount: itemDigitado.length,
                                      itemBuilder: (context, index) {
                                        return camposFormulario(
                                          100,
                                          itemDigitado.keys.elementAt(index),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
                bottomNavigationBar: Visibility(
                  visible: !exibirTelaOpcoesData,
                  child: Container(
                    alignment: Alignment.center,
                    color: Colors.white,
                    width: larguraTela,
                    height: 150,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Visibility(
                          visible: !exibirTelaOpcoesData,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              botoesAcoes(
                                Textos.btnSalvar,
                                Constantes.iconeSalvar,
                                120,
                                40,
                              ),
                              botoesAcoes(
                                Textos.btnAdicionarCampo,
                                Constantes.iconeAdicionar,
                                120,
                                40,
                              ),
                              botoesAcoes(
                                Textos.btnRemoverCampo,
                                Constantes.iconeRemover,
                                120,
                                40,
                              ),
                            ],
                          ),
                        ),
                        BarraNavegacao(),
                      ],
                    ),
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
