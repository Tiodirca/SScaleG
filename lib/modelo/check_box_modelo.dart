import 'package:cloud_firestore/cloud_firestore.dart';

class CheckBoxModelo {
  CheckBoxModelo(
      {required this.texto, this.id = "", this.checked = false});

  String id;
  String texto;
  bool checked;

  factory CheckBoxModelo.fromFirestore(
    DocumentSnapshot<Map<dynamic, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return CheckBoxModelo(
      texto: data?['nome'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "id" : id,
      "nome": texto,
    };
  }
}
