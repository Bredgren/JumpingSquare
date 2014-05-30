package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.group.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxPoint;
import flixel.util.FlxSave;
import Platform;

// TODO:
//       sound
//       kill past screen edges
//
//       spin (rotate toward velocity)
//       particles (on death and jump)
//       add good platforms with bad ones
//       increase difficulty

/**
 * A FlxState which can be used for the actual gameplay.
 */
class PlayState extends FlxState  {
  private var COLUMNS = 5;
  private var ROWS = 7;

  private var PLAYER_SIZE = 40;
  private var PLAYER_GRAVITY = 800;

  private var _speed = -80;
  private var _platform_width = 100;
  private var _platform_height = 10;
  private var _spike_chance = 0.3;

  private var _player:Player;

  private var _platforms:FlxTypedGroup<Platform>;
  private var _row_pos:Float;
  private var _spawn_counter:Float;
  private var _last_pos:Float;

  private var _camera_target:FlxSprite;
  private var _moving:Bool;

  private var _aim_vector:Ray;
  private var _aim_vector_length = 75;
  private var _aim_vector_color = 0x77808080;

  private var _game_save:FlxSave;
  private var _score_text:FlxText;
  private var _instructions:FlxText;

  private var _danger:FlxSprite;

	/**
	 * Function that is called up when to state is created to set it up.
	 */
	override public function create():Void {
    FlxG.camera.bgColor = 0xFFC0C0C0;

    _score_text = new FlxText(0, 0, 300, "", 12);
    this.add(_score_text);
    _instructions = new FlxText(FlxG.width / 2 - 83, FlxG.height / 2, 166, "Click to jump", 20);

    _aim_vector = new Ray(_aim_vector_color);
    _aim_vector.setThickness(10);

    _game_save = new FlxSave();
    _game_save.bind("save");
    Reg.best_score = _game_save.data.best_score;

    _danger = new FlxSprite(0, FlxG.height - 20);
    _danger.makeGraphic(FlxG.width, 20, 0x44FF0000);

    reset();

		super.create();
	}

  private function reset():Void {
    _row_pos = FlxG.height - 2 * (FlxG.height / ROWS);
    _moving = false;
    Reg.score = 0;
    _score_text.text = "Best: " + Reg.best_score + "\nCurrent: " + Reg.score;

    this.remove(_danger);

    this.add(_instructions);

    _platforms = new FlxTypedGroup<Platform>();
    this.add(_platforms);

    for (i in 0...(ROWS + 2)) {
      _newRow();
    }

    _camera_target = new FlxSprite(FlxG.width / 2, FlxG.height / 2);
    _camera_target.makeGraphic(1, 1, 0x00000000);
    this.add(_camera_target);

    //FlxG.camera.follow(_camera_target);

    _spawn_counter = FlxG.height / ROWS;
    _last_pos = _camera_target.y;

    var x = FlxG.width / 2;
    var y = FlxG.height - 50;
    var start_platform = _platforms.recycle(Platform, [x - _platform_width / 2, y - _platform_height / 2, _platform_width, _platform_height, PlatformType.NORMAL]);
    start_platform.setup(x - _platform_width / 2, y - _platform_height / 2, _platform_width, _platform_height, PlatformType.NORMAL);
    _player = new Player(x - PLAYER_SIZE / 2, y - _platform_height / 2 - PLAYER_SIZE, PLAYER_SIZE, PLAYER_GRAVITY);

    // Draw aim vector on top
    this.remove(_aim_vector);
    this.add(_player);
    this.add(_aim_vector);

    // Keep on top
    this.add(_danger);
  }

  private function killPlayer():Void {
    //FlxG.log.add("kill player");
    destroyThings();
    reset();
  }

  private function destroyThings():Void {
    _platforms.destroy();
    _camera_target.destroy();
    _player.destroy();
  }

  private function setSpeed(amount:Float):Void {
    for (platform in _platforms) {
      platform.velocity.y = -amount;
    }
    _camera_target.velocity.y = amount;
  }

