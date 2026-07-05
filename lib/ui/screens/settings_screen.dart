import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';
import '../widgets/common/app_background.dart';
import '../widgets/common/app_card.dart';

/// Ajustes del jugador (plan §8.5): audio, juego, apariencia y acerca de.
/// Todo se persiste vía [SettingsProvider] y aplica en caliente.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final palette = context.palette;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _Section(title: l.settingsAudio),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Column(
                children: [
                  _SwitchTile(
                    label: l.settingsSound,
                    value: settings.soundEnabled,
                    onChanged: (v) => settings.soundEnabled = v,
                  ),
                  _Divider(color: palette.border),
                  _SwitchTile(
                    label: l.settingsMusic,
                    value: settings.musicEnabled,
                    onChanged: (v) => settings.musicEnabled = v,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _Section(title: l.settingsGameplay),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Column(
                children: [
                  _SwitchTile(
                    label: l.settingsVibration,
                    value: settings.vibrationEnabled,
                    onChanged: (v) => settings.vibrationEnabled = v,
                  ),
                  _Divider(color: palette.border),
                  _SwitchTile(
                    label: l.settingsInvertControls,
                    subtitle: l.settingsInvertControlsDesc,
                    value: settings.invertControls,
                    onChanged: (v) => settings.invertControls = v,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _Section(title: l.settingsAppearance),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.settingsTheme,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 12),
                  _ThemeSelector(
                    value: settings.themeMode,
                    onChanged: (m) => settings.themeMode = m,
                  ),
                  const SizedBox(height: 20),
                  Text(l.settingsLanguage,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 12),
                  _SegmentedTwo(
                    leftLabel: 'Español',
                    rightLabel: 'English',
                    leftSelected: settings.localeCode == 'es',
                    onLeft: () => settings.localeCode = 'es',
                    onRight: () => settings.localeCode = 'en',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _Section(title: l.settingsAbout),
            AppCard(
              child: Row(
                children: [
                  Text(l.settingsVersion,
                      style: TextStyle(color: palette.textPrimary)),
                  const Spacer(),
                  const _VersionText(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: context.palette.textMuted,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: palette.textPrimary)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: TextStyle(
                          color: palette.textMuted, fontSize: 12)),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: palette.primary,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: color);
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final options = <(ThemeMode, String, IconData)>[
      (ThemeMode.system, l.settingsThemeSystem, Icons.brightness_auto_rounded),
      (ThemeMode.light, l.settingsThemeLight, Icons.light_mode_rounded),
      (ThemeMode.dark, l.settingsThemeDark, Icons.dark_mode_rounded),
    ];
    final palette = context.palette;
    return Row(
      children: [
        for (final o in options)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onChanged(o.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: value == o.$1
                        ? palette.primary.withValues(alpha: 0.15)
                        : palette.surfaceLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: value == o.$1 ? palette.primary : palette.border,
                      width: value == o.$1 ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(o.$3,
                          size: 20,
                          color: value == o.$1
                              ? palette.primary
                              : palette.textMuted),
                      const SizedBox(height: 6),
                      Text(
                        o.$2,
                        style: TextStyle(
                          color: value == o.$1
                              ? palette.primary
                              : palette.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SegmentedTwo extends StatelessWidget {
  const _SegmentedTwo({
    required this.leftLabel,
    required this.rightLabel,
    required this.leftSelected,
    required this.onLeft,
    required this.onRight,
  });

  final String leftLabel;
  final String rightLabel;
  final bool leftSelected;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    Widget seg(String label, bool selected, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? palette.primary.withValues(alpha: 0.15)
                    : palette.surfaceLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? palette.primary : palette.border,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? palette.primary : palette.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
    return Row(
      children: [
        seg(leftLabel, leftSelected, onLeft),
        const SizedBox(width: 8),
        seg(rightLabel, !leftSelected, onRight),
      ],
    );
  }
}

class _VersionText extends StatelessWidget {
  const _VersionText();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snap) {
        final v = snap.hasData
            ? '${snap.data!.version} (${snap.data!.buildNumber})'
            : '—';
        return Text(v, style: TextStyle(color: palette.textMuted));
      },
    );
  }
}