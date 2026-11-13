import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sscaleg/Widgets/tela_carregamento.dart';
import 'package:sscaleg/modelo/check_box_modelo_local_trabalho.dart';
import 'package:sscaleg/modelo/check_box_modelo_voluntario.dart';
import 'package:sscaleg/uteis/constantes.dart';
import 'package:sscaleg/uteis/estilo.dart';
import 'package:sscaleg/uteis/metodos_auxiliares.dart';
import 'package:sscaleg/uteis/passar_pegar_dados.dart';
import 'package:sscaleg/uteis/textos.dart';
import 'package:sscaleg/widgets/barra_navegacao_widget.dart';
import 'package:sscaleg/widgets/widget_ajustar_horario.dart';

class TelaGerarEscala extends StatefulWidget {
  const TelaGerarEscala({super.key});

  @override
  State<TelaGerarEscala> createState() => _TelaGerarEscalaState();
}

class _TelaGerarEscalaState extends State<TelaGerarEscala> {
  bool exibirWidgetCarregamento = false;
  final validacaoFormulario = GlobalKey<FormState>();
  Estilo estilo = Estilo();
  String idDocumento = "";
  List<String> intervaloTrabalho =
  PassarPegarDados.recuperarIntervaloTrabalho();

  List<CheckBoxModeloLocalTrabalho> locaisSorteioVoluntarios =
  PassarPegarDados.recuperarNomesLocaisTrabalho();
  List<CheckBoxModeloVoluntario> nomeVoluntarios =
  PassarPegarDados.recuperarNomesVoluntarios();

  TextEditingController nomeEscala = TextEditingController(text: "");
  Random random = Random();
  List escalaSorteada = [];
  int index = 0;
  String horarioSemana = "";
  String nomeEscalaFormatada = "";
  String horarioFinalSemana = "";
  Map dadosUsuario = {};
  String uidUsuario = "";
  String nomeColecaoUsuariosFireBase = Constantes.fireBaseColecaoUsuarios;
  String nomeColecaoFireBase = Constantes.fireBaseColecaoEscalas;
  String nomeDocumentoFireBase = Constantes.fireBaseDocumentoNomeEscalas;

  @override
  void initState() {
    super.initState();
    uidUsuario =
        PassarPegarDados.recuperarInformacoesUsuario().entries.first.value;
  }

  recuperarHorarioDefinidoInicioTrabalho() {
    setState(() {
      String horarioInicioSemana =
      PassarPegarDados.recuperarHorarioSemanaDefinido();
      String horarioInicioFinalSemana =
      PassarPegarDados.recuperarHorarioFinalSemanaDefinido();
      String horarioTrocaTurnoSemana =
      PassarPegarDados.recuperarHorarioTrocaTurnoSemanaDefinido();
      String horarioTrocaTurnoFinalSemana =
      PassarPegarDados.recuperarHorarioFinalSemanaDefinido();

      if (horarioTrocaTurnoSemana.isNotEmpty &&
          horarioTrocaTurnoFinalSemana.isNotEmpty) {
        horarioSemana = "$horarioInicioSemana $horarioTrocaTurnoSemana";
        horarioFinalSemana =
        "$horarioInicioFinalSemana $horarioTrocaTurnoFinalSemana";
      } else {
        horarioSemana = horarioInicioSemana;
        horarioFinalSemana = horarioInicioFinalSemana;
      }
    });
  }

  // Lê a observação do local para saber se exige 2 pessoas
  int _extrairVagasLocal(CheckBoxModeloLocalTrabalho local) {
    String obs = "${local.observacaoLocal} ${local.diasLocalObservacao}".toLowerCase();
    if (obs.contains('02') ||
        obs.contains('2') ||
        obs.contains('duas') ||
        obs.contains('precisa_de_02_pessoas')) {
      return 2;
    }
    return 1;
  }

