import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import 'package:ChineseCharacterView/ChineseCharacterView.dart';
import 'package:ChineseCharacterView/sqlHelper.dart';
import 'package:ChineseCharacterView/models/fontStrokeDataBean.dart';
import 'package:ChineseCharacterView/models/StrokeModel.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomePage extends StatefulWidget {

  HomePage({
    Key key,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController _controller;
  SqlHelper helper;
  FontStrokeDataBean bean;
  String font;
  String strokeInfo;
  String medianInfo;

  String str;

  List<Map> dataList;
  String pronunciation = "hao";
  String part = "暂无数据";

  //最近一次提交查询的时间
  var lastPopTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.instance = ScreenUtil()..init(context);
    this.str = Provider.of<StrokeModel>(context, listen: false).fontInfo;

    return Consumer<StrokeModel>(
        builder: (context, fontInfo, child) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _getTitleListTile(),
                ChineseCharacterView(
                  strokeInfo: this.strokeInfo,
                  medianInfo: this.medianInfo,
                  size: Size(350, 350),
                  autoDraw: fontInfo.autoDraw,
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
                            onPressed: (){
                              intervalClick(
                                needTime : 0,
                                function: () async {
                                  font = _controller.text;
                                  fontInfo.setCurFont(font);
                                  fontInfo.setNeedRefresh(true);
                                  helper = await SqlHelper.getInstance();
                                  bean = await helper.query(font);
                                  if (bean != null) {
                                    this.strokeInfo = bean.strokes;
                                    this.medianInfo = bean.medians;
                                    _parseFontData(str);
                                    setState(() {});
                                  }
                                }
                              );
                            },
                            child: Text("查询")))
                  ]),
                ),
                ElevatedButton(
                  child: Text("自动绘制,当前值：${fontInfo.autoDraw}"),
                  style: ButtonStyle(),
                  onPressed: () {
                    setState(() {
                      fontInfo.setAutoDraw(!fontInfo.autoDraw);
                    });
                  },
                ),
              ],
            ));
  }

  /*
   * 在间隔时间内只会提交一次
   * needTime: 间隔的时间
   * function：点击时要执行的方法
   */
  void intervalClick({int needTime, Function function}){
    // 防重复提交
    if(lastPopTime == null || DateTime.now().difference(lastPopTime) > Duration(seconds: needTime)){
      lastPopTime = DateTime.now();
      function();
      print("成功提交！");
    }else{
      // lastPopTime = DateTime.now(); //如果不注释这行,则强制用户一定要间隔2s后才能成功点击. 而不是以上一次点击成功的时间开始计算.
      print("请勿重复点击！");
    }
  }

  /*
   * 标题部分的控件生成
   */
  _getTitleListTile() {
    if (this.bean != null) {
      return Container(
          width: double.infinity,
          height: 80,
          padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
          child: ListTile(
            title: Container(
              //ā
              child: Text(
                this.pronunciation,
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
                left: 40.0,
                right: 10.0,
              ),
            ),
            subtitle: Text("偏旁部首:   ${this.part}",
                style: TextStyle(
                  letterSpacing: 1.2,
                )),
            //contentPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 10.0),
            trailing: Icon(Icons.volume_up),
          ));
    } else {
      return Container(
          width: double.infinity,
          height: 80,
          child: ListTile(
              title: Container(
                child: Text(
                  "",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                  ),
                ),
                margin: EdgeInsets.only(left: 40.0, right: 10.0, bottom: 10.0),
              ),
              subtitle: Text("")));
    }
  }

  _parseFontData(String str) {
    var data;
    if (str != null && str.length > 0) {
      List<Map<String, dynamic>> list1 =
          (jsonDecode(str) as List<dynamic>).cast<Map<String, dynamic>>();
      //Flutter的list.foreach不能被break或return中断，所以使用for来迭代
      for (Map<String, dynamic> item in list1) {
        if (item["character"] == this.font) {
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
