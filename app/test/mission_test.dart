// Misiones guardadas: modelo, libreta, almacenamiento y el modelo de la app.
import 'dart:convert';

import 'package:ares_path/data/mission.dart';
import 'package:ares_path/data/mission_store.dart';
import 'package:ares_path/data/site_data.dart';
import 'package:ares_path/data/site_registry.dart';
import 'package:ares_path/routing/routing.dart';
import 'package:ares_path/state/app_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _t0 = DateTime.utc(2026, 11, 14, 12);

Mission _mission(String id, {String site = 'gale_boxwork', DateTime? at}) => Mission(
      id: id,
      name: 'Mision $id',
      siteId: site,
      objectives: const [
        Objective(id: 't1', name: 'Parada', type: 'sample', priority: 5, workMin: 40, xM: 1998, yM: 1697, transport: 'hybrid'),
      ],
      consumables: const [MissionItem(name: 'Oxígeno', qty: 2, unit: 'botellas', massKg: 12.5)],
      equipment: const [MissionItem(name: 'Martillo', qty: 1, massKg: 1.2), MissionItem(name: 'Cámara')],
      notes: 'nota',
      exitMode: 'byObjective',
      createdAt: at ?? _t0,
      updatedAt: at ?? _t0,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('una misión sobrevive a guardar y leer', () {
    final m = _mission('a');
    final back = Mission.fromJson(jsonDecode(jsonEncode(m.toJson())) as Map<String, dynamic>);
    expect(back.toJson(), m.toJson());
    expect(back.objectives.single.transport, 'hybrid');
    expect(back.objectives.single.xM, 1998);
    expect(back.equipment.last.massKg, 0);
    expect(back.exitMode, 'byObjective');
    expect(back.updatedAt.isAtSameMomentAs(_t0), isTrue);
  });

  test('la masa declarada suma consumibles y equipo', () {
    expect(_mission('a').declaredMassKg, closeTo(2 * 12.5 + 1.2, 1e-9));
  });

  test('un objetivo sin transport se lee a pie', () {
    final o = Objective.fromJson({'id': 'x', 'priority': 1, 'work_min': 10, 'x_m': 1, 'y_m': 2});
    expect(o.transport, 'foot');
  });

  test('la libreta crea, duplica, abre y borra', () {
    final b = MissionBook.single(_mission('a'));
    final m2 = b.create(name: 'Dos', siteId: 'gale_boxwork', now: _t0.add(const Duration(minutes: 1)));
    expect(b.currentId, m2.id);
    expect(b.missions.length, 2);
    final m3 = b.duplicate('a', 'Copia', now: _t0.add(const Duration(minutes: 2)));
    expect(b.currentId, m3.id);
    expect(m3.objectives.single.id, 't1');
    expect(m3.consumables.single.name, 'Oxígeno');
    expect({for (final m in b.missions) m.id}.length, 3, reason: 'ids distintos');
    expect(b.open('a'), isTrue);
    expect(b.open('no_existe'), isFalse);
    expect(b.currentId, 'a');
    // Borrar la abierta abre la modificada más recientemente.
    expect(b.delete('a'), isTrue);
    expect(b.currentId, m3.id);
    expect(b.delete(m3.id), isTrue);
    expect(b.currentId, m2.id);
    expect(b.delete(m2.id), isFalse, reason: 'no se borra la última');
    expect(b.missions.length, 1);
  });

  test('ids nuevos aunque se creen en el mismo instante', () {
    final b = MissionBook.single(_mission('a'));
    final ids = {for (var i = 0; i < 5; i++) b.create(name: 'n$i', siteId: 'x', now: _t0).id};
    expect(ids.length, 5);
  });

  test('la misión más reciente de un sitio', () {
    final b = MissionBook([_mission('a', at: _t0), _mission('b', at: _t0.add(const Duration(hours: 1))), _mission('c', site: 'otro', at: _t0.add(const Duration(hours: 2)))], 'a');
    expect(b.latestForSite('gale_boxwork')!.id, 'b');
    expect(b.latestForSite('otro')!.id, 'c');
    expect(b.latestForSite('nada'), isNull);
  });

  test('la libreta se guarda y se lee con la misión abierta', () async {
    final store = MemoryMissionStore();
    final b = MissionBook([_mission('a'), _mission('b')], 'b');
    await store.save(b);
    final back = (await store.load())!;
    expect(back.currentId, 'b');
    expect(back.missions.map((m) => m.id), ['a', 'b']);
  });

  test('las preferencias del dispositivo guardan y leen; si los datos están rotos se apartan', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PrefsMissionStore();
    expect(await store.load(), isNull);
    await store.save(MissionBook.single(_mission('a')));
    expect((await store.load())!.current.name, 'Mision a');

    SharedPreferences.setMockInitialValues({PrefsMissionStore.key: '{esto no es json'});
    expect(await PrefsMissionStore().load(), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(PrefsMissionStore.corruptKey), '{esto no es json', reason: 'copia de los datos rotos');
  });

  group('en el modelo de la app', () {
    late SiteData data;
    late SiteRegistry registry;

    setUpAll(() async {
      registry = SiteRegistry.fromJson({
        'default': 'gale_boxwork',
        'sites': [
          {'id': 'gale_boxwork', 'asset_dir': 'site_gale', 'available': true, 'name': {'en': 'Gale'}},
        ],
      });
      data = await SiteData.load();
    });

    test('arranca con una misión con los objetivos de ejemplo', () {
      final m = AppModel(data, registry: registry, siteId: 'gale_boxwork');
      expect(m.book.missions.length, 1);
      expect(m.book.current.name, 'Mission 1');
      expect(m.book.current.siteId, 'gale_boxwork');
      expect(m.book.current.objectives.length, data.objectives.length);
      m.dispose();
    });

    test('abre la misión guardada: objetivos y modo de salida', () {
      final book = MissionBook.single(_mission('a'));
      final m = AppModel(data, registry: registry, siteId: 'gale_boxwork', book: book);
      expect(m.objectives.single.id, 't1');
      expect(m.exitMode, ExitMode.byObjective);
      m.dispose();
    });

    test('crear, renombrar, editar, duplicar y borrar guardan en el almacén', () async {
      final store = MemoryMissionStore();
      final m = AppModel(data, registry: registry, siteId: 'gale_boxwork', store: store);
      await m.createMission('Segunda');
      expect(m.book.current.name, 'Segunda');
      expect(m.objectives, isEmpty);
      expect(m.routes['safe']?.status, 'no_target');
      expect((await store.load())!.missions.length, 2);

      m.renameMission('  Renombrada ');
      m.setMissionNotes('hola');
      m.setMissionItems(consumables: const [MissionItem(name: 'Agua', qty: 3, unit: 'L', massKg: 1)]);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final saved = (await store.load())!.current;
      expect(saved.name, 'Renombrada');
      expect(saved.notes, 'hola');
      expect(saved.declaredMassKg, 3);

      await m.duplicateMission(m.book.currentId);
      expect(m.book.missions.length, 3);
      expect(m.book.current.name, 'Renombrada (copy)');
      expect(m.book.current.consumables.single.name, 'Agua');

      final dup = m.book.currentId;
      expect(await m.deleteMission(dup), isTrue);
      expect(m.book.missions.length, 2);
      expect((await store.load())!.missions.length, 2);
      m.dispose();
    });

    test('no abre una misión de un sitio que no está disponible', () async {
      final book = MissionBook([_mission('a'), _mission('b', site: 'sin_datos')], 'a');
      final m = AppModel(data, registry: registry, siteId: 'gale_boxwork', book: book);
      expect(await m.openMission('b'), isFalse);
      expect(m.book.currentId, 'a');
      expect(m.siteId, 'gale_boxwork');
      m.dispose();
    });
  });
}
