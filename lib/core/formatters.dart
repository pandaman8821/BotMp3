import 'dart:math' as math;

/// Utilidades de formato y comparación de texto usadas en toda la app.
class Formatters {
  const Formatters._();

  /// 3:07 · 12:45 · 1:02:33
  static String duration(Duration? value) {
    if (value == null || value.inMilliseconds <= 0) return '--:--';
    final int totalSeconds = value.inSeconds;
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;
    final String mm = minutes.toString().padLeft(hours > 0 ? 2 : 1, '0');
    final String ss = seconds.toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$mm:$ss' : '$mm:$ss';
  }

  static String durationFromMs(int milliseconds) =>
      duration(Duration(milliseconds: milliseconds));

  static String bytes(int value) {
    if (value <= 0) return '0 B';
    const List<String> units = <String>['B', 'KB', 'MB', 'GB'];
    double size = value.toDouble();
    int unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return '${size.toStringAsFixed(unit == 0 ? 0 : 1)} ${units[unit]}';
  }

  /// Texto normalizado para búsquedas: sin tildes, minúsculas y sin signos.
  static String normalize(String input) {
    const String withAccents = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const String withoutAccents = 'aaaaaeeeeiiiiooooouuuunc';
    final StringBuffer buffer = StringBuffer();
    final String lower = input.toLowerCase();
    for (int i = 0; i < lower.length; i++) {
      final String char = lower[i];
      final int index = withAccents.indexOf(char);
      if (index >= 0) {
        buffer.write(withoutAccents[index]);
      } else if (RegExp(r'[a-z0-9 ]').hasMatch(char)) {
        buffer.write(char);
      } else {
        buffer.write(' ');
      }
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Puntaje de similitud 0..1 entre dos textos (para emparejar sugerencias de IA
  /// con las canciones locales).
  static double similarity(String a, String b) {
    final String left = normalize(a);
    final String right = normalize(b);
    if (left.isEmpty || right.isEmpty) return 0;
    if (left == right) return 1;

    final Set<String> leftTokens = left.split(' ').where((String t) => t.length > 2).toSet();
    final Set<String> rightTokens = right.split(' ').where((String t) => t.length > 2).toSet();
    if (leftTokens.isEmpty || rightTokens.isEmpty) {
      return left.contains(right) || right.contains(left) ? 0.6 : 0;
    }
    final Set<String> common = leftTokens.intersection(rightTokens);
    final double overlap = (2 * common.length) / (leftTokens.length + rightTokens.length);
    if (left.contains(right) || right.contains(left)) {
      return math.max(overlap, 0.75);
    }
    return overlap;
  }

  /// Limpia el nombre de archivo típico: "01 - Artista - Título (Remix) [320kbps]".
  static String prettyFileName(String fileName) {
    String name = fileName;
    final int dot = name.lastIndexOf('.');
    if (dot > 0) name = name.substring(0, dot);
    name = name.replaceAll(RegExp(r'[_]+'), ' ');
    // Quita prefijos de pista: "01 - ", "01. ", "1-"
    name = name.replaceFirst(RegExp(r'^\s*\d{1,3}\s*[-.)]\s*'), '');
    // Quita sufijos de calidad/ruido
    name = name.replaceAll(
      RegExp(
        r'\s*[\[(](official|video|lyrics?|audio|hd|hq|4k|320\s?kbps|128\s?kbps|remaster(ed)?|mv|clip)[\])]\s*',
        caseSensitive: false,
      ),
      ' ',
    );
    return name.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Intenta separar "Artista - Título" del nombre de archivo.
  static (String artist, String title) guessArtistAndTitle(String fileName) {
    final String cleaned = prettyFileName(fileName);
    final List<String> parts = cleaned.split(' - ');
    if (parts.length >= 2) {
      final String artist = parts.first.trim();
      final String title = parts.sublist(1).join(' - ').trim();
      if (artist.isNotEmpty && title.isNotEmpty) return (artist, title);
    }
    return ('Artista desconocido', cleaned.isEmpty ? 'Sin título' : cleaned);
  }

  static String relativeDate(DateTime? date) {
    if (date == null) return '';
    final Duration diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'ahora mismo';
    if (diff.inHours < 1) return 'hace ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'hace ${diff.inHours} h';
    if (diff.inDays < 30) return 'hace ${diff.inDays} d';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
