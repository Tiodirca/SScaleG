import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
          senha,
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
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: senha);
      if (credential.user != null) {
        passarInformacoes(
          credential.user!.uid,
          credential.user!.email.toString(),
          senha,
        );
        criarCampoEmailAlterado(credential.user!.uid);
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

// metodo para cadastrar item
criarCampoEmailAlterado(String uid) async {
  try {
    // instanciando Firebase
    var db = FirebaseFirestore.instance;
    db
        .collection(Constantes.fireBaseColecaoUsuarios)
        .doc(uid)
        .set({Constantes.fireBaseCampoUsuarioEmailAlterado: ""})
        .then(
          (value) {},
          onError: (e) {
            debugPrint(e.toString());
          },
        );
  } catch (e) {
    debugPrint(e.toString());
  }
}

passarInformacoes(String uid, String email, senha) {
  Map dados = {};
  dados[Constantes.infoUsuarioUID] = uid;
  dados[Constantes.infoUsuarioEmail] = email;
  gravarSenhaUsuario(senha);
  PassarPegarDados.passarInformacoesUsuario(dados);
}

gravarSenhaUsuario(String senha) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString(Constantes.infoUsuarioSenha, senha);
}
