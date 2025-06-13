import 'package:flutter/material.dart';

class ChaptersPage extends StatefulWidget {
  final String? mangaId;
  final String? mangaTitle;
  const ChaptersPage({super.key, this.mangaId, this.mangaTitle});

  @override
  State<ChaptersPage> createState() => _ChaptersPageState();
}

class _ChaptersPageState extends State<ChaptersPage> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
