import 'package:flutter/material.dart';

class BillsPage extends StatelessWidget {
  const BillsPage({super.key});

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
                    text: 'NIE MASZ',
                    style: TextStyle(color: cs.error),
                  ),
                  const TextSpan(text: '\nŻADNYCH RACHUNKÓW!'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
