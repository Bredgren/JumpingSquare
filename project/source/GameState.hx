package ;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.util.FlxCollision;
import flixel.util.FlxPoint;
import flixel.util.FlxSpriteUtil;
import haxe.EnumFlags;

/**
 * ...
 * @author Brandon
 */
class GameState extends FlxState {
  private var _loader:FlxOgmoLoader;
  private var _tileMap:FlxTilemap;

  //private var _ice_blocks:FlxTypedGroup<IceBlock>;
  private var _player:Player;
  private var _crates:FlxTypedGroup<Crate>;
  private var _turrets:FlxTypedGroup<Turret>;
  private var _vents:FlxTypedGroup<Vent>;
  private var _platforms:FlxTypedGroup<Platform>;

  private var _max_freeze_power:Int;
  private var _freeze_power:FlxText;

  private var _dmg_indicator:FlxSprite;

  private var _platform_params:Map<Int, PlatformParams>;

  public function new() {
    super();
  }

  override public function create():Void {
    add(_tileMap);
    FlxG.log.add("add tile map");
    FlxG.log.add(_tileMap.width + " " + _tileMap.height);

    _crates = new FlxTypedGroup<Crate>();
    _turrets = new FlxTypedGroup<Turret>();
    _vents = new FlxTypedGroup<Vent>();
    _platforms = new FlxTypedGroup<MovingPlatform>();

    _platform_params = new Map<Int, PlatformParams>();

    add(_vents);
    add(_platforms);
    _loader.loadEntities(_loadEntity, "objects");
    add(_turrets);
    add(_crates);

    _freeze_power = new FlxText(10, 20, 200, "Freeze Power: ??");
    _freeze_power.setPosition(10, 10);
    _freeze_power.scrollFactor.set(0, 0);
    _freeze_power.color = 0x0530FA;
    add(_freeze_power);

    //_ice_blocks = new FlxTypedGroup<IceBlock>();
    //add(_ice_blocks);

    _dmg_indicator = new FlxSprite();
    _dmg_indicator.makeGraphic(Std.int(FlxG.game.width), Std.int(FlxG.game.height), 0x99FF0000);
    _dmg_indicator.alpha = 0;
    _dmg_indicator.scrollFactor.set(0, 0);
    add(_dmg_indicator);

    super.create();
  }

  public function levelWidth():Float {
    return _tileMap.width;
  }

  public function levelHeight():Float {
    return _tileMap.height;
  }

  override public function update():Void {
    super.update();

    if (FlxG.keys.justPressed.Q) {
      for (p in _platforms) {
        p.togglePower();
      }
    }

    _dmg_indicator.alpha = _player.getHealth();

    _freeze_power.text = "Freeze Power: " + _player.getFreezePower();

    if (_getAvailableFreezePower() < _max_freeze_power) {
      var v = _nearestUnfrozenVent();
      if (v != null) v.freeze();
    }

    var player_collide = false;

    if (FlxG.collide(_crates, _player, _player.touchCrate)) {
      player_collide = true;
    }
    if (!player_collide) {
      FlxG.overlap(_crates, _player, _player.touchCrate);
    }

    if (FlxG.collide(_turrets, _player)) {
      player_collide = true;
    }

    if (FlxG.collide(_vents, _player)) {
      player_collide = true;
    }

    if (FlxG.collide(_platforms, _player)) {
      player_collide = true;
    }

    //if (FlxG.collide(_ice_blocks, _player)) {
      //player_collide = true;
    //}

    FlxG.collide(_crates, _crates);
    FlxG.collide(_crates, _platforms);
    FlxG.collide(_tileMap, _crates);

    if (FlxG.collide(_tileMap, _player)) {
      player_collide = true;
    }

    if (player_collide) {
      _player.setIsOnGround(_player.getBody().isTouching(FlxObject.DOWN));
    } else {
      _player.setIsOnGround(false);
    }

    for (turret in _turrets) {
      var bullets = turret.weapon().group;
      FlxG.collide(_tileMap, bullets, function(obj1:FlxObject, obj2:FlxObject) {
        obj2.kill();
      });
      FlxG.overlap(_crates, bullets, function(obj1:FlxObject, obj2:FlxObject) {
        obj2.kill();
      });
      FlxG.overlap(_platforms, bullets, function(obj1:FlxObject, obj2:FlxObject) {
        obj2.kill();
      });
      FlxG.overlap(bullets, _player.getBody(), function(obj1:FlxBullet, obj2:FlxSprite) {
        _player.hit();
        obj1.kill();
      });
    }
  }

