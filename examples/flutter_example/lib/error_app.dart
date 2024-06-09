import 'package:flutter/material.dart';

class ErrorApp extends StatelessWidget {
  const ErrorApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Something went wrong.'),
        ),
      ),
    );
  }
}
