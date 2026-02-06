import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChangePhotoPage extends StatefulWidget {
  const ChangePhotoPage({super.key});

  @override
  State<ChangePhotoPage> createState() => _ChangePhotoPageState();
}

class _ChangePhotoPageState extends State<ChangePhotoPage> {
  final _picker = ImagePicker();

  File? _file;
  bool _uploading = false;
  double _progress = 0.0;

  Future<void> _pickFromGallery() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1080,
      );
      if (picked == null) return;

      setState(() {
        _file = File(picked.path);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Błąd wyboru zdjęcia: $e')));
    }
  }

  Future<void> _upload() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brak zalogowanego użytkownika')),
      );
      return;
    }
    if (_file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Najpierw wybierz zdjęcie z galerii')),
      );
      return;
    }

    setState(() {
      _uploading = true;
      _progress = 0.0;
    });

    try {
      // Upload pliku do Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(user.uid)
          .child('profile.jpg');

      final uploadTask = ref.putFile(
        _file!,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      uploadTask.snapshotEvents.listen((snap) {
        final total = snap.totalBytes;
        final sent = snap.bytesTransferred;
        if (total > 0) {
          setState(() => _progress = sent / total);
        }
      });

      await uploadTask;

      // pobranie URL do zdjęcia
      final url = await ref.getDownloadURL();

      // zapisanie URL w Firestore (users/{uid})
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'photoUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Zapisano nowe zdjęcie')));

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Błąd uploadu: $e')));
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Zmień zdjęcie')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // podglad
            Container(
              height: 180,
              width: 180,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: _file == null
                  ? Icon(Icons.person, size: 64, color: cs.onSurface)
                  : Image.file(_file!, fit: BoxFit.cover),
            ),
            const SizedBox(height: 24),

            // z galerii
            SizedBox(
              width: double.infinity,
              child: _GrayButton(
                title: 'WYBIERZ Z GALERII',
                icon: Icons.photo_library,
                onTap: _uploading ? null : _pickFromGallery,
              ),
            ),

            const SizedBox(height: 18),

            if (_uploading) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 10),
              Text(
                'Wysyłanie: ${(_progress * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],

            const Spacer(),

            _PrimaryButton(
              title: _uploading ? 'WYSYŁANIE...' : 'ZAPISZ',
              icon: Icons.cloud_upload,
              onTap: _uploading ? null : _upload,
            ),
          ],
        ),
      ),
    );
  }
}

class _GrayButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const _GrayButton({
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: cs.onSurface),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
