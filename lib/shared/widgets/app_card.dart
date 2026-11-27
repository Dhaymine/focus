import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.gradient,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppTheme.radius);

    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = InkWell(onTap: onTap, borderRadius: radius, child: content);
    }

    return Container(
      decoration: BoxDecoration(
        color: gradient == null ? scheme.surface : null,
        gradient: gradient,
        borderRadius: radius,
        border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );
  }
}
