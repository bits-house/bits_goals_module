import 'package:flutter/material.dart';

class AppSnackBar {
  const AppSnackBar._();

  static SnackBar build({
    required BuildContext context,
    required Widget content,
    Duration duration = const Duration(seconds: 15),
  }) {
    return SnackBar(
      showCloseIcon: true,
      duration: duration,
      backgroundColor: Theme.of(context).colorScheme.primary,
      content: _SnackBarContent(
        content: content,
        duration: duration,
      ),
    );
  }
}

class _SnackBarContent extends StatefulWidget {
  const _SnackBarContent({
    required this.content,
    required this.duration,
  });

  final Widget content;
  final Duration duration;

  @override
  State<_SnackBarContent> createState() => _SnackBarContentState();
}

class _SnackBarContentState extends State<_SnackBarContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.content,
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            return LinearProgressIndicator(
              value: 1 - _controller.value,
              backgroundColor: theme.colorScheme.onPrimary,
            );
          },
        ),
      ],
    );
  }
}
