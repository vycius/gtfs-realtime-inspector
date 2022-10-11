import 'package:flutter/material.dart';

import 'package:gtfs_realtime_inspector/navigator_routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GTFS Realtime inspector',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: NavigatorRoutes.routeHome,
      onGenerateRoute: NavigatorRoutes.onGenerateRoute,
    );
  }
}
