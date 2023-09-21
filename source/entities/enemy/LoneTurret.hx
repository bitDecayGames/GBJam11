package entities.enemy;

import entities.sensor.TurretSpawner;
import states.PlayState;
import entities.boss.Turret;

class LoneTurret extends Turret {
	var source:TurretSpawner = null;

	public function new(x:Float, y:Float, source:TurretSpawner) {
		super(x, y);
		this.source = source;
		health = 5;
	}

	override function kill() {
		super.kill();

		PlayState.ME.removeEnemy(this);
		body.remove();

		if (source != null) {
			source.queueReset();
		}
	}
}