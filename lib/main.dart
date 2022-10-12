import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gtfs_realtime_inspector/code_view_cubit.dart';
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
    return BlocProvider(
      create: (_) => FilterCubit(),
      child: MaterialApp(
        title: 'GTFS Realtime inspector',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: NavigatorRoutes.routeHome,
        onGenerateRoute: NavigatorRoutes.onGenerateRoute,
      ),
    );
  }
}
