import 'package:flutter/material.dart';

class Constantes {
  //ROTAS
  static const rotaTelaSplash = "telaSplash";
  static const rotaTelaInicial = "telaInicial";
  //Rotas da GERACAO DE ESCALA
  static const rotaTelaCadastroSelecaoLocalTrabalho =
      "telaCadSelecaoLocalTrabalho";
  static const rotaTelaCadastroSelecaoVoluntarios = "telaCadSelecaoVoluntarios";
  static const rotaTelaSelecaoDiasSemana = "telaSelecaoDiasSemana";
  static const rotaTelaSelecaoIntervaloTrabalho =
      "telaSelecaoIntervaloTrabalho";
  static const rotaTelaGerarEscala = "telaGerarEscala";

  //ROTAS LISTAGEM ESCALAS
  static const rotaTelaListagemEscalaBandoDados = "telaListagemEscalaBancoDados";
  static const rotaTelaEscalaDetalhada = "telaEscalaDetalhada";

  //ARGUMENTOS
  static const rotaArgumentEscalaDetalhadaNomeEscala = "nomeEscala";
  static const rotaArgumentoEscalaDetalhadaIDEscalaSelecionada = "IDEscalaSelecionada";

  // datas da semana
  static const diaSegunda = "Segunda-feira";
  static const diaTerca = "Terça-feira";
  static const diaQuarta = "Quarta-feira";
  static const diaQuinta = "Quinta-feira";
  static const diaSexta = "Sexta-feira";
  static const diaSabado = "Sábado";
  static const diaDomingo = "Domingo";

  //Complementos da geracao de escala
  static const dataCulto = "DData";
  static const horarioTrabalho = "DHorario de Trabalho";
  static const editar = "Editar";
  static const excluir = "Excluir";
  static const idDocumento = "idDocumento";

  // ICONES
  static const iconeTelaInicial = Icons.home_filled;
  static const iconeAdicionar = Icons.add;
  static const iconeAtualizar = Icons.update;
  static const iconeEditar = Icons.edit;
  static const iconeLista = Icons.list_alt_outlined;
  static const iconeOpcoesData = Icons.settings;

  static const iconeExclusao = Icons.close;
  static const iconeRecarregar = Icons.refresh;
  static const iconeBaixar = Icons.download_rounded;


  static const iconeSalvar = Icons.save;
  static const iconeAbrirBarraPesquisa = Icons.search;
  static const iconeBarraPesquisar = Icons.send;
  static const iconeSalvarOpcoes = Icons.save_as;
  static const iconeDataCulto = Icons.date_range_outlined;

  //TIPO NOTIFICACAO
  static const tipoNotificacaoSucesso = "Sucesso";
  static const tipoNotificacaoErro = "Erro";

  //FIRE BASE
  //LOCAIS TRABALHO
  static const fireBaseColecaoNomeLocaisTrabalho = "locais_trabalho";
  static const fireBaseDocumentoNomeLocaisTrabalho = "nome";

  //VOLUNTARIOS
  static const fireBaseColecaoNomeVoluntarios = "nome_voluntarios";
  static const fireBaseDocumentoNomeVoluntarios = "nome";

  //VOLUNTARIOS
  static const fireBaseColecaoEscalas = "Escalas";
  static const fireBaseDadosCadastrados = "dados_tabela";
  static const fireBaseDocumentoNomeEscalas = "nome_escalas";
}
