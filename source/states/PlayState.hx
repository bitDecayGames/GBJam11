package states;

import flixel.tweens.FlxEase;
import entities.Shuttle;
import helpers.Analytics;
import echo.data.Data.CollisionData;
import echo.util.AABB;
import states.substate.LevelSummary;
import ui.Fader;
import states.substate.LevelIntro;
import entities.sensor.NextLevelTrigger;
import flixel.FlxBasic;
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
	public var terrainDecorGroup = new FlxGroup();
	public var terrainOneWayGroup = new FlxGroup();

	public var terrainBodies:Array<Body> = [];
	public var terrainOneWayBodies:Array<Body> = [];
	public var allGroundingBodies:Array<Body> = [];

	public var playerTerrainBodies:Array<Body> = [];
	public var objects = new FlxGroup();
	public var corpseGroup = new FlxGroup();
	public var playerBullets = new FlxGroup();
	public var enemies = new FlxGroup();
	public var enemyBullets = new FlxGroup();
	public var emitters = new FlxGroup();
	public var particles = new FlxGroup();
	public var topParticles = new FlxGroup();
	public var triggers = new FlxGroup();
	public var scrollTriggers = new FlxTypedGroup<Trigger>();

	public var updaters = new FlxTypedGroup<FlxBasic>();

	var fader:Fader;

	public function new() {
		super();
		ME = this;
	}

	override public function create() {
		super.create();

		FmodManager.PlaySong(FmodSongs.Song3);

		// main will do this, but if we are dev'ing and going straight to the play screen, it may not be done yet
		Collected.initialize();

		Lifecycle.startup.dispatch();

		FlxG.camera.pixelPerfectRender = true;
		FlxG.camera.bgColor = Constants.DARKEST;

		FlxEcho.init({
			width: FlxG.width,
			height: FlxG.height,
			// gravity_y: 20 * Constants.BLOCK_SIZE, // "Space station" gravity
			gravity_y: 10 * Constants.BLOCK_SIZE, // "Lunar" gravity
		});

		fader = new Fader();

		var stars = new FlxBackdrop(AssetPaths.Stars__png, X);
		stars.scrollFactor.set(.05, 1);

		var bg = new FlxBackdrop(AssetPaths.MoonscapeBG__png, X);
		bg.scrollFactor.set(.2, 1);

		add(stars);
		add(bg);
		add(terrainDecorGroup);
		add(terrainGroup);
		add(terrainOneWayGroup);
		add(corpseGroup);
		add(objects);
		add(enemies);
		add(playerGroup);
		add(playerBullets);
		add(enemyBullets);
		add(emitters);
		add(particles);
		add(topParticles);
		add(triggers);
		add(scrollTriggers);
		add(updaters);
		add(fader);

		var startLevel = "Level_2";
		#if logan
		startLevel = "Level_3";
		#end

		loadLevel(startLevel, Collected.getCheckpointID());
	}

	@:access(echo.FlxEcho)
	@:access(ldtk.Layer_Tiles)
	public function loadLevel(levelID:String, ?entityID:String) {
		Analytics.reportLevelFinished(level == null ? "initial_load" : level.raw.identifier, Collected.getDeathCount());

		lastLevel = levelID;

		Collected.addTime(levelTime);
		levelTime = 0;

		nextCPCheck = 0;
		Collected.setLastCheckpoint(levelID, null);

		terrainDecorGroup.forEach((f) -> f.destroy());
		terrainDecorGroup.clear();

		terrainGroup.forEach((f) -> f.destroy());
		terrainGroup.clear();

		terrainOneWayGroup.forEach((f) -> f.destroy());
		terrainOneWayGroup.clear();

		objects.forEach((f) -> f.destroy());
		objects.clear();

		corpseGroup.forEach((f) -> f.destroy());
		corpseGroup.clear();

		playerBullets.forEach((f) -> f.kill());
		playerBullets.clear();
		
		enemyBullets.forEach((f) -> f.kill());
		enemyBullets.clear();

		emitters.forEach((f) -> f.destroy());
		emitters.clear();

		particles.forEach((f) -> f.destroy());
		particles.clear();

		topParticles.forEach((f) -> {
			if (f is Explosion) {
				f.kill();
			} else {
				f.destroy();
			}
		});
		topParticles.clear();

		triggers.forEach((f) -> f.destroy());
		triggers.clear();

		scrollTriggers.forEach((f) -> f.destroy());
		scrollTriggers.clear();

		playerGroup.forEach((f) -> f.destroy());
		playerGroup.clear();
		player = null;

		enemies.forEach((f) -> f.destroy());
		enemies.clear();

		updaters.forEach((f) -> f.destroy());
		updaters.clear();

		FlxEcho.clear();

		for (body in terrainBodies) {
			FlxEcho.instance.world.remove(body);
			body.dispose();
		}
		terrainBodies = [];

		for (body in terrainOneWayBodies) {
			FlxEcho.instance.world.remove(body);
			body.dispose();
		}
		terrainOneWayBodies = [];

		for (body in playerTerrainBodies) {
			FlxEcho.instance.world.remove(body);
			body.dispose();
		}
		playerTerrainBodies = [];

		level = new levels.ldtk.Level(levelID);

		for (basic in level.updaters) {
			updaters.add(basic);
		}

		camera.scroll.set();
		camera.setScrollBoundsRect(0, 0, level.bounds.width, level.bounds.height);
		FlxEcho.instance.world.set(0, 0, level.bounds.width, level.bounds.height);

		terrainDecorGroup.insert(0, level.terrainDecorGfx);
		terrainGroup.add(level.terrainGfx);
		terrainOneWayGroup.add(level.terrainOneWayGfx);

		for (trigger in level.camTriggers) {
			trigger.add_to_group(triggers);
		}

		for (trigger in level.spawners) {
			scrollTriggers.add(trigger);
		}

		terrainBodies = terrainBodies.concat(TileMap.generate(level.rawTerrainInts, 8, 8, level.rawTerrainTilesWide, level.rawTerrainTilesWide, 0, 0, 0));
		for (body in terrainBodies) {
			FlxEcho.instance.world.add(body);
		}

		terrainOneWayBodies = terrainOneWayBodies.concat(TileMap.generate(level.rawOneWayTerrainInts, 8, 8, level.rawTerrainTilesWide, level.rawTerrainTilesWide, 0, 0, 0));
		for (body in terrainOneWayBodies) {
			FlxEcho.instance.world.add(body);
		}

		allGroundingBodies = [];
		allGroundingBodies = allGroundingBodies.concat(terrainBodies).concat(terrainOneWayBodies);
		
		// make sure the arrays exist so our listeners are functioning as intended
		FlxEcho.add_group_bodies(playerGroup);
		FlxEcho.add_group_bodies(enemies);
		
		var spawnPoint = getLevelSpawnPoint();
		// give a slight delay before we start the action
		// new FlxTimer().start(1, (t) -> {
		// 	spawnPlayer(spawnPoint);
		// });

		createEndLevelTrigger();
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

		FlxEcho.instance.world.listen(FlxEcho.get_group_bodies(playerGroup), terrainOneWayBodies, {
			separate: true,
			condition: oneWayCondition,
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

		FlxEcho.instance.world.listen(FlxEcho.get_group_bodies(playerGroup), playerTerrainBodies, {
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

		// collide enemies as second group so they are always on the 'b' side of interaction
		FlxEcho.instance.world.listen(terrainBodies, FlxEcho.get_group_bodies(enemies), {
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

		// collide enemies as second group so they are always on the 'b' side of interaction
		FlxEcho.instance.world.listen(terrainOneWayBodies, FlxEcho.get_group_bodies(enemies), {
			separate: true,
			condition: oneWayCondition,
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

		// collide enemies as second group so they are always on the 'b' side of interaction
		FlxEcho.listen(playerBullets, enemies, {
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

		// collide enemies as second group so they are always on the 'b' side of interaction
		FlxEcho.listen(playerGroup, enemies, {
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

		fader.fadeIn(() -> {
			openSubState(new LevelIntro(() -> {
				new FlxTimer().start(1, (t) -> {
					spawnPlayer(spawnPoint);
				});
			}));
		});
	}

	var halfPi = Math.PI/2;
	var tmpAABB = AABB.get();
	var tmpAABB2 = AABB.get();
	function oneWayCondition(a:Body, b:Body, data:Array<CollisionData>):Bool {
		if (Math.abs(data[0].normal.radians - halfPi) < .1) {
			if (a.velocity.y > 0) {
				a.bounds(tmpAABB);
				b.bounds(tmpAABB2);
				if (Math.abs(tmpAABB.max_y - tmpAABB2.min_y) < 2) {
					return true;
				}
			}
		}
		return false;
	}

	function createEndLevelTrigger() {
		for (nl in level.raw.l_Entities.all_NextLevel) {
			var t = new NextLevelTrigger(nl.iid, FlxRect.weak(nl.pixelX, nl.pixelY, nl.width, nl.height), nl.f_Entity_ref.levelIid);
			t.add_to_group(triggers);
		}
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
		addTerrain(left);
		addTerrain(right);
	}

	public function clearEnemiesForBoss() {
		for (b in enemyBullets) {
			b.kill();
		}

		for (e in enemies) {
			e.kill();
		}
	}

	function getLevelSpawnPoint(entityID:String = null):FlxPoint {
		var spawnPoint = FlxPoint.get(50, 0);
		if (entityID != null) {
			var matches = level.checkpoints.filter((c) -> {return c.iid == entityID;});
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

	public function playEndSequence() {
		player.inControl = false;
		// spawn ship, fly into screen
		var shuttle = new Shuttle();
		shuttle.setPosition(camera.viewLeft - shuttle.width, camera.viewTop - shuttle.height);
		// XXX: adding it here to get render order correct
		enemies.add(shuttle);
		new FlxTimer().start(0.5, (timer) -> {
			shuttle.doLanding();
		});
		player.flipX = player.body.x > shuttle.x + 90;
		FlxTween.tween(shuttle, {x: camera.viewLeft + 5, y: camera.viewTop + 25}, {
			ease: FlxEase.sineOut,
			onComplete: (t) -> {
				player.flipX = player.body.x > shuttle.x + 90;
				new FlxTimer().start(0.5, (timer) -> {
					// ship door opens
					shuttle.openDoor(() -> {
						new FlxTimer().start(1, (timer2) -> {
							player.body.active = false;
							FlxTween.tween(player.body, {x: shuttle.x + 90});
							FlxTween.tween(player.body, {y: shuttle.y}, 0.7, {
								ease: FlxEase.sineOut,
								onComplete: (t2) -> {
									FlxTween.tween(player.body, {y: shuttle.y + 35}, 0.3, {
										ease: FlxEase.sineIn,
										onComplete: (t3) -> {
											player.visible = false;
											shuttle.closeDoor(() -> {
												shuttle.takeOff();
												FlxTween.tween(shuttle, {x: camera.viewRight, y: camera.viewTop - shuttle.height}, {
													ease: FlxEase.sineIn,
													onComplete: (t4) -> {
														fader.fadeOut(() -> FlxG.switchState(new CreditsState()));
													}
												});
											});
										}
									});
								}
							});
						});
					});
				});
			}
		});
		// player jumps onto ship

		// ship door closes
		// ship flies away
		// transition to end scene
		// transition to credits
	}

	public function transitionToLevel(iid:String) {
		player.inControl = false;
		fader.fadeOut(() -> {
			openSubState(new LevelSummary(() -> {
				loadLevel(iid);
			}));
		});
	}

	function spawnPlayer(point:FlxPoint, respawn:Bool = false, cb:Void->Void = null) {
		for (b in enemyBullets) {
			b.kill();
		}

		for (e in enemies) {
			e.kill();
		}

		camera.follow(null);
		camera.focusOn(point);

		findGroundUnderPoint(point, point);

		var podAngle = FlxPoint.get(1, 0).rotateByDegrees(-75);
		podAngle.scale(FlxG.height * 1.5);
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
						FmodManager.PlaySoundOneShot(FmodSFX.ShipExplode);
						camera.flash(Constants.LIGHTEST, 0.5);
						pod.kill();
						player = new Player(point.x, point.y);
						player.killable = false;
						player.body.active = true;
						player.inControl = false;
						player.body.velocity.set(10, -60);
						camera.follow(player.focalPoint);
						player.add_to_group(playerGroup);
						player.introduceYourselfWhenReady(() -> {
							openSubState(new SoldierIntro(1.5, () -> {
								player.inControl = true;
								player.killable = true;

								if (respawn) {
									player.invulnerable(1);
								}
							}));
						});
						if (cb != null) cb();
					});
				});
			}
		});
	}

	public function findGroundUnderPoint(start:FlxPoint, into:FlxPoint = null):FlxPoint {
		var groundCast = Line.get(start.x, start.y, start.x, start.y + 144);
		var ground = groundCast.linecast(allGroundingBodies);
		if (ground != null) {
			if (into == null) {
				into = FlxPoint.get();
			}
			into.set(ground.closest.hit.x, ground.closest.hit.y);
		}
		return into;
	}

	public function resetCamera() {
		camera.follow(null);
		camera.setScrollBoundsRect(0, 0, level.bounds.width, level.bounds.height);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		#if debug
		if (FlxG.keys.justPressed.P) {
			playEndSequence();
		}
		#end

		for (cp in level.checkpoints) {
			DebugDraw.ME.drawWorldCircle(cp.pixelX, cp.pixelY, 2, LEVEL);
		}

		tryUpdatingCheckpoint();

		for (st in scrollTriggers) {
			if (st.isReady() && camera.viewRight + 5 > st.x) {
				st.activate();
			}
		}
	}

	var nextCPCheck = 0;
	function tryUpdatingCheckpoint() {
		if (player == null) {
			return;
		}

		var cps = level.checkpoints;
		for (i in nextCPCheck...cps.length) {
			if (player.body.x > cps[i].pixelX) {
				Collected.setLastCheckpoint(level.raw.iid, cps[i].iid);
				nextCPCheck = i + 1;
			}
		}
	}

	public function killPlayer() {
		Collected.addDeath();
		player.remove_from_group(playerGroup);
		player.remove_object();

		// force them to a rounded pixel position to avoid jitters
		player.x = Math.round(player.x);
		
		corpseGroup.add(player);

		var cpID = Collected.getCheckpointID();
		var respawnPoint = getLevelSpawnPoint();
		var matches = level.checkpoints.filter((c) -> {return c.iid == cpID;});
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

		// XXX: We need to be able to reset bosses, specifically
		for (trigger in level.bossSpawners) {
			trigger.resetTrigger();
		}

		spawnPlayer(respawnPoint, true);
	}

	public function addTerrain(b:Body) {
		terrainBodies.push(b);
		FlxEcho.instance.world.add(b);
	}

	public function addPlayerTerrain(b:Body) {
		playerTerrainBodies.push(b);
		FlxEcho.instance.world.add(b);
	}

	public function addBGTerrain(b:FlxSprite) {
		// TODO: Do we need a separate group for things we want the player to collide with, but bullets NOT to?
		b.add_to_group(terrainDecorGroup);
	}

	public function addEnemy(e:FlxSprite) {
		e.add_to_group(enemies);
	}

	public function removeEnemy(e:FlxSprite) {
		e.remove_from_group(enemies);
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
