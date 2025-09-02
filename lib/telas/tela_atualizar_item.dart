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
class TelaAtualizarItem extends StatefulWidget {
  const TelaAtualizarItem({
    super.key,
    required this.nomeTabela,
    required this.idTabelaSelecionada,
  });

  final String nomeTabela;
  final String idTabelaSelecionada;

  @override
  State<TelaAtualizarItem> createState() => _TelaAtualizarItemState();
}

class _TelaAtualizarItemState extends State<TelaAtualizarItem> {
  Estilo estilo = Estilo();
  bool exibirTelaCarregamento = false;
  bool exibirTelaOpcaoData = false;
  String horarioTroca = "";
  bool exibirTrocaTurno = false;
  int contadorTimerPicker = 0;
  bool exibirWidgetCarregamento = false;
  Map itensRecebidosCabecalhoLinha = {};
  String nomeDigitado = "";
  String dataFormatada = "";
  String idItem = "";
  String departamentoData = "";
  Map<dynamic, dynamic> itemDigitado = {};
  TimeOfDay? horarioTimePicker = const TimeOfDay(hour: 19, minute: 00);
  DateTime dataSelecionada = DateTime.now();
  final _formKeyFormulario = GlobalKey<FormState>();
  String uidUsuario = "";
  String nomeColecaoUsuariosFireBase = Constantes.fireBaseColecaoUsuarios;
  String nomeColecaoFireBase = Constantes.fireBaseColecaoEscalas;
  String nomeDocumentoFireBase = Constantes.fireBaseDadosCadastrados;

  @override
  void initState() {
    super.initState();
    uidUsuario =
        PassarPegarDados.recuperarInformacoesUsuario().entries.first.value;
    itensRecebidosCabecalhoLinha = PassarPegarDados.recuperarItens();
    idItem = PassarPegarDados.recuperarIdAtualizarSelecionado();
    itensRecebidosCabecalhoLinha.removeWhere((key, value) {
      return key.toString().contains(Constantes.editar);
    });
    itensRecebidosCabecalhoLinha.removeWhere((key, value) {
      return key.toString().contains(Constantes.excluir);
    });
    String data = itensRecebidosCabecalhoLinha.values.elementAt(0);
    dataSelecionada = DateFormat("dd/MM/yyyy EEEE", "pt_BR").parse(data);

    dataFormatada = "${formatarData(dataSelecionada)} ";
    horarioTroca = itensRecebidosCabecalhoLinha.values.elementAt(1);
    if(horarioTroca.contains(Textos.widgetAjustarTrocaHorario)){
      exibirTrocaTurno = true;
    }

    if (data.contains("(")) {
      departamentoData = data.split("(")[1];
      dataFormatada = "$dataFormatada($departamentoData";
    }
    carregarCampos();
  }

  carregarCampos() {
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
    PassarPegarDados.passarItens({});
    PassarPegarDados.passarIdAtualizarSelecionado("");
    PassarPegarDados.passarDataComComplemento("");
  }

