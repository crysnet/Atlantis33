import 'dart:async';

import 'package:flutter/material.dart';

import '../data/mission.dart';
import '../data/mission_store.dart';
import '../data/site_data.dart';
import '../data/site_registry.dart';
import '../routing/routing.dart';

/// Modo de salida: a pie, con rover aparcado en un punto de la ruta, a pie con un rover de apoyo en el hábitat, en pareja
/// con los objetivos repartidos entre los dos astronautas, o por objetivo (cada objetivo trae su transporte).
enum ExitMode { foot, rover, support, pair, byObjective }

/// Origen de una capa: medida, modelada o de ejemplo.
enum LayerKind { measured, modeled, example }

class LayerDef {
  const LayerDef(this.id, this.kind, this.tag, {this.hasData = true, this.hasOpacity = true});

  final String id;
  final LayerKind kind;

  /// Resolución o fuente corta, en la etiqueta de la capa.
  final String tag;
  final bool hasData;
  final bool hasOpacity;
}

class LayerState {
  LayerState(this.visible, this.opacity);

  bool visible;
  double opacity;
}

/// Ruta trazada entre dos puntos (`habitat` o cualquier objetivo).
class PlannedRoute {
  const PlannedRoute({required this.id, required this.fromId, required this.toId, required this.result});

  final String id;
  final String fromId;
  final String toId;
  final RouteResult result;
}

const List<LayerDef> kLayers = [
  LayerDef('optical', LayerKind.measured, 'HiRISE 0.25 m'),
  LayerDef('slope', LayerKind.modeled, '4 m'),
  LayerDef('curiosity', LayerKind.measured, 'MSL', hasOpacity: true),
  LayerDef('thermal', LayerKind.measured, 'THEMIS-IR 100 m'),
  LayerDef('minerals', LayerKind.example, 'CRISM', hasData: false),
  LayerDef('transit', LayerKind.modeled, 'TES 3.5 km'),
  LayerDef('thermal_night', LayerKind.measured, 'THEMIS-IR 100 m'),
  LayerDef('aqueous_pts', LayerKind.measured, 'Mars Trek'),
  LayerDef('hydrous_pts', LayerKind.measured, 'CRISM · OMEGA'),
  LayerDef('valleys', LayerKind.measured, 'Hynek 2010', hasOpacity: true),
  LayerDef('zones', LayerKind.measured, 'NASA EMC 2015'),
  LayerDef('names', LayerKind.measured, 'UAI · Trek'),
  LayerDef('craters', LayerKind.measured, 'Robbins ≥ 1 km'),
];

/// Estado de la aplicación: capas, objetivos, rutas calculadas y selección.
class AppModel extends ChangeNotifier {
  AppModel(this.data, {this.registry = SiteRegistry.empty, String? siteId, MissionBook? book, MissionStore? store})
      : siteId = siteId ?? (registry.defaultId.isEmpty ? 'meridiani_regional' : registry.defaultId),
        store = store ?? MemoryMissionStore(),
        objectives = List.of(book?.current.objectives ?? data.objectives) {
    for (final l in kLayers) {
      layers[l.id] = LayerState(_defaultVisible[l.id] ?? false, _defaultOpacity[l.id] ?? 1.0);
    }
    if (book != null) {
      this.book = book;
      exitMode = _parseMode(book.current.exitMode);
      selectedRoute = exitMode == ExitMode.pair ? 'pair1' : 'safe';
    } else {
      final now = DateTime.now();
      this.book = MissionBook.single(Mission(
        id: 'm${now.microsecondsSinceEpoch.toRadixString(36)}',
        name: _missionName(1),
        siteId: this.siteId,
        objectives: List.of(data.objectives),
        createdAt: now,
        updatedAt: now,
      ));
    }
    _nextId = _nextUserId();
  }

  static const _defaultVisible = {'optical': true, 'slope': true, 'curiosity': true, 'aqueous_pts': true, 'hydrous_pts': true, 'valleys': true};
  static const _defaultOpacity = {'optical': 1.0, 'slope': 0.4, 'curiosity': 0.9, 'thermal': 0.6, 'transit': 0.55, 'thermal_night': 0.6, 'valleys': 0.9};

