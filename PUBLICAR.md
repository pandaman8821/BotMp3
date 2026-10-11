# 🚀 Publicar BotMp3 — lo que ya está hecho y lo que falta

## ⚡ Opción rápida: un solo doble clic

Si usas **GitLab** y no quieres teclear comandos:

1. Crea un **token** en GitLab: *tu avatar ▸ Edit profile ▸ Access tokens ▸ Add new token*, con el permiso **`api`** y caducidad corta (1 día).
2. Haz **doble clic en `publicar.cmd`** (está en esta carpeta).
3. Pega el token cuando lo pida (no se ve mientras escribes).

El script lo hace todo: **crea el repositorio**, **sube el código y la etiqueta**, elimina el token del remoto (no se guarda), **copia el texto de la petición al portapapeles** y **abre la página de F-Droid**. Solo tienes que pegar (Ctrl+V) y pulsar *Enviar*. Después, **revoca el token**.

> También se puede ejecutar con parámetros: `.\publicar.ps1 -Usuario pandamanlab -Proyecto BotMp3`

## ✅ Hecho por mí (no tienes que tocar nada)

| Elemento | Estado |
|---|---|
| Repositorio **git local** con el código | ✅ Inicializado y con el **primer commit** hecho |
| Etiqueta de versión | ✅ `v1.4.3` creada |
| Licencia | ✅ `LICENSE` (GPL-3.0-or-later) |
| Privacidad | ✅ `PRIVACY.md` (sin recopilación de datos) |
| Metadatos para F-Droid | ✅ `fastlane/metadata/android/{es-ES,en-US}/` (título, descripción corta y larga, changelogs, icono y capturas) |
| Receta de compilación | ✅ `metadata/com.botmp3.app.yml` (Flutter, NDK r27c, antifunción `NonFreeNet`) |
| Texto de la petición RFP | ✅ `RFP.md` (listo para pegar) |
| Firma y secretos fuera del repositorio | ✅ `.gitignore` excluye `*.jks` y `local.properties` |
| APK compilada y verificada | ✅ `BotMp3-1.4.3-release.apk` |

## ⚠️ Solo puedes hacerlo tú (3 pasos, ~10 minutos)

Requieren **tu cuenta**, por eso no puedo hacerlo desde aquí. Son tres pasos muy cortos:

### Paso 1 — Crear un repositorio **vacío**

En GitHub, GitLab o Codeberg crea un repositorio llamado `BotMp3`
(**sin** README, **sin** licencia y **sin** .gitignore: vacío del todo).

### Paso 2 — Subir el código

Abre una terminal **en esta carpeta** (`BotMp3`) y pega estas tres líneas,
cambiando `TU-USUARIO` por tu nombre de usuario:

```bash
git remote add origin https://gitlab.com/TU-USUARIO/BotMp3.git
git push -u origin main
git push origin v1.4.3
```

Si te pide identificarte, usa tu usuario y un **token de acceso personal**
(en GitHub: *Settings ▸ Developer settings ▸ Personal access tokens*) como contraseña.

### Paso 3 — Enviar la petición a F-Droid

Entra en **https://gitlab.com/fdroid/rfp/-/work_items/new** y pega el contenido de
**`RFP.md`** (título y cuerpo). Eso es todo: un voluntario de F-Droid se encarga de
escribir y probar la receta definitiva.

## 📦 Mientras esperas

- Puedes repartir tu APK en la sección **Releases** del repositorio (GitHub la crea sola
  al subir un archivo a un *tag*).
- Si quieres distribución inmediata sin esperar a F-Droid, se puede montar un
  **repositorio F-Droid propio**; dímelo y te dejo el comando preparado.

## 🔄 Para publicar una versión nueva

```bash
# 1) Sube la versión en pubspec.yaml (por ejemplo 1.5.0+15)
# 2) Compila y verifica
# 3) Publica
git add .
git commit -m "BotMp3 1.5.0"
git tag v1.5.0
git push && git push --tags
```

F-Droid detecta la etiqueta nueva automáticamente (`UpdateCheckMode: Tags`) y publica la
actualización; los usuarios la reciben como cualquier otra app.

## 🆘 Si algo se atasca

Dime en qué paso te quedas (o pásame la captura del error) y lo resolvemos. Durante la
sesión ya instalamos Git y compilamos la app desde cero, así que cualquier problema de
entorno lo puedo reproducir y arreglar aquí.
