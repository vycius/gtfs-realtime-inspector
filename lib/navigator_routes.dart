import 'package:flutter/material.dart';
import 'package:gtfs_realtime_inspector/screens/main_screen.dart';

class NavigatorRoutes {
  static const routeHome = 'home';

  NavigatorRoutes._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case routeHome:
        return MaterialPageRoute(
          builder: (context) {
            return MainScreen();
          },
        );
      default:
        throw Exception(
          'Unable to find route ${settings.name} in navigator_routes.dart',
        );
    }
  }
}
