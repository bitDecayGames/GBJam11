package ui;

import loaders.Aseprite;
import flixel.FlxSprite;

class SoldierPortrait extends FlxSprite {
	public function new(x:Float, y:Float) {
		super(x, y);
		Aseprite.loadAllAnimations(this, AssetPaths.Faces__json);
		animation.frameIndex = 1;
	}
}