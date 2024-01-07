import 'package:flutter/material.dart';
import 'package:flutter_example/deps.dart';
import 'package:flutter_example/settings/view.dart';

void main(List<String> args) {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = settingsControllerRef();
    return FutureBuilder(
      future: controller.loadSettings(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Initialization failed:\n${snapshot.error}'),
          );
        } else if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
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

  // @override
  // Widget build(BuildContext context) {
  //   return AppBar(
  //     title: const Text('LiteRef Example'),
  //     backgroundColor: Theme.of(context).colorScheme.secondary,
  //     titleTextStyle: TextStyle(
  //       color: Theme.of(context).colorScheme.onSecondary,
  //       fontSize: 20,
  //     ),
  //   );
  // }
}
