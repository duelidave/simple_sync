import 'package:flutter/material.dart';

import 'home_page.dart';

void main() {
  runApp(const FileSyncApp());
}

class FileSyncApp extends StatelessWidget {
  const FileSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Sync',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const FileSyncHomePage(),
    );
  }
}
