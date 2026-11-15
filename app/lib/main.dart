import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/mission.dart';
import 'data/mission_store.dart';
import 'data/site_data.dart';
import 'data/site_registry.dart';
import 'l10n/app_localizations.dart';
import 'screens/helmet_screen.dart';
import 'screens/mission_screen.dart';
import 'screens/plan_screen.dart';
import 'screens/safety_screen.dart';
import 'screens/science_screen.dart';
import 'state/app_model.dart';
import 'theme/app_theme.dart';
import 'widgets/sources_dialog.dart';
import 'widgets/top_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // La interfaz está pensada para tableta en horizontal y a pantalla completa.
  await SystemChrome.setPreferredOrientations(const [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const AresApp());
}

class AresApp extends StatefulWidget {
  const AresApp({super.key});

  @override
  State<AresApp> createState() => _AresAppState();
}

class _AresAppState extends State<AresApp> {
  AppModel? _model;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _open().then((m) {
      setState(() => _model = m);
      m.recompute();
    }).catchError((Object e) {
      setState(() => _error = e);
    });
  }

  /// Lee el registro de sitios y las misiones guardadas, y abre la misión que estaba abierta (o el sitio por defecto).
  Future<AppModel> _open() async {
    final registry = await SiteRegistry.load();
    final store = PrefsMissionStore();
    var book = await store.load();
    var entry = registry.byId(registry.defaultId)!;
    if (book != null) {
      // La misión abierta si su sitio está disponible; si no, la más reciente cuyo sitio lo esté; si no, se empieza de cero.
      bool usable(Mission m) => registry.byId(m.siteId)?.available ?? false;
      Mission? pick = usable(book.current) ? book.current : null;
      if (pick == null) {
        final sorted = [...book.missions]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        for (final m in sorted) {
          if (usable(m)) {
            pick = m;
            break;
          }
        }
      }
      if (pick == null) {
        book = null;
      } else {
        book.open(pick.id);
        entry = registry.byId(pick.siteId)!;
      }
    }
    return AppModel(await SiteData.load(entry.assetDir), registry: registry, siteId: entry.id, book: book, store: store);
  }

  @override
  Widget build(BuildContext context) {
    final m = _model;
    if (m == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: Scaffold(
          body: Center(
            child: Text(_error?.toString() ?? 'ARES PATH', style: AppText.mono(12, color: _error == null ? AppColors.textDim : AppColors.red)),
          ),
        ),
      );
    }
    return AppScope(
      model: m,
      child: Builder(builder: (context) {
        final model = AppScope.of(context);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ARES PATH',
          theme: buildTheme(),
          locale: model.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const _Home(),
        );
      }),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: Column(children: [
        const TopBar(),
        Expanded(
          child: switch (m.tab) {
            0 => const PlanScreen(),
            1 => const SafetyScreen(),
            2 => const ScienceScreen(),
            3 => const MissionScreen(),
            _ => const HelmetScreen(),
          },
        ),
        Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: const BoxDecoration(color: AppColors.bg, border: Border(top: BorderSide(color: AppColors.hairline))),
          child: Row(children: [
            Expanded(child: Text(l.attribution, style: AppText.mono(10, color: AppColors.textMute), overflow: TextOverflow.ellipsis)),
            InkWell(
              onTap: () => showSourcesDialog(context, m),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.menu_book_outlined, size: 12, color: AppColors.orange),
                  const SizedBox(width: 4),
                  Text(l.srcLink.toUpperCase(), style: AppText.mono(10, color: AppColors.orange)),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
