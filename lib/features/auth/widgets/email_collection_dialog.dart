import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../repositories/auth_repository.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/theme/app_theme.dart';

class EmailCollectionDialog extends ConsumerStatefulWidget {
  final int userId;
  final bool hasCollected;
  final bool isInvited;
  
  const EmailCollectionDialog({
    super.key, 
    required this.userId, 
    required this.hasCollected,
    required this.isInvited,
  });

  @override
  ConsumerState<EmailCollectionDialog> createState() => _EmailCollectionDialogState();


  static Future<void> checkAndShow(BuildContext context, WidgetRef ref, int userId) async {
    final storage = ref.read(storageServiceProvider);
    if (await storage.hasDismissedRating(userId)) return;
    
    // Check local cache first, but we should also check the server 
    // to be completely sure.
    bool hasCollectedLocally = await storage.hasCollectedEmail(userId);
    bool hasCollectedOnServer = false;
    bool isInvited = false;
    
    try {
      final status = await ref.read(authRepositoryProvider).checkEmailStatus();
      hasCollectedOnServer = status['has_submitted'] == true;
      isInvited = status['is_invited'] == true;
    } catch (e) {
      debugPrint('Error checking email status from server: $e');
    }
    
    final bool hasCollected = hasCollectedLocally || hasCollectedOnServer;
    
    if (hasCollectedOnServer && !hasCollectedLocally) {
      await storage.setCollectedEmail(userId); // update local cache
    }

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => EmailCollectionDialog(
          userId: userId, 
          hasCollected: hasCollected,
          isInvited: isInvited,
        ),
      );
    }
  }
}

class _EmailCollectionDialogState extends ConsumerState<EmailCollectionDialog> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Format email tidak valid.');
      return;
    }
    if (phone.isEmpty) {
      setState(() => _error = 'Nomor telepon tidak boleh kosong.');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).submitEmail(email, phone);
      await ref.read(storageServiceProvider).setCollectedEmail(widget.userId);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil disimpan. Terima kasih!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = extractErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openPlayStore() async {
    final url = Uri.parse('https://play.google.com/store/apps/details?id=com.studycenter.sc_student');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka Google Play Store.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hasCollected) {
      if (widget.isInvited) {
        // PLAY STORE MODAL
        return AlertDialog(
          title: const Text('Beri Rating Aplikasi'),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Terima kasih telah berpartisipasi! Dukung kami dengan memberikan rating dan ulasan di Google Play Store.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          
          actions: [
            TextButton(
              onPressed: () {
                ref.read(storageServiceProvider).setDismissedRating(widget.userId);
                Navigator.of(context).pop();
              },
              child: const Text('Nanti', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(storageServiceProvider).setDismissedRating(widget.userId);
                Navigator.of(context).pop();
                _openPlayStore();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Buka Play Store'),
            ),
          ],

        );
      } else {
        // WAITING FOR INVITE MODAL
        return AlertDialog(
          title: const Text('Status Undangan'),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Terima kasih! Kontak Anda sudah kami terima. Harap tunggu admin memverifikasi dan mengirimkan undangan/link resmi kepada Anda.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          
          actions: [
            ElevatedButton(
              onPressed: () {
                ref.read(storageServiceProvider).setDismissedRating(widget.userId);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tutup'),
            ),
          ],

        );
      }
    }

    // EMAIL COLLECTION MODAL
    return AlertDialog(
      title: const Text('Tinggalkan Kontak Anda'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bantu kami mengembangkan Study Center! Masukkan email dan nomor HP Anda untuk mendapatkan undangan aplikasi versi terbaru atau link resmi Google Play Store.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Anda',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Nomor HP',
                errorText: _error,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: CircularProgressIndicator(),
          )
        else ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Nanti Saja', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan'),
          ),
        ]
      ],
    );
  }
}

