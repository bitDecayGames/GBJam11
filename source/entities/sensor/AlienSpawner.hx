package entities.sensor;

import states.PlayState;
import animation.Flag;
import flixel.FlxG;
import flixel.math.FlxRect;

class AlienSpawner extends Trigger {
	var spawnX:Float;
	var spawnY:Float;

	var readyForReset = false;
	var activeEnemy:Alien;

	public function new(x:Float, y:Float) {
		super(null, FlxRect.weak(x, 0, 1, FlxG.height), false);
		spawnX = x;
		spawnY = y;
	}

	override function activate() {
		super.activate();

		// TODO: Spawn alien!
		trace('making alien');
		activeEnemy = new Alien(spawnX, spawnY, this);
		PlayState.ME.addEnemy(activeEnemy);
		// PlayState.ME.addEnemy
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