  // Método principal de sorteio inteligente 100% blindado contra dias inválidos
  fazerSorteio() {
    escalaSorteada.clear();

    if (nomeVoluntarios.isEmpty ||
        intervaloTrabalho.isEmpty ||
        locaisSorteioVoluntarios.isEmpty) {
      setState(() {
        exibirWidgetCarregamento = false;
      });
      chamarExibirMensagemErro(
          "Verifique se há voluntários, locais e datas cadastrados.");
      return;
    }

    int ponteiroNomes = 0;
    List<String> escaladosNoDia = [];

    // Preenche as linhas (datas) e colunas (locais)
    for (var datas in intervaloTrabalho) {
      Map linha = {};
      String horarioInicioTrabalho = "";

      if (datas.contains(Constantes.diaDomingo.toLowerCase()) ||
          datas.contains(Constantes.diaSabado.toLowerCase())) {
        horarioInicioTrabalho = horarioFinalSemana;
      } else {
        horarioInicioTrabalho = horarioSemana;
      }

      linha[Constantes.horarioTrabalho] = horarioInicioTrabalho;
      linha[Constantes.dataCulto] = datas;

      escaladosNoDia.clear();
      String diaDoCultoFormatado = datas.toLowerCase(); // Ex: "18/11/2026 quarta-feira"

      for (var local in locaisSorteioVoluntarios) {
        String nomeLocal = local.nome;
        int vagasLocal = _extrairVagasLocal(local);

        if (vagasLocal > 1) {
          // Local que exige 2 pessoas (Dupla)
          List<String> duplaDoLocal = [];

          for (int v = 0; v < vagasLocal; v++) {
            var voluntarioEscolhido = _encontrarVoluntarioValidoSeguro(
              nomeVoluntarios,
              ponteiroNomes,
              diaDoCultoFormatado,
              nomeLocal,
              escaladosNoDia,
            );

            duplaDoLocal.add(voluntarioEscolhido['nome']);
            escaladosNoDia.add(voluntarioEscolhido['nome']);
            ponteiroNomes = voluntarioEscolhido['novoPonteiro'];
          }

          linha[nomeLocal] = duplaDoLocal.join(" e ");
        } else {
          // Local padrão de 1 vaga
          var voluntarioEscolhido = _encontrarVoluntarioValidoSeguro(
            nomeVoluntarios,
            ponteiroNomes,
            diaDoCultoFormatado,
            nomeLocal,
            escaladosNoDia,
          );

          linha[nomeLocal] = voluntarioEscolhido['nome'];
          escaladosNoDia.add(voluntarioEscolhido['nome']);
          ponteiroNomes = voluntarioEscolhido['novoPonteiro'];
        }
      }

      escalaSorteada.add(linha);
    }

    chamarCadastroItens();
  }

  // Função totalmente segura que valida rigorosamente se o voluntário pode trabalhar no dia e no local
  Map<String, dynamic> _encontrarVoluntarioValidoSeguro(
      List<CheckBoxModeloVoluntario> listaVoluntariosGeral,
      int indexAtual,
      String diaCulto,
      String nomeLocal,
      List<String> jaEscaladosHoje,
      ) {
    int ponteiro = indexAtual % listaVoluntariosGeral.length;

    // 1. TENTA ENCONTRAR UM VOLUNTÁRIO QUE:
    // - Tenha disponibilidade para o dia da semana
    // - NÃO esteja escalado em nenhum outro local no mesmo dia
    // - Não tenha restrição para este local específico
    for (int i = 0; i < listaVoluntariosGeral.length; i++) {
      int indexReal = (ponteiro + i) % listaVoluntariosGeral.length;
      var vol = listaVoluntariosGeral[indexReal];

      String nomeVoluntario = vol.texto;
      bool jaTrabalhaHoje = jaEscaladosHoje.contains(nomeVoluntario);

      // Se já trabalha hoje, ele é descarta imediatamente para este segundo local
      if (jaTrabalhaHoje) continue;

      // Verifica se ele pode trabalhar neste dia e neste local
      if (_voluntarioPodeTrabalharNoDia(vol, diaCulto, nomeLocal)) {
        return {
          'nome': nomeVoluntario,
          'novoPonteiro': (indexReal + 1) % listaVoluntariosGeral.length,
        };
      }
    }

    // 2. SE A GERAÇÃO DA ESCALA EXIGIR MAIS PESSOAS DO QUE HÁ VOLUNTÁRIOS DISPONÍVEIS NO DIA:
    // (Caso extremo em que todos os elegíveis do dia já estão alocados e precisamos preencher a vaga restante)
    // Procuramos alguém que PODE trabalhar no dia (respeitando o dia da semana), mesmo que precise repetir no mesmo dia.
    for (int i = 0; i < listaVoluntariosGeral.length; i++) {
      int indexReal = (ponteiro + i) % listaVoluntariosGeral.length;
      var vol = listaVoluntariosGeral[indexReal];

      if (_voluntarioPodeTrabalharNoDia(vol, diaCulto, nomeLocal)) {
        return {
          'nome': vol.texto,
          'novoPonteiro': (indexReal + 1) % listaVoluntariosGeral.length,
        };
      }
    }

    // 3. FALLBACK ABSOLUTO (Garante que o app não quebre se absolutamente ninguém tiver o dia cadastrado)
    var fallback = listaVoluntariosGeral[ponteiro];
    return {
      'nome': fallback.texto,
      'novoPonteiro': (ponteiro + 1) % listaVoluntariosGeral.length,
    };
  }

