import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String nazwa;
  final String email;
  final String telefon;
  final String zdjecie;
  final DateTime czasUtworzenia;

  UserModel({
    required this.id,
    required this.nazwa,
    required this.email,
    required this.telefon,
    required this.zdjecie,
    required this.czasUtworzenia
});

// Zamiana obiektu na Mapę do wysłania do Firebase
Map<String, dynamic> toMap() {
  return {
    'nazwa': nazwa,
    'E-mail': email,
    'Telefon': telefon,
    'zdecie': zdjecie,
    'czasUtworzenia': Timestamp.fromDate(czasUtworzenia),
  };
}

// Tworzenie obiektu z danych pobranych z Firebase
factory UserModel.fromMap(String id, Map<String, dynamic> map) {
  return UserModel(
    id: id,
    nazwa: map['nazwa'] ?? '',
    email: map['E-mail'] ?? '',
    telefon: map['Telefon'] ?? '',
    zdjecie: map['zdecie'] ?? '',
    czasUtworzenia: (map['czasUtworzenia'] as Timestamp).toDate(),
  );
}
}