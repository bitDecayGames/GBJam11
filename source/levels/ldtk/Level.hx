package levels.ldtk;

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
	public var rawTerrainInts = new Array<Int>();
	public var rawTerrainTilesWide = 0;
	public var rawTerrainTilesTall = 0;

	// public var rawCoarseTerrainInts = new Array<Int>();
	// public var rawCoarseTerrainTilesWide = 0;
	// public var rawCoarseTerrainTilesTall = 0;

	public var rawTerrainLayer:levels.ldtk.LDTKProject.Layer_Terrain;

	// public var objects = new FlxTypedGroup<FlxObject>();
	// public var beams = new FlxTypedGroup<FlxObject>();
	// public var emitters = new Array<FlxEmitter>();
	// public var playerSpawn:Entity_Player_spawn;

	// public var camZones:Map<String, FlxRect>;
	// // public var camTransitionZones:Array<CameraTransitionZone>;

	public function new(nameOrIID:String) {
		var level = project.all_worlds.Default.getLevel(nameOrIID);
		raw = level;

		bounds.width = level.pxWid;
		bounds.height = level.pxHei;
		rawTerrainLayer = level.l_Terrain;
		terrainGfx = level.l_Terrain.render();
		rawTerrainInts = new Array<Int>();
		rawTerrainTilesWide = level.l_Terrain.cWid;
		rawTerrainTilesTall = level.l_Terrain.cHei;
		for (ch in 0...level.l_Terrain.cHei) {
			for (cw in 0...level.l_Terrain.cWid) {
				if (level.l_Terrain.hasAnyTileAt(cw, ch)) {
					var tileStack = level.l_Terrain.getTileStackAt(cw, ch);
					rawTerrainInts.push(tileStack[0].tileId);
				} else {
					rawTerrainInts.push(0);
				}
			}
		}

	// 	parseLaserRails(level);
	// 	parseLaserTurrets(level);
	// 	parseLaserStationary(level);
	// 	parseCameraAreas(level);
	// 	parseCameraTransitions(level);
		parseBosses(level);
	}

	function parseBosses(level:LDTKProject.LDTKProject_Level) {
		for (boss in level.l_Entities.all_WallBoss) {
			new WallBoss(boss.pixelX, boss.pixelY);
		}
	}

	// function parseLaserRails(level:LDTKProject_Level) {
	// 	var laserOps:Array<LaserRailOptions> = [];
	// 	for (l in level.l_Objects.all_Laser_rail_up) {
	// 		laserOps.push({
	// 			spawnX: l.pixelX,
	// 			spawnY: l.pixelY,
	// 			color: Color.fromEnum(l.f_Color),
	// 			dir: Cardinal.N,
	// 			path: [for (point in l.f_path) {
	// 				FlxPoint.get(point.cx * level.l_Objects.gridSize, point.cy * level.l_Objects.gridSize);
	// 			}],
	// 			pauseOnFire: l.f_Pause_on_fire,
	// 			rest: l.f_Rest,
	// 			delay: l.f_Initial_delay,
	// 			shootOnNode: l.f_Shoot_on_node,
	// 			laserTime: l.f_Laser_time,
	// 			muted: false,
	// 		});
	// 	}
	// 	for (l in level.l_Objects.all_Laser_rail_down) {
	// 		laserOps.push({
	// 			spawnX: l.pixelX,
	// 			spawnY: l.pixelY,
	// 			color: Color.fromEnum(l.f_Color),
	// 			dir: Cardinal.S,
	// 			path: [for (point in l.f_path) {
	// 				FlxPoint.get(point.cx * level.l_Objects.gridSize, point.cy * level.l_Objects.gridSize);
	// 			}],
	// 			pauseOnFire: l.f_Pause_on_fire,
	// 			rest: l.f_Rest,
	// 			delay: l.f_Initial_delay,
	// 			shootOnNode: l.f_Shoot_on_node,
	// 			laserTime: l.f_Laser_time,
	// 			muted: false,
	// 		});
	// 	}
	// 	for (l in level.l_Objects.all_Laser_rail_left) {
	// 		laserOps.push({
	// 			spawnX: l.pixelX,
	// 			spawnY: l.pixelY,
	// 			color: Color.fromEnum(l.f_Color),
	// 			dir: Cardinal.W,
	// 			path: [for (point in l.f_path) {
	// 				FlxPoint.get(point.cx * level.l_Objects.gridSize, point.cy * level.l_Objects.gridSize);
	// 			}],
	// 			pauseOnFire: l.f_Pause_on_fire,
	// 			rest: l.f_Rest,
	// 			delay: l.f_Initial_delay,
	// 			shootOnNode: l.f_Shoot_on_node,
	// 			laserTime: l.f_Laser_time,
	// 			muted: false,

	// 		});
	// 	}
	// 	for (l in level.l_Objects.all_Laser_rail_right) {
	// 		laserOps.push({
	// 			spawnX: l.pixelX,
	// 			spawnY: l.pixelY,
	// 			color: Color.fromEnum(l.f_Color),
	// 			dir: Cardinal.E,
	// 			path: [for (point in l.f_path) {
	// 				FlxPoint.get(point.cx * level.l_Objects.gridSize, point.cy * level.l_Objects.gridSize);
	// 			}],
	// 			pauseOnFire: l.f_Pause_on_fire,
	// 			rest: l.f_Rest,
	// 			delay: l.f_Initial_delay,
	// 			shootOnNode: l.f_Shoot_on_node,
	// 			laserTime: l.f_Laser_time,
	// 			muted: false,
	// 		});
	// 	}

	// 	for (l_config in laserOps) {
	// 		var laser = new LaserRail(l_config);
	// 		objects.add(laser);
	// 		objects.add(laser.chargeParticle);
	// 		beams.add(laser.beam);
	// 		emitters.push(laser.emitter);
	// 	}
	// }

	// function parseLaserTurrets(level:LDTKProject_Level) {
	// 	for (laser_turret in level.l_Objects.all_Laser_turret) {
	// 		var spawnPoint = FlxPoint.get(laser_turret.pixelX, laser_turret.pixelY);
	// 		var adjust = FlxPoint.get(-16, -16);
	// 		spawnPoint.addPoint(adjust);
	// 		var path = new Array<FlxPoint>();
	// 		path.push(spawnPoint);
	// 		var laser = new LaserTurret({
	// 			spawnX: spawnPoint.x,
	// 			spawnY: spawnPoint.y,
	// 			color: Color.fromEnum(laser_turret.f_Color),
	// 			dir: N,
	// 			rest: laser_turret.f_Rest,
	// 			delay: laser_turret.f_Initial_delay,
	// 			laserTime: laser_turret.f_Laser_time,
	// 			muted: false,
	// 		});
	// 		objects.add(laser);
	// 		objects.add(laser.chargeParticle);
	// 		beams.add(laser.beam);
	// 		emitters.push(laser.emitter);
	// 	}
	// }

	// function parseLaserStationary(level:LDTKProject_Level) {
	// 	var laserOps:Array<BaseLaserOptions> = [];

	// 	for (l in level.l_Objects.all_Laser_mount_up) {
	// 		laserOps.push({
	// 			spawnX: l.pixelX,
	// 			spawnY: l.pixelY,
	// 			color: Color.fromEnum(l.f_Color),
	// 			dir: Cardinal.N,
	// 			rest: l.f_Rest,
	// 			laserTime: l.f_Laser_time,
	// 			delay: l.f_Initial_delay,
	// 			muted: l.f_Mute,
	// 		});
	// 	}
	// 	for (l in level.l_Objects.all_Laser_mount_down) {
	// 		laserOps.push({
	// 			spawnX: l.pixelX,
	// 			spawnY: l.pixelY,
	// 			color: Color.fromEnum(l.f_Color),
	// 			dir: Cardinal.S,
	// 			rest: l.f_Rest,
	// 			laserTime: l.f_Laser_time,
	// 			delay: l.f_Initial_delay,
	// 			muted: l.f_Mute,
	// 		});
	// 	}
	// 	for (l in level.l_Objects.all_Laser_mount_left) {
	// 		laserOps.push({
	// 			spawnX: l.pixelX,
	// 			spawnY: l.pixelY,
	// 			color: Color.fromEnum(l.f_Color),
	// 			dir: Cardinal.W,
	// 			rest: l.f_Rest,
	// 			laserTime: l.f_Laser_time,
	// 			delay: l.f_Initial_delay,
	// 			muted: l.f_Mute,
	// 		});
	// 	}
	// 	for (l in level.l_Objects.all_Laser_mount_right) {
	// 		laserOps.push({
	// 			spawnX: l.pixelX,
	// 			spawnY: l.pixelY,
	// 			color: Color.fromEnum(l.f_Color),
	// 			dir: Cardinal.E,
	// 			rest: l.f_Rest,
	// 			laserTime: l.f_Laser_time,
	// 			delay: l.f_Initial_delay,
	// 			muted: l.f_Mute,
	// 		});
	// 	}

	// 	for (l_config in laserOps) {
	// 		var laser = new LaserStationary(l_config);
	// 		objects.add(laser);
	// 		objects.add(laser.chargeParticle);
	// 		beams.add(laser.beam);
	// 		emitters.push(laser.emitter);
	// 	}

	// 	for (l in level.l_Objects.all_Perma_laser) {
	// 		var laser = new PermaLaser(l.pixelX, l.pixelY, CardinalMaker.fromString(l.f_Direction.getName()), Color.fromEnum(l.f_Color));
	// 		objects.add(laser);
	// 	}
	// }

	// function parseCameraAreas(level:LDTKProject_Level) {
	// 	camZones = new Map<String, FlxRect>();
	// 	for (guide in level.l_Objects.all_Camera_guide) {
	// 		camZones.set(guide.iid, FlxRect.get(guide.pixelX, guide.pixelY, guide.width, guide.height));
	// 	}
	// }

	// function parseCameraTransitions(level:LDTKProject_Level) {
	// 	camTransitionZones = new Array<CameraTransitionZone>();
	// 	for (zone in level.l_Objects.all_Camera_transition) {
	// 		var transArea = FlxRect.get(zone.pixelX, zone.pixelY, zone.width, zone.height);
	// 		var camTrigger = new CameraTransitionZone(transArea);
	// 		for (i in 0...zone.f_dir.length) {
	// 			camTrigger.addGuideTrigger(CardinalMaker.fromString(zone.f_dir[i].getName()), camZones.get(zone.f_areas[i].entityIid));
	// 		}
	// 		camTransitionZones.push(camTrigger);
	// 	}
	// }
}