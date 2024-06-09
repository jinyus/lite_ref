import 'package:flutter/material.dart';

/// The application uses RouterDelegate to avoid overwriting
/// `WidgetsBinding.instance.platformDispatcher.defaultRouteName`
/// for further use of this variable in the application once it is loaded.
/// This is often necessary if you want to support web or `deep links`.
class LoadingApp extends StatelessWidget {
  const LoadingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerDelegate: InitRouterDelegate(
        child: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}

/// Displays widget without handling routes.
class InitRouterDelegate extends RouterDelegate<Object> with ChangeNotifier {
  InitRouterDelegate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }

  @override
  Future<void> setNewRoutePath(Object configuration) async {}

  @override
  Future<bool> popRoute() async {
    return false;
  }
}
