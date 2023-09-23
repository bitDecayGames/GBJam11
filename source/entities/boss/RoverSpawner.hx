package entities.boss;

import flixel.math.FlxPoint;
import states.PlayState;
import flixel.FlxG;
import flixel.math.FlxRect;
import entities.sensor.Trigger;

class RoverSpawner extends Trigger {
	var rover:RoverBoss;

	public function new(x:Float, y:Float) {
		super(null, FlxRect.get(x, y, 8, FlxG.height), false);
	}

	override function activateInner() {
		if (rover == null || !rover.alive) {
			var spawnPoint = PlayState.ME.findGroundUnderPoint(FlxPoint.weak(x, y));
			rover = new RoverBoss(spawnPoint.x, spawnPoint.y);
			PlayState.ME.addEnemy(rover);
			PlayState.ME.addEnemy(rover.turret);
			PlayState.ME.addEnemy(rover.core);
		}
	}
}