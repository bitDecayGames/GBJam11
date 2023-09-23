package levels.ldtk;

import entities.sensor.TurretSpawner;
import entities.enemy.LoneTurret;
import entities.boss.RoverSpawner;
import entities.boss.RoverBoss;
import flixel.FlxBasic;
import flixel.group.FlxGroup;
import entities.RunningAlien;
import entities.Alien;
import entities.sensor.AlienSpawner;
import entities.sensor.Trigger;
import entities.sensor.CameraTrigger;
import entities.boss.WallBoss;
import ldtk.Project;
import states.PlayState;
import bitdecay.flixel.spacial.Cardinal;
import progress.Collected;
import flixel.math.FlxRect;
import entities.Player;
import flixel.effects.particles.FlxEmitter;
import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.group.FlxSpriteGroup;

class Level {
	// private static inline var WORLD_ID = "ded66c41-3b70-11ee-9c97-27b856925a1e";
	public static var project = new LDTKProject();

	public var raw:LDTKProject.LDTKProject_Level;
	
	// // in case we need something specific
	// public var raw:LDTKProject_Level;

	public var bounds = FlxRect.get();
	public var terrainGfx = new FlxSpriteGroup();
	public var terrainDecorGfx = new FlxSpriteGroup();
	public var terrainOneWayGfx = new FlxSpriteGroup();
	public var rawTerrainInts = new Array<Int>();
	public var rawOneWayTerrainInts = new Array<Int>();
	public var rawTerrainTilesWide = 0;
	public var rawTerrainTilesTall = 0;

	public var camTriggers:Array<CameraTrigger> = [];
	public var camLockZones:Map<String, FlxRect> = [];

	public var spawners:Array<Trigger> = [];

	public var updaters:Array<FlxBasic> = [];

	public var rawTerrainLayer:levels.ldtk.LDTKProject.Layer_Solid;
	public var rawOneWayTerrainLayer:levels.ldtk.LDTKProject.Layer_OneWay;
	public var rawTerrainDecorLayer:levels.ldtk.LDTKProject.Layer_Decoration;

	public var checkpoints:Array<levels.ldtk.LDTKProject.Entity_Checkpoint>;

	public function new(nameOrIID:String) {
		var level = project.all_worlds.Default.getLevel(nameOrIID);
		raw = level;

		bounds.width = level.pxWid;
		bounds.height = level.pxHei;

		rawTerrainLayer = level.l_Solid;
		rawOneWayTerrainLayer = level.l_OneWay;
		rawTerrainDecorLayer = level.l_Decoration;
		terrainGfx = rawTerrainLayer.render();
		terrainDecorGfx = rawTerrainDecorLayer.render();
		terrainOneWayGfx = rawOneWayTerrainLayer.render();

		rawTerrainInts = new Array<Int>();
		rawTerrainTilesWide = rawTerrainLayer.cWid;
		rawTerrainTilesTall = rawTerrainLayer.cHei;
		for (ch in 0...rawTerrainLayer.cHei) {
			for (cw in 0...rawTerrainLayer.cWid) {
				if (rawTerrainLayer.hasAnyTileAt(cw, ch)) {
					var tileStack = rawTerrainLayer.getTileStackAt(cw, ch);
					rawTerrainInts.push(tileStack[0].tileId);
				} else {
					rawTerrainInts.push(-1);
				}
			}
		}

		for (ch in 0...rawOneWayTerrainLayer.cHei) {
			for (cw in 0...rawOneWayTerrainLayer.cWid) {
				if (rawOneWayTerrainLayer.hasAnyTileAt(cw, ch)) {
					var tileStack = rawOneWayTerrainLayer.getTileStackAt(cw, ch);
					rawOneWayTerrainInts.push(tileStack[0].tileId);
				} else {
					rawOneWayTerrainInts.push(-1);
				}
			}
		}

		parseBosses(level);
		parseCamLockZones(level);
		parseCamTriggers(level);
		parseAliens(level);
		parseTurrets(level);
		parseCheckpoints(level);
	}

	function parseCheckpoints(level:LDTKProject.LDTKProject_Level) {
		checkpoints = level.l_Entities.all_Checkpoint.copy();
		checkpoints.sort((a, b) -> {
			return a.pixelX - b.pixelX;
		});
	}

	function parseTurrets(level:LDTKProject.LDTKProject_Level) {
		for (spawner in level.l_Entities.all_Turret) {
			var s = spawner;
			var maker:(TurretSpawner)->LoneTurret = (source) -> {
				return new LoneTurret(spawner.pixelX, spawner.pixelY, source);
			}
			spawners.push(new TurretSpawner(spawner.pixelX, spawner.pixelY, maker));
		}
	}

	function parseAliens(level:LDTKProject.LDTKProject_Level) {
		for (spawner in level.l_Entities.all_Alien) {
			var s = spawner;
			var maker:(AlienSpawner)->Alien = (source) -> {
				if (s.f_Type == Runner) {
					return new RunningAlien(spawner.pixelX, spawner.pixelY, source);
				} else {
					return new Alien(spawner.pixelX, spawner.pixelY, source);
				}
			}
			spawners.push(new AlienSpawner(spawner.pixelX, spawner.pixelY, maker));
		}
	}

	function parseBosses(level:LDTKProject.LDTKProject_Level) {
		for (boss in level.l_Entities.all_WallBoss) {
			updaters.push(new WallBoss(boss.pixelX, boss.pixelY));
		}

		for (boss in level.l_Entities.all_RoverBoss) {
			spawners.push(new RoverSpawner(boss.pixelX, boss.pixelY));
		}
	}

	function parseCamLockZones(level:LDTKProject.LDTKProject_Level) {
		for (lockZone in level.l_Entities.all_CameraLock) {
			camLockZones.set(lockZone.iid, FlxRect.get(lockZone.pixelX, lockZone.pixelY, lockZone.width, lockZone.height));
		}
	}

	function parseCamTriggers(level:LDTKProject.LDTKProject_Level) {
		for (trigger in level.l_Entities.all_CamTrigger) {
			var rect = FlxRect.weak(trigger.pixelX, trigger.pixelY, trigger.width, trigger.height);
			camTriggers.push(new CameraTrigger(trigger.iid, rect, trigger.f_Area.entityIid));
		}
	}
}