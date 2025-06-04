class PassarPegarDados {
  static List<String> listaNomesLocaisTrabalho = [];
  static List<String> listaNomesVoluntarios = [];
  static List<String> listaDiasSemana = [];
  static List<String> listaIntervaloTrabalho = [];
  static List<String> listaCamposCadastroItens = [];
  static String horarioFinalSemanaDefinido = "";
  static String horarioSemanaDefinido = "";

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

  static List<String> passarCamposCadastroItem(List<String> camposCadastro) {
    listaCamposCadastroItens = camposCadastro;
    return listaCamposCadastroItens;
  }

  static List<String> recuperarCamposCadastroItem() {
    return listaCamposCadastroItens;
  }
}
