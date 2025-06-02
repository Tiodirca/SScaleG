import 'package:cloud_firestore/cloud_firestore.dart';

class EscalaModelo {
  String dataCulto;
  String id;
  String horarioTroca;
  var linha;

  EscalaModelo({
    this.id = "",
     this.dataCulto = "",
     this.horarioTroca = "",
    required this.linha
  });

  factory EscalaModelo.fromFirestore(
    DocumentSnapshot<Map<dynamic, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return EscalaModelo(
      dataCulto: data?['dataCulto'],
      horarioTroca: data?['horarioTroca'],
      linha: data?['linha']
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "dataCulto": dataCulto,
      "horarioTroca": horarioTroca,
      "linha" : linha
    };
  }
}
