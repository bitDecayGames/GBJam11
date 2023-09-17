package states;

import entities.EchoSprite;
import echo.Body;
import echo.util.TileMap;
import levels.ldtk.CardinalMaker;
import flixel.math.FlxPoint;
import flixel.group.FlxGroup;
import echo.FlxEcho;
import entities.Item;
import flixel.util.FlxColor;
import debug.DebugLayers;
import achievements.Achievements;
import flixel.addons.transition.FlxTransitionableState;
import signals.Lifecycle;
import entities.Player;
import flixel.FlxSprite;
import flixel.FlxG;
import bitdecay.flixel.debug.DebugDraw;
import progress.Collected;

using echo.FlxEcho;
using states.FlxStateExt;

class PlayState extends FlxTransitionableState {
	public static var ME:PlayState;

	var lastLevel:String;

	var player:Player;

	public var levelTime = 0.0;

	public var playerGroup = new FlxGroup();
	public var terrainGroup = new FlxGroup();
	public var terrainBodies:Array<Body> = [];
	public var objects = new FlxGroup();
	public var particles = new FlxGroup();

	public function new() {
		super();
		ME = this;
	}

	override public function create() {
		super.create();

		// main will do this, but if we are dev'ing and going straight to the play screen, it may not be done yet
		Collected.initialize();

		Lifecycle.startup.dispatch();

		FlxG.camera.pixelPerfectRender = true;

		FlxEcho.init({
			width: FlxG.width,
			height: FlxG.height,
			// gravity_y: 24 * Constants.BLOCK_SIZE, // "Space station" gravity
			gravity_y: 12 * Constants.BLOCK_SIZE, // "Lunar" gravity
		});

		add(terrainGroup);
		add(objects);
		add(playerGroup);
		add(particles);

		// QuickLog.error('Example error');

		loadLevel("Level_0");
	}

