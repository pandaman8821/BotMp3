# 📦 Cómo publicar BotMp3 en F-Droid — pasos, en orden

> **Lo primero que hay que entender:** F-Droid **no acepta APK subidas**. Ellos
> **compilan desde tu código fuente** y firman con **su propia clave**. Así que los
> pasos son: publicar el repositorio → rellenar unos datos → abrir una petición.
> Todo lo demás (licencia, descripciones, icono, capturas, receta) ya está
> preparado dentro de este proyecto.

---

## Punto de partida: qué ya está listo

| Requisito de F-Droid | Estado |
|---|---|
| Licencia libre | ✅ `LICENSE` (GPL-3.0-or-later) |
| Sin dependencias privativas | ✅ Todo MIT/BSD/Apache |
| Sin anuncios ni rastreadores | ✅ |
| Icono 512×512 px | ✅ `fastlane/metadata/android/*/images/icon.png` |
| Capturas | ⚠️ 5 por idioma, pero son de la v1.0 (conviene renovarlas) |
| Descripción corta y larga (es/en) | ✅ `fastlane/metadata/android/{es-ES,en-US}/` |
| Changelog de la versión | ✅ `changelogs/7.txt` (versionCode 7 = v1.3.2) |
| Antifunción declarada | ✅ `NonFreeNet` (la IA es opcional y usa servicios no libres) |
| Receta de compilación | ✅ `metadata/com.botmp3.app.yml` (rellena los `<...>`) |
| Receta al día (1.3.2 / code 7) | ✅ |
| Firma y `local.properties` fuera del repo | ✅ en `.gitignore` |
| **Código en un repositorio público** | ⛔ **Lo tienes que hacer tú → Paso 1** |

---

## Paso 1 — Publicar el código (obligatorio)

```bash
cd BotMp3
git init
git add .
git commit -m "BotMp3 1.3.2 — reproductor con cristal, escaneo automático y DJ IA"
git branch -M main
git remote add origin https://gitlab.com/TU-USUARIO/BotMp3.git
git push -u origin main

# La etiqueta es obligatoria: la receta detecta versiones nuevas por etiquetas
git tag v1.3.2
git push origin v1.3.2
```

- Vale GitHub, GitLab o Codeberg.
- **Nunca subas** `android/app/botmp3-release.jks` (tu firma) ni `local.properties`:
  el `.gitignore` ya los excluye.
- Sí conviene subir `pubspec.lock` (compilaciones reproducibles).

---

## Paso 2 — Rellenar 4 datos (2 minutos)

Abre `metadata/com.botmp3.app.yml` y sustituye:

| Marcador | Dónde | Por qué |
|---|---|---|
| `pandamanlab` | 4 apariciones (Repo, SourceCode, IssueTracker, WebSite) | Tu usuario del repositorio |
| `pandamanlab` | `AuthorName` | Firma de la ficha |
| `pandamanrd@gmail.com` | `AuthorEmail` | Contacto para el equipo de F-Droid |

Opcional pero recomendable: actualizar las capturas en
`fastlane/metadata/android/{es-ES,en-US}/images/phoneScreenshots/` (1080×2400 aprox.).

---

## Paso 3 — (Recomendado) Probar la receta en tu PC

```bash
pip install fdroidserver

git clone https://gitlab.com/fdroid/fdroiddata.git
cd fdroiddata
cp /ruta/completa/a/BotMp3/metadata/com.botmp3.app.yml metadata/

fdroid lint com.botmp3.app
fdroid build --server com.botmp3.app
```

Si `fdroid build` termina bien, la inclusión es casi segura. Si falla, suele ser por
la versión del SDK de Flutter que usa la *srclib* `flutter` de la receta: este
proyecto se compiló y verificó con **Flutter 3.47.7 · Dart 3.13.5 · AGP 8.11.1 ·
Kotlin 2.2.20 · Gradle 8.14.3 · NDK r27c · compileSdk 36 · minSdk 24**.

---

## Paso 4 — Enviar la petición (RFP) — la vía más sencilla

1. Entra en **https://gitlab.com/fdroid/rfp/-/work_items/new**
2. Pega el texto de abajo (cambiando lo tuyo).
3. Un voluntario escribe o ajusta la receta y abre el *merge request*.
   Tiempos habituales: **de unas semanas a un par de meses**.

