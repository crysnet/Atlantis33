import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../state/app_model.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Diálogo para editar nombre, tipo, prioridad y tiempo de trabajo de un objetivo, o borrarlo.
Future<void> showObjectiveDialog(BuildContext context, AppModel m, String id) async {
  final o = m.objective(id);
  if (o == null) return;
  final l = AppLocalizations.of(context)!;
  final name = TextEditingController(text: o.name);
  final work = TextEditingController(text: o.workMin.round().toString());
  var type = o.type;
  var priority = o.priority;
  var transport = o.transport;
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) {
        InputDecoration deco(String label) => InputDecoration(
              labelText: label,
              labelStyle: AppText.label(),
              isDense: true,
              enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.hairline)),
              focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.orange)),
            );
        return AlertDialog(
          title: Text(l.objectiveEdit.toUpperCase(), style: AppText.head(15)),
          content: SizedBox(
            width: 360,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(controller: name, style: AppText.body(14), decoration: deco(l.fieldName)),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: type,
                dropdownColor: AppColors.panel3,
                style: AppText.body(14),
                decoration: deco(l.fieldType),
                items: [
                  for (final t in const ['sample', 'image', 'measurement', 'equipment'])
                    DropdownMenuItem(value: t, child: Text(typeName(l, t))),
                ],
                onChanged: (v) => set(() => type = v ?? type),
              ),
              const SizedBox(height: 14),
              Text(l.fieldPriority.toUpperCase(), style: AppText.label()),
              const SizedBox(height: 6),
              Row(children: [
                for (var p = 1; p <= 5; p++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => set(() => priority = p),
                      child: Container(
                        width: 40,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: priority == p ? AppColors.orange : Colors.transparent,
                          border: Border.all(color: priority == p ? AppColors.orange : AppColors.hairline),
                        ),
                        child: Text('$p', style: AppText.mono(13, color: priority == p ? AppColors.bg : AppColors.text, weight: FontWeight.w700)),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 14),
              Text(l.transportTitle.toUpperCase(), style: AppText.label()),
              const SizedBox(height: 6),
              Row(children: [
                for (final (v, icon) in const [('foot', Icons.directions_walk), ('vehicle', Icons.local_shipping_outlined), ('hybrid', Icons.swap_horiz)])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () => set(() => transport = v),
                        child: Container(
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: transport == v ? AppColors.orange : Colors.transparent,
                            border: Border.all(color: transport == v ? AppColors.orange : AppColors.hairline),
                          ),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(icon, size: 14, color: transport == v ? AppColors.bg : AppColors.textDim),
                            const SizedBox(width: 4),
                            Flexible(child: Text(transportName(l, v), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.label(color: transport == v ? AppColors.bg : AppColors.text))),
                          ]),
                        ),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 4),
              Text(l.transportHint, style: AppText.body(11, color: AppColors.textMute, height: 1.4)),
              const SizedBox(height: 14),
              TextField(
                controller: work,
                keyboardType: TextInputType.number,
                style: AppText.mono(14),
                decoration: deco(l.fieldWork),
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                m.removeObjective(id);
              },
              child: Text(l.delete.toUpperCase(), style: AppText.label(color: AppColors.red)),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel.toUpperCase(), style: AppText.label())),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: AppColors.bg, shape: const RoundedRectangleBorder()),
              onPressed: () {
                final minutes = double.tryParse(work.text.trim()) ?? o.workMin;
                Navigator.pop(ctx);
                m.updateObjective(id, name: name.text.trim().isEmpty ? o.name : name.text.trim(), type: type, priority: priority, workMin: minutes.clamp(0, 600).toDouble(), transport: transport);
              },
              child: Text(l.save.toUpperCase(), style: AppText.label(color: AppColors.bg)),
            ),
          ],
        );
      },
    ),
  );
}
