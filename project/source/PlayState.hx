package;

import flixel.effects.particles.FlxEmitterExt;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.group.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxPoint;
import flixel.util.FlxSave;
import Platform;

// TODO: change score to be best consecutive

/**
 * A FlxState which can be used for the actual gameplay.
 */
class PlayState extends FlxState  {
  private var COLUMNS = 5;
  private var ROWS = 7;

  private var PLAYER_SIZE = 40;
  private var PLAYER_GRAVITY = 800;

  private var _speed = 80;
  private var _platform_width = 125;
  private var _platform_height = 10;
  private var _spike_chance = 0.2;
  private var _consecutive_spike_counter = 0;

  private var _player:Player;
  private var _dead:Bool;

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
  private var _reset:FlxText;
  private var _story:FlxText;

  private var _danger:FlxSprite;
  private var _explosion:FlxEmitterExt;

  private var _on_platform_last:Bool;

  private var _checkpoint_rate = 20;

	/**
	 * Function that is called up when to state is created to set it up.
	 */
	override public function create():Void {
    FlxG.camera.useBgAlphaBlending = true;
    FlxG.camera.bgColor = 0x55C0C0C0;

    _score_text = new FlxText(0, 0, 300, "", 12);
    this.add(_score_text);
    _instructions = new FlxText(FlxG.width / 2 - 83, FlxG.height / 2, 166, "Click to jump", 20);
    _instructions.alignment = "center";
    _reset = new FlxText(FlxG.width / 2 - 93, FlxG.height / 2 + 15 * 2 , 186, "R to reset progress", 15);
    _reset.alignment = "center";
    var w = 400;
    _story = new FlxText(FlxG.width / 2 - w/2, 0, w, "", 15);
    _story.color = 0xFF808080;
    _story.alignment = "center";
    _story.moves = true;
    this.add(_story);

    _aim_vector = new Ray(_aim_vector_color);
    _aim_vector.setThickness(10);

    _game_save = new FlxSave();
    _game_save.bind("save");
    Reg.best_score = _game_save.data.best_score;
    Reg.checkpoint = _game_save.data.checkpoint;

    _danger = new FlxSprite(0, FlxG.height - 20);
    _danger.makeGraphic(FlxG.width, 20, 0x44FF0000);

    _explosion = new FlxEmitterExt();
		_explosion.setRotation(0, 0);
		_explosion.setMotion(0, 25, 0.2, 360, 200, 1.8);
		_explosion.makeParticles("assets/images/particle.png", 1200, 0, true, 0);
		_explosion.setAlpha(1, 1, 0, 0);
		add(_explosion);

    reset();

		super.create();
	}

  private function reset():Void {
    _dead = false;
    _row_pos = FlxG.height - 2 * (FlxG.height / ROWS);
    _moving = false;
    _on_platform_last = true;
    Reg.score = Reg.checkpoint;
    _score_text.text = "Best: " + Reg.best_score + "\nCurrent: " + Reg.score;

    this.remove(_danger);

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

    this.add(_instructions);
    this.add(_reset);

    setStory("", FlxG.height);
    this.remove(_story);
    this.add(_story);
  }

  private function killPlayer():Void {
    //FlxG.log.add("kill player");
    FlxG.sound.play("assets/sounds/Explosion1.wav");
    explode(_player.x, _player.y);
    _dead = true;
    this.remove(_player);
    FlxG.camera.shake(0.02, 0.3, function() {
      destroyThings();
      reset();
    });
  }

  private function destroyThings():Void {
    _platforms.destroy();
    _camera_target.destroy();
    _player.destroy();
  }

