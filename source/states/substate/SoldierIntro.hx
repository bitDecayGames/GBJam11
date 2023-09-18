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
	public function new() {
		super();
	}

	override function create() {
		super.create();

		var banner = new FlxSprite(0, 10);
		banner.scrollFactor.set();
		banner.makeGraphic(FlxG.width, cast (FlxG.height / 2), Constants.LIGHTEST);
		FlxSpriteUtil.drawRect(banner, 0, 2, banner.width, banner.height - 4, Constants.DARKEST);
		FlxSpriteUtil.drawRect(banner, 0, 5, banner.width, banner.height - 10, Constants.DARK);
		FlxSpriteUtil.drawRect(banner, 0, 10, banner.width, banner.height - 20, Constants.LIGHT);

		add(banner);

		var portrait = new SoldierPortrait(10, banner.y + 16);
		portrait.scrollFactor.set();
		add(portrait);

		var flavorText = new Trooper(portrait.x + portrait.width + 10, portrait.y, "one for the\ncore!");
		flavorText.autoSize = false;
		flavorText.fieldWidth = cast (FlxG.width - flavorText.x - 10);
		flavorText.scrollFactor.set();
		add(flavorText);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (SimpleController.just_pressed(A)) {
			close();
		}
	}
}