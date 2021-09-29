import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ChineseCharacterView/ChineseCharacterView.dart';
import 'package:ChineseCharacterView/sqlHelper.dart';
import 'package:ChineseCharacterView/fontStrokeDataBean.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/rendering.dart';

class HomePage extends StatefulWidget {
  bool _autoDraw = false;

  set autoDraw(bool x){
    this._autoDraw = x; 
  }

  HomePage({
    Key key,
    bool autoDraw
    }) : super(key: key){
      this._autoDraw = autoDraw;
    }

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool autoDraw = false;
  TextEditingController _controller;
  SqlHelper helper;
  FontStrokeDataBean bean;
  String font;
  String strokeInfo;
  String medianInfo;

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

  List<Map> dataList;
  String pronunciation = "hao";
  String part = "暂无数据";

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    //如果使用IndexedStack就不会调用到dispose
    if(autoDraw){
      setState(() {
        autoDraw = false;
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.instance = ScreenUtil()..init(context);
    setState(() {
      autoDraw = widget._autoDraw;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _getTitleListTile(),
        ChineseCharacterView(
          strokeInfo: this.strokeInfo,
          medianInfo: this.medianInfo,
          size: Size(350, 350),
          autoDraw: this.autoDraw,
          drawGrid: true,
        ),
        Container(
          child: Row(children: <Widget>[
            //没有这个Expanded将无法显示内容
            Expanded(
              flex: 3,
              child: new TextField(
                controller: _controller,
                maxLength: 1,
                maxLines: 1,
                textAlign: TextAlign.left,
                decoration: InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    counterText: "",
                    hintText: "请输入要查询的字"),
              ),
            ),
            Expanded(
                flex: 1,
                child: new ElevatedButton(
                    onPressed: () async {
                      font = _controller.text;
                      helper = await SqlHelper.getInstance();
                      bean = await helper.query(font);
                      if(bean != null){
                        this.strokeInfo = bean.strokes;
                        this.medianInfo = bean.medians;
                        //curDrawingIndex = 0;
                        _parseFontData(str);
                        setState(() {});
                      }
                    },
                    child: Text("查询")))
          ]),
        ),
        ElevatedButton(
          child: Text("自动绘制,当前值：${this.autoDraw}"),
          style: ButtonStyle(),
          onPressed: () {
            setState(() {
              widget._autoDraw = !widget._autoDraw;
            });
          },
        ),
      ],
    );
  }

  _getTitleListTile(){
    if(this.bean != null){
      return Container(
        width: double.infinity,
        height: 80,
        padding:EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
        child:ListTile(
          title: Container(//ā
            child:Text(this.pronunciation,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                height: 1.2,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
                ),
            ),
            //ListTile的contentPadding也会影响到subTitle的padding，所以改用Container包裹住，仅对title的padding进行设置
            margin: EdgeInsets.only(
              left:40.0,
              right:10.0,
            ),
          ),       
          subtitle:Text(
            "偏旁部首:   ${this.part}",
            style:TextStyle(
              letterSpacing: 1.2,
            )
          ),
          //contentPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 10.0),
          trailing: Icon(Icons.volume_up),
        )
      );
    }else{
      return Container(
        width: double.infinity,
        height: 80,
        child:ListTile(
          title: Container(
            child:Text("",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
              ),
            ),
            margin: EdgeInsets.only(
              left:40.0,
              right:10.0,
              bottom: 10.0
            ),
          ), 
          subtitle:Text("")
       )
      );
    }
  }

  _parseFontData(String str){
    var data;
    if(str != null && str.length > 0){
      List<Map<String,dynamic>> list1 = (jsonDecode(str) as List<dynamic>).cast<Map<String,dynamic>>();
      //Flutter的list.foreach不能被break或return中断，所以使用for来迭代
      for(Map<String,dynamic> item in list1){
        if(item["character"] == this.font){
          this.part = item['part'];
          this.pronunciation = item['pronunciation']; 
          break;
        }

        this.part = "暂无数据";
        this.pronunciation = "暂无数据"; 
      }
    }
    return data;
  }
}
