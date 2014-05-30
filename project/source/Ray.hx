package ;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxPoint;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxSpriteUtil.LineStyle;

/**
 * ...
 * @author Brandon
 */
class Ray extends FlxSprite {
  private var _color:Int;
  private var _thickness:Int = 5;

  public function new(color:Int) {
    super(0, 0);
    _color = color;
    this.kill();
    this.x = 0;
    this.y = 0;
    var width = FlxG.width;
    var height = FlxG.height;
    this.makeGraphic(width, height, 0x00000000);
  }

  public function setColor(color:Int):Void {
    _color = color;
  }

  public function setThickness(thickness:Int):Void {
    _thickness = thickness;
  }

  public function update2(start:FlxPoint, end:FlxPoint):Void {
    super.reset(0, 0);
    FlxSpriteUtil.fill(this, 0x00000000);
    var s:LineStyle = { color: _color, thickness: _thickness };
    FlxSpriteUtil.drawLine(this, start.x, start.y, end.x, end.y, s);
  }
}