  //public function getIceBlocks():FlxTypedGroup<IceBl  ock> {
    //return _ice_blocks;
  //}

  private function _spawnPlayer(x:Float, y:Float) {
    FlxG.log.add("spawn player " + x + " " + y);
    _player = new Player(0, 0, _max_freeze_power-1, this);
    _player.x = x - _player.width / 2;
    _player.y = y - _player.height;
    add(_player);

    FlxG.camera.follow(_player.getBody(), FlxCamera.STYLE_PLATFORMER, null, 5);
  }

  private function _spawnCrate(x:Float, y:Float) {
    FlxG.log.add("spawn crate " + x + " " + y);
    var crate = new Crate(this, x, y);
    crate.x = x - crate.width / 2;
    crate.y = y - crate.height;
    _crates.add(crate);
  }

  private function _spawnTurret(x:Float, y:Float, min_angle:Float = 0, max_angle:Float = 180,
                                start_angle:Float = 90, range:Float = 500, speed:Float = 1) {
    FlxG.log.add("spawn turret " + x + " " + y);
    var turret = new Turret(this, x, y, min_angle, max_angle, start_angle, range, speed);
    turret.x = x - turret.width / 2;
    turret.y = y - turret.height / 2;
    _turrets.add(turret);
  }

  private function _spawnVent(x:Float, y:Float) {
    FlxG.log.add("spawn vent " + x + " " + y);
    var vent = new Vent(this, x, y);
    vent.x = x - vent.width / 2;
    vent.y = y - vent.height / 2;
    _vents.add(vent);
  }

  private function _spawnPlatform(id:Int, x:Float, y:Float, speed:Float, is_start:Bool) {
    if (_platform_params.exists(id)) {
      var other:PlatformParams = _platform_params.get(id);
      var x1:Float, y1:Float, x2:Float, y2:Float, speed1:Float, speed2:Float;
      if (is_start) {
        x1 = x; y1 = y;
        x2 = other.x; y2 = other.y;
        speed1 = speed; speed2 = other.speed;
      } else {
        x1 = other.x; y1 = other.y;
        x2 = x; y2 = y;
        speed1 = other.speed;
        speed2 = speed;
      }
      FlxG.log.add("spawn platform " + id + ": " + x1 + " " + y1 + " | " + speed);
      var platform = new MovingPlatform(this, new FlxPoint(x1, y1), new FlxPoint(x2, y2), speed1, speed2);
      _platforms.add(platform);
      _platform_params.remove(id);
    } else {
      FlxG.log.add("store platform " + id + ": " + x + " " + y + " | " + speed);
      var p:PlatformParams = {
        x: x,
        y: y,
        speed: speed,
        is_start: is_start,
      }
      _platform_params.set(id, p);
    }
  }

  private function _loadEntity(entity:String, params:Xml):Void {
    FlxG.log.add(entity + ": " + params);
    var x = Std.parseFloat(params.get("x"));
    var y = Std.parseFloat(params.get("y"));
    switch (entity) {
      case "Player":
        _spawnPlayer(x, y);
      case "Crate":
        _spawnCrate(x, y);
      case "Turret":
        var min_angle = Std.parseFloat(params.get("min_angle"));
        var max_angle = Std.parseFloat(params.get("max_angle"));
        var start_angle = Std.parseFloat(params.get("start_angle"));
        var range = Std.parseFloat(params.get("range"));
        var speed = Std.parseFloat(params.get("speed"));
        _spawnTurret(x, y, min_angle, max_angle, start_angle, range, speed);
      case "Vent":
        _spawnVent(x, y);
      case "Platform":
        var id = Std.parseInt(params.get("ID"));
        var is_start = params.get("is_start") == "True";
        var speed = Std.parseFloat(params.get("speed"));
        _spawnPlatform(id, x, y, speed, is_start);
    }
  }

