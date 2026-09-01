import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _showManualLogin = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final auth = ref.read(authProvider);
      if (auth.error != null) {
        ref.read(authProvider.notifier).clearError();
      }
      // If a previous session expired, pre-fill the email so user only needs password
      if (auth.expiredEmail != null) {
        _emailCtrl.text = auth.expiredEmail!;
        _showManualLogin = true;
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await ref.read(authProvider.notifier).login(
          _emailCtrl.text.trim(),
          _passCtrl.text,
        );
    if (mounted && ref.read(authProvider).isAuthenticated) {
      context.go('/home');
    }
  }

  Future<void> _quickLogin(SavedProfile profile) async {
    await ref.read(authProvider.notifier).loginWithProfile(profile);
    if (mounted && ref.read(authProvider).isAuthenticated) {
      context.go('/home');
    }
    // If login failed (token expired), the error is shown in the manual
    // form and the profile is already removed from the list.
    if (mounted && !ref.read(authProvider).isAuthenticated) {
      setState(() => _showManualLogin = true);
      // Pre-fill the email so the user doesn't have to type it again.
      _emailCtrl.text = profile.email;
    }
  }

  void _toggleObscure() {
    setState(() => _obscure = !_obscure);
  }

  @override
  Widget build(BuildContext context) {
    final savedProfiles = ref.watch(savedProfilesProvider);

    return Scaffold(
      appBar: const _LoginAppBar(),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                child: savedProfiles.when(
                  data: (profiles) {
                    if (profiles.isNotEmpty && !_showManualLogin) {
                      return _SavedProfilesCard(
                        profiles: profiles,
                        onProfileTap: _quickLogin,
                        onUseOtherAccount: () {
                          setState(() => _showManualLogin = true);
                        },
                        onRemoveProfile: (userId) async {
                          await ref
                              .read(storageServiceProvider)
                              .removeSavedProfile(userId);
                          ref.invalidate(savedProfilesProvider);
                        },
                      );
                    }
                    return _LoginFormCard(
                      emailCtrl: _emailCtrl,
                      passCtrl: _passCtrl,
                      obscure: _obscure,
                      onToggleObscure: _toggleObscure,
                      onSubmit: _submit,
                      showBackToProfiles: profiles.isNotEmpty,
                      onBackToProfiles: () {
                        setState(() => _showManualLogin = false);
                      },
                    );
                  },
                  loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.white)),
                  error: (_, __) => _LoginFormCard(
                    emailCtrl: _emailCtrl,
                    passCtrl: _passCtrl,
                    obscure: _obscure,
                    onToggleObscure: _toggleObscure,
                    onSubmit: _submit,
                    showBackToProfiles: false,
                    onBackToProfiles: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Saved Profiles Card (quick-switch UI)
// ──────────────────────────────────────────────────────────────────────────────

class _SavedProfilesCard extends StatelessWidget {
  final List<SavedProfile> profiles;
  final Future<void> Function(SavedProfile) onProfileTap;
  final VoidCallback onUseOtherAccount;
  final Future<void> Function(int userId) onRemoveProfile;

  const _SavedProfilesCard({
    required this.profiles,
    required this.onProfileTap,
    required this.onUseOtherAccount,
    required this.onRemoveProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pilih Akun',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ketuk untuk langsung masuk',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(height: 20),
          ...profiles.map((p) => _ProfileTile(
                profile: p,
                onTap: () => onProfileTap(p),
                onRemove: () => onRemoveProfile(p.userId),
              )),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onUseOtherAccount,
            icon: const Icon(Icons.person_add_outlined, size: 20),
            label: const Text('Gunakan akun lain'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final SavedProfile profile;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ProfileTile({
    required this.profile,
    required this.onTap,
    required this.onRemove,
  });

  String _roleLabel(String role) {
    switch (role) {
      case 'admin': return 'Admin';
      case 'mentor': return 'Mentor';
      case 'fulltimer': return 'Fulltimer';
      case 'student': return 'Siswa';
      case 'scholarship_teenager': return 'Beasiswa Remaja';
      case 'college': return 'Mahasiswa';
      case 'guest': return 'Tamu';
      default: return role;
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin': return const Color(0xFFDC2626);
      case 'mentor': return const Color(0xFF7C3AED);
      case 'fulltimer': return const Color(0xFF0891B2);
      case 'student': return const Color(0xFF059669);
      case 'scholarship_teenager': return const Color(0xFFD97706);
      case 'college': return const Color(0xFF2563EB);
      case 'guest': return const Color(0xFF6B7280);
      default: return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _roleColor(profile.primaryRole);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withValues(alpha: 0.15),
                  backgroundImage: profile.avatar != null
                      ? NetworkImage(profile.avatar!)
                      : null,
                  child: profile.avatar == null
                      ? Text(
                          profile.name.isNotEmpty
                              ? profile.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.name,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _roleLabel(profile.primaryRole),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: color,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              profile.email,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[500]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                  onPressed: onRemove,
                  tooltip: 'Hapus dari daftar',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Original Login Form Card (manual email/password)
// ──────────────────────────────────────────────────────────────────────────────

class _LoginAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _LoginAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Study Center ',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE0C020), fontSize: 18),
          ),
          Text(
            'Nias',
            style: TextStyle(fontWeight: FontWeight.normal, color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {},
          child: const Text('Masuk', style: TextStyle(color: Colors.white)),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0, top: 8, bottom: 8),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size(0, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onPressed: () => context.go('/register'),
            child: const Text('Daftar'),
          ),
        ),
      ],
    );
  }
}

class _LoginFormCard extends ConsumerWidget {
  const _LoginFormCard({
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.showBackToProfiles,
    required this.onBackToProfiles,
  });

  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final bool showBackToProfiles;
  final VoidCallback onBackToProfiles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authProvider);

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showBackToProfiles)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onBackToProfiles,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Kembali ke daftar akun'),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
            ),
          Text(
            'Masuk',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Masuk ke akun Study Center Nias',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          if (state.error != null) _ErrorBox(error: state.error!),
          const Text('Email atau Username', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Semantics(
            identifier: 'emailField',
            textField: true,
            child: TextField(
              key: const Key('emailField'),
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'email@contoh.com / username'),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Semantics(
            identifier: 'passwordField',
            textField: true,
            child: TextField(
              key: const Key('passwordField'),
              controller: passCtrl,
              obscureText: obscure,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'Masukkan password',
                suffixIcon: IconButton(
                  icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: onToggleObscure,
                ),
              ),
              onSubmitted: (_) => onSubmit(),
            ),
          ),
          const SizedBox(height: 24),
          Semantics(
            identifier: 'loginBtn',
            button: true,
            child: ElevatedButton(
              onPressed: state.loading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: state.loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Login Sekarang', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 24),
          const _DaftarLink(),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(
          error,
          style: const TextStyle(color: Colors.red),
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _DaftarLink extends StatelessWidget {
  const _DaftarLink();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Belum punya akun? ',
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
        GestureDetector(
          onTap: () => context.go('/register'),
          child: Text(
            'Daftar',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
