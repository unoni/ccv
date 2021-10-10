import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ChineseCharacterView/pages/HomePage.dart';
import 'package:ChineseCharacterView/pages/WordsPage.dart';
import 'package:ChineseCharacterView/models/StrokeModel.dart';

class TabsPage extends StatefulWidget {
  TabsPage({Key key}) : super(key: key);

  @override
  _TabsPageState createState() => _TabsPageState();
}

class _TabsPageState extends State<TabsPage> {
  int _currentIndex = 0;

  List<Widget> listTabs = [HomePage(), WordsPage()];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
          //appBar: AppBar(),
          body: IndexedStack(
            index: this._currentIndex,
            children: listTabs,
          ),
          bottomNavigationBar: Consumer<StrokeModel>(
            builder: (context, fontInfo, child) => BottomNavigationBar(
              currentIndex: this._currentIndex,
              type: BottomNavigationBarType.fixed,
              onTap: (index) {
                if(index != 0){
                  fontInfo.setAutoDraw(false);
                }
                setState(() {
                  this._currentIndex = index;
                });
              },
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.ondemand_video), label: "汉字演示"),
                BottomNavigationBarItem(
                  icon: Icon(Icons.book), 
                  label: "常见词组")
              ],
            ),
          )),
    );
  }
}
