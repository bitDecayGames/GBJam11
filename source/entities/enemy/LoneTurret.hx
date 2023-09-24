package entities.enemy;

import flixel.FlxSprite;
import entities.sensor.TurretSpawner;
import states.PlayState;
import entities.boss.Turret;

class LoneTurret extends Turret {
	var source:TurretSpawner = null;
	public var bg:FlxSprite;

	public function new(x:Float, y:Float, source:TurretSpawner) {
		super(x, y);
		this.source = source;
		health = 3;

		bg = new FlxSprite(x, y, AssetPaths.TurretBG__png);
		PlayState.ME.addBGTerrain(bg);
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