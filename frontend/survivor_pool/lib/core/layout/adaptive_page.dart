import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:survivor_pool/core/constants/layout.dart';

class AdaptivePage extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets compactPadding;
  final EdgeInsets widePadding;

  const AdaptivePage({
    super.key,
    required this.child,
    this.maxWidth = 1100,
    this.compactPadding = const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 24,
    ),
    this.widePadding = const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppBreakpoints.medium;
    final padding = isWide ? widePadding : compactPadding;
    final wrapped = Padding(padding: padding, child: child);
    if (!isWide) {
      return wrapped;
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: wrapped,
      ),
    );
  }
}

class PlatformRefresh extends StatelessWidget {
  final Widget child;
  final Future<void> Function()? onRefresh;

  const PlatformRefresh({super.key, required this.child, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || onRefresh == null) {
      return child;
    }
    return RefreshIndicator(onRefresh: onRefresh!, child: child);
  }
}
