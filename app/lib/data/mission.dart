import '../routing/routing.dart';

/// Un consumible o un equipo de la misión. Lo escribe el usuario: no es un dato de la NASA ni entra en el cálculo de rutas.
class MissionItem {
  const MissionItem({required this.name, this.qty = 1, this.unit = '', this.massKg = 0.0});

  factory MissionItem.fromJson(Map<String, dynamic> j) => MissionItem(
        name: (j['name'] as String?) ?? '',
        qty: ((j['qty'] as num?) ?? 1).toDouble(),
        unit: (j['unit'] as String?) ?? '',
        massKg: ((j['mass_kg'] as num?) ?? 0).toDouble(),
      );

  final String name;
  final double qty;
  final String unit;

  /// Masa de una unidad en kilogramos; 0 si no se declaró.
  final double massKg;

  /// Masa declarada de todas las unidades.
  double get totalKg => qty * massKg;

  MissionItem copyWith({String? name, double? qty, String? unit, double? massKg}) =>
      MissionItem(name: name ?? this.name, qty: qty ?? this.qty, unit: unit ?? this.unit, massKg: massKg ?? this.massKg);

  Map<String, dynamic> toJson() => {'name': name, 'qty': qty, 'unit': unit, 'mass_kg': massKg};
}

/// Una misión guardada: un sitio, uno o más objetivos (de los que el sistema calcula las rutas), consumibles, equipo y notas.
class Mission {
  const Mission({
    required this.id,
    required this.name,
    required this.siteId,
    this.objectives = const [],
    this.consumables = const [],
    this.equipment = const [],
    this.notes = '',
    this.exitMode = 'foot',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Mission.fromJson(Map<String, dynamic> j) => Mission(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? '',
        siteId: j['site_id'] as String,
        objectives: [for (final o in (j['objectives'] as List? ?? const [])) Objective.fromJson(o as Map<String, dynamic>)],
        consumables: [for (final o in (j['consumables'] as List? ?? const [])) MissionItem.fromJson(o as Map<String, dynamic>)],
        equipment: [for (final o in (j['equipment'] as List? ?? const [])) MissionItem.fromJson(o as Map<String, dynamic>)],
        notes: (j['notes'] as String?) ?? '',
        exitMode: (j['exit_mode'] as String?) ?? 'foot',
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );

  final String id;
  final String name;

  /// Id del sitio (`assets/sites.json`). Los objetivos están en las coordenadas locales de ese sitio.
  final String siteId;
  final List<Objective> objectives;
  final List<MissionItem> consumables;
  final List<MissionItem> equipment;
  final String notes;

  /// Nombre de un valor de `ExitMode` (`foot`, `rover`, `support`, `pair`, `byObjective`).
  final String exitMode;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Masa declarada de consumibles y equipo, en kilogramos.
  double get declaredMassKg => [...consumables, ...equipment].fold(0.0, (a, i) => a + i.totalKg);

  Mission copyWith({
    String? name,
    String? siteId,
    List<Objective>? objectives,
    List<MissionItem>? consumables,
    List<MissionItem>? equipment,
    String? notes,
    String? exitMode,
    DateTime? updatedAt,
  }) =>
      Mission(
        id: id,
        name: name ?? this.name,
        siteId: siteId ?? this.siteId,
        objectives: objectives ?? this.objectives,
        consumables: consumables ?? this.consumables,
        equipment: equipment ?? this.equipment,
        notes: notes ?? this.notes,
        exitMode: exitMode ?? this.exitMode,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'site_id': siteId,
        'objectives': [for (final o in objectives) o.toJson()],
        'consumables': [for (final i in consumables) i.toJson()],
        'equipment': [for (final i in equipment) i.toJson()],
        'notes': notes,
        'exit_mode': exitMode,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };
}

/// Las misiones guardadas y la que está abierta. Siempre hay al menos una.
class MissionBook {
  MissionBook(List<Mission> missions, this.currentId) : missions = List.of(missions) {
    if (this.missions.isEmpty) throw ArgumentError('Una libreta de misiones necesita al menos una misión');
    if (byId(currentId) == null) currentId = this.missions.first.id;
  }

  /// Libreta con una sola misión.
  factory MissionBook.single(Mission m) => MissionBook([m], m.id);

  factory MissionBook.fromJson(Map<String, dynamic> j) {
    final list = [for (final m in j['missions'] as List) Mission.fromJson(m as Map<String, dynamic>)];
    return MissionBook(list, (j['current'] as String?) ?? list.first.id);
  }

  static const int version = 1;

  final List<Mission> missions;
  String currentId;
  int _seq = 0;

  Mission get current => byId(currentId)!;

  Mission? byId(String id) {
    for (final m in missions) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// La misión de ese sitio modificada más recientemente, o null.
  Mission? latestForSite(String siteId) {
    Mission? best;
    for (final m in missions) {
      if (m.siteId == siteId && (best == null || m.updatedAt.isAfter(best.updatedAt))) best = m;
    }
    return best;
  }

  String _newId(DateTime now) {
    while (true) {
      final id = 'm${now.microsecondsSinceEpoch.toRadixString(36)}${_seq++}';
      if (byId(id) == null) return id;
    }
  }

  /// Crea una misión y la abre.
  Mission create({required String name, required String siteId, List<Objective> objectives = const [], String exitMode = 'foot', DateTime? now}) {
    final t = now ?? DateTime.now();
    final m = Mission(id: _newId(t), name: name, siteId: siteId, objectives: objectives, exitMode: exitMode, createdAt: t, updatedAt: t);
    missions.add(m);
    currentId = m.id;
    return m;
  }

  /// Copia una misión con otro nombre y la abre.
  Mission duplicate(String id, String name, {DateTime? now}) {
    final src = byId(id)!;
    final t = now ?? DateTime.now();
    final m = Mission(
      id: _newId(t),
      name: name,
      siteId: src.siteId,
      objectives: List.of(src.objectives),
      consumables: List.of(src.consumables),
      equipment: List.of(src.equipment),
      notes: src.notes,
      exitMode: src.exitMode,
      createdAt: t,
      updatedAt: t,
    );
    missions.add(m);
    currentId = m.id;
    return m;
  }

  /// Borra una misión. Devuelve falso si es la única. Si era la abierta, abre la modificada más recientemente.
  bool delete(String id) {
    if (missions.length <= 1 || byId(id) == null) return false;
    missions.removeWhere((m) => m.id == id);
    if (currentId == id) {
      final sorted = [...missions]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      currentId = sorted.first.id;
    }
    return true;
  }

  bool open(String id) {
    if (byId(id) == null) return false;
    currentId = id;
    return true;
  }

  /// Sustituye la misión abierta por una versión nueva (mismo id).
  void replaceCurrent(Mission m) {
    final i = missions.indexWhere((x) => x.id == currentId);
    missions[i] = m;
  }

  Map<String, dynamic> toJson() => {'version': version, 'current': currentId, 'missions': [for (final m in missions) m.toJson()]};
}
