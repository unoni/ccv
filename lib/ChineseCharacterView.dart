import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_drawing/path_drawing.dart';

bool isAnimationEnd = true;
bool firstDrawing = true;
int curDrawingIndex;

class ChineseCharacterView extends StatefulWidget {
  Size _size;
  String _strokeInfo;
  String _medianInfo;
  bool _autoDraw;
  bool _drawGrid;

  ChineseCharacterView({
    Key key,
    String strokeInfo,
    String medianInfo,
    @required Size size,
    bool autoDraw,
    bool drawGrid = true,
    //const不能省
    Duration duration = const Duration(milliseconds: 2000),
  }) : super(key: key) {
    this._strokeInfo = strokeInfo;
    this._medianInfo = medianInfo;
    this._size = size;
    this._autoDraw = autoDraw;
    this._drawGrid = drawGrid;
  }

  String get strokeInfo {
    return this._strokeInfo;
  }

  set strokeInfo(x) {
    this._strokeInfo = x;
  }

  String get medianInfo {
    return this._medianInfo;
  }

  set medianInfo(x) {
    this._medianInfo = x;
  }

  Size get size {
    return this._size;
  }

  set size(x) {
    this._size = x;
  }

  @override
  _ChineseCharacterViewState createState() => _ChineseCharacterViewState();
}

