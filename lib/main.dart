import 'package:flutter/material.dart';
import 'package:ChineseCharacterView/TabsPage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChineseCharacterView',
      home: TabsPage(),
      debugShowCheckedModeBanner:false
    );
  }
}