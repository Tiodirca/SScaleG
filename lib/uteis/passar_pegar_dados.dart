class PassarPegarDados {
  static List<String> listaNomesLocaisTrabalho = [];
  static List<String> listaNomesVoluntarios = [];
  static List<String> listaDiasSemana = [];
  static List<String> listaIntervaloTrabalho = [];
  static List<String> listaCamposLinhaItem = [];
  static List<String> listaObservacoesPDF = [];
  static List<dynamic> listaItensAtualizar = [];
  static Map itensCadastrarAtualizar = {};
  static String idItemAtualizarSelecionado = "";
  static String horarioFinalSemanaDefinido = "";
  static String horarioSemanaDefinido = "";
  static String horarioTrocaTurnoFinalSemanaDefinido = "";
  static String horarioTrocaTurnoSemanaDefinido = "";
  static String dataComComplemento = "";
  static String confirmacaoSelecaoDataComplemento = "";

  static Map informacoesUsuario = {};

  static List<String> passarNomesLocaisTrabalho(List<String> locaisTrabalho) {
    listaNomesLocaisTrabalho = locaisTrabalho;
    return listaNomesLocaisTrabalho;
  }

  static List<String> recuperarNomesLocaisTrabalho() {
    return listaNomesLocaisTrabalho;
  }

  static List<String> passarNomesVoluntarios(List<String> voluntarios) {
    listaNomesVoluntarios = voluntarios;
    return listaNomesVoluntarios;
  }

  static List<String> recuperarNomesVoluntarios() {
    return listaNomesVoluntarios;
  }

  static List<String> passarDiasSemana(List<String> diaSemana) {
    listaDiasSemana = diaSemana;
    return listaDiasSemana;
  }

  static List<String> recuperarDiasSemana() {
    return listaDiasSemana;
  }

  static List<String> passarIntervaloTrabalho(List<String> intervalo) {
    listaIntervaloTrabalho = intervalo;
    return listaIntervaloTrabalho;
  }

  static List<String> recuperarIntervaloTrabalho() {
    return listaIntervaloTrabalho;
  }

  static String passarHorarioSemanaDefinido(String horarioSemana) {
    horarioSemanaDefinido = horarioSemana;
    return horarioSemanaDefinido;
  }

  static String recuperarHorarioSemanaDefinido() {
    return horarioSemanaDefinido;
  }

  static String passarHorarioFinalSemanaDefinido(String horarioSemana) {
    horarioFinalSemanaDefinido = horarioSemana;
    return horarioFinalSemanaDefinido;
  }

  static String recuperarHorarioFinalSemanaDefinido() {
    return horarioFinalSemanaDefinido;
  }

  static String passarHorarioTrocaTurnoSemanaDefinido(
    String horarioTrocaSemana,
  ) {
    horarioTrocaTurnoSemanaDefinido = horarioTrocaSemana;
    return horarioTrocaTurnoSemanaDefinido;
  }

  static String recuperarHorarioTrocaTurnoSemanaDefinido() {
    return horarioTrocaTurnoSemanaDefinido;
  }

  static String passarHorarioTrocaTurnoFinalSemanaDefinido(
    String horarioTrocaSemana,
  ) {
    horarioTrocaTurnoFinalSemanaDefinido = horarioTrocaSemana;
    return horarioTrocaTurnoFinalSemanaDefinido;
  }

  static String recuperarHorarioTrocaTurnoFinalSemanaDefinido() {
    return horarioTrocaTurnoFinalSemanaDefinido;
  }

  static String passarDataComComplemento(String dataComplemento) {
    dataComComplemento = dataComplemento;
    return dataComComplemento;
  }

  static String recuperarDataComComplemento() {
    return dataComComplemento;
  }

  static String passarConfirmacaoSelecaoDataComplemento(
    String dataComplemento,
  ) {
    confirmacaoSelecaoDataComplemento = dataComplemento;
    return confirmacaoSelecaoDataComplemento;
  }

  static String recuperarConfirmacaoSelecaoDataComplemento() {
    return confirmacaoSelecaoDataComplemento;
  }

  static List<String> passarCamposItem(List<String> campos) {
    listaCamposLinhaItem = campos;
    return listaCamposLinhaItem;
  }

  static List<String> recuperarCamposItem() {
    return listaCamposLinhaItem;
  }

  static String passarIdAtualizarSelecionado(String id) {
    idItemAtualizarSelecionado = id;
    return idItemAtualizarSelecionado;
  }

  static String recuperarIdAtualizarSelecionado() {
    return idItemAtualizarSelecionado;
  }

  static Map passarItens(Map itens) {
    itensCadastrarAtualizar = itens;
    return itensCadastrarAtualizar;
  }

  static Map recuperarItens() {
    return itensCadastrarAtualizar;
  }

  static List<String> passarObservacoesPDF(List<String> observacoes) {
    listaObservacoesPDF = observacoes;
    return listaObservacoesPDF;
  }

  static List<String> recuperarObservacoesPDF() {
    return listaObservacoesPDF;
  }

  static Map passarInformacoesUsuario(Map infoUsuario) {
    informacoesUsuario = infoUsuario;
    return informacoesUsuario;
  }

  static Map recuperarInformacoesUsuario() {
    return informacoesUsuario;
  }
}
