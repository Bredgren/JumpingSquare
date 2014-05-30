package ;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxPoint;

/**
 * ...
 * @author Brandon
 */
class Player extends FlxSprite {
  var JUMP_MULTIPLIER = 2;
  public var on_platform:Bool;
  private var _size:Int;

  public function new(X:Float = 0, Y:Float = 0, size:Int, gravity:Int) {
    super(X, Y);
		this.makeGraphic(size, size);
    this.acceleration.y = gravity;
    on_platform = false;
    _size = size;
  }

  public function jump(dir:FlxPoint):Void {
    //FlxG.log.add("jump: " + dir);
    this.velocity.x = dir.x * JUMP_MULTIPLIER;
    this.velocity.y = dir.y * JUMP_MULTIPLIER;
    //FlxG.log.add("vel: " + this.velocity);
  }

  override public function update():Void {
    var speed = Math.sqrt(this.velocity.x * this.velocity.x + this.velocity.y * this.velocity.y);
    if (speed > 0 && !on_platform) {
      var dir = new FlxPoint(this.velocity.x / speed, this.velocity.y / speed);
      var angle = Math.atan2(dir.y, dir.x);
      this.set_angle(angle / Math.PI * 180);
    } else {
      this.set_angle(0);
    }
    super.update();
  }
}
