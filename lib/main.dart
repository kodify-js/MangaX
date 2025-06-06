import 'package:flutter/material.dart';
import 'package:mangax/pages/home.dart';
import 'package:mangax/providers/theme_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TheameProvider(),
      child: Consumer<TheameProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'MangaX',
            theme: themeProvider.getTheme(),
            home: const Home(),
          );
        },
      ),
    );
  }
}
