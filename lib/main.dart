import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/find_locale.dart';
import 'package:kennzeichen/database/index.dart';
import 'package:kennzeichen/router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_theme/system_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final locale = await findSystemLocale();
  await initializeDateFormatting(locale);

  await SystemTheme.accentColor.load();

  await Database.init();

  final app = MyApp(
    prefs: await SharedPreferences.getInstance(),
    platform: await PackageInfo.fromPlatform(),
  );

  runApp(app);
}

class MyApp extends StatelessWidget {
  static MyApp? _instance;
  static MyApp get() => _instance!;

  final SharedPreferences prefs;
  final PackageInfo platform;

  MyApp({
    super.key,
    required this.prefs,
    required this.platform,
  }) : assert(_instance == null) {
    _instance = this;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Kennzeichen',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: SystemTheme.accentColor.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: SystemTheme.accentColor.dark,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
