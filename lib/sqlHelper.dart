import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:ChineseCharacterView/fontStrokeDataBean.dart';
import 'package:path/path.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class SqlHelper {
  static String dbFileName = "strokes.db";
  static SqlHelper _instance;
  Database db;

  static Future<SqlHelper> getInstance() async {
    if (_instance == null) {
      _instance = await _initDataBase();
    }
    return _instance;
  }

  static Future<SqlHelper> _initDataBase() async {
    SqlHelper helper = SqlHelper();

    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, "strokes_copy.db");

    var exists = await databaseExists(path);

    //将assets中的数据库复制到Android或ios的数据库目录中供平台调用
    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      ByteData data = await rootBundle.load(join("assets", dbFileName));
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      await File(path).writeAsBytes(bytes, flush: true);
    } else {
      print("数据库已存在，无需复制");
    }
    helper.db = await openDatabase(path, readOnly: true);
    return helper;
  }

  Future<FontStrokeDataBean> query(String font) async {
    FontStrokeDataBean c;
    String tableName = "t_stroke";
    if(font == null || font.isEmpty || font == " "){
      return null;
    }

    if (db != null) {
      List<Map> list = await db
          .rawQuery('Select * from $tableName where character=?', [font]);
      String character = list[0]['character'];
      String stroke = list[0]['stroke'];
      String median = list[0]['median'];
      c = new FontStrokeDataBean(character, stroke, median);
    }

    print(c.font + "\n" + c.strokes + "\n" + c.medians + '\n');
    return c;
  }
}
