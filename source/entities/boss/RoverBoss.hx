package entities.boss;

import flixel.tweens.FlxTween;
import echo.Body;
import flixel.util.FlxColor;
import loaders.Aseprite;

using echo.FlxEcho;

class RoverBoss extends EchoSprite {
	public function new(x:Float, y:Float) {
		super(x, y-20);
		
		body.active = false;
	} 

	override function configSprite() {
		// Aseprite.loadAllAnimations(this, AssetPaths.GroundLaser__json);
		makeGraphic(40, 40, FlxColor.MAGENTA);
	}

	override function makeBody():Body {
		return this.add_body({
			x: x,
			y: y,
			shapes: [
				{
					type:RECT,
					width: 40,
					height: 40
				},
			],
			// kinematic: true,
		});
	}

	var waiting = true;
	var waitTime = 3.0;

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (waiting) {
			waitTime -= elapsed;
			if (waitTime <= 0) {
				waiting = false;
				dashAcrossScreen();
				waitTime = 3.0;
			}
		}
	}

	function dashAcrossScreen() {
		if (x > camera.getCenterPoint().x) {
			// TODO: Need some sort of anticipation frames
			FlxTween.tween(body, {x: camera.viewLeft - 20}, {
				onComplete: (t) -> {
					FlxTween.tween(body, {x: camera.viewLeft + 25}, {
						onComplete: (t2) -> {
							waiting = true;
						}
					});
				}
			});
		} else {
			// TODO: Need some sort of anticipation frames
			FlxTween.tween(body, {x: camera.viewRight + 20}, {
				onComplete: (t) -> {
					FlxTween.tween(body, {x: camera.viewRight - 25}, {
						onComplete: (t2) -> {
							waiting = true;
						}
					});
				}
			});
		}
	}
}