class _ChineseCharacterViewState extends State<ChineseCharacterView>
    with TickerProviderStateMixin {
  AnimationController _controller;
  double _value = 0.0;
  Duration duration;
  Animation<double> tween;

  String preStrokeInfo;
  String curStrokeInfo;
  Matrix4 pathMatrix = Matrix4.identity();
  List<Path> strokePaths = <Path>[];
  List<Path> medianPaths = <Path>[];

  //原SVG数据的尺寸是1024*1024
  double fixedSize = 1024;
  double rectSize;
  //px2dpFactor表示由原SVG的px转为flutter的dp需要的缩小倍数
  double px2dpFactor = 1 / ScreenUtil.pixelRatio;

  @override
  void initState() {
    super.initState();
    this.rectSize = widget.size.width;
    _initPathMatrix();
    WidgetsBinding.instance.addPersistentFrameCallback((timeStamp) {
      if (widget._autoDraw && strokePaths.length > 0 && isAnimationEnd) {
        isAnimationEnd = false;

        if(curDrawingIndex == 0){
          if(firstDrawing){
            firstDrawing = false;
            _nextStrokeExecute();
          }else{
            Future.delayed(Duration(milliseconds: 1000), () {
            _nextStrokeExecute();
            });
          }
        }else{
          //必须使用异步，如果直接使用sleep会出问题，应该是阻塞了主线程导致了异常
          Future.delayed(Duration(milliseconds: 300), () {
            _nextStrokeExecute();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    //需要释放资源以及重置bool，保证底部导航栏从其他页面切换回来后，动画还能正常工作。
    if(_controller != null){
      _controller.dispose();
    }
    widget._autoDraw = false;
    isAnimationEnd = true;
    firstDrawing = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.instance = ScreenUtil()..init(context);

    curStrokeInfo = widget.strokeInfo;
    if ((preStrokeInfo == null && curStrokeInfo != null) ||
        (preStrokeInfo != null && curStrokeInfo != preStrokeInfo)) {
      _initStrokePaths();
      _initMedianPaths();
    }
    preStrokeInfo = widget.strokeInfo;

    return CustomPaint(
      painter: _MyPaint(
        strokePaths: this.strokePaths,
        medianPaths: this.medianPaths,
        size: widget.size,
        autoDraw: widget._autoDraw,
        drawGrid: widget._drawGrid,
        value: _value,
      ),
      size: widget._size,
    );
  }

  _nextStrokeExecute() {
    //如果不用indexedStack就需要注释掉这个dispose
    if (_controller != null) {
      _controller.dispose();
    }

    duration =
        Duration(milliseconds: _getDrawingDuration(curDrawingIndex, 1.0));

    _controller = new AnimationController(vsync: this, duration: this.duration);

    tween = Tween(begin: 0.0, end: 1.0).animate(_controller)
      ..addStatusListener((status) {
        if (status == AnimationStatus.forward && curDrawingIndex != 0) {
          //sleep(Duration(milliseconds:1000));
        }
      })
      ..addListener(() {
        if (!widget._autoDraw) {
          //没有这个置零会导致下次播放的第一帧不是从0开始。下面那个return也是 这个作用
          _value = 0.0;
          curDrawingIndex = 0;
          firstDrawing = true;
          return;
        }
        if(mounted){
          setState(() {
            _value = _controller.value;
          });
        }
      });

    _controller.forward(from: 0.0);
  }

  /*
   * 初始化变换矩阵
   * 注：原SVG数据不能直接使用，需要经过平移、缩放等操作，所以需要用到变换矩阵
   */
  void _initPathMatrix() {
    pathMatrix.setIdentity();
    try {
      //注意是double!写(0,-900)会抛异常！
      //z也要写，不然会设置成第一个参数的大小（即x的大小）
      //dp2px(rectSize)/fixedSize表示SVG大小适配到田字格大小所需的缩小倍数
      //必须是scale在上，translate在下，才能保证translate能转为dp
      pathMatrix.scale(dp2px(rectSize) / fixedSize * px2dpFactor,
          dp2px(-rectSize) / fixedSize * px2dpFactor, 1.0);
      pathMatrix.translate(0.0, -900.0);
    } catch (e) {
      print(e.toString());
    }
  }

  /*
   * 将SVG的笔画指令数据初始化为Path对象 
   */
  _initStrokePaths() {
    curDrawingIndex = 0;
    try {
      List<String> list = parseStrokeData(widget.strokeInfo);
      if (list != null) {
        this.strokePaths.clear();
        for (String str in list) {
          Path path = parseSvgPathData(str);
          path = path.transform(pathMatrix.storage);
          this.strokePaths.add(path);
        }
      }
      return;
    } catch (e) {
      print("初始化StrokePath失败！");
    }
  }

  /*
   * 将SVG的中线指令数据初始化为Path对象 
   */
  _initMedianPaths() {
    curDrawingIndex = 0;
    try {
      List<List<Point>> list = parseMedianData(widget.medianInfo);
      if (list != null && list.length != 0) {
        this.medianPaths.clear();
        for (List<Point> pointList in list) {
          Path path = new Path();
          path.moveTo(pointList[0].x, pointList[0].y);
          for (int i = 0; i < pointList.length - 1; i++) {
            try {
              path.quadraticBezierTo(pointList[i].x, pointList[i].y,
                  pointList[i + 1].x, pointList[i + 1].y);
            } catch (e) {
              print(e.toString());
            }
          }
          path = path.transform(pathMatrix.storage);
          this.medianPaths.add(path);
        }
      }
    } catch (e) {
      print(e.toString());
    }
  }

  /*
   * 获得索引处笔画对应的绘制时间
   * index：要绘制的笔画的索引
   * times：相对于标准速度的倍速
   * 注：以田字格大小为300为标准，“三”字的第二笔长度为109.3，标准播放速度是“三”字第二笔花费1093ms，
   */
  int _getDrawingDuration(int index, double times) {
    Path curMedianPath = medianPaths[index];
    PathMetrics pathMetrics = curMedianPath.computeMetrics(forceClosed: false);
    List<PathMetric> pathMetric = pathMetrics.toList();
    return (pathMetric[0].length * (300.0 / rectSize) * 10.0) ~/ times;
  }
}

class _MyPaint extends CustomPainter {
  Size _size;

  //田字格边框画笔
  Paint gridPaint = new Paint();
  //田字格虚线画笔
  Paint dashPaint = new Paint();
  //字帽画笔
  Paint maskPaint = new Paint();
  //中线画笔
  Paint medianPaint = new Paint();
  //已经绘制路径的画笔、初始状态画笔
  Paint strokePaint = new Paint();
  //当前绘制路径的画笔
  Paint touchPaint = new Paint();

  Color gridColor = Color(0xff888888);
  Color dashColor = Color(0xff888888);
  Color strokeColor = Color(0xffbcbcbc);
  Color touchColor = Color(0xffffba00);

  Path curStrokePath;
  Path curMedianPath;

  double gridWidth = 1.0;
  double dashWidth = 1.0;
  double medianWidth = 1.0;

  //是否自动绘制
  bool _autoDraw;
  //是否画田字格
  bool _drawGrid;
  //补全笔帽所用到的圆的半径
  double _maskRadius;
  //动画控制器的值
  double _value;
  Rect gridRect;
  double rectSize;

  //笔画数据，用于描绘笔画
  List<Path> strokePaths = <Path>[];
  //中线数据，用于截取笔画
  List<Path> medianPaths = <Path>[];

  _MyPaint(
      {List<Path> strokePaths,
      List<Path> medianPaths,
      Size size,
      bool autoDraw,
      bool drawGrid,
      double value}) {
    this.strokePaths = strokePaths;
    this.medianPaths = medianPaths;
    this._size = size;
    this.rectSize = this._size.width;
    this._autoDraw = autoDraw;
    this._drawGrid = drawGrid;
    this._value = value;
    _initMyPaint();
  }

  _initMyPaint() {
    this.gridPaint.color = gridColor;
    this.gridPaint.style = PaintingStyle.stroke;
    this.gridPaint.strokeWidth = this.gridWidth;
    this.gridPaint.isAntiAlias = true;
    this.dashPaint.color = dashColor;
    this.dashPaint.style = PaintingStyle.stroke;
    this.dashPaint.strokeWidth = this.dashWidth;
    this.dashPaint.isAntiAlias = true;
    this.medianPaint.color = touchColor;
    this.medianPaint.style = PaintingStyle.stroke;
    this.medianPaint.strokeJoin = StrokeJoin.round;
    this.medianPaint.strokeCap = StrokeCap.round;
    this.medianPaint.strokeWidth = medianWidth;
    this.medianPaint.isAntiAlias = true;
    this.strokePaint.color = strokeColor;
    this.strokePaint.style = PaintingStyle.fill;
    this.strokePaint.strokeJoin = StrokeJoin.round;
    this.strokePaint.strokeCap = StrokeCap.round;
    this.strokePaint.isAntiAlias = true;
    this.touchPaint.color = touchColor;
    this.touchPaint.style = PaintingStyle.stroke;
    this.touchPaint.isAntiAlias = true;
    this.touchPaint.strokeWidth = this.rectSize / 6;
    this.touchPaint.blendMode = BlendMode.srcIn;
    this.maskPaint.color = touchColor;
    this.maskPaint.style = PaintingStyle.fill;
    this.maskPaint.isAntiAlias = true;
    this.maskPaint.blendMode = BlendMode.srcIn;
    this._maskRadius = this.rectSize / 50;
    this.gridRect = new Rect.fromLTRB(this.gridWidth / 2, this.gridWidth / 2,
        this.rectSize - this.gridWidth / 2, this.rectSize - this.gridWidth / 2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (this._drawGrid) {
      canvas.drawRect(gridRect, gridPaint);
      drawDashLine(canvas, dashPaint, Offset(0, 0),
          Offset(size.width, size.height), <double>[5.0, 2.5]);
      drawDashLine(canvas, dashPaint, Offset(0, size.height),
          Offset(size.width, 0), <double>[5.0, 2.5]);
      drawDashLine(canvas, dashPaint, Offset(size.width / 2, 0),
          Offset(size.width / 2, size.height), <double>[5.0, 2.5]);
      drawDashLine(canvas, dashPaint, Offset(0, size.width / 2),
          Offset(size.width, size.width / 2), <double>[5.0, 2.5]);
    }

    if (strokePaths.length == 0) {
      return;
    }

    //自动绘制
    if (this._autoDraw) {
      if (curDrawingIndex < strokePaths.length) {
        //还未描绘的笔画，用灰色描出
        int k = curDrawingIndex + 1;
        int j = strokePaths.length;
        while (k < j) {
          this.curStrokePath = this.strokePaths[k];
          this.strokePaint.color = strokeColor;
          if (curStrokePath != null) {
            canvas.drawPath(curStrokePath, strokePaint);
          }
          k++;
        }

        //当前正在描绘的笔画，用灰色打底，橙色描出
        canvas.saveLayer(gridRect, Paint());
        //先用灰色打底正在描绘的笔画
        this.strokePaint.color = strokeColor;
        this.curStrokePath = this.strokePaths[curDrawingIndex];
        this.curMedianPath = this.medianPaths[curDrawingIndex];
        canvas.drawPath(this.curStrokePath, this.strokePaint);
        //pathMetrics中只有一个path
        PathMetrics pathMetrics =
            this.curMedianPath.computeMetrics(forceClosed: false);
        List<PathMetric> pathMetric = pathMetrics.toList();
        Offset circleCenter = pathMetric[0].getTangentForOffset(0.0).position;
        Path curDrawPath = new Path();
        curDrawPath.addPath(
            pathMetric[0].extractPath(0.0, pathMetric[0].length * _value,
                startWithMoveTo: true),
            Offset(0, 0));
        canvas.drawPath(curDrawPath, touchPaint);
        canvas.drawCircle(circleCenter, _maskRadius, maskPaint);
        canvas.restore();

        //已经描绘的笔画
        //注意需要放在截取路径绘制的后面
        //原因在于用于截取的medianPath数据本身没有笔帽，每一笔截取路径绘制的最后一点点是没法画出来的
        //而在截取路径绘制后绘制“已经描绘的笔画”，从视觉效果上补齐了最后一点点
        this.strokePaint.color = touchColor;

        for (int i = 0; i < curDrawingIndex; i++) {
          this.curStrokePath = this.strokePaths[i];
          canvas.drawPath(this.curStrokePath, this.strokePaint);
        }
        if (_value == 1.0) {
          isAnimationEnd = true;
          canvas.drawPath(this.strokePaths[curDrawingIndex], this.strokePaint);

          if (curDrawingIndex < strokePaths.length - 1) {
            curDrawingIndex++;
          } else {
            curDrawingIndex = 0;
          }
        }

        this.strokePaint.color = strokeColor;
      }
    } else {
      //到这说明没开启自动绘制，用橙色显示汉字
      isAnimationEnd = true;
      strokePaint.color = touchColor;
      for (int i = 0; i < strokePaths.length; i++) {
        canvas.drawPath(strokePaths[i], strokePaint);
      }
      strokePaint.color = strokeColor;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    _MyPaint old = oldDelegate as _MyPaint;
    return _value != old._value || isAnimationEnd;
  }

  /*
   * 绘制虚线
   * canvas：提供的画布
   * paint：绘制虚线的画笔
   * p1：虚线起始点
   * p2：虚线终点
   * intervals：实线部分与空白部分的长度, intervals[0]表示实线长度，intervals[1]表示虚线长度
   */
  void drawDashLine(Canvas canvas, Paint paint, Offset p1, Offset p2,
      List<double> intervals) {
    double totalLength = sqrt(pow(p2.dx - p1.dx, 2) + pow(p2.dy - p1.dy, 2));
    double interval = intervals[0] + intervals[1];
    int count = totalLength ~/ interval;
    double length = interval * count;
    double factor = length / totalLength;
    double xLength = (p2.dx - p1.dx) * factor;
    double yLength = (p2.dy - p1.dy) * factor;
    double intervalOnFactor = intervals[0] / interval;
    double intervalOffFactor = intervals[1] / interval;
    double xOnSpace = xLength / count * intervalOnFactor;
    double xOffSpace = xLength / count * intervalOffFactor;
    double yOnSpace = yLength / count * intervalOnFactor;
    double yOffSpace = yLength / count * intervalOffFactor;
    double startX = p1.dx;
    double startY = p1.dy;

    for (int i = 0; i < count; i++) {
      canvas.drawLine(Offset(startX, startY),
          Offset(startX + xOnSpace, startY + yOnSpace), paint);
      startX += xOnSpace;
      startY += yOnSpace;
      startX += xOffSpace;
      startY += yOffSpace;
    }

    if (startX + xOnSpace <= p2.dx) {
      canvas.drawLine(Offset(startX, startY),
          Offset(startX + xOnSpace, startY + xOnSpace), paint);
      startX += xOnSpace;
      startY += yOnSpace;
    } else {
      canvas.drawLine(Offset(startX, startY), Offset(p2.dx, p2.dy), paint);
      return;
    }
  }
}

/*
 * 将SVG笔画数据转化为List 
 */
List<String> parseStrokeData(String str) {
  if (str != null && str.length != 0) {
    //强转时必须用cast！
    List<String> stringList = (jsonDecode(str) as List<dynamic>).cast<String>();
    return stringList;
  }

  return null;
}

/*
 * 将SVG中线数据转化为List 
 */
List<List<Point>> parseMedianData(String str) {
  if (str != null || str.length != 0) {
    List<List<Point>> result = <List<Point>>[];
    List<List> temp = (jsonDecode(str) as List<dynamic>).cast<List>();

    for (int i = 0; i < temp.length; i++) {
      //temp[i]是当前笔画
      var strokeList = <Point>[];
      //pointList是当前笔画中包含的所有点
      List<List> pointList = temp[i].cast<List>();
      for (List list in pointList) {
        List<num> xyList = list.cast<num>();
        Point p = new Point(xyList[0].toDouble(), xyList[1].toDouble());
        strokeList.add(p);
      }
      result.add(strokeList);
    }

    return result;
  }

  return null;
}

double dp2px(double dp) {
  return dp * ScreenUtil.pixelRatio;
}

double px2dp(double px) {
  return px / ScreenUtil.pixelRatio;
}
