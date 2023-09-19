package entities.particle;

import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.FlxSprite;
import flixel.effects.particles.FlxParticle;

class SmokeParticle extends FlxParticle {
	public function new() {
		super();
	}

	override function loadGraphic(graphic:FlxGraphicAsset, animated:Bool = false, frameWidth:Int = 0, frameHeight:Int = 0, unique:Bool = false, ?key:String):FlxSprite {
		var spr = super.loadGraphic(AssetPaths.Smoke__png, true, 25, 25);

		animation.add('all', [0, 1, 2, 3, 4, 5], 5, false);
		animation.play('all');

		return spr;
	}
}