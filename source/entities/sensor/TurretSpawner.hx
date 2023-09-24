package entities.sensor;

import flixel.FlxSprite;
import entities.enemy.LoneTurret;
import states.PlayState;
import animation.Flag;
import flixel.FlxG;
import flixel.math.FlxRect;

class TurretSpawner extends Trigger {
	var spawnX:Float;
	var spawnY:Float;

	var maker:(TurretSpawner)->LoneTurret;

	var readyForReset = false;
	var activeEnemy:LoneTurret;

	var bg:FlxSprite;

	public function new(x:Float, y:Float, maker:(TurretSpawner)->LoneTurret) {
		super(null, FlxRect.weak(x, 0, 1, FlxG.height), false);
		spawnX = x;
		spawnY = y;
		this.maker = maker;
	}

	override function activate() {
		super.activate();

		if (activeEnemy != null && activeEnemy.alive) {
			return;
		}

		activeEnemy = maker(this);
		PlayState.ME.addEnemy(activeEnemy);
		PlayState.ME.addBGTerrain(activeEnemy.bg);
	}

	public function queueReset() {
		readyForReset = true;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (readyForReset && camera.viewRight + 5 < x) {
			ready = true;
		}
	}
}