import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:sscaleg/uteis/constantes.dart';
import 'package:flutter/material.dart';
import 'package:sscaleg/uteis/passar_pegar_dados.dart';

class ValidarLoginCadastroUsuario {

  static Future<String> fazerLogin(
    String email,
    String senha,
    BuildContext context,
  ) async {
    try {
      String retorno = "";
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );
      if (credential.user != null) {
        passarInformacoes(
          credential.user!.uid,
          credential.user!.email.toString(),
        );
        retorno = Constantes.tipoNotificacaoSucesso;
      } else {
        retorno = Constantes.tipoNotificacaoErro;
      }
      return retorno;
    } on FirebaseAuthException catch (e) {
      return e.code.toString();
    }
  }

  static Future<String> criarCadastro(
      String email,
      String senha,
      BuildContext context,
      ) async {
    try {
      String retorno = "";
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );
      if (credential.user != null) {
        passarInformacoes(
          credential.user!.uid,
          credential.user!.email.toString(),
        );
        retorno = Constantes.tipoNotificacaoSucesso;
      } else {
        retorno = Constantes.tipoNotificacaoErro;
      }
      return retorno;
    } on FirebaseAuthException catch (e) {
      return e.code.toString();
    }
  }
}

passarInformacoes(String uid, String email) {
  Map dados = {};
  dados[Constantes.infoUsuarioUID] = uid;
  dados[Constantes.infoUsuarioEmail] = email;
  PassarPegarDados.passarInformacoesUsuario(dados);
}
