import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constantes.dart';

class ValidarAlteracaoEmail {
  static String nomeCampoEmailAlterado =
      Constantes.fireBaseCampoUsuarioEmailAlterado;
  static String nomeColecaoUsuariosFireBase =
      Constantes.fireBaseColecaoUsuarios;

  //metodo para fazer buscar a informacao gravada no bando de dados
  static Future<String> consultarEmailAlterado(String uidUsuario) async {
    String emailAlteracao = "";
    var db = FirebaseFirestore.instance;
    await db
        .collection(nomeColecaoUsuariosFireBase) // passando a colecao
        .doc(uidUsuario)
        .get()
        .then((event) {
          //definindo que a variavel
          // vai receber o seguinte valor
          emailAlteracao = event
              .data()!
              .values
              .toString()
              .replaceAll("(", "")
              .replaceAll(")", "");
        });
    return emailAlteracao;
  }

  // static Future<String> validarConfirmacaoAlteracaoEmail(
  //   String uid,
  //   String emailAlteracao,
  // ) async {
  //   String retorno = "";
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   //recuperando senha do usuario gravada ao
  //   // fazer login,cadastro ou alteracao da senha
  //   String senhaUsuario = prefs.getString(Constantes.infoUsuarioSenha) ?? '';
  //   //fazendo autenticacao do usuario usando o email puxado do banco de dados para verificar
  //   // se houve confirmacao de alteracao de email
  //   AuthCredential credencial = EmailAuthProvider.credential(
  //     email: emailAlteracao,
  //     password: senhaUsuario,
  //   );
  //   try {
  //     //vazendo login utilizando as informacoes passadas no credencial
  //      FirebaseAuth.instance
  //         .signInWithCredential(credencial)
  //         .then(
  //           (value) async {
  //             // caso a autenticacao seja VERDADEIRA sera feito
  //             // a atualizacao no banco de dados e redicionamento de tela
  //             print("fdsfsdf");
  //             // retorno = await gravarEmailAlteradoBancoDados(
  //             //   uid,
  //             //   emailAlteracao,
  //             // );
  //             // gravarEmailAlteradoBancoDados(uid, emailAlteracao);
  //           },
  //           onError: (e) {
  //             retorno = Constantes.statusEmailNaoAlterado;
  //             debugPrint("o mesmo");
  //           },
  //         );
  //   } on FirebaseAuthException {
  //     retorno = Constantes.statusEmailNaoAlterado;
  //     debugPrint("Email mesmo");
  //   }
  //   return retorno;
  // }
  //
  // static Future<String> gravarEmailAlteradoBancoDados(
  //   String uid,
  //   String emailAlteracao,
  // ) async {
  //   String retornoAlteracao = "";
  //   try {
  //     // instanciando Firebase
  //     var db = FirebaseFirestore.instance;
  //     await db
  //         .collection(nomeColecaoUsuariosFireBase)
  //         .doc(uid)
  //         // sera setado vazio no banco de dados
  //         .set({nomeCampoEmailAlterado: ""})
  //         .then(
  //           (value) {
  //             retornoAlteracao = Constantes.statusEmailAlterado;
  //             print("GRA : $retornoAlteracao");
  //           },
  //           onError: (e) {
  //             retornoAlteracao = Constantes.statusEmailNaoAlterado;
  //             debugPrint(e.toString());
  //           },
  //         );
  //   } catch (e) {
  //     retornoAlteracao = Constantes.statusEmailNaoAlterado;
  //     debugPrint(e.toString());
  //   }
  //   return retornoAlteracao;
  // }
}
