package ;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;

enum PlatformType {
  NORMAL;
  SPIKE;
}

/**
 * ...
 * @author Brandon
 */
class Platform extends FlxSprite {
  private var _type:PlatformType;

  public function new(X:Float = 0, Y:Float = 0, width:Int = 50, height:Int = 10, type:PlatformType) {
    super(X, Y);
    setup(X, Y, width, height, type);
    this.immovable = true;
    this.allowCollisions = FlxObject.UP;
    //FlxG.log.notice("new platform: " + X + ", " + Y + " | " + width + ", " + height);
  }

  public function setup(X:Float = 0, Y:Float = 0, width:Int = 50, height:Int = 10, type:PlatformType):Void {
    this.setPosition(X, Y);
    if (type == NORMAL)
		  this.makeGraphic(width, height);
    else
      this.makeGraphic(width, height, 0xFFFF0000);
    _type = type;
  }

  override public function update():Void {
    super.update();
  }

  public function getType():PlatformType {
    return _type;
  }

}