  /// Datos del sitio abierto. Cambian al llamar a [switchSite].
  SiteData data;

  /// Misiones guardadas; la abierta es la que se ve y se edita. Cada cambio se guarda solo.
  late MissionBook book;
  final MissionStore store;
  Timer? _saveTimer;

  /// Sitios conocidos y el id del abierto.
  final SiteRegistry registry;
  String siteId;

  /// Verdadero mientras se carga otro sitio.
  bool switchingSite = false;
  final Map<String, LayerState> layers = {};
  List<Objective> objectives;
  Map<String, RouteResult> routes = {};
  bool computing = false;
  int computeMs = 0;
  String selectedRoute = 'safe';
  String? selectedObjective;
  bool addMode = false;

  /// Modo de salida (por defecto, a pie).
  ExitMode exitMode = ExitMode.foot;

  /// Resumen de la salida en pareja (solo en ese modo).
  PairResult? pairResult;
  int tab = 0;

  /// Sol de REMS y RAD que usa la pantalla de seguridad.
  late int envSol = data.environment.referenceSol;
  Locale locale = const Locale('en');
  int _gen = 0;
  int _nextId = 1;

  @override
  void dispose() {
    if (_saveTimer?.isActive ?? false) {
      _saveTimer!.cancel();
      store.save(book);
    }
    super.dispose();
  }

  /// Capas del panel para el sitio abierto: las que lista el registro o, si no lista ninguna, todas.
  List<LayerDef> get layerDefs {
    final ids = registry.byId(siteId)?.layers ?? const <String>[];
    return ids.isEmpty ? kLayers : [for (final l in kLayers) if (ids.contains(l.id)) l];
  }

  int get activeLayerCount => layerDefs.where((l) => layers[l.id]!.visible).length;

  /// Nombre del sitio abierto en el idioma actual; null si el registro no lo tiene.
  String? get siteLabel => registry.byId(siteId)?.name(locale.languageCode);

  static ExitMode _parseMode(String s) => ExitMode.values.firstWhere((e) => e.name == s, orElse: () => ExitMode.foot);

  String _missionName(int n) => locale.languageCode == 'es' ? 'Misión $n' : 'Mission $n';

  /// El siguiente número libre para los ids `uN` de los objetivos que crea el usuario.
  int _nextUserId() {
    var n = 0;
    for (final m in book.missions) {
      for (final o in m.objectives) {
        final v = o.id.startsWith('u') ? int.tryParse(o.id.substring(1)) : null;
        if (v != null && v > n) n = v;
      }
    }
    for (final o in objectives) {
      final v = o.id.startsWith('u') ? int.tryParse(o.id.substring(1)) : null;
      if (v != null && v > n) n = v;
    }
    return n + 1;
  }

