import 'dart:async';
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

@immutable
class TelaCadastroItem extends StatefulWidget {
  TelaCadastroItem({
    Key? key,
    required this.nomeTabela,
    required this.idTabelaSelecionada,
  }) : super(key: key);

  final String nomeTabela;
  final String idTabelaSelecionada;

  @override
  State<TelaCadastroItem> createState() => _TelaCadastroItemState();
}

class _TelaCadastroItemState extends State<TelaCadastroItem> {
  Estilo estilo = Estilo();
  bool exibirOcultarCamposNaoUsados = false;
  bool exibirTelaCarregamento = false;
  bool exibirCampoServirSantaCeia = false;
  bool exibirSoCamposCooperadora = false;
  bool exibirOpcoesData = false;
  String horarioTroca = "";
  bool exibirWidgetCarregamento = false;
  List<String> listaCamposOriginal = [];
  List<String> listaCamposExibicao = [];
  String nomeDigitado = "";
  Map itemDigitado = {};

  //String opcaoDataComplemento = Textos.departamentoCultoLivre;
  TimeOfDay? horarioTimePicker = const TimeOfDay(hour: 19, minute: 00);
  DateTime dataSelecionada = DateTime.now();
  final _formKeyFormulario = GlobalKey<FormState>();
  final validacaoFormulario = GlobalKey<FormState>();
  TextEditingController ctPrimeiroHoraPulpito = TextEditingController(text: "");
  TextEditingController ctSegundoHoraPulpito = TextEditingController(text: "");
  TextEditingController ctPrimeiroHoraEntrada = TextEditingController(text: "");
  TextEditingController ctSegundoHoraEntrada = TextEditingController(text: "");
  TextEditingController ctRecolherOferta = TextEditingController(text: "");
  TextEditingController ctUniforme = TextEditingController(text: "");
  TextEditingController ctMesaApoio = TextEditingController(text: "");
  TextEditingController ctServirSantaCeia = TextEditingController(text: "");
  TextEditingController ctIrmaoReserva = TextEditingController(text: "");
  TextEditingController ctPorta01 = TextEditingController(text: "");
  TextEditingController ctBanheiroFeminino = TextEditingController(text: "");

  @override
  void initState() {
    super.initState();
    listaCamposOriginal = PassarPegarDados.recuperarCamposCadastroItem();
    listaCamposOriginal.removeWhere((element) {
      return element.contains(Constantes.editar);
    });
    listaCamposOriginal.removeWhere((element) {
      return element.contains(Constantes.excluir);
    });
    listaCamposExibicao = listaCamposOriginal;
    listaCamposExibicao.removeWhere((element) {
      return element.contains(Constantes.dataCulto);
    });
    listaCamposExibicao.removeWhere((element) {
      return element.contains(Constantes.horarioTrabalho);
    });
    recuperarHorarioTroca();
  }

  @override
  void dispose() {
    super.dispose();
    PassarPegarDados.passarCamposCadastroItem([]);
  }

  // // metodo para recuperar os horarios definidos
  // // e gravados no share preferences
  recuperarHorarioTroca() async {
    String data = formatarData(dataSelecionada).toString();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String horarioSemana =
        prefs.getString(Constantes.sharePreferencesAjustarHorarioSemana) ?? '';
    String horarioFinalSemana =
        prefs.getString(Constantes.sharePreferencesAjustarHorarioFinalSemana) ??
        '';
    // verificando se a data corresponde a um dia do fim de semana
    if (data.contains(Constantes.diaSabado) ||
        data.contains(Constantes.diaDomingo)) {
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
      decoration: InputDecoration(labelText: label),
    ),
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
        // verificando o tipo do botao
        // para fazer acoes diferentes
        if (nomeBotao == Textos.btnSalvar) {
          if (_formKeyFormulario.currentState!.validate()) {
            itemDigitado.forEach((key, value) {
              print(key);
              print(value);
            });
            //adicionarItensBancoDados();
          }
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (nomeBotao == "Textos.btnOpcoesData") {
                return Container();
              } else {
                return Icon(icone, color: PaletaCores.corAzulMagenta, size: 30);
              }
            },
          ),
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

