import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../state/app_model.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import 'common.dart';

/// Panel izquierdo: capas de datos con interruptor, origen del dato y opacidad, y leyenda de pendiente.
class LayersPanel extends StatelessWidget {
  const LayersPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final l = AppLocalizations.of(context)!;
    return Container(
      color: AppColors.panel,
      child: Column(children: [
        SectionHeader(
          icon: Icons.layers_outlined,
          title: l.layersTitle,
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Tag(l.layersActive(m.activeLayerCount), color: AppColors.orange, filled: true),
            const SizedBox(width: 8),
            Tooltip(
              message: l.layersReset,
              child: InkWell(onTap: m.resetLayers, child: const Icon(Icons.restart_alt, size: 16, color: AppColors.textDim)),
            ),
          ]),
        ),
        Expanded(
          child: ListView(padding: EdgeInsets.zero, children: [for (final def in m.layerDefs) _LayerRow(def: def)]),
        ),
        const _Legend(),
      ]),
    );
  }
}

class _LayerRow extends StatelessWidget {
  const _LayerRow({required this.def});

  final LayerDef def;

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final l = AppLocalizations.of(context)!;
    final st = m.layers[def.id]!;
    final f = Fmt(m.locale);
    final enabled = def.hasData;
    final color = kindColor(def.kind);
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
        decoration: BoxDecoration(
          color: st.visible && enabled ? AppColors.panel2 : Colors.transparent,
          border: const Border(bottom: BorderSide(color: AppColors.hairline)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            SizedBox(
              width: 28,
              height: 24,
              child: Checkbox(value: st.visible && enabled, onChanged: enabled ? (v) => m.toggleLayer(def.id, v ?? false) : null),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(layerName(l, def.id), style: AppText.body(13, weight: FontWeight.w500, color: st.visible && enabled ? AppColors.text : AppColors.textDim)),
            ),
            Tag(kindText(l, def.kind), color: color),
          ]),
          Padding(
            padding: const EdgeInsets.only(left: 36, top: 2),
            child: Text(enabled ? def.tag : '${def.tag} · ${l.layerNoData}', style: AppText.mono(10, color: AppColors.textMute)),
          ),
          if (st.visible && enabled && def.hasOpacity)
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 4),
              child: Row(children: [
                Text(l.opacity, style: AppText.label(color: AppColors.textMute)),
                Expanded(
                  child: SizedBox(
                    height: 22,
                    child: Slider(value: st.opacity, min: 0.1, max: 1.0, onChanged: (v) => m.setOpacity(def.id, v)),
                  ),
                ),
                SizedBox(width: 38, child: Text(f.percent(st.opacity), textAlign: TextAlign.right, style: AppText.mono(11, color: AppColors.orange))),
              ]),
            ),
        ]),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final m = AppScope.of(context);
    bool on(String id) => (m.layers[id]?.visible ?? false) && m.layerDefs.any((d) => d.id == id);
    Widget item(Color c, String t) => Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(children: [
            Container(width: 12, height: 12, color: c),
            const SizedBox(width: 8),
            Text(t, style: AppText.mono(11, color: AppColors.textDim)),
          ]),
        );
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 320),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.hairline))),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.legendTitle, style: AppText.label()),
        const SizedBox(height: 10),
        item(AppColors.slopeNominal, l.legendNominal),
        item(AppColors.slopeCaution, l.legendCaution),
        item(AppColors.slopeHigh, l.legendHigh),
        item(AppColors.slopeForbidden, l.legendForbidden),
        if (on('slope15')) item(const Color(0xFFE74C3C), l.legendSlope15),
        if (on('transit')) ...[
          const SizedBox(height: 6),
          Text(l.legendTransitTitle, style: AppText.label()),
          const SizedBox(height: 6),
          item(const Color(0xFF3CAA5C), l.legendTransitGreen),
          item(const Color(0xFFE6AA28), l.legendTransitYellow),
          item(const Color(0xFFD23232), l.legendTransitRed),
          item(const Color(0xFF969696), l.legendTransitNone),
          Text(l.transitNote, style: AppText.body(10.5, color: AppColors.textMute, height: 1.35)),
        ],
        if (on('aqueous_pts') || on('hydrous_pts') || on('valleys')) ...[
          const SizedBox(height: 6),
          Text(l.legendBiosigTitle, style: AppText.label()),
          const SizedBox(height: 6),
          if (on('aqueous_pts')) ...[
            item(kMineralColors['phyllosilicate']!, l.legendPhyllo),
            item(kMineralColors['carbonate']!, l.legendCarbonate),
          ],
          if (on('hydrous_pts')) item(kMineralColors['hydrous']!, l.legendHydrous),
          if (on('valleys')) item(kValleyColor, l.legendValleys),
          Text(l.legendBiosigNote, style: AppText.body(10.5, color: AppColors.textMute, height: 1.35)),
        ],
        if (on('geology')) ...[
          const SizedBox(height: 6),
          Text(l.legendGeologyTitle, style: AppText.label()),
          const SizedBox(height: 6),
          Text(l.legendGeologyNote, style: AppText.body(10.5, color: AppColors.textMute, height: 1.35)),
        ],
        if (on('craters')) ...[const SizedBox(height: 6), item(AppColors.text, l.legendCraters)],
        if (on('names')) item(AppColors.text, l.legendNames),
        if (m.data.context != null) ...[
          const SizedBox(height: 6),
          Text(l.contextNote, style: AppText.body(10.5, color: AppColors.textMute, height: 1.35)),
        ],
        if (on('zones')) ...[
          const SizedBox(height: 6),
          Text(l.legendZonesTitle, style: AppText.label()),
          const SizedBox(height: 6),
          item(AppColors.green, l.legendHabitation),
          item(AppColors.text, l.legendLanding),
          item(AppColors.cyan, l.legendEz),
          item(AppColors.amber, l.legendRoi),
        ],
      ]),
      ),
    );
  }
}
