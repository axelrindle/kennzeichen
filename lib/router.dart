import 'package:go_router/go_router.dart';
import 'package:kennzeichen/pages/home.dart';
import 'package:kennzeichen/pages/settings.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: "/",
      name: "Home",
      builder: (context, state) => const PageHome(),
    ),
    GoRoute(
      path: "/settings",
      name: "Settings",
      builder: (context, state) => const PageSettings(),
    )
  ],
);
