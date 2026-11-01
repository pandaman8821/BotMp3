# Enviar BotMp3 a F-Droid (gratis)

## Requisitos
1. Cuenta gratuita en https://gitlab.com
2. Nada mas: F-Droid compila el proyecto desde el codigo (GPL-3.0) y lo firma con su clave.

## Pasos
1. Entra en https://gitlab.com/fdroid/fdroiddata
2. Pulsa **Fork** (bifurca el repo a tu cuenta).
3. En tu fork, sube el archivo `fdroid/com.botmp3.app.yml` a la carpeta `metadata/`.
4. Crea una rama: `add-botmp3` y haz **commit**.
5. Abre un **Merge Request** contra `fdroid/fdroiddata` con titulo:
   `New app: BotMp3 (com.botmp3.app)`
6. En la descripcion del MR pega:

> BotMp3 es un reproductor de musica offline con asistente de IA opcional.
> - Sin anuncios, sin cuentas, sin rastreo.
> - 10 idiomas, ecualizador de 5 bandas, widget, modo coche, listas y ranking.
> - La IA usa la clave del propio usuario (DeepSeek, Gemini, OpenAI o Claude); es opcional.
> - Codigo: GPL-3.0. Solo usa dependencias open source.

7. Espera la revision (semanas). El robot ejecutara la compilacion; si falla, copia el error en el MR y avisame para corregir el YAML.

## Notas
- La version publicada en F-Droid la firma F-Droid, no tu keystore: no podras actualizar por encima con tu APK (hay que desinstalar e instalar la de F-Droid).
- El YAML asume `subdir: BotMp3` (el proyecto Flutter esta dentro de la carpeta BotMp3 del repo).
- Si cambias la version, actualiza `versionName`, `versionCode`, `commit` y `CurrentVersion`.