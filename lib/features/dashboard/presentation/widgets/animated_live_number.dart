import 'package:flutter/material.dart';

/// A numeric text widget that animates whenever [value] changes.
///
/// **Live mode** ([isLive] == true, value changed from WebSocket):
///   • Scales the number up (×1.18) then back to ×1.0 over ~400 ms.
///   • Flashes a subtle background highlight for ~300 ms.
///   • Runs a smooth counter roll between the old and new value.
///
/// **REST/refresh mode** ([isLive] == false, value changed from a REST reload):
///   • Only the counter roll animation plays — no scale or flash.
///
/// **First render** — no animation at all, regardless of [isLive].
///
/// Usage:
/// ```dart
/// AnimatedLiveNumber(
///   value: summary.moving,
///   style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
///   isLive: liveFleet.hasLiveData,
///   flashColor: AppColors.statusMoving,
/// )
/// ```
class AnimatedLiveNumber extends StatefulWidget {
  const AnimatedLiveNumber({
    super.key,
    required this.value,
    required this.style,
    this.isLive = false,
    this.flashColor,
    this.duration = const Duration(milliseconds: 450),
  });

  final int value;
  final TextStyle style;

  /// Set to true when the value is driven by WebSocket to enable
  /// scale + flash animations in addition to the counter roll.
  final bool isLive;

  /// Accent colour for the flash overlay.  Defaults to a white-ish tint.
  final Color? flashColor;

  /// Duration of the counter roll animation.
  final Duration duration;

  @override
  State<AnimatedLiveNumber> createState() => _AnimatedLiveNumberState();
}

class _AnimatedLiveNumberState extends State<AnimatedLiveNumber>
    with SingleTickerProviderStateMixin {
  late int _prev;

  /// True only before the first value change — suppresses all animation.
  bool _isFirstRender = true;
  bool _showFlash = false;

  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _prev = widget.value;

    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Quick pop-up then settle back
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.18)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.18, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 65,
      ),
    ]).animate(_scaleCtrl);
  }

  @override
  void didUpdateWidget(AnimatedLiveNumber old) {
    super.didUpdateWidget(old);

    if (old.value != widget.value) {
      if (!_isFirstRender && widget.isLive) {
        // Socket-driven update: pop + flash
        _scaleCtrl.forward(from: 0);
        if (mounted) setState(() => _showFlash = true);
        Future.delayed(const Duration(milliseconds: 320), () {
          if (mounted) setState(() => _showFlash = false);
        });
      }
      _prev = old.value;
      _isFirstRender = false;
    }
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveFlash =
        (widget.flashColor ?? Colors.white).withValues(alpha: 0.15);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Flash overlay
        if (_showFlash)
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _showFlash ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 150),
              child: Container(
                decoration: BoxDecoration(
                  color: effectiveFlash,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),

        // Number with optional scale pop
        ScaleTransition(
          scale: _scaleAnim,
          child: TweenAnimationBuilder<double>(
            key: ValueKey(widget.value),
            tween: Tween<double>(
              begin: _prev.toDouble(),
              end: widget.value.toDouble(),
            ),
            duration: widget.duration,
            curve: Curves.easeOut,
            builder: (_, v, __) =>
                Text('${v.round()}', style: widget.style),
          ),
        ),
      ],
    );
  }
}
