import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/mission.dart';
import '../l10n/app_localizations.dart';
import '../state/app_model.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';

/// Misiones guardadas: lista a la izquierda y, a la derecha, los datos de la misión abierta (nombre, notas, consumibles y equipo).
Future<void> showMissionsDialog(BuildContext context, AppModel m) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(),
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900, maxHeight: 620), child: _MissionsPanel(model: m)),
    ),
  );
}

class _MissionsPanel extends StatefulWidget {
  const _MissionsPanel({required this.model});

  final AppModel model;

  @override
  State<_MissionsPanel> createState() => _MissionsPanelState();
}

class _MissionsPanelState extends State<_MissionsPanel> {
  final _name = TextEditingController();
  final _notes = TextEditingController();
  String? _loadedId;

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _syncFields(Mission cur) {
    if (_loadedId == cur.id) return;
    _loadedId = cur.id;
    _name.text = cur.name;
    _notes.text = cur.notes;
  }

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        labelStyle: AppText.label(),
        isDense: true,
        enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.hairline)),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.orange)),
      );

  @override
  Widget build(BuildContext context) {
    final m = widget.model;
    final l = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: m,
      builder: (context, _) {
        final cur = m.book.current;
        _syncFields(cur);
        final f = Fmt(m.locale);
        final byDate = [...m.book.missions]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairline))),
            child: Row(children: [
              const Icon(Icons.folder_open, size: 18, color: AppColors.orange),
              const SizedBox(width: 8),
              Text(l.msnTitle.toUpperCase(), style: AppText.head(15)),
              const SizedBox(width: 14),
              Expanded(child: Text(l.msnRoutesNote, style: AppText.body(11, color: AppColors.textMute), maxLines: 2, overflow: TextOverflow.ellipsis)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 18)),
            ]),
          ),
          Expanded(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(
                width: 300,
                child: Column(children: [
                  Expanded(
                    child: ListView(padding: EdgeInsets.zero, children: [
                      for (final mi in byDate) _row(context, m, l, mi, mi.id == cur.id),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: OutlinedButton.icon(
                      onPressed: m.createMission,
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(l.msnNew.toUpperCase(), style: AppText.label(color: AppColors.orange)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.orange,
                        side: const BorderSide(color: AppColors.orange),
                        shape: const RoundedRectangleBorder(),
                        minimumSize: const Size.fromHeight(40),
                      ),
                    ),
                  ),
                ]),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  TextField(controller: _name, style: AppText.body(14), decoration: _deco(l.msnName), onChanged: m.renameMission),
                  const SizedBox(height: 6),
                  Text('${l.msnSite}: ${m.registry.byId(cur.siteId)?.name(m.locale.languageCode) ?? cur.siteId} · ${l.msnObjectives(m.objectives.length)}',
                      style: AppText.mono(10.5, color: AppColors.cyan)),
                  const SizedBox(height: 14),
                  TextField(controller: _notes, style: AppText.body(13), minLines: 2, maxLines: 4, decoration: _deco(l.msnNotes), onChanged: m.setMissionNotes),
                  const SizedBox(height: 16),
                  _itemsBlock(context, m, l, f, l.msnConsumables, cur.consumables, (items) => m.setMissionItems(consumables: items)),
                  const SizedBox(height: 14),
                  _itemsBlock(context, m, l, f, l.msnEquipment, cur.equipment, (items) => m.setMissionItems(equipment: items)),
                  const SizedBox(height: 12),
                  Text(l.msnMassTotal(f.num(cur.declaredMassKg, 1)), style: AppText.mono(11, color: AppColors.text)),
                  const SizedBox(height: 4),
                  Text(l.msnAssumeNote, style: AppText.body(11, color: AppColors.textMute, height: 1.4)),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await Clipboard.setData(ClipboardData(text: const JsonEncoder.withIndent('  ').convert(cur.toJson())));
                        messenger.showSnackBar(SnackBar(content: Text(l.msnCopied)));
                      },
                      icon: const Icon(Icons.copy, size: 14),
                      label: Text(l.msnExport.toUpperCase(), style: AppText.label()),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ]);
      },
    );
  }

  Widget _row(BuildContext context, AppModel m, AppLocalizations l, Mission mi, bool open) {
    final f = Fmt(m.locale);
    final site = m.registry.byId(mi.siteId)?.name(m.locale.languageCode) ?? mi.siteId;
    return InkWell(
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        if (!await m.openMission(mi.id)) messenger.showSnackBar(SnackBar(content: Text(l.msnOpenError)));
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 9, 4, 9),
        decoration: BoxDecoration(
          color: open ? AppColors.panel2 : Colors.transparent,
          border: Border(left: BorderSide(color: open ? AppColors.orange : Colors.transparent, width: 3), bottom: const BorderSide(color: AppColors.hairline)),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(mi.name, style: AppText.body(13, weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('$site · ${l.msnObjectives(mi.objectives.length)}', style: AppText.mono(10, color: AppColors.textDim), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(f.dateTime(mi.updatedAt.toLocal()), style: AppText.mono(9.5, color: AppColors.textMute)),
            ]),
          ),
          IconButton(
            tooltip: l.msnDuplicate,
            visualDensity: VisualDensity.compact,
            onPressed: () => m.duplicateMission(mi.id),
            icon: const Icon(Icons.copy_all_outlined, size: 16, color: AppColors.textDim),
          ),
          IconButton(
            tooltip: l.msnDelete,
            visualDensity: VisualDensity.compact,
            onPressed: () => _confirmDelete(context, m, l, mi),
            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.textDim),
          ),
        ]),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppModel m, AppLocalizations l, Mission mi) async {
    final messenger = ScaffoldMessenger.of(context);
    if (m.book.missions.length <= 1) {
      messenger.showSnackBar(SnackBar(content: Text(l.msnDeleteLast)));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.msnDeleteTitle, style: AppText.head(15)),
        content: Text(l.msnDeleteBody(mi.name), style: AppText.body(13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel.toUpperCase(), style: AppText.label())),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: AppColors.bg, shape: const RoundedRectangleBorder()),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete.toUpperCase(), style: AppText.label(color: AppColors.bg)),
          ),
        ],
      ),
    );
    if (ok == true) await m.deleteMission(mi.id);
  }

  Widget _itemsBlock(BuildContext context, AppModel m, AppLocalizations l, Fmt f, String title, List<MissionItem> items, void Function(List<MissionItem>) set) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(title.toUpperCase(), style: AppText.label()),
        const Spacer(),
        TextButton.icon(
          onPressed: () async {
            final it = await _itemDialog(context, l, null);
            if (it != null) set([...items, it]);
          },
          icon: const Icon(Icons.add, size: 14),
          label: Text(l.msnAddItem.toUpperCase(), style: AppText.label(color: AppColors.orange)),
        ),
      ]),
      if (items.isEmpty) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(l.msnEmptyItems, style: AppText.body(12, color: AppColors.textMute))),
      for (var i = 0; i < items.length; i++)
        InkWell(
          onTap: () async {
            final it = await _itemDialog(context, l, items[i]);
            if (it != null) set([...items]..[i] = it);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairline))),
            child: Row(children: [
              Expanded(child: Text(items[i].name, style: AppText.body(12.5), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text(
                '${f.num(items[i].qty, items[i].qty == items[i].qty.roundToDouble() ? 0 : 1)} ${items[i].unit}${items[i].massKg > 0 ? ' · ${f.num(items[i].totalKg, 1)} kg' : ''}',
                style: AppText.mono(10.5, color: AppColors.textDim),
              ),
              IconButton(
                tooltip: l.msnDelete,
                visualDensity: VisualDensity.compact,
                onPressed: () => set([...items]..removeAt(i)),
                icon: const Icon(Icons.close, size: 14, color: AppColors.textDim),
              ),
            ]),
          ),
        ),
    ]);
  }

  Future<MissionItem?> _itemDialog(BuildContext context, AppLocalizations l, MissionItem? item) {
    final name = TextEditingController(text: item?.name ?? '');
    final qty = TextEditingController(text: item == null ? '1' : '${item.qty}');
    final unit = TextEditingController(text: item?.unit ?? '');
    final mass = TextEditingController(text: item == null || item.massKg == 0 ? '' : '${item.massKg}');
    String? nameErr, qtyErr, massErr;
    // Vacío da el valor por omisión; negativo, letras o un tope excedido se avisan y no se guardan.
    double? parse(TextEditingController c, double dflt) {
      final t = c.text.trim().replaceAll(',', '.');
      if (t.isEmpty) return dflt;
      final v = double.tryParse(t);
      return v != null && v >= 0 && v <= 100000 ? v : null;
    }

    final numFmt = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    return showDialog<MissionItem>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(l.msnAddItem.toUpperCase(), style: AppText.head(15)),
          content: SizedBox(
            width: 340,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: name,
                autofocus: true,
                style: AppText.body(14),
                decoration: _deco(l.msnItemName).copyWith(errorText: nameErr),
                onChanged: (_) => set(() => nameErr = null),
              ),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: TextField(
                    controller: qty,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: numFmt,
                    style: AppText.mono(14),
                    decoration: _deco(l.msnItemQty).copyWith(errorText: qtyErr, errorMaxLines: 2),
                    onChanged: (_) => set(() => qtyErr = null),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: unit, style: AppText.body(14), decoration: _deco(l.msnItemUnit))),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: mass,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: numFmt,
                style: AppText.mono(14),
                decoration: _deco(l.msnItemMass).copyWith(errorText: massErr, errorMaxLines: 2),
                onChanged: (_) => set(() => massErr = null),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel.toUpperCase(), style: AppText.label())),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: AppColors.bg, shape: const RoundedRectangleBorder()),
              onPressed: () {
                final n = name.text.trim();
                final q = parse(qty, 1), ms = parse(mass, 0);
                if (n.isEmpty || q == null || ms == null) {
                  set(() {
                    nameErr = n.isEmpty ? l.errNameRequired : null;
                    qtyErr = q == null ? l.errNonNegative : null;
                    massErr = ms == null ? l.errNonNegative : null;
                  });
                  return;
                }
                Navigator.pop(ctx, MissionItem(name: n, qty: q, unit: unit.text.trim(), massKg: ms));
              },
              child: Text(l.save.toUpperCase(), style: AppText.label(color: AppColors.bg)),
            ),
          ],
        ),
      ),
    );
  }
}
