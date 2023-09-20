package entities.boss;

import loaders.Aseprite;
import flixel.FlxSprite;

class WallBG extends FlxSprite {
	public function new(x:Float, y:Float) {
		super(x, y);
		Aseprite.loadAllAnimations(this, AssetPaths.Wall__json);
		animation.frameIndex = 0;
	}

	public function die() {
		animation.frameIndex = 1;
	}
}