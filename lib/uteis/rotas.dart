import 'package:flutter/material.dart';
import 'package:sscaleg/telas/geracao_escalas/tela_cadastro_selecao_local_trabalho.dart';
import 'package:sscaleg/telas/geracao_escalas/tela_cadastro_selecao_nomes_voluntarios.dart';
import 'package:sscaleg/telas/geracao_escalas/tela_gerar_escala.dart';
import 'package:sscaleg/telas/geracao_escalas/tela_selecao_dias_semana.dart';
import 'package:sscaleg/telas/geracao_escalas/tela_selecao_intervalo_trabalho.dart';
import 'package:sscaleg/telas/tela_atualizar_item.dart';
import 'package:sscaleg/telas/tela_cadastro_item.dart';
import 'package:sscaleg/telas/tela_cadastro_novo_campo.dart';
import 'package:sscaleg/telas/tela_configurar_pdf_baixar.dart';
import 'package:sscaleg/telas/tela_escala_detalhada.dart';
import 'package:sscaleg/telas/tela_inicial.dart';
import 'package:sscaleg/telas/tela_listagem_escala_banco_dados.dart';
import 'package:sscaleg/telas/tela_observacao.dart';
import 'package:sscaleg/telas/tela_remover_campos.dart';

import '../telas/tela_splash.dart';
import 'constantes.dart';

class Rotas {
  static GlobalKey<NavigatorState>? navigatorKey = GlobalKey<NavigatorState>();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Recebe os parâmetros na chamada do Navigator.
    final args = settings.arguments;
    switch (settings.name) {
      case Constantes.rotaTelaSplash:
        return MaterialPageRoute(builder: (_) => const TelaSplashScreen());
      case Constantes.rotaTelaInicial:
        return MaterialPageRoute(builder: (_) => const TelaInicial());
      case Constantes.rotaTelaCadastroSelecaoLocalTrabalho:
        return MaterialPageRoute(
          builder: (_) => const TelaCadastroSelecaoLocalTrabalho(),
        );
      case Constantes.rotaTelaCadastroSelecaoVoluntarios:
        return MaterialPageRoute(
          builder: (_) => const TelaCadastroSelecaoNomesVoluntarios(),
        );
      case Constantes.rotaTelaSelecaoDiasSemana:
        return MaterialPageRoute(builder: (_) => const TelaSelecaoDiasSemana());
      case Constantes.rotaTelaSelecaoIntervaloTrabalho:
        return MaterialPageRoute(
          builder: (_) => const TelaSelecaoIntervaloTrabalho(),
        );
      case Constantes.rotaTelaGerarEscala:
        return MaterialPageRoute(builder: (_) => const TelaGerarEscala());
      case Constantes.rotaTelaListagemEscalaBandoDados:
        return MaterialPageRoute(
          builder: (_) => const TelaListagemTabelasBancoDados(),
        );
      case Constantes.rotaTelaEscalaDetalhada:
        if (args is Map) {
          return MaterialPageRoute(
            builder:
                (_) => TelaEscalaDetalhada(
                  nomeTabela: args[Constantes.rotaArgumentoNomeEscala],
                  idTabelaSelecionada:
                      args[Constantes.rotaArgumentoIDEscalaSelecionada],
                ),
          );
        } else {
          return erroRota(settings);
        }
      case Constantes.rotaTelaCadastroItem:
        if (args is Map) {
          return MaterialPageRoute(
            builder:
                (_) => TelaCadastroItem(
                  nomeTabela: args[Constantes.rotaArgumentoNomeEscala],
                  idTabelaSelecionada:
                      args[Constantes.rotaArgumentoIDEscalaSelecionada],
                ),
          );
        } else {
          return erroRota(settings);
        }
      case Constantes.rotaTelaAtualizarItem:
        if (args is Map) {
          return MaterialPageRoute(
            builder:
                (_) => TelaAtualizarItem(
                  nomeTabela: args[Constantes.rotaArgumentoNomeEscala],
                  idTabelaSelecionada:
                      args[Constantes.rotaArgumentoIDEscalaSelecionada],
                ),
          );
        } else {
          return erroRota(settings);
        }
      case Constantes.rotaTelaCadastroCampoNovo:
        if (args is Map) {
          return MaterialPageRoute(
            builder:
                (_) => TelaCadastroCampoNovo(
                  nomeEscala: args[Constantes.rotaArgumentoNomeEscala],
                  idDocumento:
                      args[Constantes.rotaArgumentoIDEscalaSelecionada],
                  tipoTelaAnterior:
                      args[Constantes
                          .rotaArgumentoTipoTelaAnteriorCadastroCampoNovo],
                ),
          );
        } else {
          return erroRota(settings);
        }
      case Constantes.rotaTelaRemoverCampos:
        if (args is Map) {
          return MaterialPageRoute(
            builder:
                (_) => TelaRemoverCampos(
                  nomeEscala: args[Constantes.rotaArgumentoNomeEscala],
                  idDocumento:
                      args[Constantes.rotaArgumentoIDEscalaSelecionada],
                  tipoTelaAnterior:
                      args[Constantes
                          .rotaArgumentoTipoTelaAnteriorCadastroCampoNovo],
                ),
          );
        } else {
          return erroRota(settings);
        }
      case Constantes.rotaTelaObservacao:
        if (args is Map) {
          return MaterialPageRoute(
            builder:
                (_) => TelaObservacao(
                  nomeTabela: args[Constantes.rotaArgumentoNomeEscala],
                  idTabelaSelecionada:
                      args[Constantes.rotaArgumentoIDEscalaSelecionada],
                ),
          );
        } else {
          return erroRota(settings);
        }
      case Constantes.rotaTelaConfigurarPDFBaixar:
        if (args is Map) {
          return MaterialPageRoute(
            builder:
                (_) => TelaConfigurarPDFBaixar(
                  cabecalhoEscala:
                      args[Constantes.rotaArgumentoCabecalhoEscala],
                  observacoes: args[Constantes.rotaArgumentoObservacaoEscala],
                  linhasEscala: args[Constantes.rotaArgumentoLinhasEscala],
                  nomeTabela: args[Constantes.rotaArgumentoNomeEscala],
                  idTabelaSelecionada:
                      args[Constantes.rotaArgumentoIDEscalaSelecionada],
                ),
          );
        } else {
          return erroRota(settings);
        }
    }
    // Se o argumento não é do tipo correto, retorna erro
    return erroRota(settings);
  }

  //metodo para exibir tela de erro
  static Route<dynamic> erroRota(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.red,
            title: const Text("Telas não encontrada!"),
          ),
          body: Container(
            color: Colors.red,
            child: const Center(child: Text("Erro de Rota")),
          ),
        );
      },
    );
  }
}
