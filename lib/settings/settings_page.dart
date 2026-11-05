/* Material 3 settings page (FlClash-style, personalization-first). */
import 'package:flutter/material.dart';
import 'package:ayatsuri/l10n/app_localizations.dart';

import 'app_settings.dart';

const _seedPresets = <Color>[
  Color(0xFFE65100), // orange (default)
  Color(0xFF6750A4), // purple
  Color(0xFF0061A4), // blue
  Color(0xFF006A6A), // teal
  Color(0xFF2E7D32), // green
  Color(0xFFB3261E), // red
  Color(0xFFAD1457), // pink
  Color(0xFF455A64), // slate
];

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.controller});
  final AppSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final s = controller.settings;
        final l10n = AppLocalizations.of(context);
        void set(AppSettings next) => controller.update(next);
        return Scaffold(
          appBar: AppBar(title: Text(l10n.settingsTitle)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _header(context, l10n.language),
              SegmentedButton<AppLocale>(
                segments: [
                  ButtonSegment(
                    value: AppLocale.system,
                    label: Text(l10n.languageSystem),
                  ),
                  ButtonSegment(
                    value: AppLocale.zh,
                    label: Text(l10n.languageZh),
                  ),
                  ButtonSegment(
                    value: AppLocale.en,
                    label: Text(l10n.languageEn),
                  ),
                ],
                selected: {s.locale},
                onSelectionChanged: (v) => set(s.copyWith(locale: v.first)),
              ),
              const SizedBox(height: 12),
              _header(context, l10n.appearance),
              SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(l10n.themeSystem),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(l10n.themeLight),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(l10n.themeDark),
                  ),
                ],
                selected: {s.themeMode},
                onSelectionChanged: (v) => set(s.copyWith(themeMode: v.first)),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.themeColor,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _seedPresets.map((c) {
                  final selected = c.toARGB32() == s.seedColor.toARGB32();
                  return GestureDetector(
                    onTap: () => set(s.copyWith(seedColor: c)),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              SwitchListTile(
                title: Text(l10n.pureBlack),
                subtitle: Text(l10n.pureBlackSub),
                value: s.pureBlack,
                onChanged: (v) => set(s.copyWith(pureBlack: v)),
              ),
              ListTile(
                title: Text(l10n.colorStyle),
                subtitle: Text(s.schemeVariant.name),
                trailing: DropdownButton<DynamicSchemeVariant>(
                  value: s.schemeVariant,
                  underline: const SizedBox.shrink(),
                  items: DynamicSchemeVariant.values
                      .map(
                        (v) => DropdownMenuItem(value: v, child: Text(v.name)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) set(s.copyWith(schemeVariant: v));
                  },
                ),
              ),
              _sliderTile(
                context,
                l10n.textSize,
                s.textScale,
                0.85,
                1.3,
                (v) => set(s.copyWith(textScale: v)),
                '${s.textScale.toStringAsFixed(2)}×',
              ),
              const Divider(height: 32),
              _header(context, l10n.background),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 160,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: controller.backgroundBytes != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(
                              controller.backgroundBytes!,
                              fit: BoxFit.cover,
                            ),
                            Container(
                              color: Theme.of(context).colorScheme.surface
                                  .withValues(alpha: s.backgroundOpacity),
                            ),
                          ],
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.image_outlined, size: 36),
                              const SizedBox(height: 8),
                              Text(l10n.noCustomBackground),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => controller.pickBackground(),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(l10n.pickImage),
                  ),
                  const SizedBox(width: 8),
                  if (controller.backgroundBytes != null)
                    OutlinedButton.icon(
                      onPressed: () => controller.clearBackground(),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(l10n.remove),
                    ),
                ],
              ),
              _sliderTile(
                context,
                l10n.backgroundDimming,
                s.backgroundOpacity,
                0.0,
                1.0,
                (v) => set(s.copyWith(backgroundOpacity: v)),
                '${(s.backgroundOpacity * 100).round()}%',
              ),
              const Divider(height: 32),
              _header(context, l10n.globeHeader),
              SwitchListTile(
                title: Text(l10n.autoRotate),
                value: s.autoRotate,
                onChanged: (v) => set(s.copyWith(autoRotate: v)),
              ),
              _sliderTile(
                context,
                l10n.rotationSpeed,
                s.rotationSpeed,
                0.002,
                0.05,
                (v) => set(s.copyWith(rotationSpeed: v)),
                s.rotationSpeed.toStringAsFixed(3),
              ),
              _sliderTile(
                context,
                l10n.globeScale,
                s.globeScale,
                0.7,
                1.3,
                (v) => set(s.copyWith(globeScale: v)),
                '${s.globeScale.toStringAsFixed(2)}×',
              ),
              _sliderTile(
                context,
                l10n.markerSize,
                s.markerScale,
                0.5,
                2.0,
                (v) => set(s.copyWith(markerScale: v)),
                '${s.markerScale.toStringAsFixed(1)}×',
              ),
              ListTile(
                title: Text(l10n.initialView),
                subtitle: Text(s.initialView.name),
                trailing: DropdownButton<InitialView>(
                  value: s.initialView,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(
                      value: InitialView.asia,
                      child: Text(l10n.asiaView),
                    ),
                    DropdownMenuItem(
                      value: InitialView.global,
                      child: Text(l10n.globalView),
                    ),
                    DropdownMenuItem(
                      value: InitialView.custom,
                      child: Text(l10n.customView),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) set(s.copyWith(initialView: v));
                  },
                ),
              ),
              if (s.initialView == InitialView.custom) ...[
                _sliderTile(
                  context,
                  l10n.latitude,
                  s.customLat,
                  -90,
                  90,
                  (v) => set(s.copyWith(customLat: v)),
                  '${s.customLat.round()}°',
                ),
                _sliderTile(
                  context,
                  l10n.longitude,
                  s.customLng,
                  -180,
                  180,
                  (v) => set(s.copyWith(customLng: v)),
                  '${s.customLng.round()}°',
                ),
              ],
              const Divider(height: 32),
              _header(context, l10n.nodeProbe),
              _sliderTile(
                context,
                l10n.maxDelayShown,
                s.maxDelayMs.toDouble(),
                0,
                1000,
                (v) => set(s.copyWith(maxDelayMs: v.round())),
                s.maxDelayMs == 0
                    ? l10n.unlimited
                    : l10n.maxDelayMs(s.maxDelayMs),
              ),
              SwitchListTile(
                title: Text(l10n.hideBlocked),
                value: s.hideBlocked,
                onChanged: (v) => set(s.copyWith(hideBlocked: v)),
              ),
              SegmentedButton<ProbeSort>(
                segments: [
                  ButtonSegment(
                    value: ProbeSort.delay,
                    label: Text(l10n.byDelay),
                  ),
                  ButtonSegment(
                    value: ProbeSort.name,
                    label: Text(l10n.byName),
                  ),
                ],
                selected: {s.probeSort},
                onSelectionChanged: (v) => set(s.copyWith(probeSort: v.first)),
              ),
              SwitchListTile(
                title: Text(l10n.compactNodeList),
                value: s.compactNodeList,
                onChanged: (v) => set(s.copyWith(compactNodeList: v)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 8),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    ),
  );

  Widget _sliderTile(
    BuildContext context,
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    String suffix,
  ) {
    return ListTile(
      title: Text(label),
      subtitle: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: ((max - min) * 20).round(),
        onChanged: onChanged,
      ),
      trailing: SizedBox(
        width: 72,
        child: Text(suffix, textAlign: TextAlign.end),
      ),
    );
  }
}
