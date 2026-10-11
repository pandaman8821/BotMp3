# 🤖🎵 BotMp3 — reproductor de música con agente IA multimodelo

**BotMp3** es una app Flutter (Android/iOS) que combina un **reproductor local completo**
(MP3, M4A, OGG, FLAC, WAV), **gestión ilimitada de listas**, **editor de carátulas integrado** y un
**agente musical IA** que funciona con **OpenAI, DeepSeek, Gemini y Claude**.

Versión **1.1.0**, tema oscuro estilo Spotify, modo offline total y optimizada para el
**POCO X7 Pro** (6,67", 1220×2712, 120 Hz AMOLED, 5000+ mAh).

![Icono de BotMp3](assets/icon/botmp3_icon.png)

---

## ✅ Estado de la entrega

| Elemento | Estado |
|---|---|
| **APK firmada lista para instalar** | ✅ **`BotMp3-1.5.0-release.apk` · 28,9 MB · arm64-v8a** |
| Código completo del proyecto Flutter | ✅ 40 archivos `.dart` · ~8.500 líneas |
| `pubspec.yaml` con dependencias reales de pub.dev | ✅ 141 dependencias resueltas |
| Configuración Android (manifest, Gradle, permisos, firma) | ✅ verificada en el build real |
| Icono de la app (cómic: auriculares + robot con nota musical) | ✅ todas las densidades + adaptativo + monocromo |
| Capturas de la interfaz | ✅ carpeta `capturas/` (5 mockups) |
| Verificación estática del código | ✅ `tools/verificar_proyecto.py` |

**Datos del build verificado:**

```
Flutter 3.47.7 (stable) · Dart 3.13.5 · Gradle 8.14.3 · AGP 8.11.1 · Kotlin 2.2.20
compileSdk 36 · minSdk 24 · targetSdk 36 · NDK 27.0.12077973
package: com.botmp3.app · versionName 1.4.4 · versionCode 15 · label: BotMp3
Firmante: CN=BotMp3, O=BotMp3, C=BO
SHA-256: edc834ce6219b4fe991650cb6e65122285447add545fed57f13d72daf99d62c6
Contenido: classes.dex + lib/arm64-v8a/{libapp.so, libflutter.so}
```

### Ajustes aplicados para que compile con Flutter 3.47

| Cambio | Motivo |
|---|---|
| Se quitó `audiotags` (y con él `jni`, `flutter_rust_bridge`) | Compila Rust + NDK; los metadatos se guardan en la biblioteca JSON propia (mismos campos: título, artista, álbum, año, género, duración y tags) |
| Se quitó `speech_to_text` (dictado) | Su dependencia `jni` exigía el NDK; las **respuestas habladas (TTS) siguen activas** |
| `dependency_overrides: path_provider_android 2.2.x` | La rama 2.3+ implementa el plugin con JNI y exige NDK |
| `minifyEnabled = false` en release | Evita fallos de R8; la APK pesa algo más pero es estable para probar |
| AGP `8.11.1`, Kotlin `2.2.20`, Gradle `8.14.3` | Mínimos que exige Flutter 3.47.7 |

> Los **puntos de extensión** para volver a activar etiquetas ID3 y dictado están marcados en
> `lib/services/metadata_service.dart` y `lib/services/voice_service.dart`.

---

## 🧭 Novedades de la versión 1.5.0 — orden, importación en vivo y audios de apps

Tres cosas que fallaban en el uso real:

### 1. El orden alfabético «no funcionaba del todo»
`String.compareTo` comparaba por código de carácter, así que **«Ámbar» iba después de la «Z»** y
las canciones **sin artista o sin álbum encabezaban la lista** (cadena vacía ordena primero).
Ahora se compara con `claveAlfabetica()` (sin acentos, en minúsculas), los valores vacíos van
**al final**, hay orden secundario por título y el menú marca con ✓ la opción activa.

### 2. La importación automática solo corría al abrir la app
Había que **reiniciar** para ver la música nueva. `_HomeShellState` es ahora
`WidgetsBindingObserver`: al volver a la app (`resumed`) se reescanea MediaStore (con un margen
mínimo de 20 s entre escaneos para no repetirlos) y las canciones nuevas aparecen solas.

### 3. Nuevo ajuste: audios de apps y notas de voz
**Ajustes ▸ Importar audios de apps y notas de voz** (desactivado por defecto).
- Desactivado: solo se importa música (`IS_MUSIC != 0`) y además se **ocultan** los audios de
  WhatsApp, Telegram, Instagram, grabadoras… ya presentes en la biblioteca.
- Activado: se incluyen también esos audios (y las pistas de más de 15 s que Android no marca
  como música), y se vuelve a escanear al momento para verlos sin reiniciar.

---

## 🐛 Novedades de la versión 1.4.4 — el ranking ya no cuenta reproducciones falsas

Al pulsar **«Reproducción aleatoria de todo»** en la lista de canciones, la app preparaba la
cola **sin arrancar la reproducción**, pero aun así sumaba una reproducción a la **primera
canción de la cola** (y en ocasiones dos, porque también la contaba el cambio de índice de la
sesión multimedia). Resultado: el ranking se inflaba, sobre todo arriba.

**Arreglo:**
- La reproducción se cuenta **solo cuando el audio suena de verdad**, y **una sola vez por
  canción** (`playerStateStream` + deduplicación por id).
- Aleatorio, preparar colas, saltos con el reproductor en pausa y rebobinar **ya no suman**.
- Nuevo botón **⟲ en el Ranking** para **reiniciar las estadísticas** (los números ya inflados
  no se pueden reconstruir, así que puedes empezar de cero).

> Nota de mantenimiento: el bloque `ndk { abiFilters … }` de `android/app/build.gradle` sigue
> activo (lo necesita el empaquetado normal). Si el SDK se queda sin el NDK r27c, AGP intentará
> instalarlo y necesitará ~3 GB libres; el SDK existe en `%LOCALAPPDATA%\Android\Sdk`.

---

## ℹ️ Novedades de la versión 1.4.3 — «Acerca de» dice la verdad

El texto de la versión estaba **escrito a mano** en el código («Versión 1.0.0»), así que nunca
cambiaba al instalar una versión nueva. Ahora:

| Antes | Ahora |
|---|---|
| «Versión 1.0.0» fija | Se lee del **APK instalado**: «BotMp3 1.4.3 (compilación 14)» |
| Sin información de la compilación | Muestra también el **número de compilación** |
| Sin novedades | Añade **«Novedades: …»** con lo que trae esa compilación concreta |
| Descripción antigua | Texto actualizado (cristal, ranking, tendencias y trabajo offline) |

La versión se consulta al sistema mediante un canal nativo propio (`botmp3/appinfo`), así que
**la pantalla se actualizará sola** en cada versión futura.

> **Sobre los avisos de versión nueva:** si publicas la app en **F-Droid**, las actualizaciones y
> los avisos los gestiona F-Droid automáticamente (y esta pantalla siempre mostrará la versión
> correcta). Si prefieres que la app **avise por su cuenta** (por ejemplo desde las *releases* de
> GitHub), solo hace falta indicar la dirección del repositorio: se añade una comprobación con
> aviso y botón de descarga.

---

## 🔒 Novedades de la versión 1.4.2 — controles del bloqueo y diagnóstico

Se corrigieron **dos causas reales** por las que los botones de la pantalla de bloqueo podían quedarse «muertos»:

| Causa | Por qué rompía | Solución |
|---|---|---|
| `androidStopForegroundOnPause: true` | Al pausar, el servicio dejaba de ser primer plano y en **HyperOS/MIUI el sistema lo mata**: la notificación sigue ahí pero **ningún botón responde** | Ahora el servicio **permanece en primer plano** mientras haya cola |
| **Un segundo `AudioPlayer`** en `MetadataService.readDurationMs` | `just_audio_background` solo admite **un reproductor por app**; al crear un reproductor temporal, el plugin pasaba a controlar ese otro reproductor y los controles quedaban ligados a un reproductor ya liberado | Eliminado: **un solo reproductor** en toda la app (la duración real la informa el reproductor al sonar) |
| Cola con entradas sin ruta válida | Una sola entrada mala podía impedir cargar la cola completa | La cola se **sanea** antes de cargarse |

### 🩺 Nuevo: Diagnóstico de reproducción
En **Ajustes ▸ Diagnóstico de reproducción** hay ahora una pantalla que muestra:
permiso de notificaciones, restricción de batería, **fuentes cargadas en la sesión multimedia
frente a las canciones de la cola**, estado del reproductor y **los últimos errores**,
con un botón para **copiar el informe**. Sirve para localizar el problema en el propio móvil.

---

## 🐞 Novedades de la versión 1.4.1 — arreglo de la pestaña IA

La **tarjeta de tendencias** que añadí en la 1.4.0 rompía la pestaña IA: usaba un `Row` con
`Expanded` dentro de una superficie de cristal y, en ese contexto, el `Expanded` se quedaba sin
ancho, así que el texto se partía **letra a letra** y la tarjeta crecía hasta ocupar la pantalla.

**Solución:** el acceso a Tendencias es ahora un **chip** en la barra de acciones rápidas de la IA
(junto a «Recomiéndame», «Modo DJ»…), que se dimensiona por su contenido y no puede romper el
layout. Se sigue llegando a la pantalla de Tendencias desde ese chip y desde **Ajustes**.

---

## 🏆🔥 Novedades de la versión 1.4.0 — ranking propio y tendencias de internet

### 1) Ranking de lo que más escuchas
- **Historial de reproducciones** propio (hasta 3000 entradas, en un fichero aparte) que permite rankings por periodo.
- Pantalla **Ranking** (icono 🏆 en la barra de *Canciones*, y también en Ajustes) con cuatro pestañas:
  **Canciones · Artistas · Álbumes · Géneros**, medallas 🥇🥈🥉 para el podio y botón **«Reproducir el top 10»**.
- Filtros de periodo: **Todo · Último mes · Última semana**, con el total de reproducciones a la vista.
- Tocar un artista, álbum o género reproduce todo lo más escuchado de ese grupo.

### 2) Tendencias de internet + notificación diaria
- Pantalla **Tendencias** (tarjeta en la pestaña *IA* y en Ajustes) con las canciones más escuchadas del país elegido
  (España, México, EE. UU., Argentina, Colombia, Chile, Perú, Venezuela, Ecuador y República Dominicana).
- Fuente pública **sin clave ni cuenta** (listas de éxitos de Apple). Si una canción está en tu biblioteca, aparece marcada
  como **«ya la tienes»** y se reproduce al tocarla; si no, se abre la búsqueda en internet.
- **Aviso diario configurable**: hora a elegir, con un resumen del *top 3* en la notificación. Implementado en código nativo
  propio (`NotificationHelper`, `TrendsReminderReceiver`, `BootReceiver`), **sin añadir dependencias** y con reprogramación tras reiniciar el móvil.
- Botones para **notificar al instante** y **copiar la lista**.

> Las tendencias se conectan a un servicio externo (sin clave). La app sigue funcionando al 100 % sin conexión; la
> antifunción `NonFreeNet` de F-Droid ya cubre estas conexiones (IA y listas de éxitos).

---

## ⏭️ Novedades de la versión 1.3.5 — siguiente/anterior en la pantalla de bloqueo

**El fallo estaba en el diseño del motor de reproducción.** Cargaba **una sola
canción** en el reproductor (`setAudioSource` con una única fuente), así que la
sesión multimedia creía que la cola tenía **un** elemento: en el bloqueo solo
aparecían «reproducir» y «pausar», sin siguiente ni anterior.

| Antes | Ahora |
|---|---|
| Una canción cargada cada vez → cola de 1 elemento para el sistema | Se carga **la cola completa** (`ConcatenatingAudioSource`) → el sistema conoce todas las canciones y ofrece **siguiente/anterior** |
| El sistema cambiaba de pista y la app no se enteraba | La app **escucha el cambio de pista** y sincroniza carátula, título y estadísticas |
| Añadir/quitar de la cola no se reflejaba en la notificación | `enqueue`, «reproducir a continuación» y eliminar actualizan la cola del sistema **sin cortar la reproducción** |

Esto arregla los controles en la **pantalla de bloqueo, los auriculares, el reloj y
Android Auto**. Nota: con el **aleatorio activado**, el botón de la app sigue el orden
aleatorio, mientras que el del sistema avanza en orden de lista (comportamiento
estándar y predecible).

---

## 🤖 Novedades de la versión 1.3.4 — modelos de IA al día (DeepSeek)

**La API de DeepSeek retiró `deepseek-chat` y `deepseek-reasoner`.** La app ofrecía
esos dos nombres, así que al elegirlos la petición fallaba. Ahora:

| Cambio | Detalle |
|---|---|
| Modelos vigentes | **`deepseek-flash`** (por defecto: el más rápido y económico) y **`deepseek-v4-pro`** (más capaz, ~4× más caro) |
| Migración automática | Si tenías guardado un nombre retirado, la app pasa sola al equivalente actual |
| Modo «thinking» | **Desactivado** en las tareas con salida JSON (metadatos, listas, búsqueda, órdenes) → responde antes y cuesta menos. **Activado** en la conversación, donde aporta calidad |
| Pistas en la interfaz | Bajo el selector de modelos aparece para qué sirve el elegido |
| **Botón «Otro…»** | Permite escribir cualquier identificador de modelo (los proveedores cambian nombres a menudo) |

**¿Cuál elegir?** Para BotMp3, **`deepseek-flash`**: es el más rápido y barato, soporta
salida JSON y admite contexto de 1M de tokens. `deepseek-v4-pro` solo compensa para
tareas puntuales de razonamiento (análisis profundos o letras largas).

---

## 🔒 Novedades de la versión 1.3.3 — controles en la pantalla de bloqueo

**Falló porque la notificación de reproducción no llegaba a crearse.** Dos causas:

| Causa | Detalle | Solución |
|---|---|---|
| **Icono de notificación inválido** | `main.dart` no indicaba `androidNotificationIcon`, así que se usaba el icono **adaptativo** (`mipmap/ic_launcher`, un XML `<adaptive-icon>`). Android lo rechaza como icono de la barra de estado: la notificación no se crea y, con ella, desaparecen los controles (bloqueo, auriculares, reloj…) | Se generó un **icono monocromo propio** (`drawable-*/ic_stat_botmp3.png`, 24–96 px, silueta de auriculares + carita + nota) y se declara en `JustAudioBackground.init` |
| **Permiso de notificaciones sin pedir** | En Android 13+ sin `POST_NOTIFICATIONS` la notificación no se muestra | Se solicita al arrancar, junto al permiso de audio |
| Sesión de audio sin configurar | El foco y el tipo de sesión quedaban al azar | Se configura `AudioSessionConfiguration.music()` |

Además, en **Ajustes** hay ahora un aviso para HyperOS/MIUI: si la música se detiene
al bloquear, hay que conceder notificaciones, activar **«Inicio automático»** y poner la
batería en **«Sin restricciones»** (es una restricción del sistema, no de la app).

---

## 🔁 Novedades de la versión 1.3.2 — el efecto de transición ya funciona en todas las pestañas

**El fallo era real y quedó reproducido con una prueba automática**: el indicador
solo se deslizaba en el **primer** cambio de pestaña (Canciones → Listas) y en los
siguientes se quedaba quieto (desplazamiento medido: **0,0 px** al pasar de Listas
a Buscar). Coincidía exactamente con lo reportado.

| Aspecto | Antes (1.3.0/1.3.1) | Ahora (1.3.2) |
|---|---|---|
| Indicador de la barra | `AnimationController` + `didUpdateWidget`: solo animaba el primer cambio | **`AnimatedPositioned`** posicionado directamente por la pestaña activa: interpola en **todos** los cambios |
| Duración | Fija (520 ms) → saltar 4 pestañas parecía un salto | **Proporcional a la distancia** (300–620 ms): recorrido continuo |
| Contenido de la pestaña | Aparición suave poco perceptible | Aparece **desde transparente**, deslizándose 26 px y creciendo (escala 0.965 → 1) |
| Accesibilidad | — | Si el sistema tiene activado «Reducir animaciones», el cambio es instantáneo |

La prueba `test/glass_test.dart → «El indicador anima en TODAS las pestañas (no salta)»`
recorre las cinco pestañas y mide el desplazamiento a mitad de animación: **antes
fallaba, ahora pasa**. Total: 4 pruebas, todas en verde.

---

## 🐞 Novedades de la versión 1.3.1 — correcciones

| Fallo | Causa real | Solución |
|---|---|---|
| **Tocar una canción no la reproducía** (parecía «añadida a la cola») | La lista de canciones pasaba siempre `onSelected`, así que el toque se interpretaba como **selección múltiple**: había que pulsar «Reproducir selección» | Tocar **reproduce al instante**; la selección múltiple se activa con **pulsación larga** (y el toque marca/desmarca solo mientras dura ese modo) |
| Sonaba otra canción distinta a la elegida | `setQueue` arrancaba siempre por la **primera** canción de la cola, ignorando el índice pulsado | Se arranca por la **canción elegida**, tanto con orden normal como aleatorio |
| **El efecto de transición solo se veía entre algunas pestañas** | El contenido se cambiaba con `IndexedStack` sin animación, y el indicador de la barra no se fijaba con exactitud | Transición de aparición (deslizamiento + opacidad) en **todas** las pestañas, y el indicador siempre termina exactamente en su sitio. Se respeta «Reducir animaciones» del sistema |
| La imagen fuente del icono se empaquetaba en la APK | Estaba dentro de `assets/icon/` | Movida a `tools/icono_fuente.jpg` (la APK pesa algo menos) |

---

## ✨ Novedades de la versión 1.3.0 — efecto cristal (Liquid Glass)

Se aplicó el lenguaje de cristal de Apple adaptado a Android, con un sistema propio
(**sin dependencias externas ni shaders**) en `lib/widgets/glass.dart`:

| Elemento | Qué se hizo |
|---|---|
| **Barra de navegación inferior** | Flotante, con desenfoque real del fondo, luz especular, bisel, indicador que se desliza con rebote y háptica al cambiar de pestaña |
| **Mini reproductor** | Panel de cristal con resplandor del color de marca |
| **Fondo del cristal** | La **carátula del álbum difuminada** detrás de las barras: el cristal toma los colores reales de la música (tinte adaptativo) |
| **Respuesta táctil** | Los paneles se encogen al pulsar y vuelven con un muelle suave |
| **Control del usuario** | `Ajustes ▸ Apariencia`: interruptor **«Efecto cristal»** + **intensidad** (20 %–100 %). Se desactiva solo con el **ahorro de batería** |
| **Rendimiento** | `BackdropGroup` (una sola lectura del fondo por fotograma), calidad por elemento (`off/light/standard/high`) y superficie sólida cuando el efecto está apagado |

**Verificación:** 4 pruebas de widgets en `test/glass_test.dart` (`flutter test`) comprueban
el render en todas las calidades, el toque de los chips, el indicador de la barra y el
mapeo de calidad. Estado: ✅ todas en verde.

El catálogo completo de funciones de Liquid Glass (qué es replicable en Android y qué no,
paquetes del ecosistema y reglas de rendimiento) está en
[`docs/LIQUID_GLASS.md`](docs/LIQUID_GLASS.md).

**Siguiente fase opcional:** panel de cristal sobre la carátula en la pantalla de
reproducción, hojas modales y menús contextuales de cristal.

---

## 🧹 Almacenamiento y caché (por qué ocupaba tanto)

**Diagnóstico:** al importar con el selector, Android entrega URIs `content://` y el plugin
`file_picker` **copia cada canción a la caché de la app** para poder dar una ruta real; además,
cuando el proveedor devolvía bytes, la app guardaba otra copia en `files/imported/`. Resultado: la
música **duplicada** (≈ tu biblioteca en «Caché» y otra vez en «Datos del usuario»; HyperOS cuenta la
caché dentro de los datos) y el riesgo de que Android borrara la caché y las canciones dejasen de
sonar.

**Qué hace ahora la v1.2.0:**

| Acción | Efecto |
|---|---|
| Las importaciones se **mueven** a `files/imported/` (almacenamiento permanente) | Ya no queda audio en la caché; Android no puede borrarlo |
| **Ajustes ▸ Liberar espacio** | Reapunta cada copia al **archivo original del dispositivo** (MediaStore) y borra la copia: recupera el espacio completo |
| Limpieza automática | Si la caché supera 250 MB se limpia sola (nunca toca audio en uso) |
| Carátulas | Cada edición reemplaza la anterior y se borran las huérfanas |
| Escaneo | Ya no duplica canciones que ya tienes (ni las que apuntan a copias importadas) |

Con el caso reportado (1,33 GB en caché): instala la v1.2.0, abre la app (escaneo automático) y en
**Ajustes ▸ Liberar espacio** recuperarás casi todo ese espacio, manteniendo listas, favoritos e
historial: las canciones pasan a apuntar a tus archivos originales.

---

## 🆕 Novedades de la versión 1.1.0

### 1) Importación automática de la música del dispositivo
- Al abrir la app se consulta **MediaStore** mediante un puente nativo propio (sin plugins) y se
  añaden automáticamente las canciones nuevas con título, artista, álbum, año, duración y género.
- Las **carátulas de los álbumes** se extraen en segundo plano y se aplican solas.
- Ajustes ▸ Biblioteca: interruptor **«Importar canciones automáticamente»** y **«Escanear ahora»**.
- Si una pista no expone ruta de archivo (Android 10+), se reproduce igual vía `content://`.

### 2) Edición mucho más simple
- **✨ Autocompletar con IA**: corrige mayúsculas y erratas y propone álbum, año, género (de la
  lista de la app) y etiquetas. Tú revisas y guardas.
- Botón **«Carátula del álbum»**: aplica la imagen original del álbum del dispositivo con un toque.
- Editor de carátulas con fila de **acciones rápidas**: Mejorar · Rotar 90° · Original.

### 3) La IA ejecuta lo que le escribes
Escribe (o dicta) una orden y la app **la ejecuta de verdad**, no solo responde:
```
pon cumbia · reproduce Bad Bunny · reproduce la lista Fiesta
crea una lista de 20 canciones para entrenar
añade esta canción a la lista Fiesta
cambia el género de esta canción a Rock · ponle el álbum X
sube el volumen al 80% · velocidad 1.5x · aleatorio · repite esta canción
actualiza mi biblioteca · ¿qué suena? · cuántas canciones tengo · ayuda
```
El modelo añade bloques `<CMD>{...}</CMD>` (protocolo incluido en el prompt) y `ActionExecutor` los
aplica sobre la biblioteca y el reproductor. Además hay un **intérprete local de español**
(`lib/services/ai/ai_actions.dart`) para que las órdenes funcionen **sin API key y sin conexión**.
Las órdenes ejecutadas se muestran como chips en la pantalla de IA y en el chat.

---

## 🚀 Compilar la APK para el POCO X7 Pro

### 0) Requisitos

| Elemento | Versión verificada |
|---|---|
| Flutter SDK | **3.47.7** (el proyecto pide ≥ 3.24) |
| Dart | 3.13.5 |
| JDK | **21** (Gradle 8.14 no soporta JDK 25) |
| Gradle | **8.14.3** (wrapper del proyecto) |
| AGP / Kotlin | **8.11.1 / 2.2.20** |
| Android SDK | Platform 36 + Build-Tools 36 (y 35 para los plugins de audio) |
| NDK | 27.0.12077973 (obligatorio por AGP 8.11) |
| Dispositivo | POCO X7 Pro (Android 15 / 16 en HyperOS) |

> Comando exacto con el que se generó la APK entregada:
>
> ```bash
> flutter build apk --release --target-platform android-arm64
> ```
>
> Genera `build/app/outputs/flutter-apk/app-release.apk`.

> ⚠️ **JDK: usa 17 o 21, no 25.** El wrapper del proyecto usa Gradle 8.9 + AGP 8.7, que **no
> soportan Java 25**. En este equipo el único JDK instalado es el JBR 25 de Android Studio, así que
> hay que instalar Temurin 21 y apuntar Flutter a él:
>
> ```bash
> winget install EclipseAdoptium.Temurin.21.JDK          # Windows
> flutter config --jdk-dir "C:\Program Files\Eclipse Adoptium\jdk-21.0.5.11-hotspot"
> flutter doctor -v
> ```

### 1) Instalar Flutter (si no lo tienes)

```bash
git clone -b stable https://gitlab.com/flutter/flutter.git C:\src\flutter
# Añade C:\src\flutter\bin al PATH y comprueba:
flutter doctor
flutter doctor --android-licenses
```

### 2) Preparar el proyecto

```bash
cd BotMp3
flutter pub get          # descarga las dependencias y genera android/local.properties
flutter analyze          # análisis estático (opcional pero recomendado)
```

### 3) Compilar la APK

```bash
# APK de depuración (la que se instala directamente)
flutter build apk --debug

# APK de release (minificada, firmada con la keystore de ejemplo)
flutter build apk --release

# Variante solo para arm64 (POCO X7 Pro): más pequeña
flutter build apk --release --target-platform android-arm64

# Si quieres un APK por arquitectura (recomendado para distribuir)
flutter build apk --release --split-per-abi
```

Salidas:

```
build/app/outputs/flutter-apk/app-debug.apk
build/app/outputs/flutter-apk/app-release.apk
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk   (con --split-per-abi)
```

### 4) Instalar en el POCO X7 Pro

```bash
# Con cable USB y depuración activada
adb devices
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# O bien: copia la APK al teléfono, ábrela y permite
# "Instalar aplicaciones desconocidas" para tu explorador de archivos.
```

> **Firma de release:** el proyecto espera `android/app/botmp3-release.jks`. Si no existe, el
> release se firma con la clave de depuración (instalable igualmente). Para crear la tuya:
>
> ```bash
> keytool -genkeypair -v -keystore android/app/botmp3-release.jks -alias botmp3 \
>   -keyalg RSA -keysize 2048 -validity 10000 \
>   -storepass botmp3 -keypass botmp3 \
>   -dname "CN=BotMp3, O=BotMp3, C=BO"
> ```

### 5) (Alternativa) Compilar solo con Gradle

Si prefieres el flujo nativo Android (`gradlew assembleDebug`):

```bash
cd android
./gradlew assembleDebug          # Linux/macOS
gradlew.bat assembleDebug        # Windows
```

Requiere que `android/local.properties` tenga `flutter.sdk` y `sdk.dir`
(lo genera automáticamente `flutter pub get`).

---

## 🔑 Configurar la IA (opcional, pero es la gracia de la app)

BotMp3 funciona **100 % sin conexión**: la IA solo se usa en la pestaña **IA**.
Añade las claves en **Ajustes ▸ IA multimodelo** (se guardan cifradas con el **Android Keystore**):

| Proveedor | Dónde obtener la key | Modelos incluidos |
|---|---|---|
| OpenAI | <https://platform.openai.com/api-keys> | `gpt-4o`, `gpt-4o-mini`, `o1`, `o1-mini` |
| DeepSeek | <https://platform.deepseek.com/api_keys> | `deepseek-chat` (V3), `deepseek-reasoner` (R1) |
| Google Gemini | <https://aistudio.google.com/app/apikey> | `gemini-1.5-pro`, `gemini-1.5-flash`, `gemini-2.0-flash` |
| Anthropic Claude | <https://console.anthropic.com/settings/keys> | `claude-3-5-sonnet-latest`, `claude-3-5-haiku-latest`, `claude-3-opus-latest` |

Con la key guardada, pulsa **Probar**. El resto es conversación en español:

* «recomiéndame 10 canciones de rock latino 2020-2025 con artistas latinos»
* «hazme una playlist de 30 canciones para entrenar»
* «algo tranquilo para estudiar un domingo lluvioso»
* «crea una canción de cumbia sobre Bolivia» → genera título, estructura, letra y **prompt** para
  un generador de audio, más enlaces de búsqueda.

> **Honestidad técnica:** la app **no genera audio ni descarga música**. Con las APIs crea la ficha
> creativa (letra/estructura/prompt) y **enlaces** de búsqueda; las canciones que propone y ya están
> en tu biblioteca se reproducen con un toque.

---

## 🗂️ Estructura del proyecto

```
BotMp3/
├── pubspec.yaml                     # dependencias (just_audio, provider, image, audiotags…)
├── analysis_options.yaml
├── lib/
│   ├── main.dart                    # arranque + just_audio_background (notificación)
│   ├── app.dart                     # MultiProvider + MaterialApp (tema claro/oscuro)
│   ├── core/
│   │   ├── constants.dart           # géneros, formatos, 4 proveedores IA, tags
│   │   ├── theme.dart               # Material 3 oscuro estilo Spotify + claro
│   │   └── formatters.dart          # tiempos, tamaños, similitud de texto
│   ├── models/                      # Song, Playlist, mensajes y resultados de IA
│   ├── services/
│   │   ├── storage_service.dart      # JSON local (biblioteca, ajustes, chat, importados)
│   │   ├── library_service.dart      # CRUD, búsqueda avanzada, export/import JSON
│   │   ├── metadata_service.dart     # etiquetas ID3/MP4/FLAC/OGG + duración + carátula
│   │   ├── player_service.dart       # cola manual, shuffle, repeat, wakelock
│   │   ├── cover_editor_service.dart # edición de imagen en isolate (compute)
│   │   ├── secure_keys_service.dart  # API keys cifradas (Keystore/Keychain)
│   │   ├── settings_service.dart     # preferencias persistentes
│   │   ├── voice_service.dart        # dictado (español) + TTS
│   │   ├── media_importer.dart       # file_picker, permisos, exportar a galería
│   │   └── ai/
│   │       ├── ai_client.dart        # base + errores + parser JSON + fábrica
│   │       ├── openai_client.dart    # OpenAI y DeepSeek (API compatible)
│   │       ├── gemini_client.dart    # Google Gemini
│   │       ├── claude_client.dart    # Anthropic Claude
│   │       └── ai_orchestrator.dart  # prompts, DJ IA, playlists, búsqueda, canciones
│   ├── providers/                    # LibraryProvider, PlayerProvider, AiAssistantProvider, SettingsProvider
│   ├── screens/                      # home_shell, songs, playlists, search, player,
│   │                                 # song_edit, cover_editor, ai, settings
│   └── widgets/                      # cover_art, wave_bars, song_tile, mini_player, dialogs
├── android/                          # manifest, Gradle, MainActivity (AudioServiceActivity), iconos
├── assets/icon/                      # icono maestro 1024 px + versión monocroma
├── capturas/                         # 5 mockups de la interfaz
└── tools/
    ├── generar_icono_y_capturas.py   # regenera icono + capturas
    └── verificar_proyecto.py         # verificación estática sin Flutter
```

---

## 🖼️ Cómo se ve la app

Las capturas están en [`capturas/`](capturas/) y se regeneran con
`python tools/generar_icono_y_capturas.py`.

| Pantalla | Descripción |
|---|---|
| `01_biblioteca.png` | **Canciones**: tarjetas con carátula, título, artista, duración y corazón. Barra superior con filtros y orden; FAB **Importar**; mini-reproductor con ondas animadas; navegación inferior de 5 pestañas. |
| `02_reproductor.png` | **Reproductor a pantalla completa**: carátula grande, chips de género/año/tags, barra de progreso con tiempos, controles grandes (aleatorio · anterior · **play 68 px** · siguiente · repetir) y fila secundaria (velocidad, volumen, **DJ IA**, metadatos). |
| `03_editor_caratula.png` | **Editor de carátula**: vista previa en vivo, sliders de brillo/contraste/saturación/temperatura/velo, chips de filtros (Original, Vintage, Blanco y negro, Cálido, Frío, Dramático, Desvanecido, Vivo), campo de texto/logo y botón **Aplicar a la canción**. |
| `04_ia_multimodelo.png` | **IA musical**: chips de proveedor (OpenAI · DeepSeek · Gemini · Claude), conversación en burbujas, tarjeta de playlist generada con el motivo de cada canción, acciones rápidas (**Recomiéndame · Playlist de 30 · Modo DJ · Crear canción**) y barra de entrada con micrófono. |
| `05_busqueda_avanzada.png` | **Búsqueda global**: caja de texto, chips de género/idioma, tarjeta de *búsqueda inteligente* con explicación en lenguaje natural y resultados ordenados por relevancia. |

---

## 📱 Optimización para el POCO X7 Pro

| Aspecto | Implementación |
|---|---|
| **Pantalla siempre visible** | `wakelock_plus` activo solo mientras suena música (configurable en Ajustes). |
| **120 Hz sin tirones** | Edición de carátulas en `compute()` (isolate), `cacheWidth` en todas las carátulas, `ListView.builder`, `IndexedStack` (no se recargan pestañas), animaciones cortas (180 ms). |
| **Batería en reproducción continua** | Sin visualizador pesado: las ondas son un `CustomPaint` de 5 barras que se **congela** en pausa o en modo ahorro; refresco de progreso a 1 s en modo ahorro (0,5 s normal); una sola conexión HTTP reutilizada para la IA. |
| **Temperaturas extremas** | *Protección térmica* + *Modo ahorro*: desactivan animaciones, reducen trabajo en segundo plano y evitan recompilar imágenes (ideal en verano boliviano) y en frío extremo evitan picos de CPU que agotan la batería. |
| **Uso con una mano** | Objetivos táctiles ≥ 56 dp, controles principales centrados y de 68 px, acciones secundarias en hojas inferiores (`showModalBottomSheet`). |
| **AMOLED** | Tema oscuro con negro puro (`#0A0A0F`), `LaunchTheme` negro (sin flash al abrir). |
| **Almacenamiento** | Importación vía SAF: no requiere permisos amplios y funciona con SD, Google Drive o MEGA. |

---

## 🧩 Funcionalidades implementadas (requisitos → código)

| Requisito | Dónde está |
|---|---|
| Lista de reproducción personalizable · orden · shuffle · repeat | `services/player_service.dart`, `providers/player_provider.dart` |
| Agregar canciones manualmente / por ruta | `services/media_importer.dart`, `screens/songs_screen.dart` (FAB Importar), `settings_screen.dart` (carpeta completa) |
| Barra de progreso, volumen, tiempo transcurrido/total | `screens/player_screen.dart` (Slider + `positionStream`/`durationStream`) |
| MP3, M4A, OGG, FLAC, WAV (+AAC, OPUS, AIFF) | `core/constants.dart` → `AudioFormats.supported` |
| Listas ilimitadas con nombre y descripción | `models/playlist.dart`, `widgets/dialogs.dart` |
| Agregar/quitar canciones de cualquier lista | `library_service.dart`, `screens/playlists_screen.dart` (arrastrar para reordenar) |
| Exportar/importar listas como JSON | `library_service.exportPlaylist/importPlaylist`, `MediaImporter.exportText/pickJsonFile` |
| Metadatos obligatorios: título, artista, álbum, año, género (select), duración | `screens/song_edit_screen.dart` |
| Tags extra para búsqueda avanzada | `Song.tags`, `lib/widgets/dialogs.dart` (filtros) |
| Búsqueda global por título/artista/álbum/género/año/tags | `library_service.search()` con puntuación de relevancia |
| Carátula por canción (PNG/JPG) y edición interna | `services/cover_editor_service.dart`, `screens/cover_editor_screen.dart` |
| Brillo, contraste, saturación, rotación, recorte, filtros, texto/logos | `CoverEditState` + pipeline por píxel en isolate |
| Exportar la carátula editada | `MediaImporter.exportBytes` (galería/almacenamiento) + incrustado en el archivo |
| Carátula a pantalla completa al reproducir | `screens/player_screen.dart` (carátula grande con `Hero`) |
| IA multimodelo (OpenAI, DeepSeek, Gemini, Claude) | `services/ai/*` |
| Recomendaciones por género/artista/mood/lista | `AiOrchestrator.recommend` |
| Generación de playlists («30 canciones de rock latino 2020-2025») | `AiOrchestrator.generatePlaylist` + `createPlaylistFromAi` |
| Búsqueda inteligente con explicación | `AiOrchestrator.smartSearch` + `screens/search_screen.dart` |
| Conversación en español sobre música | `AiOrchestrator.chat`, `screens/ai_screen.dart` |
| Crear canciones por descripción + enlaces | `AiOrchestrator.songIdea` (letra, estructura, prompt, búsqueda) |
| Modo DJ IA (elige y explica) | `AiOrchestrator.djNext` + botón DJ IA del reproductor |
| API keys externas cifradas | `services/secure_keys_service.dart` (Android Keystore / Keychain) |
| Notificaciones de reproducción | `just_audio_background` + `AudioServiceActivity` en el manifest |
| Tema claro/oscuro automático | `SettingsProvider.themeMode` |
| Voz en español (dictado + TTS) | `services/voice_service.dart` (`speech_to_text`, `flutter_tts`) |
| Modo offline total | Toda la biblioteca es local (JSON + archivos); la IA es opcional |

---

## 🔍 Verificación y herramientas

```bash
python tools/verificar_proyecto.py        # imports, dependencias, llaves, assets, símbolos
flutter analyze                            # análisis real de Dart (requiere Flutter)
python tools/generar_icono_y_capturas.py   # regenera icono + capturas
```

Resultado actual del verificador estático:

```
Archivos .dart analizados: 40
Clases/enums declarados: 77
Dependencias declaradas: 19
OK: no se detectaron problemas de imports, llaves ni assets.
```

---

## 🛠️ Problemas frecuentes

| Síntoma | Solución |
|---|---|
| `Unsupported class file major version 69` / Gradle falla al arrancar | Estás usando **JDK 25**. Instala JDK 21 y ejecuta `flutter config --jdk-dir <ruta-jdk21>`. |
| `flutter.sdk not set in local.properties` | Ejecuta `flutter pub get` dentro de `BotMp3/` (genera `android/local.properties`). |
| `Could not resolve com.android.tools.build:gradle:8.7.3` | Sin conexión o proxy: revisa `android/build.gradle` y la red. |
| La notificación no aparece | Concede **Notificaciones** a BotMp3 (Android 13+) y activa `androidStopForegroundOnPause` (ya configurado). |
| No se leen las etiquetas de un MP3 raro | BotMp3 cae al nombre del archivo; edita los metadatos a mano (se guardan en su propia base local). |
| `API key inválida` al probar | Revisa que la clave no tenga espacios y que el proveedor tenga saldo. |
| Carátula no incrustada en el archivo | Algunos formatos (p. ej. WAV) no admiten carátula; BotMp3 la guarda en su carpeta de carátulas. |

---

## 🔐 Privacidad

* La música, las listas, las carátulas y el historial **nunca salen del dispositivo**.
* Solo se envía a la API elegida el texto que escribes/preguntas y el catálogo compacto
  (título, artista, álbum, año, género, tags) que la IA necesita para recomendar.
* Las API keys se guardan **cifradas** (Android Keystore / iOS Keychain) y no se exportan en los
  respaldos JSON.

---

## 📄 Licencia y créditos

Proyecto de ejemplo listo para personalizar. Dependencias: `just_audio`,
`just_audio_background`, `audio_service`, `provider`, `image`, `audiotags`, `file_picker`,
`flutter_secure_storage`, `speech_to_text`, `flutter_tts`, `url_launcher`, `permission_handler`,
`wakelock_plus`, `http` — todas con licencias permisivas (MIT/BSD/Apache 2.0).
El uso de cada API de IA se rige por los términos de su proveedor.
