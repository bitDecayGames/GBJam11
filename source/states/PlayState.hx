package states;

import flixel.addons.display.FlxBackdrop;
import flixel.math.FlxRect;
import entities.particle.Explosion;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import entities.SoldierPod;
import flixel.effects.particles.FlxEmitter;
import echo.Line;
import states.substate.SoldierIntro;
import ui.font.BitmapText.Trooper;
import flixel.FlxObject;
import entities.sensor.Trigger;
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

	public var player:Player;

	public var level:levels.ldtk.Level;
	public var levelTime = 0.0;

	public var playerGroup = new FlxGroup();
	public var terrainGroup = new FlxGroup();
	public var terrainBodies:Array<Body> = [];
	public var objects = new FlxGroup();
	public var corpseGroup = new FlxGroup();
	public var playerBullets = new FlxGroup();
	public var enemyBullets = new FlxGroup();
	public var emitters = new FlxGroup();
	public var particles = new FlxGroup();
	public var topParticles = new FlxGroup();
	public var triggers = new FlxGroup();

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
		FlxG.camera.bgColor = Constants.DARKEST;

		FlxEcho.init({
			width: FlxG.width,
			height: FlxG.height,
			// gravity_y: 24 * Constants.BLOCK_SIZE, // "Space station" gravity
			gravity_y: 12 * Constants.BLOCK_SIZE, // "Lunar" gravity
		});

		var bg = new FlxBackdrop(AssetPaths.MoonscapeBG__png, X);
		bg.scrollFactor.set(.2, 1);

		add(bg);
		add(terrainGroup);
		add(corpseGroup);
		add(objects);
		add(playerGroup);
		add(playerBullets);
		add(enemyBullets);
		add(emitters);
		add(particles);
		add(topParticles);
		add(triggers);

		// QuickLog.error('Example error');

		var cpLevel = Collected.getCheckpointLevel();
		if (cpLevel == null) {
			cpLevel = "Level_0";
		}
		loadLevel("Level_0", Collected.getCheckpointID());
	}

	@:access(echo.FlxEcho)
	@:access(ldtk.Layer_Tiles)
	public function loadLevel(levelID:String, ?entityID:String) {
		lastLevel = levelID;

		Collected.addTime(levelTime);
		levelTime = 0;

		Collected.setLastCheckpoint(levelID, null);

		FlxEcho.clear();

		terrainGroup.forEach((f) -> f.destroy());
		terrainGroup.clear();

		objects.forEach((f) -> f.destroy());
		objects.clear();

		corpseGroup.forEach((f) -> f.destroy());
		corpseGroup.clear();

		playerBullets.forEach((f) -> f.destroy());
		playerBullets.clear();
		
		enemyBullets.forEach((f) -> f.destroy());
		enemyBullets.clear();

		emitters.forEach((f) -> f.destroy());
		emitters.clear();

		particles.forEach((f) -> f.destroy());
		particles.clear();

		topParticles.forEach((f) -> f.destroy());
		topParticles.clear();

		triggers.forEach((f) -> f.destroy());
		triggers.clear();

		playerGroup.forEach((f) -> f.destroy());
		playerGroup.clear();
		player = null;

		for (body in terrainBodies) {
			FlxEcho.instance.world.remove(body);
			body.dispose();
		}

		level = new levels.ldtk.Level(levelID);

		camera.setScrollBoundsRect(0, 0, level.bounds.width, level.bounds.height);
		FlxEcho.instance.world.set(0, 0, level.bounds.width, level.bounds.height);

		terrainGroup.add(level.terrainGfx);

		for (trigger in level.camTriggers) {
			trigger.add_to_group(triggers);
		}

		terrainBodies = TileMap.generate(level.rawTerrainInts, 8, 8, level.rawTerrainTilesWide, level.rawTerrainTilesWide);
		for (body in terrainBodies) {
			FlxEcho.instance.world.add(body);
		}
		
		FlxEcho.add_group_bodies(playerGroup);
		
		var spawnPoint = getLevelSpawnPoint();
		// give a slight delay before we start the action
		new FlxTimer().start(1, (t) -> {
			spawnPlayer(spawnPoint);
		});

		createLevelBoundingBox();

		// We need to cache our non-interacting collisions to avoid glitchy
		// physics if they change color after they overlap with a valid color
		// match.
		FlxEcho.instance.world.listen(FlxEcho.get_group_bodies(playerGroup), terrainBodies, {
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

		FlxEcho.listen(playerGroup, enemyBullets, {
			separate: false,
			enter: (a, b, o) -> {
				if (a.object is EchoSprite) {
					var aSpr:EchoSprite = cast a.object;
					aSpr.handleEnter(b, o);
				}
				if (b.object is EchoSprite) {
					var bSpr:EchoSprite = cast b.object;
					bSpr.handleEnter(a, o);
				}
			},
			exit: (a, b) -> {
				if (a.object is EchoSprite) {
					var aSpr:EchoSprite = cast a.object;
					aSpr.handleExit(b);
				}
				if (b.object is EchoSprite) {
					var bSpr:EchoSprite = cast b.object;
					bSpr.handleExit(a);
				}
			}
		});

		FlxEcho.listen(playerBullets, objects, {
			separate: false,
			enter: (a, b, o) -> {
				if (a.object is EchoSprite) {
					var aSpr:EchoSprite = cast a.object;
					aSpr.handleEnter(b, o);
				}
				if (b.object is EchoSprite) {
					var bSpr:EchoSprite = cast b.object;
					bSpr.handleEnter(a, o);
				}
			},
			exit: (a, b) -> {
				if (a.object is EchoSprite) {
					var aSpr:EchoSprite = cast a.object;
					aSpr.handleExit(b);
				}
				if (b.object is EchoSprite) {
					var bSpr:EchoSprite = cast b.object;
					bSpr.handleExit(a);
				}
			}
		});

		FlxEcho.listen(playerGroup, triggers, {
			separate: false,
			enter: (a, b, o) -> {
				// Note: Pretty sure the order we listen in dictates what comes through as
				// our `a` and `b`, but just in case, we'll check both sides
				if (a.object is Trigger) {
					var t:Trigger = cast a.object;
					t.activate();
				}
				if (b.object is Trigger) {
					var t:Trigger = cast b.object;
					t.activate();
				}
			},
		});
	}

	function createLevelBoundingBox() {
		var left = new Body({
			x: -5,
			y: level.raw.pxHei / 2,
			shapes: [
				{
					type:RECT,
					width: 10,
					height: level.raw.pxHei,
				},
			],
			kinematic: true,
		});
		addTerrain(left);
		var right = new Body({
			x: level.raw.pxWid + 5,
			y: level.raw.pxHei / 2,
			shapes: [
				{
					type:RECT,
					width: 10,
					height: level.raw.pxHei,
				},
			],
			kinematic: true,
		});
		addTerrain(right);
	}

	function getLevelSpawnPoint(entityID:String = null):FlxPoint {
		var spawnPoint = FlxPoint.get(50, 0);
		if (entityID != null) {
			var matches = level.raw.l_Entities.all_Checkpoint.filter((c) -> {return c.iid == entityID;});
			// var matches = level.raw.l_Objects.all_Door.filter((d) -> {return d.iid == entityID;});
			if (matches.length != 1) {
				var msg = 'expected checkpoint in level with iid ${entityID}, but got ${matches.length} matches';
				QuickLog.critical(msg);
			}
			var spawn = matches[0];
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

			spawnPoint.set(spawn.pixelX, spawn.pixelY);

			// FlxEcho.updates = false;
			// FlxEcho.instance.active = false;
		} else if (level.raw.l_Entities.all_Player_spawn.length > 0) {
			var rawSpawn = level.raw.l_Entities.all_Player_spawn[0];
			spawnPoint.set(rawSpawn.pixelX, rawSpawn.pixelY);
		} else {
			QuickLog.critical('no spawn found, and no entity provided. Cannot spawn player');
		}

		return spawnPoint;
	}

	function spawnPlayer(point:FlxPoint, respawn:Bool = false, cb:Void->Void = null) {
		camera.follow(null);
		camera.focusOn(point);

		var groundCast = Line.get(point.x, point.y, point.x, point.y + 144);
		var ground = groundCast.linecast(terrainBodies);
		if (ground != null) {
			point.set(ground.closest.hit.x, ground.closest.hit.y);
		}

		var podAngle = FlxPoint.get(1, 0).rotateByDegrees(-75);
		podAngle.scale(FlxG.height * 1.2);
		podAngle.addPoint(point);

		var pod = new SoldierPod(podAngle.x, podAngle.y);
		particles.add(pod);
		FlxTween.tween(pod, {x: point.x - 20, y: point.y - pod.height * .9}, {
			onComplete: (t) -> {
				pod.landed();
				camera.shake(0.03, 0.1);

				var boomDelay = respawn ? 0.5 : 2;
				new FlxTimer().start(boomDelay, (t) -> {
					Explosion.death(10, FlxRect.weak(pod.x, pod.y, pod.width, pod.height), 1, () -> {
						camera.flash(Constants.LIGHTEST, 0.5);
						pod.kill();
						player = new Player(point.x, point.y);
						player.body.active = true;
						player.inControl = false;
						player.body.velocity.set(10, -60);
						camera.follow(player);
						player.add_to_group(playerGroup);
						persistentUpdate = true;
						openSubState(new SoldierIntro(1, () -> {
							player.inControl = true;
							player.body.active = true;
							if (respawn) {
								player.invulnerable(1);
							}
						}));
						if (cb != null) cb();
					});
				});
			}
		});
	}

	public function resetCamera() {
		camera.follow(null);
		camera.setScrollBoundsRect(0, 0, level.bounds.width, level.bounds.height);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		for (cp in level.raw.l_Entities.all_Checkpoint) {
			DebugDraw.ME.drawWorldCircle(cp.pixelX, cp.pixelY, 2, LEVEL);
		}

		tryUpdatingCheckpoint();
	}

	var nextCPCheck = 0;
	function tryUpdatingCheckpoint() {
		if (player == null) {
			return;
		}

		var cps = level.raw.l_Entities.all_Checkpoint;
		for (i in nextCPCheck...cps.length) {
			if (player.body.x > cps[i].pixelX) {
				Collected.setLastCheckpoint(level.raw.iid, cps[i].iid);
				nextCPCheck = i + 1;
			}
		}
	}

	public function killPlayer() {
		player.remove_from_group(playerGroup);
		player.remove_object();

		// force them to a rounded pixel position to avoid jitters
		player.x = Math.round(player.x);
		
		corpseGroup.add(player);

		var cpID = Collected.getCheckpointID();
		var respawnPoint = getLevelSpawnPoint();
		var matches = level.raw.l_Entities.all_Checkpoint.filter((c) -> {return c.iid == cpID;});
		if (matches != null && matches.length == 1) {
			respawnPoint.set(matches[0].pixelX, matches[0].pixelY);
			var needsReset = matches[0].f_Reset_Ents;
			for (t in level.camTriggers) {
				for (nr in needsReset) {
					if (nr.entityIid == t.eID) {
						t.resetTrigger();
					}
				}
			}
		}

		spawnPlayer(respawnPoint, true);
	}

	public function addTerrain(b:Body) {
		terrainBodies.push(b);
		FlxEcho.instance.world.add(b);
	}

	public function addBGTerrain(b:FlxSprite) {
		// TODO: Do we need a separate group for things we want the player to collide with, but bullets NOT to?
		b.add_to_group(terrainGroup);
	}

	public function addEnemyBullet(b:FlxSprite) {
		b.add_to_group(enemyBullets);
	}

	public function addPlayerBullet(b:FlxSprite) {
		b.add_to_group(playerBullets);
	}

	public function recycleBullet(b:FlxSprite) {
		b.remove_from_group(enemyBullets);
		b.remove_from_group(playerBullets);
	}

	public function addBasicParticle(p:FlxSprite) {
		particles.add(p);
	}

	public function addTopParticle(p:FlxSprite) {
		topParticles.add(p);
	}

	public function addParticleEmitter(e:FlxEmitter) {
		emitters.add(e);
	}

	public function addObject(e:FlxObject) {
		e.add_to_group(objects);
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
