package entities;

import entities.projectile.BasicBullet;
import echo.Body;
import echo.data.Data.CollisionData;
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

	override function handleEnter(other:Body, data:Array<CollisionData>) {
		super.handleEnter(other, data);

		if (!(other.object is BasicBullet)) {
			if (data[0].normal.x != 0) {
				runLeft = !runLeft;
			}
		}
	}
}