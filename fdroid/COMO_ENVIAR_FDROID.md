# Enviar BotMp3 a F-Droid (paso a paso)

## Antes de nada
- Repositorio: https://github.com/pandaman8821/BotMp3 (publico, GPL-3.0)
- Version lista: **1.9.89 (versionCode 142)**, tag **v1.9.89** creado y publicado.
- El build de F-Droid compila **desde el codigo fuente** en el tag y firma con
  **su propia clave**. La firma del autor es condicional: si no existe
  `android/app/botmp3-release.jks`, el APK sale sin firmar y F-Droid lo firma.

## 1. Fork del repositorio de F-Droid
1. Entra en https://gitlab.com/fdroid/fdroiddata y pulsa **Fork** (crea tu copia).
2. Clona tu fork:
   git clone https://gitlab.com/TU_USUARIO/fdroiddata.git
   cd fdroiddata

## 2. Copia los ficheros de metadata
Desde el repositorio de BotMp3:
- `fdroid/com.botmp3.app.yml`  ->  `metadata/com.botmp3.app.yml`
- (opcional) descripciones e iconos: F-Droid lee ya
  `fastlane/metadata/android/<idioma>/` del repositorio de BotMp3, asi que no
  hace falta duplicarlas; si el revisor las pide, se pueden copiar a
  `metadata/com.botmp3.app/<idioma>/`.

## 3. Comprueba y crea el merge request
    cd fdroiddata
    cp /ruta/al/repo/BotMp3/fdroid/com.botmp3.app.yml metadata/com.botmp3.app.yml
    git checkout -b botmp3-1.9.89
    git add metadata/com.botmp3.app.yml
    git commit -m "New app: BotMp3 (com.botmp3.app)"
    git push origin botmp3-1.9.89
Despues abre el MR en GitLab hacia `fdroid/fdroiddata` (rama `master`).

## 4. Que revisara F-Droid (y como estamos)
| Requisito | Estado |
|---|---|
| Codigo abierto (GPL-3.0) | OK |
| Compila sin el keystore del autor | OK (firma condicional) |
| Sin anuncios ni rastreo | OK |
| Red solo cuando el usuario usa la IA | OK (declarado `NonFreeNet` por los proveedores de IA) |
| Version/tag coherentes | OK (`v1.9.89` / 142) |
| Sin dependencias binarias privativas | OK (solo plugins open source) |
| Reproducibilidad | Lockfile incluido (`pubspec.lock`) |

## 5. Tras la aceptacion
- F-Droid hara el build automatico del tag; si falla por la version de Flutter
  del `srclibs`, el revisor ajusta el numero (Flutter de F-Droid suele ir por
  detras). Se puede cambiar el `srclibs: - flutter@X.Y.Z` a la version que
  tengan disponible: el codigo compila con Flutter estable >= 3.24.
- Las futuras versiones se publican solas (AutoUpdateMode: Version + Tags):
  basta con crear el tag `vX.Y.Z` y actualizar `CurrentVersion`.