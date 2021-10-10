import 'package:flutter/material.dart';

class StrokeModel extends ChangeNotifier{
  bool _autoDraw = false;

  bool _needRefresh = false;

  String _curFont = "";

  String _fontInfo = """[
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

  bool get autoDraw => this._autoDraw;

  bool get needRefresh => this._needRefresh;

  String get fontInfo => this._fontInfo; 

  String get curFont => this._curFont;

  void setAutoDraw(bool flag){
    this._autoDraw = flag;
    notifyListeners();
  }

  void setNeedRefresh(bool flag){
    this._needRefresh = flag;
    notifyListeners();
  }

  bool setCurFont(String font){
    if(font.length > 1){
      _curFont = font.substring(0, 1);
      notifyListeners();
      return true;
    }else if(font.length <= 0){
      notifyListeners();
      return false;
    }else{
      _curFont = font;
      notifyListeners();
      return true;
    }
  }

  // void setFontInfo(String fontInfo){
  //   this._fontInfo = fontInfo;
  //   notifyListeners();
  // }
}