  /// Copia el estado actual a la misión abierta y lo guarda poco después.
  void _persist() {
    book.replaceCurrent(book.current.copyWith(objectives: objectives, exitMode: exitMode.name, siteId: siteId, updatedAt: DateTime.now()));
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), () => store.save(book));
  }

  Future<void> _saveNow() {
    _saveTimer?.cancel();
    return store.save(book);
  }

  /// Carga los datos de un sitio y reinicia lo que depende de él (capas y sol de referencia). Falso si falla la carga.
  Future<bool> _enterSite(SiteEntry e) async {
    switchingSite = true;
    notifyListeners();
    try {
      final d = await SiteData.load(e.assetDir);
      data = d;
      siteId = e.id;
      envSol = d.environment.referenceSol;
      for (final l in kLayers) {
        layers[l.id] = LayerState(_defaultVisible[l.id] ?? false, _defaultOpacity[l.id] ?? 1.0);
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      switchingSite = false;
    }
  }

  /// Pone en pantalla la misión abierta: sus objetivos y su modo de salida.
  void _showMission() {
    final m = book.current;
    _gen++;
    objectives = List.of(m.objectives);
    exitMode = _parseMode(m.exitMode);
    selectedRoute = exitMode == ExitMode.pair ? 'pair1' : 'safe';
    routes = {};
    tracedRoutes = [];
    activeRouteId = null;
    routeStartId = 'habitat';
    pairResult = null;
    selectedObjective = null;
    addMode = false;
    _nextId = _nextUserId();
  }

  /// Abre la misión que la libreta tiene como actual: cambia de sitio si hace falta, recalcula y guarda.
  /// Falso si su sitio no está disponible o no se pudo cargar; el llamador deja la libreta como estaba.
  Future<bool> _openCurrentMission() async {
    final m = book.current;
    if (m.siteId != siteId) {
      final e = registry.byId(m.siteId);
      if (e == null || !e.available || !await _enterSite(e)) return false;
    }
    _showMission();
    await recompute();
    await _saveNow();
    return true;
  }

  /// Abre otro sitio del registro: carga sus datos y abre su misión más reciente (o una nueva con los objetivos de ejemplo).
  /// Devuelve falso si no se pudo (sitio desconocido, sin datos o error de carga); en ese caso se queda en el actual.
  Future<bool> switchSite(String id) async {
    final e = registry.byId(id);
    if (e == null || !e.available || switchingSite) return false;
    if (id == siteId) return true;
    _persist();
    final created = book.latestForSite(id) == null;
    if (!await _enterSite(e)) {
      notifyListeners();
      return false;
    }
    if (created) {
      book.create(name: _missionName(book.missions.length + 1), siteId: id, objectives: List.of(data.objectives));
    } else {
      book.open(book.latestForSite(id)!.id);
    }
    _showMission();
    await recompute();
    await _saveNow();
    return true;
  }

  /// Crea una misión nueva, sin objetivos, en el sitio abierto y la abre.
  Future<void> createMission([String? name]) async {
    _persist();
    book.create(name: name ?? _missionName(book.missions.length + 1), siteId: siteId);
    await _openCurrentMission();
  }

  /// Abre una misión guardada. Falso si no existe o no se pudo cargar su sitio.
  Future<bool> openMission(String id) async {
    if (id == book.currentId || switchingSite) return id == book.currentId;
    _persist();
    final prev = book.currentId;
    if (!book.open(id)) return false;
    if (!await _openCurrentMission()) {
      book.open(prev);
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<void> duplicateMission(String id, [String? name]) async {
    _persist();
    final src = book.byId(id);
    if (src == null) return;
    book.duplicate(id, name ?? '${src.name} (${locale.languageCode == 'es' ? 'copia' : 'copy'})');
    await _openCurrentMission();
  }

  /// Borra una misión. No borra la última. Si era la abierta, abre la más reciente.
  Future<bool> deleteMission(String id) async {
    _persist();
    final wasCurrent = id == book.currentId;
    if (!book.delete(id)) return false;
    if (wasCurrent) {
      await _openCurrentMission();
    } else {
      notifyListeners();
      await _saveNow();
    }
    return true;
  }

  void _editMission(Mission Function(Mission) change) {
    book.replaceCurrent(change(book.current).copyWith(updatedAt: DateTime.now()));
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), () => store.save(book));
    notifyListeners();
  }

  void renameMission(String name) => _editMission((m) => m.copyWith(name: name.trim().isEmpty ? m.name : name.trim()));

  void setMissionNotes(String notes) => _editMission((m) => m.copyWith(notes: notes));

  void setMissionItems({List<MissionItem>? consumables, List<MissionItem>? equipment}) =>
      _editMission((m) => m.copyWith(consumables: consumables, equipment: equipment));

  String routeStartId = 'habitat';
  List<PlannedRoute> tracedRoutes = [];
  String? activeRouteId;

  PlannedRoute? get activePlannedRoute {
    if (activeRouteId == null) return null;
    for (final r in tracedRoutes) {
      if (r.id == activeRouteId) return r;
    }
    return null;
  }

  RouteResult? get route => activePlannedRoute?.result ?? routes[selectedRoute];

  Objective? get activeObjective {
    if (selectedObjective != null) {
      final found = objective(selectedObjective!);
      if (found != null) return found;
    }
    return objectives.isNotEmpty ? objectives.first : null;
  }

  /// Id de la ruta única calculada automáticamente.
  List<String> get routeIds => const ['safe'];

  void setLocale(Locale l) {
    locale = l;
    notifyListeners();
  }

  void setEnvSol(int sol) {
    envSol = sol;
    notifyListeners();
  }

  void setTab(int t) {
    tab = t;
    notifyListeners();
  }

  void toggleLayer(String id, bool v) {
    layers[id]!.visible = v;
    notifyListeners();
  }

  void setOpacity(String id, double v) {
    layers[id]!.opacity = v;
    notifyListeners();
  }

  void resetLayers() {
    for (final l in kLayers) {
      layers[l.id] = LayerState(_defaultVisible[l.id] ?? false, _defaultOpacity[l.id] ?? 1.0);
    }
    notifyListeners();
  }

  void setExitMode(ExitMode v) {
    if (exitMode == v) return;
    exitMode = v;
    selectedRoute = v == ExitMode.pair ? 'pair1' : 'safe';
    _persist();
    recompute();
  }

  void selectRoute(String id) {
    selectedRoute = id;
    notifyListeners();
  }

  void selectObjective(String? id) {
    final changed = selectedObjective != id;
    selectedObjective = id;
    if (changed && id != null && id != routeStartId) {
      traceRoute(routeStartId, id);
    } else {
      notifyListeners();
    }
  }

  void setRouteStart(String id) {
    if (id != 'habitat' && objective(id) == null) return;
    routeStartId = id;
    notifyListeners();
  }

  void selectTracedRoute(String id) {
    for (final r in tracedRoutes) {
      if (r.id == id) {
        activeRouteId = id;
        selectedRoute = 'safe';
        routes = {'safe': r.result};
        if (r.toId != 'habitat') selectedObjective = r.toId;
        notifyListeners();
        return;
      }
    }
  }

  void removeTracedRoute(String id) {
    tracedRoutes = tracedRoutes.where((r) => r.id != id).toList();
    if (activeRouteId == id) {
      if (tracedRoutes.isNotEmpty) {
        activeRouteId = tracedRoutes.last.id;
        routes = {'safe': tracedRoutes.last.result};
      } else {
        activeRouteId = null;
        routes = {};
      }
    }
    notifyListeners();
  }

  int? _cellForPoint(String id) {
    if (id == 'habitat') return data.grid.habitat;
    final o = objective(id);
    if (o == null) return null;
    return data.grid.cellOf(o.xM, o.yM);
  }

  RouteResult _computeLeg(String fromId, String toId) {
    final start = _cellForPoint(fromId);
    final goal = _cellForPoint(toId);
    final visited = toId == 'habitat' ? const <String>[] : [toId];
    final skipped = toId == 'habitat'
        ? const <Map<String, String>>[]
        : [
            {'id': toId, 'reason': 'unreachable'},
          ];
    if (start == null || goal == null || fromId == toId) {
      return RouteResult(
        profile: 'safe',
        status: 'unreachable',
        visited: const [],
        skipped: skipped,
        weightedCost: 0,
        cells: const [],
      );
    }
    final path = astar(data.grid, data.model, data.model.profiles['safe']!, start, goal);
    if (path == null) {
      return RouteResult(
        profile: 'safe',
        status: 'unreachable',
        visited: const [],
        skipped: skipped,
        weightedCost: 0,
        cells: const [],
      );
    }
    return RouteResult(
      profile: 'safe',
      status: 'ok',
      visited: visited,
      skipped: const [],
      weightedCost: path.cost,
      cells: path.cells,
      metrics: evaluate(data.grid, data.model, path.cells, const {}),
    );
  }

  Future<void> traceRoute(String fromId, String toId) async {
    if (fromId == toId) return;
    final routeId = '$fromId->$toId';
    for (final existing in tracedRoutes) {
      if (existing.id == routeId) {
        activeRouteId = routeId;
        selectedRoute = 'safe';
        routes = {'safe': existing.result};
        notifyListeners();
        return;
      }
    }
    final gen = ++_gen;
    computing = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final sw = Stopwatch()..start();
    final res = _computeLeg(fromId, toId);
    if (gen != _gen) return;
    computeMs = sw.elapsedMilliseconds;
    final planned = PlannedRoute(id: routeId, fromId: fromId, toId: toId, result: res);
    tracedRoutes = [...tracedRoutes.where((r) => r.id != routeId), planned];
    activeRouteId = routeId;
    pairResult = null;
    selectedRoute = 'safe';
    routes = {'safe': res};
    computing = false;
    notifyListeners();
  }

  void toggleAddMode() {
    addMode = !addMode;
    notifyListeners();
  }

  Objective? objective(String id) {
    for (final o in objectives) {
      if (o.id == id) return o;
    }
    return null;
  }

  /// Recalcula las rutas trazadas (o traza la ruta al objetivo activo si no hay ninguna).
  Future<void> recompute() async {
    final gen = ++_gen;
    computing = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final sw = Stopwatch()..start();
    final validIds = {'habitat', for (final o in objectives) o.id};
    final updated = <PlannedRoute>[];
    for (final r in tracedRoutes) {
      if (validIds.contains(r.fromId) && validIds.contains(r.toId)) {
        updated.add(PlannedRoute(id: r.id, fromId: r.fromId, toId: r.toId, result: _computeLeg(r.fromId, r.toId)));
      }
    }
    if (updated.isEmpty) {
      final target = activeObjective;
      if (target != null && target.id != routeStartId) {
        final id = '$routeStartId->${target.id}';
        updated.add(PlannedRoute(id: id, fromId: routeStartId, toId: target.id, result: _computeLeg(routeStartId, target.id)));
      }
    }
    if (gen != _gen) return;
    computeMs = sw.elapsedMilliseconds;
    tracedRoutes = updated;
    if (activeRouteId == null || !tracedRoutes.any((r) => r.id == activeRouteId)) {
      activeRouteId = tracedRoutes.isNotEmpty ? tracedRoutes.last.id : null;
    }
    pairResult = null;
    selectedRoute = 'safe';
    final active = activePlannedRoute;
    routes = active != null ? {'safe': active.result} : {};
    computing = false;
    notifyListeners();
  }

  String addObjective(double x, double y, String name) {
    final id = 'u${_nextId++}';
    objectives = [
      ...objectives,
      Objective(id: id, name: name, type: 'sample', priority: 3, workMin: 30, xM: x, yM: y),
    ];
    selectedObjective = id;
    addMode = false;
    _persist();
    traceRoute(routeStartId, id);
    return id;
  }

  void updateObjective(String id, {String? name, String? type, int? priority, double? workMin, String? transport}) {
    objectives = [
      for (final o in objectives)
        o.id == id ? o.copyWith(name: name, type: type, priority: priority, workMin: workMin, transport: transport) : o,
    ];
    _persist();
    recompute();
  }

  /// Mueve un objetivo sin recalcular (mientras se arrastra).
  void moveObjectiveLive(String id, double x, double y) {
    objectives = [for (final o in objectives) o.id == id ? o.copyWith(xM: x, yM: y) : o];
    notifyListeners();
  }

  void finishMove() {
    _persist();
    recompute();
  }

  void removeObjective(String id) {
    objectives = objectives.where((o) => o.id != id).toList();
    if (selectedObjective == id) selectedObjective = null;
    if (routeStartId == id) routeStartId = 'habitat';
    tracedRoutes = tracedRoutes.where((r) => r.fromId != id && r.toId != id).toList();
    if (activeRouteId != null && !tracedRoutes.any((r) => r.id == activeRouteId)) {
      activeRouteId = tracedRoutes.isNotEmpty ? tracedRoutes.last.id : null;
    }
    _persist();
    recompute();
  }
}

/// Entrega el [AppModel] a todo el árbol.
class AppScope extends InheritedNotifier<AppModel> {
  const AppScope({super.key, required AppModel model, required super.child}) : super(notifier: model);

  static AppModel of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
