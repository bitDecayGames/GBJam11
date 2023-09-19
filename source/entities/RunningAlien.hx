package entities;

import entities.sensor.AlienSpawner;

class RunningAlien extends Alien {
	public function new(x:Float, y:Float, source:AlienSpawner) {
		super(x, y, source);
	}

	override function updateBehavior(delta:Float) {
		super.updateBehavior(delta);
	}
}