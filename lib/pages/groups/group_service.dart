import 'package:cloud_firestore/cloud_firestore.dart';

class GroupService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // JOIN + LISTA GRUP

  Future<void> joinByCode({
    required String code,
    required String userId,
  }) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.length != 4) {
      throw Exception('Kod musi mieć 4 znaki');
    }

    final ref = _db.collection('groups').doc(normalized);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);

      if (!snap.exists) {
        throw Exception('Nie znaleziono grupy o takim kodzie');
      }

      final data = snap.data() as Map<String, dynamic>;

      final membersRaw = data['memberIds'];
      final members = (membersRaw is List)
          ? membersRaw.map((e) => e.toString()).toList()
          : <String>[];

      if (members.contains(userId)) {
        return;
      }

      tx.update(ref, {
        'memberIds': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Query<Map<String, dynamic>> groupsForUser(String userId) {
    return _db
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true);
  }

  // PARAGONY (receipts) W GRUPIE

  Stream<DocumentSnapshot<Map<String, dynamic>>> receiptDocStream({
    required String groupId,
    required String receiptId,
  }) {
    final gid = groupId.trim().toUpperCase();
    return _db
        .collection('groups')
        .doc(gid)
        .collection('receipts')
        .doc(receiptId)
        .snapshots();
  }

  Future<void> updateReceipt({
    required String groupId,
    required String receiptId,
    required String title,
    required Map<String, num> shares,
  }) async {
    final gid = groupId.trim().toUpperCase();
    final t = title.trim();
    if (t.isEmpty) throw Exception('Wpisz tytuł paragonu');
    if (shares.isEmpty) throw Exception('Wpisz kwoty dla użytkowników');

    // policz total
    double total = 0.0;
    for (final e in shares.entries) {
      final v = e.value.toDouble();
      if (v < 0) throw Exception('Kwoty nie mogą być ujemne');
      total += v;
    }
    if (total <= 0) throw Exception('Suma paragonu musi być większa od 0');

    final ref = _db
        .collection('groups')
        .doc(gid)
        .collection('receipts')
        .doc(receiptId);

    await ref.update({
      'title': t,
      'shares': shares.map((k, v) => MapEntry(k, v.toDouble())),
      'total': total,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // paragony w grupie (najnowsze na górze).
  Stream<QuerySnapshot<Map<String, dynamic>>> receiptsStream(String groupId) {
    final gid = groupId.trim().toUpperCase();
    return _db
        .collection('groups')
        .doc(gid)
        .collection('receipts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Dodanie paragonu do grupy.
  // payerId = osoba dodająca paragon (płaci całość)
  // shares = kwoty przypisane do użytkowników
  // total jest liczony jako suma shares
  Future<void> addReceipt({
    required String groupId,
    required String title,
    required String payerId,
    required Map<String, num> shares, // uid -> kwota
  }) async {
    final gid = groupId.trim().toUpperCase();
    final t = title.trim();

    if (t.isEmpty) throw Exception('Wpisz tytuł paragonu');
    if (shares.isEmpty) throw Exception('Wpisz kwoty dla użytkowników');
    if (!shares.containsKey(payerId)) {
      throw Exception('Paragon musi zawierać kwotę dla osoby płacącej');
    }

    // POBIERZ GRUPĘ
    final groupRef = _db.collection('groups').doc(gid);
    final groupSnap = await groupRef.get();
    if (!groupSnap.exists) throw Exception('Grupa nie istnieje');

    final group = groupSnap.data() as Map<String, dynamic>;
    final membersRaw = group['memberIds'];
    final members = (membersRaw is List)
        ? membersRaw.map((e) => e.toString()).toList()
        : <String>[];

    if (!members.contains(payerId)) {
      throw Exception('Płacący nie należy do tej grupy');
    }

    // Walidacja: shares tylko dla członków + kwoty >= 0
    double total = 0.0;
    for (final entry in shares.entries) {
      final uid = entry.key;
      final val = entry.value.toDouble();
      if (!members.contains(uid)) {
        throw Exception('Wykryto użytkownika spoza grupy w udziałach');
      }
      if (val < 0) throw Exception('Kwoty nie mogą być ujemne');
      total += val;
    }

    // Walidacja: total > 0
    if (total <= 0) throw Exception('Suma paragonu musi być większa od 0');

    final currency = (group['currency'] as String?) ?? 'PLN';

    await groupRef.collection('receipts').add({
      'title': t,
      'payerId': payerId,
      'currency': currency,
      'shares': shares.map((k, v) => MapEntry(k, v.toDouble())),
      'total': total,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await groupRef.update({'updatedAt': FieldValue.serverTimestamp()});
  }

  // ZAMKNIĘCIE GRUPY + GENEROWANIE RACHUNKÓW
  // Zamyka grupę i generuje rachunki (bills) dla wszystkich członków.
  // Tylko ownerId może wykonać.
  // bills/{groupId}_{userId}:
  // userId (właściciel rachunku)

  Future<void> closeGroup({
    required String groupId,
    required String actorId, // kto klika "zamknij"
  }) async {
    final gid = groupId.trim().toUpperCase();
    final groupRef = _db.collection('groups').doc(gid);

    final groupSnap = await groupRef.get();
    if (!groupSnap.exists) throw Exception('Grupa nie istnieje');

    final group = groupSnap.data() as Map<String, dynamic>;

    final ownerId = (group['ownerId'] ?? '').toString();
    if (ownerId != actorId) {
      throw Exception('Tylko właściciel grupy może ją zamknąć');
    }

    final status = (group['status'] as String?) ?? 'open';
    if (status == 'closed') {
      throw Exception('Grupa jest już zamknięta');
    }

    final membersRaw = group['memberIds'];
    final members = (membersRaw is List)
        ? membersRaw.map((e) => e.toString()).toList()
        : <String>[];

    if (members.isEmpty) throw Exception('Brak członków grupy');

    final groupName = (group['name'] as String?) ?? 'Grupa';
    final currency = (group['currency'] as String?) ?? 'PLN';

    // pobieramy wszystkie paragony
    final receiptsSnap = await groupRef.collection('receipts').get();

    if (receiptsSnap.docs.isEmpty) {
      throw Exception('Nie ma żadnych paragonów do rozliczenia');
    }

    // 1) policz net per user
    final net = <String, double>{for (final m in members) m: 0.0};

    for (final doc in receiptsSnap.docs) {
      final data = doc.data();
      final payerId = (data['payerId'] ?? '').toString();
      if (!net.containsKey(payerId)) {
        // jeżeli ktoś spoza grupy - błąd
        throw Exception('Wykryto paragon z płacącym spoza grupy');
      }

      final total = (data['total'] as num?)?.toDouble() ?? 0.0;
      if (total <= 0) continue;

      // payer + total
      net[payerId] = (net[payerId] ?? 0) + total;

      final sharesRaw = data['shares'];
      if (sharesRaw is Map) {
        sharesRaw.forEach((k, v) {
          final uid = k.toString();
          final share = (v is num) ? v.toDouble() : 0.0;
          if (!net.containsKey(uid)) {
            throw Exception('Wykryto udział spoza grupy w paragonie');
          }
          net[uid] = (net[uid] ?? 0) - share;
        });
      }
    }

    // 2) z net robimy minimalne przelewy
    final transfers = _minTransfers(net);

    // 3) z transfers budujemy bills per debtor (fromUserId)
    final billsItems = <String, List<Map<String, dynamic>>>{};

    for (final tr in transfers) {
      final from = tr.fromUserId;
      final to = tr.toUserId;
      final amount = tr.amount;

      billsItems.putIfAbsent(from, () => []);
      billsItems[from]!.add({'toUserId': to, 'amount': amount, 'paid': false});
    }

    // 4) zapis: batch
    final batch = _db.batch();
    final closedAt = FieldValue.serverTimestamp();

    // update group
    batch.update(groupRef, {
      'status': 'closed',
      'closedAt': closedAt,
      'closedBy': actorId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // bills dla każdego członka (nawet jeśli puste - wtedy status done)
    for (final uid in members) {
      final items = billsItems[uid] ?? <Map<String, dynamic>>[];
      final billRef = _db.collection('bills').doc('${gid}_$uid');

      batch.set(billRef, {
        'userId': uid,
        'groupId': gid,
        'groupName': groupName,
        'currency': currency,
        'createdAt': closedAt,
        'status': items.isEmpty ? 'done' : 'open',
        'items': items,
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  // HELPERY: minimal transfers

  List<_Transfer> _minTransfers(Map<String, double> net) {
    // Zaokrąglenie do groszy
    // zakładamy 2 miejsca
    double round2(double x) => (x * 100).roundToDouble() / 100;

    final creditors = <_Balance>[];
    final debtors = <_Balance>[];

    for (final e in net.entries) {
      final v = round2(e.value);
      if (v > 0.0) creditors.add(_Balance(e.key, v));
      if (v < 0.0) debtors.add(_Balance(e.key, -v)); // kwota do oddania
    }

    // sortowanie największe najpierw
    creditors.sort((a, b) => b.amount.compareTo(a.amount));
    debtors.sort((a, b) => b.amount.compareTo(a.amount));

    final res = <_Transfer>[];

    int i = 0, j = 0;
    while (i < debtors.length && j < creditors.length) {
      final d = debtors[i];
      final c = creditors[j];

      final pay = round2(d.amount < c.amount ? d.amount : c.amount);
      if (pay > 0) {
        res.add(
          _Transfer(fromUserId: d.userId, toUserId: c.userId, amount: pay),
        );
        d.amount = round2(d.amount - pay);
        c.amount = round2(c.amount - pay);
      }

      if (d.amount <= 0.0) i++;
      if (c.amount <= 0.0) j++;
    }

    return res;
  }
}

class _Balance {
  final String userId;
  double amount;
  _Balance(this.userId, this.amount);
}

class _Transfer {
  final String fromUserId;
  final String toUserId;
  final double amount;
  _Transfer({
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
  });
}