	/**
	 * Function that is called when this state is destroyed - you might want to
	 * consider setting all objects this state uses to null to help garbage collection.
	 */
	override public function destroy():Void {
    destroyThings();
		super.destroy();
	}

	/**
	 * Function that is called once every frame.
	 */
	override public function update():Void {
		super.update();

    var on_platform = false;

    FlxG.collide(_platforms, _player, function (platform:Platform, player:Player) {
      if (platform.getType() == PlatformType.SPIKE) {
        killPlayer();
        return;
      } else {
        on_platform = true;
      }
    });

    if (on_platform) {
      _player.drag.x = 500;
    } else {
      _player.drag.x = 0;
    }

    var mouse_pos = FlxG.mouse.getScreenPosition();
    var player_pos = _player.getScreenXY();
    var dir = new FlxPoint(mouse_pos.x - player_pos.x, mouse_pos.y - player_pos.y);
    if (on_platform) {
      if (FlxG.mouse.justPressed) {
        if (!_moving) {
          _moving = true;
          setSpeed(_speed);
          this.remove(_instructions);
        }
        _player.jump(dir);
      }
      var length = Math.sqrt(dir.x * dir.x + dir.y * dir.y);
      dir.x = dir.x / length * _aim_vector_length;
      dir.y = dir.y / length * _aim_vector_length;
      var start = new FlxPoint(_player.x + PLAYER_SIZE / 2, _player.y + PLAYER_SIZE / 2);
      var end = new FlxPoint(start.x + dir.x, start.y + dir.y);
      _aim_vector.update2(start, end);
      //this.add(_aim_vector);
    } else {
      //this.remove(_aim_vector);
      var start = new FlxPoint(-100, -100);
      var end = new FlxPoint(-200, -200);
      _aim_vector.update2(start, end);
    }

    var current_pos = _camera_target.y;
    _spawn_counter += current_pos - _last_pos; // current_pos should always be < _last_pos
    while (_spawn_counter <= 0) {
      _newRow();
      _spawn_counter += FlxG.height / ROWS;
      Reg.score++;
      if (Reg.score > Reg.best_score) {
        Reg.best_score = Reg.score;
        _game_save.data.best_score = Reg.best_score;
        _game_save.flush();
      }
      _score_text.text = "Best: " + Reg.best_score + "\nCurrent: " + Reg.score;
    }
    _last_pos = current_pos;

    // Testing for overlap with an object that moves with the camera fails after awhile.
    _platforms.forEachAlive(function(platform) {
      if (platform.getScreenXY().y > FlxG.height + 100) {
        platform.kill();
        //FlxG.log.notice("killed");
      }
    });

    if (_player.getScreenXY().y > FlxG.height) {
      killPlayer();
      return;
    }
  }

  private function _newRow():Void {
    //FlxG.log.add("new row " + _row_pos);
    var width = FlxG.width / COLUMNS;
    var height = FlxG.height / ROWS;
    if (!_moving)
      _row_pos -= height;

    var min_y = _row_pos;
    var max_y = _row_pos + height - _platform_height;

    var choices = [];
    for (i in 0...COLUMNS) {
      choices.push(i);
    }
    //FlxG.log.add("choices: " + choices);
    var buckets = [];
    for (i in 0...1) {
      var index = Math.floor(Math.random() * choices.length);
      //FlxG.log.add(index);
      buckets.push(choices[index]);
      choices.remove(index);
    }

    //FlxG.log.add("buckets: " + buckets);

    for (bucket in buckets) {
      var min_x = bucket * width;
      var max_x = min_x + width - _platform_width;
      var x = Math.random() * (max_x - min_x) + min_x;
      var y = Math.random() * (max_y - min_y) + min_y;
      var type = PlatformType.NORMAL;
      if (Math.random() < _spike_chance) {
        type = PlatformType.SPIKE;
      }
      //FlxG.log.add("new platform: " + bucket + " | " + x + ", " + y);
      var p = _platforms.recycle(Platform, [x, y, _platform_width, _platform_height, type]);
      p.setup(x, y, _platform_width, _platform_height, type);
    }
  }
}
