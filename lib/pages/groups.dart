import 'package:flutter/material.dart';

class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: cs.onSurface,
                ),
                children: [
                  const TextSpan(text: 'AKTUALNIE '),
                  TextSpan(
                    text: 'NIE NALEŻYSZ',
                    style: TextStyle(color: cs.error),
                  ),
                  const TextSpan(text: '\nDO ŻADNEJ GRUPY'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _GrayActionButton(
              title: 'STWÓRZ GRUPĘ',
              icon: Icons.add,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stwórz grupę – do zrobienia')),
                );
              },
            ),
            const SizedBox(height: 14),
            _GrayActionButton(
              title: 'DOŁĄCZ',
              icon: Icons.group_add,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dołącz – do zrobienia')),
                );
              },
            ),
          ],
        ),
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

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 240),
      child: Material(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: cs.onSurface),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