  public function fireRay(source_x:Float, source_y:Float, end_x:Float, end_y:Float,
                          result:FlxPoint, collide_with:EnumFlags<RayCollision>):FlxObject {
    var dir_x = end_x - source_x;
    var dir_y = end_y - source_y;
    var max_length = Math.sqrt(dir_x * dir_x + dir_y * dir_y);
    dir_x /= max_length;
    dir_y /= max_length;
    var step = 10.0;
    var current_length = 1.0;
    var hit_object:FlxObject = null;
    while (current_length < max_length) {
      var new_x = source_x + dir_x * current_length;
      var new_y = source_y + dir_y * current_length;
      var p = new FlxPoint(new_x, new_y);
      if (collide_with.has(RayCollision.PLAYER)) {
        hit_object = getPlayerAt(p);
        if (hit_object != null) break;
      }
      if (collide_with.has(RayCollision.VENTS)) {
        hit_object = getVentAt(p);
        if (hit_object != null) break;
      }
      //if (collide_with.has(RayCollision.ICE_BLOCKS)) {
        //hit_object = getIceBlockAt(p);
        //if (hit_object != null) break;
      //}
      if (collide_with.has(RayCollision.CRATES)) {
        hit_object = getCrateAt(p);
        if (hit_object != null) break;
      }
      if (collide_with.has(RayCollision.TURRETS)) {
        hit_object = getTurretAt(p);
        if (hit_object != null) break;
      }
      if (collide_with.has(RayCollision.PLATFORMS)) {
        hit_object = getPlatformAt(p);
        if (hit_object != null) break;
      }
      current_length += step;
    }

    var end_point = new FlxPoint(source_x + dir_x * max_length, source_y + dir_y * max_length);
    var hit_point = new FlxPoint(source_x + dir_x * current_length, source_y + dir_y * current_length);

    if (collide_with.has(RayCollision.MAP)) {
      var tile_point:FlxPoint = new FlxPoint();
      var hit = _tileMap.ray(new FlxPoint(source_x, source_y), end_point, tile_point, 3);
      if (!hit) {
        if (hit_object == null) {
          hit_point = tile_point;
        } else {
          var dx = tile_point.x - source_x;
          var dy = tile_point.y - source_y;
          var tile_dist = Math.sqrt(dx * dx + dy *  dy);
          if (tile_dist < current_length) {
            hit_point = tile_point;
            hit_object = null;
          }
        }
      } else if (hit_object == null) {
        hit_point = end_point;
      }
    }

    result.set(hit_point.x, hit_point.y);
    return hit_object;
  }

  public function getPlayerAt(point:FlxPoint):Player {
    if (_player.getBody().overlapsPoint(point)) {
      return _player;
    }
    return null;
  }

  public function getVentAt(point:FlxPoint):Vent {
    return cast(_getObjectAt(point, _vents), Vent);
  }

  //public function getIceBlockAt(point:FlxPoint):IceBlock {
    //return cast(_getObjectAt(point, _ice_blocks), IceBlock);
  //}

  public function getCrateAt(point:FlxPoint):Crate {
    return cast(_getObjectAt(point, _crates), Crate);
  }

  public function getTurretAt(point:FlxPoint):Turret {
    return cast(_getObjectAt(point, _turrets), Turret);
  }

  public function getPlatformAt(point:FlxPoint):MovingPlatform {
    return cast(_getObjectAt(point, _platforms), MovingPlatform);
  }

  public function onPlayerDeath() {
    FlxG.switchState(new PlayState());
  }

  private function _getObjectAt<T:FlxObject>(point:FlxPoint, group:FlxTypedGroup<T>):T {
    for (obj in group) {
      if (obj.alive && obj.overlapsPoint(point)) {
        return obj;
      }
    }
    return null;
  }

  override public function destroy():Void {
    FlxG.log.add("destroy");
    _tileMap.destroy();
    _player.destroy();
    _turrets.destroy();
    _crates.destroy();
    //_ice_blocks.destroy();
    _freeze_power.destroy();
    _dmg_indicator.destroy();
		super.destroy();
	}

  private function _getFreezeCount<T:Freezable>(group:FlxTypedGroup<T>):Int {
    var count = 0;
    for (o in group) {
      if (o.freezeLevel() == FreezeLevel.ONE) count += 1;
      else if (o.freezeLevel() == FreezeLevel.TWO) count += 2;
    }
    return count;
  }

  private function _getAvailableFreezePower():Int {
    var amount = 0;
    amount += _player.getFreezePower();
    amount += _getFreezeCount(_vents);
    amount += _getFreezeCount(_crates);
    amount += _getFreezeCount(_turrets);
    return amount;
  }

  private function _nearestUnfrozenVent():Vent {
    var p_x = _player.getBody().x;
    var p_y = _player.getBody().y;
    var nearest:Vent = null;
    var min_dist:Float = -1;
    for (vent in _vents) {
      if (vent.freezeLevel() == FreezeLevel.TWO) continue;
      var dx = p_x - vent.x;
      var dy = p_y - vent.y;
      var dist = dx * dx + dy * dy;
      if (min_dist < 0 || dist < min_dist) {
        min_dist = dist;
        nearest = vent;
      }
    }

    return nearest;
  }
}
