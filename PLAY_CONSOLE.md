# Guia para publicar BotMp3 en Play Console

## 1. Antes de subir
- AAB listo: `BotMp3-1.9.58.aab` (firmado, 30,5 MB, versionCode 111).
- Ficha: `fastlane/metadata/android/` con **10 idiomas** (titulo <= 30, descripcion corta <= 80).
- Graficos: `en-US/images/icon.png` (512x512) y `en-US/images/featureGraphic.png` (1024x500).
- Capturas: anadir al menos **2 de telefono** en `en-US/images/phoneScreenshots/`.

## 2. Politica de privacidad (obligatoria)
Publica `PRIVACY.md` como pagina web (GitHub Pages) y pega la URL en Play.
Pasos: repo -> Settings -> Pages -> Branch main /docs -> guardar. Copia `PRIVACY.md` a `docs/privacy.md`.

## 3. Data safety (respuestas sugeridas)
- Recopila o comparte datos: **No** (la app no envia datos a servidores de BotMp3).
- Datos compartidos con terceros: **con el proveedor de IA que el usuario elige** (titulo/artista/contexto) -> si eliges declararlo, marca "Informacion de la app" y "Contenido de audio? No".
- Datos cifrados en transito: **Si** (HTTPS obligatorio, cleartext desactivado).
- El usuario puede solicitar borrado: **Si** (borrar datos desde Ajustes).
- Recogida de ubicacion / contactos / SMS: **No**.
- Microfono: **si, solo bajo demanda** para dictado; audio **no se almacena** (efimero).

## 4. Clasificacion de contenido (IARC)
- Violencia, sexo, drogas, apuestas: **No**.
- Compras dentro de la app: **No**.
- Anuncios: **No**.
- Ubicacion compartida: **No**.
- Contenido generado por usuarios: **No** (las respuestas de IA vienen del proveedor elegido).
- Riesgo: app de musica -> clasificacion habitual **PEGI 3 / Everyone**.

## 5. Acceso para revisores (importante)
La IA necesita una clave del usuario. En "Instrucciones de acceso" escribe:
> La app funciona sin cuenta. Las funciones de IA requieren una clave propia (DeepSeek, Gemini, OpenAI o Claude) que se configura en Ajustes > IA. Sin clave, el reproductor, listas, ecualizador y widget funcionan al completo.

## 6. Declaraciones tecnicas
- Foreground service: reproduccion de audio (mediaPlayback) -> justificacion: "reproduccion continua con controles en notificacion".
- Permiso de microfono: solo dictado por voz iniciado por el usuario.
- Firma: Play App Signing con la clave de subida (tu keystore).

## 7. Ficha por idioma
Titulos y descripciones ya estan en los 10 idiomas. Revisa que el titulo no supere 30 caracteres (ya verificado).