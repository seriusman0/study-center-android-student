/// Reusable UI components implementing the UI/UX Improvement Specification.
///
/// - [AppCard]              — standard 12-radius bordered surface.
/// - [AppPrimaryButton]     — Deep Teal CTA, full-width, 48px tall.
/// - [AppDangerButton]      — Red outlined destructive action.
/// - [AppChecklistTile]     — Standardized 48px-tall checkbox row.
/// - [AppUploadBox]         — Dashed-border tappable upload area.
/// - [AppEmptyState]        — Icon + headline + subtext + optional CTA.
/// - [AppSectionCard]       — Grouped card with title + divider rows.
/// - [AppInfoTile]          — Profile/account detail row with icon.
library;

import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Lightweight dashed-rectangle painter used by [AppUploadBox].
class _DashedBorderPainter extends CustomPainter {
  final double radius;
  final double strokeWidth;
  final Color color;
  final double dashLength;
  final double gapLength;
  _DashedBorderPainter({
    required this.radius,
    required this.strokeWidth,
    required this.color,
    this.dashLength = 8,
    this.gapLength = 6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final m in metrics) {
      double distance = 0;
      while (distance < m.length) {
        final next = (distance + dashLength).clamp(0, m.length);
        canvas.drawPath(m.extractPath(distance, next.toDouble()), paint);
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius || old.strokeWidth != strokeWidth;
}

// ─── AppCard ─────────────────────────────────────────────────────────────────
/// Standard surface card with subtle border + soft shadow.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadow.low,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: card,
      ),
    );
  }
}

// ─── AppPrimaryButton ────────────────────────────────────────────────────────
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final bool fullWidth;
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
          )
        : Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 48,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          elevation: 0,
        ),
        child: child,
      ),
    );
  }
}

// ─── AppDangerButton ─────────────────────────────────────────────────────────
class AppDangerButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool fullWidth;
  const AppDangerButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.logout, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(color: AppColors.danger, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
    );
  }
}

// ─── AppChecklistTile ────────────────────────────────────────────────────────
/// Standardized checklist tile per spec:
/// - 48px min height
/// - Checkbox on the left, label and optional sublabel on the right
/// - Tap target covers entire row
class AppChecklistTile extends StatelessWidget {
  final String label;
  final String? sublabel;
  final IconData? leadingIcon;
  final bool checked;
  final bool enabled;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onTap;

  const AppChecklistTile({
    super.key,
    required this.label,
    this.sublabel,
    this.leadingIcon,
    this.checked = false,
    this.enabled = true,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = !enabled;
    return Semantics(
      label: label,
      button: true,
      onTap: disabled ? null : (onChanged != null || onTap != null ? () {} : null),
      child: InkWell(
        onTap: disabled
            ? null
            : () {
                if (onChanged != null) onChanged!(!checked);
                onTap?.call();
              },
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          child: Row(
            children: [
              Checkbox(
                value: checked,
                onChanged: disabled ? null : (v) {
                  if (v == null) return;
                  onChanged?.call(v);
                  onTap?.call();
                },
              ),
              const SizedBox(width: AppSpacing.xs),
              if (leadingIcon != null) ...[
                Icon(leadingIcon,
                    size: 18,
                    color: disabled
                        ? AppColors.textMuted
                        : (checked ? AppColors.primary : AppColors.textSecondary)),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: disabled ? AppColors.textMuted : AppColors.textPrimary,
                      ),
                    ),
                    if (sublabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        sublabel!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── AppUploadBox ────────────────────────────────────────────────────────────
/// Dashed-border tappable upload area.
class AppUploadBox extends StatelessWidget {
  final String mainText;
  final String? helperText;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? preview;
  final VoidCallback? onRemove;

  const AppUploadBox({
    super.key,
    this.mainText = 'Ketuk untuk unggah foto',
    this.helperText = 'Format JPG/PNG, maks. 5MB',
    this.icon = Icons.camera_alt_outlined,
    this.onTap,
    this.preview,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (preview != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: preview!,
          ),
          if (onRemove != null)
            Positioned(
              top: AppSpacing.xs,
              right: AppSpacing.xs,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  onPressed: onRemove,
                  tooltip: 'Hapus foto',
                ),
              ),
            ),
        ],
      );
    }

    return CustomPaint(
      painter: _DashedBorderPainter(
        radius: AppRadius.card,
        strokeWidth: 2,
        color: AppColors.borderStrong,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.xs),
              Text(
                mainText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              if (helperText != null) ...[
                const SizedBox(height: 4),
                Text(
                  helperText!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── AppEmptyState ───────────────────────────────────────────────────────────
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String headline;
  final String? subtext;
  final String? ctaLabel;
  final IconData? ctaIcon;
  final VoidCallback? onCta;

  const AppEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.headline,
    this.subtext,
    this.ctaLabel,
    this.ctaIcon,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              headline,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtext != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtext!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (ctaLabel != null && onCta != null) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: 220,
                child: AppPrimaryButton(
                  label: ctaLabel!,
                  icon: ctaIcon,
                  onPressed: onCta,
                  fullWidth: true,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── AppSectionCard ──────────────────────────────────────────────────────────
/// Card that groups related items: title header + body of divider-separated
/// rows. Use for grouped checklists (e.g. "Sidang-Sidang Gereja").
class AppSectionCard extends StatelessWidget {
  final String title;
  final Widget headerLeading;
  final List<Widget> rows;
  final EdgeInsetsGeometry? padding;

  const AppSectionCard({
    super.key,
    required this.title,
    this.headerLeading = const SizedBox.shrink(),
    required this.rows,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (headerLeading is! SizedBox) ...[
                headerLeading,
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ..._withDividers(rows),
        ],
      ),
    );
  }

  List<Widget> _withDividers(List<Widget> items) {
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        out.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 2),
          child: Divider(height: 1, color: AppColors.divider),
        ));
      }
      out.add(items[i]);
    }
    return out;
  }
}

// ─── AppInfoTile ─────────────────────────────────────────────────────────────
class AppInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  const AppInfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: AppColors.textSecondary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Lightweight skeleton shimmer used while data is loading.
/// Shows a subtle grey bar — no external dependency (no shimmer package).
class AppSkeletonLine extends StatelessWidget {
  final double height;
  final double widthRatio;
  const AppSkeletonLine({super.key, this.height = 14, this.widthRatio = 0.6});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) => Container(
        width: c.maxWidth * widthRatio,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    );
  }
}

class AppSkeletonTile extends StatelessWidget {
  const AppSkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          SizedBox(
            width: 24, height: 24,
            child: CircleSizer(),
          ),
          SizedBox(width: 12),
          Expanded(child: AppSkeletonLine(height: 14, widthRatio: 0.55)),
        ],
      ),
    );
  }
}

class CircleSizer extends StatelessWidget {
  const CircleSizer({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(
        color: AppColors.border,
        shape: BoxShape.circle,
      ),
    );
  }
}