import 'package:flutter/material.dart';

import '../core/motion.dart';
import '../core/theme.dart';
import '../screens/home_shell.dart';

/// Muestra el logo degradado un instante y deja paso a la app.
///
/// Es solo visual: los providers ya estan creados y la biblioteca se carga
/// igual mientras se ve la pantalla.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _listo = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Motion.ajustar(const Duration(milliseconds: 620)), () {
      if (mounted) setState(() => _listo = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.normal,
      switchInCurve: Motion.entrada,
      switchOutCurve: Motion.salida,
      child: _listo
          ? const HomeShell()
          : const _PortadaSplash(key: ValueKey<String>('splash')),
    );
  }
}

class _PortadaSplash extends StatelessWidget {
  const _PortadaSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.darkBg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (Rect r) => LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[AppColors.green, AppColors.aiCyan, AppColors.aiViolet],
              ).createShader(r),
              child: const Text(
                'BotMp3',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.6,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Icon(Icons.graphic_eq, color: AppColors.green.withAlpha(160), size: 22),
          ],
        ),
      ),
    );
  }
}