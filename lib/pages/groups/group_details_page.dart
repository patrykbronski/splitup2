import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'add_receipt_page.dart';
import 'group_service.dart';
import 'receipt_details_page.dart';

class GroupDetailsPage extends StatelessWidget {
  final String groupId; // kod grupy, np. BDML
  const GroupDetailsPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final gid = groupId.trim().toUpperCase();
    final cs = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Musisz być zalogowany')));
    }

    final groupRef = FirebaseFirestore.instance.collection('groups').doc(gid);

    return Scaffold(
      appBar: AppBar(title: const Text('Szczegóły grupy')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: groupRef.snapshots(),
        builder: (context, groupSnap) {
          if (groupSnap.hasError) {
            return Center(child: Text('Błąd: ${groupSnap.error}'));
          }
          if (!groupSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final doc = groupSnap.data!;
          if (!doc.exists) {
            return const Center(child: Text('Grupa nie istnieje'));
          }

          final data = doc.data()!;
          final name = (data['name'] ?? 'Grupa') as String;
          final code = (data['code'] ?? gid) as String;

          final ownerId = (data['ownerId'] ?? '').toString();
          final isOwner = ownerId == user.uid;

          final status = (data['status'] as String?) ?? 'open';
          final currency = (data['currency'] as String?) ?? 'PLN';

          final membersRaw = data['memberIds'];
          final members = (membersRaw is List)
              ? membersRaw.map((e) => e.toString()).toList()
              : <String>[];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Material(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          children: [
                            _Chip(text: 'Kod: $code'),
                            _Chip(text: 'Waluta: $currency'),
                            _Chip(
                              text: status == 'closed'
                                  ? 'Zamknięta'
                                  : 'Otwarta',
                            ),
                            _Chip(text: 'Członkowie: ${members.length}'),
                            if (isOwner) _Chip(text: 'Owner'),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: status == 'closed'
                                    ? null
                                    : () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                AddReceiptPage(groupId: gid),
                                          ),
                                        );
                                      },
                                icon: const Icon(Icons.receipt_long),
                                label: const Text('DODAJ PARAGON'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: (!isOwner || status == 'closed')
                                    ? null
                                    : () async {
                                        final ok = await _confirmClose(context);
                                        if (!ok) return;

                                        try {
                                          await GroupService().closeGroup(
                                            groupId: gid,
                                            actorId: user.uid,
                                          );

                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Grupa zamknięta. Wygenerowano rachunki.',
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                e.toString().replaceFirst(
                                                  'Exception: ',
                                                  '',
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                icon: const Icon(Icons.lock),
                                label: const Text('ZAMKNIJ'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: cs.error,
                                  foregroundColor: cs.onError,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (!isOwner)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Tylko właściciel grupy może ją zamknąć.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: GroupService().receiptsStream(gid),
                  builder: (context, recSnap) {
                    if (recSnap.hasError) {
                      return Center(child: Text('Błąd: ${recSnap.error}'));
                    }
                    if (!recSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = recSnap.data!.docs;

                    if (docs.isEmpty) {
                      return const Center(
                        child: Text('Brak paragonów w tej grupie'),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final d = docs[i].data();
                        final title = (d['title'] ?? 'Paragon') as String;
                        final payerId = (d['payerId'] ?? '').toString();
                        final total = (d['total'] as num?)?.toDouble() ?? 0.0;

                        return Material(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ReceiptDetailsPage(
                                    groupId: groupId,
                                    receiptId: docs[i].id,
                                  ),
                                ),
                              );
                            },

                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.receipt),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Suma: ${total.toStringAsFixed(2)} $currency',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color:
                                                          cs.onSurfaceVariant,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '• Płaci:',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: cs.onSurfaceVariant,
                                                  ),
                                            ),
                                            const SizedBox(width: 6),
                                            _UserNameInline(
                                              uid: payerId,
                                              meUid: user.uid,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<bool> _confirmClose(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Zamknąć grupę'),
            content: const Text(
              'Po zamknięciu zostanie policzony bilans i wygenerowane rachunki. '
              'Tego nie da się cofnąć (na tym etapie).',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('ANULUJ'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('ZAMKNIJ'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _UserNameInline extends StatelessWidget {
  final String uid;
  final String meUid;

  const _UserNameInline({required this.uid, required this.meUid});

  String _shortUid(String uid) {
    if (uid.length <= 10) return uid;
    return '${uid.substring(0, 6)}...${uid.substring(uid.length - 3)}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (uid == meUid) {
      return Text(
        'Ty',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: cs.onSurface,
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snap) {
        final data = snap.data?.data();
        final dn = (data?['displayName'] as String?)?.trim() ?? '';
        final legacy = (data?['name'] as String?)?.trim() ?? '';
        final best = dn.isNotEmpty ? dn : legacy;

        return Text(
          best.isNotEmpty ? best : _shortUid(uid),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
