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

    PassarPegarDados.recuperarNomesVoluntarios().forEach((element) {
          print("NOME : ${element.texto} Categoria : ${element.categoriaVoluntario} Observação : ${element.observacao} Dias : ${element.diasDisponiveis}");
        },);
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

      if (horarioTrocaTurnoSemana.isNotEmpty) {
        horarioSemana = "$horarioInicioSemana $horarioTrocaTurnoSemana";
      } else {
        horarioSemana = horarioInicioSemana;
      }

      if (horarioTrocaTurnoFinalSemana.isNotEmpty) {
        horarioFinalSemana =
        "$horarioInicioFinalSemana $horarioTrocaTurnoFinalSemana";
      } else {
        horarioFinalSemana = horarioInicioFinalSemana;
      }
    });
  }

  // Lê a observação do local para saber se exige 2 pessoas
  int _extrairVagasLocal(CheckBoxModeloLocalTrabalho local) {
    String obs =
    "${local.observacaoLocal} ${local.diasLocalObservacao}".toLowerCase();
    if (obs.contains('02') ||
        obs.contains('2') ||
        obs.contains('duas') ||
        obs.contains('precisa_de_02_pessoas')) {
      return 2;
    }
    return 1;
  }

  // Extrai o dia da semana exato usando suas constantes
  String _extrairDiaSemanaConstante(String textoData) {
    String lower = textoData.toLowerCase();
    if (lower.contains('segunda')) return Constantes.diaSegunda.toLowerCase();
    if (lower.contains('terça') || lower.contains('terca')) {
      return Constantes.diaTerca.toLowerCase();
    }
    if (lower.contains('quarta')) return Constantes.diaQuarta.toLowerCase();
    if (lower.contains('quinta')) return Constantes.diaQuinta.toLowerCase();
    if (lower.contains('sexta')) return Constantes.diaSexta.toLowerCase();
    if (lower.contains('sábado') || lower.contains('sabado')) {
      return Constantes.diaSabado.toLowerCase();
    }
    if (lower.contains('domingo')) return Constantes.diaDomingo.toLowerCase();
    return "";
  }

  // Remove acentos e padroniza textos
  String _normalizar(String texto) {
    return texto
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ç', 'c');
  }

  // Verifica se o voluntário tem disponibilidade livre ("Disponivel Todos os Dias" ou vazio)
  bool _isDisponivelTodosOsDias(CheckBoxModeloVoluntario vol) {
    String dias = _normalizar(vol.diasDisponiveis);
    return dias.isEmpty ||
        dias.contains('disponivel todos os dias') ||
        dias.contains('todos os dias');
  }



  // Método principal de sorteio inteligente, equilibrado e com rodízio de locais
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

    List<CheckBoxModeloVoluntario> voluntariosEmbaralhados =
    List.from(nomeVoluntarios)..shuffle(random);

    // Contador global de escalas no mês por voluntário
    Map<String, int> contagemGeralEscalas = {
      for (var v in voluntariosEmbaralhados) v.texto: 0
    };

    // Contador de quantas vezes cada voluntário trabalhou em CADA local específico (evita repetir sempre o mesmo posto)
    Map<String, Map<String, int>> contagemPorLocal = {
      for (var v in voluntariosEmbaralhados) v.texto: {}
    };

    for (var datas in intervaloTrabalho) {
      Map linha = {};
      String horarioInicioTrabalho = "";
      String diaSemanaAtual = _extrairDiaSemanaConstante(datas);

      if (diaSemanaAtual == Constantes.diaDomingo.toLowerCase() ||
          diaSemanaAtual == Constantes.diaSabado.toLowerCase()) {
        horarioInicioTrabalho = horarioFinalSemana;
      } else {
        horarioInicioTrabalho = horarioSemana;
      }

      linha[Constantes.horarioTrabalho] = horarioInicioTrabalho;
      linha[Constantes.dataCulto] = datas;

      List<String> escaladosHoje = [];

      for (var local in locaisSorteioVoluntarios) {
        String nomeLocal = local.nome;
        int vagasLocal = _extrairVagasLocal(local);

        if (vagasLocal > 1) {
          List<String> duplaDoLocal = [];

          for (int v = 0; v < vagasLocal; v++) {
            String escolhido = _escolherVoluntarioEquilibrado(
              listaVoluntarios: voluntariosEmbaralhados,
              diaSemanaAtual: diaSemanaAtual,
              nomeLocal: nomeLocal,
              escaladosHoje: escaladosHoje,
              contagemGeralEscalas: contagemGeralEscalas,
              contagemPorLocal: contagemPorLocal,
            );

            duplaDoLocal.add(escolhido);
            if (escolhido != "Sem voluntário") {
              escaladosHoje.add(escolhido);
              contagemGeralEscalas[escolhido] =
                  (contagemGeralEscalas[escolhido] ?? 0) + 1;
              contagemPorLocal[escolhido]![nomeLocal] =
                  (contagemPorLocal[escolhido]![nomeLocal] ?? 0) + 1;
            }
          }

          linha[nomeLocal] = duplaDoLocal.join(" e ");
        } else {
          String escolhido = _escolherVoluntarioEquilibrado(
            listaVoluntarios: voluntariosEmbaralhados,
            diaSemanaAtual: diaSemanaAtual,
            nomeLocal: nomeLocal,
            escaladosHoje: escaladosHoje,
            contagemGeralEscalas: contagemGeralEscalas,
            contagemPorLocal: contagemPorLocal,
          );

          linha[nomeLocal] = escolhido;
          if (escolhido != "Sem voluntário") {
            escaladosHoje.add(escolhido);
            contagemGeralEscalas[escolhido] =
                (contagemGeralEscalas[escolhido] ?? 0) + 1;
            contagemPorLocal[escolhido]![nomeLocal] =
                (contagemPorLocal[escolhido]![nomeLocal] ?? 0) + 1;
          }
        }
      }

      escalaSorteada.add(linha);
    }

    chamarCadastroItens();
  }



  // Escolhe o melhor voluntário garantindo:
  // 1. Todos sejam escalados ao menos 1 vez
  // 2. Prioridade para quem tem restrição de local exclusivo ou dias específicos
  // 3. Rodízio real entre os locais para quem pode trabalhar em vários postos
  String _escolherVoluntarioEquilibrado({
    required List<CheckBoxModeloVoluntario> listaVoluntarios,
    required String diaSemanaAtual,
    required String nomeLocal,
    required List<String> escaladosHoje,
    required Map<String, int> contagemGeralEscalas,
    required Map<String, Map<String, int>> contagemPorLocal,
  }) {
    List<CheckBoxModeloVoluntario> elegiveisHoje = listaVoluntarios.where((vol) {
      if (escaladosHoje.contains(vol.texto)) return false;
      return _voluntarioPodeTrabalharNoDia(vol, diaSemanaAtual, nomeLocal);
    }).toList();

    if (elegiveisHoje.isEmpty) {
      return "Sem voluntário";
    }

    // 1. REGRA DE OURO: Quem ainda não foi escalado NENHUMA vez (0 escalas)
    List<CheckBoxModeloVoluntario> nuncaEscalados = elegiveisHoje
        .where((vol) => (contagemGeralEscalas[vol.texto] ?? 0) == 0)
        .toList();

    if (nuncaEscalados.isNotEmpty) {
      nuncaEscalados.sort((a, b) {
        // Prioridade máxima para quem só pode trabalhar neste local exclusivo
        bool aLocalExclusivo = _temRestricaoLocalExclusivo(a);
        bool bLocalExclusivo = _temRestricaoLocalExclusivo(b);
        if (aLocalExclusivo && !bLocalExclusivo) return -1;
        if (!aLocalExclusivo && bLocalExclusivo) return 1;

        // Segunda prioridade para quem tem restrição de dias da semana
        bool aRestricaoDia = !_isDisponivelTodosOsDias(a);
        bool bRestricaoDia = !_isDisponivelTodosOsDias(b);
        if (aRestricaoDia && !bRestricaoDia) return -1;
        if (!aRestricaoDia && bRestricaoDia) return 1;

        return 0;
      });
      return nuncaEscalados.first.texto;
    }

    // 2. EQUILÍBRIO GERAL + RODÍZIO DE LOCAIS (evita cair sempre no mesmo posto)
    elegiveisHoje.sort((a, b) {
      int qtdGeralA = contagemGeralEscalas[a.texto] ?? 0;
      int qtdGeralB = contagemGeralEscalas[b.texto] ?? 0;

      // Primeiro equilibra o total geral de escalas no mês
      if (qtdGeralA != qtdGeralB) {
        return qtdGeralA.compareTo(qtdGeralB);
      }

      // Em caso de empate no total geral, escolhe quem trabalhou MENOS vezes NESTE local específico
      int qtdLocalA = contagemPorLocal[a.texto]?[nomeLocal] ?? 0;
      int qtdLocalB = contagemPorLocal[b.texto]?[nomeLocal] ?? 0;
      if (qtdLocalA != qtdLocalB) {
        return qtdLocalA.compareTo(qtdLocalB);
      }

      // Por fim, prioriza quem tem menos flexibilidade (local exclusivo ou dia restrito)
      bool aRestrito =
          _temRestricaoLocalExclusivo(a) || !_isDisponivelTodosOsDias(a);
      bool bRestrito =
          _temRestricaoLocalExclusivo(b) || !_isDisponivelTodosOsDias(b);
      if (aRestrito && !bRestrito) return -1;
      if (!aRestrito && bRestrito) return 1;

      return 0;
    });

    return elegiveisHoje.first.texto;
  }

  // Validação estrita de dias, folgas e horários/turnos
  // Validação estrita de dias, folgas, horários/turnos e restrições de "não" e "somente/apenas" por local
  // Validação estrita de dias, horários/turnos e restrições dinâmicas de "não" e "somente/apenas"
  // Validação estrita de dias, horários/turnos e restrições de local por frase natural
  // Identifica de forma ampla se o voluntário possui restrição exclusiva de local baseada na frase
  // Identifica se o voluntário possui restrição exclusiva de local baseada na frase
  bool _temRestricaoLocalExclusivo(CheckBoxModeloVoluntario vol) {
    String textoPerfil = _normalizar("${vol.observacao} ${vol.categoriaVoluntario}");

    bool temTermoExclusivo = textoPerfil.contains('somente') ||
        textoPerfil.contains('apenas') ||
        textoPerfil.contains('colocar em') ||
        textoPerfil.contains('colocar nas') ||
        textoPerfil.contains('colocar no') ||
        textoPerfil.contains('trabalhar em') ||
        textoPerfil.contains('trabalhar nas') ||
        textoPerfil.contains('trabalhar no') ||
        textoPerfil.contains('escala em') ||
        textoPerfil.contains('escalado em') ||
        RegExp(r'\bso\b').hasMatch(textoPerfil);

    if (!temTermoExclusivo) return false;

    // Verifica se menciona qualquer local cadastrado ou variações/sinônimos comuns (ofertas, sentinela, portaria, altar, etc.)
    for (var loc in locaisSorteioVoluntarios) {
      String nomeLocNorm = _normalizar(loc.nome);
      if (textoPerfil.contains(nomeLocNorm) ||
          (nomeLocNorm.contains('oferta') && (textoPerfil.contains('oferta') || textoPerfil.contains('recolher'))) ||
          (nomeLocNorm.contains('sentinela') && textoPerfil.contains('sentinela')) ||
          (nomeLocNorm.contains('portaria') && textoPerfil.contains('portaria')) ||
          (nomeLocNorm.contains('altar') && textoPerfil.contains('altar'))) {
        return true;
      }
    }

    return false;
  }

  // Validação estrita considerando sinônimos e novos locais (sentinela, portaria, altar, ofertas)
  bool _voluntarioPodeTrabalharNoDia(
      CheckBoxModeloVoluntario vol,
      String diaSemanaAtual,
      String nomeLocal,
      ) {
    String diasPermitidos = _normalizar(vol.diasDisponiveis);
    String obsVoluntario = _normalizar(vol.observacao);
    String categoriaVol = _normalizar(vol.categoriaVoluntario);
    String diaLimpo = _normalizar(diaSemanaAtual);
    String localLimpo = _normalizar(nomeLocal);

    String diaIdentificado = "";
    if (diaLimpo.contains("segunda")) diaIdentificado = "segunda";
    else if (diaLimpo.contains("terca")) diaIdentificado = "terca";
    else if (diaLimpo.contains("quarta")) diaIdentificado = "quarta";
    else if (diaLimpo.contains("quinta")) diaIdentificado = "quinta";
    else if (diaLimpo.contains("sexta")) diaIdentificado = "sexta";
    else if (diaLimpo.contains("sabado")) diaIdentificado = "sabado";
    else if (diaLimpo.contains("domingo")) diaIdentificado = "domingo";

    // 1. VERIFICAÇÃO DE DIAS DISPONÍVEIS
    if (!_isDisponivelTodosOsDias(vol)) {
      if (diaIdentificado.isEmpty || !diasPermitidos.contains(diaIdentificado)) {
        return false;
      }
    }

    // 2. TRAVA DE EXCEÇÃO DE DIAS
    String textoPerfil = "$obsVoluntario $categoriaVol";
    if (textoPerfil.contains('nao') ||
        textoPerfil.contains('exceto') ||
        textoPerfil.contains('fora') ||
        textoPerfil.contains('nunca') ||
        textoPerfil.contains('folga')) {
      if (diaIdentificado.isNotEmpty && textoPerfil.contains(diaIdentificado)) {
        return false;
      }
    }

    // 3. RESTRIÇÕES DE PRIMEIRO OU SEGUNDO HORÁRIO
    bool restricaoNaoPrimeiro = textoPerfil.contains('nao primeiro') || textoPerfil.contains('nao_primeiro');
    bool restricaoSomentePrimeiro = textoPerfil.contains('somente primeiro') ||
        textoPerfil.contains('apenas primeiro') ||
        RegExp(r'\bso primeiro\b').hasMatch(textoPerfil);

    bool restricaoNaoSegundo = textoPerfil.contains('nao segundo') || textoPerfil.contains('nao_segundo');
    bool restricaoSomenteSegundo = textoPerfil.contains('somente segundo') ||
        textoPerfil.contains('apenas segundo') ||
        RegExp(r'\bso segundo\b').hasMatch(textoPerfil);

    bool ehPrimeiroHorario = localLimpo.contains('01') || localLimpo.contains('1') || localLimpo.contains('primeiro');
    bool ehSegundoHorario = localLimpo.contains('02') || localLimpo.contains('2') || localLimpo.contains('segundo');

    if (restricaoNaoPrimeiro && ehPrimeiroHorario) return false;
    if (restricaoNaoSegundo && ehSegundoHorario) return false;
    if (restricaoSomentePrimeiro && !ehPrimeiroHorario) return false;
    if (restricaoSomenteSegundo && !ehSegundoHorario) return false;

    // 4. BLOQUEIO DE LOCAIS ESPECÍFICOS POR NEGAÇÃO ("NÃO", "EXCETO")
    if (textoPerfil.contains('nao') ||
        textoPerfil.contains('exceto') ||
        textoPerfil.contains('fora') ||
        textoPerfil.contains('nunca')) {
      List<String> palavrasLocal = localLimpo.split(RegExp(r'\s+'));
      for (String palavra in palavrasLocal) {
        if (palavra.length > 2 && textoPerfil.contains(palavra)) {
          return false;
        }
      }
    }

    // 5. RESTRIÇÃO EXCLUSIVA DE LOCAL AMPLIADA (Trata ofertas, sentinela, portaria, altar e variações)
    if (_temRestricaoLocalExclusivo(vol)) {
      bool bateuComLocalAtual = false;

      List<String> palavrasLocalAtual = localLimpo
          .split(RegExp(r'\s+'))
          .where((p) => p.length > 2)
          .toList();

      for (String palavra in palavrasLocalAtual) {
        if (textoPerfil.contains(palavra)) {
          bateuComLocalAtual = true;
          break;
        }
      }

      // Equivalência semântica expandida
      if (!bateuComLocalAtual) {
        if ((localLimpo.contains('oferta') || localLimpo.contains('recolher')) &&
            (textoPerfil.contains('oferta') || textoPerfil.contains('recolher'))) {
          bateuComLocalAtual = true;
        } else if (localLimpo.contains('sentinela') && textoPerfil.contains('sentinela')) {
          bateuComLocalAtual = true;
        } else if (localLimpo.contains('portaria') && textoPerfil.contains('portaria')) {
          bateuComLocalAtual = true;
        } else if (localLimpo.contains('altar') && textoPerfil.contains('altar')) {
          bateuComLocalAtual = true;
        }
      }

      // Se a pessoa tem restrição exclusiva, bloqueia qualquer local que não seja o correspondente
      if (!bateuComLocalAtual) {
        return false;
      }
    }

    return true;
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
          .add({nomeDocumentoFireBase: nomeEscalaFormatada}).then(
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
                                    chamarFazerSorteio(); // Mantém compatibilidade
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