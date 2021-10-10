import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:ChineseCharacterView/models/StrokeModel.dart';

class WordsPage extends StatefulWidget {
  WordsPage({Key key}) : super(key: key);

  @override
  _WordsPageState createState() => _WordsPageState();
}

class _WordsPageState extends State<WordsPage> {
  String curCharacter;
  List<Map> words;

  @override
  Widget build(BuildContext context) {

    return Consumer<StrokeModel>(
        builder: (context, fontInfo, child){
          curCharacter = fontInfo.curFont;
          words = _parseWordsData(fontInfo.fontInfo);

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: _getWordsTile()
          );
      });
  }

  Widget _buildWords() {
    return ListView.builder(
        padding: EdgeInsets.all(10.0),
        itemCount: this.words.length * 2 + 1,
        itemBuilder: (context, i) {
          if (i.isEven)
            return const Divider(
              thickness: 1.0,
              color: Colors.black26,
            );
          else {
            int index = i ~/ 2;
            return ListTile(
              title: Container(
                width: double.infinity,
                height: 40,
                child: Text(
                  this.words[index]["word"],
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
              ),
              subtitle: Text("    ${this.words[index]["explanation"]}"),
            );
          }
        });
  }

  List<Widget> _getWordsTile() {
    if (words != null && words.length != 0) {
      return [
        ListTile(
            title: Text(
          this.curCharacter,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 35, fontWeight: FontWeight.w400),
        )),
        //Column遇到无限延展的child，如这里的ListView需要用Expanded转为严格约束
        Expanded(child: _buildWords())
      ];
    } else {
      return [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(
            "暂无数据",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w400,
            ),
          )
        ])
      ];
    }
  }

  _parseWordsData(String str) {
    List<Map> words;
    if (str != null && str.length > 0) {
      List<Map<String, dynamic>> list1 =
          (jsonDecode(str) as List<dynamic>).cast<Map<String, dynamic>>();

      for (Map<String, dynamic> item in list1) {
        if (item["character"] == curCharacter) {
          words = (item["words"] as List<dynamic>).cast<Map<String, dynamic>>();
          break;
        }
      }
    }
    return words;
  }
}
