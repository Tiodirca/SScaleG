import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import '../constantes.dart';

class ExclusaoDados {

  static String nomeColecaoUsuariosFireBase =
      Constantes.fireBaseColecaoUsuarios;
  static String nomeColecaoFireBaseLocal =
      Constantes.fireBaseColecaoNomeLocaisTrabalho;
  static String nomeColecaoFireBaseVoluntario =
      Constantes.fireBaseColecaoNomeVoluntarios;
  static String nomeColecaoFireBaseObservacao =
      Constantes.fireBaseColecaoNomeObservacao;
  static String nomeColecaoFireBaseCabecalhoPDF =
      Constantes.fireBaseColecaoNomeCabecalhoPDF;
  static String nomeColecaoFireBaseEscalas = Constantes.fireBaseColecaoEscalas;
  static String nomeColecaoFireBaseDepartamentoData =
      Constantes.fireBaseColecaoNomeDepartamentosData;
  static String nomeDocumentoFireBaseEscalas =
      Constantes.fireBaseDadosCadastrados;


  static Future<bool> buscarDadosDentroEscala(String uidUsuario) async {
    bool retorno = false;
    try {
      var db = FirebaseFirestore.instance;
      await db
          .collection(nomeColecaoUsuariosFireBase) // passando a colecao
          .doc(uidUsuario)
          .collection(nomeColecaoFireBaseEscalas)
          .where(Constantes.fireBaseDocumentoNomeEscalas)
          .get()
          .then(
            (querySnapshot) async {
              for (var docSnapshot in querySnapshot.docs) {
                //deletando o CAMPO de CADA ID para poder excluir a colecao
                db
                    .collection(
                      nomeColecaoUsuariosFireBase,
                    ) // passando a colecao
                    .doc(uidUsuario)
                    .collection(nomeColecaoFireBaseEscalas)
                    .doc(docSnapshot.id)
                    .delete()
                    .then(
                      (value) {
                        retorno = true;
                      },
                      onError: (e) {
                        retorno = false;
                        debugPrint("Erro Excluir: ${e.toString()}");
                      },
                    );
                retorno = await excluirDadosColecaoDocumentoDentroEscala(
                  docSnapshot.id,
                  uidUsuario,
                );
              }
              retorno = true;
            },
            onError: (e) {
              retorno = false;
              debugPrint("Erro : ${e.toString()}");
            },
          );
    } catch (e) {
      retorno = false;
      debugPrint("Erro : ${e.toString()}");
    }
    return retorno;
  }

  //metodo para percorrer cadas ESCALA
  // EXCLUINDO CADA ELEMENTO DENTRO DELA
  static Future<bool> excluirDadosColecaoDocumentoDentroEscala(
    String idDocumentoFirebase,
    String uidUsuario,
  ) async {
    int index = 0;
    bool retornoFinalizacaoExclusao = false;
    try {
      var db = FirebaseFirestore.instance;
      await db
          .collection(nomeColecaoUsuariosFireBase) // passando a colecao
          .doc(uidUsuario)
          .collection(nomeColecaoFireBaseEscalas)
          .doc(idDocumentoFirebase)
          .collection(nomeDocumentoFireBaseEscalas)
          .get()
          .then(
            (querySnapshot) {
              // para cada iteracao do FOR excluir o
              // item corresponde ao ID da iteracao
              for (var docSnapshot in querySnapshot.docs) {
                db
                    .collection(
                      nomeColecaoUsuariosFireBase,
                    ) // passando a colecao
                    .doc(uidUsuario)
                    .collection(nomeColecaoFireBaseEscalas)
                    .doc(idDocumentoFirebase)
                    .collection(nomeDocumentoFireBaseEscalas)
                    .doc(docSnapshot.id)
                    .delete()
                    .then(
                      (value) {
                        index++;
                        if (index == querySnapshot.size) {
                          retornoFinalizacaoExclusao = true;
                        }
                      },
                      onError: (e) {
                        retornoFinalizacaoExclusao = false;
                        debugPrint(
                          "Erro Excluir Item a item Tabela : ${e.toString()}",
                        );
                      },
                    );
              }
            },
            onError: (e) {
              retornoFinalizacaoExclusao = false;
              debugPrint("Erro Excluir Item a item Tabela : ${e.toString()}");
            },
          );
    } catch (e) {
      retornoFinalizacaoExclusao = false;
      debugPrint("Erro Excluir Item a item Tabela : ${e.toString()}");
    }
    return retornoFinalizacaoExclusao;
  }

  //metodo chamado na tela de dados do usuario
  // onde vai percorrer cada item da
  // colecao/escala excluir item a item
  static Future<bool> chamarDeletarItemAItem(
    String nomeColecao,
    String uidUsuario,
  ) async {
    bool retorno = false;
    var db = FirebaseFirestore.instance;
    await db
        .collection(nomeColecaoUsuariosFireBase)
        .doc(uidUsuario)
        .collection(nomeColecao)
        .get()
        .then(
          (querySnapshot) {
            //para cada iteracao do FOR excluir o
            //item corresponde ao ID da iteracao
            for (var docSnapshot in querySnapshot.docs) {
              db
                  .collection(nomeColecaoUsuariosFireBase)
                  .doc(uidUsuario)
                  .collection(nomeColecao)
                  .doc(docSnapshot.id)
                  .delete()
                  .then(
                    (value) {
                      retorno = true;
                    },
                    onError: (e) {
                      debugPrint("Erro Excluir Item a item : ${e.toString()}");
                    },
                  );
            }
            retorno = true;
          },
          onError: (e) {
            debugPrint("Erro Excluir Item a item : ${e.toString()}");
            retorno = false;
          },
        );
    return retorno;
  }
}
