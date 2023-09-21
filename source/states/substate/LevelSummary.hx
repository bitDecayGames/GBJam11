package states.substate;

import progress.Collected;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import ui.font.BitmapText.TrooperDarkest;
import ui.font.BitmapText.TrooperLight;
import input.SimpleController;
import ui.font.BitmapText.Trooper;
import ui.SoldierPortrait;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;

class LevelSummary extends FlxSubState {
	var display:Float = 3;
	var cb:Void->Void;

	var everything = new FlxTypedGroup<FlxObject>();

	var pages = 2;

	public function new(cb:Void->Void = null) {
		super();
		this.cb = cb;
	}

	override function create() {
		super.create();
		var bg = new FlxSprite(AssetPaths.Placard__png);
		bg.screenCenter();
		bg.y -= FlxG.height;
		add(bg);
		
		var missionTitle = new TrooperDarkest(0, bg.y + 25, "mission complete");
		missionTitle.alignment = CENTER;
		missionTitle.autoSize = false;
		missionTitle.fieldWidth = cast(bg.width - 30);
		missionTitle.screenCenter(X);
		add(missionTitle);

		var bg2 = new FlxSprite(bg.x, bg.y - FlxG.height, AssetPaths.Placard__png);
		add(bg2);

		var deathLabel = new TrooperDarkest(0, bg2.y + 15, "soldiers lost:");
		deathLabel.alignment = CENTER;
		deathLabel.autoSize = false;
		deathLabel.fieldWidth = cast(bg.width - 30);
		deathLabel.screenCenter(X);
		add(deathLabel);

		var deathCount = new TrooperLight(0, deathLabel.y + 10, '${Collected.getDeathCount()}');
		deathCount.alignment = CENTER;
		deathCount.autoSize = false;
		deathCount.fieldWidth = cast(bg.width - 30);
		deathCount.screenCenter(X);
		add(deathCount);

		everything.add(bg);
		everything.add(missionTitle);
		everything.add(bg2);
		everything.add(deathLabel);
		everything.add(deathCount);

		tweenEverything();
	}

	function tweenEverything() {
		var firstOne = true;
		for (m in everything) {
			m.scrollFactor.set();

			var doThings = firstOne;
			firstOne = false;
			var thing = m;
			var dest = thing.y + FlxG.height;

			// TODO SFX: Mission panel stars sliding out
			FlxTween.tween(thing, {y: dest}, {
				ease: FlxEase.quartIn,
				onComplete: (t) -> {
					if (doThings) {
						pages--;
						if (pages >= 0) {
							// TODO SFX: Mission panel slams into center screen
							camera.shake(.01, .1);
						}

						new FlxTimer().start(2, (timer) -> {
							// we go to -1 so everything goes off screen
							if (pages <= -1) {
								close();
								if (cb != null) cb();
							} else {
								tweenEverything();
							}
						});
					}
				}
			});
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
	}
}