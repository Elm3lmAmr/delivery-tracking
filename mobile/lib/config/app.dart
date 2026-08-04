import 'package:flutter/material.dart';
import 'router.dart';
import 'theme.dart';

class EdaraApp extends StatelessWidget {
  const EdaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Edara Delivery',
      theme: buildEdaraTheme(),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
