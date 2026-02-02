import 'package:flutter/material.dart';

import 'bills.dart';
import 'groups.dart';
import 'join.dart';
import 'profile.dart';

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
                      Text(
                        'Patryk',
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: cs.surfaceContainerHighest,
                        child: Icon(
                          Icons.person,
                          size: 18,
                          color: cs.onSurface,
                        ),
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
