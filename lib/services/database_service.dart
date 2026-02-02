import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitup/models/zaproszenie_model.dart';
import '../models/uzytkownik_model.dart';
import '../models/grupa_model.dart';

class DatabaseService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  //Obsługa użytkowników

  //Dodanie nowego użytkownika
  Future<void> zapiszUzytkownika(UserModel user) async {
    await db.collection('Użytkownicy').doc(user.id).set(user.toMap());
  }

  //Edycja profilu (nazwa, telefon)
  Future<void> aktualizujProfil(String userId, Map<String, dynamic> noweDane) async {
    await db.collection('UZytkownicy').doc(userId).update(noweDane);
  }

  //Obsługa grup
  //Tworzenie nowej grupy
  Future<void> stworzGrupe(GroupModel group) async {
    await db.collection('Grupy').add(group.toMap());
  }

  //Zaproszenia
  //Wysyłanie
  Future<void> wyslijZaproszenie(ZaproszenieModel zaproszenie) async {
    await db.collection('Zaproszenia').add(zaproszenie.toMap());
  }

  //Akceptacja oraz zmiana statusu
  Future<void> zaakceptujZaproszenie(ZaproszenieModel zaproszenie) async {
    await db.collection('Zaproszenia').doc(zaproszenie.id).update({'status': 'zaakceptowane',
    });

    //Dopisywanie czlonka do grupy
    await db.collection('Grupy').doc(zaproszenie.idGrupy).update({
      'idCzlonkow': FieldValue.arrayUnion([zaproszenie.idUzytkownika])
    });
  }

  //Odrzucanie
  Future<void> odrzucZaproszenie(String zaproszenieId) async {
    await db.collection('Zaproszenia').doc(zaproszenieId).update({
      'status': 'odrzucone',
    });
  }

  // Dodanie osoby bezpośrednio do listy idCzlonkow w Grupie
  Future<void> dodajCzlonkaBezposrednio(String groupId, String userId) async {
    await db.collection('Grupy').doc(groupId).update({
      'idCzlonkow': FieldValue.arrayUnion([userId])
    });
  }

  //Wyszukiwanie grupy po nazwie
  Stream<List<GroupModel>> szukajGrup(String fraza) {
    return db
        .collection('Grupy')
        .where('nazwaGrupy', isGreaterThanOrEqualTo: fraza)
        .where('nazwaGrupy', isLessThanOrEqualTo: fraza + '\uf8ff')
        .snapshots()
        .map((snapshot) => snapshot.docs
          .map((doc) => GroupModel.fromMap(doc.id, doc.data()))
          .toList());
  }

  // Wyszukiwanie po telefonie (dokładne dopasowanie)
  Future<List<UserModel>> szukajUzytkownikaPoTelefonie(String telefon) async {
    String czystyNumer = wyczyscNumer(telefon);

    var snapshot = await db
        .collection('Użytkownicy')
        .where('Telefon', isEqualTo: telefon)
        .get();

    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  //Obsługa wydatków

  //Dodanie wydatku do konkretnej grupy
  //Ścieżka: Grupy -> {id_grupy} -> Wydatki (podkolekcja)
  Future<void> dodajWydatek(String groupId, WydatekModel wydatek) async {
    await db
        .collection('Grupy')
        .doc(groupId)
        .collection('Wydatki')
        .add(wydatek.toMap());
  }

  //Edycja wydatku
  Future<void> edytujWydatek(String groupId, String wydatekId, WydatekModel nowyWydatek) async {
    await db
        .collection('Grupy')
        .doc(groupId)
        .collection('Wydatki')
        .doc(wydatekId)
        .update(nowyWydatek.toMap());
  }

  // Funkcja pobierająca listę wydatków dla konkretnej grupy
  Stream<List<WydatekModel>> pobierzWydatkiGrupy(String groupId) {
    return db
        .collection('Grupy')
        .doc(groupId)
        .collection('Wydatki')
        .orderBy('czasDodaniaWydatku', descending: true) // Najnowsze wydatki na górze
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      return WydatekModel.fromMap(doc.data());
    }).toList());
  }
  
  //Pobieranie strumienia grup
  Stream<List<GroupModel>> pobierzGrupy() {
    return db.collection('Grupy').snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => GroupModel.fromMap(doc.id, doc. data())).toList());
  }

  // Usunięcie członka z grupy (np. gdy ktoś opuści grupę)
  Future<void> usunCzlonkaZGrupy(String groupId, String userId) async {
    await db.collection('Grupy').doc(groupId).update({
      'idCzlonkow': FieldValue.arrayRemove([userId]) // arrayRemove to przeciwieństwo arrayUnion
    });
  }

// Usunięcie konkretnego wydatku
  Future<void> usunWydatek(String groupId, String wydatekId) async {
    await db
        .collection('Grupy')
        .doc(groupId)
        .collection('Wydatki')
        .doc(wydatekId)
        .delete();
  }


  //Pomocnicze
  // Czyszczenie nr tel ze spacji
  String wyczyscNumer(String numer) {
    // Usuwa wszystko co nie jest cyfrą lub znakiem +
    return numer.replaceAll(RegExp(r'[^0-9+]'), '');
  }
}