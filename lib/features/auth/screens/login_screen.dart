import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (ref.read(authProvider).error != null) {
        ref.read(authProvider.notifier).clearError();
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

  void _toggleObscure() {
    setState(() => _obscure = !_obscure);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const _LoginAppBar(),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F766E), Color(0xFF0D9488)], // teal-700 to teal-600
            ),
          ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: _LoginFormCard(
                emailCtrl: _emailCtrl,
                passCtrl: _passCtrl,
                obscure: _obscure,
                onToggleObscure: _toggleObscure,
                onSubmit: _submit,
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}

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
            style: TextStyle(fontWeight: FontWeight.normal, color: Colors.white.withOpacity(0.8), fontSize: 14),
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
  });

  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authProvider);

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          const _GoogleLoginButton(),
          const SizedBox(height: 24),
          const _DividerAtau(),
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
          const SizedBox(height: 16),
          const _RememberMeCheckbox(),
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

class _GoogleLoginButton extends StatelessWidget {
  const _GoogleLoginButton();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      onPressed: () {},
      // A remote-hosted logo means the button silently shows an ugly
      // "HTTP request failed" accessibility text (and no icon) whenever the
      // network is slow/blocked/offline. Use the Material "G" glyph instead
      // — no network dependency, always renders.
      icon: const Icon(Icons.g_mobiledata, size: 28, color: Color(0xFF4285F4)),
      label: const Text('Masuk dengan Google', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
    );
  }
}

class _DividerAtau extends StatelessWidget {
  const _DividerAtau();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('atau', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ),
        const Expanded(child: Divider()),
      ],
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

class _RememberMeCheckbox extends StatelessWidget {
  const _RememberMeCheckbox();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: false,
            onChanged: (val) {},
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 8),
        Text('Ingat saya', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
      ],
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
