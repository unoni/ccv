class FontStrokeDataBean {
  String _font;
  String _strokes;
  String _medians;

  FontStrokeDataBean(this._font,this._strokes,this._medians);

  get font{
    return this._font;
  }

  get strokes{
    return this._strokes;
  }

  get medians{
    return this._medians;
  }
}