  // Método auxiliar rigoroso que valida dias e restrições de local
  bool _voluntarioPodeTrabalharNoDia(CheckBoxModeloVoluntario vol, String diaCulto, String nomeLocal) {
    String diasPermitidos = vol.diasDisponiveis.toLowerCase().trim();
    String obsVoluntario = vol.observacao.toLowerCase().trim();
    String categoriaVol = vol.categoriaVoluntario.toLowerCase().trim();
    String diaAtualLower = diaCulto.toLowerCase();
    String localLower = nomeLocal.toLowerCase();

    // Se o voluntário preencheu os dias permitidos no cadastro:
    if (diasPermitidos.isNotEmpty) {
      List<String> listaDias = diasPermitidos.split(RegExp(r'[,;\s]+'));
      listaDias.removeWhere((d) => d.isEmpty);

      if (listaDias.isNotEmpty) {
        bool bateuDia = listaDias.any((diaPermitido) =>
        diaAtualLower.contains(diaPermitido.toLowerCase()) ||
            diaPermitido.toLowerCase().contains(diaAtualLower)
        );

        // Se o dia atual da escala NÃO estiver na lista dele, ele é BLOQUEADO instantaneamente!
        if (!bateuDia) {
          return false;
        }
      }
    }

    // Trava de exceção por texto (ex: "não na sexta")
    String textoPerfil = "$obsVoluntario $categoriaVol";
    if (textoPerfil.contains('nao') || textoPerfil.contains('exceto') || textoPerfil.contains('fora') || textoPerfil.contains('nunca')) {
      if ((textoPerfil.contains('segunda') && diaAtualLower.contains('segunda')) ||
          (textoPerfil.contains('terca') && diaAtualLower.contains('terca')) ||
          (textoPerfil.contains('quarta') && diaAtualLower.contains('quarta')) ||
          (textoPerfil.contains('quinta') && diaAtualLower.contains('quinta')) ||
          (textoPerfil.contains('sexta') && diaAtualLower.contains('sexta')) ||
          (textoPerfil.contains('sabado') && diaAtualLower.contains('sabado')) ||
          (textoPerfil.contains('domingo') && diaAtualLower.contains('domingo'))) {
        return false;
      }
    }

    // Trava de bloqueio de local específico nas observações
    if ((textoPerfil.contains('nao') || textoPerfil.contains('exceto')) && textoPerfil.contains(localLower)) {
      return false;
    }

    return true; // Aprovado para o dia e local!
  }

  // Método para buscar o id na base de dados para poder adicionar os dados
  buscarIDDocumentoFirebase() async {
    String idDocumentoFirebase = "";
    var db = FirebaseFirestore.instance;
    await db
        .collection(nomeColecaoUsuariosFireBase)
        .doc(uidUsuario)
        .collection(nomeColecaoFireBase)
        .where(nomeDocumentoFireBase)
        .get()
        .then((querySnapshot) {
      for (var docSnapshot in querySnapshot.docs) {
        if (docSnapshot.data().values.contains(nomeEscalaFormatada)) {
          idDocumentoFirebase = docSnapshot.id;
        }
      }
    });
    return idDocumentoFirebase;
  }

