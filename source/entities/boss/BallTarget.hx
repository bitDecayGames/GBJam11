package entities.boss;

import bitdecay.flixel.debug.DebugDraw;
import flixel.math.FlxRect;
import entities.particle.Explosion;
import flixel.util.FlxTimer;
import entities.projectile.BasicBullet;
import echo.data.Data.CollisionData;
import loaders.Aseprite;
import loaders.AsepriteMacros;
import echo.Body;

using echo.FlxEcho;

class BallTarget extends EchoSprite {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/BallTarget.json");

	public function new(x:Float, y:Float) {
		super(x, y);
	}

	override function configSprite() {
		Aseprite.loadAllAnimations(this, AssetPaths.BallTarget__json);
		animation.play(anims.Idle);
		x += width/2;
		y += height/2;
	}

	override function makeBody():Body {
		return this.add_body({
			x: x,
			y: y,
			shapes: [
				{
					type:CIRCLE,
					radius: 15,
				},
			],
			kinematic: true,
		});
	}

	var damageTimer:FlxTimer = new FlxTimer();
	var damageBlinkDuration = 0.2;

	override function handleEnter(other:Body, data:Array<CollisionData>) {
		super.handleEnter(other, data);

		if (other.object is BasicBullet) {
			health--;
			camera.shake(0.01, 0.1);
			FmodManager.PlaySoundOneShot(FmodSFX.EnemyBossDamage);

			if (health <= 0) {
				body.active = false;
			}

			animation.play(anims.Damage);
			damageTimer.start(damageBlinkDuration, (t) -> {
				if (health > 0) {
					animation.play(anims.Idle);
				} else {
					// TODO: More animation around this?
					animation.play(anims.Broken);
					Explosion.death(15, FlxRect.weak(x, y, width, height), 3);
				}
			});
		}
	}
}