import 'package:flutter/material.dart';

/// A Dialog that animates its child when it changes, fading out the old one and
/// fading in the new one. It also animates the size change, if the new child has a
/// different size than the old one.
///
/// The [child] MUST have a [Key] that changes when the content changes, otherwise the
/// animation won't run and it will not reflect the new content.
class AppAnimatedDialog extends StatefulWidget {
  const AppAnimatedDialog({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AppAnimatedDialog> createState() => _AppAnimatedDialogState();
}

class _AppAnimatedDialogState extends State<AppAnimatedDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  Widget? _currentChild;

  @override
  void initState() {
    super.initState();

    _currentChild = widget.child;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant AppAnimatedDialog oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.child.key != _currentChild?.key) {
      _runTransition();
    } else {
      _currentChild = widget.child;
    }
  }

  Future<void> _runTransition() async {
    await _controller.reverse();

    if (!mounted) return;

    setState(() {
      _currentChild = widget.child;
    });

    await _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 512,
          maxHeight: 348,
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: FadeTransition(
            opacity: _fade,
            child: RepaintBoundary(
              child: _currentChild,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
