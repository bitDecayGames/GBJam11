package entities;

import entities.sensor.AlienSpawner;

class RunningAlien extends Alien {

	var runLeft = true;

	public function new(x:Float, y:Float, source:AlienSpawner) {
		super(x, y, source);
	}

	override function updateBehavior(delta:Float) {
		if (!grounded) {
			return;
		}

		if (runLeft) {
			if (!groundedCastLeft) {
				runLeft = false;
			}
			intentState.add(MOVE_LEFT);
			body.velocity.x = -speed;
		} else {
			if (!groundedCastRight) {
				runLeft = true;
			}
			intentState.add(MOVE_RIGHT);
			body.velocity.x = speed;
		}
	}
}