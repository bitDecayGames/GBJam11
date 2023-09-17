package entities.boss;

import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import entities.projectile.BasicBullet;
import echo.data.Data.CollisionData;
import loaders.AsepriteMacros;
import loaders.Aseprite;
import echo.Body;

using echo.FlxEcho;

class Turret extends EchoSprite {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/RotatingTurret.json");
	
	public function new(x:Float, y:Float) {
		super(x, y);
	}

	override function configSprite() {
		Aseprite.loadAllAnimations(this, AssetPaths.RotatingTurret__json);
		// animation.play(anims);
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
					radius: 7,
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

			if (health <= 0) {
				body.active = false;
			}

			animation.frameIndex = 7;
			damageTimer.start(damageBlinkDuration, (t) -> {
				if (health > 0) {
					animation.frameIndex = 2;
				} else {
					// TODO: More animation around this?
					animation.frameIndex = 12;
				}
			});
		}
	}
}