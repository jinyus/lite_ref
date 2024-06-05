import 'package:flutter/material.dart';
import 'package:flutter_example/deps.dart';
import 'package:flutter_example/error_app.dart';
import 'package:flutter_example/loading_app.dart';
import 'package:flutter_example/settings/view.dart';
import 'package:lite_ref/lite_ref.dart';

void main(List<String> args) {
  runApp(const LiteRefScope(child: MyApp()));
}

enum AppLoaderState {
  loading,
  loaded,
  error;

  bool get isLoaded => this == AppLoaderState.loaded;

  bool get isLoading => this == AppLoaderState.loading;

  bool get hasError => this == AppLoaderState.error;
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<void>? _appLoader;
  AppLoaderState _loadingState = AppLoaderState.loading;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appLoader ??= _loadApp(context).then((value) {
      if (mounted) {
        setState(() {
          _loadingState = AppLoaderState.loaded;
        });
      }
    }).catchError(
      (error, stackTrace) {
        if (mounted) {
          setState(() {
            _loadingState = AppLoaderState.error;
          });
        }
      },
    );
  }

  Future<void> _loadApp(BuildContext context) async {
    await settingsControllerRef.read(context);
    await Future<dynamic>.delayed(const Duration(seconds: 2));
  }

  @override
  Widget build(BuildContext context) {
    return switch (_loadingState) {
      AppLoaderState.loading => const LoadingApp(),
      AppLoaderState.loaded => const LoadedApp(),
      AppLoaderState.error => const ErrorApp(),
    };
  }
}

class LoadedApp extends StatelessWidget {
  const LoadedApp({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = settingsControllerRef.assertOf(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return MaterialApp(
          theme: ThemeData(),
          darkTheme: ThemeData.dark(),
          themeMode: controller.themeMode,
          onGenerateRoute: (RouteSettings routeSettings) {
            return MaterialPageRoute<void>(
              settings: routeSettings,
              builder: (BuildContext context) {
                switch (routeSettings.name) {
                  case SettingsView.routeName:
                    return const SettingsView();
                  default:
                    return const HomePage();
                }
              },
            );
          },
        );
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(context, title: 'Lite Ref Example'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              key: const Key('settings'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 100),
                textStyle: const TextStyle(fontSize: 40),
              ),
              onPressed: () {
                Navigator.of(context).pushNamed(SettingsView.routeName);
              },
              child: const Text('Goto Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class MyAppBar extends AppBar {
  MyAppBar(
    BuildContext context, {
    required String title,
    super.key,
  }) : super(
          title: Text(title),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          iconTheme: Theme.of(context).iconTheme.copyWith(
                color: Theme.of(context).colorScheme.onSecondary,
              ),
          titleTextStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSecondary,
            fontSize: 20,
          ),
        );
}
