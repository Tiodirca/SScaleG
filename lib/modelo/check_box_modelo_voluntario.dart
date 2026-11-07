import 'package:cloud_firestore/cloud_firestore.dart';

class CheckBoxModeloVoluntario {
  CheckBoxModeloVoluntario({
    required this.texto,
    this.id = "",
    this.checked = false,
    required this.categoriaVoluntario,
    this.diasDisponiveis = "",
    this.observacao = ""
  });

  String id;
  String texto;
  String categoriaVoluntario;
  String diasDisponiveis;
  String observacao;
  bool checked;

  factory CheckBoxModeloVoluntario.fromFirestore(
    DocumentSnapshot<Map<dynamic, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return CheckBoxModeloVoluntario(
      texto: data?['nomeVoluntario'],
      categoriaVoluntario: data?['categoriaVoluntario'],
      diasDisponiveis: data?['diasDisponiveis'],
      observacao: data?['observacao']
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "id": id,
      "nomeVoluntario": texto,
      "categoriaVoluntario": categoriaVoluntario,
      "diasDisponiveis": diasDisponiveis,
      "observacao" : observacao
    };
  }
}
