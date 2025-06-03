import 'package:flutter/material.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:sscaleg/uteis/constantes.dart';

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
}
