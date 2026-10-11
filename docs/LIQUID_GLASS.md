# 🧊 Liquid Glass en BotMp3 — catálogo de funciones y viabilidad real en Android

«Liquid Glass» es el lenguaje visual de Apple (iOS 26/27): un material translúcido que
**desenfoca, refracta y colorea** lo que tiene detrás, con brillos especulares que
reaccionan a la luz y al movimiento, y con formas que se deforman con física de muelle.

Este documento lista **todas las funciones del Liquid Glass**, si se pueden replicar en
una APK Android, con qué técnica, y **dónde encajaría cada una en BotMp3**.

> Conclusión rápida: **la gran mayoría se puede replicar** en Android con Flutter
> (blur real + shader GLSL de refracción + física de muelles). Lo que **no** se puede es
> el cristal del *sistema* (notificación, pantalla de bloqueo, ver el escritorio a través
> de la app), porque Android no expone esa composición a las apps.

---

## 1. Las piezas del material (y su viabilidad)

| # | Función del Liquid Glass | ¿En APK Android? | Cómo se implementa | Coste GPU |
|---|---|---|---|---|
| 1 | **Desenfoque del fondo en tiempo real** | ✅ Sí | `BackdropFilter` + `ImageFilter.blur` (Skia e Impeller) | Medio |
| 2 | **Refracción tipo lente en los bordes** (el fondo se curva) | ✅ Sí | Shader GLSL aplicado como filtro: `ImageFilter.shader` sobre `BackdropFilterLayer` | Alto (Vulkan/Metal pleno; GLES con AST reducido) |
| 3 | **Aberración cromática** (franjas de color en el borde) | ✅ Sí en Vulkan/Metal · ⚠️ aproximada en GLES/Web | Mismo shader, muestreo por canal con desplazamiento | Alto |
| 4 | **Brillo especular / luz de borde (Fresnel)** | ✅ Sí | Gradiente + `CustomPainter` (barato) | Bajo |
| 5 | **Sombra interior y bisel** | ✅ Sí | `CustomPainter` con `BoxShadow` invertido / `BlendMode` | Bajo |
| 6 | **Tinte adaptativo (vibrancy)**: el color de detrás tiñe el cristal | ✅ Sí, y **mejorado** | Shader leyendo la luminancia del fondo, o —en BotMp3— **la paleta de la carátula** (`palette_generator`) | Medio |
| 7 | **Grano/ruido sutil** | ✅ Sí | Textura de ruido en `BlendMode.overlay` con opacidad ~3 % | Bajo |
| 8 | **Brillo que reacciona al giroscopio** | ✅ Sí | `sensors_plus` + un `Stream<double>` que mueve el ángulo especular | Bajo (pero consume batería si es continuo) |
| 9 | **Brillo que reacciona al scroll y al tacto** | ✅ Sí | Posición del dedo / offset de scroll → ángulo del gradiente | Bajo |
| 10 | **Material claro y oscuro diferenciados** | ✅ Sí | Dos variantes de tema (más opaco en oscuro, más translúcido en claro) | Bajo |
| 11 | **Ajuste automático de fuerza según el fondo** (más opaco sobre colores claros) | ✅ Sí | Luminancia del backdrop → factor 0,8–1,2 | Bajo |
| 12 | **Morphing líquido** (el botón se convierte en panel/menú) | ✅ Sí | Física propia (`SpringSimulation`) + `CustomPainter`/shader | Medio |
| 13 | **Muelles elásticos y rebote** | ✅ Sí | `SpringSimulation`, `flutter_animate`, `CupertinoMotion` | Bajo |
| 14 | **Rubber banding** (la barra se estira al arrastrar) | ✅ Sí | Listener + `Transform.scale` con muelle | Bajo |
| 15 | **Efecto gelatina (jelly)** en el indicador de pestaña | ✅ Sí | Muelle de 2 fases + escalado | Bajo |
| 16 | **Fusión gooey de formas** (gotas que se unen) | ✅ Sí | Blur + aumento de contraste sobre el canal alfa, o shader | Medio |
| 17 | **Haptics** al cambiar de pestaña / cruzar límites | ✅ Sí | `HapticFeedback` / `vibration` | Nulo |
| 18 | **Estado pulsado**: se encoge al 88 %, oscurece y vuelve con rebote | ✅ Sí | `AnimatedScale` + muelle | Bajo |
| 19 | **Barra que se minimiza al hacer scroll y se expande** | ✅ Sí | `ScrollController` + `AnimatedContainer` | Bajo |
| 20 | **Pestaña activa como lente mágica que refracta** | ✅ Sí | Máscara de recorte sobre la capa de cristal | Medio |
| 21 | **Submenús en capas** (el padre retrocede y se atenúa) | ✅ Sí | `Overlay` + escala/opacidad animadas | Bajo |
| 22 | **Precarga AOT de shaders** (sin tirones en el primer fotograma) | ✅ Sí | `initialize()` asíncrono antes de `runApp` (solo E/S de disco) | Nulo |