### Texto listo para pegar en el RFP

```
BotMp3 — reproductor de música offline con editor de carátulas y DJ IA

Repositorio:      https://gitlab.com/TU-USUARIO/BotMp3
Licencia:         GPL-3.0-or-later
Categoría:        Multimedia / Music
Autor:            TU NOMBRE pandamanrd@gmail.com
Antifunciones:    NonFreeNet — las funciones de IA son opcionales y se conectan a
                  servicios no libres (OpenAI, DeepSeek, Google Gemini, Anthropic
                  Claude) usando la clave del propio usuario. La app funciona al
                  100 % sin activarlas.

Descripción corta: Reproductor de música offline con listas, editor de carátulas y DJ IA.
Descripción larga: (copiar de fastlane/metadata/android/es-ES/full_description.txt)

Notas para quien empaquete:
- Aplicación Flutter (Dart). Compilada y probada con Flutter 3.47.7, AGP 8.11.1,
  Kotlin 2.2.20, Gradle 8.14.3, NDK r27c, compileSdk 36, minSdk 24.
- Incluyo una receta de ejemplo en metadata/com.botmp3.app.yml.
- Sin código nativo propio: los efectos de cristal usan solo APIs de Flutter
  (BackdropFilter) y los metadatos se guardan en un JSON local de la app.
- `path_provider_android` está fijado a la rama 2.2.x con dependency_overrides
  porque la 2.3+ implementa el plugin con JNI y obliga a usar el NDK.
- La app no pide ninguna clave para funcionar; la IA es opcional.
```

---

## Paso 5 — Alternativa: enviar tú el *merge request*

```bash
git clone https://gitlab.com/fdroid/fdroiddata.git
cd fdroiddata
cp /ruta/a/BotMp3/metadata/com.botmp3.app.yml metadata/
fdroid lint com.botmp3.app
# Cuando pase el lint:
git checkout -b botmp3
git add metadata/com.botmp3.app.yml
git commit -m "New app: BotMp3"
git push origin botmp3
```

Y abre el *merge request* en GitLab explicando qué es la app y la antifunción
`NonFreeNet`. Es la vía más rápida si tienes soltura con Git.

---

## Paso 6 — Alternativa: repositorio propio (sin esperar aprobación)

Si quieres distribución FOSS ya, puedes montar tu propio repositorio F-Droid
firmado con `fdroidserver` y compartir la URL. Tus usuarios lo añaden como
repositorio adicional. Útil mientras esperas la inclusión en el principal.

---

## Después de publicar: cosas importantes

| Tema | Detalle |
|---|---|
| **Firma distinta** | F-Droid firma con su clave: su APK **no se instala encima** de la que compilé (tendrías que desinstalar). Decide qué vía será tu principal para no confundir a los usuarios |
| **Nueva versión** | Sube `versionCode` en `pubspec.yaml`, crea la etiqueta (`git tag v1.3.3`) y F-Droid la detecta (`UpdateCheckMode: Tags`). A veces hay que actualizar la receta con el nuevo `CurrentVersion` |
| **Antifunciones** | Si algún día quitas la IA, avisa para retirar `NonFreeNet`. Si añades anuncios o analítica, hay que declararlo |
| **Tu APK propia** | Puedes seguir repartiéndola en la sección *Releases* de tu repositorio en paralelo |
| **Incidencias** | Configura bien `IssueTracker` en la receta para que los usuarios te reporten ahí |

---

## Checklist final

- [ ] Repositorio público con `LICENSE`, `metadata/` y `fastlane/` (y `pubspec.lock`)
- [ ] Etiqueta `v1.3.2` creada y subida
- [ ] `pandamanlab`, `AuthorName` y `AuthorEmail` rellenados en `metadata/com.botmp3.app.yml`
- [ ] `changelogs/7.txt` presente en `es-ES` y `en-US` ✅ (ya incluido)
- [ ] Capturas renovadas (recomendable)
- [ ] `fdroid lint com.botmp3.app` sin errores (si has probado la receta)
- [ ] Issue RFP abierto **o** merge request enviado