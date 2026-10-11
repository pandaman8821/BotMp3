# Petición de empaquetado (RFP) — texto listo para pegar

> Abre **https://gitlab.com/fdroid/rfp/-/work_items/new**, pega el título en «Title» y todo
> lo demás en la descripción. Sustituye antes `pandamanlab`, `pandamanlab` y el correo.

## Título

```
BotMp3 — reproductor de música offline con IA, ranking y tendencias (com.botmp3.app)
```

## Cuerpo

```markdown
### Nombre de la aplicación
BotMp3

### Descripción corta
Reproductor offline con IA, listas, carátulas, ranking y tendencias.

### Descripción larga
(copiar el contenido de `fastlane/metadata/android/es-ES/full_description.txt`;
también hay versión en inglés en `fastlane/metadata/android/en-US/full_description.txt`)

### Datos de la aplicación
- **Identificador**: `com.botmp3.app`
- **Repositorio**: https://gitlab.com/pandamanlab/BotMp3
- **Versión a empaquetar**: `1.4.3` (versionCode `14`), etiqueta `v1.4.3`
- **Licencia**: GPL-3.0-or-later (archivo `LICENSE` incluido)
- **Categorías**: Multimedia / Music
- **Autor**: pandamanlab pandamanrd@gmail.com
- **Incidencias**: https://gitlab.com/pandamanlab/BotMp3/issues
- **Antifunciones**: `NonFreeNet`
- **Receta incluida**: `metadata/com.botmp3.app.yml`
- **Metadatos listos**: `fastlane/metadata/android/` (es-ES y en-US, con icono,
  capturas, descripciones y changelogs de cada versión)

### Justificación de la antifunción NonFreeNet
Las funciones de IA (OpenAI, DeepSeek, Google Gemini, Anthropic Claude) son
**opcionales**, están desactivadas por defecto y requieren que el usuario introduzca su
propia clave de API. La lista de tendencias usa un **servicio público gratuito sin
clave**. La aplicación es totalmente funcional sin activar ninguna conexión.

### Notas para quien empaquete
- Aplicación **Flutter (Dart)**. Compilada y verificada con:
  Flutter **3.47.7**, Dart 3.13.5, AGP **8.11.1**, Kotlin **2.2.20**, Gradle **8.14.3**,
  NDK **r27c**, `compileSdk 36`, `minSdk 24`, `targetSdk 36`, ABI `arm64-v8a`.
- La receta de ejemplo usa la *srclib* `flutter`; si la versión disponible en la granja
  difiere, ajustar `srclibs`/`prebuild`.
- **No hay código nativo propio**: el efecto de cristal usa solo APIs de Flutter
  (`BackdropFilter`); las notificaciones de tendencias usan un `MethodChannel` propio en
  Kotlin (sin plugins externos ni desugaring).
- `path_provider_android` está fijado a la rama **2.2.x** con `dependency_overrides`
  porque la 2.3+ implementa el plugin con JNI y obliga a usar el NDK.
- Todas las dependencias son **MIT/BSD/Apache**. Sin anuncios, sin rastreadores y sin
  analítica.
- La app no pide ninguna clave para funcionar.
```

## Después de enviarlo

1. Un voluntario revisa la petición y escribe/ajusta la receta.
2. Suele tardar **de unas semanas a un par de meses**.
3. Cuando la app esté publicada, F-Droid gestiona las actualizaciones y los avisos:
   solo hay que subir el `versionCode` y crear la etiqueta (`git tag v1.4.4`).