  private function setSpeed(amount:Float):Void {
    for (platform in _platforms) {
      platform.velocity.y = amount;
    }
    _camera_target.velocity.y = -amount;
    _story.velocity.y = _speed * 0.75;
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

    if (_dead) return;

    if (!_moving && FlxG.keys.justPressed.R) {
      Reg.score = 0;
      Reg.checkpoint = 0;
      _game_save.data.checkpoint = Reg.checkpoint;
      _game_save.data.score = Reg.score;
      _game_save.flush();
      _score_text.text = "Best: " + Reg.best_score + "\nCurrent: " + Reg.score;
    }

    updateProgress();

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
      if (!_on_platform_last)
        FlxG.sound.play("assets/sounds/land1.wav");
      if (FlxG.mouse.justPressed) {
        if (!_moving) {
          _moving = true;
          setSpeed(_speed);
          this.remove(_instructions);
          this.remove(_reset);
        }
        _player.jump(dir);
        FlxG.sound.play("assets/sounds/Jump1.wav");
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

    _on_platform_last = on_platform;
    _player.on_platform = on_platform;

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

    if (player_pos.y > FlxG.height ||
        player_pos.x < -_player.width * 1.1 ||
        player_pos.x > FlxG.width + _player.width * 1.1) {
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
      if (Math.random() < _spike_chance && _consecutive_spike_counter < 2) {
        type = PlatformType.SPIKE;
        _consecutive_spike_counter++;
      } else {
        _consecutive_spike_counter = 0;
      }
      //FlxG.log.add("new platform: " + bucket + " | " + x + ", " + y);
      var p = _platforms.recycle(Platform, [x, y, _platform_width, _platform_height, type]);
      p.setup(x, y, _platform_width, _platform_height, type);
    }
  }

  private function explode(X:Float = 0, Y:Float = 0):Void {
		if (X == 0 && Y == 0) {
			X = FlxG.width / 2;
			Y = FlxG.height / 2;
		}

    _explosion.x = X;
    _explosion.y = Y;
    _explosion.start(true, 0.05, 0, 100, 0.5);
    _explosion.update();
	}

  private function setStory(text:String, y:Float) {
    _story.text = text;
    _story.y = y;
  }

  private function updateProgress() {
    if (Reg.score >= Reg.checkpoint + _checkpoint_rate) {
        Reg.checkpoint += _checkpoint_rate;
        _game_save.data.checkpoint = Reg.checkpoint;
        _game_save.flush();
    }

    var y = -50;
    switch (Reg.score) {
      case 15:
        setStory("Hey, how's it going?", y);
      case 30:
        setStory("Dang! You're doing pretty good.", y);
      case 50:
        setStory("Whoa! Don't look down.", y);
      case 75:
        setStory("Still can't see the top yet. Better keep going.", y);
      case 100:
        setStory("This might take awhile", y);
      case 130:
        setStory("How about a thoughtful poem to pass the time", y);
      case 145:
        setStory("It’s titled Only Breath and was written by Rumi", y);
      case 150:
        setStory("Not Christian or Jew or Muslim,", y);
      case 165:
        setStory("not Hindu, Buddhist, sufi, or zen.", y);
      case 185:
        setStory("Not any religion or cultural system.", y);
      case 205:
        setStory("I am not from the East or the West,", y);
      case 220:
        setStory("not out of the ocean or up from the ground,", y);
      case 235:
        setStory("not natural or ethereal,", y);
      case 250:
        setStory("not composed of elements at all.", y);
      case 270:
        setStory("I do not exist,", y);
      case 285:
        setStory("am not an entity in this world or the next,", y);
      case 300:
        setStory("did not descend from Adam or Eve", y);
      case 315:
        setStory("or any origin story.", y);
      case 335:
        setStory("My place is placeless,", y);
      case 350:
        setStory("a trace of the traceless.", y);
      case 370:
        setStory("Neither body or soul.", y);
      case 390:
        setStory("I belong to the beloved,", y);
      case 405:
        setStory("have seen the two worlds as one", y);
      case 420:
        setStory("and that one call to and know,", y);
      case 435:
        setStory("first,", y);
      case 445:
        setStory("last,", y);
      case 455:
        setStory("outer,", y);
      case 465:
        setStory("inner,", y);
      case 480:
        setStory("only that breath breathing", y);
      case 500:
        setStory("human being.", y);
      case 550:
        setStory("Well, I’m starting to think there isn’t a top.", y);
      case 570:
        setStory("I’ll stop bothering you now", y);
      case 590:
        setStory("let you concentrate", y);
      case 610:
        setStory("on getting as high as you can", y);
      case 630:
        setStory("Maybe there’s something waiting for you up there", y);
      case 650:
        setStory("Or maybe not", y);
      case 670:
        setStory("Okay, now I’m leaving", y);
      case 690:
        setStory("Bye...", y);
    }
  }
}
