import 'package:flutter/material.dart';

class Constantes {
  //ROTAS
  static const rotaTelaSplash = "telaSplash";
  static const rotaTelaInicial = "telaInicial";
  static const rotaTelaLoginCadastro = "loginCadastro";
  static const rotaTelaDadosUsuario = "dadosUsuario";

  //Rotas da GERACAO DE ESCALA
  static const rotaTelaCadastroSelecaoLocalTrabalho =
      "telaCadSelecaoLocalTrabalho";
  static const rotaTelaCadastroSelecaoVoluntarios = "telaCadSelecaoVoluntarios";
  static const rotaTelaSelecaoDiasSemana = "telaSelecaoDiasSemana";
  static const rotaTelaSelecaoIntervaloTrabalho =
      "telaSelecaoIntervaloTrabalho";
  static const rotaTelaGerarEscala = "telaGerarEscala";

  //ROTAS LISTAGEM ESCALAS
  static const rotaTelaListagemEscalaBandoDados =
      "telaListagemEscalaBancoDados";
  static const rotaTelaEscalaDetalhada = "telaEscalaDetalhada";

  //CADASTRO E ATUALIZAR ITEM
  static const rotaTelaCadastroItem = "telaCadastroItem";
  static const rotaTelaAtualizarItem = "telaAtualizarItem";

  //CADASTRAR E REMOVER CAMPOS
  static const rotaTelaCadastroCampoNovo = "telaCadastroCampoNovo";
  static const rotaTelaRemoverCampos = "telaRemoverCampos";

  static const rotaTelaObservacao = "telaObservacao";

  static const rotaTelaConfigurarPDFBaixar = "telaConfigurarPDFBaixar";

  static const tipoTelaAnteriorCadastroItem = "telaAnteriorCadastroItem";
  static const tipoTelaAnteriorAtualizarItem = "telaAnteriorAtualizarItem";

  //ARGUMENTOS
  static const rotaArgumentoNomeEscala = "nomeEscala";
  static const rotaArgumentoIDEscalaSelecionada = "IDEscalaSelecionada";
  static const rotaArgumentoIDItemSelecionado = "IDEscalaSelecionada";
  static const rotaArgumentoTipoTelaAnteriorCadastroCampoNovo =
      "cadastroCampoNovo";
  static const rotaArgumentoCabecalhoEscala = "cabecalhoEscala";
  static const rotaArgumentoLinhasEscala = "linhasEscala";
  static const rotaArgumentoObservacaoEscala = "observacaoEscala";

  static const infoUsuarioUID = "uid";
  static const infoUsuarioEmail = "email";

  // datas da semana
  static const diaSegunda = "Segunda-feira";
  static const diaTerca = "Terça-feira";
  static const diaQuarta = "Quarta-feira";
  static const diaQuinta = "Quinta-feira";
  static const diaSexta = "Sexta-feira";
  static const diaSabado = "Sábado";
  static const diaDomingo = "Domingo";

  //Complementos da geracao de escala
  static const dataCulto = "01_data";
  static const horarioTrabalho = "02_horario_de_Trabalho";
  static const editar = "Editar";
  static const excluir = "Excluir";
  static const idDocumento = "idDocumento";

  // ICONES
  static const iconeTelaInicial = Icons.home_filled;
  static const iconeEditar = Icons.edit;
  static const iconeVoltar = Icons.arrow_back_ios_new_outlined;
  static const iconeLista = Icons.list_alt_outlined;
  static const iconeExclusao = Icons.close;
  static const iconeAbrirBarraPesquisa = Icons.search;
  static const iconeBarraPesquisar = Icons.send;
  static const iconeDataCulto = Icons.date_range_outlined;
  static const iconeMudarHorario = Icons.access_time_filled_outlined;
  static const iconeEmail = Icons.email;
  static const iconeSenha = Icons.password;

  // SHARE PREFERENCES
  static const sharePreferencesAjustarHorarioSemana = "ajustarHorarioSemana";
  static const sharePreferencesAjustarHorarioFinalSemana =
      "ajustarHorarioFinalSemana";

  //Horarios padrao
  static const TimeOfDay horarioPadraoSemana = TimeOfDay(hour: 19, minute: 20);
  static const TimeOfDay horarioPadraoFinalSemana = TimeOfDay(
    hour: 17,
    minute: 50,
  );

  static const confirmacaoSelecaoDataComplemento =
      "selecaoDataComplemento";

  static const tipoBuscaAdicionarCampo = "buscaAdicionarCampo";

  //TIPO NOTIFICACAO
  static const tipoNotificacaoSucesso = "Sucesso";
  static const tipoNotificacaoErro = "Erro";

  //FIRE BASE
  //LOCAIS TRABALHO

  static const fireBaseColecaoUsuarios = "Usuarios";

  static const fireBaseColecaoNomeLocaisTrabalho = "locais_trabalho";
  static const fireBaseDocumentoNomeLocaisTrabalho = "nome";

  //COMPLEMENTO DATA DEPARTAMENTO
  static const fireBaseColecaoNomeDepartamentosData = "departamentos_data";
  static const fireBaseDocumentoNomeDepartamentosData = "nome";

  //VOLUNTARIOS
  static const fireBaseColecaoNomeVoluntarios = "nome_voluntarios";
  static const fireBaseDocumentoNomeVoluntarios = "nome";

  //OBSERVACOES
  static const fireBaseColecaoNomeObservacao = "Observacoes";
  static const fireBaseDocumentoNomeObservacao = "nome";

  //CABECALHO PDF
  static const fireBaseColecaoNomeCabecalhoPDF = "cabecalhoPDF";
  static const fireBaseDocumentoNomeCabecalhoPDF = "nome";

  //VOLUNTARIOS
  static const fireBaseColecaoEscalas = "Escalas";
  static const fireBaseDadosCadastrados = "dados_tabela";
  static const fireBaseDocumentoNomeEscalas = "nome_escalas";
}
