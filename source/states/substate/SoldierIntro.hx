package states.substate;

import input.SimpleController;
import ui.font.BitmapText.Trooper;
import ui.SoldierPortrait;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;

class SoldierIntro extends FlxSubState {
	// static var quips = [
	// 	"one for the core!",
	// 	"we will not be stopped!",
	// 	"prepare yourself!"
	// ];
	static var quips = [
		"prepare yourself!"
	];
	
	var display:Float = 0;
	var cb:Void->Void;

	public function new(displayTime:Float, cb:Void->Void = null) {
		super();
		display = displayTime;
		this.cb = cb;
	}

	override function create() {
		super.create();

		var banner = new FlxSprite(0, 10, AssetPaths.Banner__png);
		banner.scrollFactor.set();
		// banner.makeGraphic(FlxG.width, cast (FlxG.height / 2), Constants.LIGHTEST);
		// FlxSpriteUtil.drawRect(banner, 0, 2, banner.width, banner.height - 4, Constants.DARKEST);
		// FlxSpriteUtil.drawRect(banner, 0, 5, banner.width, banner.height - 10, Constants.DARK);
		// FlxSpriteUtil.drawRect(banner, 0, 10, banner.width, banner.height - 20, Constants.LIGHT);

		add(banner);

		var portrait = new SoldierPortrait(3, banner.y + 9);
		portrait.scrollFactor.set();
		add(portrait);

		var flavorText = new Trooper(portrait.x + portrait.width + 10, portrait.y, quips[FlxG.random.int(0, quips.length-1)]);
		flavorText.autoSize = false;
		flavorText.fieldWidth = cast (FlxG.width - flavorText.x - 10);
		flavorText.scrollFactor.set();
		add(flavorText);

		FmodManager.PlaySoundOneShot(FmodSFX.VoicePrepareYourself);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		display -= elapsed;

		if (display <= 0) {
			close();
			if (cb != null) cb();
		}
	}
}