import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String nazwaGrupy;
  final String opis;
  final String status;
  final String idWlasciciela;
  final List<String> idCzlonkow;

  GroupModel({
    required this.id,
    required this.nazwaGrupy,
    required this.opis,
    required this.status,
    required this.idWlasciciela,
    required this.idCzlonkow,
});

  factory GroupModel.fromMap(String id, Map<String, dynamic> map) {
    return GroupModel(
      id: id,
      nazwaGrupy: map['nazwaGrupy'] ?? '',
      opis: map['opis'] ?? '',
      status: map['Status'] ?? '',
      idWlasciciela: map['idWlasciciela'] ?? '',
      idCzlonkow: List<String>.from(map['idCzlonkow'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nazwaGrupy': nazwaGrupy,
      'opis': opis,
      'Status': status,
      'idWlasciciela': idWlasciciela,
      'idCzlonkow': idCzlonkow,
    };
  }
}

// Klasa dla wydatku
class WydatekModel {
  final String nazwaWydatku;
  final double cena;
  final String waluta;
  final String idPlatnika;
  final Map<String, dynamic> ileKto;

  WydatekModel({
    required this.nazwaWydatku,
    required this.cena,
    required this.waluta,
    required this.idPlatnika,
    required this.ileKto,
});

  Map<String, dynamic> toMap() {
    return {
      'nazwaWydatku': nazwaWydatku,
      'Cena': cena,
      'Waluta': waluta,
      'idPlatnika': idPlatnika,
      'ileKto': ileKto,
      'czasDodaniaWydatku': FieldValue.serverTimestamp(),
    };
  }

  // Dodaj to do klasy WydatekModel
  factory WydatekModel.fromMap(Map<String, dynamic> map) {
    return WydatekModel(
      nazwaWydatku: map['nazwaWydatku'] ?? '',
      cena: (map['Cena'] as num).toDouble(), // Bezpieczna konwersja na double
      waluta: map['Waluta'] ?? 'PLN',
      idPlatnika: map['idPlatnika'] ?? '',
      ileKto: Map<String, dynamic>.from(map['ileKto'] ?? {}),
    );
  }
}