---

## 2. Dónde aplicarlo en BotMp3 (función por función)

Las reglas de Apple son claras: **el cristal es para la capa de navegación y control**,
el contenido (listas, tarjetas de canciones) se mantiene opaco. Aplicado a BotMp3:

| Pantalla / elemento de BotMp3 | Tratamiento | Viabilidad |
|---|---|---|
| **Barra de navegación inferior** (Canciones · Listas · Buscar · IA · Ajustes) | Barra flotante de cristal con indicador gomoso y haptics | ✅ Ideal |
| **Mini reproductor** (sobre la barra) | Panel de cristal con el progreso y `play/pausa` | ✅ Ideal |
| **AppBar** de cada pestaña | Barra flotante, brillo de iconos adaptado al contenido | ✅ |
| **Pantalla de reproducción** | Carátula a pantalla completa + **panel de controles en cristal sobre la carátula** (aquí el fondo es una imagen conocida: la refracción sale perfecta) | ✅ Ideal |
| **Botón grande de reproducir/pausar** | Botón circular de cristal con barrido iridiscente y pulsación elástica | ✅ Ideal |
| **Slider de progreso y de volumen** | Pista y pulgar de cristal con lente | ✅ |
| **Chips de órdenes de la IA** («pon cumbia», «ayuda») | Chips de cristal con brillo al pulsar | ✅ |
| **Editor de canción** (título, artista, álbum, género, tags) | Campos de cristal agrupados + selector de género en hoja de cristal | ✅ |
| **Selector de género / año / modelo de IA** | Menú desplegable de cristal con submenús en capas | ✅ |
| **Menú ⋮ de una canción** | Menú de cristal que **emerge del propio botón** (morphing) | ✅ Muy vistoso |
| **Hoja inferior de «Liberar espacio», escaneo, exportar** | `GlassModalSheet` con morph desde el botón que lo abre | ✅ |
| **Avisos** («Liberados 1,2 GB», «3 canciones nuevas») | Toast de cristal | ✅ |
| **Indicadores** (escaneando, IA pensando) | Progreso de cristal | ✅ |
| **Editor de carátulas** (brillo, contraste, filtros, texto) | Panel de cristal **sobre la carátula que estás editando** (refracción con la propia imagen) | ✅ Muy vistoso |
| **Ajustes** (listas de opciones) | Secciones agrupadas de cristal, filas opacas (según la guía) | ✅ |
| **Búsqueda global** | Barra que se transforma y se expande al enfocar | ✅ |
| **Carátulas de listas/álbumes en cuadrícula** | Cristal `minimal` para no matar el rendimiento con la refracción | ✅ |
| **Splash de arranque** | Icono sobre cristal con degradado morado de marca | ✅ |
| **Widget de pantalla de inicio** | ❌ Android usa `RemoteViews`: solo imágenes estáticas, sin blur ni refracción | ❌ |
| **Notificación y pantalla de bloqueo** | ❌ Son del sistema: la app solo puede poner la carátula como imagen (ya lo hacemos) | ❌ |
| **Ver el escritorio a través de la app** | ❌ Ninguna app Android puede leer y refractar lo que hay detrás de su ventana | ❌ |
| **Cristal sobre vídeo en vivo a 120 Hz** | ⚠️ Carísimo; exigiría reducir resolución y blur pequeño | ⚠️ No recomendado |
| **Cristal dentro de cristal** | ❌ Degrada por diseño (el cristal interior no puede refractar el exterior) | ❌ |
| **Blur dentro de `ListView` con `premium`** | ⚠️ Limitación conocida en Impeller: puede fallar en scroll | ⚠️ Usar `standard`/`minimal` |

---

## 3. Paquetes Flutter que ya lo implementan (verificados)

