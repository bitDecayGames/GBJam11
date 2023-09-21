package states.substate;

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

class LevelIntro extends FlxSubState {
	var display:Float = 3;
	var cb:Void->Void;

	var everything = new FlxTypedGroup<FlxObject>();

	public function new(cb:Void->Void = null) {
		super();
		this.cb = cb;
	}

	override function create() {
		super.create();
		var bg = new FlxSprite(AssetPaths.Placard__png);
		// bg.makeGraphic(cast(FlxG.width * .8), cast(FlxG.height * .5), Constants.LIGHTEST);
		bg.screenCenter();
		add(bg);
		
		var missionTitle = new TrooperDarkest(0, bg.y + 25, PlayState.ME.level.raw.f_mission_name);
		missionTitle.alignment = CENTER;
		missionTitle.autoSize = false;
		missionTitle.fieldWidth = cast(bg.width - 6);
		missionTitle.screenCenter(X);
		add(missionTitle);

		var missionDescription = new TrooperLight(0, missionTitle.y + 20, PlayState.ME.level.raw.f_mission_description);
		missionDescription.alignment = CENTER;
		missionDescription.autoSize = false;
		missionDescription.fieldWidth = cast(bg.width - 6);
		missionDescription.screenCenter(X);
		add(missionDescription);

		everything.add(bg);
		everything.add(missionTitle);
		everything.add(missionDescription);

		tweenEverything();
	}

	function tweenEverything() {
		var firstOne = true;
		for (m in everything) {
			var doThings = firstOne;
			firstOne = false;
			var thing = m;
			var dest = thing.y;
			var destOut = thing.y + FlxG.height;
			thing.y -= FlxG.height;

			// TODO SFX: Mission panel stars sliding out
			FlxTween.tween(thing, {y: dest}, {
				ease: FlxEase.quartIn,
				onComplete: (t) -> {
					if (doThings) {
						// TODO SFX: Mission panel slams into center screen
						camera.shake(.01, .1);
					}
					new FlxTimer().start(2, (timer) -> {
						if (doThings) {
							// TODO SFX: Mission panel stars sliding out
						}
						FlxTween.tween(thing, {y: destOut}, {
							ease:FlxEase.quartIn,
							onComplete: (t2) -> {
								if (doThings) {
									close();
									if (cb != null) cb();
								}
							}
						});
					});
				}
			});
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
	}
}