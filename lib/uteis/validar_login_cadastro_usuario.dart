import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:sscaleg/uteis/constantes.dart';
import 'package:sscaleg/uteis/metodos_auxiliares.dart';
import 'package:flutter/material.dart';
import 'package:sscaleg/uteis/passar_pegar_dados.dart';
import 'package:sscaleg/uteis/textos.dart';

class ValidarLoginCadastroUsuario {
  static redirecionarTelaLoginCadastro(BuildContext context) {
    Navigator.pushReplacementNamed(context, Constantes.rotaTelaLoginCadastro);
  }

  static redirecionarTelaInicial(BuildContext context) {
    Navigator.pushReplacementNamed(context, Constantes.rotaTelaInicial);
  }

  static fazerLogin(String email, String senha, BuildContext context) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );
      if (credential.user != null) {
        passarInformacoes(credential.user!.uid, credential.user!.email.toString());
        redirecionarTelaInicial(context);
      } else {
        //print("USUARIO NÂO ENCONTRADO");
      }
    } on FirebaseAuthException catch (e) {
      validarErro(e.code.toString(), context);
    }
  }
}

validarErro(String erro, BuildContext context) {
  if (erro == 'user-not-found') {
    chamarExibirMensagemErro(
      Textos.erroValidarUsuarioEmailNaoCadastrado,
      context,
    );
  } else if (erro == 'wrong-password') {
    chamarExibirMensagemErro(Textos.erroValidarUsuarioSenhaErrada, context);
    chamarExibirMensagemErro(erro, context);
  } else if (erro == "invalid-email") {
    chamarExibirMensagemErro(Textos.erroValidarUsuarioEmailErrado, context);
  } else if (erro == "unknown-error") {
    chamarExibirMensagemErro("Erro Desconhecido : $erro", context);
  }
}

passarInformacoes(String uid, String email) {
  Map dados = {};
  dados[Constantes.infoUsuarioUID] = uid;
  dados[Constantes.infoUsuarioEmail] = email;
  PassarPegarDados.passarInformacoesUsuario(dados);
}

chamarExibirMensagemErro(String erro, BuildContext context) {
  MetodosAuxiliares.exibirMensagens(
    Constantes.tipoNotificacaoErro,
    erro,
    context,
  );
}
