import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../state/app_model.dart';
import '../theme/app_theme.dart';
import 'missions_dialog.dart';

/// Barra superior: marca, sitio, pestañas, idioma y estado de la ruta seleccionada.
class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final l = AppLocalizations.of(context)!;
    final tabs = [l.navPlan];
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(color: AppColors.bg, border: Border(bottom: BorderSide(color: AppColors.hairline))),
      child: Row(children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(border: Border.all(color: AppColors.orange, width: 1.5)),
          child: const Icon(Icons.change_history, size: 15, color: AppColors.orange),
        ),
        const SizedBox(width: 10),
        Text(l.appName, style: AppText.head(15, height: 1.0)),
        const SizedBox(width: 18),
        Container(width: 1, height: 26, color: AppColors.hairline),
        const SizedBox(width: 14),
        Flexible(child: _SiteChip(model: m)),
        const SizedBox(width: 8),
        Flexible(child: _MissionChip(model: m)),
        const SizedBox(width: 22),
        for (var i = 0; i < tabs.length; i++)
          InkWell(
            onTap: () => m.setTab(i),
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: m.tab == i ? AppColors.orange : Colors.transparent, width: 2)),
              ),
              child: Text(tabs[i], style: AppText.head(13, weight: FontWeight.w500, color: m.tab == i ? AppColors.orange : AppColors.text)),
            ),
          ),
        const Spacer(),
        _langSwitch(m),
      ]),
    );
  }

  Widget _langSwitch(AppModel m) {
    Widget btn(String code, String label) {
      final on = m.locale.languageCode == code;
      return InkWell(
        onTap: () => m.setLocale(Locale(code)),
        child: Container(
          width: 36,
          height: 26,
          alignment: Alignment.center,
          color: on ? AppColors.orange : Colors.transparent,
          child: Text(label, style: AppText.mono(11, color: on ? AppColors.bg : AppColors.textDim, weight: FontWeight.w700)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.hairline)),
      child: Row(children: [btn('en', 'EN'), btn('es', 'ES')]),
    );
  }
}

/// Nombre del sitio abierto. Si el registro tiene más de un sitio, abre el selector.
class _SiteChip extends StatelessWidget {
  const _SiteChip({required this.model});

  final AppModel model;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final m = model;
    final name = (m.siteLabel ?? l.siteName).toUpperCase();
    final multi = m.registry.sites.isNotEmpty;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: AppColors.panel2, border: Border.all(color: AppColors.hairline)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Flexible(child: Text(name, style: AppText.label(color: AppColors.text), overflow: TextOverflow.ellipsis)),
        if (m.switchingSite)
          const Padding(padding: EdgeInsets.only(left: 8), child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5)))
        else if (multi)
          const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.textDim),
      ]),
    );
    if (!multi) return chip;
    return PopupMenuButton<String>(
      tooltip: l.siteChange,
      constraints: const BoxConstraints(minWidth: 520),
      enabled: !m.switchingSite,
      padding: EdgeInsets.zero,
      color: AppColors.panel,
      onSelected: (id) async {
        final messenger = ScaffoldMessenger.of(context);
        final ok = await m.switchSite(id);
        if (!ok && m.siteId != id) messenger.showSnackBar(SnackBar(content: Text(l.siteLoadError)));
      },
      itemBuilder: (_) => [
        for (final s in m.registry.sites)
          PopupMenuItem<String>(
            value: s.id,
            enabled: s.available,
            child: Row(children: [
              Icon(s.id == m.siteId ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 14, color: s.id == m.siteId ? AppColors.orange : AppColors.textMute),
              const SizedBox(width: 8),
              Flexible(child: Text(s.name(m.locale.languageCode), style: AppText.label(color: s.available ? AppColors.text : AppColors.textMute), overflow: TextOverflow.ellipsis)),
              if (s.available && (s.indicative || s.reach)) ...[
                const SizedBox(width: 10),
                Text(s.reach ? l.siteReachTag : l.siteIndicativeTag, style: AppText.mono(10, color: AppColors.amber)),
              ],
              if (!s.available) ...[
                const SizedBox(width: 10),
                Text(l.sitePending, style: AppText.mono(10, color: AppColors.textMute)),
              ],
            ]),
          ),
      ],
      child: chip,
    );
  }
}

/// Nombre de la misión abierta; abre la lista de misiones.
class _MissionChip extends StatelessWidget {
  const _MissionChip({required this.model});

  final AppModel model;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Tooltip(
      message: l.msnTitle,
      child: InkWell(
        onTap: () => showMissionsDialog(context, model),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: AppColors.panel2, border: Border.all(color: AppColors.hairline)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.folder_open, size: 14, color: AppColors.orange),
            const SizedBox(width: 6),
            Flexible(child: Text(model.book.current.name.toUpperCase(), style: AppText.label(color: AppColors.text), overflow: TextOverflow.ellipsis)),
          ]),
        ),
      ),
    );
  }
}
