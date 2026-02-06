import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'group_service.dart';

class ReceiptDetailsPage extends StatefulWidget {
  final String groupId; // 4-znakowy kod
  final String receiptId; // id paragonu

  const ReceiptDetailsPage({
    super.key,
    required this.groupId,
    required this.receiptId,
  });

  @override
  State<ReceiptDetailsPage> createState() => _ReceiptDetailsPageState();
}

class _ReceiptDetailsPageState extends State<ReceiptDetailsPage> {
  final _service = GroupService();

  // cache na nazwy userów
  final Map<String, String> _nameCache = {};

  Future<String> _getUserName(String uid) async {
    if (_nameCache.containsKey(uid)) return _nameCache[uid]!;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = snap.data();
    final name = (data?['name'] ?? data?['displayName'] ?? uid).toString();
    _nameCache[uid] = name;
    return name;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openEdit(
    Map<String, dynamic> group,
    Map<String, dynamic> receipt,
  ) async {
    final titleCtrl = TextEditingController(
      text: (receipt['title'] ?? '').toString(),
    );

    final sharesRaw = receipt['shares'];
    final shares = <String, double>{};
    if (sharesRaw is Map) {
      for (final e in sharesRaw.entries) {
        shares[e.key.toString()] = (e.value is num)
            ? (e.value as num).toDouble()
            : 0.0;
      }
    }

    final membersRaw = group['memberIds'];
    final members = (membersRaw is List)
        ? membersRaw.map((e) => e.toString()).toList()
        : <String>[];

    // kontrolery dla kwot
    final ctrls = <String, TextEditingController>{};
    for (final uid in members) {
      final v = shares[uid] ?? 0.0;
      ctrls[uid] = TextEditingController(
        text: v == 0 ? '' : v.toStringAsFixed(2),
      );
    }

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (ctx, setLocal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    'Edytuj paragon',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tytuł',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Kwoty na osoby',
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: members.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final uid = members[i];
                        return FutureBuilder<String>(
                          future: _getUserName(uid),
                          builder: (_, ns) {
                            final label = ns.data ?? uid;
                            return TextField(
                              controller: ctrls[uid],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: label,
                                border: const OutlineInputBorder(),
                                hintText: '0.00',
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('ZAPISZ ZMIANY'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (ok != true) {
      titleCtrl.dispose();
      for (final c in ctrls.values) c.dispose();
      return;
    }

    try {
      final newShares = <String, num>{};
      for (final e in ctrls.entries) {
        final raw = e.value.text.trim().replaceAll(',', '.');
        if (raw.isEmpty) {
          newShares[e.key] = 0;
          continue;
        }
        final v = double.tryParse(raw);
        if (v == null) throw Exception('Niepoprawna liczba przy: ${e.key}');
        newShares[e.key] = v;
      }

      await _service.updateReceipt(
        groupId: widget.groupId,
        receiptId: widget.receiptId,
        title: titleCtrl.text,
        shares: newShares,
      );

      _snack('Zapisano zmiany');
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      titleCtrl.dispose();
      for (final c in ctrls.values) c.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final cs = Theme.of(context).colorScheme;
    final gid = widget.groupId.trim().toUpperCase();

    final groupRef = FirebaseFirestore.instance.collection('groups').doc(gid);

    return Scaffold(
      appBar: AppBar(title: const Text('Szczegóły paragonu')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: groupRef.snapshots(),
        builder: (context, groupSnap) {
          if (groupSnap.hasError)
            return Center(child: Text('Błąd: ${groupSnap.error}'));
          if (!groupSnap.hasData)
            return const Center(child: CircularProgressIndicator());

          final group = groupSnap.data!.data() ?? <String, dynamic>{};
          final status = (group['status'] as String?) ?? 'open';
          final ownerId = (group['ownerId'] ?? '').toString();

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _service.receiptDocStream(
              groupId: widget.groupId,
              receiptId: widget.receiptId,
            ),
            builder: (context, snap) {
              if (snap.hasError)
                return Center(child: Text('Błąd: ${snap.error}'));
              if (!snap.hasData)
                return const Center(child: CircularProgressIndicator());

              final doc = snap.data!;
              if (!doc.exists)
                return const Center(child: Text('Paragon nie istnieje'));

              final receipt = doc.data() ?? <String, dynamic>{};
              final title = (receipt['title'] ?? 'Paragon').toString();
              final payerId = (receipt['payerId'] ?? '').toString();
              final currency = (receipt['currency'] ?? 'PLN').toString();
              final total = (receipt['total'] is num)
                  ? (receipt['total'] as num).toDouble()
                  : 0.0;

              final canEdit =
                  (status == 'open') &&
                  (uid != null) &&
                  (uid == payerId || uid == ownerId);

              final sharesRaw = receipt['shares'];
              final shares = <String, double>{};
              if (sharesRaw is Map) {
                for (final e in sharesRaw.entries) {
                  shares[e.key.toString()] = (e.value is num)
                      ? (e.value as num).toDouble()
                      : 0.0;
                }
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    FutureBuilder<String>(
                      future: payerId.isEmpty
                          ? Future.value('-')
                          : _getUserName(payerId),
                      builder: (_, ns) => Text(
                        'Płacący: ${ns.data ?? payerId}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Suma: ${total.toStringAsFixed(2)} $currency',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Chip(
                          label: Text(
                            status == 'open'
                                ? 'Grupa otwarta'
                                : 'Grupa zamknięta',
                          ),
                        ),
                        const Spacer(),
                        if (canEdit)
                          FilledButton.icon(
                            onPressed: () => _openEdit(group, receipt),
                            icon: const Icon(Icons.edit),
                            label: const Text('EDYTUJ'),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Text(
                      'Udziały',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),

                    Expanded(
                      child: ListView.separated(
                        itemCount: shares.keys.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final u = shares.keys.elementAt(i);
                          final v = shares[u] ?? 0.0;
                          return FutureBuilder<String>(
                            future: _getUserName(u),
                            builder: (_, ns) {
                              final name = ns.data ?? u;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Text('${v.toStringAsFixed(2)} $currency'),
                                  ],
                                ),
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
          );
        },
      ),
    );
  }
}
