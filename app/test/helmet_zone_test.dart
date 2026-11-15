// Casco en Endeavour: fondo en perspectiva y tarjeta con fotos reales de Opportunity (la zona, no el punto).
import 'package:ares_path/data/site_data.dart';
import 'package:ares_path/l10n/app_localizations.dart';
import 'package:ares_path/screens/helmet_screen.dart';
import 'package:ares_path/state/app_model.dart';
import 'package:ares_path/widgets/terrain_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('el casco de Endeavour dibuja el terreno y la tarjeta de fotos', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    late AppModel m;
    await tester.runAsync(() async {
      m = AppModel(await SiteData.load('site_meridiani_endeavour'));
      await m.recompute();
    });
    await tester.pumpWidget(AppScope(
      model: m,
      child: const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
        home: Scaffold(body: HelmetScreen()),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    expect(find.byType(TerrainView), findsOneWidget);
    expect(find.text('THE AREA, SEEN BY OPPORTUNITY'), findsOneWidget);
    expect(find.text('1/4'), findsOneWidget);
    await tester.tap(find.text('THE AREA, SEEN BY OPPORTUNITY'));
    await tester.pump();
    expect(find.text('2/4'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 90)));
}
