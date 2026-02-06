import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitup/pages/auth/auth_choice_page.dart';

import 'change_photo_page.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Wylogowano')));

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthChoicePage()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Błąd wylogowania: $e')));
    }
  }

  void _goToChangePhoto(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ChangePhotoPage()));
  }

  void _goToEditProfile(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const EditProfilePage()));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _ProfileTopRow(),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _GrayActionButton(
                        title: 'ZMIEŃ ZDJĘCIE',
                        icon: Icons.photo_camera,
                        onTap: () => _goToChangePhoto(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _GrayActionButton(
                        title: 'EDYTUJ DANE',
                        icon: Icons.edit,
                        onTap: () => _goToEditProfile(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                _LogoutButton(onTap: () => _signOut(context)),
              ],
            ),
          ),
        ),

        // EMAIL Z BAZY / AUTH
        Positioned(
          left: 0,
          right: 0,
          top: 180,
          child: Center(
            child: _EmailLine(
              fallbackEmail: user?.email ?? '',
              color: cs.onSurface,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmailLine extends StatelessWidget {
  final String fallbackEmail;
  final TextStyle? style;
  final Color color;

  const _EmailLine({
    required this.fallbackEmail,
    required this.color,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Text('-', style: style);
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data();
        final emailFromDb = (data?['email'] as String?)?.trim() ?? '';
        final email = emailFromDb.isNotEmpty
            ? emailFromDb
            : (fallbackEmail.isNotEmpty ? fallbackEmail : '-');

        return Text(email, textAlign: TextAlign.center, style: style);
      },
    );
  }
}

class _ProfileTopRow extends StatelessWidget {
  const _ProfileTopRow();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: cs.surfaceContainerHighest,
            child: Icon(Icons.person, size: 40, color: cs.onSurface),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoLine(text: 'imię/ksywa'),
                SizedBox(height: 6),
                _InfoLine(text: 'nr tel.'),
                SizedBox(height: 6),
                _InfoLine(text: 'nr konta'),
              ],
            ),
          ),
        ],
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        final photoUrl = (data?['photoUrl'] as String?)?.trim() ?? '';

        final dn = (data?['displayName'] as String?)?.trim() ?? '';
        final legacyName = (data?['name'] as String?)?.trim() ?? '';
        final displayName = dn.isNotEmpty
            ? dn
            : (legacyName.isNotEmpty ? legacyName : 'imię/ksywa');

        final phone = (data?['phone'] as String?)?.trim() ?? 'nr tel.';
        final bankAccount =
            (data?['bankAccount'] as String?)?.trim() ?? 'nr konta';

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: cs.surfaceContainerHighest,
              backgroundImage: photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
              child: photoUrl.isEmpty
                  ? Icon(Icons.person, size: 40, color: cs.onSurface)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoLine(text: displayName),
                  const SizedBox(height: 6),
                  _InfoLine(text: phone),
                  const SizedBox(height: 6),
                  _InfoLine(text: bankAccount),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String text;

  const _InfoLine({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
      ),
    );
  }
}

class _GrayActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _GrayActionButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: cs.onSurface),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, size: 18, color: cs.error),
              const SizedBox(width: 10),
              Text(
                'WYLOGUJ',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                  color: cs.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
