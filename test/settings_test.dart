import 'dart:convert';

import 'package:ayatsuri/settings/app_settings.dart';
import 'package:ayatsuri/l10n/app_localizations.dart';
import 'package:ayatsuri/settings/settings_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('settings JSON round-trip preserves fields', () {
    const original = AppSettings(
      themeMode: ThemeMode.dark,
      pureBlack: true,
      textScale: 1.2,
      autoRotate: true,
      rotationSpeed: 0.01,
      markerScale: 1.5,
      initialView: InitialView.custom,
      customLat: 10,
      customLng: 20,
      maxDelayMs: 300,
      hideBlocked: true,
      probeSort: ProbeSort.name,
      compactNodeList: true,
      backgroundOpacity: 0.4,
      locale: AppLocale.zh,
      serverUrl: 'http://192.168.0.2:9091',
      secret: 'foobar',
    );
    final restored = AppSettings.fromJson(
      jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
    );
    expect(restored.themeMode, ThemeMode.dark);
    expect(restored.pureBlack, isTrue);
    expect(restored.textScale, 1.2);
    expect(restored.autoRotate, isTrue);
    expect(restored.rotationSpeed, 0.01);
    expect(restored.markerScale, 1.5);
    expect(restored.initialView, InitialView.custom);
    expect(restored.latLngLat, 10);
    expect(restored.latLngLng, 20);
    expect(restored.maxDelayMs, 300);
    expect(restored.hideBlocked, isTrue);
    expect(restored.probeSort, ProbeSort.name);
    expect(restored.compactNodeList, isTrue);
    expect(restored.backgroundOpacity, 0.4);
    expect(restored.locale, AppLocale.zh);
    expect(restored.serverUrl, 'http://192.168.0.2:9091');
    expect(restored.secret, 'foobar');
    expect(restored.locale.flutterLocale, const Locale('zh'));
  });

  test('locale defaults to follow-system and old JSON stays readable', () {
    expect(const AppSettings().locale, AppLocale.system);
    expect(AppLocale.system.flutterLocale, isNull);
    expect(AppLocale.en.flutterLocale, const Locale('en'));
    final restored = AppSettings.fromJson({'v': 1});
    expect(restored.locale, AppLocale.system);
    final bad = AppSettings.fromJson({'locale': 'xx'});
    expect(bad.locale, AppLocale.system);
  });

  test('corrupt stored settings fall back to defaults', () async {
    SharedPreferences.setMockInitialValues({
      'ayatsuri_settings_v1': 'not-json{{{',
    });
    final controller = AppSettingsController();
    await controller.load();
    expect(controller.loaded, isTrue);
    expect(controller.settings.themeMode, ThemeMode.system);
  });

  testWidgets('settings page renders and persists theme mode change', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppSettingsController();
    await controller.load();
    await tester.pumpWidget(
      MaterialApp(
        locale: controller.settings.locale.flutterLocale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsPage(controller: controller),
      ),
    );
    expect(find.text('Appearance'), findsOneWidget);
    // TextFields carry their own internal Scrollables, so
    // scrollUntilVisible's default byType(Scrollable) lookup would find
    // several; drag the list directly instead.
    Future<void> scrollTo(String text) async {
      for (var i = 0; i < 10 && find.text(text).evaluate().isEmpty; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -200));
        await tester.pumpAndSettle();
      }
      expect(find.text(text), findsOneWidget);
    }

    await scrollTo('Background');
    await scrollTo('Globe');
    await scrollTo('Node probe');
    await tester.drag(find.byType(ListView), const Offset(0, 2000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').first);
    await tester.pumpAndSettle();
    expect(controller.settings.themeMode, ThemeMode.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ayatsuri_settings_v1'), isNotNull);
  });

  testWidgets('language switch applies Chinese live and persists', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppSettingsController();
    await controller.load();
    await tester.pumpWidget(
      ListenableBuilder(
        listenable: controller,
        builder: (context, _) => MaterialApp(
          locale: controller.settings.locale.flutterLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsPage(controller: controller),
        ),
      ),
    );
    expect(find.text('Settings'), findsOneWidget);
    await tester.tap(find.text('简体中文'));
    await tester.pumpAndSettle();
    expect(controller.settings.locale, AppLocale.zh);
    expect(find.text('设置'), findsOneWidget);
    expect(find.text('外观'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ayatsuri_settings_v1'), contains('"locale":"zh"'));
  });
}