| Paquete | Versión | Requisitos | Qué aporta |
|---|---|---|---|
| [`liquid_glass_widgets`](https://pub.dev/packages/liquid_glass_widgets) | 1.11.1 | Flutter ≥ 3.41 · Dart ≥ 3.5 | Catálogo completo (barras, hojas, menús, chips, sliders, switches, buscador…), blur + **refracción por shader**, aberración cromática, motor de morphing, calidad adaptativa, luz por giroscopio, accesibilidad. **Compatible con nuestro Flutter 3.47.7.** |
| [`cupertino_liquid_glass`](https://pub.dev/packages/cupertino_liquid_glass) | 0.7.1 | Flutter ≥ 3.32 · Dart ≥ 3.11.3 | Aproximación sin shaders propios: `BackdropFilter`, especular, biseles, grano, barras con muelles y haptics, `BackdropGroup`, dial de intensidad y respaldo sólido (`enableGlass: false`).**Compatible con nuestro Dart 3.13.5.** |
| `fluid_glass` | — | — | Alternativa ligera del mismo estilo |
| [`palette_generator`](https://pub.dev/packages/palette_generator) | — | — | Extrae la paleta de la carátula → **tinte del cristal con el color del álbum** |
| [`sensors_plus`](https://pub.dev/packages/sensors_plus) | — | — | Giroscopio para el brillo que reacciona al mover el móvil |
| `flutter_animate` | — | — | Muelles y transiciones de entrada |

> Nota técnica: Flutter permite `ImageFilter.shader(...)` para **refractar el fondo con un
> shader propio** (GLSL vía `FragmentProgram`). Hay una limitación conocida al **mezclar
> varios `ImageFilter`** ([flutter#177133](https://github.com/flutter/flutter/issues/177133)),
> así que lo práctico es: **un** filtro de blur + **un** filtro de shader por superficie.

---

## 4. Reglas de rendimiento obligatorias (POCO X7 Pro, 120 Hz)

1. **Agrupar fondos**: envolver las superficies de cristal de una pantalla en un
   `BackdropGroup` para que compartan **una sola lectura del fondo por fotograma**
   (con 15 tarjetas de cristal, pasar de 15 lecturas a 1).
2. **No anidar** cristal dentro de cristal: cada capa extra cuesta y la interior pierde
   el efecto por diseño.
3. **Elegir calidad por elemento**: `premium` solo en superficies estáticas y focales
   (panel de reproducción, barra inferior); `standard` en barras y hojas;
   `minimal` (sin shader) en tarjetas dentro de listas.
4. **Calidad adaptativa + persistencia**: medir el dispositivo al arrancar y **guardar** la
   calidad resultante en `SharedPreferences` para no repetir el calentamiento de ~3 s en
   cada inicio (y no degradar a `minimal` en un móvil potente).
5. **Radio de blur moderado** (sigma 10–20) en scroll; subirlo solo en pantallas estáticas.
6. **Nada de blur dentro de `ListView` en calidad premium** (limitación del motor en Impeller).
7. **Respetar accesibilidad**: con «Reducir movimiento» activo, los muelles saltan al
   estado final; con «Alto contraste», el cristal pasa a panel sólido. Es automático en los
   paquetes y **necesario** para no marear ni gastar batería.
8. **Modo ahorro**: si el usuario activa «ahorro de batería» (ya existe ese ajuste en
   BotMp3), bajar a `minimal` o `enableGlass: false` → superficie sólida y sin GPU.

---

## 5. Plan de implementación sugerido para BotMp3

| Fase | Alcance | Riesgo | Impacto visual |
|---|---|---|---|
| **1. Núcleo** | `LiquidGlassWidgets.wrap()` + tema de cristal con el morado de marca (`#8D16CA`) y `Material` transparente en `builder` | Bajo | — |
| **2. Navegación** | Barra inferior flotante + AppBar + **mini reproductor** de cristal | Bajo | Alto |
| **3. Reproducción** | Panel de controles sobre la carátula + botón play iridiscente + sliders | Medio | Muy alto |
| **4. IA** | Chips de órdenes, hoja de chat, menú de comandos con morphing | Medio | Alto |
| **5. Edición** | Editor de canción y de carátula con panel de cristal sobre la imagen | Medio | Muy alto |
| **6. Detalles** | Toasts, indicadores, menús ⋮, búsqueda expandible, haptics | Bajo | Medio |
| **7. Rendimiento** | `BackdropGroup`, calidad por elemento, adaptativa persistida, respaldo sólido en ahorro | Alto (medir en el POCO) | — |

**Consejo de diseño:** el Liquid Glass es un lenguaje de Apple. En Android, Google
recomienda *Material 3 Expressive* (que también usa desenfoque y formas elásticas, pero con
su propia identidad). Puedes usar el cristal **tamizado con tu morado y tu tipografía** para
que se sienta propio y no una copia de iOS.

---

## 6. Resumen en una frase

De las ~22 piezas que forman el Liquid Glass, **20 son implementables en tu APK**
(las 2 restantes son el cristal del sistema operativo y el cristal sobre el escritorio,
imposibles desde una app), y **unas 20 funciones concretas de BotMp3** pueden adoptarlo,
con la regla de oro: **cristal en la navegación y los controles, contenido opaco**.
