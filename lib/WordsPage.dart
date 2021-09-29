import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ChineseCharacterView/ChineseCharacterView.dart';
import 'package:ChineseCharacterView/sqlHelper.dart';
import 'package:ChineseCharacterView/fontStrokeDataBean.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/rendering.dart';

class WordsPage extends StatefulWidget {
  WordsPage({Key key}) : super(key: key);

  @override
  _WordsPageState createState() => _WordsPageState();
}

class _WordsPageState extends State<WordsPage> {
 
  String str = """[
{
"character":"好",
"pronunciation":"hǎo",
"part":"女",
"words":[
  {"word":"好坏",
   "explanation":"好坏的释义"
  },
  {"word":"好人",
   "explanation":"好人的释义"
  }
]
},
{
"character":"红",
"pronunciation":"hóng",
"part":"纟",
"words":[
  {"word":"红色",
   "explanation":"红色的释义红色的释义红色的释义红色的释义红色的释义红色的释义红色的释义红色的释义红色的释义红色的释义红色的释义红色的释义红色的释义红色的释义红色的释义"
  },
  {"word":"真红",
   "explanation":"真红的释义真红的释义真红的释义真红的释义真红的释义真红的释义真红的释义真红的释义真红的释义真红的释义真红的释义真红的释义真红的释义真红的释义真红的释义真红的释义真红的释义真红的释义真红的释义真红的释义真红的释义真红的释义真红的释义"
  }
]
}
]""";

  String curCharacter = "红";
  List<Map> words;

  @override
  Widget build(BuildContext context) {
    this.words = _parseWordsData(str);

    return Column(
       children:[
         ListTile(
           title:Text(this.curCharacter,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.w400
              ),
         )),
         //Column遇到无限延展的child，如这里的ListView需要用Expanded转为严格约束
         Expanded(
           child: _buildWords()
         )
       ]
    );
  }

  Widget _buildWords(){
    return ListView.builder(
      padding: EdgeInsets.all(10.0),
      itemCount: this.words.length * 2 + 1,
      itemBuilder: (context,i){
        if (i.isEven) return const Divider(
          thickness: 1.0,
          color: Colors.black26,
        );
        else{
          int index = i ~/ 2;
          return ListTile(
            title:Container(
              width:double.infinity,
              height:40,
              child:Text(this.words[index]["word"],
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
            ),
            subtitle: Text("    ${this.words[index]["explanation"]}"),
          );
        }
      }
    );
  }

  _parseWordsData(String str){
    List<Map> words;
    if(str != null && str.length > 0){
      List<Map<String,dynamic>> list1 = (jsonDecode(str) as List<dynamic>).cast<Map<String,dynamic>>();
      list1.forEach((element) {
        if(element["character"] == curCharacter){
          //必须转成Map<String,dynamic>而不能是Map<String,String>
          words = (element["words"] as List<dynamic>).cast<Map<String,dynamic>>();
          return;
        }
      });
    }
    return words;
  }
}