package entities.boss;

import loaders.Aseprite;
import states.PlayState;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;

class WallBoss extends FlxTypedGroup<FlxSprite> {

	var bodyBG:FlxSprite;
	var ballTarget:BallTarget;
	var gunTurret1:Turret;
	var gunTurret2:Turret;
	var groundLaser:GroundLaser;

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
		ballTarget.health = 30;
		gunTurret1 = new Turret(
			x + sliceMap.get("Turret1").keys[0].bounds.x,
			y + sliceMap.get("Turret1").keys[0].bounds.y);
		gunTurret1.health = 30;
		gunTurret2 = new Turret(
			x + sliceMap.get("Turret2").keys[0].bounds.x,
			y + sliceMap.get("Turret2").keys[0].bounds.y);
		gunTurret2.health = 30;
		groundLaser = new GroundLaser(x + sliceMap.get("GroundLaser").keys[0].bounds.x, y + sliceMap.get("GroundLaser").keys[0].bounds.y);
		// TODO: We probably want to do this only once the player is close enough
		spawn();
	}

	public function spawn() {
		PlayState.ME.addBGTerrain(bodyBG);
		PlayState.ME.addObject(ballTarget);
		PlayState.ME.addObject(gunTurret1);
		PlayState.ME.addObject(gunTurret2);
		PlayState.ME.addObject(groundLaser);
	}
}