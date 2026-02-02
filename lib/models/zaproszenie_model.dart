import 'package:cloud_firestore/cloud_firestore.dart';

class ZaproszenieModel {
  final String id;
  final String idGrupy;
  final String nazwaGrupy;
  final String idUzytkownika; //Kto chce dołączyć
  final String nazwaUzytkownika;
  final String idWlascicielaGrupy; //Kto akceptuje
  final String status; //oczekujace, zaakceptowane, odrzucone

  ZaproszenieModel({
    required this.id,
    required this.idGrupy,
    required this.nazwaGrupy,
    required this.idUzytkownika,
    required this.nazwaUzytkownika,
    required this.idWlascicielaGrupy,
    this.status = 'oczekujace',
});

  Map<String, dynamic> toMap() {
    return{
      'idGrupy': idGrupy,
      'nazwaGrupy': nazwaGrupy,
      'idUzytkownika': idUzytkownika,
      'nazwaUzytkownika': nazwaUzytkownika,
      'idWlascicielaGrupy': idWlascicielaGrupy,
      'status': status,
      'dataProsby': FieldValue.serverTimestamp(),
    };
  }

  factory ZaproszenieModel.fromMap(String id, Map<String, dynamic> map) {
    return ZaproszenieModel(
        id: id,
        idGrupy: map['idGrupy'] ?? '',
        nazwaGrupy: map['nazwaGrupy'] ?? '',
        idUzytkownika: map['idUzytkownika'] ?? '',
        nazwaUzytkownika: map['nazwaUzytkownika'] ?? '',
        idWlascicielaGrupy: map['idWlascicielaGrupy'] ?? '',
        status: map['status'] ?? 'oczekujace',
    );
  }
}