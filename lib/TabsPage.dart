import 'package:ChineseCharacterView/WordsPage.dart';
import 'package:flutter/material.dart';

import 'package:ChineseCharacterView/HomePage.dart';

class TabsPage extends StatefulWidget {
  TabsPage({Key key}) : super(key: key);

  @override
  _TabsPageState createState() => _TabsPageState();
}

class _TabsPageState extends State<TabsPage> {
  int _currentIndex = 0;
  Widget homePage;
  Widget wordsPage;

  List<Widget> listTabs = [];

  @override
  void initState() { 
    super.initState();
    homePage = HomePage(autoDraw: false);
    wordsPage = WordsPage();
    listTabs.add(homePage);
    listTabs.add(wordsPage);
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
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: this._currentIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (index){
            if(index != 0){
              //listTabs[0]和listTabs[0] as HomePage是同一个对象,但是进行(listTabs[0] as HomePage).autoDraw = false;的修改不会使得IndexedStack重新build，应该是因为IndexedStack会保持状态，只执行一次生命周期函数。
              setState(() {
                (listTabs[0] as HomePage).autoDraw = false;
              });             
            }
            setState(() {
              this._currentIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.ondemand_video),
              label:"汉字演示"
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book),
              label:"常见词组"
            )
          ],
        ),
      ),
    );
  }
}