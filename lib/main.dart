import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ignore: depend_on_referenced_packages
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:gtfs_realtime_inspector/extensions.dart';
import 'package:gtfs_realtime_inspector/feeds_input/feeds_input.dart';
import 'package:gtfs_realtime_inspector/info/views/info_page.dart';
import 'package:gtfs_realtime_inspector/inspect/inspect.dart';
import 'package:gtfs_realtime_inspector/utils.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl_browser.dart';

Future<void> main() async {
  if (!kDebugMode) usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting(await findSystemLocale());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const inputDecorationTheme = InputDecorationTheme(
      border: OutlineInputBorder(),
      helperMaxLines: 5,
      errorMaxLines: 5,
    );

    final lightTheme = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.indigo,
      inputDecorationTheme: inputDecorationTheme,
      brightness: Brightness.light,
    );
    final darkTheme = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.indigo,
      inputDecorationTheme: inputDecorationTheme,
      brightness: Brightness.dark,
    );

    return MaterialApp.router(
      title: 'GTFS Realtime inspector',
      theme: lightTheme,
      darkTheme: darkTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}

final GoRouter _router = GoRouter(
  routes: <GoRoute>[
    GoRoute(
      name: 'input',
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        final queryParams = state.queryParametersAll;

        final gtfsUrl = queryParams['gtfs_url']?.firstOrNull?.emptyToNull();
        final gtfsRealtimeUrls = queryParams['gtfs_realtime_urls'] ?? [];

        return FeedsInputPage(
          initialGtfsUrl: gtfsUrl,
          initialGtfsRealtimeUrls: gtfsRealtimeUrls,
        );
      },
      routes: [
        GoRoute(
          name: 'inspect',
          path: 'inspect',
          builder: (BuildContext context, GoRouterState state) {
            final queryParams = state.queryParametersAll;

            final gtfsUrl = queryParams['gtfs_url']?.firstOrNull?.emptyToNull();
            final gtfsRealtimeUrls = queryParams['gtfs_realtime_urls']!;

            return InspectPage(
              gtfsUrl: gtfsUrl,
              gtfsRealtimeUrls: gtfsRealtimeUrls,
            );
          },
          redirect: (BuildContext context, GoRouterState state) {
            if (state.name == 'inspect') {
              final queryParams = state.queryParametersAll;

              final gtfsUrl =
                  queryParams['gtfs_url']?.firstOrNull?.emptyToNull();
              final gtfsRealtimeUrls = queryParams['gtfs_realtime_urls'];

              if (gtfsUrl != null && !isValidUrl(gtfsUrl)) {
                return '/';
              }

              if (gtfsRealtimeUrls == null ||
                  gtfsRealtimeUrls.isEmpty ||
                  gtfsRealtimeUrls.any((u) => !isValidUrl(u))) {
                return '/';
              }
            }

            return null;
          },
          routes: [
            GoRoute(
              name: 'info',
              path: 'info',
              pageBuilder: (BuildContext context, GoRouterState state) {
                final queryParams = state.queryParametersAll;

                final gtfsUrl =
                    queryParams['gtfs_url']?.firstOrNull?.emptyToNull();
                final gtfsRealtimeUrls = queryParams['gtfs_realtime_urls']!;

                return MaterialPage(
                  fullscreenDialog: true,
                  child: InfoPage(
                    gtfsUrl: gtfsUrl,
                    gtfsRealtimeUrls: gtfsRealtimeUrls,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    ),
  ],
);
