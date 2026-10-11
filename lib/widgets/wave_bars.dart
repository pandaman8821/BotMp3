import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Ondas sonoras animadas estilo ecualizador (identidad de BotMp3).
///
/// Si [animate] es false (modo ahorro o reproducción en pausa) se dibuja un
/// fotograma estático: cero coste de CPU y de batería.
class WaveBars extends StatefulWidget {
  const WaveBars({
    super.key,
    this.barCount = 5,
    this.height = 22,
    this.color = AppColors.green,
    this.animate = true,
    this.barWidth = 4,
    this.spacing = 3,
  });

  final int barCount;
  final double height;
  final Color color;
  final bool animate;
  final double barWidth;
  final double spacing;

  @override
  State<WaveBars> createState() => _WaveBarsState();
}

class _WaveBarsState extends State<WaveBars> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  final math.Random _random = math.Random(7);
  late final List<double> _phases =
      List<double>.generate(widget.barCount, (int i) => _random.nextDouble() * math.pi * 2);

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant WaveBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.barCount * (widget.barWidth + widget.spacing),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, _) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List<Widget>.generate(widget.barCount, (int index) {
              final double t = widget.animate ? _controller.value : 0.35;
              final double wave = (math.sin((t * math.pi * 2) + _phases[index]) + 1) / 2;
              final double factor = 0.28 + wave * 0.72;
              return Padding(
                padding: EdgeInsets.only(right: widget.spacing),
                child: Container(
                  width: widget.barWidth,
                  height: widget.height * factor,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(widget.barWidth / 2),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
