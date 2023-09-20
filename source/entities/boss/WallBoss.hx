package entities.boss;

import loaders.AsepriteMacros;
import flixel.FlxBasic;
import flixel.math.FlxRect;
import entities.particle.Explosion;
import flixel.FlxG;
import echo.Body;
import echo.FlxEcho;
import loaders.Aseprite;
import states.PlayState;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;

class WallBoss extends FlxBasic {

	private static var slices = AsepriteMacros.sliceNames("assets/aseprite/Wall.json");

	var sliceMap = new Map<String, loaders.AsepriteTypes.AseAtlasSlice>();

	var bodyBG:WallBG;
	var ballTarget:BallTarget;
	var gunTurret1:Turret;
	var gunTurret2:Turret;
	var groundLaser:GroundLaser;

	var blocker:Body;
	var exitPlatform:Body;
	var exitRoof:Body;

	var deathStarted = false;

	public function new(x:Float, y:Float) {
		super();

		var atlas = Aseprite.getAtlas(AssetPaths.Wall__json);
		for (slice in atlas.meta.slices) {
			// this is just to force our slice names to align with map keys. likely want a better way of doing this
			// in the future
			sliceMap.set(slice.name + "_0", slice);
		}
		// Spawn main backing image
		bodyBG = new WallBG(x, y);
		// build turrets/ball targets
		// add everything to the playstate
		ballTarget = new BallTarget(
			x + sliceMap.get(slices.Ball_0).keys[0].bounds.x,
			y + sliceMap.get(slices.Ball_0).keys[0].bounds.y + 1);
		ballTarget.health = 10;
		gunTurret1 = new Turret(
			x + sliceMap.get(slices.Turret1_0).keys[0].bounds.x,
			y + sliceMap.get(slices.Turret1_0).keys[0].bounds.y);
		gunTurret1.health = 5;
		gunTurret2 = new Turret(
			x + sliceMap.get(slices.Turret2_0).keys[0].bounds.x,
			y + sliceMap.get(slices.Turret2_0).keys[0].bounds.y);
		gunTurret2.health = 5;
		groundLaser = new GroundLaser(x + sliceMap.get(slices.GroundLaser_0).keys[0].bounds.x, y + sliceMap.get(slices.GroundLaser_0).keys[0].bounds.y);
		// TODO: We probably want to do this only once the player is close enough
		spawn();
	}

	public function spawn() {
		blocker = new Body({
			x: bodyBG.x,
			y: bodyBG.y,
			shapes: [
				{
					type:RECT,
					width: 16,
					height: FlxG.camera.height,
					offset_x: 8,
					offset_y: FlxG.camera.height/2
				},
			],
			kinematic: true,
		});

		var floorSlice = sliceMap.get(slices.dead_platform_0).keys[0];
		exitPlatform = new Body({
			x: bodyBG.x + floorSlice.bounds.x,
			y: bodyBG.y + floorSlice.bounds.y,
			shape: {
				type: RECT,
				width: floorSlice.bounds.w,
				height: floorSlice.bounds.h,
				offset_x: floorSlice.bounds.w / 2,
				offset_y: floorSlice.bounds.h / 2,
			},
			kinematic: true,
		});
		exitPlatform.active = false;

		var roofSlice = sliceMap.get(slices.death_roof_0).keys[0];
		exitRoof = new Body({
			x: bodyBG.x + roofSlice.bounds.x,
			y: bodyBG.y + roofSlice.bounds.y,
			shape: {
				type: RECT,
				width: roofSlice.bounds.w,
				height: roofSlice.bounds.h,
				offset_x: roofSlice.bounds.w / 2,
				offset_y: roofSlice.bounds.h / 2,
			},
			kinematic: true,
		});
		exitRoof.active = false;

		PlayState.ME.addTerrain(blocker);
		PlayState.ME.addTerrain(exitPlatform);
		PlayState.ME.addTerrain(exitRoof);
		PlayState.ME.addBGTerrain(bodyBG);
		PlayState.ME.addObject(ballTarget);
		PlayState.ME.addObject(gunTurret1);
		PlayState.ME.addObject(gunTurret2);
		PlayState.ME.addObject(groundLaser);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (!deathStarted && ballTarget.health <= 0 && gunTurret1.health <= 0 && gunTurret2.health <= 0) {
			deathStarted = true;
			Explosion.death(100, FlxRect.weak(bodyBG.x, bodyBG.y, bodyBG.width, bodyBG.height), 3, () -> {
				blocker.active = false;
				bodyBG.die();
				exitPlatform.active = true;
				exitRoof.active = true;
			});
		}
	}
}