import 'package:flutter/material.dart';

import 'join.dart';
import 'groups.dart';
import 'bills.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(left: 10, top: 10),
          child: const Text(
            'splitUp',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20, top: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                setState(() {
                  _index = 0; // przejście do Profilu
                });
              },
              child: Row(
                children: const [
                  Text(
                    'Patryk',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(width: 8),
                  CircleAvatar(radius: 16, child: Icon(Icons.person, size: 18)),
                ],
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
