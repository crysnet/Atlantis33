import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'grid.dart';
import 'model.dart';
import 'planner.dart';

/// Lo que hay que calcular: los objetivos y el modo de salida.
class PlanRequest {
  const PlanRequest(this.objectives, {this.withRover = false, this.withSupport = false, this.byObjective = false, this.pair = false});

  final List<Objective> objectives;
  final bool withRover;
  final bool withSupport;
  final bool byObjective;

  /// Salida en pareja: calcula el par de rutas en vez de las tres.
  final bool pair;
}

/// Resultado de un cálculo: las rutas y, en modo pareja, su resumen.
class PlanOutput {
  const PlanOutput(this.routes, this.pair);

  final Map<String, RouteResult> routes;
  final PairResult? pair;
}

/// Calcula las rutas en el hilo actual. La usan el isolate de fondo, la web (sin isolates) y las pruebas.
PlanOutput runPlan(RouteGrid grid, RoutingModel model, PlanRequest r) {
  final planner = Planner(grid, model, r.objectives, withRover: r.withRover, withSupport: r.withSupport, byObjective: r.byObjective);
  final PairResult? pair = r.pair ? planner.pair() : null;
  return PlanOutput(pair?.routes ?? planner.allThree(), pair);
}

class _Init {
  const _Init(this.grid, this.model);
  final RouteGrid grid;
  final RoutingModel model;
}

class _Job {
  const _Job(this.id, this.request);
  final int id;
  final PlanRequest request;
}

class _Done {
  const _Done(this.id, this.output, this.error);
  final int id;
  final PlanOutput? output;
  final String? error;
}

void _entry(SendPort main) {
  final port = ReceivePort();
  main.send(port.sendPort);
  RouteGrid? grid;
  RoutingModel? model;
  port.listen((m) {
    if (m is _Init) {
      grid = m.grid;
      model = m.model;
    } else if (m is _Job) {
      try {
        main.send(_Done(m.id, runPlan(grid!, model!, m.request), null));
      } catch (e) {
        main.send(_Done(m.id, null, e.toString()));
      }
    } else {
      port.close();
    }
  });
}

/// Calcula rutas sin bloquear la interfaz: un isolate propio guarda la rejilla y el modelo del sitio y recibe solo los
/// objetivos de cada pedido. En la web (sin isolates) o si el isolate falla, calcula en el hilo principal.
class RouteWorker {
  RouteWorker(this.grid, this.model);

  final RouteGrid grid;
  final RoutingModel model;

  Isolate? _isolate;
  SendPort? _send;
  ReceivePort? _recv;
  Future<void>? _starting;
  bool _failed = kIsWeb;
  final Map<int, Completer<PlanOutput?>> _waiting = {};
  int _next = 0;
  int? _active;
  (int, PlanRequest, Completer<PlanOutput?>)? _queued;

  Future<void> _start() async {
    final recv = ReceivePort();
    _recv = recv;
    final ready = Completer<SendPort>();
    recv.listen((m) {
      if (m is SendPort) {
        ready.complete(m);
      } else if (m is _Done) {
        final c = _waiting.remove(m.id);
        if (m.id == _active) _active = null;
        if (c != null && !c.isCompleted) {
          m.output != null ? c.complete(m.output) : c.completeError(m.error ?? 'error');
        }
        _pump();
      }
    });
    _isolate = await Isolate.spawn(_entry, recv.sendPort, errorsAreFatal: false);
    _send = await ready.future;
    _send!.send(_Init(grid, model));
  }

  void _pump() {
    final q = _queued;
    if (q == null || _active != null) return;
    _queued = null;
    _active = q.$1;
    _waiting[q.$1] = q.$3;
    _send!.send(_Job(q.$1, q.$2));
  }

  /// Calcula [r]. Devuelve null si otro pedido más nuevo lo reemplazó antes de empezar.
  Future<PlanOutput?> run(PlanRequest r) async {
    if (!_failed) {
      try {
        await (_starting ??= _start());
        final id = _next++;
        final c = Completer<PlanOutput?>();
        // Solo cuenta el pedido más nuevo: el que esperaba turno se descarta.
        _queued?.$3.complete(null);
        _queued = (id, r, c);
        _pump();
        return await c.future;
      } catch (_) {
        _failed = true;
        dispose();
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return runPlan(grid, model, r);
  }

  void dispose() {
    _send?.send(null);
    _isolate?.kill(priority: Isolate.beforeNextEvent);
    _recv?.close();
    _isolate = null;
    _send = null;
    _recv = null;
    _starting = null;
    for (final c in _waiting.values) {
      if (!c.isCompleted) c.complete(null);
    }
    _waiting.clear();
    _queued?.$3.complete(null);
    _queued = null;
    _active = null;
  }
}