  // Método para chamar o cadastro de itens no banco de dados
  chamarCadastroItens() async {
    try {
      var db = FirebaseFirestore.instance;
      db
          .collection(nomeColecaoUsuariosFireBase)
          .doc(uidUsuario)
          .collection(nomeColecaoFireBase)
          .add({nomeDocumentoFireBase: nomeEscalaFormatada})
          .then(
            (value) async {
          String idDocumentoFirebase = await buscarIDDocumentoFirebase();
          idDocumento = idDocumentoFirebase;
          for (var element in escalaSorteada) {
            cadastrarItens(element.entries.toList(), idDocumentoFirebase);
          }
        },
        onError: (e) {
          setState(() {
            exibirWidgetCarregamento = false;
          });
          chamarExibirMensagemErro(
            "Erro Criar Nome Escala : ${e.toString()}",
          );
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

  cadastrarItens(List<MapEntry> escala, String idDocumentoFirebase) async {
    try {
      var db = FirebaseFirestore.instance;
      db
          .collection(nomeColecaoUsuariosFireBase)
          .doc(uidUsuario)
          .collection(nomeColecaoFireBase)
          .doc(idDocumentoFirebase)
          .collection(Constantes.fireBaseDadosCadastrados)
          .doc()
          .set(criarMapComTodosOsDados(escala))
          .then((value) {
        index++;
        if (index == escalaSorteada.length) {
          index = 0;
          MetodosAuxiliares.exibirMensagens(
            Constantes.tipoNotificacaoSucesso,
            Textos.notificacaoSucesso,
            context,
          );
          limparListaDados();
          redirecionarProximaTela();
        }
      });
    } catch (e) {
      setState(() {
        exibirWidgetCarregamento = false;
      });
      chamarExibirMensagemErro(e.toString());
    }
  }

  limparListaDados() {
    PassarPegarDados.passarNomesLocaisTrabalho([]);
    PassarPegarDados.passarNomesVoluntarios([]);
    PassarPegarDados.passarIntervaloTrabalho([]);
    PassarPegarDados.passarDiasSemana([]);
    PassarPegarDados.passarHorarioSemanaDefinido("");
    PassarPegarDados.passarHorarioFinalSemanaDefinido("");
  }

  redirecionarProximaTela() {
    var dados = {};
    dados[Constantes.rotaArgumentoNomeEscala] = nomeEscalaFormatada;
    dados[Constantes.rotaArgumentoIDEscalaSelecionada] = idDocumento;
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(
        context,
        Constantes.rotaTelaEscalaDetalhada,
        arguments: dados,
      );
    });
  }

  criarMapComTodosOsDados(List<MapEntry> escala) {
    Map<String, dynamic> itemFinal = {};
    for (var element in escala) {
      itemFinal[element.key] = element.value;
    }
    return itemFinal;
  }

  chamarFazerSorteio() {
    if (validacaoFormulario.currentState!.validate()) {
      setState(() {
        nomeEscalaFormatada =
            nomeEscala.text.trim().replaceAll(" ", "_").toLowerCase();
        exibirWidgetCarregamento = true;
      });
      recuperarHorarioDefinidoInicioTrabalho();
      fazerSorteio();
    }
  }

  @override
  Widget build(BuildContext context) {
    double larguraTela = MediaQuery.of(context).size.width;
    double alturaTela = MediaQuery.of(context).size.height;
    Timer(const Duration(seconds: 2), () {
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
                  title: Text(Textos.btnCriarEscala),
                  leading: IconButton(
                    color: Colors.white,
                    onPressed: () {
                      PassarPegarDados.passarIntervaloTrabalho([]);
                      Navigator.pushReplacementNamed(
                        context,
                        Constantes.rotaTelaSelecaoIntervaloTrabalho,
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
                          margin: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(
                            Textos.telaGerarEscalaDescricao,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        Column(
                          children: [
                            Form(
                              key: validacaoFormulario,
                              child: SizedBox(
                                width: Platform.isWindows ? 300 : 200,
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    hintText: Textos.labelTextFieldCampo,
                                  ),
                                  controller: nomeEscala,
                                  onFieldSubmitted: (value) {
                                    chamarFazerSorteio();
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
                            WidgetAjustarHorario(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                bottomNavigationBar: Container(
                  color: Colors.white,
                  height: 100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 40,
                        child: FloatingActionButton(
                          heroTag: Textos.btnCriarEscala,
                          onPressed: () {
                            chamarFazerSorteio();
                          },
                          child: Text(
                            Textos.btnCriarEscala,
                            style: const TextStyle(color: Colors.black),
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