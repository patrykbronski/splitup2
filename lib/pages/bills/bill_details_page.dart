import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BillDetailsPage extends StatelessWidget {
  final String billId;
  const BillDetailsPage({super.key, required this.billId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Musisz być zalogowany')));
    }

    final billRef = FirebaseFirestore.instance.collection('bills').doc(billId);

    return Scaffold(
      appBar: AppBar(title: const Text('Rachunek')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: billRef.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Błąd: ${snap.error}'));
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());

          final doc = snap.data!;
          if (!doc.exists)
            return const Center(child: Text('Rachunek nie istnieje'));

          final data = doc.data()!;
          final ownerId = (data['userId'] ?? '').toString();
          if (ownerId != user.uid) {
            return const Center(child: Text('Brak dostępu'));
          }

          final groupName = (data['groupName'] ?? 'Grupa') as String;
          final currency = (data['currency'] ?? 'PLN') as String;
          final items = (data['items'] is List)
              ? (data['items'] as List)
              : const [];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pozycje do opłacenia',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 12),

                if (items.isEmpty)
                  const Expanded(
                    child: Center(child: Text('Brak płatności do wykonania')),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final it = items[i];
                        if (it is! Map) return const SizedBox.shrink();

                        final toUserId = (it['toUserId'] ?? '').toString();
                        final amount =
                            (it['amount'] as num?)?.toDouble() ?? 0.0;
                        final paid = it['paid'] == true;

                        return _BillItemTile(
                          toUserId: toUserId,
                          amount: amount,
                          currency: currency,
                          paid: paid,
                          onTogglePaid: () async {
                            await _togglePaid(
                              billRef: billRef,
                              index: i,
                              newPaid: !paid,
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _togglePaid({
    required DocumentReference<Map<String, dynamic>> billRef,
    required int index,
    required bool newPaid,
  }) async {
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(billRef);
      if (!snap.exists) return;
      final data = snap.data()!;
      final items = (data['items'] is List)
          ? List<Map<String, dynamic>>.from(data['items'])
          : <Map<String, dynamic>>[];

      if (index < 0 || index >= items.length) return;

      final updated = Map<String, dynamic>.from(items[index]);
      updated['paid'] = newPaid;
      items[index] = updated;

      // status done gdy wszystko paid albo items puste
      final allPaid = items.isNotEmpty && items.every((e) => e['paid'] == true);
      final status = items.isEmpty ? 'done' : (allPaid ? 'done' : 'open');

      tx.update(billRef, {'items': items, 'status': status});
    });
  }
}

class _BillItemTile extends StatelessWidget {
  final String toUserId;
  final double amount;
  final String currency;
  final bool paid;
  final VoidCallback onTogglePaid;

  const _BillItemTile({
    required this.toUserId,
    required this.amount,
    required this.currency,
    required this.paid,
    required this.onTogglePaid,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(toUserId);

    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTogglePaid,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                paid ? Icons.check_circle : Icons.cancel,
                color: paid ? Colors.green : cs.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: userRef.snapshots(),
                  builder: (context, snap) {
                    final data = snap.data?.data();
                    final name = (data?['displayName'] as String?) ?? toUserId;
                    final phone = (data?['phone'] as String?) ?? '-';
                    final bank = (data?['bankAccount'] as String?) ?? '-';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tel: $phone',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Konto: $bank',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${amount.toStringAsFixed(2)} $currency',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
