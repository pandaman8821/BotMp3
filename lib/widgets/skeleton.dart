import 'package:flutter/material.dart';

import '../core/motion.dart';
import '../core/theme.dart';

/// Bloque gris que late: se usa mientras carga la biblioteca.
class SkeletonBloque extends StatefulWidget {
  const SkeletonBloque({
    super.key,
    this.ancho,
    this.alto = 14,
    this.radio = 8,
  });

  final double? ancho;
  final double alto;
  final double radio;

  @override
  State<SkeletonBloque> createState() => _SkeletonBloqueState();
}

class _SkeletonBloqueState extends State<SkeletonBloque>
    with SingleTickerProviderStateMixin {
  late final AnimationController _control = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _control,
      builder: (BuildContext context, Widget? child) {
        final double opacidad = 0.18 + (_control.value * 0.22);
        return Container(
          width: widget.ancho,
          height: widget.alto,
          decoration: BoxDecoration(
            color: AppColors.darkTextDim.withAlpha((opacidad * 255).round()),
            borderRadius: BorderRadius.circular(widget.radio),
          ),
        );
      },
    );
  }
}

/// Lista de filas fantasma, para no enseñar un spinner vacio.
class ListaSkeleton extends StatelessWidget {
  const ListaSkeleton({super.key, this.filas = 8});

  final int filas;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: filas,
      itemBuilder: (BuildContext context, int i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: <Widget>[
            const SkeletonBloque(ancho: 46, alto: 46, radio: 12),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SkeletonBloque(ancho: 160 + ((i % 3) * 40), alto: 12),
                  const SizedBox(height: 7),
                  const SkeletonBloque(ancho: 100, alto: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de carga para reproductor/miniaturas.
class SkeletonTarjeta extends StatelessWidget {
  const SkeletonTarjeta({super.key, this.alto = 180, this.radio = 20});

  final double alto;
  final double radio;

  @override
  Widget build(BuildContext context) {
    return SkeletonBloque(ancho: double.infinity, alto: alto, radio: radio);
  }
}

/// Fuente unica de duraciones para que el skeleton respete el ajuste.
Duration skeletonDuracion() => Motion.ajustar(const Duration(milliseconds: 900));