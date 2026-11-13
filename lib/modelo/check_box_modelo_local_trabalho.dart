import 'package:cloud_firestore/cloud_firestore.dart';

class CheckBoxModeloLocalTrabalho {
  CheckBoxModeloLocalTrabalho({
    this.id = "",
    this.checked = false,
    required this.nome,
    this.diasLocalObservacao = "",
    this.observacaoLocal = "",
  });

  String id;
  String nome;
  String diasLocalObservacao;
  String observacaoLocal;
  bool checked;

  factory CheckBoxModeloLocalTrabalho.fromFirestore(
    DocumentSnapshot<Map<dynamic, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return CheckBoxModeloLocalTrabalho(
      nome: data?['nome'],
      diasLocalObservacao: data?['diasLocalObservacao'],
      observacaoLocal: data?['observacaoLocal'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "id": id,
      "nome": nome,
      "diasLocalObservacao": diasLocalObservacao,
      "observacaoLocal": observacaoLocal,
    };
  }
}
