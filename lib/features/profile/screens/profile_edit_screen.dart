import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Local provider for edit state
// ---------------------------------------------------------------------------
class _EditState {
  final bool loading;
  final String? error;
  final bool saved;

  const _EditState({this.loading = false, this.error, this.saved = false});

  _EditState copyWith({bool? loading, String? error, bool? saved}) =>
      _EditState(
        loading: loading ?? this.loading,
        error:   error,
        saved:   saved ?? this.saved,
      );
}

class _EditNotifier extends AutoDisposeNotifier<_EditState> {
  @override
  _EditState build() => const _EditState();

  Future<bool> save({
    required String name,
    String? password,
  }) async {
    state = const _EditState(loading: true);
    try {
      final dio = ref.read(dioProvider);
      final body = <String, dynamic>{
        'name': name,
        if (password != null && password.isNotEmpty) 'password': password,
      };
      final res = await dio.put(ApiConstants.profile, data: body);
      final data = res.data as Map<String, dynamic>;
      final userJson = (data['user'] ?? data) as Map<String, dynamic>;
      final updatedUser = UserModel.fromJson(userJson);
      // Update the auth state with new user data
      ref.read(authProvider.notifier).setUser(updatedUser);
      state = const _EditState(saved: true);
      return true;
    } catch (e) {
      state = _EditState(error: extractErrorMessage(e));
      return false;
    }
  }
}

final _editProvider =
    NotifierProvider.autoDispose<_EditNotifier, _EditState>(_EditNotifier.new);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey  = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  final _passCtrl = TextEditingController();
  bool _obscure   = true;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final ok = await ref.read(_editProvider.notifier).save(
          name:     _nameCtrl.text.trim(),
          password: _passCtrl.text.isEmpty ? null : _passCtrl.text,
        );

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_editProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(state.error!,
                        style: const TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nama tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password Baru (opsional)',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v != null && v.isNotEmpty && v.length < 8) {
                      return 'Password minimal 8 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Kosongkan jika tidak ingin mengubah password.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey[500]),
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: state.loading ? null : _submit,
                  child: state.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Simpan Perubahan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
