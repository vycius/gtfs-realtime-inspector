import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppFutureBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loadingBuilder;

  const AppFutureBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.loadingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasData &&
            snapshot.connectionState == ConnectionState.done) {
          return builder(context, snapshot.requireData);
        } else if (snapshot.hasError) {
          if (kDebugMode) {
            print('Error while loading future: ${snapshot.error}');
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Error: ${snapshot.error}\n${snapshot.stackTrace}',
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            ),
          );
        }

        final loadingBuilderFunc = loadingBuilder;
        if (loadingBuilderFunc != null) {
          return loadingBuilderFunc(context);
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('Loading...'),
              )
            ],
          ),
        );
      },
    );
  }
}
