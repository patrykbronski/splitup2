import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../bills/bills.dart';
import '../groups/groups.dart';
import '../join/join.dart';
import '../profile/profile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  final List<Widget> _pages = const [
    ProfilePage(),
    BillsPage(),
    GroupsPage(),
    JoinPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(20);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.only(left: 10, top: 10),
          child: Text(
            'splitUp',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20, top: 10),
            child: Material(
              color: Colors.transparent,
              borderRadius: radius,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                borderRadius: radius,
                onTap: () => setState(() => _index = 0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (user == null)
                        Text(
                          'konto',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w400,
                          ),
                        )
                      else
                        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .snapshots(),
                          builder: (context, snap) {
                            final data = snap.data?.data();

                            final dn =
                                (data?['displayName'] as String?)?.trim() ?? '';
                            final legacyName =
                                (data?['name'] as String?)?.trim() ?? '';
                            final authName = (user.displayName ?? '').trim();

                            final name = dn.isNotEmpty
                                ? dn
                                : (legacyName.isNotEmpty
                                      ? legacyName
                                      : (authName.isNotEmpty
                                            ? authName
                                            : 'konto'));

                            final photoUrlDb =
                                (data?['photoUrl'] as String?)?.trim() ?? '';
                            final photoUrlAuth = (user.photoURL ?? '').trim();
                            final photoUrl = photoUrlDb.isNotEmpty
                                ? photoUrlDb
                                : photoUrlAuth;

                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: cs.surfaceContainerHighest,
                                  backgroundImage: photoUrl.isNotEmpty
                                      ? NetworkImage(photoUrl)
                                      : null,
                                  child: photoUrl.isEmpty
                                      ? Icon(
                                          Icons.person,
                                          size: 18,
                                          color: cs.onSurface,
                                        )
                                      : null,
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        onTap: (newIndex) => setState(() => _index = newIndex),
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurface.withOpacity(0.65),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Rachunki',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Grupy'),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Dołącz',
          ),
        ],
      ),
    );
  }
}
