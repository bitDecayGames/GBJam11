package entities.boss;

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

	var bodyBG:FlxSprite;
	var ballTarget:BallTarget;
	var gunTurret1:Turret;
	var gunTurret2:Turret;
	var groundLaser:GroundLaser;

	var blocker:Body;

	var deathStarted = false;

	public function new(x:Float, y:Float) {
		super();

		var atlas = Aseprite.getAtlas(AssetPaths.Wall__json);
		var sliceMap = new Map<String, loaders.AsepriteTypes.AseAtlasSlice>();
		for (slice in atlas.meta.slices) {
			sliceMap.set(slice.name, slice);
		}
		// Spawn main backing image
		bodyBG = new FlxSprite(x, y, AssetPaths.Wall__png);
		// build turrets/ball targets
		// add everything to the playstate
		ballTarget = new BallTarget(
			x + sliceMap.get("Ball").keys[0].bounds.x,
			y + sliceMap.get("Ball").keys[0].bounds.y + 1);
		ballTarget.health = 3;
		gunTurret1 = new Turret(
			x + sliceMap.get("Turret1").keys[0].bounds.x,
			y + sliceMap.get("Turret1").keys[0].bounds.y);
		gunTurret1.health = 2;
		gunTurret2 = new Turret(
			x + sliceMap.get("Turret2").keys[0].bounds.x,
			y + sliceMap.get("Turret2").keys[0].bounds.y);
		gunTurret2.health = 2;
		groundLaser = new GroundLaser(x + sliceMap.get("GroundLaser").keys[0].bounds.x, y + sliceMap.get("GroundLaser").keys[0].bounds.y);
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
		PlayState.ME.addTerrain(blocker);
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
			});
		}
	}
}