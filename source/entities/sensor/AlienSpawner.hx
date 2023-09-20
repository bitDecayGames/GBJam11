package entities.sensor;

import states.PlayState;
import animation.Flag;
import flixel.FlxG;
import flixel.math.FlxRect;

class AlienSpawner extends Trigger {
	var spawnX:Float;
	var spawnY:Float;

	var maker:(AlienSpawner)->Alien;

	var readyForReset = false;
	var activeEnemy:Alien;

	public function new(x:Float, y:Float, maker:(AlienSpawner)->Alien) {
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