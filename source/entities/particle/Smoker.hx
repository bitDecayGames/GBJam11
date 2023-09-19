package entities.particle;

import states.PlayState;
import flixel.effects.particles.FlxEmitter;

class Smoker {
	public static function create(pX:Float, pY:Float):FlxEmitter {
		var emitter = new FlxEmitter(pX, pY);
		emitter.particleClass = SmokeParticle;
		emitter.loadParticles(null, 100);
		emitter.lifespan.set(1.25, 2.5);
		// emitter.acceleration.set(0, -8, 0, -12, 0, 0, 0, 0);
		emitter.speed.set(45, 60);
		emitter.drag.set(20, 20);
		emitter.launchAngle.set(-110, -70);
		emitter.start(false);

		PlayState.ME.addParticleEmitter(emitter);
		return emitter;
	}
}
