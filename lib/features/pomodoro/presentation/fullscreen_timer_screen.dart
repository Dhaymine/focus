import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/generated/app_localizations.dart';
import '../data/timer_controller.dart';
import '../domain/timer_snapshot.dart';
import 'timer_view.dart';

class FullscreenTimerScreen extends ConsumerStatefulWidget {
  const FullscreenTimerScreen({super.key});

  @override
  ConsumerState<FullscreenTimerScreen> createState() =>
      _FullscreenTimerScreenState();
}

class _FullscreenTimerScreenState extends ConsumerState<FullscreenTimerScreen> {
  bool get _mobile => Platform.isAndroid || Platform.isIOS;

  @override
  void initState() {
    super.initState();
    if (_mobile) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void dispose() {
    if (_mobile) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final snap = ref.watch(timerControllerProvider);
    final ctl = ref.read(timerControllerProvider.notifier);

    final Widget action;
    switch (snap.status) {
      case TimerStatus.idle:
        action = FilledButton.icon(
          onPressed: ctl.start,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(l10n.actionStart),
        );
      case TimerStatus.running:
        action = FilledButton.icon(
          onPressed: ctl.pause,
          icon: const Icon(Icons.pause_rounded),
          label: Text(l10n.actionPause),
        );
      case TimerStatus.paused:
        action = FilledButton.icon(
          onPressed: ctl.resume,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(snap.awaitingNext
              ? l10n.actionStartNext
              : l10n.actionResume),
        );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const Positioned.fill(child: LiveTimerView(borderRadius: 0)),
          SafeArea(
            child: Align(
              alignment: AlignmentDirectional.topEnd,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: action,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
