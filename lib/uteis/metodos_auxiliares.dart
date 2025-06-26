import 'package:flutter/material.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sscaleg/uteis/constantes.dart';
import 'package:sscaleg/uteis/textos.dart';

class MetodosAuxiliares {
  static exibirMensagens(String tipoAlerta, String msg, BuildContext context) {
    if (tipoAlerta == Constantes.tipoNotificacaoSucesso) {
      ElegantNotification.success(
        width: 360,
        title: Text(tipoAlerta),
        showProgressIndicator: false,
        animationDuration: const Duration(seconds: 1),
        toastDuration: const Duration(seconds: 2),
        description: Text(msg),
      ).show(context);
    } else {
      return ElegantNotification.error(
        width: 360,
        title: Text(tipoAlerta),
        showProgressIndicator: false,
        animationDuration: const Duration(seconds: 1),
        toastDuration: const Duration(seconds: 2),
        description: Text(msg),
      ).show(context);
    }
  }

  static formatarHorarioAjuste(TimeOfDay horarioDefinido) {
    String horarioFormatado =
        "${Textos.widgetAjustarHorarioInicio}${horarioDefinido.hour.toString().padLeft(2, "0")}:${horarioDefinido.minute.toString().padLeft(2, "0")}";
    return horarioFormatado;
  }

  static gravarHorarioInicioTrabalhoDefinido(
    String parametroSharePreferences,
    String horarioDefinido,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(parametroSharePreferences, horarioDefinido);
  }

  static recuperarValoresSharePreferences(
    String parametroSharePreferences,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String valorRecuperado = prefs.getString(parametroSharePreferences) ?? '';
    return valorRecuperado;
  }

  //metodo para ajustar o tamanho do textField com base no tamanho da tela
  static ajustarTamanhoTextField(double larguraTela) {
    double tamanho = 150;
    //verificando qual o tamanho da tela
    if (larguraTela <= 600) {
      tamanho = 150;
    } else {
      tamanho = 300;
    }
    return tamanho;
  }

  static quantidadeColunasGridView(double larguraTela) {
    int tamanho = 5;
    //verificando qual o tamanho da tela
    if (larguraTela <= 600) {
      tamanho = 2;
    } else if (larguraTela >= 600 && larguraTela <= 1000) {
      tamanho = 4;
    } else {
      tamanho = 5;
    }
    return tamanho;
  }

}
