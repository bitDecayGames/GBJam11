package entities;

import loaders.AsepriteMacros;
import loaders.Aseprite;
import flixel.math.FlxPoint;
import entities.particle.Smoker;
import flixel.effects.particles.FlxEmitter;
import flixel.util.FlxColor;
import flixel.FlxSprite;

class SoldierPod extends FlxSprite {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/Pod.json");

	var emitter:FlxEmitter;
	var emitterOffset = FlxPoint.get(28, 0);

	public function new(x:Float, y:Float) {
		super(x, y);
		Aseprite.loadAllAnimations(this, AssetPaths.Pod__json);
		
		emitter = Smoker.create(x, y);
		emitter.frequency = 0.05;
		FmodManager.PlaySoundOneShot(FmodSFX.ShipFall);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		emitter.setPosition(x + emitterOffset.x, y + emitterOffset.y);
	}

	public function landed() {
		FmodManager.PlaySoundOneShot(FmodSFX.ShipCrash);
		animation.play(anims.Crash);
		emitter.frequency = 0.1;
	}

	override function kill() {
		super.kill();

		emitter.kill();
	}
}