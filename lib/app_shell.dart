import 'package:flutter/material.dart';
import 'preload/app_preloader.dart';
import 'screens/homescreen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();

    // Start background preload AFTER first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppPreloader.instance.start();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}
