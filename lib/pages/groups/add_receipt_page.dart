import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'group_service.dart';

class AddReceiptPage extends StatefulWidget {
  final String groupId;
  const AddReceiptPage({super.key, required this.groupId});

  @override
  State<AddReceiptPage> createState() => _AddReceiptPageState();
}

class _AddReceiptPageState extends State<AddReceiptPage> {
  final _titleCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  String _currency = 'PLN';
  List<String> _members = [];
  final Map<String, TextEditingController> _amountCtrls = {};

  // uid -> displayName / name
  final Map<String, String> _nameCache = {};

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    for (final c in _amountCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _loadGroup() async {
    final gid = widget.groupId.trim().toUpperCase();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(gid)
          .get();

      if (!doc.exists) throw Exception('Grupa nie istnieje');

      final data = doc.data()!;
      final membersRaw = data['memberIds'];
      final members = (membersRaw is List)
          ? membersRaw.map((e) => e.toString()).toList()
          : <String>[];

      final currency = (data['currency'] as String?) ?? 'PLN';

      // kontrolery kwot
      for (final uid in members) {
        _amountCtrls.putIfAbsent(uid, () => TextEditingController(text: '0'));
      }

      setState(() {
        _members = members;
        _currency = currency;
        _loading = false;
      });

      await _prefetchNames(members);
      if (mounted) setState(() {});
    } on FirebaseException catch (e) {
      // permission denied
      _snack('Błąd Firestore: ${e.code}');
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _prefetchNames(List<String> uids) async {
    final me = FirebaseAuth.instance.currentUser?.uid;

    final missing = uids
        .where((u) => u != me && !_nameCache.containsKey(u))
        .toList();

    if (missing.isEmpty) return;

    try {
      for (var i = 0; i < missing.length; i += 10) {
        final chunk = missing.sublist(
          i,
          (i + 10 > missing.length) ? missing.length : i + 10,
        );

        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final d in snap.docs) {
          final data = d.data();
          final dn = (data['displayName'] as String?)?.trim() ?? '';
          final legacy = (data['name'] as String?)?.trim() ?? '';
          final best = dn.isNotEmpty ? dn : legacy;

          _nameCache[d.id] = best.isNotEmpty ? best : _shortUid(d.id);
        }

        // jeśli jakiegoś UID nie było w wynikach
        for (final uid in chunk) {
          _nameCache.putIfAbsent(uid, () => _shortUid(uid));
        }
      }
    } on FirebaseException catch (e) {
      // jak nie mamy read do users innych osób, to permission-denied
      if (e.code == 'permission-denied') {
        _snack(
          'Brak uprawnień do odczytu profili (users). Opublikuj rules i sprawdź /users read.',
        );
      } else {
        _snack('Błąd Firestore: ${e.code}');
      }

      for (final uid in missing) {
        _nameCache.putIfAbsent(uid, () => _shortUid(uid));
      }
    } catch (_) {
      for (final uid in missing) {
        _nameCache.putIfAbsent(uid, () => _shortUid(uid));
      }
    }
  }

  String _shortUid(String uid) {
    if (uid.length <= 10) return uid;
    return '${uid.substring(0, 6)}...${uid.substring(uid.length - 3)}';
  }

  String _labelForUser(String uid) {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (uid == me) return 'Ty';
    return _nameCache[uid] ?? _shortUid(uid);
  }

  double _parseAmount(String s) {
    final cleaned = s.replaceAll(',', '.').trim();
    if (cleaned.isEmpty) return 0;
    return double.tryParse(cleaned) ?? 0;
  }

  double _calcTotal() {
    double total = 0;
    for (final uid in _members) {
      total += _parseAmount(_amountCtrls[uid]?.text ?? '0');
    }
    return total;
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      _snack('Wpisz tytuł paragonu');
      return;
    }

    final shares = <String, num>{};
    for (final uid in _members) {
      final val = _parseAmount(_amountCtrls[uid]?.text ?? '0');
      if (val < 0) {
        _snack('Kwoty nie mogą być ujemne');
        return;
      }
      shares[uid] = (val * 100).round() / 100;
    }

    final total = _calcTotal();
    if (total <= 0) {
      _snack('Suma paragonu musi być większa od 0');
      return;
    }

    setState(() => _saving = true);
    try {
      await GroupService().addReceipt(
        groupId: widget.groupId,
        title: title,
        payerId: user.uid,
        shares: shares,
      );

      if (!mounted) return;
      _snack('Dodano paragon');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Dodaj paragon')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _titleCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Tytuł (np. gokarty)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Kwoty przypisane do osób ($_currency)',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: ListView.separated(
                  itemCount: _members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final uid = _members[i];
                    final ctrl = _amountCtrls[uid]!;

                    return Material(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.person),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _labelForUser(uid),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 120,
                              child: TextField(
                                controller: ctrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                textAlign: TextAlign.right,
                                decoration: const InputDecoration(
                                  hintText: '0.00',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Suma: ${_calcTotal().toStringAsFixed(2)} $_currency',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_saving ? 'ZAPIS...' : 'ZAPISZ'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
