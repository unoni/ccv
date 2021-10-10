import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ChineseCharacterView/pages/TabsPage.dart';
import 'package:ChineseCharacterView/models/StrokeModel.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChineseCharacterView',
      home: ChangeNotifierProvider(
        create: (context) => StrokeModel(),
        child:TabsPage()
      ),
      debugShowCheckedModeBanner:false
    );
  }
}

