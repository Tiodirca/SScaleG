class PassarPegarDados {
  static List<String> nomesLocaisTrabalho = [];
  static List<String> nomesVoluntarios = [];
  static List<String> diasSemana = [];
  static List<String> intervaloTrabalho = [];

  static List<String> passarNomesLocaisTrabalho(List<String> locaisTrabalho) {
    nomesLocaisTrabalho = locaisTrabalho;
    return nomesLocaisTrabalho;
  }

  static List<String> recuperarNomesLocaisTrabalho() {
    return nomesLocaisTrabalho;
  }

  static List<String> passarNomesVoluntarios(List<String> voluntarios) {
    nomesVoluntarios = voluntarios;
    return nomesVoluntarios;
  }

  static List<String> recuperarNomesVoluntarios() {
    return nomesVoluntarios;
  }

  static List<String> passarDiasSemana(List<String> diaSemana) {
    diasSemana = diaSemana;
    return diasSemana;
  }

  static List<String> recuperarDiasSemana() {
    return diasSemana;
  }

  static List<String> passarIntervaloTrabalho(List<String> intervalo) {
    intervaloTrabalho = intervalo;
    return intervaloTrabalho;
  }

  static List<String> recuperarIntervaloTrabalho() {
    return intervaloTrabalho;
  }
}
