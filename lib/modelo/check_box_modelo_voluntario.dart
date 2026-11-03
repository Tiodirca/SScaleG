import 'package:cloud_firestore/cloud_firestore.dart';

class CheckBoxModeloVoluntario {
  CheckBoxModeloVoluntario({
    required this.texto,
    this.id = "",
    this.checked = false,
    required this.categoriaVoluntario,
    this.diasDisponiveis = "",
  });

  String id;
  String texto;
  String categoriaVoluntario;
  String diasDisponiveis;
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
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "id": id,
      "nomeVoluntario": texto,
      "categoriaVoluntario": categoriaVoluntario,
      "diasDisponiveis": diasDisponiveis,
    };
  }
}