	@:access(echo.FlxEcho)
	@:access(ldtk.Layer_Tiles)
	public function loadLevel(levelID:String, ?entityID:String) {
		lastLevel = levelID;

		Collected.addTime(levelTime);
		levelTime = 0;

		Collected.setLastCheckpoint(levelID);

		FlxEcho.clear();

		terrainGroup.forEach((f) -> f.destroy());
		terrainGroup.clear();

		objects.forEach((f) -> f.destroy());
		objects.clear();

		particles.forEach((f) -> f.destroy());
		particles.clear();

		playerGroup.forEach((f) -> f.destroy());
		playerGroup.clear();
		player = null;

		var level = new levels.ldtk.Level(levelID);

		camera.setScrollBoundsRect(0, 0, level.bounds.width, level.bounds.height);
		FlxEcho.instance.world.set(0, 0, level.bounds.width, level.bounds.height);

		terrainGroup.add(level.terrainGfx);

		// softFocusBounds = FlxRect.get(0, 0, level.bounds.width, level.bounds.height);
		// baseTerrainCam.setScrollBoundsRect(0, 0, level.bounds.width, level.bounds.height);

		// FlxEcho.instance.world.set(0, 0, level.bounds.width, level.bounds.height);

		// var tileObjs = TileTypes.buildTiles(level);
		terrainBodies = TileMap.generate(level.rawTerrainInts, 8, 8, level.rawTerrainTilesWide, level.rawTerrainTilesWide);
		// level.terrainGfx.add_to_group(objects);
		for (body in terrainBodies) {
			// level.terrainGfx.add_body(body);

			FlxEcho.instance.world.add(body);
		}
		
		// for (o in level.objects) {
		// 	o.add_to_group(objects);
		// 	o.camera = objectCam;
		// }

		var extraSpawnLogic:Void->Void = null;
		var spawnPoint = FlxPoint.get(50, 0);
		if (entityID != null) {
			// var matches = level.raw.l_Objects.all_Door.filter((d) -> {return d.iid == entityID;});
			// if (matches.length != 1) {
			// 	var msg = 'expected door in level ${levelID} with iid ${entityID}, but got ${matches.length} matches';
			// 	QuickLog.critical(msg);
			// }
			// var spawn = matches[0];
			// var t:Transition = null;
			// for (o in objects) {
			// 	if (o is Transition) {
			// 		t = cast o;
			// 		if (t.doorID == spawn.iid) {
			// 			// this is the door we are coming into, so open it
			// 			t.open();
			// 			break;
			// 		}
			// 	}
			// }
			// var spawnDir = CardinalMaker.fromString(spawn.f_access_dir.getName());
			// spawnPoint.set(spawn.pixelX, spawn.pixelY);
			// TODO: find a better way to calculate this offset
			// spawnPoint.addPoint(spawnDir.asVector().scale(16));

			FlxEcho.updates = false;
			FlxEcho.instance.active = false;
		} else if (level.raw.l_Entities.all_Player_spawn.length > 0) {
			var rawSpawn = level.raw.l_Entities.all_Player_spawn[0];
			spawnPoint.set(rawSpawn.pixelX, rawSpawn.pixelY);
		} else {
			QuickLog.critical('no spawn found, and no entity provided. Cannot spawn player');
		}

		player = new Player(spawnPoint.x, spawnPoint.y);
		camera.follow(player);
		player.add_to_group(playerGroup);
		// player.camera = objectCam;
		// deltaModIgnorers.add(player);
		if (extraSpawnLogic != null) {
			extraSpawnLogic();
		}

		// We need to cache our non-interacting collisions to avoid glitchy
		// physics if they change color after they overlap with a valid color
		// match.
		FlxEcho.instance.world.listen(player.get_body(), terrainBodies, {
			// condition: Collide.colorBodiesDoNotInteract,
			separate: true,
			enter: (a, b, o) -> {
				if (a.object is EchoSprite) {
					var aSpr:EchoSprite = cast a.object;
					aSpr.handleEnter(b, o);
				}
			},
			exit: (a, b) -> {
				if (a.object is EchoSprite) {
					var aSpr:EchoSprite = cast a.object;
					aSpr.handleExit(b);
				}
			}
		});

		// FlxEcho.listen(playerGroup, lasers, {
		// 	condition: Collide.colorBodiesInteract,
		// 	enter: (a, b, o) -> {
		// 		if (Std.isOfType(a.object, ColorCollideSprite)) {
		// 			cast(a.object, ColorCollideSprite).handleEnter(b, o);
		// 		}
		// 		if (Std.isOfType(b.object, ColorCollideSprite)) {
		// 			cast(b.object, ColorCollideSprite).handleEnter(a, o);
		// 		}
		// 	},
		// 	stay: (a, b, o) -> {
		// 		if (Std.isOfType(a.object, ColorCollideSprite)) {
		// 			cast(a.object, ColorCollideSprite).handleStay(b, o);
		// 		}
		// 		if (Std.isOfType(b.object, ColorCollideSprite)) {
		// 			cast(b.object, ColorCollideSprite).handleStay(a, o);
		// 		}
		// 	},
		// });

		// FlxEcho.listen(playerGroup, objects, {
		// 	condition: Collide.colorBodiesInteract,
		// 	correction_threshold: .025, // not sure if this actually helps, but it seems to result in less snagging
		// 	enter: (a, b, o) -> {
		// 		if (Std.isOfType(a.object, ColorCollideSprite)) {
		// 			cast(a.object, ColorCollideSprite).handleEnter(b, o);
		// 		}
		// 		if (Std.isOfType(b.object, ColorCollideSprite)) {
		// 			cast(b.object, ColorCollideSprite).handleEnter(a, o);
		// 		}
		// 	},
		// 	stay: (a, b, o) -> {
		// 		if (Std.isOfType(a.object, ColorCollideSprite)) {
		// 			cast(a.object, ColorCollideSprite).handleStay(b, o);
		// 		}
		// 		if (Std.isOfType(b.object, ColorCollideSprite)) {
		// 			cast(b.object, ColorCollideSprite).handleStay(a, o);
		// 		}
		// 	},
		// 	exit: (a, b) -> {
		// 		if (Std.isOfType(a.object, ColorCollideSprite)) {
		// 			cast(a.object, ColorCollideSprite).handleExit(b);
		// 		}
		// 		if (Std.isOfType(b.object, ColorCollideSprite)) {
		// 			cast(b.object, ColorCollideSprite).handleExit(a);
		// 		}
		// 	},
		// });
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		var cam = FlxG.camera;
		DebugDraw.ME.drawCameraRect(cam.getCenterPoint().x - 5, cam.getCenterPoint().y - 5, 10, 10, DebugLayers.RAYCAST, FlxColor.RED);
		DebugDraw.ME.drawWorldRect(10, 10, 140, 124, DebugLayers.RAYCAST, FlxColor.RED);
	}

	override public function onFocusLost() {
		super.onFocusLost();
		this.handleFocusLost();
	}

	override public function onFocus() {
		super.onFocus();
		this.handleFocus();
	}
}
