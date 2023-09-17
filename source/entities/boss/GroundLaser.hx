package entities.boss;

import loaders.AsepriteMacros;
import loaders.Aseprite;
import echo.Body;

using echo.FlxEcho;

class GroundLaser extends EchoSprite {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/GroundLaser.json");
	
	public function new(x:Float, y:Float) {
		super(x, y);
	}

	override function configSprite() {
		Aseprite.loadAllAnimations(this, AssetPaths.GroundLaser__json);
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
					type:RECT,
					width: 54,
					height: 13
				},
			],
			kinematic: true,
		});
	}
}