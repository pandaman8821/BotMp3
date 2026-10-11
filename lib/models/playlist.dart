/// Lista de reproducción personalizable (creación ilimitada).
class Playlist {
  Playlist({
    required this.id,
    required this.name,
    this.description = '',
    List<String>? songIds,
    this.coverPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isAiGenerated = false,
    this.aiPrompt,
  })  : songIds = songIds ?? <String>[],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String name;
  final String description;

  /// Ids de las canciones; el orden de la lista define el orden de reproducción.
  final List<String> songIds;

  /// Carátula propia de la lista (opcional).
  final String? coverPath;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// True si la lista la creó el agente IA (se muestra con una insignia).
  final bool isAiGenerated;

  /// Prompt original usado por la IA para generarla (queda guardado).
  final String? aiPrompt;

  int get length => songIds.length;

  Playlist copyWith({
    String? name,
    String? description,
    List<String>? songIds,
    Object? coverPath = _unsetCover,
    DateTime? updatedAt,
    bool? isAiGenerated,
    String? aiPrompt,
  }) {
    return Playlist(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      songIds: songIds ?? this.songIds,
      coverPath: identical(coverPath, _unsetCover) ? this.coverPath : coverPath as String?,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      aiPrompt: aiPrompt ?? this.aiPrompt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'description': description,
        'songIds': songIds,
        'coverPath': coverPath,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isAiGenerated': isAiGenerated,
        'aiPrompt': aiPrompt,
      };

  static Playlist fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Lista sin nombre').toString(),
      description: (json['description'] ?? '').toString(),
      songIds: (json['songIds'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic id) => id.toString())
          .toList(),
      coverPath: json['coverPath']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      isAiGenerated: json['isAiGenerated'] == true,
      aiPrompt: json['aiPrompt']?.toString(),
    );
  }

  /// Formato de exportación/importación JSON (portable entre dispositivos).
  Map<String, dynamic> toExportJson() => <String, dynamic>{
        'format': 'botmp3.playlist',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'name': name,
        'description': description,
        'isAiGenerated': isAiGenerated,
        'aiPrompt': aiPrompt,
        'songs': songIds,
        'songsDetail': <Map<String, dynamic>>[],
      };

  @override
  bool operator ==(Object other) => other is Playlist && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

const Object _unsetCover = Object();
