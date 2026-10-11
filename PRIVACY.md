# Privacidad de BotMp3

**Resumen: BotMp3 no recopila nada.** No hay cuentas, ni anuncios, ni analítica, ni
rastreadores. Todo lo que hace la app ocurre en tu dispositivo, salvo las conexiones que
tú mismo actives.

## Qué se guarda y dónde

| Dato | Dónde vive | Sale del dispositivo |
|---|---|---|
| Biblioteca (canciones, metadatos, etiquetas) | Almacenamiento privado de la app | No |
| Listas de reproducción y favoritos | Almacenamiento privado de la app | No |
| Historial de reproducciones (ranking) | Almacenamiento privado de la app | No |
| Carátulas (originales y editadas) | Almacenamiento privado de la app | No |
| Ajustes (tema, cristal, tendencias…) | Almacenamiento privado de la app | No |
| **Claves de API de IA** | Cifradas con el **Android Keystore** | No |

La app **no** pide nombre, correo, teléfono, ubicación ni identificadores de publicidad.

## Conexiones a internet (opcionales y solo cuando tú las usas)

1. **Proveedor de IA** (OpenAI, DeepSeek, Google Gemini o Anthropic Claude): cuando
   pides una recomendación, una lista, una búsqueda inteligente o un comando, se envía
   el texto que escribes y los metadatos de las canciones necesarios para responder
   (título, artista, género, año). **Nunca se envía el audio ni archivos de tu música.**
   Está desactivado hasta que tú añades una clave.
2. **Lista de tendencias**: al abrir la pantalla de tendencias se descarga la lista de
   canciones más escuchadas de un **servicio público** (listas de éxitos de Apple). Es
   una descarga sin datos tuyos: no se envía nada.

Ninguna de las dos se usa si no la activas, y la app funciona al 100 % sin conexión.

## Permisos y para qué se usan

| Permiso | Para qué |
|---|---|
| Leer audio (`READ_MEDIA_AUDIO` / `READ_EXTERNAL_STORAGE`) | Buscar tu música en el dispositivo |
| Notificaciones (`POST_NOTIFICATIONS`) | Notificación de reproducción y avisos de tendencias |
| Servicio en primer plano (`FOREGROUND_SERVICE*`) | Seguir reproduciendo con la pantalla apagada |
| Internet (`INTERNET`, `ACCESS_NETWORK_STATE`) | Solo las dos conexiones opcionales de arriba |
| Grabación de voz (`RECORD_AUDIO`) | Solo si usas funciones de voz |
| Arranque (`RECEIVE_BOOT_COMPLETED`) | Reprogramar el aviso diario de tendencias |

## Tus derechos

Como no se recopila nada, no hay nada que exportar ni que borrar en un servidor:
**desinstalar la app elimina todos tus datos** (biblioteca, listas, historial y claves).

## Contacto

Para cualquier duda sobre privacidad: pandamanrd@gmail.com
