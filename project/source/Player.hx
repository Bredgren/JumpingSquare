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

  public function new(X:Float = 0, Y:Float = 0, size:Int, gravity:Int) {
    super(X, Y);
		this.makeGraphic(size, size);
    this.acceleration.y = gravity;
  }

  public function jump(dir:FlxPoint):Void {
    //FlxG.log.add("jump: " + dir);
    this.velocity.x = dir.x * JUMP_MULTIPLIER;
    this.velocity.y = dir.y * JUMP_MULTIPLIER;
    //FlxG.log.add("vel: " + this.velocity);
  }

}
