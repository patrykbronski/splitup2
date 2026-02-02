import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: const [
            _ProfileHeader(),
            SizedBox(height: 24),
            // _SectionTitle(title: 'Ustawienia'),
            // SizedBox(height: 8),
            _ProfileTile(
              icon: Icons.person,
              title: 'Dane konta',
              subtitle: 'Imię, zdjęcie, nr konta/tel.',
            ),
            _ProfileTile(
              icon: Icons.info_outline,
              title: 'O aplikacji',
              subtitle: 'Dowiedz się jak działa apka',
            ),
            SizedBox(height: 16),
            _LogoutButton(),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(radius: 32, child: Icon(Icons.person, size: 32)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Patryk',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'patrykbronski@tlen.pl',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
        // const Icon(Icons.edit),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip
          .antiAlias, //dopasowuje krawędzie efektu kliknięcia do kształtu przycisku
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black12),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // na razie puste; później tu dasz nawigację do podstron
        },
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        // później: wylogowanie (Firebase / SharedPreferences)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wylogowanie - do zrobienia')),
        );
      },
      icon: const Icon(Icons.logout),
      label: const Text('Wyloguj'),
    );
  }
}
