import '../routing/routing.dart';

class MissionItem {
  const MissionItem({
    required this.name,
    this.qty = 1,
    this.unit = '',
    this.massKg = 0,
  });

  final String name;
  final double qty;
  final String unit;
  final double massKg;

  double get totalKg => qty * massKg;

  factory MissionItem.fromJson(Map<String, dynamic> j) => MissionItem(
        name: j['name'] as String? ?? '',
        qty: (j['qty'] as num? ?? 1).toDouble(),
        unit: j['unit'] as String? ?? '',
        massKg: (j['mass_kg'] as num? ?? 0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'qty': qty,
        'unit': unit,
        'mass_kg': massKg,
      };
}

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

  final String id;
  final String name;
  final String siteId;
  final List<Objective> objectives;
  final List<MissionItem> consumables;
  final List<MissionItem> equipment;
  final String notes;
  final String exitMode;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get declaredMassKg {
    var sum = 0.0;
    for (final c in consumables) {
      sum += c.totalKg;
    }
    for (final e in equipment) {
      sum += e.totalKg;
    }
    return sum;
  }

  Mission copyWith({
    String? id,
    String? name,
    String? siteId,
    List<Objective>? objectives,
    List<MissionItem>? consumables,
    List<MissionItem>? equipment,
    String? notes,
    String? exitMode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Mission(
        id: id ?? this.id,
        name: name ?? this.name,
        siteId: siteId ?? this.siteId,
        objectives: objectives ?? this.objectives,
        consumables: consumables ?? this.consumables,
        equipment: equipment ?? this.equipment,
        notes: notes ?? this.notes,
        exitMode: exitMode ?? this.exitMode,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory Mission.fromJson(Map<String, dynamic> j) => Mission(
        id: j['id'] as String,
        name: j['name'] as String,
        siteId: j['site_id'] as String,
        objectives: [
          for (final o in (j['objectives'] as List? ?? const []))
            Objective.fromJson(o as Map<String, dynamic>),
        ],
        consumables: [
          for (final c in (j['consumables'] as List? ?? const []))
            MissionItem.fromJson(c as Map<String, dynamic>),
        ],
        equipment: [
          for (final e in (j['equipment'] as List? ?? const []))
            MissionItem.fromJson(e as Map<String, dynamic>),
        ],
        notes: j['notes'] as String? ?? '',
        exitMode: j['exit_mode'] as String? ?? 'foot',
        createdAt: DateTime.parse(j['created_at'] as String).toUtc(),
        updatedAt: DateTime.parse(j['updated_at'] as String).toUtc(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'site_id': siteId,
        'objectives': [for (final o in objectives) o.toJson()],
        'consumables': [for (final c in consumables) c.toJson()],
        'equipment': [for (final e in equipment) e.toJson()],
        'notes': notes,
        'exit_mode': exitMode,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };
}

class MissionBook {
  MissionBook(List<Mission> missions, this.currentId)
      : _missions = List<Mission>.of(missions);

  factory MissionBook.single(Mission m) => MissionBook([m], m.id);

  final List<Mission> _missions;
  String currentId;
  int _seq = 0;

  List<Mission> get missions => List.unmodifiable(_missions);

  Mission get current => byId(currentId) ?? _missions.first;

  Mission? byId(String id) {
    for (final m in _missions) {
      if (m.id == id) return m;
    }
    return null;
  }

  void replaceCurrent(Mission m) {
    final idx = _missions.indexWhere((e) => e.id == currentId);
    if (idx >= 0) {
      _missions[idx] = m;
    } else {
      _missions.add(m);
    }
    currentId = m.id;
  }

  String _nextId(DateTime ts) {
    while (true) {
      _seq++;
      final candidate = 'm_${ts.millisecondsSinceEpoch}_$_seq';
      if (byId(candidate) == null) return candidate;
    }
  }

  Mission create({
    required String name,
    required String siteId,
    List<Objective> objectives = const [],
    DateTime? now,
  }) {
    final ts = (now ?? DateTime.now()).toUtc();
    final m = Mission(
      id: _nextId(ts),
      name: name,
      siteId: siteId,
      objectives: List<Objective>.of(objectives),
      createdAt: ts,
      updatedAt: ts,
    );
    _missions.add(m);
    currentId = m.id;
    return m;
  }

  Mission duplicate(String id, String name, {DateTime? now}) {
    final src = byId(id) ?? current;
    final ts = (now ?? DateTime.now()).toUtc();
    final copy = Mission(
      id: _nextId(ts),
      name: name,
      siteId: src.siteId,
      objectives: List<Objective>.of(src.objectives),
      consumables: List<MissionItem>.of(src.consumables),
      equipment: List<MissionItem>.of(src.equipment),
      notes: src.notes,
      exitMode: src.exitMode,
      createdAt: ts,
      updatedAt: ts,
    );
    _missions.add(copy);
    currentId = copy.id;
    return copy;
  }

  bool open(String id) {
    if (byId(id) == null) return false;
    currentId = id;
    return true;
  }

  bool delete(String id) {
    if (_missions.length <= 1) return false;
    final idx = _missions.indexWhere((m) => m.id == id);
    if (idx < 0) return false;
    _missions.removeAt(idx);
    if (currentId == id) {
      var latest = _missions.first;
      for (final m in _missions.skip(1)) {
        if (m.updatedAt.isAfter(latest.updatedAt)) {
          latest = m;
        }
      }
      currentId = latest.id;
    }
    return true;
  }

  Mission? latestForSite(String siteId) {
    Mission? best;
    for (final m in _missions) {
      if (m.siteId != siteId) continue;
      if (best == null || m.updatedAt.isAfter(best.updatedAt)) {
        best = m;
      }
    }
    return best;
  }

  factory MissionBook.fromJson(Map<String, dynamic> j) {
    final list = [
      for (final m in (j['missions'] as List))
        Mission.fromJson(m as Map<String, dynamic>),
    ];
    if (list.isEmpty) {
      throw const FormatException('Empty missions in MissionBook');
    }
    final cur = j['current'] as String? ?? list.first.id;
    return MissionBook(list, cur);
  }

  Map<String, dynamic> toJson() => {
        'version': 1,
        'current': currentId,
        'missions': [for (final m in _missions) m.toJson()],
      };
}