  Widget botoesSwitch(String label, bool valorBotao) => SizedBox(
    width: 180,
    child: Row(
      children: [
        Text(label),
        Switch(
          inactiveThumbColor: PaletaCores.corAzulMagenta,
          value: valorBotao,
          activeColor: PaletaCores.corAzulMagenta,
          onChanged: (bool valor) {
            setState(() {
              //mudarSwitch(label, valor);
            });
          },
        ),
      ],
    ),
  );

  redirecionarTelaAnterior() {
    var dados = {};
    dados[Constantes.rotaArgumentEscalaDetalhadaNomeEscala] = widget.nomeTabela;
    dados[Constantes.rotaArgumentoEscalaDetalhadaIDEscalaSelecionada] =
        widget.idTabelaSelecionada;
    Navigator.pushReplacementNamed(
      context,
      Constantes.rotaTelaEscalaDetalhada,
      arguments: dados,
    );
  }

  @override
  Widget build(BuildContext context) {
    double alturaTela = MediaQuery.of(context).size.height;
    double larguraTela = MediaQuery.of(context).size.width;
    double alturaBarraStatus = MediaQuery.of(context).padding.top;
    double alturaAppBar = AppBar().preferredSize.height;
    Timer(Duration(seconds: 2), () {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
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
                  title: Text(Textos.tituloTelaCadastro),
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
                  height: alturaTela - alturaAppBar - alturaBarraStatus,
                  child: SingleChildScrollView(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 0,
                      ),
                      width: larguraTela,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (exibirOpcoesData) {
                            return Column(
                              children: [
                                // WidgetOpcoesData(
                                //   dataSelecionada:
                                //       formatarData(dataSelecionada),
                                // ),
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
                                    Textos.descricaoTelaCadastro,
                                    style: const TextStyle(fontSize: 18),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    botoesAcoes(
                                      Textos.btnData,
                                      Constantes.iconeDataCulto,
                                      50,
                                      50,
                                    ),
                                    SizedBox(
                                      height: 50,
                                      width: 50,
                                      child: FloatingActionButton(
                                        elevation: 0,
                                        heroTag: "mudar horario",
                                        backgroundColor: Colors.white,
                                        shape: const RoundedRectangleBorder(
                                          side: BorderSide(
                                            color: PaletaCores.corCastanho,
                                          ),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(10),
                                          ),
                                        ),
                                        onPressed: () async {
                                          //exibirTimePicker();
                                        },
                                        child: const Icon(
                                          Icons.access_time_filled_outlined,
                                          color: PaletaCores.corAzulEscuro,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    SizedBox(
                                      width: 250,
                                      child: Text(
                                        Textos.descricaoDataSelecionada +
                                            formatarData(dataSelecionada),
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
                                  child: SizedBox(
                                    width: larguraTela,
                                    height: alturaTela * 0.5,
                                    child: ListView.builder(
                                      itemCount: listaCamposExibicao.length,
                                      itemBuilder: (context, index) {
                                        return camposFormulario(
                                          larguraTela,
                                          listaCamposExibicao.elementAt(index),
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
                bottomNavigationBar: Container(
                  alignment: Alignment.center,
                  color: Colors.white,
                  width: larguraTela,
                  height: 150,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Visibility(
                            visible: !exibirOpcoesData,
                            child: botoesAcoes(
                              Textos.btnSalvar,
                              Constantes.iconeSalvar,
                              90,
                              60,
                            ),
                          ),
                          botoesAcoes(
                            Textos.btnAdicionarCampo,
                            Constantes.iconeAdicionar,
                            140,
                            60,
                          ),
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
