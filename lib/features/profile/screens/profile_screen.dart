import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/theme/design_tokens.dart';
import '../../../shared/widgets/app_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final avatarRadius = 48.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    backgroundImage: user.avatar != null
                        ? NetworkImage(user.avatar!)
                        : null,
                    child: user.avatar == null
                        ? Text(
                            user.name.isEmpty
                                ? '?'
                                : user.name[0].toUpperCase(),
                            style: TextStyle(
                              // Per spec: initial ~45% of diameter.
                              fontSize: avatarRadius * 2 * 0.45,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  if (user.avatar != null)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 1,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => context.push('/profile/edit'),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.camera_alt_outlined,
                                size: 16, color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                user.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (user.cabang != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Center(
                child: Text(
                  user.cabang!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    child: AppInfoTile(
                      icon: Icons.alternate_email,
                      label: 'Username',
                      value: user.username,
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    child: AppInfoTile(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user.email,
                    ),
                  ),
                  if (user.cabang != null) ...[
                    const Divider(height: 1, color: AppColors.divider),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      child: AppInfoTile(
                        icon: Icons.location_on_outlined,
                        label: 'Cabang',
                        value: user.cabang!,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: 'Edit Profil',
              icon: Icons.edit_outlined,
              onPressed: () => context.push('/profile/edit'),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppDangerButton(
              label: 'Keluar',
              icon: Icons.logout,
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Keluar?'),
                        content: const Text(
                            'Anda akan keluar dari akun ini. Lanjutkan?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.danger),
                            child: const Text('Keluar'),
                          ),
                        ],
                      ),
                    ) ??
                    false;
                if (!confirmed) return;
                if (!context.mounted) return;
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version ?? '...';
                final build = snapshot.data?.buildNumber ?? '';
                return Center(
                  child: Text(
                    'Versi $version ($build)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}