  redirecionarTelaCadastroNovoCampo() {
    var dados = {};
    PassarPegarDados.passarItens(itensRecebidosCabecalhoLinha);
    PassarPegarDados.passarIdAtualizarSelecionado(idItem);
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
    PassarPegarDados.passarIdAtualizarSelecionado(idItem);
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
    //Definindo que a variavel vai receber o valor do
    // metodo mais um pequeno espaco no final
    // espaco esse utilizado para o complemento de data para nao ficar grudado
    dataFormatada = "${formatarData(dataSelecionada)} ";

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String horarioSemana =
        prefs.getString(Constantes.sharePreferencesAjustarHorarioSemana) ?? '';
    String horarioFinalSemana =
        prefs.getString(Constantes.sharePreferencesAjustarHorarioFinalSemana) ??
        '';
    String horarioTrocaTurnoSemana =
        prefs.getString(Constantes.sharePreferencesTrocaHorarioSemana) ?? '';
    String horarioTrocaTurnoFinalSemana =
        prefs.getString(Constantes.sharePreferencesTrocaHorarioFinalSemana) ??
        '';
    // verificando se a data corresponde a um dia do fim de semana
    if (dataFormatada.contains(Constantes.diaSabado.toLowerCase()) ||
        dataFormatada.contains(Constantes.diaDomingo.toLowerCase())) {
      setState(() {
        if (exibirTrocaTurno) {
          horarioTroca = "$horarioFinalSemana $horarioTrocaTurnoFinalSemana";
        } else {
          horarioTroca = horarioFinalSemana;
        }
      });
    } else {
      setState(() {
        if (exibirTrocaTurno) {
          horarioTroca = "$horarioSemana $horarioTrocaTurnoSemana";
        } else {
          horarioTroca = horarioFinalSemana;
        }
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
    String dados =
        PassarPegarDados.recuperarConfirmacaoSelecaoDataComplemento();
    //verificando se a string e vazia
    if (dados.isEmpty) {
      //definindo um timer para chamar novamente o metodo a cada 1 segundo
      Timer(const Duration(seconds: 1), () {
        verificarCarregamentoDadosConcluido();
      });
    } else if (dados.contains(Constantes.confirmacaoSelecaoDataComplemento)) {
      if (mounted) {
        setState(() {
          if (PassarPegarDados.recuperarDataComComplemento().isNotEmpty) {
            dataFormatada = PassarPegarDados.recuperarDataComComplemento();
          }
          PassarPegarDados.passarConfirmacaoSelecaoDataComplemento("");
          exibirTelaOpcaoData = false;
        });
      }
    }
  }

  chamarAtualizarItens() {
    itemDigitado[Constantes.dataCulto] = dataFormatada;
    itemDigitado[Constantes.horarioTrabalho] = horarioTroca;
    atualizarItem(widget.idTabelaSelecionada);
  }

  atualizarItem(String idDocumentoFirebase) async {
    setState(() {
      exibirWidgetCarregamento = true;
    });
    try {
      var db = FirebaseFirestore.instance;
      db
          .collection(nomeColecaoUsuariosFireBase)
          .doc(uidUsuario)
          .collection(nomeColecaoFireBase)
          .doc(idDocumentoFirebase)
          .collection(nomeDocumentoFireBase)
          .doc(idItem)
          .set(criarMapCompativel(itemDigitado))
          .then((value) {
            redirecionarTelaAnterior();
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

  Widget botoesSwitch(String label, bool valorBotao) => SizedBox(
    width: 180,
    child: Row(
      children: [
        Text(label),
        Switch(
          inactiveThumbColor: PaletaCores.corAzulEscuro,
          value: valorBotao,
          activeColor: PaletaCores.corAzulEscuro,
          onChanged: (bool valor) {
            setState(() {
              exibirTrocaTurno = !exibirTrocaTurno;
              recuperarHorarioTroca();
            });
          },
        ),
      ],
    ),
  );

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
            if (icone == Constantes.iconeMudarHorario) {
              exibirTimePicker();
            } else if (icone == Constantes.iconeDataCulto) {
              exibirDataPicker();
            }
          },
          child: Icon(icone, color: PaletaCores.corAzulEscuro, size: 30),
        ),
      );

  Widget camposFormulario(double larguraTela, String label) => Container(
    padding: const EdgeInsets.only(
      left: 5.0,
      top: 5.0,
      right: 5.0,
      bottom: 5.0,
    ),
    height: 100,
    child: TextFormField(
      onChanged: (value) {
        itemDigitado[label] = value;
      },
      initialValue: itemDigitado[label],
      keyboardType: TextInputType.text,
      decoration: InputDecoration(labelText: label.replaceAll("_", " ")),
    ),
  );

  Widget botoesAcoes(String nomeBotao) => SizedBox(
    height: 40,
    width: nomeBotao == Textos.btnOpcaoData ? 120 : 110,
    child: FloatingActionButton(
      heroTag: nomeBotao,
      onPressed: () async {
        // verificando o tipo do botao
        // para fazer acoes diferentes
        if (nomeBotao == Textos.btnAtualizar) {
          if (_formKeyFormulario.currentState!.validate()) {
            chamarAtualizarItens();
          }
        } else if (nomeBotao == Textos.btnAdicionarCampo) {
          redirecionarTelaCadastroNovoCampo();
        } else if (nomeBotao == Textos.btnRemoverCampo) {
          redirecionarTelaRemoverCampos();
        } else if (nomeBotao == Textos.btnOpcaoData) {
          setState(() {
            exibirTelaOpcaoData = true;
            PassarPegarDados.passarDataComComplemento("");
            PassarPegarDados.passarConfirmacaoSelecaoDataComplemento("");
            verificarCarregamentoDadosConcluido();
          });
        }
      },
      child: Text(
        nomeBotao,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black),
      ),
    ),
  );

  exibirTimePicker() async {
    TimeOfDay? novoHorario = await showTimePicker(
      context: context,
      helpText:
          contadorTimerPicker == 1
              ? Textos.descricaoTimePickerHorarioTroca
              : Textos.descricaoTimePickerHorarioInicial,
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
        if (exibirTrocaTurno) {
          acaoTimerPickerTrocaTurno();
        } else {
          horarioTroca = MetodosAuxiliares.formatarHorarioAjuste(
            horarioTimePicker!,
            exibirTrocaTurno,
          );
        }
      });
    }
  }

  acaoTimerPickerTrocaTurno() {
    contadorTimerPicker++;
    if (contadorTimerPicker == 1) {
      horarioTroca = MetodosAuxiliares.formatarHorarioAjuste(
        horarioTimePicker!,
        false,
      );
      exibirTimePicker();
    } else {
      String horarioTrocaFormatado = MetodosAuxiliares.formatarHorarioAjuste(
        horarioTimePicker!,
        true,
      );
      horarioTroca = "$horarioTroca $horarioTrocaFormatado";
      contadorTimerPicker = 0;
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
            } else if (exibirTelaOpcaoData) {
              return WidgetOpcoesData(dataSelecionada: dataFormatada);
            } else {
              return Scaffold(
                appBar: AppBar(
                  //Colocando Visible negando o valor da variavel ou quando a variavel for verdadeira
                  // para que quando o usuario clicar para mostrar o widget de opcoes data
                  // estes campos sejam ocultados enquanto a  tela de carregamento aparece
                  title: Text(Textos.telaAtualizarItemTitulo),
                  leading: IconButton(
                    color: Colors.white,
                    onPressed: () {
                      redirecionarTelaAnterior();
                    },
                    icon: const Icon(Icons.arrow_back_ios),
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
                      child: Column(
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
                              Textos.telaAtualizarDescricao,
                              style: const TextStyle(fontSize: 18),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              botoesIcones(
                                Constantes.iconeDataCulto,
                                40,
                                PaletaCores.corCastanho,
                              ),
                              botoesAcoes(Textos.btnOpcaoData),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  botoesSwitch(
                                    Textos.trocaTurno,
                                    exibirTrocaTurno,
                                  ),
                                  botoesIcones(
                                    Constantes.iconeMudarHorario,
                                    40,
                                    PaletaCores.corCastanho,
                                  ),
                                ],
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
                                    larguraTela,
                                    itemDigitado.keys.elementAt(index),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                bottomNavigationBar: Container(
                  alignment: Alignment.center,
                  width: larguraTela,
                  color: Colors.white,
                  height: 100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          botoesAcoes(Textos.btnAtualizar),
                          botoesAcoes(Textos.btnAdicionarCampo),
                          botoesAcoes(Textos.btnRemoverCampo),
                        ],
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
