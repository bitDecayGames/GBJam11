package entities;

import flixel.math.FlxPoint;
import entities.particle.Smoker;
import flixel.effects.particles.FlxEmitter;
import flixel.util.FlxColor;
import flixel.FlxSprite;

class SoldierPod extends FlxSprite {
	var emitter:FlxEmitter;
	var emitterOffset = FlxPoint.get(7, 15);

	public function new(x:Float, y:Float) {
		super(x, y);
		makeGraphic(15, 30, FlxColor.MAGENTA);
		
		emitter = Smoker.create(x, y);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		emitter.setPosition(x + emitterOffset.x, y + emitterOffset.y);
	}
}