# Política de privacidad de BotMp3

*Última actualización: 15 de noviembre de 2026 · Versión de la app: 1.9.126 o posterior*

**Resumen:** BotMp3 es un reproductor de música local. No tiene cuentas, ni anuncios, ni
analítica, ni rastreadores. Tu música y tus datos se quedan en tu dispositivo. Solo sale
información hacia internet cuando **tú** usas una función que lo necesita, y nunca se envía
el audio de tus canciones.

## 1. Qué se guarda y dónde

| Dato | Dónde se guarda | ¿Sale del dispositivo? |
|---|---|---|
| Biblioteca (canciones, metadatos, etiquetas) | Almacenamiento privado de la app | No |
| Listas de reproducción y favoritos | Almacenamiento privado de la app | No |
| Historial de reproducciones (ranking y estadísticas) | Almacenamiento privado de la app | No |
| Carátulas (originales y editadas) | Almacenamiento privado de la app | No |
| Conversación con la IA | Almacenamiento privado de la app | Solo al proveedor de IA (ver punto 2) |
| Ajustes (tema, cristal, tendencias, ecualizador…) | Almacenamiento privado de la app | No |
| **Claves de API de IA** | Cifradas con el **Android Keystore** | Solo al proveedor al que pertenecen |

La app **no** pide nombre, correo, teléfono, ubicación, contactos ni identificadores de
publicidad. Las copias de seguridad en la nube de Android están desactivadas para estos datos.

## 2. Conexiones a internet (opcionales)

| Función | A quién se conecta | Qué se envía |
|---|---|---|
| **Asistente de IA** (chat, recomendaciones, Modo DJ, autocompletar datos) | El proveedor que elijas: OpenAI, DeepSeek, Google Gemini o Anthropic Claude | El texto que escribes y el título, artista, álbum, género y año de las canciones necesarias para responder. Se usa **tu propia clave de API** |
| **Lista de modelos de IA** | El mismo proveedor de IA | Solo tu clave, para listar los modelos disponibles |
| **Tendencias** | Listas públicas de éxitos de Apple (`rss.applemarketingtools.com`) | El país elegido. Ningún dato personal |
| **Letras sincronizadas** | LRCLIB (`lrclib.net`) | Título, artista y duración de la canción |
| **Buscar carátulas** | Apple iTunes Search (`itunes.apple.com`) y Deezer (`api.deezer.com`) | Título, artista y álbum de la canción |

**Asistente de IA:** antes del primer uso, la app muestra un aviso y **no envía nada hasta
que lo aceptas**. Puedes retirar el consentimiento cuando quieras desde el icono de
privacidad de la pantalla de IA. Lo que envías queda sujeto a la política de privacidad del
proveedor que elijas:

- OpenAI: <https://openai.com/policies/privacy-policy>
- DeepSeek: <https://www.deepseek.com/> (enlace «Privacy Policy» al pie de la página)
- Google Gemini: <https://policies.google.com/privacy>
- Anthropic Claude: <https://www.anthropic.com/legal/privacy>

Las respuestas de la IA se generan automáticamente y pueden contener errores. Cada respuesta
tiene un botón **Reportar** para avisarnos de contenido ofensivo o dañino.

Si no usas estas funciones, la app funciona al 100 % sin conexión.

## 3. Permisos y para qué se usan

| Permiso | Para qué |
|---|---|
| Leer audio (`READ_MEDIA_AUDIO` / `READ_EXTERNAL_STORAGE` hasta Android 12) | Encontrar tu música en el dispositivo |
| Notificaciones (`POST_NOTIFICATIONS`) | Controles de reproducción y aviso diario de tendencias |
| Servicio en primer plano (`FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`) y `WAKE_LOCK` | Seguir reproduciendo con la pantalla apagada |
| Internet (`INTERNET`, `ACCESS_NETWORK_STATE`) | Solo para las funciones opcionales del punto 2 |
| Arranque (`RECEIVE_BOOT_COMPLETED`) | Volver a programar el aviso diario de tendencias |

BotMp3 **no** usa el micrófono, la cámara ni la ubicación.

### Audios de otras apps

La opción **Importar audios de apps y notas de voz** (WhatsApp, Telegram, grabadoras…)
está **desactivada por defecto**. Si la activas, esos audios se añaden a tu biblioteca
local y siguen sin salir del dispositivo.

## 4. Menores de edad

BotMp3 no está dirigida a menores de 13 años y no recopila datos de nadie a sabiendas.

## 5. Tus derechos y cómo borrar tus datos

Como no tenemos servidores ni cuentas, no guardamos ningún dato tuyo. Puedes:

- Borrar la conversación con la IA desde la pantalla de IA.
- Borrar tus claves de API desde **Ajustes ▸ IA**.
- Borrar todo **desinstalando la app** o desde *Ajustes de Android ▸ Apps ▸ BotMp3 ▸
  Almacenamiento ▸ Borrar datos*.

## 6. Cambios en esta política

Si la política cambia, se actualizará esta página y la fecha de arriba.

## 7. Contacto

Para cualquier duda sobre privacidad: **pandamanrd@gmail.com**
