# Sistema de temas de BotMp3

## Resumen
BotMp3 tiene **8 estilos visuales** seleccionables en caliente desde
`Ajustes > Apariencia > Tema`. No hay 8 copias de las pantallas: hay **tokens**
que toda la app consume.

## Arquitectura
```
lib/core/theme/
  tokens.dart          -> BotTokens (colores, tipografia, radios, fondo, animacion, ecualizador)
  catalog.dart         -> kThemes (los 8 estilos) + themeById()
  theme_manager.dart   -> ThemeManager (estado + persistencia + notificacion en caliente)
  theme_backdrop.dart  -> fondo decorativo de cada estilo (un unico painter barato)
lib/core/theme.dart    -> fachada AppColors/AppTheme (compatibilidad con el codigo existente)
lib/widgets/theme_picker.dart -> selector con vista previa en Ajustes
```

## Flujo
1. `main()` llama a `ThemeManager.init()` (lee `tema_id` de SharedPreferences).
2. `BotMp3App` provee el `ThemeManager` con Provider y reconstruye `MaterialApp`
   cuando cambia (por eso el cambio es instantaneo, sin reiniciar).
3. `AppColors.green`, `AppColors.darkBg`, etc. ya no son constantes: son getters
   que devuelven el token del tema activo. Las pantallas no cambian.
4. `ThemeBackdrop` pinta el fondo del estilo (gradientes, neon, papel, ondas,
   lineas de velocidad, arcos goticos o barras de cine) en un solo `CustomPaint`.

## Tokens disponibles (`BotTokens`)
| Token | Uso |
|---|---|
| `primary` / `primaryDark` | acentos, botones, progreso |
| `secondary` / `accent` | IA, gradientes, detalles |
| `background` / `surface` / `surfaceHigh` / `outline` | fondos y bordes |
| `text` / `textDim` | texto principal y secundario |
| `onPrimary` | texto/iconos sobre el color primario |
| `coverColors` | degradado para caratulas sin imagen |
| `radius`, `titleWeight`, `titleSpacing`, `uppercaseTitles`, `fontFamily` | forma y tipografia |
| `backdrop`, `eqStyle`, `glow`, `motionMs`, `letterbox` | efectos, ecualizador, movimiento |
| `light` | variante clara opcional (solo minimal y glass) |

## Como anadir un tema nuevo
1. Crea un `BotTokens` en `lib/core/theme/catalog.dart` con un `id` nuevo.
2. Anadelo a `kThemes`.
3. (Opcional) Si necesita un fondo propio, agrega un valor a `BotBackdrop` y su
   `case` en `_BackdropPainter` (`theme_backdrop.dart`).
4. (Opcional) Anade su nombre traducido en `lib/l10n/app_*.arb`.
5. `flutter analyze && flutter test` -> listo. No hay que tocar ninguna pantalla.

## Accesibilidad
- Contraste verificado por test (`test/theme_test.dart`): texto >= 4.5:1 y
  texto secundario >= 3:1 en los 8 temas.
- Interruptor **Reducir movimiento**: `motionMs = 0` y el fondo queda estatico.
- Cada tarjeta del selector usa `Semantics(button, selected, label)` para TalkBack.

## Rendimiento
- Un unico `CustomPaint` de fondo, sin imagenes ni blur real.
- Las animaciones de fondo solo se activan en 3 estilos y se detienen al
  desactivar "reducir movimiento".
- Cambiar de tema no toca el reproductor: `PlayerProvider` conserva su instancia.