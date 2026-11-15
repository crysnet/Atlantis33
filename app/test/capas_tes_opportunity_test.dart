// Recorrido de Opportunity en Meridiani y capa de tránsito (TES) en Gale.
import 'dart:convert';
import 'dart:io';

import 'package:ares_path/data/site_data.dart';
import 'package:ares_path/data/site_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Endeavour trae el recorrido de Opportunity, dentro de la ventana y con soles crecientes', () async {
    final d = await SiteData.load('site_meridiani_endeavour');
    expect(d.curiosity.length, greaterThan(100));
    var prev = 0;
    for (final p in d.curiosity) {
      expect(p.sol, greaterThanOrEqualTo(prev));
      prev = p.sol;
    }
    expect(d.curiosity.last.sol, greaterThan(3000), reason: 'llega a Endeavour (sol 2700 en adelante)');
  });

  test('las capas del registro: Opportunity solo en Meridiani con datos, tránsito también en Gale', () async {
    final reg = SiteRegistry.fromJson(jsonDecode(File('assets/sites.json').readAsStringSync()) as Map<String, dynamic>);
    List<String> ids(String id) => reg.byId(id)!.layers;
    expect(ids('meridiani_endeavour'), contains('opportunity'));
    expect(ids('meridiani_habitat'), isNot(contains('opportunity')));
    expect(ids('gale_boxwork'), contains('transit'));
    expect(ids('gale_reach'), contains('transit'));
    expect(File('assets/site_gale/layers/transit.png').existsSync(), isTrue);
    expect(File('assets/site_gale_reach/layers/transit.png').existsSync(), isTrue);
  });
}
