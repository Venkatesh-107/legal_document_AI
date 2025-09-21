import 'package:flutter/material.dart';
import 'screens/summarizer_page.dart';
//main.dart

void main() {
  runApp(LegalDocApp());
}

class LegalDocApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Legal Doc Scanner",
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: SummarizerPage(),
    );
  }
}
